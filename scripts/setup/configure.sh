#!/usr/bin/env bash
# Nix-Darwin Configuration Script
#
# Interactive configuration creation for user-agnostic setup
# Generates config files and directories from templates
#
# Usage:
#   ./configure.sh        # Standard interactive mode
#   ./configure.sh --help # Show help

set -e  # Exit on error
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_VERSION="1.0.0"
DRY_RUN=false
FORCE_MODE=false

# Export age key location for SOPS
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration variables
USERNAME=""
FULL_NAME=""
EMAIL=""
MACHINE_ID=""
MACHINE_TYPE=""
MACHINE_DESCRIPTION=""
SYSTEM_ARCH=""
HOMEBREW_ENABLED=""

# Track created files for rollback
CREATED_FILES=()
CREATED_DIRS=()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Rollback/cleanup function
cleanup_on_failure() {
  local exit_code=$1

  if [ $exit_code -ne 0 ] && [ ${#CREATED_FILES[@]} -gt 0 -o ${#CREATED_DIRS[@]} -gt 0 ]; then
    echo ""
    warning "Configuration incomplete due to error"
    echo ""
    echo "The following files/directories were created:"
    for file in "${CREATED_FILES[@]}"; do
      echo "  • $file"
    done
    for dir in "${CREATED_DIRS[@]}"; do
      echo "  • $dir/"
    done
    echo ""
    read -p "Remove partial files? [Y/n]: " cleanup_confirm

    if [[ ! $cleanup_confirm =~ ^[Nn]$ ]]; then
      info "Cleaning up partial configuration..."
      for file in "${CREATED_FILES[@]}"; do
        if [ -f "$file" ]; then
          rm "$file" && success "Removed $file"
        fi
      done
      for dir in "${CREATED_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
          rmdir "$dir" && success "Removed empty directory $dir/"
        fi
      done
      echo ""
      success "Cleanup complete"
    else
      info "Keeping partial files - you can manually clean up later"
    fi
  fi
}

# Set trap to call cleanup on exit
trap 'cleanup_on_failure $?' EXIT

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

print_step() {
  echo ""
  echo -e "${BOLD}${BLUE}$1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

error() {
  echo -e "${RED}✗ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
  echo -e "${CYAN}[i]  $1${NC}"
}

prompt() {
  echo -e "${MAGENTA}❓ $1${NC}"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_machine_id() {
  local id="$1"
  # Machine ID should be lowercase alphanumeric with hyphens only
  if [[ ! "$id" =~ ^[a-z0-9-]+$ ]]; then
    return 1
  fi
  # Should not start or end with hyphen
  if [[ "$id" =~ ^- || "$id" =~ -$ ]]; then
    return 1
  fi
  # Should not have consecutive hyphens
  if [[ "$id" =~ -- ]]; then
    return 1
  fi
  return 0
}

validate_email() {
  local email="$1"
  # Basic email validation: contains @ and has domain part
  if [[ "$email" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
    return 0
  fi
  return 1
}

validate_username() {
  local username="$1"
  local system_user="$(whoami)"
  # Warn if different from system username
  if [ "$username" != "$system_user" ]; then
    warning "Username '$username' differs from system user '$system_user'"
    echo "   This may cause permission issues. Continue anyway?"
    read -p "   [y/N]: " confirm_diff
    if [[ ! $confirm_diff =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi
  return 0
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_prerequisites() {
  print_step "◆ Checking Prerequisites"

  info "Verifying required tools are installed..."
  echo ""

  local missing_tools=()

  # Check Nix
  if command -v nix &>/dev/null; then
    local nix_version=$(nix --version 2>/dev/null | awk '{print $3}')
    success "Nix installed ($nix_version)"
  else
    missing_tools+=("nix")
    error "Nix not installed"
  fi

  # Check nix-darwin
  if command -v darwin-rebuild &>/dev/null; then
    success "nix-darwin installed"
  else
    missing_tools+=("nix-darwin")
    error "nix-darwin not installed"
  fi

  # Check SOPS
  if command -v sops &>/dev/null; then
    local sops_version=$(sops --version 2>/dev/null | head -n1 | awk '{print $2}')
    success "SOPS installed ($sops_version)"
  else
    missing_tools+=("sops")
    error "SOPS not installed"
  fi

  # Check age
  if command -v age &>/dev/null; then
    local age_version=$(age --version 2>&1 | head -n1 | xargs)
    success "age installed ($age_version)"
  else
    missing_tools+=("age")
    error "age not installed"
  fi

  # Check git
  if command -v git &>/dev/null; then
    local git_version=$(git --version 2>/dev/null | awk '{print $3}')
    success "git installed ($git_version)"
  else
    missing_tools+=("git")
    error "git not installed"
  fi

  echo ""

  if [ ${#missing_tools[@]} -gt 0 ]; then
    error "Missing required tools: ${missing_tools[*]}"
    echo ""
    warning "These tools are required for nix-darwin configuration"
    echo ""
    echo "To install missing prerequisites, run:"
    echo -e "  ${BOLD}./scripts/setup/./scripts/setup/bootstrap.sh${NC}"
    echo ""
    exit 1
  fi

  success "All prerequisites satisfied ✓"
  echo ""
}

# ============================================================================
# INFORMATION GATHERING
# ============================================================================

detect_mac_model() {
  # Detect model name and chip from system_profiler
  local model_name=$(system_profiler SPHardwareDataType | grep 'Model Name' | awk -F': ' '{print $2}' | xargs)
  local chip=$(system_profiler SPHardwareDataType | grep 'Chip' | awk -F': ' '{print $2}' | xargs)

  # Auto-detect architecture from chip
  local arch
  if [[ "$chip" =~ "Apple" ]]; then
    arch="aarch64-darwin"
  else
    # Intel Mac detected - not supported
    error "Intel Macs are not supported by this configuration"
    echo ""
    echo "This nix-darwin configuration requires Apple Silicon (M1/M2/M3)."
    echo "Detected chip: $chip"
    echo ""
    exit 1
  fi

  # Return model|chip|arch for parsing
  echo "$model_name|$chip|$arch"
}

generate_machine_id() {
  # Generate username-agnostic machine ID from model and chip
  # Format: {model}-{chip} (e.g., "macbook-pro-m1")
  local model_name="$1"
  local chip="$2"

  # Normalize model name (lowercase, replace spaces with hyphens)
  local model=$(echo "$model_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  # Extract chip version (M1, M2, M3) and remove Pro/Max/Ultra suffixes
  # "Apple M1 Pro" → "m1", "Apple M2 Max" → "m2"
  local chip_version=$(echo "$chip" | grep -o 'M[0-9]' | tr '[:upper:]' '[:lower:]')

  # Combine: macbook-pro-m1
  echo "${model}-${chip_version}"
}

gather_user_info() {
  print_step "◆ Configuration Setup (Step 1 of 5)"

  # Auto-detect system values
  local detected_user="$(whoami)"
  local detected_email="$(git config --global user.email 2>/dev/null || echo "")"
  local detected_name="$(git config --global user.name 2>/dev/null || echo "")"
  local detected_hostname="$(hostname | sed 's/\.local$//')"

  # Detect Mac model and architecture
  local model_info=$(detect_mac_model)
  local detected_model=$(echo "$model_info" | cut -d'|' -f1)
  local detected_chip=$(echo "$model_info" | cut -d'|' -f2)
  SYSTEM_ARCH=$(echo "$model_info" | cut -d'|' -f3)

  # Generate username-agnostic machine ID (e.g., "macbook-pro-m1")
  local suggested_machine_id=$(generate_machine_id "$detected_model" "$detected_chip")

  # Display detected values
  echo "📋 Detected from your system:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%s %-15s %s\n" "✓" "Username:" "$detected_user"
  printf "%s %-15s %s\n" "$([ -n "$detected_email" ] && echo "✓" || echo "⚠")" "Email:" "${detected_email:-(not set)}"
  printf "%s %-15s %s\n" "$([ -n "$detected_name" ] && echo "✓" || echo "⚠")" "Full name:" "${detected_name:-(not set)}"
  printf "%s %-15s %s\n" "✓" "Machine ID:" "$suggested_machine_id"
  printf "%s %-15s %s\n" "✓" "Hostname:" "$detected_hostname"
  printf "%s %-15s %s\n" "✓" "Model:" "$detected_model"
  printf "%s %-15s %s\n" "✓" "Chip:" "$detected_chip"
  printf "%s %-15s %s\n" "✓" "Architecture:" "$SYSTEM_ARCH"
  echo ""

  # Show warnings for missing values
  [ -z "$detected_email" ] && warning "No git email configured - will prompt"
  [ -z "$detected_name" ] && warning "No git name configured - will prompt"
  echo ""

  # Educational note about Machine ID
  info "💡 About Machine ID:"
  echo "   Username-agnostic identifier for hardware (e.g., macbook-pro-m1)"
  echo "   Controls: host directory, secrets location, workspace, build target"
  echo ""

  # Keep or customize choice
  echo "Options:"
  echo "  [k] Keep detected values (fastest - just press Enter)"
  echo "  [c] Customize specific values"
  echo ""
  read -p "Choice [k/c] (default: k): " keep_or_change
  keep_or_change="${keep_or_change:-k}"

  if [[ "$keep_or_change" =~ ^[Kk]$ ]]; then
    # Fast path - use detected values
    USERNAME="$detected_user"
    EMAIL="$detected_email"
    FULL_NAME="$detected_name"
    MACHINE_ID="$suggested_machine_id"

    # Prompt only for missing values
    if [ -z "$EMAIL" ]; then
      echo ""
      read -p "Email (required): " EMAIL
      while [ -z "$EMAIL" ]; do
        warning "Email is required"
        read -p "Email: " EMAIL
      done
    fi

    if [ -z "$FULL_NAME" ]; then
      echo ""
      read -p "Full name (required): " FULL_NAME
      while [ -z "$FULL_NAME" ]; do
        warning "Full name is required"
        read -p "Full name: " FULL_NAME
      done
    fi
  else
    # Custom path - allow changing each value
    info "Customize values (press Enter to keep detected)"
    echo ""

    # Username
    echo "Username: $detected_user"
    read -p "Change? [y/N]: " change_user
    if [[ "$change_user" =~ ^[Yy]$ ]]; then
      read -p "New username: " USERNAME
      USERNAME="${USERNAME:-$detected_user}"
    else
      USERNAME="$detected_user"
    fi
    echo ""

    # Email
    if [ -n "$detected_email" ]; then
      echo "Email: $detected_email"
      read -p "Change? [y/N]: " change_email
      if [[ "$change_email" =~ ^[Yy]$ ]]; then
        read -p "New email: " EMAIL
      else
        EMAIL="$detected_email"
      fi
    else
      read -p "Email (required): " EMAIL
      while [ -z "$EMAIL" ]; do
        warning "Email is required"
        read -p "Email: " EMAIL
      done
    fi
    echo ""

    # Full name
    if [ -n "$detected_name" ]; then
      echo "Full name: $detected_name"
      read -p "Change? [y/N]: " change_name
      if [[ "$change_name" =~ ^[Yy]$ ]]; then
        read -p "New full name: " FULL_NAME
      else
        FULL_NAME="$detected_name"
      fi
    else
      read -p "Full name (required): " FULL_NAME
      while [ -z "$FULL_NAME" ]; do
        warning "Full name is required"
        read -p "Full name: " FULL_NAME
      done
    fi
    echo ""

    # Machine ID (username-agnostic)
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Step 2 of 5: Machine ID Setup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    info "What is a Machine ID?"
    echo "   A username-agnostic identifier for this Mac's hardware"
    echo ""
    info "What it controls:"
    echo "   • Host directory: hosts/\${machineId}/"
    echo "   • Secrets location: hosts/\${machineId}/secrets.yaml"
    echo "   • Workspace directory: workspace/\${machineId}/"
    echo "   • Build target: darwin-rebuild switch --flake .#\${machineId}"
    echo ""
    info "Good examples:"
    echo "   ✓ macbook-pro-m1 (describes hardware)"
    echo "   ✓ macbook-air-2024 (includes year)"
    echo "   ✓ personal-laptop (describes purpose)"
    echo ""
    warning "Avoid personal identifiers:"
    echo "   ✗ mbp-jimmy (contains username)"
    echo "   ✗ jimmy-macbook (contains username)"
    echo ""
    echo "Suggested: $suggested_machine_id"
    echo ""

    # Validate machine ID input
    while true; do
      read -p "Enter machine ID [default: $suggested_machine_id]: " MACHINE_ID
      MACHINE_ID="${MACHINE_ID:-$suggested_machine_id}"

      if validate_machine_id "$MACHINE_ID"; then
        break
      else
        error "Invalid machine ID format"
        echo "   • Use lowercase letters, numbers, and hyphens only"
        echo "   • Must not start/end with hyphen"
        echo "   • No consecutive hyphens"
        echo ""
      fi
    done
    echo ""
  fi

  # Machine type (always ask)
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Step 3 of 5: Profile Selection"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  info "Profiles control which tools, configs, and settings are loaded"
  echo ""
  echo "📱 1) Personal Mac (Recommended for home use)"
  echo "   • All development tools and languages"
  echo "   • Personal AWS profile by default"
  echo "   • Personal email in git config"
  echo "   • Full shell customizations"
  echo ""
  echo "💼 2) Work Mac (For company laptops)"
  echo "   • Work-specific AWS profiles"
  echo "   • Work email in git config"
  echo "   • Corporate security tools"
  echo "   • Work-appropriate aliases"
  echo ""
  echo "🛠️  3) Minimal (Troubleshooting/Testing)"
  echo "   • Base system only, no extras"
  echo "   • Fastest builds and rebuilds"
  echo "   • Good for debugging issues"
  echo "   • Can upgrade to personal/work later"
  echo ""
  read -p "Select profile [1-3] (default: 1): " MACHINE_TYPE_CHOICE
  MACHINE_TYPE_CHOICE="${MACHINE_TYPE_CHOICE:-1}"

  case $MACHINE_TYPE_CHOICE in
    1)
      MACHINE_TYPE="personal"
      ;;
    2)
      MACHINE_TYPE="work"
      ;;
    3)
      MACHINE_TYPE="minimal"
      ;;
    *)
      error "Invalid choice"
      exit 1
      ;;
  esac

  # Homebrew configuration (ask user preference)
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Step 4 of 5: Homebrew Configuration"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Smart defaults based on machine type
  local homebrew_default="y"
  if [ "$MACHINE_TYPE" = "work" ]; then
    homebrew_default="n"
    warning "Work machines: Corporate proxies may block Homebrew (requires Go modules)"
    echo "   If your corporate proxy allows it, you can still enable Homebrew."
  fi

  echo ""
  read -p "Enable Homebrew? [y/N] (default: $homebrew_default): " enable_homebrew
  enable_homebrew="${enable_homebrew:-$homebrew_default}"

  if [[ "$enable_homebrew" =~ ^[Yy]$ ]]; then
    HOMEBREW_ENABLED="true"
    success "Homebrew will be enabled"
  else
    HOMEBREW_ENABLED="false"
    info "Homebrew will be disabled"
  fi
  echo ""

  # Machine description (use system's existing ComputerName)
  MACHINE_DESCRIPTION=$(scutil --get ComputerName 2>/dev/null || echo "${USERNAME}'s ${detected_model}")
  info "Computer name: $MACHINE_DESCRIPTION"
  echo ""

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Step 5 of 5: Review Configuration"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo -e "${BOLD}Configuration Summary:${NC}"
  echo "  Username:     $USERNAME"
  echo "  Full Name:    $FULL_NAME"
  echo "  Email:        $EMAIL"
  echo "  Machine ID:   $MACHINE_ID"
  echo "  Machine Type: $MACHINE_TYPE"
  echo "  Description:  $MACHINE_DESCRIPTION"
  echo "  Architecture: $SYSTEM_ARCH"
  echo "  Homebrew:     $HOMEBREW_ENABLED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  while true; do
    echo ""
    read -p "Looks good? [Y/n/e to edit]: " confirm

    if [[ $confirm =~ ^[Yy]$ ]] || [[ -z $confirm ]]; then
      # User confirmed, continue
      break
    elif [[ $confirm =~ ^[Ee]$ ]]; then
      # User wants to edit - show menu
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Edit Configuration"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "  1) Username ($USERNAME)"
      echo "  2) Full Name ($FULL_NAME)"
      echo "  3) Email ($EMAIL)"
      echo "  4) Machine ID ($MACHINE_ID)"
      echo "  5) Profile ($MACHINE_TYPE)"
      echo "  6) Homebrew ($HOMEBREW_ENABLED)"
      echo "  0) Cancel and review again"
      echo ""
      read -p "Which setting to change? [0-6]: " edit_choice

      case $edit_choice in
        1)
          echo ""
          read -p "Enter new username [$USERNAME]: " new_username
          if [[ -n $new_username ]]; then
            USERNAME="$new_username"
            success "Username updated to: $USERNAME"
          fi
          ;;
        2)
          echo ""
          read -p "Enter new full name [$FULL_NAME]: " new_full_name
          if [[ -n $new_full_name ]]; then
            FULL_NAME="$new_full_name"
            success "Full name updated to: $FULL_NAME"
          fi
          ;;
        3)
          echo ""
          while true; do
            read -p "Enter new email [$EMAIL]: " new_email
            if [[ -z $new_email ]]; then
              break  # Keep existing
            elif validate_email "$new_email"; then
              EMAIL="$new_email"
              success "Email updated to: $EMAIL"
              break
            else
              error "Invalid email format (must contain @ and domain)"
            fi
          done
          ;;
        4)
          echo ""
          while true; do
            read -p "Enter new machine ID [$MACHINE_ID]: " new_machine_id
            if [[ -z $new_machine_id ]]; then
              break  # Keep existing
            elif validate_machine_id "$new_machine_id"; then
              MACHINE_ID="$new_machine_id"
              success "Machine ID updated to: $MACHINE_ID"
              break
            else
              error "Invalid machine ID (lowercase, hyphens only, no start/end/consecutive hyphens)"
            fi
          done
          ;;
        5)
          echo ""
          echo "Select new profile:"
          echo "  1) Personal"
          echo "  2) Work"
          echo "  3) Minimal"
          read -p "Choose [1-3]: " new_profile_choice
          case $new_profile_choice in
            1) MACHINE_TYPE="personal"; success "Profile updated to: personal" ;;
            2) MACHINE_TYPE="work"; success "Profile updated to: work" ;;
            3) MACHINE_TYPE="minimal"; success "Profile updated to: minimal" ;;
            *) warning "Invalid choice, keeping: $MACHINE_TYPE" ;;
          esac
          ;;
        6)
          echo ""
          read -p "Enable Homebrew? [y/N]: " new_homebrew
          if [[ $new_homebrew =~ ^[Yy]$ ]]; then
            HOMEBREW_ENABLED="true"
            success "Homebrew enabled"
          else
            HOMEBREW_ENABLED="false"
            success "Homebrew disabled"
          fi
          ;;
        0)
          info "Returning to summary..."
          ;;
        *)
          warning "Invalid choice, returning to summary..."
          ;;
      esac

      # Show updated summary
      echo ""
      echo -e "${BOLD}Updated Configuration Summary:${NC}"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "  Username:     $USERNAME"
      echo "  Full Name:    $FULL_NAME"
      echo "  Email:        $EMAIL"
      echo "  Machine ID:   $MACHINE_ID"
      echo "  Machine Type: $MACHINE_TYPE"
      echo "  Description:  $MACHINE_DESCRIPTION"
      echo "  Architecture: $SYSTEM_ARCH"
      echo "  Homebrew:     $HOMEBREW_ENABLED"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    elif [[ $confirm =~ ^[Nn]$ ]]; then
      echo ""
      info "Let's start over..."
      gather_user_info  # Restart from beginning
      return
    else
      warning "Please enter Y (yes), N (start over), or E (edit)"
    fi
  done

  echo ""
}

