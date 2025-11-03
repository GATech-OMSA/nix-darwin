#!/usr/bin/env bash
# install-zsh-plugins.sh
# Installs custom Oh-My-Zsh plugins that cannot be managed by Nix
# These plugins are required by the configuration in home/jimmy/shell/zsh.nix

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Plugin directory
CUSTOM_PLUGINS="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Installing Custom Zsh Plugins${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if Oh-My-Zsh is installed
if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo -e "${RED}Error: Oh-My-Zsh is not installed!${NC}"
    echo "Please install Oh-My-Zsh first:"
    echo "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    exit 1
fi

# Function to install a plugin
install_plugin() {
    local name=$1
    local repo=$2
    local plugin_path="${CUSTOM_PLUGINS}/${name}"

    echo -e "${BLUE}Installing ${name}...${NC}"

    if [ -d "${plugin_path}" ]; then
        echo -e "${YELLOW}  Already installed, updating...${NC}"
        cd "${plugin_path}" && git pull
    else
        git clone "${repo}" "${plugin_path}"
        echo -e "${GREEN}  ✓ Installed${NC}"
    fi
}

# Install plugins
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions"
install_plugin "you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git"
install_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: ${BLUE}darwin-rebuild switch --flake ~/nix-darwin${NC}"
echo "  2. Restart your terminal or run: ${BLUE}exec zsh${NC}"
echo ""
echo -e "${GREEN}Plugins installed:${NC}"
echo "  ✓ zsh-autosuggestions - Command suggestions as you type"
echo "  ✓ zsh-syntax-highlighting - Highlights valid/invalid commands"
echo "  ✓ zsh-completions - Additional 100+ completions"
echo "  ✓ you-should-use - Reminds you to use defined aliases"
echo "  ✓ zsh-history-substring-search - Search history with arrow keys"
