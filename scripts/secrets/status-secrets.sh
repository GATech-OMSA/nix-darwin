#!/usr/bin/env bash
#
# status-secrets.sh - Show secrets management status
#
# Quick overview of age key, SOPS config, encryption status, tools,
# and active deployed secrets.
#
# Usage:
#   secrets-status

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
error() { echo -e "${RED}✗${NC} $*"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/machine-id.sh"  # get_machine_id

echo ""
echo "Secrets Management Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Age key
echo "Age Key:"
if [ -f ~/.config/sops/age/keys.txt ]; then
  pubkey=$(grep "public key:" ~/.config/sops/age/keys.txt | awk '{print $NF}')
  perms=$(stat -f%Lp ~/.config/sops/age/keys.txt 2>/dev/null)
  success "Exists: ~/.config/sops/age/keys.txt"
  echo -e "  ${DIM}Public key: $pubkey${NC}"
  if [ "$perms" = "600" ]; then
    success "Permissions: $perms"
  else
    warning "Permissions: $perms (should be 600)"
  fi
else
  error "Not found: ~/.config/sops/age/keys.txt"
  echo "  Generate: age-keygen -o ~/.config/sops/age/keys.txt"
fi
echo ""

# SOPS config
echo ".sops.yaml:"
if [ -f "$REPO_ROOT/.sops.yaml" ]; then
  success "Exists: $REPO_ROOT/.sops.yaml"
  if [ -n "${pubkey:-}" ]; then
    if grep -q "$pubkey" "$REPO_ROOT/.sops.yaml" 2>/dev/null; then
      success "Public key matches"
    else
      warning "Public key NOT in .sops.yaml"
    fi
  fi
else
  error "Not found"
fi
echo ""

# Machine and secrets file
echo "Secrets File:"
if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
  machine_id="$(get_machine_id)"
  secrets_file="$REPO_ROOT/nix-config/hosts/$machine_id/secrets.yaml"

  echo -e "  ${DIM}Machine: $machine_id${NC}"

  if [ -f "$secrets_file" ]; then
    success "Exists: $secrets_file"
    if grep -q "sops:" "$secrets_file" 2>/dev/null && grep -q "mac:" "$secrets_file" 2>/dev/null; then
      success "Encrypted (SOPS)"
    else
      warning "Appears to be plaintext"
    fi
  else
    error "Not found: $secrets_file"
  fi
else
  error "No machine config found"
fi
echo ""

# Tools
echo "Tools:"
for tool in sops age yq jq; do
  if command -v "$tool" &>/dev/null; then
    ver=$($tool --version 2>/dev/null | head -1)
    success "$tool: $ver"
  else
    error "$tool: not found"
  fi
done
echo ""

# Active deployed secrets
echo "Deployed Secrets:"
deployed=0
for path in ~/.zsh_secrets ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_work ~/.aws/credentials ~/.aws/accounts.json; do
  if [ -f "$path" ]; then
    perms=$(stat -f%Lp "$path" 2>/dev/null)
    age=$(stat -f%Sm -t"%Y-%m-%d" "$path" 2>/dev/null)
    success "$path ${DIM}($perms, $age)${NC}"
    deployed=$(( deployed + 1 ))
  fi
done

for dir in ~/.db ~/.tokens ~/.credentials; do
  if [ -d "$dir" ]; then
    count=$(find "$dir" -type f -not -path "*/backup/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt 0 ]; then
      success "$dir/ ($count files)"
      deployed=$(( deployed + count ))
    fi
  fi
done

if [ "$deployed" -eq 0 ]; then
  warning "No deployed secrets found"
  echo "  Run: secrets-deploy"
fi
echo ""

# Workflow hint
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  secrets-edit    Edit encrypted secrets.yaml"
echo "  secrets-deploy  Decrypt + deploy to target paths"
echo "  respin          Apply to current shell (full restart)"
echo "  secrets-rescan  Discover unmanaged secrets"
echo ""
