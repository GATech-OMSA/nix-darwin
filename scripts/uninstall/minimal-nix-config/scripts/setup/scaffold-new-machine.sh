#!/usr/bin/env bash
# scaffold-new-machine.sh
#
# Quick setup guide for deploying minimal-nix-config on a new machine

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║                                                            ║${NC}"
echo -e "${BLUE}${BOLD}║         New Machine Setup - Minimal Nix-Darwin            ║${NC}"
echo -e "${BLUE}${BOLD}║                                                            ║${NC}"
echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "This wizard will help you set up minimal nix-darwin on a new machine."
echo ""

# Step 1: Check prerequisites
echo -e "${CYAN}Step 1: Checking Prerequisites${NC}"
echo "─────────────────────────────────"
echo ""

MISSING=0

# Check Nix
if command -v nix &> /dev/null; then
    nix_version=$(nix --version | head -1)
    echo -e "  ${GREEN}✓${NC} Nix installed: $nix_version"
else
    echo -e "  ${YELLOW}✗${NC} Nix not installed"
    MISSING=$((MISSING + 1))
fi

# Check nix-darwin
if command -v darwin-rebuild &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} nix-darwin installed"
else
    echo -e "  ${YELLOW}✗${NC} nix-darwin not installed"
    MISSING=$((MISSING + 1))
fi

# Check Homebrew (optional)
if command -v brew &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Homebrew installed"
else
    echo -e "  ${CYAN}ℹ${NC} Homebrew not installed (optional)"
fi

echo ""

if [ $MISSING -gt 0 ]; then
    echo -e "${YELLOW}Missing $MISSING prerequisite(s).${NC}"
    echo ""
    echo "Install missing components:"
    echo ""

    if ! command -v nix &> /dev/null; then
        echo "1. Install Nix (Determinate Systems installer):"
        echo "   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
        echo ""
    fi

    if ! command -v darwin-rebuild &> /dev/null; then
        echo "2. Install nix-darwin:"
        echo "   nix run nix-darwin -- switch --flake ${CONFIG_ROOT}"
        echo ""
    fi

    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    echo ""
fi

# Step 2: Configure
echo -e "${CYAN}Step 2: Machine Configuration${NC}"
echo "──────────────────────────────────"
echo ""

if [ -f "${CONFIG_ROOT}/config/user-config.nix" ] && [ -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    echo "Existing configuration found."
    echo ""
    cat "${CONFIG_ROOT}/config/machine-config.nix" 2>/dev/null | grep -E "machineId|machineType|description" | sed 's/^/  /'
    echo ""
    read -p "Reconfigure? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        "${CONFIG_ROOT}/scripts/setup/configure.sh"
    fi
else
    echo "Running configuration wizard..."
    echo ""
    "${CONFIG_ROOT}/scripts/setup/configure.sh"
fi

echo ""

# Step 3: Customize
echo -e "${CYAN}Step 3: Customize Configuration (Optional)${NC}"
echo "───────────────────────────────────────────────"
echo ""
echo "You can now customize your configuration:"
echo ""
echo "  • Add packages:      vim ${CONFIG_ROOT}/modules/shared/packages.nix"
echo "  • Add GUI apps:      vim ${CONFIG_ROOT}/modules/darwin/homebrew.nix"
echo "  • System settings:   vim ${CONFIG_ROOT}/modules/darwin/system.nix"
echo "  • Fonts:             vim ${CONFIG_ROOT}/modules/darwin/fonts.nix"
echo ""

read -p "Customize now? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Which file would you like to edit?"
    echo "  1. packages.nix (CLI tools)"
    echo "  2. homebrew.nix (GUI apps)"
    echo "  3. system.nix (macOS settings)"
    echo "  4. Skip"
    echo ""
    read -p "Choice [1-4]: " -n 1 choice
    echo ""
    echo ""

    case $choice in
        1)
            ${EDITOR:-vim} "${CONFIG_ROOT}/modules/shared/packages.nix"
            ;;
        2)
            ${EDITOR:-vim} "${CONFIG_ROOT}/modules/darwin/homebrew.nix"
            ;;
        3)
            ${EDITOR:-vim} "${CONFIG_ROOT}/modules/darwin/system.nix"
            ;;
    esac
fi

echo ""

# Step 4: Activate
echo -e "${CYAN}Step 4: Activate Configuration${NC}"
echo "────────────────────────────────────"
echo ""
echo "Ready to apply your configuration!"
echo ""

read -p "Apply now? (Y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    "${CONFIG_ROOT}/scripts/setup/activate.sh"
else
    echo ""
    echo "Skipped activation."
    echo ""
    echo "To activate later:"
    echo "  ${CONFIG_ROOT}/scripts/setup/activate.sh"
fi

echo ""

# Summary
echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                                                            ║${NC}"
echo -e "${GREEN}${BOLD}║                    Setup Complete!                         ║${NC}"
echo -e "${GREEN}${BOLD}║                                                            ║${NC}"
echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your minimal nix-darwin is configured at:"
echo "  ${CONFIG_ROOT}"
echo ""
echo "Next steps:"
echo "  1. Restart your shell:      exec zsh"
echo "  2. Test configuration:      darwin-rebuild switch --flake ${CONFIG_ROOT}"
echo "  3. Set up workspace backup: ${CONFIG_ROOT}/scripts/workspace/backup.sh"
echo ""
echo "Useful commands:"
echo "  • Health check:    ${CONFIG_ROOT}/scripts/maintenance/health-check.sh"
echo "  • Add packages:    Edit ${CONFIG_ROOT}/modules/shared/packages.nix"
echo "  • Documentation:   ${CONFIG_ROOT}/README.md"
echo ""
