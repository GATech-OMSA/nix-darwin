#!/usr/bin/env bash
#
# Test: Rollback Functionality
# Tests system rollback capability (validation only)
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Rollback Functionality"

test_section "Rollback Command"

# Test: nix-rollback alias exists
assert_command_exists \
  "nix-rollback" \
  "nix-rollback alias available"

# Test: darwin-rebuild rollback works
assert_command_exists \
  "darwin-rebuild" \
  "darwin-rebuild command available for rollback"

test_section "System Generations"

# Test: Generations directory exists
assert_directory_exists \
  "/nix/var/nix/profiles" \
  "Nix profiles directory exists"

# Test: System profile link exists
assert_symlink_exists \
  "/run/current-system" \
  "Current system link exists"

# Test: Previous generations exist
gen_count=$(ls -1 /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l | xargs)

if [[ $gen_count -gt 1 ]]; then
  _test_log "pass" "Multiple generations available: $gen_count"
  test_verbose "Rollback possible to previous generation"
elif [[ $gen_count -eq 1 ]]; then
  _test_log "fail" "Only one generation exists" \
    "No previous generation to roll back to"
else
  _test_log "fail" "No system generations found"
fi

test_section "Generation Metadata"

# Test: Can list generations
if darwin-rebuild --list-generations 2>&1 | grep -q "Generation"; then
  _test_log "pass" "Can list system generations"

  if [[ $TEST_VERBOSE -eq 1 ]]; then
    test_info "Recent generations:"
    darwin-rebuild --list-generations 2>/dev/null | tail -5 | sed 's/^/    /'
  fi
else
  _test_log "fail" "Cannot list system generations"
fi

test_section "Rollback Safety"

# Test: Can dry-run rollback
if darwin-rebuild --rollback --dry-run 2>&1 | grep -q "would"; then
  _test_log "pass" "Rollback dry-run works"
else
  test_skip "Rollback dry-run" "No previous generation or dry-run not supported"
fi

# We don't actually perform rollback in tests
test_skip "Actual rollback execution" "Not performed in test suite (would change system state)"

test_section "Home Manager Generations"

# Test: Home Manager generations exist
if [[ -d "$HOME/.local/state/nix/profiles" ]] || [[ -d "$HOME/.local/state/home-manager/gcroots" ]]; then
  _test_log "pass" "Home Manager generations directory exists"

  # Count generations
  hm_gen_count=$(ls -1 "$HOME/.local/state/nix/profiles/home-manager-"* 2>/dev/null | wc -l | xargs || echo "0")

  if [[ $hm_gen_count -gt 1 ]]; then
    _test_log "pass" "Multiple Home Manager generations: $hm_gen_count"
  elif [[ $hm_gen_count -eq 1 ]]; then
    _test_log "fail" "Only one Home Manager generation"
  fi
else
  _test_log "fail" "Home Manager generations directory not found"
fi

test_section "Garbage Collection Safety"

# Test: Generations protected from GC
if [[ -L /nix/var/nix/profiles/system ]]; then
  _test_log "pass" "System profile protects generations from GC"
else
  _test_log "fail" "System profile link missing"
fi

# Test: Can query what would be collected
if nix-collect-garbage --dry-run 2>&1 | grep -q "would delete"; then
  _test_log "pass" "Can preview garbage collection impact"
else
  test_skip "GC preview" "No garbage to collect or dry-run not supported"
fi

test_end
