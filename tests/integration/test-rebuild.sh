#!/usr/bin/env bash
#
# Test: Full Rebuild Cycle
# Tests complete rebuild workflow (build only, no switch)
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Full Rebuild Cycle"

test_section "Prerequisites"

# Test: darwin-rebuild available
assert_command_exists \
  "darwin-rebuild" \
  "darwin-rebuild command available"

# Test: Nix daemon running
assert_command_succeeds \
  "pgrep -x nix-daemon" \
  "Nix daemon is running"

# Test: Clean git state
if git -C "$REPO_ROOT" diff --quiet 2>/dev/null; then
  _test_log "pass" "Git working tree is clean"
else
  _test_log "fail" "Git has uncommitted changes" \
    "Commit or stash changes before testing"
fi

test_section "Pre-Flight Checks"

# Test: Pre-flight script exists
assert_file_exists \
  "$REPO_ROOT/scripts/pre-flight-checks.sh" \
  "Pre-flight checks script exists"

# Test: Pre-flight checks pass
if [[ "${TEST_DRY_RUN:-0}" -eq 0 ]]; then
  if "$REPO_ROOT/scripts/pre-flight-checks.sh" --quiet 2>&1 | tee /tmp/preflight-test.log; then
    _test_log "pass" "Pre-flight checks pass"
  else
    _test_log "fail" "Pre-flight checks failed" \
      "Check log: /tmp/preflight-test.log"
  fi
else
  test_skip "Pre-flight execution" "TEST_DRY_RUN=1"
fi

test_section "Build Process"

current_hostname=$(hostname -s)

if [[ "$current_hostname" != "mbp-jimmy" ]] && [[ "$current_hostname" != "mbp-work" ]]; then
  test_skip "Build test" "Unknown hostname: $current_hostname"
  test_end
fi

# Test: Configuration builds successfully
if [[ "${TEST_DRY_RUN:-0}" -eq 0 ]]; then
  test_info "Building configuration (this may take several minutes)..."

  build_start=$(date +%s)

  if darwin-rebuild build --flake "$REPO_ROOT#$current_hostname" 2>&1 | tee /tmp/rebuild-test.log; then
    build_end=$(date +%s)
    build_duration=$((build_end - build_start))

    _test_log "pass" "Configuration built successfully (${build_duration}s)"

    # Test: Build created result symlink
    if [[ -L "$REPO_ROOT/result" ]]; then
      _test_log "pass" "Build created result symlink"

      # Get derivation info
      if drv_path=$(readlink "$REPO_ROOT/result" 2>/dev/null); then
        test_verbose "Derivation: $drv_path"
      fi

      # Cleanup
      rm -f "$REPO_ROOT/result"
    else
      _test_log "fail" "No result symlink created"
    fi
  else
    build_end=$(date +%s)
    build_duration=$((build_end - build_start))

    _test_log "fail" "Build failed after ${build_duration}s" \
      "Check log: /tmp/rebuild-test.log"
  fi
else
  test_skip "Build execution" "TEST_DRY_RUN=1"
fi

test_section "Post-Build Validation"

# Test: No build artifacts remain
assert_command_fails \
  "[[ -L '$REPO_ROOT/result' ]]" \
  "Build artifacts cleaned up"

# Test: Nix store still accessible
assert_command_succeeds \
  "ls /nix/store > /dev/null" \
  "Nix store still accessible"

# Test: System still responsive
assert_command_succeeds \
  "echo 'test' > /dev/null" \
  "System remains responsive"

test_end
