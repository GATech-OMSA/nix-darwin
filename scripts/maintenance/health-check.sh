#!/usr/bin/env bash
# Comprehensive nix-darwin system health check script
# Validates system state across multiple categories with scoring

# Note: Not using 'set -e' because we want to continue on check failures
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# Colors + print/check helpers (print_header, check_pass, …) — TTY-aware.
source "${REPO_ROOT}/scripts/lib/audit-framework.sh"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner
# sumval <summary-line> <key> → the integer for key=<number> on a SUMMARY: line.
# Used to parse the sub-scripts' machine-readable summary instead of scraping ANSI.
# Field-matched (not grep -oE) so key="secure" doesn't also match "insecure=".
sumval() { echo "$1" | awk -v k="$2" '{for(i=1;i<=NF;i++) if($i~"^"k"="){split($i,a,"="); print a[2]; exit}}'; }
VERBOSE=0
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Parse command line arguments
all_args=("$@")
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

run_banner "health-check" "verbose=$VERBOSE" "${all_args[@]}"

# print_header / print_category / check_pass / check_fail / check_warn /
# verbose_output come from scripts/lib/audit-framework.sh (sourced above).

# ============================================================================
# CHECK FUNCTIONS
# ============================================================================

check_nix_daemon() {
  print_category "NIX DAEMON & CORE"

  # Check if nix-daemon is running — traditional nix-daemon or Determinate Nix daemon
  if pgrep -x nix-daemon &> /dev/null; then
    check_pass "Nix daemon is running"
  elif pgrep -x determinate-nixd &> /dev/null; then
    check_pass "Nix daemon is running (Determinate Nix)"
  elif launchctl list 2>/dev/null | grep -q "org.nixos.nix-daemon\|systems.determinate"; then
    check_pass "Nix daemon is running"
  elif [[ -S /run/nix-daemon.socket || -S /private/run/nix-daemon.socket ]]; then
    check_pass "Nix daemon is running (socket active)"
  else
    check_fail "Nix daemon is not running" "Run: sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
  fi

  # Check nix command availability
  if command -v nix &> /dev/null; then
    nix_version=$(nix --version 2>&1 | head -n1 || echo "unknown")
    check_pass "Nix command available" "$nix_version"
  else
    check_fail "Nix command not found"
  fi

  # Check nix store
  if [[ -d /nix/store ]]; then
    # Note: du -sh can be slow on large stores, so we just check accessibility
    if [[ $VERBOSE -eq 1 ]]; then
      store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
      check_pass "Nix store accessible" "Size: $store_size"
    else
      check_pass "Nix store accessible"
    fi
  else
    check_fail "Nix store not found" "Expected at /nix/store"
  fi

  # Check flake inputs
  if [[ -f "$REPO_ROOT/flake.lock" ]]; then
    check_pass "Flake lock file exists"
    if [[ $VERBOSE -eq 1 ]]; then
      last_updated=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$REPO_ROOT/flake.lock" 2>/dev/null || echo "unknown")
      verbose_output "Last updated: $last_updated"
    fi
  else
    check_warn "Flake lock file missing" "Run: nix flake update"
  fi
}

check_darwin_activation() {
  print_category "DARWIN SYSTEM"

  # Check darwin-rebuild availability — falls back to nix profiles path when /run/current-system is missing
  if command -v darwin-rebuild &> /dev/null; then
    check_pass "darwin-rebuild command available"
  elif [[ -x /nix/var/nix/profiles/system/sw/bin/darwin-rebuild ]]; then
    check_pass "darwin-rebuild available (not in PATH)" "Run: sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake ~/nix-darwin"
  else
    check_fail "darwin-rebuild command not found"
  fi

  # Check system activation
  if [[ -L /run/current-system ]]; then
    current_gen=$(readlink /run/current-system)
    check_pass "System is activated" "$current_gen"
  else
    check_fail "System activation symlink missing"
  fi

  # Check launchd services — includes Determinate Nix service labels
  local services=(
    "org.nixos.nix-daemon"
    "systems.determinate.nix-daemon"
    "systems.determinate.determinate-nixd"
  )

  local service_count=0
  for service in "${services[@]}"; do
    if launchctl list 2>/dev/null | grep -q "$service"; then
      ((service_count++))
    fi
  done

  if [[ $service_count -gt 0 ]]; then
    check_pass "LaunchD services active" "$service_count service(s) running"
  else
    check_warn "No LaunchD services detected" "Some services may not be configured"
  fi

  # Check system generations
  if [[ -d /nix/var/nix/profiles ]]; then
    gen_count=$(ls -1 /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l | xargs)
    if [[ $gen_count -gt 0 ]]; then
      check_pass "System generations available" "$gen_count generation(s)"
    else
      check_warn "No system generations found"
    fi
  fi
}

