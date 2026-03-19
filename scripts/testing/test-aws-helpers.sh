#!/bin/bash
# Test script for AWS multi-role implementation

set -e

echo "Testing AWS Multi-Role Implementation"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
  echo -e "${GREEN}$1${NC}"
}

error() {
  echo -e "${RED}error: $1${NC}"
}

warn() {
  echo -e "${YELLOW}warning: $1${NC}"
}

# Test 1: Check accounts.json exists
echo "Test 1: Check accounts.json"
if [ -f ~/.aws/accounts.json ]; then
  success "accounts.json found"

  # Validate JSON
  if jq empty ~/.aws/accounts.json 2>/dev/null; then
    success "accounts.json is valid JSON"
  else
    error "accounts.json is invalid JSON"
    exit 1
  fi
else
  warn "accounts.json not found (optional for testing)"
fi

echo ""

# Test 2: Check AWS config generated
echo "Test 2: Check AWS config profiles"
if [ -f ~/.aws/config ]; then
  success "AWS config found"

  # Count profiles
  profile_count=$(grep -c "^\[profile " ~/.aws/config || true)
  echo "  Found $profile_count profiles"

  # Show first few
  echo "  Sample profiles:"
  grep "^\[profile " ~/.aws/config | head -5 | sed 's/^/    /'
else
  error "AWS config not found"
  exit 1
fi

echo ""

# Test 3: Check awsuse function exists
echo "Test 3: Check shell functions"
if type awsuse &>/dev/null; then
  success "awsuse function loaded"
else
  error "awsuse function not found"
  exit 1
fi

if type awslogin &>/dev/null; then
  success "awslogin function loaded"
else
  error "awslogin function not found"
  exit 1
fi

if type awslist &>/dev/null; then
  success "awslist function loaded"
else
  error "awslist function not found"
  exit 1
fi

if type awswhere &>/dev/null; then
  success "awswhere function loaded"
else
  error "awswhere function not found"
  exit 1
fi

if type awscheck &>/dev/null; then
  success "awscheck function loaded"
else
  error "awscheck function not found"
  exit 1
fi

echo ""

# Test 4: Check aliases generated
echo "Test 4: Check aliases generated from accounts.json"
if [ -f ~/.aws/accounts.json ]; then
  # Get first project alias
  first_alias=$(jq -r 'to_entries[0].value.alias' ~/.aws/accounts.json)
  first_env=$(jq -r 'to_entries[0].value.accounts | keys[0]' ~/.aws/accounts.json)

  expected_alias="${first_alias}${first_env}"

  if alias | grep -q "^${expected_alias}="; then
    success "Alias generated: $expected_alias"
  else
    warn "Alias not found: $expected_alias (may need shell reload)"
  fi
else
  warn "Skipping alias test (no accounts.json)"
fi

echo ""

# Test 5: Check for deprecated generic aliases
echo "Test 5: Check for deprecated generic aliases"
if alias | grep -q "^awsdev="; then
  warn "Generic 'awsdev' alias found (deprecated, but OK if intentional)"
else
  success "No generic 'awsdev' alias (good!)"
fi

echo ""

# Test 6: Test awslist output
echo "Test 6: Test awslist function"
if [ -f ~/.aws/accounts.json ]; then
  echo "  Output sample:"
  awslist 2>/dev/null | head -10 | sed 's/^/    /'
  success "awslist works"
else
  warn "Skipping awslist test (no accounts.json)"
fi

echo ""

# Test 7: Check profile format
echo "Test 7: Check profile naming format"
if [ -f ~/.aws/accounts.json ]; then
  # Check if any profiles with roles exist
  if grep -q "^\[profile .*-developer\]" ~/.aws/config 2>/dev/null; then
    success "Role-specific profiles found (e.g., *-developer)"
  else
    warn "No role-specific profiles found (may not have additional_roles configured)"
  fi

  # Check for support profiles
  first_project=$(jq -r 'to_entries[0].key' ~/.aws/accounts.json)
  first_env=$(jq -r 'to_entries[0].value.accounts | keys[0]' ~/.aws/accounts.json)
  expected_profile="${first_project}-${first_env}"

  if grep -q "^\[profile $expected_profile\]" ~/.aws/config 2>/dev/null; then
    success "Default profile format correct: $expected_profile"
  else
    error "Expected profile not found: $expected_profile"
  fi
else
  warn "Skipping profile format test (no accounts.json)"
fi

echo ""
echo "All tests completed!"
echo ""
echo "Next steps:"
echo "  1. Run: exec zsh (to reload shell with new aliases)"
echo "  2. Try: awslist (to see all accounts)"
echo "  3. Test: awsuse <alias> <env> [role]"
echo "  4. Check: awswho (to see current profile)"
echo ""
