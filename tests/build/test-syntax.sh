#!/usr/bin/env bash
#
# Test: Nix Syntax
# Validates all .nix files parse without errors

source "$(dirname "$0")/../test-framework.sh"

test_begin "Nix Syntax Validation"

test_section "Nix File Parsing"

errors=0
total=0

while IFS= read -r nix_file; do
  [[ -z "$nix_file" ]] && continue
  ((total++))
  relative="${nix_file#$REPO_ROOT/}"

  if nix-instantiate --parse "$nix_file" > /dev/null 2>&1; then
    if [[ "${TEST_VERBOSE:-0}" -eq 1 ]]; then
      _test_log "pass" "Parses: $relative"
    fi
  else
    _test_log "fail" "Syntax error: $relative" \
      "$(nix-instantiate --parse "$nix_file" 2>&1 | head -3)"
    ((errors++))
  fi
done < <(/usr/bin/find "$REPO_ROOT/nix-config" -name "*.nix" -type f -not -path "*/hosts/_template/*" 2>/dev/null)

# Also check top-level flake.nix
if nix-instantiate --parse "$REPO_ROOT/flake.nix" > /dev/null 2>&1; then
  ((total++))
else
  _test_log "fail" "Syntax error: flake.nix"
  ((errors++))
  ((total++))
fi

if [[ $errors -eq 0 ]]; then
  _test_log "pass" "All $total .nix files parse successfully"
else
  _test_log "fail" "$errors of $total .nix files have syntax errors"
fi

test_end