# ============================================================================
# CONFIGURATION FILE CREATION
# ============================================================================

create_config_files() {
  print_step "◆ Creating Configuration Files"

  # Preview what will be created (non-dry-run)
  if [ "$DRY_RUN" != true ]; then
    echo ""
    info "📋 Preview of files to be created:"
    echo ""
    echo "  ✓ config/user-config.nix"
    echo "     Location: $REPO_ROOT/config/user-config.nix"
    echo "     Settings: username, fullName, email"
    echo ""
    echo "  ✓ config/machine-config.nix"
    echo "     Location: $REPO_ROOT/config/machine-config.nix"
    echo "     Settings: machineId, machineType, description, system"
    echo ""
    echo "  ✓ nix-config/hosts/$MACHINE_ID/ directory"
    echo "     Location: $REPO_ROOT/nix-config/hosts/$MACHINE_ID/"
    echo ""
    echo "  ✓ nix-config/hosts/$MACHINE_ID/secrets.yaml (encrypted)"
    echo "     Location: $REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"
    echo ""
    read -p "Create these files? [Y/n]: " create_confirm
    if [[ $create_confirm =~ ^[Nn]$ ]]; then
      warning "Cancelled by user"
      exit 0
    fi
    echo ""
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would execute:"
    echo ""
    echo "  mkdir -p \"$REPO_ROOT/config\""
    echo ""
    echo "  cat > \"$REPO_ROOT/config/user-config.nix\" <<'EOF'"
    echo "  {"
    echo "    username = \"$USERNAME\";"
    echo "    fullName = \"$FULL_NAME\";"
    echo "    email = \"$EMAIL\";"
    echo "  }"
    echo "  EOF"
    echo ""
    echo "  cat > \"$REPO_ROOT/config/machine-config.nix\" <<'EOF'"
    echo "  {"
    echo "    machineId = \"$MACHINE_ID\";"
    echo "    machineType = \"$MACHINE_TYPE\";"
    echo "    description = \"$MACHINE_DESCRIPTION\";"
    echo "    expectedHostname = \"$(hostname)\";"
    echo "    system = \"$SYSTEM_ARCH\";"
    echo "  }"
    echo "  EOF"
    echo ""
    success "[DRY RUN] Config files would be created successfully"
    echo ""
    return
  fi

  # Create config directory with error handling
  if ! mkdir -p "$REPO_ROOT/config" 2>/dev/null; then
    error "Failed to create config/ directory"
    echo ""
    echo "Possible causes:"
    echo "  • Insufficient permissions"
    echo "  • Disk full"
    echo "  • Path is a file (not a directory)"
    echo ""
    echo "Recovery steps:"
    echo "  1. Check permissions: ls -la $REPO_ROOT"
    echo "  2. Ensure path is writable: chmod u+w $REPO_ROOT"
    echo "  3. Check disk space: df -h"
    echo ""
    exit 1
  fi
  CREATED_DIRS+=("$REPO_ROOT/config")

  # 1. user-config.nix
  if [ -f "$REPO_ROOT/config/user-config.nix" ]; then
    if [ "$FORCE_MODE" = true ]; then
      warning "Overwriting existing config/user-config.nix"
    else
      warning "config/user-config.nix already exists - overwriting"
      info "Use --force to acknowledge file replacement"
    fi
  fi
  info "Creating config/user-config.nix..."
  if ! cat > "$REPO_ROOT/config/user-config.nix" <<EOF
{
  username = "$USERNAME";
  fullName = "$FULL_NAME";
  email = "$EMAIL";
}
EOF
  then
    error "Failed to write config/user-config.nix"
    echo ""
    echo "Recovery steps:"
    echo "  1. Check disk space: df -h $REPO_ROOT"
    echo "  2. Verify write permissions: ls -la $REPO_ROOT/config/"
    echo "  3. Try manual creation: vim $REPO_ROOT/config/user-config.nix"
    echo ""
    exit 1
  fi
  CREATED_FILES+=("$REPO_ROOT/config/user-config.nix")
  success "Created config/user-config.nix"

  # 2. machine-config.nix
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    if [ "$FORCE_MODE" = true ]; then
      warning "Overwriting existing config/machine-config.nix"
    else
      warning "config/machine-config.nix already exists - overwriting"
      info "Use --force to acknowledge file replacement"
    fi
  fi
  info "Creating config/machine-config.nix..."
  if ! cat > "$REPO_ROOT/config/machine-config.nix" <<EOF
{
  machineId = "$MACHINE_ID";
  machineType = "$MACHINE_TYPE";
  description = "$MACHINE_DESCRIPTION";
  expectedHostname = "$(hostname)";
  system = "$SYSTEM_ARCH";
}
EOF
  then
    error "Failed to write config/machine-config.nix"
    echo ""
    echo "Recovery steps:"
    echo "  1. Check disk space: df -h $REPO_ROOT"
    echo "  2. Verify write permissions: ls -la $REPO_ROOT/config/"
    echo "  3. Try manual creation: vim $REPO_ROOT/config/machine-config.nix"
    echo ""
    exit 1
  fi
  CREATED_FILES+=("$REPO_ROOT/config/machine-config.nix")
  success "Created config/machine-config.nix"

  echo ""
}

