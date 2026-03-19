#!/usr/bin/env bash
#
# deploy-secrets.sh - Decrypt and deploy secrets without nix-rebuild
#
# Reads secrets.yaml, decrypts with sops, and deploys each key to its
# target path. Works for both personal and work profiles.
#
# Usage:
#   secrets-deploy           # Auto-detect machine ID
#   secrets-deploy --dry-run # Show what would be deployed

set -uo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

info() { echo -e "${BLUE}[i]${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}▸${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRY_RUN=false
AGE_KEY="$HOME/.config/sops/age/keys.txt"

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run|-n) DRY_RUN=true ;;
    --help|-h)
      echo "Usage: deploy-secrets.sh [--dry-run]"
      echo ""
      echo "Decrypt secrets.yaml and deploy to target paths."
      echo "Auto-detects machine ID from config/machine-config.nix."
      exit 0
      ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# Ensure Nix paths are available (activation hooks may have limited PATH)
for nixpath in /run/current-system/sw/bin /nix/var/nix/profiles/default/bin "$HOME/.nix-profile/bin"; do
  [[ -d "$nixpath" ]] && [[ ":$PATH:" != *":$nixpath:"* ]] && PATH="$nixpath:$PATH"
done

# Check required tools
for tool in sops yq; do
  if ! command -v "$tool" &>/dev/null; then
    error "Required tool not found: $tool"
    exit 1
  fi
done

# Auto-detect machine ID
if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
  MACHINE_ID=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
else
  error "Could not detect machine ID (config/machine-config.nix not found)"
  exit 1
fi

SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"

# Pre-flight checks
if [ ! -f "$AGE_KEY" ]; then
  error "Age key not found: $AGE_KEY"
  exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
  error "Secrets file not found: $SECRETS_FILE"
  exit 1
fi

info "Machine: $MACHINE_ID"
info "Secrets: $SECRETS_FILE"
echo ""

# Decrypt entire file once into memory
info "Decrypting secrets..."
DECRYPTED=$(SOPS_AGE_KEY_FILE="$AGE_KEY" sops -d "$SECRETS_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
  error "Failed to decrypt secrets file"
  exit 1
fi

# Get available keys
AVAILABLE_KEYS=$(printf '%s\n' "$DECRYPTED" | yq 'keys | .[]' 2>/dev/null)

if [ -z "$AVAILABLE_KEYS" ]; then
  error "No keys found in secrets file (yq returned empty)"
  exit 1
fi

# ==============================================================================
# SECRET MAPPINGS
# ==============================================================================
# Format: "yaml_key|target_path|mode"
# Keys not present in secrets.yaml are silently skipped.

MAPPINGS=(
  # Shell secrets
  "zsh_secrets|$HOME/.zsh_secrets|0600"

  # SSH keys (personal)
  "ssh_private_key|$HOME/.ssh/id_ed25519|0600"
  "ssh_public_key|$HOME/.ssh/id_ed25519.pub|0644"

  # SSH keys (work)
  "work_ssh_private_key|$HOME/.ssh/id_ed25519_work|0600"
  "work_ssh_public_key|$HOME/.ssh/id_ed25519_work.pub|0644"
  "work_ssh_private_key_rsa|$HOME/.ssh/id_rsa_work|0600"
  "work_ssh_public_key_rsa|$HOME/.ssh/id_rsa_work.pub|0644"

  # AWS
  "aws_credentials|$HOME/.aws/credentials|0600"
  "aws_accounts|$HOME/.aws/accounts.json|0600"

  # Database credentials
  "mssql_prod_connection|$HOME/.db/mssql/prod|0600"
  "postgres_prod_connection|$HOME/.db/postgres/prod|0600"
  "ods_prod_connection|$HOME/.db/ods/prod|0600"
  "dw_prod_connection|$HOME/.db/dw/prod|0600"

  # API tokens
  "git_token|$HOME/.tokens/git_token|0600"
  "hcp_terraform_token|$HOME/.tokens/hcp_terraform_token|0600"
  "jira_api_token|$HOME/.tokens/jira_api_token|0600"
  "confluence_token|$HOME/.tokens/confluence_token|0600"

  # Service credentials
  "servicenow_credentials|$HOME/.credentials/servicenow|0600"
  "vpn_credentials|$HOME/.credentials/vpn|0600"
)

# ==============================================================================
# DEPLOY
# ==============================================================================

deployed=0
skipped=0

for mapping in "${MAPPINGS[@]}"; do
  IFS='|' read -r key path mode <<< "$mapping"

  # Skip if key not in secrets.yaml (fixed-string match, not regex)
  if ! printf '%s\n' "$AVAILABLE_KEYS" | grep -qxF "$key"; then
    continue
  fi

  # Use --raw-output to preserve multiline values (SSH keys, etc.)
  VALUE=$(printf '%s\n' "$DECRYPTED" | yq -r ".$key" 2>/dev/null)

  if [[ -z "$VALUE" || "$VALUE" == "null" ]]; then
    skipped=$(( skipped + 1 ))
    continue
  fi

  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${DIM}would deploy${NC} $key → $path ($mode)"
    deployed=$(( deployed + 1 ))
    continue
  fi

  # Backup if content differs
  if [ -f "$path" ]; then
    if ! printf '%s\n' "$VALUE" | diff -q - "$path" >/dev/null 2>&1; then
      backup_dir="$(dirname "$path")/backup"
      mkdir -p "$backup_dir"
      /bin/cp "$path" "$backup_dir/$(basename "$path")-$(date +%Y%m%d-%H%M%S)-$$"
    fi
  fi

  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$VALUE" > "${path}.tmp"
  /bin/mv "${path}.tmp" "$path"
  chmod "$mode" "$path"
  success "$key → $path"
  deployed=$(( deployed + 1 ))
done

echo ""
if [ "$DRY_RUN" = true ]; then
  info "Dry run: $deployed would be deployed, $skipped skipped"
else
  success "Deployed: $deployed, Skipped: $skipped"
  echo ""
  info "Run 'secrets-reload' to re-source in current shell"
fi