check_home_manager() {
  print_category "HOME MANAGER"

  # Check home-manager activation
  if [[ -L "$HOME/.nix-profile" ]]; then
    check_pass "Home Manager profile activated"
  else
    check_warn "Home Manager profile not found"
  fi

  # Check common symlinks created by home-manager
  local hm_files=(
    "$HOME/.zshrc"
    "$HOME/.config/git/config"
    "$HOME/.config/starship.toml"
  )

  local link_count=0
  local missing_files=()
  for file in "${hm_files[@]}"; do
    if [[ -f "$file" || -L "$file" ]]; then
      ((link_count++))
    else
      missing_files+=("$(basename "$file")")
    fi
  done

  if [[ $link_count -eq ${#hm_files[@]} ]]; then
    check_pass "Home Manager files linked" "$link_count/${#hm_files[@]} files"
  elif [[ $link_count -gt 0 ]]; then
    check_warn "Some Home Manager files missing" "Missing: ${missing_files[*]}"
  else
    check_fail "No Home Manager files found" "Run: darwin-rebuild switch"
  fi

  # Check home-manager generations
  if [[ -d "$HOME/.local/state/nix/profiles" ]] || [[ -d "$HOME/.local/state/home-manager/gcroots" ]]; then
    check_pass "Home Manager generations directory exists"
  else
    check_warn "Home Manager generations directory not found"
  fi
}

check_shell_config() {
  print_category "SHELL CONFIGURATION"

  # Check current shell
  if [[ "$SHELL" == *"zsh"* ]]; then
    check_pass "Shell is zsh" "$SHELL"
  else
    check_warn "Shell is not zsh" "Current: $SHELL"
  fi

  # Check .zshrc
  if [[ -f "$HOME/.zshrc" ]]; then
    check_pass ".zshrc exists"
    if grep -q "home-manager" "$HOME/.zshrc" 2>/dev/null; then
      verbose_output "Managed by Home Manager"
    fi
  else
    check_fail ".zshrc not found"
  fi

  # Check critical aliases (use shell subprocess to test if command resolves)
  if zsh -i -c 'type nix-rebuild' &>/dev/null; then
    check_pass "nix-rebuild alias available"
  else
    check_warn "nix-rebuild alias not found" "May need to reload shell"
  fi

  # Check starship prompt
  if command -v starship &> /dev/null; then
    check_pass "Starship prompt available"
    if [[ -f "$HOME/.config/starship.toml" ]]; then
      verbose_output "Config: $HOME/.config/starship.toml"
    fi
  else
    check_warn "Starship prompt not installed"
  fi

  # Check startup time (Target: <0.3s)
  if command -v zsh &> /dev/null; then
    # Measure time to start interactive shell and exit immediately
    # /usr/bin/time -p outputs POSIX format: real X.XX
    startup_output=$(/usr/bin/time -p zsh -i -c exit 2>&1)
    startup_time=$(echo "$startup_output" | grep real | awk '{print $2}')
    
    # Use awk for float comparison
    is_slow=$(echo "$startup_time" | awk '{if ($1 > 0.3) print 1; else print 0}')
    
    if [[ "$is_slow" -eq 0 ]]; then
      check_pass "Shell startup optimized" "${startup_time}s (target: <0.3s)"
    else
      check_warn "Shell startup slow" "${startup_time}s (target: <0.3s)"
      if [[ $VERBOSE -eq 1 ]]; then
        verbose_output "Tip: Run 'zsh -i -c zprof' to debug bottlenecks"
      fi
    fi
  fi

  # Check Oh-My-Zsh if configured
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    check_pass "Oh-My-Zsh installed"
  else
    check_warn "Oh-My-Zsh not installed" "Optional component"
  fi
}

check_git_config() {
  print_category "GIT CONFIGURATION"

  # Check git command
  if command -v git &> /dev/null; then
    git_version=$(git --version)
    check_pass "Git command available" "$git_version"
  else
    check_fail "Git command not found"
  fi

  # Check git config
  if [[ -f "$HOME/.config/git/config" ]]; then
    check_pass "Git config exists"
  else
    check_warn "Git config not found" "Expected at ~/.config/git/config"
  fi

  # Check git hooks
  if [[ -x "$REPO_ROOT/.git/hooks/pre-commit" ]]; then
    check_pass "Git pre-commit hook installed"
  else
    check_warn "Git pre-commit hook not executable" "Run: chmod +x .git/hooks/pre-commit"
  fi

  if [[ -x "$REPO_ROOT/.git/hooks/pre-push" ]]; then
    check_pass "Git pre-push hook installed"
  else
    check_warn "Git pre-push hook not executable" "Run: chmod +x .git/hooks/pre-push"
  fi

  # Check git user config
  if git config user.name &> /dev/null && git config user.email &> /dev/null; then
    user_name=$(git config user.name)
    user_email=$(git config user.email)
    check_pass "Git user configured" "$user_name <$user_email>"
  else
    check_fail "Git user not configured" "Run: git config --global user.name/user.email"
  fi
}

check_secrets() {
  print_category "SECRETS & ENCRYPTION"

  # Check SOPS availability — falls back to nix profiles path when /run/current-system is missing
  if command -v sops &> /dev/null; then
    sops_version=$(sops --version 2>&1 | head -n1)
    check_pass "SOPS command available" "$sops_version"
  elif [[ -x /nix/var/nix/profiles/system/sw/bin/sops ]]; then
    sops_version=$(/nix/var/nix/profiles/system/sw/bin/sops --version 2>&1 | head -n1)
    check_pass "SOPS available (not in PATH)" "$sops_version"
  else
    check_fail "SOPS command not found"
  fi

  # Check age key
  if [[ -f "$HOME/.config/sops/age/keys.txt" ]]; then
    check_pass "SOPS age key exists"
    # Check permissions
    perms=$(stat -f "%A" "$HOME/.config/sops/age/keys.txt" 2>/dev/null || echo "000")
    if [[ "$perms" == "600" ]]; then
      verbose_output "Permissions: 600 (secure)"
    else
      check_warn "Age key has insecure permissions: $perms" "Run: chmod 600 ~/.config/sops/age/keys.txt"
    fi
  else
    check_warn "SOPS age key not found" "Expected at ~/.config/sops/age/keys.txt"
  fi

  # Check secrets encryption
  secrets_count=0
  encrypted_count=0
  for secrets_file in $(find "$REPO_ROOT/nix-config/hosts" -name "secrets.yaml" 2>/dev/null || true); do
    ((secrets_count++))
    if grep -q "sops:" "$secrets_file" && grep -q "ENC\[" "$secrets_file"; then
      ((encrypted_count++))
    fi
  done

  if [[ $secrets_count -gt 0 ]]; then
    if [[ $encrypted_count -eq $secrets_count ]]; then
      check_pass "All secrets files encrypted" "$encrypted_count/$secrets_count files"
    else
      check_fail "Some secrets files not encrypted" "$encrypted_count/$secrets_count encrypted"
    fi
  else
    check_warn "No secrets files found"
  fi

  # Run comprehensive permission audit
  if [[ -x "$REPO_ROOT/scripts/validation/audit-permissions.sh" ]]; then
    echo ""
    echo -e "  ${CYAN}Running comprehensive permission audit...${NC}"

    # Capture audit output and results
    audit_output=$("$REPO_ROOT/scripts/validation/audit-permissions.sh" 2>&1)
    audit_exit_code=$?

    # Parse the machine-readable SUMMARY: line (replaces fragile ANSI scraping).
    audit_summary=$(echo "$audit_output" | grep '^SUMMARY:')
    if [[ -n "$audit_summary" ]]; then
      secure_count=$(sumval "$audit_summary" secure);     secure_count=${secure_count:-0}
      insecure_count=$(sumval "$audit_summary" insecure); insecure_count=${insecure_count:-0}
      total_files=$(sumval "$audit_summary" total);       total_files=${total_files:-0}

      if [[ $audit_exit_code -eq 0 ]]; then
        check_pass "Credential file permissions secure" "$secure_count/$total_files files with 600 permissions"
      else
        check_warn "$insecure_count credential file(s) with insecure permissions" "Run: $REPO_ROOT/scripts/validation/audit-permissions.sh --fix"
      fi

      if [[ $VERBOSE -eq 1 ]]; then
        echo ""
        echo "$audit_output"
        echo ""
      fi
    else
      check_warn "Permission audit failed to complete" "Check: $REPO_ROOT/scripts/validation/audit-permissions.sh"
    fi
  else
    # Fallback to basic permission checks
    local insecure_count=0
    local credential_files=(
      "$HOME/.aws/credentials"
      "$HOME/.ssh/id_ed25519"
      "$HOME/.ssh/id_ed25519_work"
    )

    for file in "${credential_files[@]}"; do
      if [[ -f "$file" ]]; then
        perms=$(stat -f "%A" "$file" 2>/dev/null || echo "000")
        if [[ "$perms" != "600" ]]; then
          ((insecure_count++))
        fi
      fi
    done

    if [[ $insecure_count -eq 0 ]]; then
      check_pass "Credential file permissions secure"
    else
      check_warn "$insecure_count credential file(s) with insecure permissions" "Run: chmod 600 <file>"
    fi
  fi
}

check_packages() {
  print_category "CRITICAL PACKAGES"

  # Essential packages that should be available
  local critical_packages=(
    "git:Git version control"
    "curl:HTTP client"
    "jq:JSON processor"
    "vim:Text editor"
    "zsh:Z shell"
  )

  local installed_count=0
  for pkg_info in "${critical_packages[@]}"; do
    pkg="${pkg_info%%:*}"
    desc="${pkg_info#*:}"
    if command -v "$pkg" &> /dev/null; then
      ((installed_count++))
      if [[ $VERBOSE -eq 1 ]]; then
        check_pass "$desc ($pkg)"
      fi
    else
      check_fail "$desc not installed" "Package: $pkg"
    fi
  done

  if [[ $VERBOSE -eq 0 ]]; then
    if [[ $installed_count -eq ${#critical_packages[@]} ]]; then
      check_pass "All critical packages installed" "$installed_count/${#critical_packages[@]} packages"
    else
      check_fail "Missing critical packages" "$installed_count/${#critical_packages[@]} installed"
    fi
  fi

  # Check for package manager tools
  if command -v nix &> /dev/null && command -v brew &> /dev/null; then
    check_pass "Package managers available" "Nix + Homebrew"
  elif command -v nix &> /dev/null; then
    check_pass "Package manager available" "Nix"
  else
    check_fail "No package managers found"
  fi
}

check_repository_state() {
  print_category "REPOSITORY STATE"

  # Check if we're in a git repository
  if git rev-parse --git-dir &> /dev/null; then
    check_pass "Git repository initialized"
  else
    check_fail "Not in a git repository"
    return
  fi

  # Check current branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  if [[ "$current_branch" != "unknown" ]]; then
    check_pass "On branch: $current_branch"
  else
    check_warn "Could not determine current branch"
  fi

  # Check for uncommitted changes
  if git diff --quiet && git diff --cached --quiet; then
    check_pass "Working directory clean"
  else
    check_warn "Uncommitted changes detected" "Run: git status"
  fi

  # Check remote connection
  if git remote -v | grep -q origin; then
    check_pass "Git remote configured"
    if [[ $VERBOSE -eq 1 ]]; then
      remote_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
      verbose_output "Remote: $remote_url"
    fi
  else
    check_warn "No git remote configured"
  fi
}

check_backup_verification() {
  print_category "BACKUP VERIFICATION"

  # Check if verification script exists
  if [[ ! -x "$REPO_ROOT/scripts/maintenance/verify-backups.sh" ]]; then
    check_warn "Backup verification script not found or not executable"
    return
  fi

  # Run backup verification in quiet mode (capture exit code only)
  echo -e "  ${CYAN}Running backup verification...${NC}"
  echo ""

  # Run verification and capture full output
  verify_output=$("$REPO_ROOT/scripts/maintenance/verify-backups.sh" 2>&1)
  verify_exit_code=$?

  # Parse the machine-readable SUMMARY: line (replaces fragile ANSI scraping).
  verify_summary=$(echo "$verify_output" | grep '^SUMMARY:')
  if [[ -n "$verify_summary" ]]; then
    passed=$(sumval "$verify_summary" passed);     passed=${passed:-0}
    failed=$(sumval "$verify_summary" failed);     failed=${failed:-0}
    warnings=$(sumval "$verify_summary" warnings); warnings=${warnings:-0}
    total=$(sumval "$verify_summary" total);       total=${total:-0}

    if [[ $verify_exit_code -eq 0 ]]; then
      check_pass "Backup verification passed" "$passed/$total checks passed"
    elif [[ $failed -gt 0 ]]; then
      check_fail "$failed backup verification check(s) failed" "Run: $REPO_ROOT/scripts/maintenance/verify-backups.sh --verbose"
    else
      check_warn "$warnings backup verification warning(s)" "Review with: $REPO_ROOT/scripts/maintenance/verify-backups.sh --verbose"
    fi

    # Show verbose output if requested
    if [[ $VERBOSE -eq 1 ]]; then
      echo ""
      echo "$verify_output"
      echo ""
    fi
  else
    check_warn "Backup verification failed to complete" "Check: $REPO_ROOT/scripts/verify-backups.sh"
  fi
}

check_system_resources() {
  print_category "SYSTEM RESOURCES"

  # Uptime — long uptimes accumulate stale memory/swap and slow new processes
  local uptime_out
  uptime_out=$(uptime)
  if uptime_days=$(sed -nE 's/.*up ([0-9]+) day.*/\1/p' <<< "$uptime_out") && [[ -n "$uptime_days" ]]; then
    if (( uptime_days < 14 )); then
      check_pass "Uptime healthy" "${uptime_days} days"
    elif (( uptime_days < 30 )); then
      check_warn "Long uptime" "${uptime_days} days — consider rebooting if shells feel slow"
    else
      check_fail "Very long uptime" "${uptime_days} days — reboot recommended"
    fi
  fi

  # Load average — sustained > num-cores indicates contention
  cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)
  load_5min=$(sed -nE 's/.*load averages?: [^ ]+ +([0-9.]+).*/\1/p' <<< "$uptime_out")
  if [[ -n "$load_5min" ]]; then
    is_high=$(awk -v l="$load_5min" -v c="$cores" 'BEGIN { print (l > c * 0.75) ? 1 : 0 }')
    if [[ "$is_high" -eq 0 ]]; then
      check_pass "Load average normal" "5min=${load_5min} (cores=${cores})"
    else
      check_warn "High load average" "5min=${load_5min} on ${cores} cores"
    fi
  fi

  # Swap pressure — committed swap can't be reclaimed without restarting apps
  swap_used_mb=$(sysctl vm.swapusage 2>/dev/null | sed -nE 's/.*used = ([0-9.]+)M.*/\1/p' | awk '{print int($1)}')
  if [[ -n "$swap_used_mb" ]]; then
    if (( swap_used_mb < 1024 )); then
      check_pass "Swap usage low" "${swap_used_mb}MB committed"
    elif (( swap_used_mb < 4096 )); then
      check_warn "Moderate swap usage" "${swap_used_mb}MB committed — try 'sudo purge' to reclaim RAM"
    else
      check_fail "Heavy swap usage" "${swap_used_mb}MB committed — reboot to fully clear"
    fi
  fi

  # Free memory pages (16KB each on Apple Silicon)
  pages_free=$(memory_pressure 2>/dev/null | sed -nE 's/Pages free: +([0-9]+).*/\1/p')
  if [[ -n "$pages_free" ]]; then
    free_mb=$(( pages_free * 16 / 1024 ))
    if (( free_mb > 1024 )); then
      check_pass "Free memory adequate" "${free_mb}MB"
    elif (( free_mb > 256 )); then
      check_warn "Free memory low" "${free_mb}MB — fresh processes may be slow"
    else
      check_fail "Free memory critical" "${free_mb}MB — fresh shells will hang on swap-in"
    fi
  fi

  # Atuin WAL — bloated WAL slows every shell init via `atuin uuid`
  history_wal="$HOME/.local/share/atuin/history.db-wal"
  if [[ -f "$history_wal" ]]; then
    wal_mb=$(du -m "$history_wal" 2>/dev/null | awk '{print $1}')
    if (( wal_mb < 2 )); then
      check_pass "Atuin WAL healthy" "${wal_mb}MB"
    else
      check_warn "Atuin WAL bloated" "${wal_mb}MB — run 'system-cleanup' to checkpoint"
    fi
  fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  print_header "NIX-DARWIN SYSTEM HEALTH CHECK"

  # Run all checks
  check_system_resources
  check_nix_daemon
  check_darwin_activation
  check_home_manager
  check_shell_config
  check_git_config
  check_secrets
  check_packages
  check_repository_state
  check_backup_verification

  # Calculate health score
  print_header "HEALTH REPORT"
  echo ""

  local pass_percent=0
  if [[ $TOTAL_CHECKS -gt 0 ]]; then
    pass_percent=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
  fi

  echo -e "${BOLD}Total Checks:${NC} $TOTAL_CHECKS"
  echo -e "${GREEN}✓ Passed:${NC}     $PASSED_CHECKS"
  echo -e "${RED}✗ Failed:${NC}     $FAILED_CHECKS"
  echo -e "${YELLOW}▸ Warnings:${NC}   $WARNINGS"
  echo ""

  # Determine health status
  local health_emoji=""
  local health_status="HEALTHY"
  local health_color="$GREEN"

  if [[ $FAILED_CHECKS -gt 5 ]] || [[ $pass_percent -lt 60 ]]; then
    health_emoji=""
    health_status="CRITICAL"
    health_color="$RED"
  elif [[ $FAILED_CHECKS -gt 2 ]] || [[ $pass_percent -lt 80 ]]; then
    health_emoji=""
    health_status="NEEDS ATTENTION"
    health_color="$YELLOW"
  elif [[ $WARNINGS -gt 3 ]] || [[ $pass_percent -lt 90 ]]; then
    health_emoji=""
    health_status="FAIR"
    health_color="$YELLOW"
  fi

  echo -e "${BOLD}Health Score:${NC} ${health_color}${pass_percent}%${NC} ($PASSED_CHECKS/$TOTAL_CHECKS checks passed)"
  echo -e "${BOLD}Status:${NC}       ${health_emoji} ${health_color}${health_status}${NC}"
  echo ""

  # Provide recommendations
  if [[ $FAILED_CHECKS -gt 0 ]] || [[ $WARNINGS -gt 0 ]]; then
    echo -e "${BOLD}${YELLOW}Recommendations:${NC}"
    echo ""
    if [[ $FAILED_CHECKS -gt 0 ]]; then
      echo "  • Address failed checks first (marked with ✗)"
      echo "  • Run 'darwin-rebuild switch --flake ~/nix-darwin' if system is not activated"
    fi
    if [[ $WARNINGS -gt 0 ]]; then
      echo "  • Review warnings (marked with ▸) for potential issues"
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