#!/usr/bin/env bash
#
# config-diff.sh - Compare nix-darwin configurations between generations
#
# Usage:
#   config-diff.sh                    # Compare current vs previous
#   config-diff.sh --generations 9 10 # Compare specific generations
#   config-diff.sh --packages-only    # Only show package differences
#   config-diff.sh --verbose          # Show full diff output
#   config-diff.sh --help             # Show help

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Options
PACKAGES_ONLY=false
VERBOSE=false
GEN_OLD=""
GEN_NEW=""

# Functions
msg() { echo -e "${BOLD}$1${RESET}"; }
success() { echo -e "${GREEN}✓${RESET} $1"; }
error() { echo -e "${RED}✗${RESET} $1" >&2; }
warning() { echo -e "${YELLOW}▸${RESET} $1"; }
info() { echo -e "${BLUE}→${RESET} $1"; }
section() { echo -e "\n${CYAN}${BOLD}═══ $1 ═══${RESET}\n"; }

show_help() {
    cat <<EOF
${BOLD}config-diff.sh${RESET} - Compare nix-darwin configurations between generations

${BOLD}USAGE:${RESET}
    config-diff.sh [OPTIONS]

${BOLD}OPTIONS:${RESET}
    --generations N M    Compare generation N to generation M
    --packages-only      Only show package differences
    --verbose            Show full diff output
    --help               Show this help message

${BOLD}EXAMPLES:${RESET}
    config-diff.sh                    # Compare current vs previous
    config-diff.sh --generations 8 10 # Compare generations 8 and 10
    config-diff.sh --packages-only    # Only show package changes
    config-diff.sh --verbose          # Show detailed diffs

${BOLD}GENERATION STRUCTURE:${RESET}
    Generations are stored in: /nix/var/nix/profiles/
    Each generation contains:
        sw/bin/           - System packages
        darwin/           - macOS system settings
        user/             - Home Manager configuration
        activate          - Activation script
        etc/              - System configuration files

EOF
}

# Parse arguments
all_args=("$@")
while [[ $# -gt 0 ]]; do
    case $1 in
        --generations)
            GEN_OLD="$2"
            GEN_NEW="$3"
            shift 3
            ;;
        --packages-only)
            PACKAGES_ONLY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

run_banner "config-diff" "packages_only=$PACKAGES_ONLY verbose=$VERBOSE" "${all_args[@]}"

# Get generations
PROFILE_DIR="/nix/var/nix/profiles"

if [[ -z "$GEN_OLD" ]]; then
    # Find current and previous generation
    CURRENT=$(readlink "$PROFILE_DIR/system" | grep -oE 'system-[0-9]+-link' | grep -oE '[0-9]+')
    PREVIOUS=$((CURRENT - 1))

    if [[ $PREVIOUS -lt 1 ]]; then
        error "No previous generation found"
        exit 1
    fi

    GEN_OLD=$PREVIOUS
    GEN_NEW=$CURRENT
fi

# Validate generations exist
OLD_PATH="$PROFILE_DIR/system-${GEN_OLD}-link"
NEW_PATH="$PROFILE_DIR/system-${GEN_NEW}-link"

if [[ ! -L "$OLD_PATH" ]]; then
    error "Generation $GEN_OLD not found at $OLD_PATH"
    exit 1
fi

if [[ ! -L "$NEW_PATH" ]]; then
    error "Generation $GEN_NEW not found at $NEW_PATH"
    exit 1
fi

# Header
msg "╔════════════════════════════════════════════════════════════════╗"
msg "║         Nix-Darwin Configuration Diff Tool                    ║"
msg "╚════════════════════════════════════════════════════════════════╝"
echo ""
info "Comparing generation ${BOLD}$GEN_OLD${RESET} → ${BOLD}$GEN_NEW${RESET}"
echo ""

# Get generation metadata
OLD_STORE=$(readlink "$OLD_PATH")
NEW_STORE=$(readlink "$NEW_PATH")

info "Old: $OLD_STORE"
info "New: $NEW_STORE"
echo ""

# Compare packages
section "Package Changes"

