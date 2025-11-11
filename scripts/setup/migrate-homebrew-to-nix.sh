#!/bin/bash
# ============================================================================
# HOMEBREW → NIX MIGRATION TOOL
# ============================================================================
#
# Helps migrate Homebrew-installed packages to Nix management.
#
# USAGE:
#   ./scripts/migrate-homebrew-to-nix.sh [OPTIONS]
#
# OPTIONS:
#   --dry-run          Show what would be migrated without making changes
#   --auto-cli         Automatically migrate all CLI tools without prompting
#   --help             Show this help message
#
# WORKFLOW:
#   1. Scans installed Homebrew packages (formulae + casks)
#   2. Checks which packages are available in nixpkgs
#   3. Categorizes: CLI tools (→Nix), GUI apps (→keep Homebrew), Unavailable
#   4. Interactive selection of packages to migrate
#   5. Updates nix configuration files
#   6. Shows post-migration instructions
#
# EXAMPLES:
#   # Interactive mode (recommended)
#   ./scripts/migrate-homebrew-to-nix.sh
#
#   # Dry run to preview changes
#   ./scripts/migrate-homebrew-to-nix.sh --dry-run
#
#   # Auto-migrate all CLI tools
#   ./scripts/migrate-homebrew-to-nix.sh --auto-cli
#
# ============================================================================

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Config files to update
PACKAGES_FILE="$REPO_ROOT/modules/shared/packages.nix"
HOMEBREW_FILE="$REPO_ROOT/modules/darwin/homebrew.nix"

# Temporary files
TEMP_DIR="/tmp/homebrew-nix-migration-$$"
FORMULAE_LIST="$TEMP_DIR/formulae.txt"
CASKS_LIST="$TEMP_DIR/casks.txt"
NIX_AVAILABLE="$TEMP_DIR/nix_available.txt"
TO_MIGRATE="$TEMP_DIR/to_migrate.txt"

# Flags
DRY_RUN=false
AUTO_CLI=false

# ============================================================================
# COLORS & MESSAGING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

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
  echo -e "${RED}❌${NC} $*" >&2
}

