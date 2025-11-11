#!/usr/bin/env bash

# ============================================================================
# AWESOME APPS INSTALLER (FZF Edition)
# ============================================================================
#
# Interactive installer for curated macOS applications
# Uses fzf for multi-select UI and config/awesome-apps.yaml catalog
#
# Usage:
#   ./scripts/install-awesome-apps.sh
#
# Features:
#   - Interactive multi-select UI powered by fzf (already installed)
#   - Category-based app browsing
#   - Dry-run support
#   - Nix integration (adds apps to homebrew.nix)
#   - Automatic darwin-rebuild
#

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CATALOG_FILE="$REPO_ROOT/config/awesome-apps.yaml"
HOMEBREW_NIX="$REPO_ROOT/modules/darwin/homebrew.nix"
TEMP_DIR=$(mktemp -d)

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

info() {
  echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
  echo -e "${GREEN}✅${NC} $*"
}

warning() {
  echo -e "${YELLOW}⚠️${NC}  $*"
}

error() {
  echo -e "${RED}❌${NC} $*"
}

step() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}$*${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
  if ! command -v fzf &>/dev/null; then
    error "fzf is not installed"
    echo ""
    echo "fzf should be installed via home-manager in your Nix config."
    echo "Check: home/_mixins/base.nix"
    exit 1
  fi

  if [ ! -f "$CATALOG_FILE" ]; then
    error "Catalog file not found: $CATALOG_FILE"
    exit 1
  fi

  if [ ! -f "$HOMEBREW_NIX" ]; then
    error "Homebrew Nix config not found: $HOMEBREW_NIX"
    exit 1
  fi
}

# ============================================================================
# YAML PARSING
# ============================================================================

get_categories() {
  grep "^[a-z_]*:$" "$CATALOG_FILE" | sed 's/:$//'
}

get_category_display_name() {
  local category="$1"
  case "$category" in
    ai_llm) echo "AI & LLM Tools" ;;
    ai_coding) echo "AI Coding Assistants" ;;
    local_llm) echo "Local LLM Tools" ;;
    ai_browsers) echo "AI Browsers" ;;
    task_management) echo "Task Management" ;;
    productivity) echo "Productivity" ;;
    development) echo "Development Tools" ;;
    browsers) echo "Browsers" ;;
    creative) echo "Creative & Design" ;;
    communication) echo "Communication" ;;
    security_privacy) echo "Security & Privacy" ;;
    utilities) echo "Utilities" ;;
    *) echo "$category" ;;
  esac
}

count_category_apps() {
  local category="$1"
  awk -v cat="$category:" '
    $1 == cat { in_category = 1; next }
    in_category {
      if (/^[a-z_]+:/) { exit }
      if (/^  - name:/) { count++ }
    }
    END { print count }
  ' "$CATALOG_FILE"
}

parse_category_apps() {
  local category="$1"

  awk -v cat="$category:" '
    $1 == cat { in_category = 1; next }
    in_category {
      if (/^[a-z_]+:/) { exit }
      if (/^  - name:/) {
        gsub(/^  - name: "/, ""); gsub(/"$/, ""); name = $0
        getline; gsub(/^    cask: "/, ""); gsub(/"$/, ""); cask = $0
        getline; gsub(/^    description: "/, ""); gsub(/"$/, ""); desc = $0
        getline; gsub(/^    tags: \[/, ""); gsub(/\]$/, ""); tags = $0
        print cask "|" name "|" desc "|" tags
      }
    }
  ' "$CATALOG_FILE"
}

# ============================================================================
# INSTALLATION MODE
# ============================================================================

select_installation_mode() {
  step "🎨 Awesome Apps Installer"

  echo "Select installation mode:"
  echo ""

  MODE=$(printf "Install selected apps to Nix config\nDry run - preview changes only\nBrowse catalog only" | \
    fzf --height=10 \
        --prompt="Mode > " \
        --header="↑↓ Navigate | ↵ ENTER to select | ESC to cancel" \
        --pointer="▶ ")

  if [ -z "$MODE" ]; then
    warning "No mode selected"
    exit 0
  fi

  echo ""
  success "Mode: $MODE"
  echo ""
}

# ============================================================================
# CATEGORY SELECTION
# ============================================================================

select_categories() {
  step "📂 Category Selection"

  # Get all categories with counts
  local category_list=""
  while IFS= read -r cat; do
    local display_name=$(get_category_display_name "$cat")
    local app_count=$(count_category_apps "$cat")
    category_list+="${cat}|${display_name} (${app_count} apps)"$'\n'
  done < <(get_categories)

  # Use fzf for multi-select
  local selected=$(echo -n "$category_list" | \
    fzf --multi \
        --prompt="Categories > " \
        --header="⎵ TAB to select multiple | ↵ ENTER when done | ESC to cancel" \
        --marker="✓ " \
        --pointer="▶ " \
        --preview="echo {2}" \
        --preview-window=up:3:wrap \
        --with-nth=2 \
        --delimiter='|')

  if [ -z "$selected" ]; then
    warning "No categories selected"
    exit 0
  fi

  # Extract category IDs
  SELECTED_CATEGORIES=()
  while IFS='|' read -r cat_id display; do
    SELECTED_CATEGORIES+=("$cat_id")
  done <<< "$selected"

  echo ""
  success "Selected ${#SELECTED_CATEGORIES[@]} categories"
  echo ""
}

# ============================================================================
# APP SELECTION
# ============================================================================

