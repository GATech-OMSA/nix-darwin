#!/usr/bin/env bash
# Automated backup verification script
# Validates backup completeness, integrity, and restore capability

set -o pipefail

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="$REPO_ROOT/user-data"
TEMP_RESTORE_DIR="/tmp/nix-darwin-restore-test-$$"
VERBOSE=0
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-v|--verbose] [-h|--help]"
      echo ""
      echo "Options:"
      echo "  -v, --verbose    Show detailed output for all checks"
      echo "  -h, --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_category() {
  echo ""
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
  echo ""
}

check_pass() {
  ((TOTAL_CHECKS++))
  ((PASSED_CHECKS++))
  echo -e "  ${GREEN}✓${NC} $1"
  if [[ $VERBOSE -eq 1 && -n "${2:-}" ]]; then
    echo -e "    ${CYAN}→${NC} $2"
  fi
}

check_fail() {
  ((TOTAL_CHECKS++))
  ((FAILED_CHECKS++))
  echo -e "  ${RED}✗${NC} $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "    ${RED}→${NC} $2"
  fi
}

check_warn() {
  ((TOTAL_CHECKS++))
  ((WARNINGS++))
  echo -e "  ${YELLOW}⚠${NC} $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "    ${YELLOW}→${NC} $2"
  fi
}

verbose_output() {
  if [[ $VERBOSE -eq 1 ]]; then
    echo -e "    ${CYAN}→${NC} $1"
  fi
}

cleanup_temp() {
  if [[ -d "$TEMP_RESTORE_DIR" ]]; then
    rm -rf "$TEMP_RESTORE_DIR"
  fi
}

# Cleanup on exit
trap cleanup_temp EXIT

# ============================================================================
# BACKUP VERIFICATION FUNCTIONS
# ============================================================================

check_backup_directory() {
  print_category "BACKUP DIRECTORY STRUCTURE"

  # Check if backup directory exists
  if [[ -d "$BACKUP_DIR" ]]; then
    check_pass "Backup directory exists" "$BACKUP_DIR"
  else
    check_fail "Backup directory not found" "Expected at $BACKUP_DIR"
    return 1
  fi

  # Check for expected subdirectories
  local expected_dirs=(
    "app-configs"
    "user-content"
  )

  for dir in "${expected_dirs[@]}"; do
    if [[ -d "$BACKUP_DIR/$dir" ]]; then
      check_pass "Directory exists: $dir"
    else
      check_fail "Missing directory: $dir" "Run: ~/nix-darwin/user-data/backup.sh"
    fi
  done

  # Check backup script exists and is executable
  if [[ -x "$BACKUP_DIR/backup.sh" ]]; then
    check_pass "Backup script is executable"
  elif [[ -f "$BACKUP_DIR/backup.sh" ]]; then
    check_warn "Backup script exists but not executable" "Run: chmod +x $BACKUP_DIR/backup.sh"
  else
    check_fail "Backup script not found" "Expected at $BACKUP_DIR/backup.sh"
  fi
}

check_app_configs() {
  print_category "APPLICATION CONFIGS BACKUP"

  local app_configs=(
    "claude:Claude Code configuration"
    "continue:Continue.dev configuration"
    "gemini:Gemini configuration"
    "iterm2:iTerm2 preferences"
    "cursor:Cursor configuration"
    "docker:Docker user config"
  )

  local backed_up_count=0
  for app_info in "${app_configs[@]}"; do
    app="${app_info%%:*}"
    desc="${app_info#*:}"

    if [[ -d "$BACKUP_DIR/app-configs/$app" ]] || [[ -f "$BACKUP_DIR/app-configs/$app.json" ]]; then
      ((backed_up_count++))
      if [[ $VERBOSE -eq 1 ]]; then
        check_pass "$desc backed up"
        # Show file count if directory
        if [[ -d "$BACKUP_DIR/app-configs/$app" ]]; then
          file_count=$(find "$BACKUP_DIR/app-configs/$app" -type f | wc -l | xargs)
          verbose_output "$file_count file(s)"
        fi
      fi
    else
      if [[ $VERBOSE -eq 1 ]]; then
        check_warn "$desc not backed up" "May not be installed"
      fi
    fi
  done

  if [[ $VERBOSE -eq 0 ]]; then
    if [[ $backed_up_count -gt 0 ]]; then
      check_pass "Application configs backed up" "$backed_up_count/${#app_configs[@]} apps"
    else
      check_warn "No application configs backed up" "Run backup.sh to create backup"
    fi
  fi
}