# ============================================================================
# DIRECTORY CREATION FROM TEMPLATES
# ============================================================================

create_hosts_directory() {
  print_step "◆ Creating Host Directory"

  if [ -d "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" ]; then
    if [ "$FORCE_MODE" = true ]; then
      warning "Removing existing hosts/$MACHINE_ID/"
      rm -rf "$REPO_ROOT/nix-config/hosts/$MACHINE_ID"
      success "Removed hosts/$MACHINE_ID/"
      echo ""
    else
      warning "hosts/$MACHINE_ID/ already exists - skipping"
      info "Use --force to overwrite existing configuration"
      echo ""
      return
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would create nix-config/hosts/$MACHINE_ID/ from template"
    echo ""
    return
  fi

  info "Creating nix-config/hosts/$MACHINE_ID/..."
  mkdir -p "$REPO_ROOT/nix-config/hosts/$MACHINE_ID"
  CREATED_DIRS+=("$REPO_ROOT/nix-config/hosts/$MACHINE_ID")

  # Copy from template
  local TEMPLATE_DIR="$REPO_ROOT/nix-config/hosts/_template"

  if [ ! -d "$TEMPLATE_DIR" ]; then
    error "Template directory not found: $TEMPLATE_DIR"
    return 1
  fi

  # Copy default.nix from template and replace placeholders
  info "Generating default.nix from template..."
  sed \
    -e "s/REPLACE_WITH_COMPUTER_NAME/$MACHINE_DESCRIPTION/g" \
    -e "s/REPLACE_WITH_HOMEBREW_CHOICE/$HOMEBREW_ENABLED/g" \
    "$TEMPLATE_DIR/default.nix" > "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/default.nix"
  CREATED_FILES+=("$REPO_ROOT/nix-config/hosts/$MACHINE_ID/default.nix")

  # Copy appropriate secrets file based on profile
  case "$MACHINE_TYPE" in
    personal)
      info "Copying secrets-personal.nix..."
      cp "$TEMPLATE_DIR/secrets-personal.nix" "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets-personal.nix"
      CREATED_FILES+=("$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets-personal.nix")
      ;;
    work)
      info "Copying secrets-work.nix..."
      cp "$TEMPLATE_DIR/secrets-work.nix" "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets-work.nix"
      CREATED_FILES+=("$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets-work.nix")
      ;;
    *)
      # Minimal profile - no secrets
      ;;
  esac

  # Copy secrets.yaml template if it exists
  if [ -f "$TEMPLATE_DIR/secrets.yaml.template" ]; then
    info "Copying secrets.yaml template..."
    cp "$TEMPLATE_DIR/secrets.yaml.template" "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"
    CREATED_FILES+=("$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml")
  fi

  success "Created nix-config/hosts/$MACHINE_ID/ from template"

  echo ""
}

