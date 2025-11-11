#!/usr/bin/env bash
#
# rescan-secrets.sh - Rescan system for secrets and merge with existing secrets.yaml
#
# Features:
# - Comprehensive secret scanning (3-4 levels deep)
# - Smart deduplication (checks both name AND path)
# - Safe merge with existing secrets
# - Timestamped backups before changes
# - Interactive preview and confirmation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default configuration
SCAN_DEPTH="${SECRET_SCAN_DEPTH:-4}"
DRY_RUN=false
INTERACTIVE=true

# Helper functions
info() { echo -e "${BLUE}ℹ ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*" >&2; }

print_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Rescan system for secrets and intelligently merge with existing secrets.yaml

OPTIONS:
  -h, --help              Show this help message
  -d, --depth NUM         Scan depth (default: 4 levels)
  -y, --yes               Skip confirmation prompts
  --dry-run              Show what would be done without making changes
  -m, --machine-id ID     Specify machine ID (auto-detected if not provided)

EXAMPLES:
  # Interactive rescan with preview
  ./rescan-secrets.sh

  # Scan 3 levels deep, auto-confirm
  ./rescan-secrets.sh --depth 3 --yes

  # Dry run to see what would be discovered
  ./rescan-secrets.sh --dry-run

DEDUPLICATION:
  - Skips if secret name already exists
  - Skips if secret path already exists
  - Only appends genuinely new secrets

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_usage
      exit 0
      ;;
    -d|--depth)
      SCAN_DEPTH="$2"
      shift 2
      ;;
    -y|--yes)
      INTERACTIVE=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -m|--machine-id)
      MACHINE_ID="$2"
      shift 2
      ;;
    *)
      error "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

# Auto-detect machine ID from config if not provided
if [ -z "${MACHINE_ID:-}" ]; then
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    MACHINE_ID=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
    info "Auto-detected machine ID: $MACHINE_ID"
  else
    error "Could not detect machine ID. Please specify with --machine-id"
    exit 1
  fi
fi

# Validate machine ID
SECRETS_DIR="$REPO_ROOT/nix-config/hosts/$MACHINE_ID"
SECRETS_FILE="$SECRETS_DIR/secrets.yaml"

if [ ! -d "$SECRETS_DIR" ]; then
  error "Machine directory not found: $SECRETS_DIR"
  exit 1
fi

if [ ! -f "$SECRETS_FILE" ]; then
  error "Secrets file not found: $SECRETS_FILE"
  info "Expected: $SECRETS_FILE"
  exit 1
fi

# Check for SOPS
if ! command -v sops &>/dev/null; then
  error "SOPS not found. Please install SOPS first:"
  echo "  nix-shell -p sops"
  exit 1
fi

info "Secret Management v2.0 - Rescan & Merge"
echo ""
info "Configuration:"
echo "  Machine ID: $MACHINE_ID"
echo "  Secrets file: $SECRETS_FILE"
echo "  Scan depth: $SCAN_DEPTH levels"
echo "  Dry run: $DRY_RUN"
echo ""

# ==== Step 1: Decrypt existing secrets ====

info "Step 1: Decrypting existing secrets..."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

DECRYPTED_FILE="$TEMP_DIR/secrets-decrypted.yaml"

if ! sops -d "$SECRETS_FILE" > "$DECRYPTED_FILE" 2>/dev/null; then
  error "Failed to decrypt secrets.yaml"
  echo ""
  echo "Possible causes:"
  echo "  • SOPS age key not configured"
  echo "  • SOPS_AGE_KEY_FILE environment variable not set"
  echo "  • Age key file doesn't exist"
  echo ""
  echo "Fix:"
  echo "  export SOPS_AGE_KEY_FILE=\$HOME/.config/sops/age/keys.txt"
  exit 1
fi

success "Decrypted secrets.yaml"
echo ""

# ==== Step 2: Load existing secrets into memory ====

info "Step 2: Loading existing secrets..."

declare -A existing_names
declare -A existing_paths
existing_count=0

