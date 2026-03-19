#!/usr/bin/env bash
#
# Run All Tests
# Comprehensive test runner for nix-darwin integration test suite
#
# Usage:
#   ./tests/run-all-tests.sh                    # Run all tests
#   ./tests/run-all-tests.sh --verbose          # Detailed output
#   ./tests/run-all-tests.sh --category build   # Run specific category
#   ./tests/run-all-tests.sh --dry-run          # Skip expensive operations
#   ./tests/run-all-tests.sh --ci               # CI mode (minimal output, exit codes)
#
# Exit codes:
#   0 - All tests passed
#   1 - Some tests failed
#   2 - Invalid arguments
#

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test execution options
VERBOSE=0
DRY_RUN=0
CI_MODE=0
CATEGORY=""
STOP_ON_FAIL=0

# Test tracking
SUITES_TOTAL=0
SUITES_PASSED=0
SUITES_FAILED=0
SUITES_SKIPPED=0

START_TIME=$(date +%s)

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

print_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Options:
  -v, --verbose         Show detailed test output
  -d, --dry-run         Skip expensive operations (builds, etc.)
  -c, --category CAT    Run only specific category (build|security|lib|integration)
  -s, --stop-on-fail    Stop execution on first test failure
  --ci                  CI mode (minimal output, strict exit codes)
  -h, --help            Show this help message

Categories:
  build                 Build process tests (flake check, syntax, darwin build)
  security              Security tests (SOPS, permissions, git hooks)
  lib                   Library function tests (helpers, machine detection)
  integration           Integration tests (multi-machine, rebuild, rollback)
  all                   Run all tests (default)

Examples:
  $0                              # Run all tests
  $0 --verbose                    # Run all with detailed output
  $0 --category build             # Run only build tests
  $0 --dry-run --category build   # Quick build validation
  $0 --ci                         # CI/CD pipeline mode

EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=1
      export TEST_VERBOSE=1
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=1
      export TEST_DRY_RUN=1
      shift
      ;;
    -c|--category)
      CATEGORY="$2"
      shift 2
      ;;
    -s|--stop-on-fail)
      STOP_ON_FAIL=1
      shift
      ;;
    --ci)
      CI_MODE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 2
      ;;
  esac
done

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
  if [[ $CI_MODE -eq 0 ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
  fi
}

print_section() {
  if [[ $CI_MODE -eq 0 ]]; then
    echo ""
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
    echo ""
  fi
}

print_info() {
  if [[ $CI_MODE -eq 0 ]]; then
    echo -e "${BLUE}→${NC} $1"
  fi
}

run_test_suite() {
  local test_script="$1"
  local suite_name
  suite_name=$(basename "$test_script" .sh)

  ((SUITES_TOTAL++))

  if [[ $CI_MODE -eq 0 ]]; then
    echo ""
    echo -e "${CYAN}Running:${NC} $suite_name"
  fi

  # Run the test
  if bash "$test_script"; then
    ((SUITES_PASSED++))
    if [[ $CI_MODE -eq 0 ]]; then
      echo -e "${GREEN}✓ PASSED:${NC} $suite_name"
    else
      echo "PASS: $suite_name"
    fi
    return 0
  else
    ((SUITES_FAILED++))
    if [[ $CI_MODE -eq 0 ]]; then
      echo -e "${RED}✗ FAILED:${NC} $suite_name"
    else
      echo "FAIL: $suite_name"
    fi

    if [[ $STOP_ON_FAIL -eq 1 ]]; then
      echo ""
      echo -e "${RED}Stopping on first failure (--stop-on-fail)${NC}"
      generate_report
      exit 1
    fi

    return 1
  fi
}

generate_report() {
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - START_TIME))

  if [[ $CI_MODE -eq 0 ]]; then
    print_header "Test Execution Summary"

    echo -e "${BOLD}Total Test Suites:${NC} $SUITES_TOTAL"
    echo -e "${GREEN}✓ Passed:${NC}          $SUITES_PASSED"
    echo -e "${RED}✗ Failed:${NC}          $SUITES_FAILED"
    echo -e "${YELLOW}⊘ Skipped:${NC}         $SUITES_SKIPPED"
    echo ""
    echo -e "${BOLD}Execution Time:${NC}    ${duration}s"
    echo ""

    if [[ $SUITES_FAILED -eq 0 ]]; then
      echo -e "${GREEN}${BOLD}ALL TEST SUITES PASSED${NC}"
      echo ""
    else
      echo -e "${RED}${BOLD}error: sOME TEST SUITES FAILED${NC}"
      echo ""
      echo -e "${YELLOW}Review failed test output above for details${NC}"
      echo ""
    fi
  else
    # CI mode: compact output
    echo ""
    echo "===== TEST SUMMARY ====="
    echo "Total:   $SUITES_TOTAL"
    echo "Passed:  $SUITES_PASSED"
    echo "Failed:  $SUITES_FAILED"
    echo "Skipped: $SUITES_SKIPPED"
    echo "Time:    ${duration}s"
    echo "======================="
  fi
}

