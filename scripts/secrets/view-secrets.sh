#!/usr/bin/env bash
#
# view-secrets.sh - View decrypted secrets (read-only)
#
# Features:
# - Read-only viewing with syntax highlighting
# - No modifications allowed
# - Safe SOPS decryption

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MACHINE_ID="${1:-}"

# Auto-detect machine ID if not provided
if [ -z "$MACHINE_ID" ]; then
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    MACHINE_ID=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
    info "Auto-detected machine ID: $MACHINE_ID"
  else
    error "Could not detect machine ID"
    echo ""
    echo "Usage: $(basename "$0") [MACHINE_ID]"
    exit 1
  fi
fi

SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"

# Validate
if [ ! -f "$SECRETS_FILE" ]; then
  error "Secrets file not found: $SECRETS_FILE"
  exit 1
fi

if ! command -v sops &>/dev/null; then
  error "SOPS not found. Install with: nix-shell -p sops"
  exit 1
fi

# Validate SOPS environment
if [ -z "${SOPS_AGE_KEY_FILE:-}" ]; then
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
  else
    error "SOPS_AGE_KEY_FILE not set and default not found"
    exit 1
  fi
fi

info "Viewing secrets.yaml (read-only)"
echo ""

# Decrypt and display
if ! sops -d "$SECRETS_FILE"; then
  error "Failed to decrypt secrets.yaml"
  exit 1
fi
