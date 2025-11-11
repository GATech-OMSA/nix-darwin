#!/usr/bin/env bash
# Nix-Darwin Bootstrap Script
#
# One-time installation of prerequisites for nix-darwin
# Installs: Nix, nix-darwin, SOPS, age
#
# Usage:
#   ./bootstrap.sh        # Install all prerequisites
#   ./bootstrap.sh --help # Show help

set -e  # Exit on error
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_VERSION="1.0.0"
DRY_RUN=false

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
# NIX INSTALLATION
# ============================================================================

install_nix() {
  print_step "◆ Nix Installation"

  if command -v nix &>/dev/null; then
    success "Nix already installed"
    nix --version
    return
  fi

  info "Installing Nix package manager..."
  echo ""

  warning "This will:"
  echo "  • Create /nix directory"
  echo "  • Install Nix daemon"
  echo "  • Modify shell configuration"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would run: sh <(curl -L https://nixos.org/nix/install) --daemon"
    echo ""
    return
  fi

  read -p "Continue with Nix installation? [Y/n]: " confirm
  if [[ $confirm =~ ^[Nn]$ ]]; then
    error "Nix installation cancelled"
    exit 1
  fi

  echo ""
  info "Running Nix installer (multi-user mode)..."

  # Run official Nix installer
  sh <(curl -L https://nixos.org/nix/install) --daemon

  success "Nix installed successfully"
  echo ""

  # Source nix-daemon for current session
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi

  echo ""
}

# ============================================================================
# NIX-DARWIN INSTALLATION
# ============================================================================

install_nix_darwin() {
  print_step "◆ Nix-Darwin Installation"

  if command -v darwin-rebuild &>/dev/null; then
    success "nix-darwin already installed"
    return
  fi

  info "Installing nix-darwin..."
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would enable experimental features in ~/.config/nix/nix.conf"
    info "[DRY RUN] Would run: nix run nix-darwin -- switch --flake ."
    echo ""
    return
  fi

  # Enable experimental features for flakes
  mkdir -p ~/.config/nix
  cat > ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF

  info "Nix experimental features enabled (flakes)"
  echo ""

  # Build and activate initial nix-darwin configuration
  info "Running initial nix-darwin build..."
  echo ""

  warning "This will perform the first system build"
  info "Location: $(pwd)"
  echo ""

  read -p "Continue with nix-darwin installation? [Y/n]: " confirm
  if [[ $confirm =~ ^[Nn]$ ]]; then
    error "nix-darwin installation cancelled"
    exit 1
  fi

  echo ""

  # Run nix-darwin installer
  nix run nix-darwin -- switch --flake .

  success "nix-darwin installed successfully"
  echo ""
}

# ============================================================================
# SOPS INSTALLATION
# ============================================================================

install_sops() {
  print_step "◆ SOPS Installation"

  if command -v sops &>/dev/null; then
    success "SOPS already installed"
    sops --version
    return
  fi

  info "Installing SOPS (Secrets OPerationS)..."
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would run: nix-env -iA nixpkgs.sops"
    echo ""
    return
  fi

  # Install via nix-env
  nix-env -iA nixpkgs.sops

  if command -v sops &>/dev/null; then
    success "SOPS installed successfully"
    sops --version
  else
    error "SOPS installation failed"
    exit 1
  fi

  echo ""
}

# ============================================================================
# AGE INSTALLATION
# ============================================================================

install_age() {
  print_step "◆ Age Installation"

  if command -v age &>/dev/null; then
    success "age already installed"
    age --version
    return
  fi

  info "Installing age (encryption tool)..."
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would run: nix-env -iA nixpkgs.age"
    echo ""
    return
  fi

  # Install via nix-env
  nix-env -iA nixpkgs.age

  if command -v age &>/dev/null; then
    success "age installed successfully"
    age --version
  else
    error "age installation failed"
    exit 1
  fi

  echo ""
}

# ============================================================================
# VERIFICATION
# ============================================================================

verify_installation() {
  print_step "✓ Verification"

  echo "Checking installed tools..."
  echo ""

  local all_installed=true

  # Nix
  if command -v nix &>/dev/null; then
    success "Nix: $(nix --version | head -1)"
  else
    error "Nix: Not found"
    all_installed=false
  fi

  # nix-darwin
  if command -v darwin-rebuild &>/dev/null; then
    success "nix-darwin: Installed"
  else
    error "nix-darwin: Not found"
    all_installed=false
  fi

  # SOPS
  if command -v sops &>/dev/null; then
    success "SOPS: $(sops --version | head -1)"
  else
    error "SOPS: Not found"
    all_installed=false
  fi

  # age
  if command -v age &>/dev/null; then
    success "age: $(age --version | head -1)"
  else
    error "age: Not found"
    all_installed=false
  fi

  # git
  if command -v git &>/dev/null; then
    success "git: $(git --version)"
  else
    warning "git: Not found (usually pre-installed on macOS)"
  fi

  echo ""

  if [ "$all_installed" = false ]; then
    error "Some tools failed to install"
    exit 1
  fi

  success "All prerequisites installed successfully"
  echo ""
}

# ============================================================================
# AGE KEY GENERATION
# ============================================================================

setup_age_key() {
  print_step "◆ SOPS Age Key Setup"

  local AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

  # Check if key already exists
  if [ -f "$AGE_KEY_FILE" ]; then
    success "Age key already exists: $AGE_KEY_FILE"
    echo ""

    # Extract and display public key
    local AGE_PUBLIC_KEY=$(grep "# public key:" "$AGE_KEY_FILE" | cut -d: -f2 | tr -d ' ')

    if [ -n "$AGE_PUBLIC_KEY" ]; then
      info "Your public key: $AGE_PUBLIC_KEY"
      echo ""
      info "This key will be used to encrypt secrets in configure.sh"
      info "Backup will be created in configure.sh in user-data-{username}/ directory"
    else
      warning "Could not extract public key from existing key file"
    fi

    echo ""
    return
  fi

  # Generate new age key
  info "Generating new age encryption key..."
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would generate age key at: $AGE_KEY_FILE"
    info "[DRY RUN] Public key: age1dry-run-example-key-123"
    echo ""
    return
  fi

  mkdir -p "$(dirname "$AGE_KEY_FILE")"

  # Generate key and capture output
  age-keygen -o "$AGE_KEY_FILE" 2>&1 | tee /tmp/age-keygen-output.txt
  local AGE_PUBLIC_KEY=$(grep "Public key:" /tmp/age-keygen-output.txt | cut -d: -f2 | tr -d ' ')
  rm -f /tmp/age-keygen-output.txt

  chmod 600 "$AGE_KEY_FILE"

  echo ""
  success "Age key generated successfully"
  echo ""

  # Display critical backup information
  echo -e "${BOLD}${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${RED}             🔒 CRITICAL: BACKUP YOUR KEY NOW 🔒${NC}"
  echo -e "${BOLD}${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}Key location:${NC} $AGE_KEY_FILE"
  echo -e "${BOLD}Public key:${NC}   $AGE_PUBLIC_KEY"
  echo ""
  echo -e "${YELLOW}⚠ WITHOUT THIS KEY, YOU CANNOT DECRYPT YOUR SECRETS!${NC}"
  echo ""
  echo "📦 Automatic backup will be created in configure.sh"
  echo "   Location: user-data-{username}/backups/age-keys/"
  echo ""
  echo "Additional recommended backup methods:"
  echo "  1. Password manager (1Password, Bitwarden, etc.)"
  echo "  2. USB drive (encrypted)"
  echo "  3. Paper backup (secure location)"
  echo "  4. Encrypted cloud storage"
  echo ""
  echo "Commands to backup:"
  echo "  # Copy to clipboard (macOS):"
  echo "  cat $AGE_KEY_FILE | pbcopy"
  echo ""
  echo "  # View key file:"
  echo "  cat $AGE_KEY_FILE"
  echo ""

  # Force user confirmation
  while true; do
    read -p "Have you saved your key securely? (yes/no): " confirm
    case $confirm in
      [Yy]es|[Yy])
        success "Key backup confirmed"
        echo ""
        break
        ;;
      [Nn]o|[Nn])
        warning "Please backup your key before continuing"
        echo ""
        ;;
      *)
        warning "Please answer 'yes' or 'no'"
        ;;
    esac
  done
}