# ============================================================================
# TEST EXECUTION
# ============================================================================

main() {
  print_header "Nix-Darwin Integration Test Suite"

  if [[ $DRY_RUN -eq 1 ]]; then
    print_info "Dry-run mode: Skipping expensive operations"
  fi

  if [[ -n "$CATEGORY" ]]; then
    print_info "Running category: $CATEGORY"
  fi

  # Define test suites by category (Bash 3 compatible - no associative arrays)
  tests_build="$SCRIPT_DIR/build/test-flake-check.sh
$SCRIPT_DIR/build/test-syntax.sh
$SCRIPT_DIR/build/test-darwin-build.sh"

  tests_security="$SCRIPT_DIR/security/test-sops-encryption.sh
$SCRIPT_DIR/security/test-permissions.sh
$SCRIPT_DIR/security/test-git-hooks.sh"

  tests_lib="$SCRIPT_DIR/lib/test-machine-detection.sh
$SCRIPT_DIR/lib/test-helpers.sh"

  tests_integration="$SCRIPT_DIR/integration/test-multi-machine.sh
$SCRIPT_DIR/integration/test-rebuild.sh
$SCRIPT_DIR/integration/test-rollback.sh"

  # Function to get tests for a category (Bash 3 compatible)
  get_tests_for_category() {
    case "$1" in
      build) echo "$tests_build" ;;
      security) echo "$tests_security" ;;
      lib) echo "$tests_lib" ;;
      integration) echo "$tests_integration" ;;
      *) echo "" ;;
    esac
  }

  # Determine which tests to run
  if [[ -n "$CATEGORY" ]]; then
    tests_to_run=$(get_tests_for_category "$CATEGORY")
    if [[ -z "$tests_to_run" ]]; then
      echo -e "${RED}Error: Unknown category '$CATEGORY'${NC}"
      echo "Valid categories: build, security, lib, integration, all"
      exit 2
    fi
  else
    # Run all tests
    tests_to_run=""
    for category in build security lib integration; do
      tests_to_run+="$(get_tests_for_category "$category")"$'\n'
    done
  fi

  # Make all test scripts executable
  find "$SCRIPT_DIR" -name "test-*.sh" -type f -exec chmod +x {} \;
  chmod +x "$SCRIPT_DIR/test-framework.sh"

  # Run tests by category
  for category in build security lib integration; do
    # Skip if specific category requested and this isn't it
    if [[ -n "$CATEGORY" ]] && [[ "$CATEGORY" != "$category" ]]; then
      continue
    fi

    print_section "Category: $(echo "$category" | tr '[:lower:]' '[:upper:]')"

    # Run each test in category
    while IFS= read -r test_script; do
      [[ -z "$test_script" ]] && continue
      [[ ! -f "$test_script" ]] && continue

      run_test_suite "$test_script" || true
    done <<< "$(get_tests_for_category "$category")"
  done

  # Generate final report
  generate_report

  # Exit with appropriate code
  if [[ $SUITES_FAILED -eq 0 ]]; then
    exit 0
  else
    exit 1
  fi
}

# Run main
main
