#!/usr/bin/env bash
#
# Pre-Flight Checks for darwin-rebuild
#
# Validates system health before running rebuild to prevent common failure scenarios.
# Run automatically before nix-rebuild or manually with: ./scripts/pre-flight-checks.sh
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical failures (rebuild should not proceed)
#   2 - Warnings only (rebuild can proceed with caution)
#
# Usage:
#   ./scripts/pre-flight-checks.sh              # Run all checks
#   ./scripts/pre-flight-checks.sh --quiet      # Minimal output
#   ./scripts/pre-flight-checks.sh --warnings-only  # Only show warnings/errors
#
# Integration:
#   nix-rebuild                  # Runs pre-flight checks automatically
#   nix-rebuild-skip-checks      # Emergency rebuild without checks
#   nix-preflight                # Run checks manually without rebuilding
#
# Checks performed:
#   1. Disk space (>5GB free required)
#   2. Git status (warns on uncommitted changes)
#   3. Nix daemon running
#   4. No active rebuild processes
#   5. Valid flake.nix syntax
#   6. Nix store integrity
#   7. Network connectivity to cache.nixos.org
#   8. System load
#   9. Required files exist (flake.nix, flake.lock)
#  10. Secrets encryption (SOPS binary format)
#

set -euo pipefail

# ============================================
# COLOR CODES
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# CONFIGURATION
# ============================================
MIN_DISK_SPACE_GB=5
NIX_DARWIN_DIR="${HOME}/nix-darwin"
QUIET_MODE=false
WARNINGS_ONLY=false

# Counters
CRITICAL_COUNT=0
WARNING_COUNT=0
PASS_COUNT=0

# ============================================
# UTILITY FUNCTIONS
# ============================================

print_header() {
  if [[ "$QUIET_MODE" == "false" ]]; then
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
  fi
}

print_check() {
  if [[ "$QUIET_MODE" == "false" ]] && [[ "$WARNINGS_ONLY" == "false" ]]; then
    echo -e "${BLUE}🔍 $1${NC}"
  fi
}

print_pass() {
  ((PASS_COUNT++))
  if [[ "$QUIET_MODE" == "false" ]] && [[ "$WARNINGS_ONLY" == "false" ]]; then
    echo -e "${GREEN}  ✅ $1${NC}"
  fi
}

print_warning() {
  ((WARNING_COUNT++))
  if [[ "$QUIET_MODE" == "false" ]]; then
    echo -e "${YELLOW}  ⚠️  $1${NC}"
  fi
}

print_critical() {
  ((CRITICAL_COUNT++))
  echo -e "${RED}  ❌ $1${NC}"
}

print_info() {
  if [[ "$QUIET_MODE" == "false" ]] && [[ "$WARNINGS_ONLY" == "false" ]]; then
    echo -e "     $1"
  fi
}

# ============================================
# CHECK FUNCTIONS
# ============================================

check_disk_space() {
  print_check "Checking disk space..."

  # Get available space in GB (works on macOS)
  local available_gb
  available_gb=$(df -g / | tail -n 1 | awk '{print $4}')

  if [[ "$available_gb" -lt "$MIN_DISK_SPACE_GB" ]]; then
    print_critical "Insufficient disk space: ${available_gb}GB available (minimum: ${MIN_DISK_SPACE_GB}GB)"
    print_info "Free up disk space before rebuilding"
    return 1
  else
    print_pass "Disk space: ${available_gb}GB available"
  fi

  return 0
}

check_git_status() {
  print_check "Checking git status..."

  if [[ ! -d "$NIX_DARWIN_DIR/.git" ]]; then
    print_warning "Not a git repository"
    return 0
  fi

  cd "$NIX_DARWIN_DIR" || return 1

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    print_warning "Uncommitted changes detected"
    print_info "Consider committing changes before rebuild"
    print_info "Run: git status"
  else
    print_pass "Git working tree clean"
  fi

  # Check for untracked files that might be important
  local untracked_count
  untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

  if [[ "$untracked_count" -gt 0 ]]; then
    print_warning "${untracked_count} untracked file(s) detected"
    print_info "Review with: git status"
  fi

  return 0
}

check_nix_daemon() {
  print_check "Checking Nix daemon status..."

  # Check if nix-daemon is running
  if pgrep -x "nix-daemon" > /dev/null; then
    print_pass "Nix daemon is running"
  else
    print_critical "Nix daemon is not running"
    print_info "Try: sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
    return 1
  fi

  return 0
}

check_active_rebuilds() {
  print_check "Checking for active rebuild processes..."

  # Check for darwin-rebuild processes
  if pgrep -f "darwin-rebuild" > /dev/null; then
    print_critical "Another darwin-rebuild process is running"
    print_info "Wait for current rebuild to finish or kill process"
    return 1
  else
    print_pass "No active rebuild processes"
  fi

  return 0
}

