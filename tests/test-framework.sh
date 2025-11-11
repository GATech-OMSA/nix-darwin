#!/usr/bin/env bash
#
# Test Framework for nix-darwin Integration Tests
#
# Provides helper functions for writing test assertions and managing test execution.
# All test scripts should source this framework.
#
# Usage:
#   source "$(dirname "$0")/test-framework.sh"
#   test_begin "My Test Suite"
#   assert_command_exists "nix"
#   assert_file_exists "/path/to/file"
#   test_end
#

# Note: Not using 'set -e' because we want to continue on test failures
set -uo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Color codes
export TEST_RED='\033[0;31m'
export TEST_GREEN='\033[0;32m'
export TEST_YELLOW='\033[1;33m'
export TEST_BLUE='\033[0;34m'
export TEST_CYAN='\033[0;36m'
export TEST_BOLD='\033[1m'
export TEST_NC='\033[0m'

# Test counters
export TEST_TOTAL=0
export TEST_PASSED=0
export TEST_FAILED=0
export TEST_SKIPPED=0

# Test state
export TEST_SUITE_NAME=""
export TEST_START_TIME=""
export TEST_VERBOSE="${TEST_VERBOSE:-0}"
export TEST_DRY_RUN="${TEST_DRY_RUN:-0}"

# Repository root
export REPO_ROOT
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================================================
# TEST LIFECYCLE FUNCTIONS
# ============================================================================

test_begin() {
  TEST_SUITE_NAME="$1"
  TEST_START_TIME=$(date +%s)
  TEST_TOTAL=0
  TEST_PASSED=0
  TEST_FAILED=0
  TEST_SKIPPED=0

  echo ""
  echo -e "${TEST_BOLD}${TEST_CYAN}════════════════════════════════════════════════════════${TEST_NC}"
  echo -e "${TEST_BOLD}${TEST_CYAN}🧪 Test Suite: ${TEST_SUITE_NAME}${TEST_NC}"
  echo -e "${TEST_BOLD}${TEST_CYAN}════════════════════════════════════════════════════════${TEST_NC}"
  echo ""
}

test_end() {
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - TEST_START_TIME))

  echo ""
  echo -e "${TEST_BOLD}${TEST_CYAN}────────────────────────────────────────────────────────${TEST_NC}"
  echo -e "${TEST_BOLD}Results for: ${TEST_SUITE_NAME}${TEST_NC}"
  echo ""
  echo -e "  Total:   ${TEST_TOTAL}"
  echo -e "  ${TEST_GREEN}Passed:  ${TEST_PASSED}${TEST_NC}"
  echo -e "  ${TEST_RED}Failed:  ${TEST_FAILED}${TEST_NC}"
  echo -e "  ${TEST_YELLOW}Skipped: ${TEST_SKIPPED}${TEST_NC}"
  echo -e "  Duration: ${duration}s"
  echo ""

  if [[ $TEST_FAILED -eq 0 ]]; then
    echo -e "${TEST_GREEN}${TEST_BOLD}✅ ALL TESTS PASSED${TEST_NC}"
    exit 0
  else
    echo -e "${TEST_RED}${TEST_BOLD}❌ SOME TESTS FAILED${TEST_NC}"
    exit 1
  fi
}

# ============================================================================
# ASSERTION FUNCTIONS
# ============================================================================

_test_log() {
  local status="$1"
  local message="$2"
  local details="${3:-}"

  ((TEST_TOTAL++))

  case "$status" in
    pass)
      ((TEST_PASSED++))
      echo -e "  ${TEST_GREEN}✓${TEST_NC} $message"
      ;;
    fail)
      ((TEST_FAILED++))
      echo -e "  ${TEST_RED}✗${TEST_NC} $message"
      if [[ -n "$details" ]]; then
        echo -e "    ${TEST_RED}→${TEST_NC} $details"
      fi
      ;;
    skip)
      ((TEST_SKIPPED++))
      echo -e "  ${TEST_YELLOW}⊘${TEST_NC} $message (skipped)"
      ;;
  esac

  if [[ $TEST_VERBOSE -eq 1 && -n "$details" ]]; then
    echo -e "    ${TEST_CYAN}→${TEST_NC} $details"
  fi
}

assert_command_exists() {
  local cmd="$1"
  local message="${2:-Command '$cmd' exists}"

  if command -v "$cmd" &> /dev/null; then
    _test_log "pass" "$message"
  else
    _test_log "fail" "$message" "Command not found: $cmd"
  fi
  return 0  # Always return success to continue testing
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File exists: $file}"

  if [[ -f "$file" ]]; then
    _test_log "pass" "$message"
  else
    _test_log "fail" "$message" "File not found: $file"
  fi
  return 0
}

assert_directory_exists() {
  local dir="$1"
  local message="${2:-Directory exists: $dir}"

  if [[ -d "$dir" ]]; then
    _test_log "pass" "$message"
  else
    _test_log "fail" "$message" "Directory not found: $dir"
  fi
  return 0
}

