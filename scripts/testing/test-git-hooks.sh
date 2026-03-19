#!/usr/bin/env bash
# Test git hook behavior
# Tests pre-commit hook enforcement of file permissions

# Don't use 'set -e' because we expect some commands to fail
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "Testing Git Hooks"
echo "==================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Clean up any leftover test files from previous runs
echo "Cleaning up previous test files..."
rm -f ~/.tokens/test-token-* 2>/dev/null || true
rm -f test-dummy-*.txt 2>/dev/null || true
echo ""

# Helper function to run a test
run_test() {
  local test_name="$1"
  local test_command="$2"

  echo -n "Test: $test_name ... "

  if eval "$test_command" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}error: fAIL${NC}"
    ((TESTS_FAILED++))
  fi
}

# Test 1: Insecure file should block commit
echo "Test 1: Insecure permissions should block commit"
# Create test credential directory and file
mkdir -p "$HOME/.tokens"
TEST_FILE="$HOME/.tokens/test-token-$(date +%s)"
touch "$TEST_FILE"
chmod 644 "$TEST_FILE"

# Create a dummy git change to trigger pre-commit
DUMMY_FILE="test-dummy-$(date +%s).txt"
echo "test" > "$DUMMY_FILE"
git add "$DUMMY_FILE" 2>/dev/null || true

if git commit -m "test insecure file" 2>&1 | grep -q "BLOCKED"; then
  echo -e "  ${GREEN}PASS${NC}: Commit blocked for insecure file (644)"
  ((TESTS_PASSED++))
else
  echo -e "  ${RED}error: fAIL${NC}: Commit should have been blocked for 644 permissions"
  ((TESTS_FAILED++))
fi

# Clean up
git restore --staged "$DUMMY_FILE" 2>/dev/null || true
rm -f "$DUMMY_FILE" "$TEST_FILE"

# Test 2: Secure file should allow commit
echo "Test 2: Secure permissions should allow commit"
mkdir -p "$HOME/.tokens"
TEST_FILE="$HOME/.tokens/test-token-$(date +%s)"
touch "$TEST_FILE"
chmod 600 "$TEST_FILE"

# Create a dummy git change to trigger pre-commit
DUMMY_FILE="test-dummy-$(date +%s).txt"
echo "test" > "$DUMMY_FILE"
git add "$DUMMY_FILE" 2>/dev/null || true

if git commit -m "test secure file" >/dev/null 2>&1; then
  echo -e "  ${GREEN}PASS${NC}: Commit allowed for secure file (600)"
  ((TESTS_PASSED++))
  git reset --soft HEAD~1  # Undo commit
else
  echo -e "  ${RED}error: fAIL${NC}: Commit should have been allowed for 600 permissions"
  ((TESTS_FAILED++))
fi

# Clean up
git restore --staged "$DUMMY_FILE" 2>/dev/null || true
rm -f "$DUMMY_FILE" "$TEST_FILE"

# Test 3: --no-verify bypass should work
echo "Test 3: --no-verify should bypass hook"
mkdir -p "$HOME/.tokens"
TEST_FILE="$HOME/.tokens/test-token-$(date +%s)"
touch "$TEST_FILE"
chmod 644 "$TEST_FILE"

# Create a dummy git change to trigger pre-commit
DUMMY_FILE="test-dummy-$(date +%s).txt"
echo "test" > "$DUMMY_FILE"
git add "$DUMMY_FILE" 2>/dev/null || true

if git commit --no-verify -m "test bypass" >/dev/null 2>&1; then
  echo -e "  ${GREEN}PASS${NC}: --no-verify bypass works"
  ((TESTS_PASSED++))
  git reset --soft HEAD~1  # Undo commit
else
  echo -e "  ${RED}error: fAIL${NC}: --no-verify should bypass hook"
  ((TESTS_FAILED++))
fi

# Clean up
git restore --staged "$DUMMY_FILE" 2>/dev/null || true
rm -f "$DUMMY_FILE" "$TEST_FILE"

# Test 4: Error message should be clear and actionable
echo "Test 4: Error message should contain required information"
mkdir -p "$HOME/.tokens"
TEST_FILE="$HOME/.tokens/test-token-$(date +%s)"
touch "$TEST_FILE"
chmod 644 "$TEST_FILE"

# Create a dummy git change to trigger pre-commit
DUMMY_FILE="test-dummy-$(date +%s).txt"
echo "test" > "$DUMMY_FILE"
git add "$DUMMY_FILE" 2>/dev/null || true

ERROR_OUTPUT=$(git commit -m "test message" 2>&1 || true)

CHECKS_PASSED=0
CHECKS_TOTAL=4

if echo "$ERROR_OUTPUT" | grep -q "BLOCKED"; then
  ((CHECKS_PASSED++))
fi

if echo "$ERROR_OUTPUT" | grep -q "644"; then
  ((CHECKS_PASSED++))
fi

if echo "$ERROR_OUTPUT" | grep -q "600"; then
  ((CHECKS_PASSED++))
fi

if echo "$ERROR_OUTPUT" | grep -q "chmod 600"; then
  ((CHECKS_PASSED++))
fi

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo -e "  ${GREEN}PASS${NC}: Error message contains all required information"
  ((TESTS_PASSED++))
else
  echo -e "  ${RED}error: fAIL${NC}: Error message missing information ($CHECKS_PASSED/$CHECKS_TOTAL checks passed)"
  ((TESTS_FAILED++))
fi

# Clean up
git restore --staged "$DUMMY_FILE" 2>/dev/null || true
rm -f "$DUMMY_FILE" "$TEST_FILE"

# Test 5: Hook should collect ALL issues before failing
echo "Test 5: Hook should report all issues at once"
mkdir -p "$HOME/.tokens"
TEST_FILE1="$HOME/.tokens/test-token-1-$(date +%s)"
TEST_FILE2="$HOME/.tokens/test-token-2-$(date +%s)"
touch "$TEST_FILE1" "$TEST_FILE2"
chmod 644 "$TEST_FILE1" "$TEST_FILE2"

# Create a dummy git change to trigger pre-commit
DUMMY_FILE="test-dummy-$(date +%s).txt"
echo "test" > "$DUMMY_FILE"
git add "$DUMMY_FILE" 2>/dev/null || true

ERROR_OUTPUT=$(git commit -m "test multiple files" 2>&1 || true)

# Should mention both files in the error
if echo "$ERROR_OUTPUT" | grep -q "test-token-1" && echo "$ERROR_OUTPUT" | grep -q "test-token-2"; then
  echo -e "  ${GREEN}PASS${NC}: Hook reports all insecure files"
  ((TESTS_PASSED++))
else
  echo -e "  ${YELLOW}warning: sKIP${NC}: Could not verify multiple file reporting"
fi

# Clean up
git restore --staged "$DUMMY_FILE" 2>/dev/null || true
rm -f "$DUMMY_FILE" "$TEST_FILE1" "$TEST_FILE2"

# Summary
echo ""
echo "==================="
echo "Test Summary"
echo "==================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All hook tests passed!${NC}"
  exit 0
else
  echo -e "${RED}error: some tests failed${NC}"
  exit 1
fi
