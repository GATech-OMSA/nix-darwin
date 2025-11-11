#!/usr/bin/env bash
#
# Test: Darwin Build
# Tests darwin-rebuild build without switching (dry-run validation)
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Darwin Build"

test_section "Prerequisites"

# Test: darwin-rebuild command exists
assert_command_exists \
  "darwin-rebuild" \
  "darwin-rebuild command available"

# Test: Nix daemon is running
assert_command_succeeds \
  "pgrep -x nix-daemon" \
  "Nix daemon is running"

# Test: Hostname detection
current_hostname=$(hostname -s)
assert_command_succeeds \
  "hostname -s" \
  "Can detect current hostname: $current_hostname"

test_section "Build Configuration"

# Determine which configuration to build
if [[ "$current_hostname" == "mbp-work" ]]; then
  config_name="mbp-work"
elif [[ "$current_hostname" == "mbp-jimmy" ]]; then
  config_name="mbp-jimmy"
else
  test_skip "Build test" "Running on unknown hostname: $current_hostname"
  test_end
fi

test_info "Testing configuration: $config_name"

test_section "Dry Build (No Switch)"

# Test: Build without switching (validates but doesn't activate)
if [[ "${TEST_DRY_RUN:-0}" -eq 0 ]]; then
  test_info "Performing dry build (this may take a few minutes)..."

  if darwin-rebuild build --flake "$REPO_ROOT#$config_name" 2>&1 | tee /tmp/darwin-build-test.log; then
    _test_log "pass" "Configuration builds successfully"

    # Check for result symlink
    if [[ -L "$REPO_ROOT/result" ]]; then
      _test_log "pass" "Build created result symlink"

      # Cleanup result symlink
      rm -f "$REPO_ROOT/result"
    else
      _test_log "fail" "Build did not create result symlink"
    fi
  else
    _test_log "fail" "Configuration build failed" \
      "Check build log: /tmp/darwin-build-test.log"
  fi
else
  test_skip "Dry build test" "TEST_DRY_RUN=1"
fi

test_section "Build Artifacts"

# Test: No build artifacts left behind
assert_command_fails \
  "[[ -L '$REPO_ROOT/result' ]]" \
  "No result symlink left after cleanup"

test_end