create_home_directory() {
  print_step "🏡 Home Configuration"

  # With profile system, home/jimmy is tracked in git and shared
  # User-specific overrides go in profiles, not per-user directories

  if [ -d "$REPO_ROOT/home/$USERNAME" ]; then
    success "Using existing home/$USERNAME/ configuration"
    info "User customizations managed via profile: $MACHINE_TYPE"
    echo ""
    return
  fi

  # If home directory doesn't exist, the profile system handles it
  success "Home configuration managed by profile: $MACHINE_TYPE"
  info "Located at: home/_profiles/$MACHINE_TYPE/"
  echo ""
}

create_workspace_directory() {
  print_step "📁 Creating Workspace Directory"

  local WORKSPACE_DIR="$REPO_ROOT/workspace/$MACHINE_ID"
  local BACKUP_DIR="$WORKSPACE_DIR/backups"
  local AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would create workspace/$MACHINE_ID/ from template"
    if [ -f "$AGE_KEY_FILE" ]; then
      info "[DRY RUN] Would backup age key to: $BACKUP_DIR/keys.txt.backup-YYYYMMDD-HHMMSS"
    else
      warning "[DRY RUN] Age key not found - would skip backup"
    fi
    echo ""
    return
  fi

  if [ -d "$WORKSPACE_DIR" ]; then
    success "workspace/$MACHINE_ID/ already exists"
    info "Workspace is machine-specific and gitignored"
  else
    info "Creating workspace/$MACHINE_ID/ directory..."

    # Create workspace directory (backup.sh will create subdirectories)
    mkdir -p "$WORKSPACE_DIR/backups"
    CREATED_DIRS+=("$WORKSPACE_DIR")
    success "Created workspace/$MACHINE_ID/"
    info "Run 'backup-workspace' to populate with application data"
  fi

  # Backup age key
  mkdir -p "$BACKUP_DIR"
  if [ -f "$AGE_KEY_FILE" ]; then
    local BACKUP_FILE="$BACKUP_DIR/age-key-$(date +%Y%m%d-%H%M%S).txt"
    cp "$AGE_KEY_FILE" "$BACKUP_FILE"
    chmod 600 "$BACKUP_FILE"
    CREATED_FILES+=("$BACKUP_FILE")
    success "Age key backed up to workspace"
  else
    warning "Age key not found at $AGE_KEY_FILE"
    info "It will be generated during secrets setup"
  fi

  echo ""
}

# ============================================================================
# SECRET SCANNING AND ENCRYPTION
# ============================================================================

