#!/usr/bin/env bash
# Nix-Darwin Activation Script
#
# Non-interactive system build and activation
# Applies the nix-darwin configuration to your system
#
# Usage:
#   ./activate.sh        # Standard activation
#   ./activate.sh --help # Show help

set -e  # Exit on error
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_VERSION="1.0.0"
DRY_RUN=false

# Export age key location for SOPS
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_config_files() {
  print_step "◆ Checking Configuration Files"

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would check for required configuration files:"
    echo "  • config/user-config.nix"
    echo "  • config/machine-config.nix"
    echo "  • nix-config/hosts/{machineId}/"
    echo ""
    info "[DRY RUN] Configuration check would ensure all files exist before activation"
    echo ""
    return
  fi

  local missing_files=()

  # Check user-config.nix
  if [ -f "$REPO_ROOT/config/user-config.nix" ]; then
    success "config/user-config.nix found"
  else
    missing_files+=("config/user-config.nix")
    error "config/user-config.nix not found"
  fi

  # Check machine-config.nix
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    success "config/machine-config.nix found"
  else
    missing_files+=("config/machine-config.nix")
    error "config/machine-config.nix not found"
  fi

  # Extract machineId from machine-config.nix (if it exists)
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    local machine_id=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | cut -d '"' -f 2)

    # Check host directory exists
    if [ -d "$REPO_ROOT/nix-config/hosts/$machine_id" ]; then
      success "nix-config/hosts/$machine_id/ directory found"
    else
      missing_files+=("nix-config/hosts/$machine_id/")
      error "nix-config/hosts/$machine_id/ directory not found"
    fi
  fi

  echo ""

  if [ ${#missing_files[@]} -gt 0 ]; then
    error "Missing configuration files/directories: ${missing_files[*]}"
    echo ""
    echo "Run configure.sh first to create configuration:"
    echo "  ./scripts/setup/configure.sh"
    exit 1
  fi

  success "All required configuration files present"
  echo ""
}

check_and_handle_secrets() {
  print_step "◆ Secret Encryption Status"

  # Extract machineId from machine-config.nix
  local machine_id=$(grep 'machineId' "$REPO_ROOT/config/machine-config.nix" | cut -d '"' -f 2)
  local SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$machine_id/secrets.yaml"

  # Check if secrets file exists
  if [ ! -f "$SECRETS_FILE" ]; then
    info "No secrets.yaml found - skipping secret handling"
    echo ""
    return
  fi

  # Check if file is already encrypted (contains "sops:" marker)
  if grep -q "sops:" "$SECRETS_FILE" 2>/dev/null; then
    info "secrets.yaml is encrypted"
    echo ""

    # Verify we can decrypt (test age keys work)
    info "Verifying age keys can decrypt secrets..."
    echo ""

    if sops -d "$SECRETS_FILE" > /dev/null 2>&1; then
      success "Age keys verified - decryption works"
      echo ""
      info "To view or edit encrypted secrets:"
      echo "  • View:  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d $SECRETS_FILE"
      echo "  • Edit:  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops $SECRETS_FILE"
      echo ""
      # Continue to build (nix-darwin uses encrypted file, sops-nix decrypts during build)
      return
    else
      error "Cannot decrypt secrets.yaml with current age keys"
      echo ""
      echo "This usually means:"
      echo "  • secrets.yaml was restored from another machine"
      echo "  • .sops.yaml has wrong public key"
      echo "  • Age private key is missing or incorrect"
      echo ""
      echo "Troubleshooting steps:"
      echo ""
      echo "1. Check your age public key:"
      echo "   age-keygen -y ~/.config/sops/age/keys.txt"
      echo ""
      echo "2. Verify it matches .sops.yaml:"
      echo "   cat .sops.yaml | grep age1"
      echo ""
      echo "3. If keys don't match, update .sops.yaml with your current public key"
      echo ""
      echo "4. Or re-create secrets.yaml from scratch:"
      echo "   rm $SECRETS_FILE"
      echo "    ./scripts/setup/configure.sh"
      echo ""
      exit 1
    fi
  fi

  # File exists and is plaintext - handle encryption
  warning "secrets.yaml is plaintext (unencrypted)"
  info "Will encrypt with SOPS before activation..."
  echo ""

  # Check for placeholder values before encryption (only uncommented lines)
  info "Checking for placeholder values in uncommented lines..."
  echo ""

  local placeholder_patterns=(
    'sk-\.\.\.'
    'ghp_\.\.\.'
    'sk-ant-\.\.\.'
    'REPLACE_WITH_'
    'AAAAC3NzaC1lZDI1NTE5AAAAI\.\.\.'
    'your_key_here'
    'YOUR_ACCESS_KEY'
    'YOUR_SECRET'
    'AKIA\.\.\.'
    'user@hostname'
    'localhost:5432'
  )

  # Only check UNCOMMENTED lines (exclude lines starting with #)
  local found_placeholders=false
  for pattern in "${placeholder_patterns[@]}"; do
    if grep -v '^\s*#' "$SECRETS_FILE" | grep -qE "$pattern" 2>/dev/null; then
      found_placeholders=true
      break
    fi
  done

  if [ "$found_placeholders" = true ]; then
    error "Placeholder values detected in UNCOMMENTED secrets.yaml lines"
    echo ""
    echo "Found placeholder patterns in active (uncommented) lines:"
    echo ""
    grep -n -v '^\s*#' "$SECRETS_FILE" | grep -E 'sk-\.\.\.|ghp_\.\.\.|REPLACE_WITH_|AAAAC3|your_key_here|YOUR_|AKIA\.\.\.|user@hostname|localhost:5432' | head -10
    echo ""
    echo "Please edit secrets.yaml and replace all placeholder values:"
    echo "  vim $SECRETS_FILE"
    echo ""
    echo "Note: Commented placeholders (lines starting with #) are safe and ignored."
    echo ""
    exit 1
  fi

  success "No placeholder values detected in uncommented lines"
  echo ""

  # Encrypt in place
  info "Encrypting secrets.yaml..."
  echo ""

  if sops -e -i "$SECRETS_FILE"; then
    success "secrets.yaml encrypted successfully"
    echo ""
    info "To view or edit encrypted secrets:"
    echo "  • View:  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d $SECRETS_FILE"
    echo "  • Edit:  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops $SECRETS_FILE"
    echo ""
  else
    error "Failed to encrypt secrets.yaml"
    echo ""
    echo "Please check:"
    echo "  • SOPS is installed: brew install sops"
    echo "  • Age key exists: ls ~/.config/sops/age/keys.txt"
    echo "  • .sops.yaml is configured correctly"
    echo ""
    echo "Or encrypt manually:"
    echo "  sops -e -i $SECRETS_FILE"
    echo ""
    exit 1
  fi
}

# ============================================================================
# BUILD AND ACTIVATION
# ============================================================================

build_and_activate() {
  print_step "◆ Building and Activating Nix-Darwin Configuration"

  info "This will:"
  echo "  • Build your nix-darwin configuration"
  echo "  • Install/update packages"
  echo "  • Apply system settings"
  echo "  • Activate Home Manager configuration"
  echo ""

  # Extract machineId for dry-run display
  MACHINE_ID_DISPLAY=$(grep -E '^\s*machineId\s*=' "$REPO_ROOT/config/machine-config.nix" | sed -E 's/.*"(.*)".*/\1/' || echo "unknown")

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would run: darwin-rebuild switch --flake $REPO_ROOT#$MACHINE_ID_DISPLAY"
    echo ""
    info "[DRY RUN] This would:"
    echo "  • Build the nix-darwin system configuration"
    echo "  • Install packages defined in modules/shared/packages.nix"
    echo "  • Apply system settings from modules/darwin/"
    echo "  • Activate Home Manager configuration from home/$USERNAME/"
    echo "  • Generate managed files (~/.zshrc, ~/.config/git/config, etc.)"
    echo ""
    success "[DRY RUN] Build simulation complete"
    echo ""
    return
  fi

  warning "This may take several minutes on first run (downloading packages)"
  echo ""

  read -p "Continue? [Y/n]: " confirm
  if [[ $confirm =~ ^[Nn]$ ]]; then
    info "Activation cancelled"
    exit 0
  fi

  echo ""
  info "Running darwin-rebuild switch (requires sudo)..."
  echo ""

  # Export FLAKE_ROOT for gitignored config imports
  export FLAKE_ROOT="$REPO_ROOT"

  # Extract machineId from config/machine-config.nix
  MACHINE_ID=$(grep -E '^\s*machineId\s*=' "$REPO_ROOT/config/machine-config.nix" | sed -E 's/.*"(.*)".*/\1/')

  if [ -z "$MACHINE_ID" ]; then
    error "Could not extract machineId from config/machine-config.nix"
    exit 1
  fi

  info "Building configuration for: $MACHINE_ID"
  echo ""

  # Run darwin-rebuild with flake (requires sudo for system activation)
  # --impure flag is required because we use builtins.getEnv for gitignored configs
  # Explicitly specify the configuration name using #machineId
  if sudo FLAKE_ROOT="$FLAKE_ROOT" darwin-rebuild switch --flake "$REPO_ROOT#$MACHINE_ID" --impure; then
    echo ""
    success "Build and activation complete!"
  else
    echo ""
    error "Build failed!"
    echo ""
    echo "Common issues:"
    echo "  • Syntax error in .nix files → Check: nix flake check"
    echo "  • Missing dependencies → Check: nix flake update"
    echo "  • Permission issues → Check: sudo permissions"
    echo ""
    echo "For detailed error output, run:"
    echo "  sudo FLAKE_ROOT=\"\$PWD\" darwin-rebuild switch --flake .#$MACHINE_ID --impure --show-trace"
    exit 1
  fi

  echo ""
}

# ============================================================================
# POST-ACTIVATION
# ============================================================================

post_activation_steps() {
  print_step "◆ Post-Activation Steps"

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] After real activation, you would:"
    echo "  1. Restart your shell: exec zsh"
    echo "  2. Verify packages: which git starship fzf"
    echo "  3. Test aliases: alias | grep git"
    echo ""
    return
  fi

  echo "Your nix-darwin configuration is now active!"
  echo ""

  echo -e "${BOLD}Next steps:${NC}"
  echo ""

  echo "1. Restart your shell to load new environment:"
  echo -e "   ${GREEN}exec zsh${NC}"
  echo ""

  echo "2. Verify installation:"
  echo "   • Check packages: which git starship fzf"
  echo "   • Test aliases: alias | grep git"
  echo "   • Verify shell: echo \$SHELL"
  echo ""

  echo "3. Optional: Review generated files:"
  echo "   • ~/.zshrc (managed by nix-darwin)"
  echo "   • ~/.config/git/config (managed by Home Manager)"
  echo "   • ~/.config/starship.toml (managed by Home Manager)"
  echo ""

  warning "Remember: Edit source .nix files, not generated configs"
  info "After changes: nix-rebuild && exec zsh"
  echo ""
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

show_help() {
  cat << EOF
Nix-Darwin Activation Script v${SCRIPT_VERSION}

Usage:
  ./activate.sh        # Build and activate configuration
  ./activate.sh --help # Show this help

What this script does:
  1. Verifies configuration files exist
  2. Runs darwin-rebuild switch --flake .
  3. Activates your nix-darwin configuration
  4. Provides post-activation instructions

Three-Script Setup Workflow:
  1. ./scripts/bootstrap.sh  → Install prerequisites (Nix, nix-darwin, SOPS, age)
  2. ./scripts/setup/configure.sh  → Create configuration files and directories
  3. ./scripts/activate.sh   → Build and activate system (this script)

Prerequisites:
  Configuration files must exist:
    • config/user-config.nix
    • config/machine-config.nix
    • nix-config/hosts/{machineId}/

  If missing, run:
    ./scripts/setup/configure.sh

After activation:
  Restart your shell:
    exec zsh

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
print_header "Nix-Darwin Activation v${SCRIPT_VERSION}"

check_config_files
check_and_handle_secrets
build_and_activate
post_activation_steps

print_header "✓ Activation Complete"

print_step "▶ Next Step"
echo "Restart your shell to load the new environment:"
echo -e "  ${BOLD}${GREEN}exec zsh${NC}"
echo ""
