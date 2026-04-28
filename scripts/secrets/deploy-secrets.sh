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

# Resolve required tools to absolute paths and verify identity.
# Activation hooks have an unstable PATH (which yq/sops gets found can vary by
# generation-swap timing or stray binaries elsewhere). A wrong or older yq
# silently returns the whole document instead of a single key value, leaving
# secret files containing raw YAML — caught here.
resolve_bin() {
  local name="$1"
  local found
  found=$(command -v "$name" 2>/dev/null) || { error "Required tool not found: $name"; exit 1; }
  # Ensure it actually lives in the nix store (not a stray system binary)
  case "$found" in
    /nix/store/*|/run/current-system/*|/nix/var/nix/profiles/*) ;;
    *) error "Tool '$name' resolves outside nix store: $found"; exit 1 ;;
  esac
  printf '%s' "$found"
}
SOPS=$(resolve_bin sops)
YQ=$(resolve_bin yq)

# Verify yq is mikefarah/yq (Go), not kislyuk/yq (Python) — they have
# different path syntax and the wrong one returns garbage silently.
if ! "$YQ" --version 2>&1 | grep -q 'mikefarah'; then
  error "yq at $YQ is not mikefarah/yq (Go). Got: $($YQ --version 2>&1 | head -1)"
  exit 1
fi

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

# Decrypt entire file once to a temp file (avoids shell mangling multiline values)
info "Decrypting secrets..."
DECRYPTED_FILE=$(mktemp)
trap '/bin/rm -f "$DECRYPTED_FILE"' EXIT
if ! SOPS_AGE_KEY_FILE="$AGE_KEY" "$SOPS" -d "$SECRETS_FILE" > "$DECRYPTED_FILE" 2>/dev/null; then
  error "Failed to decrypt secrets file"
  exit 1
fi

# Get available keys
AVAILABLE_KEYS=$("$YQ" 'keys | .[]' "$DECRYPTED_FILE" 2>/dev/null)

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

  # Read from temp file to preserve multiline values (SSH keys, etc.)
  VALUE=$("$YQ" -r ".$key" "$DECRYPTED_FILE" 2>/dev/null)

  if [[ -z "$VALUE" || "$VALUE" == "null" ]]; then
    skipped=$(( skipped + 1 ))
    continue
  fi

  # Sanity: extracted value must not contain other top-level YAML keys from
  # the file (would indicate yq returned the whole document instead of one
  # key's value — the bug we previously hit during activation).
  #
  # Belt-and-suspenders: the decrypted YAML starts with the literal comment
  # "# Edit with: sops" — if that string appears in any extracted value, yq
  # returned the entire document. This catches the failure mode even when the
  # per-key regex below misses (e.g. unforeseen YAML scalar markers).
  if printf '%s' "$VALUE" | grep -qF "# Edit with: sops"; then
    error "Extracted value for '$key' contains the YAML file header — yq returned the whole document. Aborting to avoid corrupting $path."
    exit 1
  fi

  for other_key in $AVAILABLE_KEYS; do
    [[ "$other_key" == "$key" ]] && continue
    # Match real YAML key syntax: "key:" optionally followed by whitespace and
    # a scalar style indicator (| or >). The previous "-qxF" guard required an
    # exact full-line match for "key:" but real YAML uses "key: |" for
    # multiline scalars, so the check never fired.
    if printf '%s' "$VALUE" | grep -qE "^${other_key}:[[:space:]]*[|>]?[[:space:]]*$"; then
      error "Extracted value for '$key' contains another top-level key '$other_key:' — yq returned wrong content. Aborting to avoid corrupting $path."
      exit 1
    fi
  done

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