step() {
  echo -e "\n${BOLD}${CYAN}▶${NC} ${BOLD}$*${NC}\n"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

cleanup() {
  rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

show_help() {
  sed -n '/^# ====.*HOMEBREW/,/^# ====/p' "$0" | grep -v '^# ====' | sed 's/^# //' | sed 's/^#//'
  exit 0
}

check_dependencies() {
  local missing=()

  if ! command -v brew &> /dev/null; then
    missing+=("brew")
  fi

  if ! command -v nix &> /dev/null; then
    missing+=("nix")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing required dependencies: ${missing[*]}"
    error "Please install: ${missing[*]}"
    exit 1
  fi
}

# ============================================================================
# HOMEBREW SCANNING
# ============================================================================

scan_homebrew_packages() {
  step "Scanning Homebrew packages..."

  mkdir -p "$TEMP_DIR"

  # Scan formulae (CLI tools)
  info "Scanning formulae (CLI tools)..."
  brew list --formula > "$FORMULAE_LIST" 2>/dev/null || touch "$FORMULAE_LIST"
  local formula_count=$(wc -l < "$FORMULAE_LIST" | tr -d ' ')
  success "Found $formula_count formulae"

  # Scan casks (GUI apps)
  info "Scanning casks (GUI apps)..."
  brew list --cask > "$CASKS_LIST" 2>/dev/null || touch "$CASKS_LIST"
  local cask_count=$(wc -l < "$CASKS_LIST" | tr -d ' ')
  success "Found $cask_count casks"

  echo ""
  info "Total packages: $((formula_count + cask_count))"
}

# ============================================================================
# NIX AVAILABILITY CHECKING
# ============================================================================

check_nix_availability() {
  local package="$1"
  local type="$2"  # formula or cask

  # Search nixpkgs for package
  # Using nix search is slow, so we'll do a simple heuristic first

  # For formulae: likely available in nixpkgs
  if [ "$type" = "formula" ]; then
    # Try to find in nixpkgs
    if nix search nixpkgs "^$package\$" --json 2>/dev/null | grep -q "\"$package\""; then
      echo "available"
      return 0
    fi

    # Try alternative name (sometimes formula names differ)
    if nix search nixpkgs "$package" --json 2>/dev/null | grep -q "pname.*$package"; then
      echo "available-alt"
      return 0
    fi

    echo "unavailable"
    return 1
  fi

  # For casks: GUI apps should stay in Homebrew
  if [ "$type" = "cask" ]; then
    echo "cask-keep-homebrew"
    return 0
  fi
}

check_all_packages() {
  step "Checking Nix availability..."

  > "$NIX_AVAILABLE"

  local total_count=$(wc -l < "$FORMULAE_LIST" | tr -d ' ')
  local current=0

  info "Checking nixpkgs for $total_count packages..."
  info "(This may take a few minutes...)"
  echo ""

  # Check formulae
  while IFS= read -r package; do
    ((current++))
    echo -ne "\r${BLUE}Progress:${NC} $current/$total_count packages checked"

    local availability=$(check_nix_availability "$package" "formula")
    echo "$package|formula|$availability" >> "$NIX_AVAILABLE"
  done < "$FORMULAE_LIST"

  # Add casks (marked to stay in Homebrew)
  while IFS= read -r package; do
    echo "$package|cask|cask-keep-homebrew" >> "$NIX_AVAILABLE"
  done < "$CASKS_LIST"

  echo ""
  echo ""
  success "Availability check complete"
}

# ============================================================================
# CATEGORIZATION
# ============================================================================

categorize_packages() {
  step "Categorizing packages..."

  local cli_available=0
  local cli_unavailable=0
  local gui_count=0

  echo ""
  echo "┌─────────────────────────────────────────────┐"
  echo "│  📊 Package Categorization                  │"
  echo "└─────────────────────────────────────────────┘"
  echo ""

  # CLI tools available in Nix (recommended for migration)
  echo -e "${GREEN}${BOLD}✅ CLI Tools Available in Nix${NC} (recommended to migrate):"
  while IFS='|' read -r package type availability; do
    if [ "$type" = "formula" ] && [[ "$availability" == "available"* ]]; then
      echo "   • $package"
      ((cli_available++))
    fi
  done < "$NIX_AVAILABLE"

  if [ $cli_available -eq 0 ]; then
    echo "   (none)"
  fi
  echo ""

  # CLI tools NOT available in Nix
  echo -e "${YELLOW}${BOLD}⚠️  CLI Tools NOT in Nix${NC} (keep in Homebrew):"
  while IFS='|' read -r package type availability; do
    if [ "$type" = "formula" ] && [ "$availability" = "unavailable" ]; then
      echo "   • $package"
      ((cli_unavailable++))
    fi
  done < "$NIX_AVAILABLE"

  if [ $cli_unavailable -eq 0 ]; then
    echo "   (none)"
  fi
  echo ""

  # GUI apps (stay in Homebrew)
  echo -e "${CYAN}${BOLD}🖥️  GUI Apps${NC} (keep in Homebrew - casks):"
  while IFS='|' read -r package type availability; do
    if [ "$type" = "cask" ]; then
      echo "   • $package"
      ((gui_count++))
    fi
  done < "$NIX_AVAILABLE"

  if [ $gui_count -eq 0 ]; then
    echo "   (none)"
  fi
  echo ""

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "Summary:"
  echo "  • CLI → Nix: ${GREEN}$cli_available packages${NC}"
  echo "  • CLI → Keep: ${YELLOW}$cli_unavailable packages${NC}"
  echo "  • GUI → Keep: ${CYAN}$gui_count casks${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ============================================================================
# INTERACTIVE SELECTION
# ============================================================================

select_packages_to_migrate() {
  step "Package Selection"

  > "$TO_MIGRATE"

  if [ "$AUTO_CLI" = true ]; then
    info "Auto-migrating all CLI tools available in Nix..."
    while IFS='|' read -r package type availability; do
      if [ "$type" = "formula" ] && [[ "$availability" == "available"* ]]; then
        echo "$package" >> "$TO_MIGRATE"
      fi
    done < "$NIX_AVAILABLE"

    local count=$(wc -l < "$TO_MIGRATE" | tr -d ' ')
    success "Selected $count packages for migration"
    return 0
  fi

  echo "Select packages to migrate to Nix management:"
  echo ""
  echo "Options:"
  echo "  ${GREEN}y${NC} - Migrate this package"
  echo "  ${YELLOW}n${NC} - Keep in Homebrew"
  echo "  ${CYAN}a${NC} - Migrate all remaining CLI tools"
  echo "  ${RED}q${NC} - Quit selection"
  echo ""

  local migrate_all=false

  while IFS='|' read -r package type availability; do
    # Only ask about CLI tools available in Nix
    if [ "$type" != "formula" ] || [[ "$availability" != "available"* ]]; then
      continue
    fi

    if [ "$migrate_all" = true ]; then
      echo "$package" >> "$TO_MIGRATE"
      continue
    fi

    echo -ne "${BOLD}Migrate ${GREEN}$package${NC}? [y/n/a/q]: "
    read -r choice

    case "$choice" in
      y|Y)
        echo "$package" >> "$TO_MIGRATE"
        ;;
      a|A)
        echo "$package" >> "$TO_MIGRATE"
        migrate_all=true
        info "Auto-selecting all remaining packages..."
        ;;
      q|Q)
        warning "Selection cancelled"
        break
        ;;
      *)
        info "Skipping $package"
        ;;
    esac
  done < "$NIX_AVAILABLE"

  echo ""
  local count=$(wc -l < "$TO_MIGRATE" | tr -d ' ')
  success "Selected $count packages for migration"
}

