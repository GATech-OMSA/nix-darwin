#!/usr/bin/env bash
#
# Test: Lib Helper Functions
# Tests helper function availability and behavior
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Lib Helper Functions"

test_section "Shell Function Definitions"

# Most helper functions (update-all, nix-rebuild, navigation aliases, git aliases,
# config shortcuts) are zsh aliases/functions defined via Home Manager.
# They are NOT available in non-interactive bash test scripts.
# Instead, verify the Nix source files that define them exist.

assert_file_exists \
  "$REPO_ROOT/nix-config/home/_profiles/_template/shell/zsh.nix" \
  "Shell config source exists (defines aliases)"

assert_file_exists \
  "$REPO_ROOT/nix-config/home/_profiles/_template/programs/git.nix" \
  "Git config source exists (defines git aliases)"

test_section "Shell Function Source Files"

function_files=(
  "$REPO_ROOT/nix-config/home/_profiles/_template/shell/functions/core.zsh"
  "$REPO_ROOT/nix-config/home/_profiles/_template/shell/functions/update.zsh"
  "$REPO_ROOT/nix-config/home/_profiles/_template/shell/functions/cleanup.zsh"
)

for func_file in "${function_files[@]}"; do
  if [[ -f "$func_file" ]]; then
    filename=$(basename "$func_file")
    _test_log "pass" "Function source exists: $filename"
  else
    filename=$(basename "$func_file")
    _test_log "fail" "Function source missing: $filename"
  fi
done

test_section "Core Commands"

assert_command_exists \
  "git" \
  "Git command available"

assert_command_exists \
  "nix" \
  "Nix command available"

assert_command_exists \
  "darwin-rebuild" \
  "darwin-rebuild command available"

test_end
