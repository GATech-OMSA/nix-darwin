#!/usr/bin/env bash
# migrate-to-determinate.sh
#
# Migrate from official Nix to Determinate Systems Nix
# This script helps safely migrate while preserving your nix-darwin setup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

BACKUP_DIR="${HOME}/.nix-migration-backup-$(date +%Y%m%d-%H%M%S)"

clear
echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}${BOLD}║                                                              ║${NC}"
echo -e "${BLUE}${BOLD}║     Migrate from Official Nix to Determinate Systems        ║${NC}"
echo -e "${BLUE}${BOLD}║                                                              ║${NC}"
echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "This script will:"
echo "  1. Backup your current Nix state"
echo "  2. Document your current configuration"
echo "  3. Guide you through uninstalling official Nix"
echo "  4. Install Determinate Systems Nix"
echo "  5. Restore your nix-darwin configuration"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will temporarily remove Nix from your system${NC}"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# ============================================================
# PHASE 1: BACKUP & DOCUMENTATION
# ============================================================

echo -e "${CYAN}${BOLD}═══ Phase 1: Backup Current State ═══${NC}"
echo ""

mkdir -p "${BACKUP_DIR}"

echo "📦 Backing up current state to:"
echo "   ${BACKUP_DIR}"
echo ""

# Check current Nix version
echo "Current Nix installation:"
if command -v nix &> /dev/null; then
    nix --version | tee "${BACKUP_DIR}/nix-version.txt"

    # Check if it's already Determinate
    if nix --version | grep -q "Determinate"; then
        echo ""
        echo -e "${GREEN}You're already using Determinate Systems Nix!${NC}"
        echo ""
        echo "Nix version: $(cat ${BACKUP_DIR}/nix-version.txt)"
        exit 0
    fi
else
    echo -e "${RED}Nix not found!${NC}"
    exit 1
fi

echo ""

# Save current darwin-rebuild generations
echo "Saving darwin-rebuild generations..."
if command -v darwin-rebuild &> /dev/null; then
    darwin-rebuild --list-generations > "${BACKUP_DIR}/generations.txt" 2>&1 || true
    echo "  ✓ Saved to generations.txt"
else
    echo "  ⚠️  darwin-rebuild not found (will be reinstalled)"
fi

echo ""

# List currently installed packages
echo "Listing installed packages..."
nix-env -q > "${BACKUP_DIR}/user-packages.txt" 2>&1 || true
echo "  ✓ Saved to user-packages.txt"

echo ""

# Save current nix-darwin configuration
echo "Backing up nix-darwin configuration..."
if [ -d "/Users/jimmy/nix-darwin" ]; then
    # Just save the paths - the actual files stay in place
    echo "/Users/jimmy/nix-darwin" > "${BACKUP_DIR}/config-location.txt"

    # Save current machine config
    if [ -f "/Users/jimmy/nix-darwin/config/machine-config.nix" ]; then
        cp "/Users/jimmy/nix-darwin/config/machine-config.nix" "${BACKUP_DIR}/" 2>/dev/null || true
    fi

    if [ -f "/Users/jimmy/nix-darwin/config/user-config.nix" ]; then
        cp "/Users/jimmy/nix-darwin/config/user-config.nix" "${BACKUP_DIR}/" 2>/dev/null || true
    fi

    echo "  ✓ Configuration location saved"
else
    echo -e "  ${YELLOW}⚠️  nix-darwin not found at /Users/jimmy/nix-darwin${NC}"
fi

echo ""

# Save environment variables
echo "Saving Nix environment..."
env | grep -i nix > "${BACKUP_DIR}/nix-env-vars.txt" || true
echo "  ✓ Saved to nix-env-vars.txt"

echo ""
echo -e "${GREEN}✓ Backup complete!${NC}"
echo ""
echo "Backup location: ${BACKUP_DIR}"
echo ""

read -p "Press Enter to continue to Phase 2..."
echo ""

# ============================================================
# PHASE 2: UNINSTALL OFFICIAL NIX
# ============================================================

echo -e "${CYAN}${BOLD}═══ Phase 2: Uninstall Official Nix ═══${NC}"
echo ""

echo "The official Nix installer doesn't provide an uninstall script."
echo "We need to manually remove Nix components."
echo ""
echo -e "${YELLOW}This requires sudo access.${NC}"
echo ""

read -p "Proceed with uninstall? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. Your backup is at: ${BACKUP_DIR}"
    exit 0
fi

echo ""

# Stop nix-daemon
echo "1. Stopping nix-daemon..."
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true
echo "  ✓ Daemon stopped"

echo ""

# Remove Nix store
echo "2. Removing /nix directory..."
echo "   This may take a few minutes..."
if [ -d /nix ]; then
    sudo rm -rf /nix
    echo "  ✓ /nix removed"
else
    echo "  ℹ /nix not found"
fi

echo ""

# Remove build users
echo "3. Removing Nix build users..."
for i in $(seq 1 32); do
    sudo dscl . -delete "/Users/_nixbld$i" 2>/dev/null || true
done
echo "  ✓ Build users removed"

echo ""

# Remove Nix group
echo "4. Removing nixbld group..."
sudo dscl . -delete /Groups/nixbld 2>/dev/null || true
echo "  ✓ Group removed"

echo ""

# Remove launchd plists
echo "5. Removing launchd configurations..."
sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
sudo rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true
echo "  ✓ Launchd configs removed"

echo ""