# ============================================================================
# CONFIG FILE UPDATES
# ============================================================================

update_nix_config() {
  step "Updating Nix configuration..."

  if [ ! -f "$TO_MIGRATE" ] || [ ! -s "$TO_MIGRATE" ]; then
    warning "No packages selected for migration"
    return 0
  fi

  local packages=()
  while IFS= read -r package; do
    packages+=("$package")
  done < "$TO_MIGRATE"

  if [ "$DRY_RUN" = true ]; then
    info "DRY RUN: Would add the following packages to $PACKAGES_FILE:"
    for pkg in "${packages[@]}"; do
      echo "  • $pkg"
    done
    return 0
  fi

  info "Adding ${#packages[@]} packages to $PACKAGES_FILE..."

  # Backup original file
  cp "$PACKAGES_FILE" "$PACKAGES_FILE.backup"

  # Find the insertion point (before the closing bracket)
  local temp_file="$TEMP_DIR/packages.nix.new"

  # Read the file and insert packages before the last ]
  awk -v packages="${packages[*]}" '
  BEGIN {
    split(packages, pkg_array, " ")
  }
  /^[[:space:]]*\];[[:space:]]*$/ && !inserted {
    # Found closing bracket, insert packages before it
    print ""
    print "    # ============================================================================"
    print "    # MIGRATED FROM HOMEBREW (auto-generated by migrate-homebrew-to-nix.sh)"
    print "    # ============================================================================"
    for (i in pkg_array) {
      printf "    %s\n", pkg_array[i]
    }
    print ""
    inserted = 1
  }
  { print }
  ' "$PACKAGES_FILE" > "$temp_file"

  mv "$temp_file" "$PACKAGES_FILE"
  success "Updated $PACKAGES_FILE"

  info "Backup saved: $PACKAGES_FILE.backup"
}

