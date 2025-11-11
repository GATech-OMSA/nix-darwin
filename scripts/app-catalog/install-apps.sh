#!/usr/bin/env bash

# ============================================================================
# AWESOME APPS INSTALLER (GUM Edition)
# ============================================================================
#
# Interactive installer for curated macOS applications
# Uses gum for beautiful terminal UI and config/awesome-apps.yaml catalog
#
# Usage:
#   ./scripts/install-awesome-apps-gum.sh
#
# Features:
#   - Interactive multi-select UI powered by gum
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

# Base ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Modern Palette (Teal & Lime)
PALETTE_TEAL="#00F5D4"
PALETTE_BLUE="#008E9B"
PALETTE_BORDER="#005F69"
PALETTE_LIME="#9EF01A"
PALETTE_RED="#FF5555"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

info() {
  echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

warning() {
  echo -e "${YELLOW}!${NC}  $*"
}

error() {
  echo -e "${RED}×${NC} $*"
}

step() {
  local text="$*"
  local width=80
  local text_length=${#text}
  local padding=$(( (width - text_length) / 2 ))

  echo ""
  echo -e "${BOLD}════════════════════════════════════════════════════════════════════════════════${NC}"
  printf "${BOLD}%*s%s%*s${NC}\n" $padding "" "$text" $padding ""
  echo -e "${BOLD}════════════════════════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# ============================================================================
# DEPENDENCY CHECKS
# ============================================================================

check_dependencies() {
  if ! command -v gum &>/dev/null; then
    error "gum is not installed"
    echo ""
    echo "Install gum with:"
    echo "  brew install gum"
    echo ""
    echo "Or add to your Nix configuration and rebuild."
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
  local output_file="$2"

  awk -v cat="$category:" '
    $1 == cat { in_category = 1; next }
    in_category {
      if (/^[a-z_]+:/) { exit }
      if (/^  - name:/) {
        gsub(/^  - name: "/, ""); gsub(/"$/, ""); name = $0
        getline; gsub(/^    cask: "/, ""); gsub(/"$/, ""); cask = $0
        getline; gsub(/^    description: "/, ""); gsub(/"$/, ""); desc = $0
        getline; gsub(/^    tags: \[/, ""); gsub(/\]$/, ""); tags = $0
        print name "|" cask "|" desc "|" tags
      }
    }
  ' "$CATALOG_FILE" > "$output_file"
}

# ============================================================================
# INSTALLATION MODE
# ============================================================================

select_installation_mode() {
  step "Awesome Apps Installer"

  gum style \
    --foreground="$PALETTE_TEAL" \
    --border-foreground="$PALETTE_BORDER" \
    --border="rounded" \
    --align="center" \
    --width=80 \
    --margin="1 2" \
    --padding="1 2" \
    "Interactive installer for macOS applications" \
    "Powered by Homebrew Casks + Nix-Darwin"

  echo ""

  MODE=$(gum choose \
    --header="How would you like to proceed?" \
    --header.foreground="$PALETTE_TEAL" \
    --cursor="▶ " \
    --cursor.foreground="$PALETTE_TEAL" \
    --selected.foreground="$PALETTE_LIME" \
    "Install selected apps to Nix config" \
    "Dry run - preview changes only" \
    "Exit")

  if [[ "$MODE" == "Exit" ]] || [[ -z "$MODE" ]]; then
    gum style --foreground="$PALETTE_RED" "Aborting."
    exit 0
  fi

  echo ""
  gum style --foreground="$PALETTE_LIME" "✓ Mode: $MODE"
  echo ""
}

# ============================================================================
# APP SHOPPING WORKFLOW
# ============================================================================

select_categories_for_browsing() {
  step "Step 1 of 3: Select Categories to Browse" >&2

  gum style \
    --foreground="$PALETTE_BLUE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="0 2" \
    --width=80 \
    --align="center" \
    "Select one or more categories to explore" \
    "" \
    "SPACE/x toggle • ↑↓ navigate • ENTER confirm • ESC abort" \
    "Select 'Done' to proceed • Select 'Exit' to cancel" >&2

  echo "" >&2

  local all_categories=($(get_categories))
  local category_options=()
  for cat in "${all_categories[@]}"; do
    local display_name=$(get_category_display_name "$cat")
    local app_count=$(count_category_apps "$cat")
    category_options+=("$cat|$display_name ($app_count apps)")
  done

  local category_display_names=$(printf '%s\n' "${category_options[@]}" | sed 's/^[^|]*|//')

  local selected_display=$( (printf '%s\n' "$category_display_names"; printf '%s\n' "" "Done - Proceed to Final Review" "Exit - Cancel Installation") | \
    gum choose --no-limit \
      --header="Categories to browse (or select Done when finished)" \
      --header.foreground="$PALETTE_TEAL" \
      --cursor="▶ " \
      --cursor.foreground="$PALETTE_TEAL" \
      --selected.foreground="$PALETTE_LIME" \
      --height=15)

  if [[ "$selected_display" == *"Exit - Cancel Installation"* ]]; then
    gum style --foreground="$PALETTE_RED" "Installation cancelled." >&2
    exit 0
  fi

  if [[ "$selected_display" == *"Done - Proceed to Final Review"* ]] || [ -z "$selected_display" ]; then
    return
  fi

  local categories_to_browse=()
  while IFS= read -r display; do
    # Skip the Done/Exit options
    if [[ "$display" == "Done - Proceed to Final Review" ]] || [[ "$display" == "Exit - Cancel Installation" ]]; then
      continue
    fi
    for opt in "${category_options[@]}"; do
      if [[ "$opt" == *"|$display" ]]; then
        categories_to_browse+=("${opt%%|*}")
        break
      fi
    done
  done <<< "$selected_display"

  printf "%s\n" "${categories_to_browse[@]}"
}

# Reads categories from stdin, app_selection from arguments
select_new_apps() {
  mapfile -t categories_to_browse
  local app_selection_str="$1"
  local app_selection=($app_selection_str)

  step "Step 2 of 3: Select Apps to Add to Selection" >&2

  local app_options=()

  gum spin --spinner="dot" --title="Loading apps..." --spinner.foreground="$PALETTE_TEAL" --title.foreground="$PALETTE_TEAL" -- sleep 0.5 >&2
  for category in "${categories_to_browse[@]}"; do
    local display_name=$(get_category_display_name "$category")
    local apps_file="$TEMP_DIR/${category}.txt"
    parse_category_apps "$category" "$apps_file"

    if [ ! -s "$apps_file" ]; then
      continue
    fi

    while IFS='|' read -r name cask desc tags; do
      local in_selection=false
      for selection_app in "${app_selection[@]}"; do
        if [[ "$selection_app" == "$cask" ]]; then
          in_selection=true
          break
        fi
      done

      if [[ "$in_selection" == false ]]; then
        local tag_display=$(echo "$tags" | sed 's/, / | /g')
        app_options+=("$cask|[$display_name] $name ($tag_display)")
      fi
    done < "$apps_file"
  done

  if [ ${#app_options[@]} -eq 0 ]; then
    gum style --foreground="$PALETTE_TEAL" --margin="1 2" "✓ All apps from the selected categories are already in your selection or no apps were found." >&2
    sleep 1 >&2
    echo "" >&2
    return
  fi

  gum style \
    --foreground="$PALETTE_BLUE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="0 2" \
    --width=80 \
    --align="center" \
    "Select new applications to add to your selection" \
    "" \
    "SPACE/x toggle • ↑↓ navigate • ENTER confirm • ESC abort" \
    "Select 'Back' to choose more categories • Select 'Exit' to cancel" >&2
  echo "" >&2

  local app_display_names=$(printf '%s\n' "${app_options[@]}" | sed 's/^[^|]*|//')

  local selected_display=$( (printf '%s\n' "$app_display_names"; printf '%s\n' "" "Back - Return to Categories" "Exit - Cancel Installation") | \
    gum choose --no-limit \
      --header="Select apps to add to selection" \
      --header.foreground="$PALETTE_TEAL" \
      --cursor="▶ " \
      --cursor.foreground="$PALETTE_TEAL" \
      --selected.foreground="$PALETTE_LIME" \
      --height=20)

  if [[ "$selected_display" == *"Exit - Cancel Installation"* ]]; then
    gum style --foreground="$PALETTE_RED" "Installation cancelled." >&2
    exit 0
  fi

  if [[ "$selected_display" == *"Back - Return to Categories"* ]] || [ -z "$selected_display" ]; then
    return
  fi

  local newly_selected_apps=()
  while IFS= read -r display; do
    for opt in "${app_options[@]}"; do
      if [[ "$opt" == *"|$display" ]]; then
        newly_selected_apps+=("${opt%%|*}")
        break
      fi
    done
  done <<< "$selected_display"

  printf "%s\n" "${newly_selected_apps[@]}"
}

review_final_selection() {
  mapfile -t app_selection

  step "Step 3 of 3: Final Review" >&2

  if [ ${#app_selection[@]} -eq 0 ]; then
    return
  fi

  gum style \
    --foreground="$PALETTE_BLUE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="0 2" \
    --width=80 \
    --align="center" \
    "Review your final selection" \
    "" \
    "✓ All items are selected by default" \
    "SPACE/x toggle • ↑↓ navigate • ENTER confirm • ESC abort" \
    "Select 'Back' to add more • Select 'Exit' to cancel" >&2
  echo "" >&2

  local selected_flags=()
  for item in "${app_selection[@]}"; do
    selected_flags+=(--selected "$item")
  done

  local final_selection=$( (printf '%s\n' "${app_selection[@]}"; printf '%s\n' "" "Back - Add More Apps" "Exit - Cancel Installation") | \
    gum choose --no-limit \
      --header="Final confirmation" \
      --header.foreground="$PALETTE_TEAL" \
      --cursor="▶ " \
      --cursor.foreground="$PALETTE_TEAL" \
      --selected.foreground="$PALETTE_LIME" \
      --height=20 \
      "${selected_flags[@]}")

  if [[ "$final_selection" == *"Exit - Cancel Installation"* ]]; then
    gum style --foreground="$PALETTE_RED" "Installation cancelled." >&2
    exit 0
  fi

  if [[ "$final_selection" == *"Back - Add More Apps"* ]] || [ -z "$final_selection" ]; then
    return
  fi

  echo "$final_selection"
}

# ============================================================================
# SUMMARY & CONFIRMATION
# ============================================================================

show_summary() {
  step "Summary"

  # Mode display
  gum style \
    --foreground="$PALETTE_TEAL" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="0 2" \
    --width=80 \
    --bold \
    "Installation Mode: $MODE"

  echo ""

  # Apps list
  gum style \
    --foreground="$PALETTE_BLUE" \
    --bold \
    --margin="0 2" \
    "Selected Apps (${#SELECTED_APPS[@]} total):"

  echo ""

  # Show each app with status
  for app in "${SELECTED_APPS[@]}"; do
    if grep -q "\"$app\"" "$HOMEBREW_NIX" 2>/dev/null; then
      gum style --foreground="$PALETTE_LIME" --margin="0 4" "  ✓ $app (already installed)"
    else
      gum style --foreground="$PALETTE_TEAL" --margin="0 4" "  + $app (will be added)"
    fi
  done

  echo ""
  echo ""

  # Confirmation prompt
  CONFIRM=$(gum choose \
    --header="Ready to proceed?" \
    --header.foreground="$PALETTE_TEAL" \
    --cursor="▶ " \
    --cursor.foreground="$PALETTE_TEAL" \
    --selected.foreground="$PALETTE_LIME" \
    "Yes, proceed" \
    "Cancel and Exit")

  echo ""

  if [ "$CONFIRM" != "Yes, proceed" ]; then
    gum style --foreground="$PALETTE_RED" "Installation cancelled."
    exit 0
  fi
}

# ============================================================================
# NIX INTEGRATION
# ============================================================================

add_casks_to_nix() {
  step "Updating Nix Configuration"

  # Backup original
  cp "$HOMEBREW_NIX" "$HOMEBREW_NIX.backup"

  gum spin --spinner="dot" --title="Analyzing homebrew.nix..." --spinner.foreground="$PALETTE_TEAL" --title.foreground="$PALETTE_TEAL" -- sleep 1

  # Find the casks array section
  local temp_file="$TEMP_DIR/homebrew.nix.tmp"
  local in_casks=false
  local added_apps=()

  while IFS= read -r line; do
    echo "$line" >> "$temp_file"

    # Detect casks array start
    if [[ "$line" =~ ^[[:space:]]*casks[[:space:]]*=[[:space:]]*\[ ]]; then
      in_casks=true
      continue
    fi

    # Detect casks array end
    if [[ "$in_casks" == true ]] && [[ "$line" =~ ^[[:space:]]*\] ]]; then
      # Add new casks before closing bracket
      for app in "${SELECTED_APPS[@]}"; do
        # Check if already exists
        if ! grep -q "\"$app\"" "$HOMEBREW_NIX"; then
          echo "      \"$app\"" >> "$temp_file"
          added_apps+=("$app")
        fi
      done
      in_casks=false
    fi
  done < "$HOMEBREW_NIX"

  if [ ${#added_apps[@]} -gt 0 ]; then
    mv "$temp_file" "$HOMEBREW_NIX"
    gum style --foreground="$PALETTE_LIME" --bold "✓ Added ${#added_apps[@]} new casks to homebrew.nix"
    echo ""
    for app in "${added_apps[@]}"; do
      gum style --foreground="$PALETTE_TEAL" --margin="0 4" "  + $app"
    done
  else
    gum style --foreground="$PALETTE_LIME" "✓ All selected apps already in homebrew.nix"
    rm "$temp_file"
  fi

  echo ""
}

# ============================================================================
# DARWIN REBUILD
# ============================================================================

run_darwin_rebuild() {
  step "Rebuilding System"

  info "Running darwin-rebuild switch..."
  echo ""

  if darwin-rebuild switch --flake "$REPO_ROOT"; then
    echo ""
    step "Installation Complete!"
    echo ""

    # Show what was actually installed
    local new_count=0
    for app in "${SELECTED_APPS[@]}"; do
      if ! grep -q "\"$app\"" "$HOMEBREW_NIX.backup" 2>/dev/null; then
        ((new_count++))
      fi
    done

    if [ $new_count -gt 0 ]; then
      gum style --foreground="$PALETTE_LIME" --bold "✓ Successfully added $new_count new apps:"
      echo ""
      for app in "${SELECTED_APPS[@]}"; do
        if ! grep -q "\"$app\"" "$HOMEBREW_NIX.backup" 2>/dev/null; then
          gum style --foreground="$PALETTE_TEAL" --margin="0 4" "  ✓ $app"
        fi
      done
    else
      gum style --foreground="$PALETTE_LIME" "✓ All selected apps were already installed"
    fi

    echo ""
    success "System rebuild complete!"
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
  step "Dry Run - Preview Changes"

  local new_count=0
  local existing_count=0

  gum style \
    --foreground="$PALETTE_BLUE" \
    --bold \
    --margin="0 2" \
    "Changes that would be made:"

  echo ""

  for app in "${SELECTED_APPS[@]}"; do
    if grep -q "\"$app\"" "$HOMEBREW_NIX" 2>/dev/null; then
      gum style --foreground="$PALETTE_LIME" --margin="0 4" "  ✓ $app (already in config)"
      ((existing_count++))
    else
      gum style --foreground="$PALETTE_TEAL" --margin="0 4" "  + $app (would be added)"
      ((new_count++))
    fi
  done

  echo ""

  gum style \
    --foreground="$PALETTE_TEAL" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="1 2" \
    --width=80 \
    "Summary" \
    "  Existing: $existing_count" \
    "  New:      $new_count" \
    "" \
    "Would run:" \
    "  darwin-rebuild switch --flake $REPO_ROOT"

  echo ""
  gum style --foreground="$PALETTE_LIME" --bold "✓ Dry run complete - no changes made"
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
  check_dependencies
  select_installation_mode

  APP_SELECTION=()

  # Main loop for accumulating apps
  while true; do
    mapfile -t categories_to_browse < <(select_categories_for_browsing)

    # If user selected Exit or nothing, we're done browsing
    if [ ${#categories_to_browse[@]} -eq 0 ]; then
      break
    fi

    # Pass categories via stdin, selection via argument
    mapfile -t newly_selected_casks < <(printf "%s\n" "${categories_to_browse[@]}" | select_new_apps "${APP_SELECTION[*]}")

    if [ ${#newly_selected_casks[@]} -gt 0 ]; then
      # Add to selection first
      for cask in "${newly_selected_casks[@]}"; do
        # Avoid adding duplicates if logic ever fails
        if [[ ! " ${APP_SELECTION[@]} " =~ " ${cask} " ]]; then
            APP_SELECTION+=("$cask")
        fi
      done

      # Then show the summary with correct total
      echo "" >&2
      gum style --foreground="$PALETTE_LIME" --margin="0 2" "✓ Added ${#newly_selected_casks[@]} app(s). Total selection: ${#APP_SELECTION[@]} apps" >&2
      for cask in "${newly_selected_casks[@]}"; do
        gum style --foreground="$PALETTE_TEAL" --margin="0 4" "  • $cask" >&2
      done
      echo "" >&2
    fi

    # Loop automatically returns to category selection
  done

  # Final review and deselection
  mapfile -t SELECTED_APPS < <(printf "%s\n" "${APP_SELECTION[@]}" | review_final_selection)

  if [ ${#SELECTED_APPS[@]} -eq 0 ]; then
    gum style --foreground="$PALETTE_RED" "! No apps selected for installation."
    exit 0
  fi

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
  esac

  step "Complete"
  success "All done!"
  echo ""
}

# ============================================================================
# CLEANUP & EXECUTION
# ============================================================================

trap "rm -rf $TEMP_DIR" EXIT

main
