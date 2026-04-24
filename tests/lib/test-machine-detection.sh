#!/usr/bin/env bash
#
# Test: Machine Detection
# Tests machine type detection logic
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Machine Detection"

test_section "Hostname Detection"

# Test: Can detect hostname
current_hostname=$(hostname -s)
assert_command_succeeds \
  "hostname -s" \
  "Hostname detection works: $current_hostname"

# Test: Hostname is recognized
if [[ "$current_hostname" == "mbp-jimmy" ]] || [[ "$current_hostname" == "mbp-work" ]]; then
  _test_log "pass" "Hostname is a known configuration: $current_hostname"
else
  _test_log "fail" "Hostname is unknown: $current_hostname" \
    "Expected: mbp-jimmy or mbp-work"
fi

test_section "Machine Mode Detection"

# Test: MACHINE_MODE environment variable
if [[ -n "${MACHINE_MODE:-}" ]]; then
  _test_log "pass" "MACHINE_MODE is set: $MACHINE_MODE"

  # Validate it's a known mode
  if [[ "$MACHINE_MODE" == "home" ]] || [[ "$MACHINE_MODE" == "work" ]]; then
    _test_log "pass" "MACHINE_MODE is valid: $MACHINE_MODE"
  else
    _test_log "fail" "MACHINE_MODE is invalid: $MACHINE_MODE" \
      "Expected: home or work"
  fi
else
  _test_log "fail" "MACHINE_MODE not set" \
    "Should be set in shell configuration"
fi

test_section "Configuration Consistency"

# Test: Hostname and MACHINE_MODE alignment
if [[ "$current_hostname" == "mbp-jimmy" ]]; then
  if [[ "${MACHINE_MODE:-}" == "home" ]]; then
    _test_log "pass" "Personal Mac: hostname and mode aligned"
  else
    _test_log "fail" "Personal Mac mode mismatch" \
      "Hostname: $current_hostname, Mode: ${MACHINE_MODE:-unset}"
  fi
elif [[ "$current_hostname" == "mbp-work" ]]; then
  if [[ "${MACHINE_MODE:-}" == "work" ]]; then
    _test_log "pass" "Work Mac: hostname and mode aligned"
  else
    _test_log "fail" "Work Mac mode mismatch" \
      "Hostname: $current_hostname, Mode: ${MACHINE_MODE:-unset}"
  fi
fi

test_section "Nix Evaluation"

# Flake outputs are keyed on machineId (from config/machine-config.nix), not hostname
machine_id=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" machineId 2>/dev/null || echo "")

if [[ -n "$machine_id" ]]; then
  assert_command_succeeds \
    "nix eval --raw '$REPO_ROOT#darwinConfigurations.$machine_id.system' 2>/dev/null" \
    "Nix can evaluate current machine configuration ($machine_id)"
else
  test_skip "Nix evaluation" "Could not read machineId from config"
fi

assert_directory_exists \
  "$REPO_ROOT/nix-config/lib" \
  "nix-config/lib/ directory exists"

assert_file_exists \
  "$REPO_ROOT/nix-config/lib/default.nix" \
  "nix-config/lib/default.nix exists"

test_section "Helper Functions Exist"

# Test: Key lib files exist
lib_files=(
  "$REPO_ROOT/nix-config/lib/aws-helpers.nix"
  "$REPO_ROOT/nix-config/lib/reload-helpers.nix"
)

for lib_file in "${lib_files[@]}"; do
  if [[ -f "$lib_file" ]]; then
    filename=$(basename "$lib_file")
    assert_command_succeeds \
      "nix-instantiate --parse '$lib_file'" \
      "nix-config/lib/$filename has valid syntax"
  fi
done

test_end
