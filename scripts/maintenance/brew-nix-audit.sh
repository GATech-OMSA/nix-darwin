#!/usr/bin/env bash
#
# Brew-to-Nix Audit
#
# Compares installed Homebrew packages with available Nix packages
# to identify opportunities for migrating to a declarative setup.
#

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner

# ============================================
# COLORS
# ============================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

run_banner "brew-nix-audit" "(none)" "$@"

echo -e "${BLUE}Auditing Homebrew packages for Nix alternatives...${NC}\n"

if ! command -v brew &> /dev/null; then
  echo "error: homebrew not found."
  exit 1
fi

# Get list of brew-installed formulae (not casks)
echo "Fetching Homebrew formulae..."
brew_pkgs=$(brew leaves)
total_brew=$(echo "$brew_pkgs" | wc -l | xargs)

echo "Checking $total_brew packages in Nixpkgs..."
echo "------------------------------------------------"

match_count=0
while read -r pkg; do
  # Search nixpkgs for exact match
  if nix-env -qaP ".*${pkg}.*" &>/dev/null; then
    echo -e "${GREEN}Match found:${NC} $pkg"
    ((match_count++))
  else
    echo -e "${YELLOW}No exact match:${NC} $pkg"
  fi
done <<< "$brew_pkgs"

echo "------------------------------------------------"
echo -e "\n${BLUE}Audit Results:${NC}"
echo "   • Total Brew Packages: $total_brew"
echo "   • Nix Alternatives Found: $match_count"
echo ""
echo "   To migrate a package:"
echo "   1. Add it to nix-config/modules/shared/packages.nix"
echo "   2. Remove it from nix-config/modules/darwin/homebrew.nix (if present)"
echo "   3. Run: nix-rebuild"
echo "   4. Run: brew uninstall $pkg"
