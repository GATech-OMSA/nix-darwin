#!/bin/bash

# ============================================================================
# install-prerequisites.sh - Install Nix + SOPS + age prerequisites
# ============================================================================
#
# This script installs the required tools for nix-darwin setup:
#   - Nix package manager (Determinate Systems installer)
#   - SOPS (secrets encryption)
#   - age (encryption backend for SOPS)
#
# Usage:
#   ./scripts/install-prerequisites.sh
#
# What it does:
#   1. Checks if each tool is already installed
#   2. Installs missing tools
#   3. Verifies successful installation
#   4. Provides next steps
#
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() {
  echo -e "${BLUE}ℹ${NC}  $*"
}

success() {
  echo -e "${GREEN}✓${NC}  $*"
}

warning() {
  echo -e "${YELLOW}⚠${NC}  $*"
}

error() {
  echo -e "${RED}✗${NC}  $*"
}

step() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$*${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

step "Step 1: System Requirements Check"

info "Checking system requirements..."
echo ""

# Check macOS version
if ! sw_vers &>/dev/null; then
  error "This script is for macOS only"
  exit 1
fi

macos_version=$(sw_vers -productVersion)
success "macOS version: $macos_version"

# Check admin access
if ! sudo -n true 2>/dev/null; then
  info "This script requires sudo access"
  echo ""
  sudo -v
fi
success "Admin access confirmed"

# Check Command Line Tools
if ! xcode-select -p &>/dev/null; then
  warning "Xcode Command Line Tools not installed"
  info "Installing Command Line Tools..."
  xcode-select --install
  echo ""
  error "Please install Command Line Tools and run this script again"
  exit 1
fi
success "Command Line Tools installed"

# Check disk space (need ~10GB)
available_space=$(df -g . | awk 'NR==2 {print $4}')
if [[ $available_space -lt 10 ]]; then
  warning "Low disk space: ${available_space}GB available (10GB+ recommended)"
else
  success "Disk space: ${available_space}GB available"
fi

echo ""
success "All system requirements satisfied"

# ============================================================================
# NIX INSTALLATION
# ============================================================================

step "Step 2: Nix Package Manager Installation"

if command -v nix &>/dev/null; then
  nix_version=$(nix --version | head -n1)
  success "Nix already installed: $nix_version"
  info "Skipping Nix installation"
else
  info "Installing Nix package manager..."
  echo ""
  info "Using Determinate Systems installer (recommended)"
  info "This installer provides:"
  echo "  • Multi-user installation"
  echo "  • Flakes enabled by default"
  echo "  • Better macOS integration"
  echo ""

  # Install Nix
  if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; then
    success "Nix installed successfully"

    # Source Nix for current session
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      # shellcheck source=/dev/null
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      success "Nix environment loaded for current session"
    fi

    # Verify installation
    if command -v nix &>/dev/null; then
      nix_version=$(nix --version | head -n1)
      success "Verified: $nix_version"
    else
      warning "Nix installed but not in PATH"
      info "Please restart your terminal and run this script again"
      exit 0
    fi
  else
    error "Nix installation failed"
    exit 1
  fi
fi

# ============================================================================
# SOPS INSTALLATION
# ============================================================================

step "Step 3: SOPS Installation"

if command -v sops &>/dev/null; then
  sops_version=$(sops --version 2>&1 | head -n1)
  success "SOPS already installed: $sops_version"
  info "Skipping SOPS installation"
else
  info "Installing SOPS (secrets encryption tool)..."
  echo ""

  # Check if Nix is available
  if ! command -v nix-env &>/dev/null; then
    error "Nix not found in PATH"
    info "Please restart your terminal and run this script again"
    exit 1
  fi

  # Install SOPS via Nix
  if nix-env -iA nixpkgs.sops; then
    success "SOPS installed successfully"

    # Verify installation
    if command -v sops &>/dev/null; then
      sops_version=$(sops --version 2>&1 | head -n1)
      success "Verified: $sops_version"
    else
      error "SOPS installation verification failed"
      exit 1
    fi
  else
    error "SOPS installation failed"
    exit 1
  fi
fi

# ============================================================================
# AGE INSTALLATION
# ============================================================================

step "Step 4: age Installation"

if command -v age &>/dev/null; then
  age_version=$(age --version 2>&1 | head -n1)
  success "age already installed: $age_version"
  info "Skipping age installation"
else
  info "Installing age (encryption backend for SOPS)..."
  echo ""

  # Check if Nix is available
  if ! command -v nix-env &>/dev/null; then
    error "Nix not found in PATH"
    info "Please restart your terminal and run this script again"
    exit 1
  fi

  # Install age via Nix
  if nix-env -iA nixpkgs.age; then
    success "age installed successfully"

    # Verify installation
    if command -v age &>/dev/null; then
      age_version=$(age --version 2>&1 | head -n1)
      success "Verified: $age_version"
    else
      error "age installation verification failed"
      exit 1
    fi
  else
    error "age installation failed"
    exit 1
  fi
fi

# ============================================================================
# FINAL VERIFICATION
# ============================================================================

step "Step 5: Final Verification"

info "Verifying all prerequisites..."
echo ""

all_good=true

# Check Nix
if command -v nix &>/dev/null; then
  nix_version=$(nix --version | head -n1)
  success "Nix: $nix_version"
else
  error "Nix: NOT FOUND"
  all_good=false
fi

# Check SOPS
if command -v sops &>/dev/null; then
  sops_version=$(sops --version 2>&1 | head -n1)
  success "SOPS: $sops_version"
else
  error "SOPS: NOT FOUND"
  all_good=false
fi

# Check age
if command -v age &>/dev/null; then
  age_version=$(age --version 2>&1 | head -n1)
  success "age: $age_version"
else
  error "age: NOT FOUND"
  all_good=false
fi

# Check git (usually pre-installed on macOS)
if command -v git &>/dev/null; then
  git_version=$(git --version)
  success "git: $git_version"
else
  warning "git: NOT FOUND (should be in Command Line Tools)"
  all_good=false
fi

echo ""

if [[ $all_good == true ]]; then
  success "All prerequisites installed successfully!"
else
  error "Some prerequisites are missing"
  info "Please restart your terminal and verify installation"
  exit 1
fi

# ============================================================================
# NEXT STEPS
# ============================================================================

step "Next Steps"

echo "Prerequisites are now installed. You can proceed with nix-darwin setup:"
echo ""
echo "  1. Clone the repository (if not already):"
echo "     ${GREEN}git clone https://github.com/YOUR-USERNAME/nix-darwin.git ~/nix-darwin${NC}"
echo "     ${GREEN}cd ~/nix-darwin${NC}"
echo ""
echo "  2. Run the setup script:"
echo "     ${GREEN}./setup.sh${NC}"
echo ""
echo "     The setup script will:"
echo "       • Scan for existing secrets (AWS, SSH, DB, tokens)"
echo "       • Discover configurations (git, VS Code, etc.)"
echo "       • Encrypt secrets with SOPS"
echo "       • Create backups"
echo "       • Install nix-darwin"
echo ""
echo "  3. Or manually install nix-darwin:"
echo "     ${GREEN}sudo scutil --set HostName mbp-jimmy${NC}  # or mbp-work"
echo "     ${GREEN}sudo nix run nix-darwin -- switch --flake .#mbp-jimmy${NC}"
echo ""
echo "Documentation:"
echo "  • Quickstart:  ${BLUE}docs/QUICKSTART.md${NC}"
echo "  • Setup Guide: ${BLUE}README.md${NC}"
echo "  • Full Docs:   ${BLUE}docs/index.md${NC}"
echo ""
success "Setup prerequisites complete! 🚀"
echo ""
