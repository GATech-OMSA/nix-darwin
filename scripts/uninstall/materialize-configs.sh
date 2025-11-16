#!/usr/bin/env bash
# materialize-configs.sh
#
# Converts nix-darwin managed configs (symlinks/generated) to real static files

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=${1:-false}
MINIMAL_NIX_DIR=${2:-""}

echo -e "${BLUE}=== Materializing Nix-Darwin Configs ===${NC}"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Ask user where they want to keep minimal nix config
if [ -z "$MINIMAL_NIX_DIR" ]; then
    echo -e "${CYAN}Where would you like to keep your minimal nix-darwin config?${NC}"
    echo ""
    echo "This will be used for package management only (no dotfile generation)."
    echo ""
    echo "Suggested locations:"
    echo "  1. ~/.nix-darwin-minimal (default, user-specific)"
    echo "  2. ~/nix-darwin-minimal (visible in home)"
    echo "  3. ~/.config/nix-darwin (XDG standard location)"
    echo "  4. Custom path"
    echo ""
    read -p "Enter path [default: ~/.nix-darwin-minimal]: " user_path

    if [ -z "$user_path" ]; then
        MINIMAL_NIX_DIR="${HOME}/.nix-darwin-minimal"
    else
        # Expand ~ if present
        MINIMAL_NIX_DIR="${user_path/#\~/$HOME}"
    fi

    echo ""
    echo -e "${GREEN}✓ Will use: ${MINIMAL_NIX_DIR}${NC}"
    echo ""
fi

# Working directory for materialized configs
MATERIAL_DIR="${HOME}/.materialized-configs-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${MATERIAL_DIR}"

echo "Working directory: ${MATERIAL_DIR}"
echo ""

# Configs to materialize
declare -A CONFIGS=(
    [".zshrc"]="Shell configuration"
    [".zshenv"]="Shell environment"
    [".config/git/config"]="Git configuration"
    [".config/starship.toml"]="Starship prompt"
    [".aws/config"]="AWS configuration"
    [".ssh/config"]="SSH configuration"
    [".npmrc"]="NPM configuration"
    [".condarc"]="Conda configuration"
    [".gitignore_global"]="Global gitignore"
)

# Secrets to decrypt and materialize
declare -A SECRETS=(
    [".secrets/credentials.env"]="Environment credentials"
    [".aws/credentials"]="AWS credentials"
)

echo -e "${YELLOW}Step 1: Materializing configuration files...${NC}"
echo ""

for config in "${!CONFIGS[@]}"; do
    desc="${CONFIGS[$config]}"
    source_path="${HOME}/${config}"

    if [ ! -e "$source_path" ]; then
        echo -e "  ${RED}✗${NC} ${config} - Not found, skipping"
        continue
    fi

    material_path="${MATERIAL_DIR}/${config}"
    mkdir -p "$(dirname "$material_path")"

    # Check if it's a symlink (Nix-managed)
    if [ -L "$source_path" ]; then
        target=$(readlink "$source_path")
        echo -e "  ${BLUE}→${NC} ${config} - Symlink to Nix store"
        echo "      Target: ${target}"

        if [ "$DRY_RUN" = "false" ]; then
            # Resolve and copy
            cp -L "$source_path" "$material_path"
            echo -e "      ${GREEN}✓${NC} Materialized to ${material_path}"
        else
            echo "      Would materialize to ${material_path}"
        fi
    else
        echo -e "  ${GREEN}✓${NC} ${config} - Already a real file"

        if [ "$DRY_RUN" = "false" ]; then
            cp -p "$source_path" "$material_path"
            echo "      Copied to ${material_path}"
        else
            echo "      Would copy to ${material_path}"
        fi
    fi

    echo ""
done

echo -e "${YELLOW}Step 2: Updating Nix-specific paths in configs...${NC}"
echo ""