assert_symlink_exists() {
  local link="$1"
  local message="${2:-Symlink exists: $link}"

  if [[ -L "$link" ]]; then
    _test_log "pass" "$message"
  else
    _test_log "fail" "$message" "Symlink not found: $link"
  fi
  return 0
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File '$file' contains '$pattern'}"

  if [[ ! -f "$file" ]]; then
    _test_log "fail" "$message" "File not found: $file"
    return 0
  fi

  if grep -q "$pattern" "$file" 2>/dev/null; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Pattern not found in file"
    return 0
  fi
}

assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File '$file' does not contain '$pattern'}"

  if [[ ! -f "$file" ]]; then
    _test_log "fail" "$message" "File not found: $file"
    return 0
  fi

  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Pattern found in file (should not exist)"
    return 0
  fi
}

assert_command_succeeds() {
  local cmd="$1"
  local message="${2:-Command succeeds: $cmd}"

  if eval "$cmd" &> /dev/null; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Command failed with exit code: $?"
    return 0
  fi
}

assert_command_fails() {
  local cmd="$1"
  local message="${2:-Command fails: $cmd}"

  if ! eval "$cmd" &> /dev/null; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Command succeeded (expected failure)"
    return 0
  fi
}

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values equal: '$actual' == '$expected'}"

  if [[ "$actual" == "$expected" ]]; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Expected: '$expected', Got: '$actual'"
    return 0
  fi
}

assert_not_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values not equal: '$actual' != '$expected'}"

  if [[ "$actual" != "$expected" ]]; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Values should not be equal: '$actual'"
    return 0
  fi
}

assert_file_permissions() {
  local file="$1"
  local expected_perms="$2"
  local message="${3:-File '$file' has permissions $expected_perms}"

  if [[ ! -f "$file" ]]; then
    _test_log "fail" "$message" "File not found: $file"
    return 0
  fi

  local actual_perms
  actual_perms=$(stat -f "%A" "$file" 2>/dev/null || echo "000")

  if [[ "$actual_perms" == "$expected_perms" ]]; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Expected: $expected_perms, Got: $actual_perms"
    return 0
  fi
}

assert_exit_code() {
  local cmd="$1"
  local expected_code="$2"
  local message="${3:-Command exits with code $expected_code}"

  local actual_code=0
  eval "$cmd" &> /dev/null || actual_code=$?

  if [[ "$actual_code" -eq "$expected_code" ]]; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Expected: $expected_code, Got: $actual_code"
    return 0
  fi
}

assert_output_contains() {
  local cmd="$1"
  local pattern="$2"
  local message="${3:-Output contains: $pattern}"

  local output
  output=$(eval "$cmd" 2>&1)

  if echo "$output" | grep -q "$pattern"; then
    _test_log "pass" "$message"
    return 0
  else
    _test_log "fail" "$message" "Pattern not found in output"
    if [[ $TEST_VERBOSE -eq 1 ]]; then
      echo -e "    ${TEST_CYAN}Output:${TEST_NC}"
      echo "$output" | sed 's/^/      /'
    fi
    return 0
  fi
}

test_skip() {
  local message="${1:-Test skipped}"
  local reason="${2:-}"

  ((TEST_TOTAL++))
  ((TEST_SKIPPED++))
  echo -e "  ${TEST_YELLOW}⊘${TEST_NC} $message (skipped)"
  if [[ -n "$reason" ]]; then
    echo -e "    ${TEST_YELLOW}→${TEST_NC} $reason"
  fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

test_info() {
  echo -e "${TEST_BLUE}ℹ${TEST_NC} $1"
}

test_section() {
  echo ""
  echo -e "${TEST_BOLD}${TEST_BLUE}▶ $1${TEST_NC}"
  echo ""
}

test_verbose() {
  if [[ $TEST_VERBOSE -eq 1 ]]; then
    echo -e "  ${TEST_CYAN}→${TEST_NC} $1"
  fi
}

# ============================================================================
# FIXTURE HELPERS
# ============================================================================

create_temp_file() {
  local content="${1:-}"
  local temp_file
  temp_file=$(mktemp)
  echo "$content" > "$temp_file"
  echo "$temp_file"
}

cleanup_temp_file() {
  local file="$1"
  [[ -f "$file" ]] && rm -f "$file"
}

# Export all functions
export -f test_begin
export -f test_end
export -f _test_log
export -f assert_command_exists
export -f assert_file_exists
export -f assert_directory_exists
export -f assert_symlink_exists
export -f assert_file_contains
export -f assert_file_not_contains
export -f assert_command_succeeds
export -f assert_command_fails
export -f assert_equals
export -f assert_not_equals
export -f assert_file_permissions
export -f assert_exit_code
export -f assert_output_contains
export -f test_skip
export -f test_info
export -f test_section
export -f test_verbose
export -f create_temp_file
export -f cleanup_temp_file
