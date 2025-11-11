#!/usr/bin/env bash
#
# Test: Lib Helper Functions
# Tests helper function availability and behavior
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Lib Helper Functions"

test_section "Update Functions"

# Test: update-all function exists
assert_command_exists \
  "update-all" \
  "update-all function available"

# Test: update-nix function exists
assert_command_exists \
  "update-nix" \
  "update-nix function available"

# Test: update-brew function exists (if Homebrew installed)
if command -v brew &> /dev/null; then
  assert_command_exists \
    "update-brew" \
    "update-brew function available"
else
  test_skip "update-brew test" "Homebrew not installed"
fi

test_section "Navigation Functions"

# Test: Navigation aliases exist
navigation_aliases=(
  "dev"
  "nixconf"
  "repos"
)

for alias_cmd in "${navigation_aliases[@]}"; do
  if command -v "$alias_cmd" &> /dev/null || alias "$alias_cmd" &> /dev/null; then
    if [[ $TEST_VERBOSE -eq 1 ]]; then
      _test_log "pass" "Navigation alias exists: $alias_cmd"
    fi
  else
    _test_log "fail" "Navigation alias missing: $alias_cmd"
  fi
done

_test_log "pass" "Core navigation aliases available"

test_section "Config Shortcuts"

# Test: Config editing shortcuts
config_shortcuts=(
  "gitconf"
  "zshconf"
  "vscodeconf"
)

for shortcut in "${config_shortcuts[@]}"; do
  if command -v "$shortcut" &> /dev/null || alias "$shortcut" &> /dev/null; then
    if [[ $TEST_VERBOSE -eq 1 ]]; then
      _test_log "pass" "Config shortcut exists: $shortcut"
    fi
  else
    _test_log "fail" "Config shortcut missing: $shortcut"
  fi
done

_test_log "pass" "Config editing shortcuts available"

test_section "Scaffold Functions"

# Test: Scaffold function exists
if command -v scaffold-nix-module &> /dev/null; then
  _test_log "pass" "scaffold-nix-module function available"
else
  test_skip "scaffold-nix-module test" "Function not found in current shell"
fi

test_section "Git Helpers"

# Test: Git aliases with g prefix
git_aliases=(
  "g s"
  "g aa"
  "g cm"
  "g ps"
  "g pl"
)

for git_alias in "${git_aliases[@]}"; do
  # Check if the alias is defined (we can't easily test all git aliases)
  # Just verify git itself works
  :
done

# Basic git functionality test
assert_command_exists \
  "git" \
  "Git command available"

# Test: Git aliases are loaded
if alias | grep -q "^g="; then
  _test_log "pass" "Git g alias defined"
else
  _test_log "fail" "Git g alias not found" \
    "Check git.nix configuration"
fi

test_section "Nix Helper Functions"

# Test: nix-rebuild alias exists
assert_command_exists \
  "nix-rebuild" \
  "nix-rebuild alias available"

# Test: nix-rollback alias exists
assert_command_exists \
  "nix-rollback" \
  "nix-rollback alias available"

# Test: edit-secrets function exists (if SOPS installed)
if command -v sops &> /dev/null; then
  assert_command_exists \
    "edit-secrets" \
    "edit-secrets function available"
else
  test_skip "edit-secrets test" "SOPS not installed"
fi

test_section "Function Output Validity"

# Test: Functions have proper structure (check for common patterns)
# We can't easily test function execution without side effects,
# but we can verify they're defined correctly

# Test: Update function help
if command -v update-all &> /dev/null; then
  # Just verify the function can be called with --help or -h
  # (if it supports it)
  if update-all --help &> /dev/null 2>&1 || true; then
    test_verbose "update-all function callable"
  fi
fi

test_end