# Create two versions of .zshrc - original and updated
if [ -f "${MATERIAL_DIR}/.zshrc" ]; then
    echo "  Processing .zshrc..."

    # Save original
    cp "${MATERIAL_DIR}/.zshrc" "${MATERIAL_DIR}/.zshrc.original"
    echo -e "    ${GREEN}✓${NC} Saved original: .zshrc.original"

    if [ "$DRY_RUN" = "false" ]; then
        # Update paths in .zshrc
        # Replace references to /Users/jimmy/nix-darwin with $MINIMAL_NIX_DIR

        # Get the current nix-darwin directory from the materialized config
        current_nix_dir="/Users/jimmy/nix-darwin"

        # Update the file
        sed -i.bak \
            -e "s|${current_nix_dir}|${MINIMAL_NIX_DIR}|g" \
            "${MATERIAL_DIR}/.zshrc"

        # Also add a header comment explaining the change
        {
            echo "# ============================================"
            echo "# This .zshrc has been converted from nix-darwin managed config"
            echo "# Original saved as: .zshrc.original"
            echo "# Minimal Nix config location: ${MINIMAL_NIX_DIR}"
            echo "# ============================================"
            echo ""
            cat "${MATERIAL_DIR}/.zshrc"
        } > "${MATERIAL_DIR}/.zshrc.tmp"
        mv "${MATERIAL_DIR}/.zshrc.tmp" "${MATERIAL_DIR}/.zshrc"

        # Clean up backup
        rm -f "${MATERIAL_DIR}/.zshrc.bak"

        echo -e "    ${GREEN}✓${NC} Updated paths to point to: ${MINIMAL_NIX_DIR}"
    else
        echo "    Would update paths from /Users/jimmy/nix-darwin → ${MINIMAL_NIX_DIR}"
    fi

    echo ""
    echo "  Two versions created:"
    echo "    • .zshrc.original - Exact copy from Nix-managed config"
    echo "    • .zshrc          - Updated to use minimal config at ${MINIMAL_NIX_DIR}"
    echo ""
else
    echo "  ⚠️  .zshrc not found, skipping path updates"
    echo ""
fi

echo -e "${YELLOW}Step 3: Decrypting and materializing secrets...${NC}"
echo ""

# Check if SOPS key is available
SOPS_KEY="${HOME}/.config/sops/age/keys.txt"
if [ ! -f "$SOPS_KEY" ]; then
    echo -e "${RED}⚠ SOPS age key not found at ${SOPS_KEY}${NC}"
    echo "  Secrets will need to be manually extracted"
    echo ""
else
    # Try to decrypt secrets from nix-config
    SECRETS_FILE="/Users/jimmy/nix-darwin/nix-config/hosts/macbook-pro-m1/secrets.yaml"

    if [ -f "$SECRETS_FILE" ]; then
        echo "  Found secrets file: ${SECRETS_FILE}"

        if [ "$DRY_RUN" = "false" ]; then
            # Decrypt secrets
            export SOPS_AGE_KEY_FILE="$SOPS_KEY"

            echo "  Decrypting secrets..."
            sops -d "$SECRETS_FILE" > "${MATERIAL_DIR}/secrets.yaml" 2>/dev/null || {
                echo -e "    ${RED}✗${NC} Could not decrypt secrets"
                echo "    You'll need to manually create credential files"
            }

            if [ -f "${MATERIAL_DIR}/secrets.yaml" ]; then
                echo -e "    ${GREEN}✓${NC} Secrets decrypted to ${MATERIAL_DIR}/secrets.yaml"
                echo ""
                echo "  You'll need to manually extract values from this file to:"
                for secret in "${!SECRETS[@]}"; do
                    echo "    - ${secret}"
                done
            fi
        else
            echo "    Would decrypt to ${MATERIAL_DIR}/secrets.yaml"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Secrets file not found"
    fi

    echo ""
fi

echo -e "${YELLOW}Step 4: Creating installation script...${NC}"
echo ""

# Save config info
cat > "${MATERIAL_DIR}/CONFIG_INFO.txt" << EOF
Materialized Configuration Information
========================================