# ============================================================================
# GUM INSTALLATION (for future UI enhancements)
# ============================================================================

install_gum() {
  print_step "◆ Installing Gum (UI Tool)"

  if command -v gum &>/dev/null; then
    success "gum already installed: $(gum --version)"
    echo ""
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would install gum via Nix"
    echo ""
    return
  fi

  info "Installing gum for enhanced terminal UI..."
  echo ""

  if nix-env -iA nixpkgs.gum; then
    success "gum installed successfully"
  else
    warning "gum installation failed - continuing without it"
    info "Scripts will work without gum, just with simpler UI"
  fi

  echo ""
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

show_help() {
  cat << EOF
Nix-Darwin Bootstrap Script v${SCRIPT_VERSION}

Usage:
  ./bootstrap.sh        # Install all prerequisites
  ./bootstrap.sh --help # Show this help

What this script installs:
  1. Nix package manager (multi-user mode)
  2. nix-darwin (macOS configuration framework)
  3. SOPS (secrets encryption)
  4. age (encryption tool for SOPS)

Prerequisites:
  • macOS 10.12 or later
  • Administrator access (for /nix creation)
  • Internet connection

After bootstrap:
  Run the configuration script:
    ./scripts/setup/configure.sh

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
print_header "Nix-Darwin Bootstrap v${SCRIPT_VERSION}"

warning "This script will install system-wide tools"
echo "Prerequisites to install:"
echo "  • Nix package manager"
echo "  • nix-darwin"
echo "  • SOPS"
echo "  • age"
echo ""

read -p "Continue with installation? [Y/n]: " proceed
if [[ $proceed =~ ^[Nn]$ ]]; then
  info "Installation cancelled"
  exit 0
fi

install_nix
install_nix_darwin
install_sops
install_age
verify_installation
setup_age_key
install_gum

print_header "✓ Bootstrap Complete"

success "All prerequisites installed"
success "Age encryption key generated and backed up"
info "Your age public key will be used in configure.sh to set up .sops.yaml"
echo ""

print_step "▶ Next Step"
echo "Run the configuration script:"
echo -e "  ${BOLD}${GREEN}./scripts/configure${NC}"
echo ""

