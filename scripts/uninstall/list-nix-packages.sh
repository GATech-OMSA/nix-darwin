#!/usr/bin/env bash
# list-nix-packages.sh
#
# Lists all packages managed by Nix and provides cleanup options

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLEANUP=${1:-false}

echo -e "${BLUE}=== Nix-Managed Packages ===${NC}"
echo ""

# Function to list packages from Nix
list_nix_packages() {
    echo -e "${YELLOW}System packages (from nix-darwin):${NC}"
    echo ""

    # Get packages from current system profile
    if [ -e /run/current-system/sw/bin ]; then
        echo "  Installed binaries:"
        ls /run/current-system/sw/bin | head -20
        total=$(ls /run/current-system/sw/bin | wc -l | tr -d ' ')
        echo "  ... (${total} total commands available)"
        echo ""
    fi

    # List key packages defined in our config
    echo -e "${YELLOW}Key packages from nix-config/modules/shared/packages.nix:${NC}"
    echo ""

    # Parse the packages.nix file
    if [ -f "/Users/jimmy/nix-darwin/nix-config/modules/shared/packages.nix" ]; then
        grep -E '^\s+pkgs\.' /Users/jimmy/nix-darwin/nix-config/modules/shared/packages.nix | \
            sed 's/^\s*/  /' | \
            head -30
        echo "  ..."
        echo ""
    fi
}

# Function to list Homebrew packages
list_homebrew_packages() {
    echo -e "${YELLOW}Homebrew packages:${NC}"
    echo ""

    if command -v brew &>/dev/null; then
        echo "  CLI tools:"
        brew list | head -20
        total_formulae=$(brew list | wc -l | tr -d ' ')
        echo "  ... (${total_formulae} total formulae)"
        echo ""

        echo "  GUI applications:"
        brew list --cask | head -20
        total_casks=$(brew list --cask | wc -l | tr -d ' ')
        echo "  ... (${total_casks} total casks)"
        echo ""
    else
        echo "  Homebrew not installed"
        echo ""
    fi
}

# Function to categorize packages
categorize_packages() {
    echo -e "${CYAN}=== Package Categorization ===${NC}"
    echo ""

    echo -e "${YELLOW}Development Tools (Nix):${NC}"
    echo "  git, gh, awscli2, jq, yq, sops, age"
    echo "  node, python3, rustc, cargo"
    echo ""

    echo -e "${YELLOW}Shell & Terminal (Nix):${NC}"
    echo "  zsh, starship, eza, bat, fd, ripgrep, fzf"
    echo "  zoxide, direnv, tmux"
    echo ""

    echo -e "${YELLOW}System Utilities (Nix):${NC}"
    echo "  curl, wget, htop, tree, watch"
    echo "  coreutils, findutils, gnugrep, gnused"
    echo ""

    echo -e "${YELLOW}GUI Applications (Homebrew):${NC}"
    if command -v brew &>/dev/null; then
        brew list --cask | sed 's/^/  /'
    fi
    echo ""
}

# Main listing
list_nix_packages
list_homebrew_packages
categorize_packages

# Cleanup option
if [ "$CLEANUP" = "true" ]; then
    echo -e "${RED}=== Package Cleanup ===${NC}"
    echo ""
    echo -e "${YELLOW}This will help you remove Nix-managed packages.${NC}"
    echo ""
    echo "Options:"
    echo "  1. Keep all Nix packages (recommended)"
    echo "  2. Keep only essential tools (git, curl, etc.)"
    echo "  3. Remove all Nix packages (keep Homebrew)"
    echo "  4. Cancel"
    echo ""
    read -p "Choose option (1-4): " -n 1 -r choice
    echo ""
    echo ""

    case $choice in
        1)
            echo -e "${GREEN}✓ Keeping all Nix packages${NC}"
            echo ""
            echo "You can continue using Nix for package management."
            echo "Just switch to the minimal config to stop managing dotfiles."
            ;;
        2)
            echo -e "${YELLOW}Keeping essential tools only${NC}"
            echo ""
            echo "Essential packages to keep:"
            echo "  - git, gh"
            echo "  - curl, wget"
            echo "  - jq, yq"
            echo "  - awscli2"
            echo ""
            echo "All other packages will be available via Homebrew fallback."
            echo ""
            echo "To implement this, edit the minimal-nix-config and rebuild."
            ;;
        3)
            echo -e "${RED}⚠ Removing all Nix packages${NC}"
            echo ""
            echo "This will:"
            echo "  1. Switch to an empty nix-darwin config"
            echo "  2. Run garbage collection"
            echo "  3. Remove all Nix-managed packages"
            echo ""
            echo "Homebrew packages will be unaffected."
            echo ""
            echo "To implement this:"
            echo "  1. Use the minimal-nix-config (empty packages list)"
            echo "  2. Run: darwin-rebuild switch --flake ."
            echo "  3. Run: nix-collect-garbage -d"
            ;;
        4)
            echo "Cancelled."
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    echo ""
fi

echo -e "${BLUE}=== Summary ===${NC}"
echo ""
echo "Your current setup:"
echo "  • Nix-managed CLI tools and development packages"
echo "  • Homebrew-managed GUI applications"
echo "  • Both can coexist happily"
echo ""
echo "After rollback, you can:"
echo "  • Keep Nix for package management only"
echo "  • Use Homebrew for everything"
echo "  • Mix and match as needed"
echo ""