Generated: $(date)
Minimal Nix Config Location: ${MINIMAL_NIX_DIR}

Files Created:
--------------
• .zshrc.original - Exact copy from nix-darwin (unmodified)
• .zshrc          - Modified version pointing to ${MINIMAL_NIX_DIR}
• Other configs   - Materialized as-is from Nix store

Notes:
------
If you want to use a different location for minimal nix config:
1. Edit .zshrc manually
2. Replace all instances of: ${MINIMAL_NIX_DIR}
3. With your preferred path

The .zshrc.original is provided as a reference if you need to
see the exact paths from your nix-darwin setup.
EOF

# Create install script
INSTALL_SCRIPT="${MATERIAL_DIR}/INSTALL.sh"

cat > "$INSTALL_SCRIPT" << 'INSTALL_EOF'
#!/usr/bin/env bash
# Auto-generated installation script
#
# This script will replace your Nix-managed configs with the materialized versions

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Installing Materialized Configs ==="
echo ""
echo -e "${YELLOW}This will replace your current configs with static versions.${NC}"
echo -e "${YELLOW}Make sure you've backed up first!${NC}"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

MATERIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing configs..."
cd "${MATERIAL_DIR}"

for config in $(find . -type f -name ".*" -o -type f -path "./.config/*"); do
    # Skip this script, secrets, and info files
    [[ "$config" == "./INSTALL.sh" ]] && continue
    [[ "$config" == "./secrets.yaml" ]] && continue
    [[ "$config" == "./CONFIG_INFO.txt" ]] && continue
    [[ "$config" == "./.zshrc.original" ]] && continue  # Skip .original files

    target="${HOME}/${config#./}"

    # Create parent directory
    mkdir -p "$(dirname "$target")"

    # Backup existing if not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        backup="${target}.nix-backup"
        echo "  Backing up $target → $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        echo "  Removing Nix symlink: $target"
        rm "$target"
    fi

    # Install new config
    cp -p "$config" "$target"
    echo -e "  ${GREEN}✓${NC} Installed $target"
done

# Copy .zshrc.original to home for reference
if [ -f "./.zshrc.original" ]; then
    cp -p "./.zshrc.original" "${HOME}/.zshrc.original"
    echo -e "  ${GREEN}✓${NC} Copied reference: ~/.zshrc.original"
fi

echo ""
echo -e "${GREEN}✓ Configuration installation complete!${NC}"
echo ""
echo "Installed configs:"
echo "  • ~/.zshrc          - Modified for minimal nix config"
echo "  • ~/.zshrc.original - Original from nix-darwin (reference)"
echo "  • Other dotfiles    - As materialized from Nix"
echo ""
echo "Next steps:"
echo "  1. Set up minimal nix config (see below)"
echo "  2. Restart your shell: exec zsh"
echo "  3. Test your configs (esp. nix-rebuild command)"
echo "  4. If everything works, you can remove full nix-darwin"
echo ""
echo "Note: Your .zshrc is configured to use minimal nix at:"
echo "  ${MATERIAL_DIR}/CONFIG_INFO.txt has the path"
echo ""

if [ -f "${MATERIAL_DIR}/secrets.yaml" ]; then
    echo -e "${YELLOW}⚠ Don't forget to extract secrets from:${NC}"
    echo "  ${MATERIAL_DIR}/secrets.yaml"
    echo ""
fi
INSTALL_EOF

chmod +x "$INSTALL_SCRIPT"

echo -e "${GREEN}✓ Materialization complete!${NC}"
echo ""
echo "Materialized configs are in: ${MATERIAL_DIR}"
echo ""
echo "To install these configs:"
echo "  ${INSTALL_SCRIPT}"
echo ""

if [ "$DRY_RUN" = "false" ]; then
    echo "Files created:"
    ls -la "${MATERIAL_DIR}"
fi

# Return directory for use by calling script
echo "${MATERIAL_DIR}"