update_sops_yaml() {
  print_step "◆ Updating .sops.yaml Configuration"

  local AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
  local SOPS_CONFIG="$REPO_ROOT/.sops.yaml"

  # Extract age public key
  if [ ! -f "$AGE_KEY_FILE" ]; then
    error "Age key not found at $AGE_KEY_FILE"
    echo ""
    echo "Please run ./scripts/setup/bootstrap.sh first to generate your age key"
    exit 1
  fi

  local AGE_PUBLIC_KEY=$(grep "# public key:" "$AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')

  if [ -z "$AGE_PUBLIC_KEY" ]; then
    error "Could not extract age public key from $AGE_KEY_FILE"
    exit 1
  fi

  success "Found age public key: $AGE_PUBLIC_KEY"
  echo ""

  # Update .sops.yaml
  info "Updating .sops.yaml with your age public key..."

  cat > "$SOPS_CONFIG" <<EOF
# .sops.yaml - SOPS Configuration
#
# This file configures SOPS encryption for secrets management
# Generated by configure.sh

keys:
  - &user_key $AGE_PUBLIC_KEY

creation_rules:
  # Host-specific secrets
  - path_regex: nix-config/hosts/.*/secrets\.yaml$
    key_groups:
      - age:
          - *user_key
EOF

  success ".sops.yaml updated with your age public key"
  echo ""
}

scan_existing_secrets() {
  print_step "◆ Scanning for Existing Secrets"

  info "Detecting secrets in your home directory..."
  echo ""

  local found_secrets=()
  local secret_count=0
  local scan_depth="${SECRET_SCAN_DEPTH:-4}"  # Default: 4 levels deep

  info "Scan depth: $scan_depth directory levels"
  echo ""

  # ==== Known Secret Directories ====

  # Scan ~/.db/ directory (database credentials)
  if [ -d "$HOME/.db" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("Database credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.db" -maxdepth "$scan_depth" -type f -print0 2>/dev/null)
  fi

  # Scan ~/.tokens/ directory (API tokens)
  if [ -d "$HOME/.tokens" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("API token: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.tokens" -maxdepth "$scan_depth" -type f -print0 2>/dev/null)
  fi

  # Scan ~/.credentials/ directory
  if [ -d "$HOME/.credentials" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("Credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.credentials" -maxdepth "$scan_depth" -type f -print0 2>/dev/null)
  fi

  # Check AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    found_secrets+=("AWS credentials: ~/.aws/credentials")
    ((secret_count++)) || true
  fi

  # Scan SSH keys (private keys only, exclude .pub)
  if [ -d "$HOME/.ssh" ]; then
    while IFS= read -r -d '' file; do
      if [[ ! "$file" =~ \.pub$ ]] && [[ -f "$file" ]]; then
        found_secrets+=("SSH key: $file")
        ((secret_count++)) || true
      fi
    done < <(find "$HOME/.ssh" -name "id_*" -type f -print0 2>/dev/null)
  fi

  # Scan ~/.gnupg/ directory (GPG keys)
  if [ -d "$HOME/.gnupg" ]; then
    while IFS= read -r -d '' file; do
      if [[ "$file" =~ (secring\.gpg|private-keys-v1\.d) ]]; then
        found_secrets+=("GPG private key: $file")
        ((secret_count++)) || true
      fi
    done < <(find "$HOME/.gnupg" -maxdepth 2 -type f -print0 2>/dev/null)
  fi

  # Check Docker config
  if [ -f "$HOME/.docker/config.json" ]; then
    found_secrets+=("Docker config: ~/.docker/config.json")
    ((secret_count++)) || true
  fi

  # Scan ~/.vpn/ directory
  if [ -d "$HOME/.vpn" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("VPN credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.vpn" -maxdepth "$scan_depth" -type f -print0 2>/dev/null)
  fi

  # ==== CLI Config Files ====

  # Kubernetes config
  if [ -f "$HOME/.kube/config" ]; then
    found_secrets+=("Kubernetes config: ~/.kube/config")
    ((secret_count++)) || true
  fi

  # Scan application-specific config files
  local app_configs=(
    "$HOME/.npmrc:npm config"
    "$HOME/.netrc:Network credentials"
    "$HOME/.pgpass:PostgreSQL password"
    "$HOME/.my.cnf:MySQL credentials"
    "$HOME/.pypirc:PyPI credentials"
    "$HOME/.gem/credentials:Ruby gem credentials"
    "$HOME/.wakatime.cfg:WakaTime API key"
  )
  for app_config in "${app_configs[@]}"; do
    local file_path="${app_config%%:*}"
    local description="${app_config##*:}"
    if [ -f "$file_path" ]; then
      found_secrets+=("$description: $file_path")
      ((secret_count++)) || true
    fi
  done

  # ==== Environment Files (Deep Scan) ====

  # Scan for .env* files (all variations, up to scan_depth)
  while IFS= read -r -d '' env_file; do
    found_secrets+=("Environment file: $env_file")
    ((secret_count++)) || true
  done < <(find "$HOME" -maxdepth "$scan_depth" -type f \
    \( -name ".env" -o -name ".env.*" -o -name ".envrc" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -name "*.swp" \
    ! -name "*.bak" \
    ! -name "*.backup" \
    ! -name "*~" \
    -print0 2>/dev/null)

  # ==== Wildcard Pattern Scanning ====

  # Files with *secret* in name
  while IFS= read -r -d '' file; do
    found_secrets+=("Secret file: $file")
    ((secret_count++)) || true
  done < <(find "$HOME" -maxdepth "$scan_depth" -type f \
    -iname "*secret*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -name "*.md" \
    ! -name "*.txt" \
    -print0 2>/dev/null | head -z -n 20)  # Limit to first 20 matches

  # Files with *credential* in name
  while IFS= read -r -d '' file; do
    found_secrets+=("Credential file: $file")
    ((secret_count++)) || true
  done < <(find "$HOME" -maxdepth "$scan_depth" -type f \
    -iname "*credential*" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -name "*.md" \
    ! -name "*.txt" \
    -print0 2>/dev/null | head -z -n 20)

  # Certificate files (.pem, .p12, .pfx)
  while IFS= read -r -d '' file; do
    found_secrets+=("Certificate: $file")
    ((secret_count++)) || true
  done < <(find "$HOME" -maxdepth "$scan_depth" -type f \
    \( -name "*.pem" -o -name "*.p12" -o -name "*.pfx" -o -name "*.key" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    -print0 2>/dev/null | head -z -n 20)

  # ==== Shell Config Scanning ====

  # Scan shell configuration files for exported secrets
  local shell_configs=("$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.config/fish/config.fish")
  for config_file in "${shell_configs[@]}"; do
    if [ -f "$config_file" ]; then
      # Search for export statements with secret-like patterns
      if grep -qE 'export.*(API_KEY|TOKEN|SECRET|PASSWORD|PRIVATE_KEY).*=' "$config_file" 2>/dev/null; then
        found_secrets+=("Shell config with secrets: $config_file")
        ((secret_count++)) || true
      fi
    fi
  done

  # Scan generated alias files (from previous Nix configs or manual setups)
  while IFS= read -r -d '' alias_file; do
    # Check if file contains secrets (connection strings, API keys, tokens)
    if grep -qE '(API_KEY|TOKEN|SECRET|PASSWORD|PRIVATE_KEY|mysql.*-p|psql.*postgresql://|curl.*token)' "$alias_file" 2>/dev/null; then
      found_secrets+=("Alias file with potential secrets: $alias_file")
      ((secret_count++)) || true
    fi
  done < <(find "$HOME/.config" -maxdepth 3 -type f \
    \( -name "*alias*" -o -name "*aliases*" \) \
    ! -path "*/.git/*" \
    -print0 2>/dev/null)

  # Scan shell history files (can leak secrets from pasted commands)
  local history_files=("$HOME/.zsh_history" "$HOME/.bash_history" "$HOME/.history")
  for history_file in "${history_files[@]}"; do
    if [ -f "$history_file" ]; then
      # Check for secrets in command history (sample check to avoid full scan)
      if grep -qE '(export.*SECRET|API_KEY.*=|TOKEN.*=|PASSWORD.*=|-p.*[A-Za-z0-9]{8,})' "$history_file" 2>/dev/null | head -n 1; then
        found_secrets+=("Shell history with potential secrets: $history_file")
        ((secret_count++)) || true
      fi
    fi
  done

  # ==== Age Key Detection ====

  # Check for SOPS_AGE_KEY_FILE environment variable
  if [ -n "$SOPS_AGE_KEY_FILE" ] && [ -f "$SOPS_AGE_KEY_FILE" ]; then
    found_secrets+=("SOPS age key: $SOPS_AGE_KEY_FILE")
    ((secret_count++)) || true
  fi

  # Check default age key location
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    found_secrets+=("SOPS age key: ~/.config/sops/age/keys.txt")
    ((secret_count++)) || true
  fi

  # Display results
  if [ $secret_count -eq 0 ]; then
    info "No existing secrets detected in common locations"
    echo "   You'll need to create them manually or via SOPS encryption"
  else
    success "Found $secret_count existing secret(s):"
    echo ""
    for secret in "${found_secrets[@]}"; do
      echo "   ✓ $secret"
    done
    echo ""
    warning "These secrets should be encrypted in nix-config/hosts/$MACHINE_ID/secrets.yaml"
    info "See docs/secrets.md for SOPS setup instructions"
    echo ""
    info "To change scan depth: export SECRET_SCAN_DEPTH=3  # Default: 4"
  fi

  echo ""

  # Always return success - we're just displaying results
  return 0
}

validate_secret_structure() {
  local SECRETS_FILE="$1"

  if [ ! -f "$SECRETS_FILE" ]; then
    error "Secrets file not found: $SECRETS_FILE"
    return 1
  fi

  info "Validating secrets.yaml structure..."
  echo ""

  # Required keys based on secrets-personal.nix
  local required_keys=("zsh_secrets" "ssh_private_key" "ssh_public_key")
  local uncommented_count=0
  local commented_count=0

  echo "Checking secret structure:"
  echo ""

  for key in "${required_keys[@]}"; do
    if grep -q "^${key}:" "$SECRETS_FILE"; then
      success "✓ $key (uncommented - ready)"
      ((uncommented_count++)) || true
    elif grep -q "^# ${key}:" "$SECRETS_FILE"; then
      info "  $key (commented - needs uncommenting)"
      ((commented_count++)) || true
    else
      warning "✗ $key (missing from template)"
    fi
  done

  echo ""

  if [ $uncommented_count -eq 0 ]; then
    info "All required keys are commented (default template state)"
    echo ""
    info "Before activation, you must:"
    echo "  1. Uncomment required keys (zsh_secrets, ssh_private_key, ssh_public_key)"
    echo "  2. Replace placeholder values with actual secrets"
    echo "  3. Review and uncomment any discovered secrets you need"
    echo ""
  elif [ $uncommented_count -lt ${#required_keys[@]} ]; then
    warning "Some required keys still commented"
    info "Uncomment remaining keys before activation"
    echo ""
  else
    success "All required keys present and uncommented"
    echo ""
  fi

  # Always return success - validation is informational only at this stage
  return 0
}

create_secrets_file() {
  print_step "◆ Secret File Creation"

  local SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"

  # Handle dry-run mode
  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would create secrets.yaml at: $SECRETS_FILE"
    echo ""
    info "[DRY RUN] Template would contain:"
    echo "  • Required secrets (zsh_secrets, ssh keys)"
    echo "  • Optional secrets (AWS, GitHub, databases)"
    echo "  • Discovered secrets from system scan"
    echo ""
    success "[DRY RUN] Secrets file would be created"
    echo ""
    return
  fi

  # Backup existing file if it exists
  if [ -f "$SECRETS_FILE" ]; then
    # Store backups in workspace directory
    local WORKSPACE_BACKUP_DIR="$REPO_ROOT/workspace/$MACHINE_ID/backups"
    mkdir -p "$WORKSPACE_BACKUP_DIR"

    local BACKUP_FILENAME="secrets.yaml.backup-$(date +%Y%m%d-%H%M%S)"
    local BACKUP_FILE="$WORKSPACE_BACKUP_DIR/$BACKUP_FILENAME"
    cp "$SECRETS_FILE" "$BACKUP_FILE"
    success "Existing secrets.yaml backed up to: $BACKUP_FILE"
    echo ""

    # Rotate old backups - keep only the 2 most recent
    local backup_pattern="$WORKSPACE_BACKUP_DIR/secrets.yaml.backup-*"
    local backup_count=$(ls -1 $backup_pattern 2>/dev/null | wc -l | tr -d ' ')

    if [ "$backup_count" -gt 2 ]; then
      info "Rotating old backups (keeping 2 most recent)..."
      # Get all backups sorted by time (newest first), keep first 2, delete rest
      local kept=0
      for backup_file in $(ls -1t $backup_pattern 2>/dev/null); do
        kept=$((kept + 1))
        if [ $kept -gt 2 ]; then
          rm "$backup_file"
          info "Removed old backup: $(basename "$backup_file")"
        fi
      done
      echo ""
    fi
  fi

  info "Creating plaintext secrets.yaml template..."
  info "This file will NOT be encrypted yet - please review it to add or remove secrets"
  info "before running ./scripts/setup/activate.sh. That step will encrypt the file automatically."
  echo ""

  # Create comprehensive plaintext template matching secrets-personal.nix structure
  cat > "$SECRETS_FILE" <<'EOF'
# Edit with: sops hosts/mbp-jimmy/secrets.yaml
# or use the helper: edit-secrets
# Environment variables and API keys
# These will be placed in ~/.zsh_secrets and sourced automatically
# This file will be encrypted with SOPS after review
#
# IMPORTANT: All keys are commented for safety
# Uncomment and populate with actual values before activation
#
# After adding your secrets, encrypt with: sops -e -i secrets/secrets.yaml
#
# IMPORTANT: This file will be encrypted and safe to commit to git
# DO NOT commit this file before encrypting it!

# Placeholder (required for SOPS encryption - can be removed after adding real secrets)
_placeholder: "generated_by_configure"

# Required keys (MUST uncomment and populate):
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Shell environment secrets (API keys, tokens)
# zsh_secrets: |
#   export OPENAI_API_KEY="sk-..."
#   export GITHUB_TOKEN="ghp_..."
#   export ANTHROPIC_API_KEY="sk-ant-..."

# SSH private key (ed25519 recommended)
# ssh_private_key: |
#   -----BEGIN OPENSSH PRIVATE KEY-----
#   REPLACE_WITH_YOUR_PRIVATE_KEY_CONTENT
#   -----END OPENSSH PRIVATE KEY-----

# SSH public key
# ssh_public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@hostname"

# Optional secrets (uncomment and populate if needed):
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# AWS credentials (multiple profiles supported)
# aws_credentials: |
#   [default]
#   aws_access_key_id = AKIA...
#   aws_secret_access_key = ...
#
#   [personal]
#   aws_access_key_id = AKIA...
#   aws_secret_access_key = ...

# Ollama SSH keys (if using remote Ollama)
# ollama_ssh_private_key: |
#   -----BEGIN OPENSSH PRIVATE KEY-----
#   ...
#   -----END OPENSSH PRIVATE KEY-----
#
# ollama_ssh_public_key: "ssh-ed25519 AAAAC3... user@host"

# Database credentials
# db_production: "postgresql://user:password@host:5432/dbname"
# db_staging: "postgresql://user:password@host:5432/dbname"

# API tokens
# stripe_api_key: "sk_live_..."
# sendgrid_api_key: "SG..."

EOF

  # Add discovered secrets as commented templates
  echo "# ============================================" >> "$SECRETS_FILE"
  echo "# Discovered Secrets (uncomment and populate)" >> "$SECRETS_FILE"
  echo "# ============================================" >> "$SECRETS_FILE"
  echo "" >> "$SECRETS_FILE"

  # Database credentials
  if [ -d "$HOME/.db" ]; then
    find "$HOME/.db" -type f 2>/dev/null | while read -r file; do
      local secret_name=$(echo "$file" | sed "s|$HOME/.db/||" | tr '/' '_')
      echo "# db_${secret_name}: |" >> "$SECRETS_FILE"
      # Comment all lines from the file, not just the first
      cat "$file" | sed 's/^/#   /' >> "$SECRETS_FILE"
      echo "" >> "$SECRETS_FILE"
    done
  fi

  # API tokens
  if [ -d "$HOME/.tokens" ]; then
    find "$HOME/.tokens" -type f 2>/dev/null | while read -r file; do
      local token_name=$(basename "$file")
      echo "# ${token_name}: |" >> "$SECRETS_FILE"
      # Comment all lines from the file
      cat "$file" | sed 's/^/#   /' >> "$SECRETS_FILE"
      echo "" >> "$SECRETS_FILE"
    done
  fi

  # Additional credentials directory
  if [ -d "$HOME/.credentials" ]; then
    find "$HOME/.credentials" -type f 2>/dev/null | while read -r file; do
      local cred_name=$(basename "$file")
      echo "# ${cred_name}: |" >> "$SECRETS_FILE"
      # Comment all lines from the file
      cat "$file" | sed 's/^/#   /' >> "$SECRETS_FILE"
      echo "" >> "$SECRETS_FILE"
    done
  fi

  # AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    echo "# aws_credentials: |" >> "$SECRETS_FILE"
    cat "$HOME/.aws/credentials" | sed 's/^/#   /' >> "$SECRETS_FILE"
    echo "" >> "$SECRETS_FILE"
  fi

  # AWS accounts (for work profile - SSO multi-account mapping)
  if [ -f "$HOME/.aws/accounts.json" ]; then
    echo "# AWS account mapping (work profile only)" >> "$SECRETS_FILE"
    echo "# aws_accounts: |" >> "$SECRETS_FILE"
    cat "$HOME/.aws/accounts.json" | sed 's/^/#   /' >> "$SECRETS_FILE"
    echo "" >> "$SECRETS_FILE"
  elif [ "$MACHINE_TYPE" = "work" ]; then
    echo "# AWS account mapping (work profile - add your account IDs)" >> "$SECRETS_FILE"
    echo "# Template: templates/aws/accounts.json.template" >> "$SECRETS_FILE"
    echo "# aws_accounts: |" >> "$SECRETS_FILE"
    echo "#   {" >> "$SECRETS_FILE"
    echo "#     \"work-domain\": {" >> "$SECRETS_FILE"
    echo "#       \"description\": \"Work AWS Organization\"," >> "$SECRETS_FILE"
    echo "#       \"default_role\": \"support\"," >> "$SECRETS_FILE"
    echo "#       \"accounts\": {" >> "$SECRETS_FILE"
    echo "#         \"dev\": \"123456789012\"," >> "$SECRETS_FILE"
    echo "#         \"qa\": \"234567890123\"," >> "$SECRETS_FILE"
    echo "#         \"prod\": \"345678901234\"" >> "$SECRETS_FILE"
    echo "#       }" >> "$SECRETS_FILE"
    echo "#     }" >> "$SECRETS_FILE"
    echo "#   }" >> "$SECRETS_FILE"
    echo "" >> "$SECRETS_FILE"
  fi


  # SSH keys
  if [ -d "$HOME/.ssh" ]; then
    find "$HOME/.ssh" -name "id_*" -type f ! -name "*.pub" 2>/dev/null | while read -r file; do
      local key_name=$(basename "$file")
      echo "# ssh_${key_name}: |" >> "$SECRETS_FILE"
      echo "#   <contents of $file>" >> "$SECRETS_FILE"
      echo "" >> "$SECRETS_FILE"
    done
  fi

  success "Plaintext secrets.yaml created at: $SECRETS_FILE"
  echo ""

  # Validate structure
  validate_secret_structure "$SECRETS_FILE"

  warning "⚠ IMPORTANT: This file contains UNENCRYPTED secrets!"
  echo ""
  echo "📝 Review and edit secrets.yaml:"
  echo ""
  echo "  1. Fill in required keys (zsh_secrets, ssh_private_key, ssh_public_key)"
  echo "  2. Review discovered secrets section at bottom"
  echo "  3. Uncomment discovered secrets by removing # prefix"
  echo "  4. Keep # for secrets you don't need"
  echo ""
  echo "Commands:"
  echo "  • View file:     cat $SECRETS_FILE"
  echo "  • Edit file:     vim $SECRETS_FILE"
  echo ""
  echo "Encryption (choose one):"
  echo "  • Automatic:     ./scripts/setup/activate.sh (encrypts automatically)"
  echo "  • Manual:        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -e -i $SECRETS_FILE"
  echo ""
  echo "After encryption:"
  echo "  • View:          SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d $SECRETS_FILE"
  echo "  • Edit:          SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops $SECRETS_FILE"
  echo ""
  info "💡 Tip: Uncomment test_secret to verify encryption chain works"
  echo ""

  # Interactive secrets workflow checklist
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Secrets Review Checklist"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Before running ./scripts/setup/activate.sh, you should:"
  echo ""
  echo "  ☐ Review $SECRETS_FILE for sensitive data"
  echo "  ☐ Add any additional secrets (API keys, tokens)"
  echo "  ☐ Uncomment discovered secrets you want to keep"
  echo "  ☐ Remove/comment placeholders you don't need"
  echo "  ☐ Verify test_secret is uncommented (for validation)"
  echo ""
  echo "Ready to edit secrets now? This will open in your default editor."
  echo ""
  read -p "Open secrets.yaml for editing? [Y/n]: " edit_now

  if [[ ! $edit_now =~ ^[Nn]$ ]]; then
    # Detect editor preference
    EDITOR="${EDITOR:-${VISUAL:-vim}}"
    echo ""
    info "Opening $SECRETS_FILE in $EDITOR..."
    echo ""
    $EDITOR "$SECRETS_FILE"
    echo ""
    success "Secrets file edited"
  else
    info "You can edit later with: ${EDITOR:-vim} $SECRETS_FILE"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 Secrets Management Commands"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "After activation, use these commands to manage encrypted secrets:"
  echo ""
  echo "  Edit encrypted secrets:"
  echo "    edit-secrets"
  echo ""
  echo "  View encrypted secrets (decrypted):"
  echo "    view-secrets"
  echo ""
  echo "  Manual commands (if needed):"
  echo "    SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops $SECRETS_FILE"
  echo ""
}

# ============================================================================
# VERIFICATION CHECKLIST
# ============================================================================

show_verification_checklist() {
  print_header "📋 Comprehensive Pre-Activation Review"

  # Handle dry-run mode
  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] In a real run, this would show:"
    echo ""
    echo "  1. Generated configuration files (user-config.nix, machine-config.nix)"
    echo "  2. Generated directories (hosts/, home/, workspace/)"
    echo "  3. Secrets location and encryption status"
    echo "  4. Next steps checklist"
    echo ""
    success "[DRY RUN] Verification checklist would be displayed"
    echo ""
    return
  fi

  echo "Please review the following before running activate.sh:"
  echo ""

  # ============================================================
  # SECTION 1: Generated Configuration Files
  # ============================================================
  echo -e "${BOLD}${CYAN}1. Generated Configuration Files${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "User configuration:"
  cat "$REPO_ROOT/config/user-config.nix" | sed 's/^/  /'
  echo ""
  echo "Machine configuration:"
  cat "$REPO_ROOT/config/machine-config.nix" | sed 's/^/  /'
  echo ""

  # ============================================================
  # SECTION 2: Generated Directories
  # ============================================================
  echo -e "${BOLD}${CYAN}2. Generated Directories${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Host directory:"
  echo "  📁 nix-config/hosts/$MACHINE_ID/"
  echo "     Location: $REPO_ROOT/nix-config/hosts/$MACHINE_ID/"
  ls -1 "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/" | sed 's/^/     ├─ /'
  echo ""
  echo "Home directory:"
  echo "  📁 home/$USERNAME/"
  echo "     Location: $REPO_ROOT/home/$USERNAME/"
  echo "     ├─ (complete template structure copied)"
  echo ""

  # ============================================================
  # SECTION 3: Manual Review Commands
  # ============================================================
  echo -e "${BOLD}${CYAN}3. Manual Review Commands${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Verify generated configurations:"
  echo -e "  ${GREEN}cat config/user-config.nix${NC}       # User information"
  echo -e "  ${GREEN}cat config/machine-config.nix${NC}    # Machine type and settings"
  echo -e "  ${GREEN}cat nix-config/hosts/$MACHINE_ID/default.nix${NC}  # Host configuration"
  echo ""
  echo "Check directory structure:"
  echo -e "  ${GREEN}ls -la nix-config/hosts/$MACHINE_ID/${NC}     # Host files"
  echo -e "  ${GREEN}ls -la home/$USERNAME/${NC}  # Home configuration files"
  echo ""

  # ============================================================
  # SECTION 4: Secrets Setup Steps
  # ============================================================
  echo -e "${BOLD}${CYAN}4. Secrets Setup (SOPS Encryption)${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    success "Age key found: ~/.config/sops/age/keys.txt"
    echo ""
    echo "Create encrypted secrets file:"
    echo -e "  ${GREEN}sops nix-config/hosts/$MACHINE_ID/secrets.yaml${NC}"
    echo ""
    echo "Add your secrets following the structure in:"
    echo "  nix-config/hosts/$MACHINE_ID/secrets-$MACHINE_TYPE.nix"
  else
    warning "Age key not found!"
    echo ""
    echo "Generate age key first:"
    echo -e "  ${GREEN}age-keygen -o ~/.config/sops/age/keys.txt${NC}"
    echo ""
    echo "Then create encrypted secrets file:"
    echo -e "  ${GREEN}sops nix-config/hosts/$MACHINE_ID/secrets.yaml${NC}"
  fi
  echo ""
  info "See docs/guides/secrets.md for detailed SOPS setup"
  echo ""

  # ============================================================
  # SECTION 5: Pre-Activation Checklist
  # ============================================================
  echo -e "${BOLD}${CYAN}5. Pre-Activation Checklist${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Before running activate.sh, verify:"
  echo ""
  echo "  ☐ User information is correct (username, email, full name)"
  echo "  ☐ Machine type is correct ($MACHINE_TYPE)"
  echo "  ☐ Homebrew setting is correct (enabled: $HOMEBREW_ENABLED)"
  echo "  ☐ nix-config/hosts/$MACHINE_ID/default.nix looks good"
  echo "  ☐ home/$USERNAME/ directory structure is complete"
  echo "  ☐ Secrets are encrypted in nix-config/hosts/$MACHINE_ID/secrets.yaml (or will be created later)"
  echo ""

  # ============================================================
  # SECTION 6: Next Steps
  # ============================================================
  echo -e "${BOLD}${GREEN}✓ Ready to Activate${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Once verified, run the activation script:"
  echo -e "  ${BOLD}${GREEN}./scripts/setup/activate.sh${NC}"
  echo ""
  echo "This will:"
  echo "  1. Build your nix-darwin configuration"
  echo "  2. Activate the system changes"
  echo "  3. Set up your shell environment"
  echo ""
  warning "If build fails, you can rollback with: nix-rollback"
  echo ""
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

show_help() {
  cat << EOF
Nix-Darwin Configuration Script v${SCRIPT_VERSION}

Usage:
  ./configure.sh         # Interactive configuration setup
  ./configure.sh --force # Force reconfiguration (removes existing files)
  ./configure.sh --help  # Show this help

What this script does:
  1. Gathers user information (username, email, full name)
  2. Creates config/user-config.nix
  3. Creates config/machine-config.nix
  4. Creates hosts/{machineId}/ from template
  5. Creates home/{username}/ from template
  6. Provides verification checklist

Prerequisites:
  Run ./scripts/setup/bootstrap.sh first to install required tools:
    ././scripts/setup/bootstrap.sh

After configuration:
  Review the generated files, then run:
    ./scripts/setup/activate.sh

For more information:
  docs/guides/installation.md

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_help
      exit 0
      ;;
    --dry-run|-n)
      DRY_RUN=true
      info "Dry-run mode enabled - no changes will be made"
      echo ""
      ;;
    --force|-f)
      FORCE_MODE=true
      warning "Force mode enabled - existing files will be removed"
      echo ""
      ;;
    *)
      error "Unknown option: $1"
      echo ""
      show_help
      exit 1
      ;;
  esac
  shift
done

# Main execution
print_header "Nix-Darwin Configuration Wizard v${SCRIPT_VERSION}"

check_prerequisites
gather_user_info
create_config_files
create_hosts_directory
create_home_directory
create_workspace_directory
update_sops_yaml

# Ask user if they want to scan for existing secrets
print_step "◆ Secret Management"
echo ""
echo "Would you like to scan your system for existing secrets?"
echo "(API keys, credentials, SSH keys, tokens, etc.)"
echo ""
echo "This will search common locations like ~/.db/, ~/.tokens/, ~/.aws/, etc."
echo ""
read -p "Scan for existing secrets? [y/N] " -n 1 -r scan_choice
echo ""
echo ""

if [[ "$scan_choice" =~ ^[Yy]$ ]]; then
  scan_existing_secrets
else
  info "Skipping automatic secret scan"
  echo ""
  echo "📝 secrets.yaml will be created with template structure"
  echo ""
  echo "To manually add your existing secrets:"
  echo ""
  echo "1. Find secrets in common locations:"
  echo "   • ~/.aws/credentials - AWS credentials"
  echo "   • ~/.ssh/id_*     - SSH private keys"
  echo "   • ~/.db/          - Database credentials"
  echo "   • ~/.tokens/      - API tokens"
  echo "   • Shell configs   - grep 'export.*API_KEY' ~/.zshrc"
  echo ""
  echo "2. Edit the template: vim nix-config/hosts/$MACHINE_ID/secrets.yaml"
  echo "   • Fill in required keys (zsh_secrets, ssh_private_key, ssh_public_key)"
  echo "   • Uncomment optional sections you need"
  echo "   • Add custom secrets as needed"
  echo ""
  echo "3. Encryption happens automatically via ./scripts/setup/activate.sh"
  echo ""
fi

create_secrets_file
show_verification_checklist

print_header "✓ Configuration Complete"

success "Configuration files created"
success "Directory structure ready"
success ".sops.yaml configured with your age public key"
success "Plaintext secrets.yaml created (review before activation)"
echo ""

# Show proxy configuration reminder for work profiles
if [[ "$MACHINE_TYPE" == "work" ]]; then
  echo ""
  print_step "⚠️  Corporate Proxy Configuration"
  echo ""
  echo "If you're behind a corporate proxy, update ${CYAN}config/user-config.nix${NC} with your proxy settings:"
  echo ""
  echo "  ${BOLD}proxies = {${NC}"
  echo "    ${BOLD}go${NC} = { enabled = true; url = \"https://your-nexus.com/...\"; };"
  echo "    ${BOLD}python${NC} = { enabled = true; url = \"https://your-nexus.com/...\"; };"
  echo "    ${BOLD}npm${NC} = { enabled = true; url = \"https://your-nexus.com/...\"; };"
  echo "  ${BOLD}};${NC}"
  echo ""
  echo "This enables:"
  echo "  • Go module downloads (required for sops-nix)"
  echo "  • Python package installations via pip"
  echo "  • NPM package installations"
  echo ""
  echo "See ${CYAN}config/user-config.nix.template${NC} for full examples."
  echo ""
fi

print_step "▶ Next Step"
echo "Review the checklist above, then run the activation script:"
echo -e "  ${BOLD}${GREEN}./scripts/activate.sh${NC}"
echo ""