select_apps_from_categories() {
  step "📱 App Selection"

  local all_apps_list=""

  # Aggregate apps from all selected categories
  info "Aggregating apps from selected categories..."
  for category in "${SELECTED_CATEGORIES[@]}"; do
    local display_name=$(get_category_display_name "$category")

    # Parse apps and prepend category display name
    local category_apps=$(parse_category_apps "$category" | awk -v prefix="[$display_name] " -F'|' '{OFS="|"; print $1, prefix $2, $3, $4}')

    if [ -n "$category_apps" ]; then
      all_apps_list+="$category_apps"$'\n'
    fi
  done

  if [ -z "$all_apps_list" ]; then
    warning "No apps found in the selected categories."
    exit 0
  fi

  # Use fzf for a single multi-select
  local selected=$(echo -n "$all_apps_list" | \
    fzf --multi \
        --prompt="Apps > " \
        --header="⎵ TAB to select multiple | ↵ ENTER when done | ESC to cancel" \
        --marker="✓ " \
        --pointer="▶ " \
        --preview="echo {2} --- {3}" \
        --preview-window=up:3:wrap \
        --with-nth=2,4 \
        --delimiter='|')

  if [ -z "$selected" ]; then
    warning "No apps selected"
    exit 0
  fi

  # Extract cask IDs
  SELECTED_APPS=()
  while IFS='|' read -r cask name desc tags; do
    SELECTED_APPS+=("$cask")
  done <<< "$selected"

  success "Selected ${#SELECTED_APPS[@]} apps"
  echo ""
}

# ============================================================================
# SUMMARY & CONFIRMATION
# ============================================================================

show_summary() {
  step "📊 Summary"

  echo -e "${BOLD}Mode:${NC} $MODE"
  echo -e "${BOLD}Selected Apps (${#SELECTED_APPS[@]}):${NC}"
  for app in "${SELECTED_APPS[@]}"; do
    if grep -q "\"$app\"" "$HOMEBREW_NIX" 2>/dev/null; then
      echo "  ${GREEN}✓${NC} $app (already installed)"
    else
      echo "  ${CYAN}+${NC} $app (will be added)"
    fi
  done
  echo ""

  echo "Press ENTER to proceed, or Ctrl+C to cancel..."
  read -r

  echo ""
}

# ============================================================================
# NIX INTEGRATION
# ============================================================================

add_casks_to_nix() {
  step "🔧 Updating Nix Configuration"

  # Backup original
  cp "$HOMEBREW_NIX" "$HOMEBREW_NIX.backup"

  info "Adding ${#SELECTED_APPS[@]} casks to homebrew.nix..."
  echo ""

  # Read the file and find where to insert
  local new_casks=()
  for app in "${SELECTED_APPS[@]}"; do
    if ! grep -q "\"$app\"" "$HOMEBREW_NIX"; then
      new_casks+=("$app")
    fi
  done

  if [ ${#new_casks[@]} -eq 0 ]; then
    success "All selected apps already in homebrew.nix"
    return
  fi

  # Insert new casks before the closing bracket of casks array
  local temp_file="$TEMP_DIR/homebrew.nix.new"

  awk -v apps="${new_casks[*]}" '
    BEGIN {
      split(apps, new_apps, " ")
    }
    /^[[:space:]]*casks[[:space:]]*=/ {
      in_casks = 1
      print
      next
    }
    in_casks && /^[[:space:]]*\];/ {
      # Add new casks before closing bracket
      for (i in new_apps) {
        print "      \"" new_apps[i] "\""
      }
      in_casks = 0
    }
    { print }
  ' "$HOMEBREW_NIX" > "$temp_file"

  mv "$temp_file" "$HOMEBREW_NIX"

  success "Added ${#new_casks[@]} new casks:"
  for app in "${new_casks[@]}"; do
    echo "  + $app"
  done
  echo ""
}

# ============================================================================
# DARWIN REBUILD
# ============================================================================

run_darwin_rebuild() {
  step "🔨 Rebuilding System"

  info "Running darwin-rebuild switch..."
  echo ""

  if darwin-rebuild switch --flake "$REPO_ROOT"; then
    echo ""
    success "System rebuild complete!"
    success "New apps have been installed"
  else
    echo ""
    error "Darwin rebuild failed"
    warning "Restoring backup..."
    mv "$HOMEBREW_NIX.backup" "$HOMEBREW_NIX"
    exit 1
  fi
}

# ============================================================================
# DRY RUN
# ============================================================================

show_dry_run() {
  step "🔍 Dry Run - Preview Changes"

  local new_count=0
  local existing_count=0

  echo -e "${BOLD}Changes that would be made:${NC}"
  echo ""

  for app in "${SELECTED_APPS[@]}"; do
    if grep -q "\"$app\"" "$HOMEBREW_NIX" 2>/dev/null; then
      echo "  ${GREEN}✓${NC} $app (already in config)"
      ((existing_count++))
    else
      echo "  ${CYAN}+${NC} $app (would be added)"
      ((new_count++))
    fi
  done

  echo ""
  echo -e "${BOLD}Summary:${NC}"
  echo "  Existing: $existing_count"
  echo "  New:      $new_count"
  echo ""
  echo -e "${BOLD}Would run:${NC}"
  echo "  darwin-rebuild switch --flake $REPO_ROOT"
  echo ""
  success "Dry run complete - no changes made"
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
  # Dependency checks
  check_dependencies

  # Interactive workflow
  select_installation_mode
  select_categories
  select_apps_from_categories
  show_summary

  # Execute based on mode
  case "$MODE" in
    "Install selected apps to Nix config")
      add_casks_to_nix
      run_darwin_rebuild
      ;;
    "Dry run - preview changes only")
      show_dry_run
      ;;
    "Browse catalog only")
      success "Catalog browsing complete"
      ;;
  esac

  step "✨ Complete"
  success "All done!"
  echo ""
}

# ============================================================================
# CLEANUP & EXECUTION
# ============================================================================

trap "rm -rf $TEMP_DIR" EXIT

main
