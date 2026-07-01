#!/usr/bin/env bash
#
# Test: Flake Check
# Validates flake structure and metadata

source "$(dirname "$0")/../test-framework.sh"

test_begin "Flake Check"

test_section "Flake Structure"

assert_file_exists \
  "$REPO_ROOT/flake.nix" \
  "flake.nix exists"

assert_file_exists \
  "$REPO_ROOT/flake.lock" \
  "flake.lock exists"

test_section "Flake Metadata"

assert_command_succeeds \
  "nix flake metadata '$REPO_ROOT' --no-write-lock-file" \
  "Flake metadata is readable"

test_section "Flake Evaluation"

if [[ "${TEST_DRY_RUN:-0}" -eq 1 ]]; then
  test_skip "Flake check" "Skipped in dry-run mode"
else
  assert_command_succeeds \
    "nix flake check '$REPO_ROOT' --no-build --no-write-lock-file 2>&1" \
    "nix flake check passes (no-build)"
fi

test_section "Machine Registry"

MACHINE_ID=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" machineId 2>/dev/null || echo "")
if [[ -n "$MACHINE_ID" ]]; then
  _test_log "pass" "machineId readable from config: $MACHINE_ID"

  assert_command_succeeds \
    "nix eval --raw '$REPO_ROOT#darwinConfigurations.$MACHINE_ID.system.system' --no-write-lock-file 2>/dev/null" \
    "darwinConfiguration for $MACHINE_ID evaluates"
else
  _test_log "fail" "Failed to read machineId from config/machine-config.nix"
fi

test_end