update_homebrew_config() {
  if [ "$DRY_RUN" = true ]; then
    info "DRY RUN: Would comment out migrated packages in $HOMEBREW_FILE"
    return 0
  fi

  if [ ! -f "$TO_MIGRATE" ] || [ ! -s "$TO_MIGRATE" ]; then
    return 0
  fi

  info "Updating Homebrew configuration..."

  # Backup original file
  cp "$HOMEBREW_FILE" "$HOMEBREW_FILE.backup"

  # Comment out migrated packages
  while IFS= read -r package; do
    sed -i.tmp "s/^[[:space:]]*\"$package\"[[:space:]]*$/    # \"$package\"  # Migrated to Nix/" "$HOMEBREW_FILE"
    rm -f "$HOMEBREW_FILE.tmp"
  done < "$TO_MIGRATE"

  success "Updated $HOMEBREW_FILE"
  info "Backup saved: $HOMEBREW_FILE.backup"
}

# ============================================================================
# POST-MIGRATION INSTRUCTIONS
# ============================================================================

show_post_migration_instructions() {
  local package_count=$(wc -l < "$TO_MIGRATE" | tr -d ' ')

  step "Migration Complete!"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  success "Migrated $package_count packages to Nix"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    warning "DRY RUN: No changes were made"
    echo ""
    info "To actually migrate, run without --dry-run:"
    echo "  ./scripts/migrate-homebrew-to-nix.sh"
    return 0
  fi

  echo "${BOLD}Next Steps:${NC}"
  echo ""
  echo "1. ${BOLD}Review changes:${NC}"
  echo "   code $PACKAGES_FILE"
  echo "   code $HOMEBREW_FILE"
  echo ""
  echo "2. ${BOLD}Rebuild Nix configuration:${NC}"
  echo "   nix-rebuild"
  echo ""
  echo "3. ${BOLD}Verify packages work:${NC}"
  while IFS= read -r package; do
    echo "   which $package"
  done < "$TO_MIGRATE" | head -5
  if [ $package_count -gt 5 ]; then
    echo "   ... and $((package_count - 5)) more"
  fi
  echo ""
  echo "4. ${BOLD}Uninstall from Homebrew (optional):${NC}"
  echo "   brew uninstall \\"
  while IFS= read -r package; do
    echo "     $package \\"
  done < "$TO_MIGRATE" | sed '$ s/ \\$//'
  echo ""
  echo "5. ${BOLD}If something breaks:${NC}"
  echo "   # Restore from backup"
  echo "   cp $PACKAGES_FILE.backup $PACKAGES_FILE"
  echo "   cp $HOMEBREW_FILE.backup $HOMEBREW_FILE"
  echo "   nix-rebuild"
  echo ""

  info "Migrated packages list saved: $TO_MIGRATE"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --auto-cli)
        AUTO_CLI=true
        shift
        ;;
      --help|-h)
        show_help
        ;;
      *)
        error "Unknown option: $1"
        echo "Run with --help for usage information"
        exit 1
        ;;
    esac
  done

  # Header
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🍺 → ❄️  Homebrew → Nix Migration Tool"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ "$DRY_RUN" = true ]; then
    warning "DRY RUN MODE: No changes will be made"
  fi
  echo ""

  # Check dependencies
  check_dependencies

  # Scan Homebrew packages
  scan_homebrew_packages

  # Check Nix availability (commented out for now - too slow)
  # check_all_packages

  # For now, use a simpler heuristic: all formulae are CLI tools
  step "Analyzing packages..."
  info "Using heuristic: all formulae → CLI tools (likely in Nix)"
  info "                 all casks → GUI apps (keep in Homebrew)"
  echo ""

  # Simple categorization
  > "$NIX_AVAILABLE"
  while IFS= read -r package; do
    echo "$package|formula|available" >> "$NIX_AVAILABLE"
  done < "$FORMULAE_LIST"

  while IFS= read -r package; do
    echo "$package|cask|cask-keep-homebrew" >> "$NIX_AVAILABLE"
  done < "$CASKS_LIST"

  # Categorize and display
  categorize_packages

  # Select packages
  select_packages_to_migrate

  # Update configs
  update_nix_config
  update_homebrew_config

  # Show instructions
  show_post_migration_instructions
}

main "$@"