check_flake_syntax() {
  print_check "Validating flake.nix syntax..."

  cd "$NIX_DARWIN_DIR" || return 1

  # Try to evaluate flake (quick syntax check)
  if nix flake metadata --no-write-lock-file &> /dev/null; then
    print_pass "flake.nix syntax valid"
  else
    print_critical "flake.nix syntax error detected"
    print_info "Run: nix flake check --show-trace"
    return 1
  fi

  return 0
}

check_nix_store_integrity() {
  print_check "Checking Nix store integrity..."

  # Quick check if /nix/store is accessible
  if [[ ! -d "/nix/store" ]]; then
    print_critical "/nix/store directory not found"
    print_info "Nix installation may be corrupted"
    return 1
  fi

  # Check if we can read from store
  if ! ls /nix/store > /dev/null 2>&1; then
    print_critical "Cannot access /nix/store"
    print_info "Permission or mount issue detected"
    return 1
  fi

  print_pass "Nix store accessible"
  return 0
}

check_network_connectivity() {
  print_check "Checking network connectivity..."

  # Try to reach cache.nixos.org (binary cache)
  if ping -c 1 -W 2 cache.nixos.org &> /dev/null; then
    print_pass "Network connectivity OK"
  else
    print_warning "Cannot reach cache.nixos.org"
    print_info "Rebuild may be slower without binary cache"
  fi

  return 0
}

check_system_load() {
  print_check "Checking system load..."

  # Get load average (1 minute)
  local load_avg
  load_avg=$(sysctl -n vm.loadavg | awk '{print $2}')

  # Get CPU count
  local cpu_count
  cpu_count=$(sysctl -n hw.ncpu)

  # Calculate load per CPU
  local load_per_cpu
  load_per_cpu=$(echo "$load_avg / $cpu_count" | bc -l | awk '{printf "%.2f", $0}')

  # Warn if load is high (>80% per CPU)
  if (( $(echo "$load_per_cpu > 0.8" | bc -l) )); then
    print_warning "High system load detected: ${load_avg} (${cpu_count} CPUs)"
    print_info "Consider waiting for load to decrease"
  else
    print_pass "System load: ${load_avg} (${cpu_count} CPUs)"
  fi

  return 0
}

check_required_files() {
  print_check "Checking required files exist..."

  local required_files=(
    "$NIX_DARWIN_DIR/flake.nix"
    "$NIX_DARWIN_DIR/flake.lock"
  )

  local missing=0
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      print_critical "Required file missing: $file"
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    print_pass "All required files present"
    return 0
  else
    return 1
  fi
}

check_secrets_encrypted() {
  print_check "Checking secrets encryption..."

  local secrets_files
  secrets_files=$(find "$NIX_DARWIN_DIR/hosts" -name "secrets.yaml" -not -path "*/_template/*")

  local unencrypted=0
  for file in $secrets_files; do
    if [[ -f "$file" ]]; then
      # Check if file contains sops and mac keys (encrypted)
      if grep -q "sops:" "$file" && grep -q "mac:" "$file"; then
        # Encrypted file
        continue
      else
        # Not encrypted
        print_critical "Secrets file is not encrypted: $file"
        print_info "Run: sops -e -i $file"
        ((unencrypted++))
      fi
    fi
  done

  if [[ $unencrypted -eq 0 ]]; then
    print_pass "All secrets properly encrypted"
    return 0
  else
    return 1
  fi
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --quiet)
        QUIET_MODE=true
        shift
        ;;
      --warnings-only)
        WARNINGS_ONLY=true
        shift
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--quiet] [--warnings-only]"
        exit 1
        ;;
    esac
  done

  print_header "🚀 Pre-Flight Checks for darwin-rebuild"

  # Run all checks
  check_disk_space || true
  check_git_status || true
  check_nix_daemon || true
  check_active_rebuilds || true
  check_flake_syntax || true
  check_nix_store_integrity || true
  check_network_connectivity || true
  check_system_load || true
  check_required_files || true
  check_secrets_encrypted || true

  # Print summary
  echo ""
  print_header "📊 Pre-Flight Summary"

  echo -e "${GREEN}✅ Passed: $PASS_COUNT${NC}"

  if [[ $WARNING_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Warnings: $WARNING_COUNT${NC}"
  fi

  if [[ $CRITICAL_COUNT -gt 0 ]]; then
    echo -e "${RED}❌ Critical: $CRITICAL_COUNT${NC}"
  fi

  echo ""

  # Determine exit code
  if [[ $CRITICAL_COUNT -gt 0 ]]; then
    echo -e "${RED}🚨 CRITICAL ISSUES DETECTED${NC}"
    echo -e "${RED}Fix critical issues before rebuilding${NC}"
    echo ""
    exit 1
  elif [[ $WARNING_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  WARNINGS DETECTED${NC}"
    echo -e "${YELLOW}Review warnings, rebuild may proceed with caution${NC}"
    echo ""
    exit 2
  else
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo -e "${GREEN}System ready for rebuild${NC}"
    echo ""
    exit 0
  fi
}

# Run main
main "$@"
