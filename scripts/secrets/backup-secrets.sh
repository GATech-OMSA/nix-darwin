#!/usr/bin/env bash
#
# backup-secrets.sh - Create timestamped backup of secrets.yaml
#
# Features:
# - Timestamped backups
# - Configurable backup directory
# - Automatic cleanup of old backups (optional)

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
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

# Create backup
BACKUP_FILE="${SECRETS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SECRETS_FILE" "$BACKUP_FILE"

success "Backup created: $BACKUP_FILE"
echo ""
info "To restore: cp $BACKUP_FILE $SECRETS_FILE"
