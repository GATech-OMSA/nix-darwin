#!/usr/bin/env bash

# ============================================================================
# CLEANUP TEST CREDENTIALS
# ============================================================================
#
# Removes test credential files created by create-test-credentials.sh
#
# Usage:
#   ./tests/cleanup-test-credentials.sh           # Interactive mode
#   ./tests/cleanup-test-credentials.sh --force   # Skip confirmation
#
# What gets removed:
#   - ~/.db/production           (database credentials)
#   - ~/.tokens/github           (API token)
#   - ~/.credentials/stripe      (API key)
#   - ~/.env.test                (environment variables)
#   - Empty directories: ~/.db/, ~/.tokens/, ~/.credentials/
#

set -e

# Parse arguments
FORCE=false
for arg in "$@"; do
  case $arg in
    --force)
      FORCE=true
      shift
      ;;
  esac
done

# Colors
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
  echo -e "${BOLD}${CYAN}║        Cleanup Test Credentials from System           ║${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

show_removal_summary() {
  echo ""
  echo -e "${BOLD}${YELLOW}warning: the following test credentials will be removed:${NC}"
  echo ""

  local found_any=false

  if [ -f "$HOME/.db/production" ]; then
    [ "$found_any" = false ] && echo "   Database Credentials:"
    echo "     • ~/.db/production"
    found_any=true
  fi

  if [ -f "$HOME/.tokens/github" ]; then
    [ -f "$HOME/.db/production" ] && echo ""
    echo "  API Tokens:"
    echo "     • ~/.tokens/github"
    found_any=true
  fi

  if [ -f "$HOME/.credentials/stripe" ]; then
    [ -f "$HOME/.tokens/github" ] && echo ""
    echo "  API Keys:"
    echo "     • ~/.credentials/stripe"
    found_any=true
  fi

  if [ -f "$HOME/.env.test" ]; then
    [ -f "$HOME/.credentials/stripe" ] && echo ""
    echo "  Environment Files:"
    echo "     • ~/.env.test"
    found_any=true
  fi

  if [ "$found_any" = false ]; then
    echo "  ${GREEN}✓${NC} No test credential files found"
    return 1
  fi

  echo ""
  echo -e "${BOLD}${YELLOW}Empty directories will also be removed:${NC}"
  [ -d "$HOME/.db" ] && echo "     • ~/.db/ (if empty)"
  [ -d "$HOME/.tokens" ] && echo "     • ~/.tokens/ (if empty)"
  [ -d "$HOME/.credentials" ] && echo "     • ~/.credentials/ (if empty)"
  echo ""

  return 0
}

confirm_cleanup() {
  if [ "$FORCE" = true ]; then
    warning "Running in --force mode, skipping confirmation"
    return 0
  fi

  read -p "Are you sure you want to remove these test credentials? (yes/no): " confirmation

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

cleanup_test_credentials() {
  print_step " Removing Test Credential Files"

  local removed=0

  # Test files to remove
  local test_files=(
    "$HOME/.db/production"
    "$HOME/.tokens/github"
    "$HOME/.credentials/stripe"
    "$HOME/.env.test"
  )

  for file in "${test_files[@]}"; do
    if [ -f "$file" ]; then
      info "Removing: $file"
      rm -f "$file"
      success "Removed $(basename "$file")"
      removed=$((removed + 1))
    fi
  done

  if [ $removed -eq 0 ]; then
    info "No test credential files to remove"
  fi

  echo ""
}

cleanup_empty_directories() {
  print_step " Removing Empty Directories"

  local removed=0

  # Check and remove empty directories
  if [ -d "$HOME/.db" ] && [ -z "$(ls -A "$HOME/.db")" ]; then
    info "Removing empty directory: ~/.db/"
    rmdir "$HOME/.db"
    success "Removed ~/.db/"
    removed=$((removed + 1))
  elif [ -d "$HOME/.db" ]; then
    warning "Directory ~/.db/ is not empty, keeping it"
  fi

  if [ -d "$HOME/.tokens" ] && [ -z "$(ls -A "$HOME/.tokens")" ]; then
    info "Removing empty directory: ~/.tokens/"
    rmdir "$HOME/.tokens"
    success "Removed ~/.tokens/"
    removed=$((removed + 1))
  elif [ -d "$HOME/.tokens" ]; then
    warning "Directory ~/.tokens/ is not empty, keeping it"
  fi

  if [ -d "$HOME/.credentials" ] && [ -z "$(ls -A "$HOME/.credentials")" ]; then
    info "Removing empty directory: ~/.credentials/"
    rmdir "$HOME/.credentials"
    success "Removed ~/.credentials/"
    removed=$((removed + 1))
  elif [ -d "$HOME/.credentials" ]; then
    warning "Directory ~/.credentials/ is not empty, keeping it"
  fi

  if [ $removed -eq 0 ]; then
    info "No empty directories to remove"
  fi

  echo ""
}

show_completion() {
  print_step "Cleanup Complete"

  echo ""
  echo -e "${BOLD}${GREEN}Test credentials have been removed!${NC}"
  echo ""
  echo -e "${CYAN}To recreate test credentials:${NC}"
  echo "  ${BOLD}./tests/create-test-credentials.sh${NC}"
  echo ""
}

main() {
  banner

  if ! show_removal_summary; then
    exit 0
  fi

  confirm_cleanup

  echo ""
  print_step "Starting Cleanup"

  cleanup_test_credentials
  cleanup_empty_directories
  show_completion
}

main
