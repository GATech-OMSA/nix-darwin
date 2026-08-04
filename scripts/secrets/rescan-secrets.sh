#!/usr/bin/env bash
#
# rescan-secrets.sh - Discover potential secrets on the filesystem
#
# Read-only scanner that finds credential files and shows what could be
# added to secrets.yaml. Does NOT modify any files — use secrets-edit
# to manually add entries.
#
# Usage:
#   secrets-rescan              # Scan with defaults
#   secrets-rescan --depth 3    # Limit scan depth
#   secrets-rescan --help       # Show help

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
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner
SCAN_DEPTH="${SECRET_SCAN_DEPTH:-4}"

# Common exclusions for find
EXCLUDES=(
  ! -path "*/.Trash/*"
  ! -path "*/Library/Caches/*"
  ! -path "*/Library/Logs/*"
  ! -path "*/.cache/*"
  ! -path "*/tmp/*"
  ! -path "*/node_modules/*"
  ! -path "*/.venv/*"
  ! -path "*/venv/*"
  ! -path "*/__pycache__/*"
  ! -path "*/.git/*"
  ! -path "*/dist/*"
  ! -path "*/build/*"
  ! -path "*/target/*"
  ! -path "*/backup/*"
)

print_usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Read-only scanner that discovers potential secrets on the filesystem.
Shows what could be added to secrets.yaml — does NOT modify any files.

OPTIONS:
  -h, --help              Show this help message
  -d, --depth NUM         Scan depth (default: 4 levels)

EXAMPLES:
  secrets-rescan              # Standard scan
  secrets-rescan --depth 2    # Shallow scan

To add discovered secrets:
  secrets-edit                # Manually add to encrypted secrets.yaml

EOF
}

# Parse arguments
all_args=("$@")
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) print_usage; exit 0 ;;
    -d|--depth) SCAN_DEPTH="$2"; shift 2 ;;
    *) error "Unknown option: $1"; print_usage; exit 1 ;;
  esac
done

run_banner "rescan-secrets" "depth=$SCAN_DEPTH" "${all_args[@]}"

# ==============================================================================
# KNOWN DEPLOY TARGETS (from deploy-secrets.sh)
# Files written by secrets-deploy — skip these to avoid loop
# ==============================================================================

declare -A DEPLOY_TARGETS
DEPLOY_TARGETS=(
  ["$HOME/.zsh_secrets"]=1
  ["$HOME/.ssh/id_ed25519"]=1
  ["$HOME/.ssh/id_ed25519.pub"]=1
  ["$HOME/.ssh/id_ed25519_work"]=1
  ["$HOME/.ssh/id_ed25519_work.pub"]=1
  ["$HOME/.ssh/id_rsa_work"]=1
  ["$HOME/.ssh/id_rsa_work.pub"]=1
  ["$HOME/.aws/credentials"]=1
  ["$HOME/.aws/accounts.json"]=1
)

is_deploy_target() {
  [[ -n "${DEPLOY_TARGETS[$1]:-}" ]]
}

# ==============================================================================
# SCAN
# ==============================================================================

echo ""
info "Scanning for potential secrets (depth: $SCAN_DEPTH)..."
echo ""

found=0

print_finding() {
  local category="$1"
  local path="$2"

  if is_deploy_target "$path"; then
    return  # Skip files managed by secrets-deploy
  fi

  local size=$(stat -f%z "$path" 2>/dev/null || echo "?")
  local perms=$(stat -f%Lp "$path" 2>/dev/null || echo "?")

  echo -e "  ${YELLOW}${category}${NC}"
  echo -e "    Path: $path"
  echo -e "    ${DIM}Size: ${size}B  Perms: ${perms}${NC}"
  echo ""
  found=$(( found + 1 ))
}

# --- Database credentials ---
if [ -d "$HOME/.db" ]; then
  while IFS= read -r -d '' file; do
    print_finding "Database credential" "$file"
  done < <(find "$HOME/.db" -maxdepth "$SCAN_DEPTH" -type f "${EXCLUDES[@]}" -print0 2>/dev/null)
fi

# --- API tokens ---
if [ -d "$HOME/.tokens" ]; then
  while IFS= read -r -d '' file; do
    print_finding "API token" "$file"
  done < <(find "$HOME/.tokens" -maxdepth "$SCAN_DEPTH" -type f "${EXCLUDES[@]}" -print0 2>/dev/null)
fi

# --- Credentials ---
if [ -d "$HOME/.credentials" ]; then
  while IFS= read -r -d '' file; do
    print_finding "Credential" "$file"
  done < <(find "$HOME/.credentials" -maxdepth "$SCAN_DEPTH" -type f "${EXCLUDES[@]}" -print0 2>/dev/null)
fi

# --- .env files (exclude .envrc which is direnv config) ---
while IFS= read -r -d '' file; do
  print_finding "Environment file" "$file"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  \( -name ".env" -o -name ".env.*" \) \
  ! -name ".envrc" \
  "${EXCLUDES[@]}" \
  -print0 2>/dev/null)

# --- Certificates ---
while IFS= read -r -d '' file; do
  print_finding "Certificate" "$file"
done < <(find "$HOME" -maxdepth "$SCAN_DEPTH" -type f \
  \( -name "*.pem" -o -name "*.p12" -o -name "*.pfx" \) \
  ! -name "cacert.pem" \
  "${EXCLUDES[@]}" \
  -print0 2>/dev/null | head -z -n 10)

# --- Private keys (not managed by deploy) ---
while IFS= read -r -d '' file; do
  print_finding "Private key" "$file"
done < <(find "$HOME/.ssh" "$HOME/.gnupg" -maxdepth 2 -type f \
  \( -name "*.key" -o -name "id_*" \) \
  ! -name "*.pub" \
  "${EXCLUDES[@]}" \
  -print0 2>/dev/null)

# ==============================================================================
# SUMMARY
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$found" -eq 0 ]; then
  success "No unmanaged secrets found."
else
  warning "Found $found potential secret(s) not managed by secrets-deploy"
  echo ""
  echo "  To add to secrets management:"
  echo "    1. secrets-edit          # Add key + content to secrets.yaml"
  echo "    2. Add mapping to scripts/secrets/deploy-secrets.sh"
  echo "    3. secrets-deploy        # Deploy to target path"
fi
echo ""
