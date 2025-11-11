#!/usr/bin/env bash
#
# Test: Nix Syntax
# Validates all .nix files have correct syntax
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Nix Syntax Validation"

test_section "Find All Nix Files"

# Find all .nix files
nix_files=$(find "$REPO_ROOT" \
  -name "*.nix" \
  -not -path "*/\.git/*" \
  -not -path "*/result/*" \
  -not -path "*/\.direnv/*" \
  2>/dev/null)

file_count=$(echo "$nix_files" | wc -l | xargs)
test_info "Found $file_count .nix files to validate"

test_section "Syntax Validation"

failed_files=()

# Validate each file
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  relative_path="${file#$REPO_ROOT/}"

  # Use nix-instantiate to check syntax
  if nix-instantiate --parse "$file" &> /dev/null; then
    if [[ $TEST_VERBOSE -eq 1 ]]; then
      _test_log "pass" "Syntax valid: $relative_path"
    fi
  else
    _test_log "fail" "Syntax error: $relative_path" \
      "Run: nix-instantiate --parse $file"
    failed_files+=("$relative_path")
  fi
done <<< "$nix_files"

test_section "Summary"

# Overall syntax check
if [[ ${#failed_files[@]} -eq 0 ]]; then
  _test_log "pass" "All $file_count Nix files have valid syntax"
else
  _test_log "fail" "${#failed_files[@]} file(s) have syntax errors" \
    "Failed files: ${failed_files[*]}"
fi

test_section "Critical Files"

# Test critical files individually for detailed reporting
critical_files=(
  "$REPO_ROOT/flake.nix"
  "$REPO_ROOT/modules/darwin/default.nix"
  "$REPO_ROOT/modules/shared/packages.nix"
  "$REPO_ROOT/home/jimmy/default.nix"
)

for file in "${critical_files[@]}"; do
  if [[ -f "$file" ]]; then
    relative_path="${file#$REPO_ROOT/}"
    assert_command_succeeds \
      "nix-instantiate --parse '$file'" \
      "Critical file valid: $relative_path"
  fi
done

test_end
