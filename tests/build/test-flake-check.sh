#!/usr/bin/env bash
#
# Test: Flake Check
# Validates nix flake structure and configuration
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Flake Check"

test_section "Flake Metadata"

# Test: Flake metadata is accessible
assert_command_succeeds \
  "cd '$REPO_ROOT' && nix flake metadata --no-write-lock-file" \
  "Flake metadata is valid"

# Test: Flake shows command works
assert_command_succeeds \
  "cd '$REPO_ROOT' && nix flake show" \
  "Flake show succeeds"

test_section "Flake Outputs"

# Test: darwinConfigurations exists for mbp-jimmy
assert_output_contains \
  "cd '$REPO_ROOT' && nix flake show 2>&1" \
  "darwinConfigurations" \
  "Flake has darwinConfigurations output"

# Test: darwinConfigurations exists for mbp-work
assert_output_contains \
  "cd '$REPO_ROOT' && nix flake show 2>&1" \
  "mbp-work" \
  "Flake has mbp-work configuration"

test_section "Flake Lock"

# Test: flake.lock exists
assert_file_exists \
  "$REPO_ROOT/flake.lock" \
  "flake.lock exists"

# Test: flake.lock is valid JSON
assert_command_succeeds \
  "jq empty '$REPO_ROOT/flake.lock'" \
  "flake.lock is valid JSON"

# Test: flake.lock has required inputs
assert_file_contains \
  "$REPO_ROOT/flake.lock" \
  "nixpkgs" \
  "flake.lock contains nixpkgs input"

assert_file_contains \
  "$REPO_ROOT/flake.lock" \
  "nix-darwin" \
  "flake.lock contains nix-darwin input"

assert_file_contains \
  "$REPO_ROOT/flake.lock" \
  "home-manager" \
  "flake.lock contains home-manager input"

test_section "Flake Inputs"

# Test: All inputs are up to date (no uncommitted lock changes)
if [[ -f "$REPO_ROOT/flake.lock" ]]; then
  if git -C "$REPO_ROOT" diff --quiet flake.lock 2>/dev/null; then
    _test_log "pass" "flake.lock has no uncommitted changes"
  else
    _test_log "fail" "flake.lock has uncommitted changes" \
      "Run: git diff flake.lock"
  fi
fi

test_end
