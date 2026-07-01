#!/usr/bin/env bash
#
# Test: Darwin Build (Dry Run)
# Validates the active machine configuration can be built

source "$(dirname "$0")/../test-framework.sh"

test_begin "Darwin Build (Dry Run)"

test_section "Machine Configuration"

MACHINE_ID=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" machineId 2>/dev/null || echo "")

if [[ -z "$MACHINE_ID" ]]; then
  _test_log "fail" "Cannot read machineId from config/machine-config.nix"
  test_end
fi

_test_log "pass" "Active machine: $MACHINE_ID"

test_section "Host Directory"

assert_directory_exists \
  "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" \
  "Host directory exists for $MACHINE_ID"

assert_file_exists \
  "$REPO_ROOT/nix-config/hosts/$MACHINE_ID/default.nix" \
  "Host default.nix exists"

test_section "Dry-Run Build"

if [[ "${TEST_DRY_RUN:-0}" -eq 1 ]]; then
  test_skip "Darwin build dry-run" "Skipped in dry-run mode"
else
  if nix build "$REPO_ROOT#darwinConfigurations.$MACHINE_ID.system" --dry-run --no-write-lock-file 2>&1; then
    _test_log "pass" "Dry-run build succeeds for $MACHINE_ID"
  else
    _test_log "fail" "Dry-run build failed for $MACHINE_ID"
  fi
fi

test_end