# Remove nix profile
echo "6. Removing Nix profile..."
sudo rm -rf /etc/nix 2>/dev/null || true
rm -rf ~/.nix-profile 2>/dev/null || true
rm -rf ~/.nix-defexpr 2>/dev/null || true
rm -rf ~/.nix-channels 2>/dev/null || true
echo "  ✓ Profile removed"

echo ""

# Remove shell configurations
echo "7. Cleaning up shell configurations..."
if [ -f ~/.zshrc ]; then
    # Backup current .zshrc
    cp ~/.zshrc "${BACKUP_DIR}/zshrc.backup"

    # Remove Nix lines (they'll be re-added by Determinate installer)
    sed -i.bak '/# Nix/d' ~/.zshrc 2>/dev/null || true
    sed -i.bak '/nix-daemon/d' ~/.zshrc 2>/dev/null || true
    rm -f ~/.zshrc.bak

    echo "  ✓ Shell configs cleaned (backed up)"
fi

echo ""
echo -e "${GREEN}✓ Official Nix uninstalled!${NC}"
echo ""

read -p "Press Enter to continue to Phase 3..."
echo ""

# ============================================================
# PHASE 3: INSTALL DETERMINATE NIX
# ============================================================

echo -e "${CYAN}${BOLD}═══ Phase 3: Install Determinate Systems Nix ═══${NC}"
echo ""

echo "Installing Determinate Systems Nix..."
echo ""
echo "This installer:"
echo "  • Provides proper uninstall support"
echo "  • Enables flakes by default"
echo "  • Better macOS integration"
echo "  • Maintained by Determinate Systems"
echo ""

read -p "Install now? (Y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    echo ""
    echo "To install manually later:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    exit 0
fi

echo ""
echo "Downloading and running Determinate installer..."
echo ""

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

echo ""
echo -e "${GREEN}✓ Determinate Nix installed!${NC}"
echo ""

# Source nix to make it available in current shell
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Verify installation
echo "Verifying installation..."
if command -v nix &> /dev/null; then
    nix_version=$(nix --version)
    echo "  ✓ Nix installed: $nix_version"

    if echo "$nix_version" | grep -q "Determinate"; then
        echo -e "  ${GREEN}✓ Confirmed: Determinate Systems Nix${NC}"
    fi
else
    echo -e "  ${RED}✗ Nix command not found${NC}"
    echo ""
    echo "You may need to restart your shell:"
    echo "  exec zsh"
    exit 1
fi

echo ""

read -p "Press Enter to continue to Phase 4..."
echo ""

# ============================================================
# PHASE 4: RESTORE NIX-DARWIN
# ============================================================

echo -e "${CYAN}${BOLD}═══ Phase 4: Restore nix-darwin Configuration ═══${NC}"
echo ""

echo "Your nix-darwin configuration is preserved in:"
echo "  /Users/jimmy/nix-darwin"
echo ""
echo "We'll now rebuild from your existing configuration."
echo ""

if [ ! -d "/Users/jimmy/nix-darwin" ]; then
    echo -e "${RED}✗ nix-darwin directory not found!${NC}"
    echo ""
    echo "Your backup is at: ${BACKUP_DIR}"
    exit 1
fi

cd /Users/jimmy/nix-darwin

# Check flake exists
if [ ! -f "flake.nix" ]; then
    echo -e "${RED}✗ flake.nix not found!${NC}"
    exit 1
fi

echo "Rebuilding nix-darwin from your configuration..."
echo ""

# First-time rebuild with Determinate Nix
echo "Running initial darwin-rebuild..."
echo ""

# Set FLAKE_ROOT for gitignored config imports
export FLAKE_ROOT=/Users/jimmy/nix-darwin
sudo FLAKE_ROOT=/Users/jimmy/nix-darwin nix run nix-darwin -- switch --flake . --impure

echo ""
echo -e "${GREEN}✓ nix-darwin rebuilt successfully!${NC}"
echo ""

# ============================================================
# PHASE 5: VERIFICATION
# ============================================================

echo -e "${CYAN}${BOLD}═══ Phase 5: Verification ═══${NC}"
echo ""

echo "Checking system state..."
echo ""

# Check Nix version
echo "Nix version:"
nix --version
echo ""

# Check nix-darwin
if command -v darwin-rebuild &> /dev/null; then
    echo -e "${GREEN}✓${NC} darwin-rebuild available"

    # Show current generation
    current_gen=$(darwin-rebuild --list-generations | grep current || echo "unknown")
    echo "  Current generation: $current_gen"
else
    echo -e "${RED}✗${NC} darwin-rebuild not found"
fi

echo ""

# Check flakes are enabled
echo "Checking flakes support..."
if nix flake metadata . &>/dev/null; then
    echo -e "${GREEN}✓${NC} Flakes enabled and working"
else
    echo -e "${RED}✗${NC} Flakes not working"
fi

echo ""

# Summary
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                                                              ║${NC}"
echo -e "${GREEN}${BOLD}║            Migration Complete!                               ║${NC}"
echo -e "${GREEN}${BOLD}║                                                              ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "What changed:"
echo "  ✓ Official Nix → Determinate Systems Nix"
echo "  ✓ nix-darwin configuration preserved"
echo "  ✓ All modules and settings intact"
echo "  ✓ Flakes enabled by default"
echo ""

echo "Next steps:"
echo "  1. Restart your shell:     exec zsh"
echo "  2. Test nix-rebuild:       nix-rebuild"
echo "  3. Verify packages:        nix-env -q"
echo ""

echo "Backup location (safe to delete after verification):"
echo "  ${BACKUP_DIR}"
echo ""

echo "To uninstall Determinate Nix in the future:"
echo "  sudo /nix/nix-installer uninstall"
echo ""