check_user_content() {
  print_category "USER CONTENT BACKUP"

  local content_items=(
    "vscode-snippets:VS Code snippets"
    "vscode:VS Code settings"
    "jupyter:Jupyter configs"
    "ipython:IPython configs"
  )

  local backed_up_count=0
  for item_info in "${content_items[@]}"; do
    item="${item_info%%:*}"
    desc="${item_info#*:}"

    if [[ -d "$BACKUP_DIR/user-content/$item" ]] || [[ -f "$BACKUP_DIR/user-content/$item.json" ]]; then
      ((backed_up_count++))
      if [[ $VERBOSE -eq 1 ]]; then
        check_pass "$desc backed up"
      fi
    else
      if [[ $VERBOSE -eq 1 ]]; then
        check_warn "$desc not backed up" "May not exist"
      fi
    fi
  done

  if [[ $VERBOSE -eq 0 ]]; then
    if [[ $backed_up_count -gt 0 ]]; then
      check_pass "User content backed up" "$backed_up_count/${#content_items[@]} items"
    else
      check_warn "No user content backed up"
    fi
  fi

  # Check for important standalone files
  if [[ -f "$BACKUP_DIR/ssh_known_hosts" ]]; then
    check_pass "SSH known_hosts backed up"
  else
    check_warn "SSH known_hosts not backed up"
  fi

  if [[ -f "$BACKUP_DIR/zoxide_database" ]]; then
    check_pass "Zoxide database backed up"
  else
    check_warn "Zoxide database not backed up"
  fi
}

check_backup_integrity() {
  print_category "BACKUP INTEGRITY"

  # Calculate total backup size
  if [[ -d "$BACKUP_DIR" ]]; then
    backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "unknown")
    check_pass "Backup size calculated" "$backup_size"
  else
    check_fail "Cannot calculate backup size" "Directory missing"
    return 1
  fi

  # Count total files
  file_count=$(find "$BACKUP_DIR" -type f ! -name "backup.sh" ! -name ".DS_Store" 2>/dev/null | wc -l | xargs)
  if [[ $file_count -gt 0 ]]; then
    check_pass "Files backed up" "$file_count files"
  else
    check_fail "No files found in backup" "Run: ~/nix-darwin/user-data/backup.sh"
  fi

  # Check for empty directories (might indicate backup issues)
  empty_dirs=$(find "$BACKUP_DIR" -type d -empty 2>/dev/null | wc -l | xargs)
  if [[ $empty_dirs -eq 0 ]]; then
    check_pass "No empty directories"
  else
    check_warn "$empty_dirs empty directory(ies) found" "May indicate incomplete backup"
  fi

  # Check for .DS_Store pollution (informational)
  ds_store_count=$(find "$BACKUP_DIR" -name ".DS_Store" 2>/dev/null | wc -l | xargs)
  if [[ $ds_store_count -gt 0 ]]; then
    if [[ $VERBOSE -eq 1 ]]; then
      check_warn "$ds_store_count .DS_Store file(s) found" "Consider cleaning: find user-data -name .DS_Store -delete"
    fi
  fi
}

test_restore_capability() {
  print_category "RESTORE CAPABILITY TEST"

  # Create temp directory for restore test
  if mkdir -p "$TEMP_RESTORE_DIR"; then
    check_pass "Created temp restore directory" "$TEMP_RESTORE_DIR"
  else
    check_fail "Cannot create temp restore directory"
    return 1
  fi

  # Test restoring a few representative files
  local test_files=(
    "app-configs/claude.json"
    "ssh_known_hosts"
    "zoxide_database"
  )

  local restore_success=0
  local restore_total=0

  for file in "${test_files[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
      ((restore_total++))
      # Test copy to temp location
      dest_dir="$TEMP_RESTORE_DIR/$(dirname "$file")"
      mkdir -p "$dest_dir"
      if cp "$BACKUP_DIR/$file" "$dest_dir/" 2>/dev/null; then
        ((restore_success++))
        if [[ $VERBOSE -eq 1 ]]; then
          check_pass "Restore test: $(basename "$file")"
        fi
      else
        check_fail "Failed to restore: $file"
      fi
    fi
  done

  if [[ $restore_total -gt 0 ]]; then
    if [[ $restore_success -eq $restore_total ]]; then
      check_pass "Restore capability verified" "$restore_success/$restore_total files restored"
    else
      check_fail "Restore capability issues" "$restore_success/$restore_total files restored"
    fi
  else
    check_warn "No files available for restore test" "Backup may be incomplete"
  fi

  # Test directory restore
  if [[ -d "$BACKUP_DIR/app-configs/claude" ]]; then
    if cp -r "$BACKUP_DIR/app-configs/claude" "$TEMP_RESTORE_DIR/" 2>/dev/null; then
      restored_count=$(find "$TEMP_RESTORE_DIR/claude" -type f | wc -l | xargs)
      check_pass "Directory restore test passed" "Restored $restored_count files"
    else
      check_fail "Directory restore test failed"
    fi
  fi
}