# Parse existing secrets (extract name and path)
while IFS=: read -r key value; do
  # Skip comments and empty lines
  [[ "$key" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$key" ]] && continue

  # Extract secret name (key before colon)
  secret_name=$(echo "$key" | tr -d ' ' | tr -d '\t')

  # Extract path from value (if it contains a path)
  if [[ "$value" =~ (\/[^[:space:]]+) ]]; then
    secret_path="${BASH_REMATCH[1]}"
    existing_paths["$secret_path"]=1
  fi

  if [ -n "$secret_name" ]; then
    existing_names["$secret_name"]=1
    ((existing_count++)) || true
  fi
done < "$DECRYPTED_FILE"

success "Loaded $existing_count existing secrets"
echo ""

# ==== Step 3: Scan for new secrets ====

info "Step 3: Scanning for new secrets (depth: $SCAN_DEPTH)..."
echo ""

discovered_secrets=()
new_secrets=()
duplicate_count=0

# Use same scanning logic as configure.sh
scan_and_dedupe() {
  local category="$1"
  local path="$2"
  local name_key="$3"

  # Generate a secret name key (for deduplication)
  local secret_key="${name_key}"

  # Check if name already exists
  if [[ -n "${existing_names[$secret_key]:-}" ]]; then
    ((duplicate_count++)) || true
    return
  fi

  # Check if path already exists
  if [[ -n "${existing_paths[$path]:-}" ]]; then
    ((duplicate_count++)) || true
    return
  fi

  # New secret discovered
  discovered_secrets+=("$category:$name_key:$path")
  new_secrets+=("$name_key: $path")
}

# Scan known directories
if [ -d "$HOME/.db" ]; then
  while IFS= read -r -d '' file; do
    basename_file=$(basename "$file")
    scan_and_dedupe "Database credential" "$file" "db_${basename_file//[^a-zA-Z0-9_]/_}"
  done < <(find "$HOME/.db" -maxdepth "$SCAN_DEPTH" -type f -print0 2>/dev/null)
fi

if [ -d "$HOME/.tokens" ]; then
  while IFS= read -r -d '' file; do
    basename_file=$(basename "$file")
    scan_and_dedupe "API token" "$file" "token_${basename_file//[^a-zA-Z0-9_]/_}"
  done < <(find "$HOME/.tokens" -maxdepth "$SCAN_DEPTH" -type f -print0 2>/dev/null)
fi

if [ -d "$HOME/.credentials" ]; then
  while IFS= read -r -d '' file; do
    basename_file=$(basename "$file")
    scan_and_dedupe "Credential" "$file" "cred_${basename_file//[^a-zA-Z0-9_]/_}"
  done < <(find "$HOME/.credentials" -maxdepth "$SCAN_DEPTH" -type f -print0 2>/dev/null)
fi

# Scan .env files
while IFS= read -r -d '' env_file; do
  basename_file=$(basename "$env_file")
  scan_and_dedupe "Environment file" "$env_file" "env_${basename_file//[^a-zA-Z0-9_]/_}"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  \( -name ".env" -o -name ".env.*" -o -name ".envrc" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  -print0 2>/dev/null)

# Scan wildcard patterns (limit to 10 each to avoid spam)
while IFS= read -r -d '' file; do
  basename_file=$(basename "$file")
  scan_and_dedupe "Secret file" "$file" "secret_${basename_file//[^a-zA-Z0-9_]/_}"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  -iname "*secret*" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -name "*.md" \
  -print0 2>/dev/null | head -z -n 10)

while IFS= read -r -d '' file; do
  basename_file=$(basename "$file")
  scan_and_dedupe "Credential file" "$file" "credential_${basename_file//[^a-zA-Z0-9_]/_}"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  -iname "*credential*" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -name "*.md" \
  -print0 2>/dev/null | head -z -n 10)

# Certificates
while IFS= read -r -d '' file; do
  basename_file=$(basename "$file")
  scan_and_dedupe "Certificate" "$file" "cert_${basename_file//[^a-zA-Z0-9_]/_}"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  \( -name "*.pem" -o -name "*.p12" -o -name "*.pfx" -o -name "*.key" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  -print0 2>/dev/null | head -z -n 10)

# ==== Step 4: Display results ====

info "Scan complete!"
echo ""
echo "Results:"
echo "  Existing secrets: $existing_count"
echo "  New discoveries: ${#new_secrets[@]}"
echo "  Duplicates skipped: $duplicate_count"
echo ""

if [ ${#new_secrets[@]} -eq 0 ]; then
  success "No new secrets found. Your secrets.yaml is up to date!"
  exit 0
fi

warning "New secrets discovered:"
echo ""
for secret in "${new_secrets[@]}"; do
  echo "  + $secret"
done
echo ""

# ==== Step 5: Confirm merge ====

if [ "$DRY_RUN" = true ]; then
  info "[DRY RUN] Would append ${#new_secrets[@]} new secrets to $SECRETS_FILE"
  exit 0
fi

if [ "$INTERACTIVE" = true ]; then
  echo -n "Append these ${#new_secrets[@]} secrets to secrets.yaml? [y/N] "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    warning "Operation cancelled by user"
    exit 0
  fi
fi

# ==== Step 6: Create backup ====

info "Step 6: Creating backup..."

BACKUP_FILE="${SECRETS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SECRETS_FILE" "$BACKUP_FILE"

success "Backup created: $BACKUP_FILE"
echo ""

# ==== Step 7: Merge secrets ====

info "Step 7: Merging new secrets..."

# Append new secrets to decrypted file
echo "" >> "$DECRYPTED_FILE"
echo "# New secrets discovered by rescan-secrets.sh on $(date)" >> "$DECRYPTED_FILE"

for secret_entry in "${discovered_secrets[@]}"; do
  IFS=: read -r category name_key path <<< "$secret_entry"
  echo "$name_key: $path  # $category" >> "$DECRYPTED_FILE"
done

success "Merged ${#new_secrets[@]} new secrets"
echo ""

# ==== Step 8: Re-encrypt with SOPS ====

info "Step 8: Re-encrypting secrets.yaml..."

if ! sops -e "$DECRYPTED_FILE" > "$SECRETS_FILE" 2>/dev/null; then
  error "Failed to re-encrypt secrets.yaml"
  warning "Your original file is backed up at: $BACKUP_FILE"
  exit 1
fi

success "Re-encrypted secrets.yaml successfully"
echo ""

# ==== Summary ====

success "✓ Rescan complete!"
echo ""
echo "Summary:"
echo "  • Added ${#new_secrets[@]} new secrets"
echo "  • Backup: $BACKUP_FILE"
echo "  • Updated: $SECRETS_FILE"
echo ""
info "Next steps:"
echo "  1. Review the updated secrets: scripts/secrets/view-secrets.sh"
echo "  2. Edit if needed: scripts/secrets/edit-secrets.sh"
echo "  3. Rebuild system: nix-rebuild && exec zsh"
