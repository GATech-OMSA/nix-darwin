#!/usr/bin/env bash

# ============================================================================
# CLEANUP SCRIPT
# ============================================================================
#
# Removes all generated configuration files and directories created by
# configure.sh to allow starting fresh
#
# Usage:
#   ./cleanup.sh           # Interactive mode with confirmations
#   ./cleanup.sh --force   # Skip confirmations (dangerous!)
#
# What gets removed:
#   - config/user-config.nix
#   - config/machine-config.nix
#   - hosts/$MACHINE_ID/
#   - workspace/$MACHINE_ID/
#   - Test secret files in ~/.db, ~/.tokens, ~/.credentials, ~/.env.test
#

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$SCRIPT_DIR"
FORCE=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --force)
      FORCE=true
      shift
      ;;
  esac
done

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

info() {
  echo -e "${BLUE}[i]${NC}  $*"
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

print_step() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$*${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

banner() {
  echo ""
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}║              nix-darwin Cleanup Script                ║${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}║       Remove all generated configuration files        ║${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ============================================================================
# DETECTION
# ============================================================================

detect_machine_id() {
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    grep 'machineId =' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/'
  fi
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

cleanup_config_files() {
  print_step "🗑️  Removing Config Files"

  local removed=0

  if [ -f "$REPO_ROOT/config/user-config.nix" ]; then
    info "Removing: config/user-config.nix"
    rm -f "$REPO_ROOT/config/user-config.nix"
    success "Removed user-config.nix"
    removed=$((removed + 1))
  fi

  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    info "Removing: config/machine-config.nix"
    rm -f "$REPO_ROOT/config/machine-config.nix"
    success "Removed machine-config.nix"
    removed=$((removed + 1))
  fi

  if [ $removed -eq 0 ]; then
    info "No config files to remove"
  fi

  echo ""
}

cleanup_host_directory() {
  local MACHINE_ID=$1

  if [ -z "$MACHINE_ID" ]; then
    warning "No machine ID detected, skipping host directory cleanup"
    return
  fi

  print_step "🗑️  Removing Host Directory"

  if [ -d "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" ]; then
    info "Removing: nix-config/hosts/$MACHINE_ID/"

    # Show what will be removed
    echo ""
    info "Contents:"
    ls -la "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" 2>/dev/null | tail -n +4 | awk '{print "   " $9}'
    echo ""

    rm -rf "$REPO_ROOT/nix-config/hosts/$MACHINE_ID"
    success "Removed nix-config/hosts/$MACHINE_ID/"
  else
    info "No host directory to remove: nix-config/hosts/$MACHINE_ID/"
  fi

  echo ""
}

cleanup_workspace_directory() {
  local MACHINE_ID=$1

  if [ -z "$MACHINE_ID" ]; then
    warning "No machine ID detected, skipping workspace cleanup"
    return
  fi

  print_step "🗑️  Removing Workspace Directory"

  if [ -d "$REPO_ROOT/workspace/$MACHINE_ID" ]; then
    info "Removing: workspace/$MACHINE_ID/"

    # Show what will be removed
    echo ""
    info "Contents:"
    du -sh "$REPO_ROOT/workspace/$MACHINE_ID"/* 2>/dev/null | awk '{print "   " $2 " (" $1 ")"}'
    echo ""

    rm -rf "$REPO_ROOT/workspace/$MACHINE_ID"
    success "Removed workspace/$MACHINE_ID/"
  else
    info "No workspace directory to remove: workspace/$MACHINE_ID/"
  fi

  echo ""
}

# Removed - test secrets should remain for testing configure.sh secret scanning

cleanup_test_script() {
  print_step "🗑️  Removing Test Script"

  if [ -f "$REPO_ROOT/test-secret-scan.sh" ]; then
    info "Removing: test-secret-scan.sh"
    rm -f "$REPO_ROOT/test-secret-scan.sh"
    success "Removed test-secret-scan.sh"
  else
    info "No test script to remove"
  fi

  echo ""
}

# ============================================================================
# CONFIRMATION
# ============================================================================

show_removal_summary() {
  local MACHINE_ID=$1

  echo ""
  echo -e "${BOLD}${YELLOW}⚠️  Warning: The following will be removed:${NC}"
  echo ""
  echo "  📄 Configuration Files:"
  [ -f "$REPO_ROOT/config/user-config.nix" ] && echo "     • config/user-config.nix"
  [ -f "$REPO_ROOT/config/machine-config.nix" ] && echo "     • config/machine-config.nix"
  echo ""

  if [ -n "$MACHINE_ID" ]; then
    echo "  🖥️  Machine-Specific ($MACHINE_ID):"
    [ -d "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" ] && echo "     • nix-config/hosts/$MACHINE_ID/"
    [ -d "$REPO_ROOT/workspace/$MACHINE_ID" ] && echo "     • workspace/$MACHINE_ID/"
    echo ""
  fi


  echo "  🧪 Test Scripts:"
  [ -f "$REPO_ROOT/test-secret-scan.sh" ] && echo "     • test-secret-scan.sh"
  echo ""

  echo -e "${BOLD}${RED}⚠️  This action CANNOT be undone!${NC}"
  echo ""
}

confirm_cleanup() {
  if [ "$FORCE" = true ]; then
    warning "Running in --force mode, skipping confirmation"
    return 0
  fi

  read -p "Are you sure you want to proceed? (yes/no): " confirmation

  case "$confirmation" in
    yes|YES|Yes)
      return 0
      ;;
    *)
      echo ""
      info "Cleanup cancelled"
      exit 0
      ;;
  esac
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
  banner

  info "Detecting existing configuration..."
  local MACHINE_ID=$(detect_machine_id)

  if [ -n "$MACHINE_ID" ]; then
    success "Detected machine ID: $MACHINE_ID"
  else
    warning "No machine ID detected (config/machine-config.nix not found)"
  fi

  echo ""

  show_removal_summary "$MACHINE_ID"
  confirm_cleanup

  echo ""
  print_step "🚀 Starting Cleanup"

  cleanup_config_files
  cleanup_host_directory "$MACHINE_ID"
  cleanup_workspace_directory "$MACHINE_ID"
  cleanup_test_script

  print_step "✅ Cleanup Complete"

  echo ""
  echo -e "${BOLD}${GREEN}All generated files have been removed!${NC}"
  echo ""
  echo -e "${CYAN}Next steps:${NC}"
  echo "  1. Run configure script to start fresh:"
  echo "     ${BOLD}./configure.sh${NC}  (original version)"
  echo "     ${BOLD}./configure-v3.sh${NC}  (paginated wizard)"
  echo ""
  echo "  2. Or configure with dry-run to preview:"
  echo "     ${BOLD}./configure-v3.sh --dry-run${NC}"
  echo ""
}

main