check_backup_freshness() {
  print_category "BACKUP FRESHNESS"

  # Check when backup script was last run
  if [[ -f "$BACKUP_DIR/app-configs/claude.json" ]]; then
    last_modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$BACKUP_DIR/app-configs/claude.json" 2>/dev/null || echo "unknown")
    # Calculate age in hours
    if [[ -f "$BACKUP_DIR/app-configs/claude.json" ]]; then
      now=$(date +%s)
      file_time=$(stat -f "%m" "$BACKUP_DIR/app-configs/claude.json" 2>/dev/null || echo "0")
      age_hours=$(( (now - file_time) / 3600 ))

      if [[ $age_hours -lt 24 ]]; then
        check_pass "Backup is fresh" "Last updated: $last_modified (<24 hours)"
      elif [[ $age_hours -lt 168 ]]; then  # 1 week
        check_warn "Backup is $age_hours hours old" "Consider running backup.sh"
      else
        check_fail "Backup is stale (>1 week old)" "Run: ~/nix-darwin/user-data/backup.sh"
      fi
    fi
  else
    check_warn "Cannot determine backup freshness" "No reference file found"
  fi
}

check_critical_files() {
  print_category "CRITICAL FILES VERIFICATION"

  # Files that should definitely be backed up
  local critical_backups=(
    "app-configs/claude:Claude Code config"
    "ssh_known_hosts:SSH known hosts"
  )

  local missing_critical=0
  for backup_info in "${critical_backups[@]}"; do
    backup_path="${backup_info%%:*}"
    desc="${backup_info#*:}"

    # Check if it's a file or directory
    if [[ -f "$BACKUP_DIR/$backup_path" ]] || [[ -d "$BACKUP_DIR/$backup_path" ]]; then
      check_pass "$desc backed up"
    else
      check_fail "$desc MISSING" "Critical backup not found"
      ((missing_critical++))
    fi
  done

  if [[ $missing_critical -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}⚠ WARNING: $missing_critical critical backup(s) missing!${NC}"
    echo -e "  ${CYAN}Run: ~/nix-darwin/user-data/backup.sh${NC}"
  fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  print_header "🔍 BACKUP VERIFICATION"

  # Run all verification checks
  check_backup_directory
  check_app_configs
  check_user_content
  check_backup_integrity
  test_restore_capability
  check_backup_freshness
  check_critical_files

  # Generate verification report
  print_header "📊 VERIFICATION REPORT"
  echo ""

  local pass_percent=0
  if [[ $TOTAL_CHECKS -gt 0 ]]; then
    pass_percent=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
  fi

  echo -e "${BOLD}Total Checks:${NC} $TOTAL_CHECKS"
  echo -e "${GREEN}✓ Passed:${NC}     $PASSED_CHECKS"
  echo -e "${RED}✗ Failed:${NC}     $FAILED_CHECKS"
  echo -e "${YELLOW}⚠ Warnings:${NC}   $WARNINGS"
  echo ""

  # Determine verification status
  local status_emoji="🟢"
  local status_text="VERIFIED"
  local status_color="$GREEN"

  if [[ $FAILED_CHECKS -gt 3 ]] || [[ $pass_percent -lt 60 ]]; then
    status_emoji="🔴"
    status_text="CRITICAL"
    status_color="$RED"
  elif [[ $FAILED_CHECKS -gt 0 ]] || [[ $pass_percent -lt 80 ]]; then
    status_emoji="🟡"
    status_text="NEEDS ATTENTION"
    status_color="$YELLOW"
  elif [[ $WARNINGS -gt 3 ]]; then
    status_emoji="🟡"
    status_text="FAIR"
    status_color="$YELLOW"
  fi

  echo -e "${BOLD}Verification Score:${NC} ${status_color}${pass_percent}%${NC} ($PASSED_CHECKS/$TOTAL_CHECKS checks passed)"
  echo -e "${BOLD}Status:${NC}             ${status_emoji} ${status_color}${status_text}${NC}"
  echo ""

  # Provide recommendations
  if [[ $FAILED_CHECKS -gt 0 ]] || [[ $WARNINGS -gt 0 ]]; then
    echo -e "${BOLD}${YELLOW}Recommendations:${NC}"
    echo ""
    if [[ $FAILED_CHECKS -gt 0 ]]; then
      echo "  • Run backup script to create/update backup: ~/nix-darwin/user-data/backup.sh"
      echo "  • Address critical failures (marked with ✗)"
    fi
    if [[ $WARNINGS -gt 0 ]]; then
      echo "  • Review warnings for potential backup gaps"
    fi
    echo "  • Run with --verbose flag for detailed information"
    echo ""
  fi

  # Exit with appropriate code
  if [[ $FAILED_CHECKS -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run main function
main
