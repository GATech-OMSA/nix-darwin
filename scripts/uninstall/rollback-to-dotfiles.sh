#!/usr/bin/env bash
# rollback-to-dotfiles.sh
#
# Main orchestrator for rolling back from nix-darwin to traditional dotfiles
#
# Usage:
#   ./rollback-to-dotfiles.sh              # Interactive mode
#   ./rollback-to-dotfiles.sh --dry-run    # Preview changes
#   ./rollback-to-dotfiles.sh --cleanup    # Include package cleanup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
DRY_RUN=false
CLEANUP_PACKAGES=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --cleanup-packages)
            CLEANUP_PACKAGES=true
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run           Preview changes without making them"
            echo "  --cleanup-packages  Interactive package cleanup"
            echo "  --help              Show this help"
            exit 0
            ;;
    esac
done

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║            Nix-Darwin → Traditional Dotfiles                  ║
║                                                               ║
║  This will convert your declarative config to static files    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}${BOLD}DRY RUN MODE${NC} - No changes will be made"
    echo ""
fi

# Explain what will happen
echo -e "${CYAN}What this script does:${NC}"
echo ""
echo "  ✅ Keeps Nix package manager installed"
echo "  ✅ Keeps all apps (Nix + Homebrew)"
echo "  ✅ Converts configs to real files (not symlinks)"
echo "  ✅ Creates backups of everything"
echo ""
echo "  🔄 Changes:"
echo "     • ~/.zshrc: Nix-managed → Real file you can edit"
echo "     • ~/.gitconfig: Nix-managed → Real file"
echo "     • AWS/SSH configs: Nix-managed → Real files"
echo "     • Secrets: Encrypted → Decrypted plain files"
echo ""
echo "  📦 After rollback:"
echo "     • You edit files directly (no more nix-rebuild)"
echo "     • Nix still available for packages"
echo "     • Can switch back anytime"
echo ""

if [ "$DRY_RUN" = "false" ]; then
    echo -e "${YELLOW}${BOLD}⚠️  This will modify your system${NC}"
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    echo ""
fi

# Phase 1: Backup
echo -e "${BLUE}${BOLD}═══ Phase 1: Backup Current State ═══${NC}"
echo ""

if [ "$DRY_RUN" = "false" ]; then
    BACKUP_DIR=$("${SCRIPT_DIR}/backup-current-state.sh")
    echo ""
    echo -e "${GREEN}✓ Backup complete${NC}"
    echo "  Location: ${BACKUP_DIR}"
else
    echo "Would create backup in ~/.nix-darwin-backup-TIMESTAMP"
fi

echo ""
read -p "Press Enter to continue..."
echo ""

# Phase 2: Configure minimal nix location
echo -e "${BLUE}${BOLD}═══ Phase 2: Configure Minimal Nix Location ═══${NC}"
echo ""

echo "Your configs (especially .zshrc) reference the nix-darwin directory for"
echo "commands like 'nix-rebuild', 'nixconf', etc."
echo ""
echo "After rollback, these should point to your minimal nix config instead."
echo ""

if [ "$DRY_RUN" = "false" ]; then
    echo -e "${CYAN}Where would you like to keep your minimal nix-darwin config?${NC}"
    echo ""
    echo "Suggested locations:"
    echo "  1. ~/.nix-darwin-minimal (default, hidden)"
    echo "  2. ~/nix-darwin-minimal (visible in home)"
    echo "  3. ~/.config/nix-darwin (XDG standard)"
    echo "  4. Custom path"
    echo ""
    read -p "Enter path [default: ~/.nix-darwin-minimal]: " MINIMAL_NIX_DIR

    if [ -z "$MINIMAL_NIX_DIR" ]; then
        MINIMAL_NIX_DIR="${HOME}/.nix-darwin-minimal"
    else
        # Expand ~ if present
        MINIMAL_NIX_DIR="${MINIMAL_NIX_DIR/#\~/$HOME}"
    fi

    echo ""
    echo -e "${GREEN}✓ Will use: ${MINIMAL_NIX_DIR}${NC}"
else
    MINIMAL_NIX_DIR="${HOME}/.nix-darwin-minimal"
    echo "Would use: ${MINIMAL_NIX_DIR}"
fi

echo ""
read -p "Press Enter to continue..."
echo ""

# Phase 3: Show current packages
echo -e "${BLUE}${BOLD}═══ Phase 3: Package Inventory ═══${NC}"
echo ""

"${SCRIPT_DIR}/list-nix-packages.sh" false

echo ""
read -p "Press Enter to continue..."
echo ""

# Phase 4: Materialize configs
echo -e "${BLUE}${BOLD}═══ Phase 4: Materialize Configurations ═══${NC}"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    "${SCRIPT_DIR}/materialize-configs.sh" true "$MINIMAL_NIX_DIR"
else
    MATERIAL_DIR=$("${SCRIPT_DIR}/materialize-configs.sh" false "$MINIMAL_NIX_DIR")
    echo ""
    echo -e "${GREEN}✓ Configs materialized${NC}"
    echo "  Location: ${MATERIAL_DIR}"
fi

echo ""
read -p "Press Enter to continue..."
echo ""

# Phase 5: Review and confirm
echo -e "${BLUE}${BOLD}═══ Phase 5: Review Changes ═══${NC}"
echo ""

echo "Summary of changes:"
echo ""
echo "  📁 Backups created:"
if [ "$DRY_RUN" = "false" ]; then
    echo "     ${BACKUP_DIR}"
else
    echo "     ~/.nix-darwin-backup-TIMESTAMP"
