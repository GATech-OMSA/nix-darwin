#!/usr/bin/env bash
#
# Test: Multi-Machine Configuration
# Tests personal vs work machine differentiation
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Multi-Machine Configuration"

test_section "Machine Type Detection"

current_hostname=$(hostname -s)
test_info "Current hostname: $current_hostname"

# Determine expected configuration
if [[ "$current_hostname" == "mbp-jimmy" ]]; then
  expected_mode="home"
  expected_profile="personal"
  config_name="mbp-jimmy"
elif [[ "$current_hostname" == "mbp-work" ]]; then
  expected_mode="work"
  expected_profile="work-domain"
  config_name="mbp-work"
else
  test_skip "All multi-machine tests" "Unknown hostname: $current_hostname"
  test_end
fi

test_info "Expected MACHINE_MODE: $expected_mode"
test_info "Expected AWS_PROFILE: $expected_profile"

test_section "Environment Variables"

# Test: MACHINE_MODE matches expected
assert_equals \
  "${MACHINE_MODE:-unset}" \
  "$expected_mode" \
  "MACHINE_MODE matches machine type"

# Test: AWS_PROFILE matches expected (if set)
if [[ -n "${AWS_PROFILE:-}" ]]; then
  assert_equals \
    "$AWS_PROFILE" \
    "$expected_profile" \
    "AWS_PROFILE matches machine type"
else
  test_skip "AWS_PROFILE test" "AWS_PROFILE not set"
fi

test_section "Mixin Configuration"

# Test: Appropriate mixin is loaded
if [[ "$current_hostname" == "mbp-jimmy" ]]; then
  assert_file_exists \
    "$REPO_ROOT/home/_mixins/personal.nix" \
    "Personal mixin exists"

  # Verify it's being used in configuration
  if [[ -f "$REPO_ROOT/hosts/mbp-jimmy/default.nix" ]]; then
    assert_file_contains \
      "$REPO_ROOT/hosts/mbp-jimmy/default.nix" \
      "personal.nix" \
      "Personal Mac imports personal.nix"
  fi

elif [[ "$current_hostname" == "mbp-work" ]]; then
  assert_file_exists \
    "$REPO_ROOT/home/_mixins/work.nix" \
    "Work mixin exists"

  # Verify it's being used in configuration
  if [[ -f "$REPO_ROOT/hosts/mbp-work/default.nix" ]]; then
    assert_file_contains \
      "$REPO_ROOT/hosts/mbp-work/default.nix" \
      "work.nix" \
      "Work Mac imports work.nix"
  fi
fi

test_section "Git Configuration"

# Test: Git email matches machine type
git_email=$(git config user.email 2>/dev/null || echo "")

if [[ "$current_hostname" == "mbp-jimmy" ]]; then
  if [[ "$git_email" == *"users.noreply.github.com"* ]]; then
    _test_log "pass" "Personal Mac uses GitHub noreply email"
  else
    _test_log "fail" "Personal Mac email unexpected: $git_email"
  fi

elif [[ "$current_hostname" == "mbp-work" ]]; then
  if [[ "$git_email" == *"@"* ]] && [[ "$git_email" != *"users.noreply.github.com"* ]]; then
    _test_log "pass" "Work Mac uses work email: $git_email"
  else
    _test_log "fail" "Work Mac email unexpected: $git_email"
  fi
fi

test_section "Machine-Specific Functions"

# Test: Work-specific functions on work Mac
if [[ "$current_hostname" == "mbp-work" ]]; then
  if command -v awslogin &> /dev/null; then
    _test_log "pass" "Work Mac has awslogin function"
  else
    _test_log "fail" "Work Mac missing awslogin function"
  fi

  if command -v awswho &> /dev/null; then
    _test_log "pass" "Work Mac has awswho function"
  else
    _test_log "fail" "Work Mac missing awswho function"
  fi
fi

# Test: Personal-specific settings on personal Mac
if [[ "$current_hostname" == "mbp-jimmy" ]]; then
  # Personal Mac should not have work-specific functions
  if ! command -v awslogin &> /dev/null; then
    _test_log "pass" "Personal Mac doesn't have work functions"
  else
    _test_log "fail" "Personal Mac has work-specific functions"
  fi
fi

test_section "Configuration Files"

# Test: Host-specific directory exists
assert_directory_exists \
  "$REPO_ROOT/hosts/$config_name" \
  "Host directory exists: hosts/$config_name"

# Test: Host configuration files exist
assert_file_exists \
  "$REPO_ROOT/hosts/$config_name/default.nix" \
  "Host default.nix exists"

# Test: Secrets file exists (should be encrypted)
if [[ -f "$REPO_ROOT/hosts/$config_name/secrets.yaml" ]]; then
  assert_file_exists \
    "$REPO_ROOT/hosts/$config_name/secrets.yaml" \
    "Secrets file exists"

  # Should be encrypted (binary)
  if file "$REPO_ROOT/hosts/$config_name/secrets.yaml" | grep -q "data"; then
    _test_log "pass" "Secrets file is encrypted"
  else
    _test_log "fail" "Secrets file is not encrypted"
  fi
fi

test_end
