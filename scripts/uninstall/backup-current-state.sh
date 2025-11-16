#!/usr/bin/env bash
# backup-current-state.sh
#
# Backs up the current nix-darwin managed state before rollback

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup directory
BACKUP_DIR="${HOME}/.nix-darwin-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}=== Nix-Darwin State Backup ===${NC}"
echo ""
echo "Backup directory: ${BACKUP_DIR}"
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}"/{configs,nix-state,secrets,scripts}

echo -e "${YELLOW}Backing up current configurations...${NC}"

# Backup all current dotfiles (even if they're symlinks, we'll resolve them)
CONFIGS=(
    ".zshrc"
    ".zshenv"
    ".config/git/config"
    ".config/starship.toml"
    ".config/fish/config.fish"
    ".aws/config"
    ".aws/credentials"
    ".ssh/config"
    ".npmrc"
    ".condarc"
    ".gitignore_global"
)

for config in "${CONFIGS[@]}"; do
    if [ -e "${HOME}/${config}" ]; then
        echo "  Backing up ${config}..."

        # Create parent directory if needed
        config_dir=$(dirname "${BACKUP_DIR}/configs/${config}")
        mkdir -p "${config_dir}"

        # If it's a symlink, resolve and copy the target
        if [ -L "${HOME}/${config}" ]; then
            target=$(readlink "${HOME}/${config}")
            cp -L "${HOME}/${config}" "${BACKUP_DIR}/configs/${config}"
            echo "    (symlink → ${target})"
        else
            cp -p "${HOME}/${config}" "${BACKUP_DIR}/configs/${config}"
        fi
    fi
done

echo ""
echo -e "${YELLOW}Backing up Nix state...${NC}"

# Save current generation
darwin-rebuild --list-generations > "${BACKUP_DIR}/nix-state/generations.txt" 2>&1 || true

# Save current configuration
if [ -d "/Users/jimmy/nix-darwin" ]; then
    echo "  Saving current nix-darwin configuration..."
    cp -r /Users/jimmy/nix-darwin "${BACKUP_DIR}/nix-state/nix-darwin-config" 2>/dev/null || true
fi

# List current packages
echo "  Listing Nix packages..."
nix-env -q > "${BACKUP_DIR}/nix-state/nix-packages.txt" 2>&1 || true

# List Darwin packages
echo "  Listing darwin-rebuild packages..."
darwin-rebuild --list > "${BACKUP_DIR}/nix-state/darwin-packages.txt" 2>&1 || true

# List Homebrew packages
if command -v brew &>/dev/null; then
    echo "  Listing Homebrew packages..."
    brew list > "${BACKUP_DIR}/nix-state/homebrew-packages.txt" 2>&1 || true
    brew list --cask > "${BACKUP_DIR}/nix-state/homebrew-casks.txt" 2>&1 || true
fi

echo ""
echo -e "${YELLOW}Backing up secrets (if accessible)...${NC}"

# Try to backup decrypted secrets
if [ -f "${HOME}/.secrets/credentials.env" ]; then
    echo "  Backing up credentials.env..."
    cp -p "${HOME}/.secrets/credentials.env" "${BACKUP_DIR}/secrets/" 2>/dev/null || \
        echo "    (Could not backup - permissions issue)"
fi

if [ -d "${HOME}/.db" ]; then
    echo "  Backing up .db directory..."
    cp -rp "${HOME}/.db" "${BACKUP_DIR}/secrets/" 2>/dev/null || \
        echo "    (Could not backup - permissions issue)"
fi

if [ -d "${HOME}/.tokens" ]; then
    echo "  Backing up .tokens directory..."
    cp -rp "${HOME}/.tokens" "${BACKUP_DIR}/secrets/" 2>/dev/null || \
        echo "    (Could not backup - permissions issue)"
fi

echo ""
echo -e "${YELLOW}Creating restore script...${NC}"

# Create restore script
cat > "${BACKUP_DIR}/RESTORE.sh" << 'RESTORE_EOF'
#!/usr/bin/env bash
# Auto-generated restore script

set -euo pipefail

echo "=== Restoring Nix-Darwin State ==="
echo ""
echo "This will restore your nix-darwin managed configuration."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restoring configurations..."
cd "${BACKUP_DIR}/configs"
for config in $(find . -type f); do
    target="${HOME}/${config#./}"
    mkdir -p "$(dirname "$target")"
    cp -p "$config" "$target"
    echo "  Restored $config"
done

echo ""
echo "Restore complete!"
echo "Now run: cd /Users/jimmy/nix-darwin && darwin-rebuild switch --flake ."
RESTORE_EOF

chmod +x "${BACKUP_DIR}/RESTORE.sh"

echo ""
echo -e "${GREEN}✓ Backup complete!${NC}"
echo ""
echo "Backup location: ${BACKUP_DIR}"
echo ""
echo "To restore from this backup:"
echo "  ${BACKUP_DIR}/RESTORE.sh"
echo ""

# Return backup directory for use by calling script
echo "${BACKUP_DIR}"
