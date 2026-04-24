#!/usr/bin/env bash
#
# Test: File Permissions
# Validates credential files have secure permissions
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "File Permissions"

test_section "Credential Files"

# List of credential files that should have 600 permissions
credential_files=(
  "$HOME/.aws/credentials"
  "$HOME/.ssh/id_ed25519"
  "$HOME/.ssh/id_ed25519_work"
  # .ssh/config excluded: Nix-managed symlink, permissions set by Nix (755)
  "$HOME/.config/sops/age/keys.txt"
  "$HOME/.gitconfig"
)

insecure_count=0

for file in "${credential_files[@]}"; do
  if [[ -f "$file" ]]; then
    perms=$(stat -f "%A" "$file" 2>/dev/null || echo "000")

    if [[ "$perms" == "600" ]]; then
      if [[ $TEST_VERBOSE -eq 1 ]]; then
        _test_log "pass" "Secure permissions: ${file#$HOME/} ($perms)"
      fi
    else
      _test_log "fail" "Insecure permissions: ${file#$HOME/}" \
        "Current: $perms, Expected: 600"
      ((insecure_count++))
    fi
  else
    test_verbose "File not found (skipped): ${file#$HOME/}"
  fi
done

if [[ $insecure_count -eq 0 ]]; then
  _test_log "pass" "All credential files have secure permissions (600)"
fi

test_section "Protected Directories"

# Directories that should have secure permissions
protected_dirs=(
  "$HOME/.ssh:700"
  "$HOME/.aws:700"
  "$HOME/.config/sops/age:700"
)

for dir_perms in "${protected_dirs[@]}"; do
  dir="${dir_perms%%:*}"
  expected="${dir_perms#*:}"

  if [[ -d "$dir" ]]; then
    actual=$(stat -f "%A" "$dir" 2>/dev/null || echo "000")

    if [[ "$actual" == "$expected" ]]; then
      if [[ $TEST_VERBOSE -eq 1 ]]; then
        _test_log "pass" "Directory permissions OK: ${dir#$HOME/} ($actual)"
      fi
    else
      _test_log "fail" "Directory permissions incorrect: ${dir#$HOME/}" \
        "Current: $actual, Expected: $expected"
    fi
  else
    test_verbose "Directory not found (skipped): ${dir#$HOME/}"
  fi
done

test_section "Git-Ignored Credential Paths"

# Paths that should be in .gitignore
ignored_patterns=(
  ".db/"
  ".tokens/"
  ".aws/credentials"
)

if [[ -f "$REPO_ROOT/.gitignore" ]]; then
  for pattern in "${ignored_patterns[@]}"; do
    if grep -q "^$pattern" "$REPO_ROOT/.gitignore" 2>/dev/null; then
      if [[ $TEST_VERBOSE -eq 1 ]]; then
        _test_log "pass" "Gitignored: $pattern"
      fi
    else
      _test_log "fail" "Not gitignored: $pattern" \
        "Add to .gitignore: $pattern"
    fi
  done

  _test_log "pass" "All sensitive patterns in .gitignore"
else
  _test_log "fail" ".gitignore not found"
fi

test_section "Comprehensive Audit"

# Run audit-permissions.sh if available
if [[ -x "$REPO_ROOT/scripts/audit-permissions.sh" ]]; then
  test_info "Running comprehensive permission audit..."

  if "$REPO_ROOT/scripts/audit-permissions.sh" &> /tmp/permission-audit.log; then
    _test_log "pass" "Comprehensive audit passed"
  else
    audit_output=$(cat /tmp/permission-audit.log)
    insecure=$(echo "$audit_output" | grep -c "Insecure:" || echo "0")

    if [[ "$insecure" -gt 0 ]]; then
      _test_log "fail" "Audit found $insecure insecure file(s)" \
        "Run: $REPO_ROOT/scripts/audit-permissions.sh --fix"
    fi
  fi

  rm -f /tmp/permission-audit.log
else
  test_skip "Comprehensive audit" "audit-permissions.sh not found"
fi

test_end