fi
echo ""
echo "  📝 Configs to install:"
if [ "$DRY_RUN" = "false" ]; then
    echo "     ${MATERIAL_DIR}"
    echo "     (includes .zshrc.original + modified .zshrc)"
else
    echo "     ~/.materialized-configs-TIMESTAMP"
fi
echo ""
echo "  🔧 Minimal Nix location:"
echo "     ${MINIMAL_NIX_DIR}"
echo ""
echo "  📋 Next steps:"
echo "     1. Install materialized configs"
echo "     2. Set up minimal nix-darwin at chosen location"
echo "     3. Restart shell"
echo "     4. Test everything (esp. nix-rebuild)"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN COMPLETE${NC}"
    echo ""
    echo "To actually perform the rollback:"
    echo "  ${SCRIPT_DIR}/rollback-to-dotfiles.sh"
    exit 0
fi

echo -e "${YELLOW}Ready to install configs?${NC}"
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Stopped before installation."
    echo ""
    echo "Your materialized configs are ready at:"
    echo "  ${MATERIAL_DIR}"
    echo ""
    echo "To install later:"
    echo "  ${MATERIAL_DIR}/INSTALL.sh"
    exit 0
fi

# Phase 6: Install configs
echo ""
echo -e "${BLUE}${BOLD}═══ Phase 6: Install Configs ═══${NC}"
echo ""

cd "${MATERIAL_DIR}"
./INSTALL.sh

echo ""
echo -e "${GREEN}✓ Configs installed${NC}"
echo ""
echo "Installed files:"
echo "  • ~/.zshrc          - Modified to use ${MINIMAL_NIX_DIR}"
echo "  • ~/.zshrc.original - Original from nix-darwin (reference)"
echo "  • Other dotfiles    - Materialized as-is"
echo ""

# Phase 7: Switch to minimal nix-darwin
echo -e "${BLUE}${BOLD}═══ Phase 7: Set Up Minimal Nix Config ═══${NC}"
echo ""

echo "Now we'll set up a minimal nix-darwin config at:"
echo "  ${MINIMAL_NIX_DIR}"
echo ""
echo "This config only manages packages, not dotfiles."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Copying minimal config to ${MINIMAL_NIX_DIR}..."
    mkdir -p "${MINIMAL_NIX_DIR}"
    cp -r "${SCRIPT_DIR}/minimal-nix-config"/* "${MINIMAL_NIX_DIR}/"

    echo ""
    echo -e "${GREEN}✓ Minimal config copied${NC}"
    echo ""
    echo "To switch to minimal config:"
    echo "  cd ${MINIMAL_NIX_DIR}"
    echo "  darwin-rebuild switch --flake ."
    echo ""
    echo -e "${YELLOW}Note: This will remove Home Manager and stop managing dotfiles${NC}"
    echo ""
    read -p "Run darwin-rebuild now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "${MINIMAL_NIX_DIR}"
        darwin-rebuild switch --flake .
        echo ""
        echo -e "${GREEN}✓ Switched to minimal config${NC}"
    else
        echo ""
        echo "Skipped. You can run it later:"
        echo "  cd ${MINIMAL_NIX_DIR} && darwin-rebuild switch --flake ."
    fi
else
    echo ""
    echo "Skipped minimal config setup."
    echo "You'll need to set this up manually for nix-rebuild to work."
    echo ""
    echo "Copy minimal config:"
    echo "  cp -r ${SCRIPT_DIR}/minimal-nix-config/* ${MINIMAL_NIX_DIR}/"
fi

# Phase 8: Package cleanup (optional)
if [ "$CLEANUP_PACKAGES" = "true" ]; then
    echo ""
    echo -e "${BLUE}${BOLD}═══ Phase 8: Package Cleanup ═══${NC}"
    echo ""
    "${SCRIPT_DIR}/list-nix-packages.sh" true
fi

# Done!
echo ""
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                                                               ║${NC}"
echo -e "${GREEN}${BOLD}║                  ✓ Rollback Complete!                         ║${NC}"
echo -e "${GREEN}${BOLD}║                                                               ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your system is now using traditional dotfiles."
echo ""
echo "What changed:"
echo "  ✓ ~/.zshrc is now a real file (edit directly)"
echo "  ✓ ~/.zshrc.original saved as reference"
echo "  ✓ ~/.gitconfig is now a real file"
echo "  ✓ All configs are now yours to manage"
echo "  ✓ Nix commands point to: ${MINIMAL_NIX_DIR}"
echo "  ✓ Nix is still installed and working"
echo ""
echo "Next steps:"
echo "  1. Restart your shell: exec zsh"
echo "  2. Test nix-rebuild (should use ${MINIMAL_NIX_DIR})"
echo "  3. Test other aliases and functions"
echo "  4. Manage dotfiles however you like (Git, etc.)"
echo ""
echo "Understanding your .zshrc files:"
echo "  • ~/.zshrc          - Active version (paths updated for minimal nix)"
echo "  • ~/.zshrc.original - Exact copy from nix-darwin (reference only)"
echo ""
echo "To restore nix-darwin declarative config:"
if [ "$DRY_RUN" = "false" ]; then
    echo "  ${BACKUP_DIR}/RESTORE.sh"
else
    echo "  ~/.nix-darwin-backup-TIMESTAMP/RESTORE.sh"
fi
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  • Minimal config: ${MINIMAL_NIX_DIR}/README.md"
echo "  • Materialized configs: ${MATERIAL_DIR}"
echo "  • Config info: ${MATERIAL_DIR}/CONFIG_INFO.txt"
echo "  • Backup location: ${BACKUP_DIR}"
echo ""
