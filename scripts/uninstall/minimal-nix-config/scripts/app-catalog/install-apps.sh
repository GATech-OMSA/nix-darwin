#!/usr/bin/env bash
# install-apps.sh
#
# Interactive app installer for minimal nix-darwin
# Helps discover and install GUI apps via Homebrew

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOMEBREW_FILE="${CONFIG_ROOT}/modules/darwin/homebrew.nix"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}=== App Installer ===${NC}"
echo ""

# App catalog (curated list of popular apps)
declare -A APP_CATALOG=(
    # Development
    ["visual-studio-code"]="Code editor by Microsoft"
    ["iterm2"]="Better terminal"
    ["docker"]="Container platform"
    ["postman"]="API development tool"
    ["github"]="GitHub Desktop"

    # Browsers
    ["google-chrome"]="Google Chrome browser"
    ["firefox"]="Mozilla Firefox browser"
    ["brave-browser"]="Privacy-focused browser"

    # Productivity
    ["notion"]="Notes and docs"
    ["obsidian"]="Knowledge base"
    ["slack"]="Team communication"
    ["discord"]="Chat and voice"
    ["zoom"]="Video conferencing"

    # Utilities
    ["rectangle"]="Window management"
    ["alt-tab"]="Better app switching"
    ["raycast"]="Spotlight replacement"
    ["appcleaner"]="App uninstaller"
    ["the-unarchiver"]="Archive utility"

    # Media
    ["spotify"]="Music streaming"
    ["vlc"]="Media player"
    ["handbrake"]="Video transcoder"

    # Security
    ["1password"]="Password manager"
    ["protonvpn"]="VPN client"
)

# Category mapping
declare -A CATEGORIES=(
    ["Development"]="visual-studio-code iterm2 docker postman github"
    ["Browsers"]="google-chrome firefox brave-browser"
    ["Productivity"]="notion obsidian slack discord zoom"
    ["Utilities"]="rectangle alt-tab raycast appcleaner the-unarchiver"
    ["Media"]="spotify vlc handbrake"
    ["Security"]="1password protonvpn"
)

# Function to show app by category
show_category() {
    local category=$1
    echo ""
    echo -e "${CYAN}${BOLD}${category}${NC}"
    echo "────────────────────────────────"
    echo ""

    local apps="${CATEGORIES[$category]}"
    local i=1
    for app in $apps; do
        local desc="${APP_CATALOG[$app]}"
        printf "  %2d. %-25s - %s\n" $i "$app" "$desc"
        i=$((i + 1))
    done
}

# Main menu
while true; do
    echo ""
    echo "Browse apps by category:"
    echo ""
    echo "  1. Development"
    echo "  2. Browsers"
    echo "  3. Productivity"
    echo "  4. Utilities"
    echo "  5. Media"
    echo "  6. Security"
    echo "  7. Search by name"
    echo "  8. Add custom app"
    echo "  9. Exit"
    echo ""

    read -p "Choose category [1-9]: " category_choice

    case $category_choice in
        1) show_category "Development" ;;
        2) show_category "Browsers" ;;
        3) show_category "Productivity" ;;
        4) show_category "Utilities" ;;
        5) show_category "Media" ;;
        6) show_category "Security" ;;
        7)
            echo ""
            read -p "Search for app: " search_term
            echo ""
            echo "Searching Homebrew casks for: $search_term"
            brew search --cask "$search_term" 2>/dev/null || echo "  No matches found"
            ;;
        8)
            echo ""
            read -p "Enter cask name (e.g., notion): " custom_app
            if [ -n "$custom_app" ]; then
                echo ""
                echo -e "${YELLOW}Adding custom app: $custom_app${NC}"

                # Verify it exists in Homebrew
                if brew info --cask "$custom_app" &>/dev/null; then
                    echo -e "${GREEN}✓${NC} Found in Homebrew"
                else
                    echo -e "${RED}✗${NC} Not found in Homebrew casks"
                    echo ""
                    echo "Search for it:"
                    echo "  brew search --cask $custom_app"
                    continue
                fi
            fi
            ;;
        9)
            echo ""
            echo "Exiting."
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid choice."
            continue
            ;;
    esac

    # After showing category or custom app, ask to install
    if [ "$category_choice" -ge 1 ] && [ "$category_choice" -le 6 ]; then
        echo ""
        read -p "Enter app number to install (or Enter to go back): " app_choice

        if [ -z "$app_choice" ]; then
            continue
        fi

        # Get category name
        case $category_choice in
            1) category="Development" ;;
            2) category="Browsers" ;;
            3) category="Productivity" ;;
            4) category="Utilities" ;;
            5) category="Media" ;;
            6) category="Security" ;;
        esac

        # Get app name
        apps="${CATEGORIES[$category]}"
        app_array=($apps)
        app_index=$((app_choice - 1))

        if [ $app_index -ge 0 ] && [ $app_index -lt ${#app_array[@]} ]; then
            selected_app="${app_array[$app_index]}"
        else
            echo "Invalid app number."
            continue
        fi
    elif [ "$category_choice" = "8" ]; then
        selected_app="$custom_app"
    else
        continue
    fi

    # Install app
    echo ""
    echo -e "${BLUE}Installing: $selected_app${NC}"
    echo ""

    # Check if already in config
    if grep -q "\"$selected_app\"" "$HOMEBREW_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Already in configuration!${NC}"
        echo ""
        read -p "Install anyway via Homebrew directly? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install --cask "$selected_app"
        fi
        continue
    fi

    # Add to homebrew.nix
    echo "Adding to ${HOMEBREW_FILE}..."

    # Find the casks section and add the app
    # This is a simple append - users should organize it manually
    if grep -q "casks = \[" "$HOMEBREW_FILE"; then
        # Add before the closing bracket
        sed -i.bak "/casks = \[/a\\
      \"$selected_app\"
" "$HOMEBREW_FILE"

        echo -e "${GREEN}✓${NC} Added to configuration"

        # Clean up backup
        rm -f "${HOMEBREW_FILE}.bak"

        echo ""
        echo "To install, run:"
        echo "  darwin-rebuild switch --flake ${CONFIG_ROOT}"
        echo ""

        read -p "Rebuild now? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            darwin-rebuild switch --flake "$CONFIG_ROOT"
        fi
    else
        echo -e "${RED}Error: Could not find casks section in homebrew.nix${NC}"
    fi
done