# Get package lists
OLD_PACKAGES=$(ls "$OLD_PATH/sw/bin/" 2>/dev/null | sort)
NEW_PACKAGES=$(ls "$NEW_PATH/sw/bin/" 2>/dev/null | sort)

# Count packages
OLD_COUNT=$(echo "$OLD_PACKAGES" | wc -l | tr -d ' ')
NEW_COUNT=$(echo "$NEW_PACKAGES" | wc -l | tr -d ' ')

echo -e "Old generation: ${BOLD}$OLD_COUNT${RESET} packages"
echo -e "New generation: ${BOLD}$NEW_COUNT${RESET} packages"
echo ""

# Find added packages
ADDED=$(comm -13 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES"))
if [[ -n "$ADDED" ]]; then
    echo -e "${GREEN}${BOLD}Added ($( echo "$ADDED" | wc -l | tr -d ' ' )):${RESET}"
    echo "$ADDED" | while IFS= read -r pkg; do
        echo -e "  ${GREEN}+${RESET} $pkg"
    done
    echo ""
fi

# Find removed packages
REMOVED=$(comm -23 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES"))
if [[ -n "$REMOVED" ]]; then
    echo -e "${RED}${BOLD}Removed ($( echo "$REMOVED" | wc -l | tr -d ' ' )):${RESET}"
    echo "$REMOVED" | while IFS= read -r pkg; do
        echo -e "  ${RED}-${RESET} $pkg"
    done
    echo ""
fi

# If no changes
if [[ -z "$ADDED" ]] && [[ -z "$REMOVED" ]]; then
    success "No package changes"
    echo ""
fi

# Exit if packages-only mode
if [[ "$PACKAGES_ONLY" == "true" ]]; then
    msg "╔════════════════════════════════════════════════════════════════╗"
    msg "║                    Summary                                     ║"
    msg "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    ADDED_COUNT=0
    REMOVED_COUNT=0
    [[ -n "$ADDED" ]] && ADDED_COUNT=$(echo "$ADDED" | wc -l | tr -d ' ')
    [[ -n "$REMOVED" ]] && REMOVED_COUNT=$(echo "$REMOVED" | wc -l | tr -d ' ')

    echo -e "Generation ${BOLD}$GEN_OLD${RESET} → ${BOLD}$GEN_NEW${RESET}"
    echo -e "${GREEN}+ $ADDED_COUNT added${RESET}"
    echo -e "${RED}- $REMOVED_COUNT removed${RESET}"
    echo ""

    exit 0
fi

# Compare system settings (darwin/)
section " System Settings"

if diff -r "$OLD_PATH/darwin/" "$NEW_PATH/darwin/" > /dev/null 2>&1; then
    success "No system setting changes"
else
    if [[ "$VERBOSE" == "true" ]]; then
        diff -r "$OLD_PATH/darwin/" "$NEW_PATH/darwin/" 2>/dev/null | head -50 || true
    else
        warning "System settings changed (use --verbose for details)"

        # Try to show high-level differences
        if [[ -d "$OLD_PATH/darwin/" ]] && [[ -d "$NEW_PATH/darwin/" ]]; then
            OLD_DARWIN_FILES=$(find "$OLD_PATH/darwin/" -type f 2>/dev/null | wc -l)
            NEW_DARWIN_FILES=$(find "$NEW_PATH/darwin/" -type f 2>/dev/null | wc -l)
            echo "  Files: $OLD_DARWIN_FILES → $NEW_DARWIN_FILES"
        fi
    fi
fi
echo ""

# Compare Home Manager (user/)
section "Home Manager Configuration"

if [[ -d "$OLD_PATH/user" ]] && [[ -d "$NEW_PATH/user" ]]; then
    if diff -r "$OLD_PATH/user/" "$NEW_PATH/user/" > /dev/null 2>&1; then
        success "No Home Manager changes"
    else
        if [[ "$VERBOSE" == "true" ]]; then
            diff -r "$OLD_PATH/user/" "$NEW_PATH/user/" 2>/dev/null | head -50 || true
        else
            warning "Home Manager configuration changed (use --verbose for details)"

            # Show high-level stats
            OLD_USER_FILES=$(find "$OLD_PATH/user/" -type f 2>/dev/null | wc -l)
            NEW_USER_FILES=$(find "$NEW_PATH/user/" -type f 2>/dev/null | wc -l)
            echo "  Files: $OLD_USER_FILES → $NEW_USER_FILES"
        fi
    fi
else
    info "Home Manager not present in one or both generations"
fi
echo ""

# Compare activation scripts
section "Activation Scripts"

if diff "$OLD_PATH/activate" "$NEW_PATH/activate" > /dev/null 2>&1; then
    success "No activation script changes"
else
    if [[ "$VERBOSE" == "true" ]]; then
        diff "$OLD_PATH/activate" "$NEW_PATH/activate" 2>/dev/null | head -30 || true
    else
        warning "Activation script changed (use --verbose for details)"

        # Show file sizes
        OLD_SIZE=$(wc -c < "$OLD_PATH/activate" | tr -d ' ')
        NEW_SIZE=$(wc -c < "$NEW_PATH/activate" | tr -d ' ')
        echo "  Size: $OLD_SIZE → $NEW_SIZE bytes"
    fi
fi
echo ""

# Compare etc/ configuration
section "System Configuration (/etc)"

if [[ -L "$OLD_PATH/etc" ]] && [[ -L "$NEW_PATH/etc" ]]; then
    OLD_ETC=$(readlink "$OLD_PATH/etc")
    NEW_ETC=$(readlink "$NEW_PATH/etc")

    if [[ "$OLD_ETC" == "$NEW_ETC" ]]; then
        success "No /etc configuration changes"
    else
        warning "System configuration changed"
        if [[ "$VERBOSE" == "true" ]]; then
            diff -r "$OLD_ETC/etc" "$NEW_ETC/etc" 2>/dev/null | head -30 || true
        else
            echo "  Old: $OLD_ETC"
            echo "  New: $NEW_ETC"
        fi
    fi
else
    info "/etc configuration not present in one or both generations"
fi
echo ""

# Summary
section "Summary"

ADDED_COUNT=0
REMOVED_COUNT=0
[[ -n "$ADDED" ]] && ADDED_COUNT=$(echo "$ADDED" | wc -l | tr -d ' ')
[[ -n "$REMOVED" ]] && REMOVED_COUNT=$(echo "$REMOVED" | wc -l | tr -d ' ')

echo -e "${BOLD}Generation Comparison:${RESET} $GEN_OLD → $GEN_NEW"
echo ""
echo -e "${BOLD}Package Changes:${RESET}"
echo -e "  ${GREEN}+ $ADDED_COUNT added${RESET}"
echo -e "  ${RED}- $REMOVED_COUNT removed${RESET}"
echo ""

# Check if any significant changes occurred
HAS_CHANGES=false
[[ $ADDED_COUNT -gt 0 ]] || [[ $REMOVED_COUNT -gt 0 ]] && HAS_CHANGES=true

if ! diff -r "$OLD_PATH/darwin/" "$NEW_PATH/darwin/" > /dev/null 2>&1; then
    HAS_CHANGES=true
    echo -e "${YELLOW}▸${RESET} System settings changed"
fi

if [[ -d "$OLD_PATH/user" ]] && [[ -d "$NEW_PATH/user" ]]; then
    if ! diff -r "$OLD_PATH/user/" "$NEW_PATH/user/" > /dev/null 2>&1; then
        HAS_CHANGES=true
        echo -e "${YELLOW}▸${RESET} Home Manager configuration changed"
    fi
fi

if ! diff "$OLD_PATH/activate" "$NEW_PATH/activate" > /dev/null 2>&1; then
    HAS_CHANGES=true
    echo -e "${YELLOW}▸${RESET} Activation scripts changed"
fi

if [[ "$HAS_CHANGES" == "false" ]]; then
    echo ""
    success "No significant changes detected between generations"
fi

echo ""
info "Tip: Use ${BOLD}--verbose${RESET} to see detailed diffs"
info "Tip: Use ${BOLD}--packages-only${RESET} for quick package overview"
echo ""
