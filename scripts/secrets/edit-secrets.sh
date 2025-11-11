#!/usr/bin/env bash
#
# edit-secrets.sh - Edit encrypted secrets.yaml with SOPS
#
# Features:
# - Automatic backup before editing
# - SOPS environment validation
# - Safe editing workflow

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse options
MACHINE_ID="${1:-}"
NO_BACKUP=false

if [[ "$MACHINE_ID" == "--no-backup" ]]; then
  NO_BACKUP=true
  MACHINE_ID="${2:-}"
fi

# Auto-detect machine ID if not provided
if [ -z "$MACHINE_ID" ]; then
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    MACHINE_ID=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
    info "Auto-detected machine ID: $MACHINE_ID"
  else
    error "Could not detect machine ID"
    echo ""
    echo "Usage: $(basename "$0") [MACHINE_ID]"
    echo ""
    echo "Example:"
    echo "  ./scripts/secrets/edit-secrets.sh mbp-jimmy"
    echo "  ./scripts/secrets/edit-secrets.sh  # Auto-detect from config"
    exit 1
  fi
fi

SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"

# Validate secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
  error "Secrets file not found: $SECRETS_FILE"
  exit 1
fi

# Check for SOPS
if ! command -v sops &>/dev/null; then
  error "SOPS not found. Please install SOPS first:"
  echo "  nix-shell -p sops"
  exit 1
fi

# Validate SOPS environment
if [ -z "${SOPS_AGE_KEY_FILE:-}" ]; then
  warning "SOPS_AGE_KEY_FILE not set"
  echo ""
  echo "Checking default location: ~/.config/sops/age/keys.txt"

  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    info "Using default age key location"
  else
    error "Age key not found"
    echo ""
    echo "Please set SOPS_AGE_KEY_FILE:"
    echo "  export SOPS_AGE_KEY_FILE=\$HOME/.config/sops/age/keys.txt"
    exit 1
  fi
fi

# Create backup
if [ "$NO_BACKUP" = false ]; then
  BACKUP_FILE="${SECRETS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$SECRETS_FILE" "$BACKUP_FILE"
  success "Backup created: $BACKUP_FILE"
fi

# Edit with SOPS
info "Opening secrets.yaml in SOPS editor..."
echo ""

if sops "$SECRETS_FILE"; then
  success "Secrets updated successfully"
  echo ""
  info "Next steps:"
  echo "  1. Verify changes: ./scripts/secrets/view-secrets.sh"
  echo "  2. Rebuild system: nix-rebuild && exec zsh"
else
  error "SOPS editor exited with error"
  if [ "$NO_BACKUP" = false ]; then
    warning "Backup available at: $BACKUP_FILE"
  fi
  exit 1
fi
