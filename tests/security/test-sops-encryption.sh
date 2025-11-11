#!/usr/bin/env bash
#
# Test: SOPS Encryption
# Validates secrets are properly encrypted
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "SOPS Encryption"

test_section "SOPS Installation"

# Test: SOPS command exists
assert_command_exists \
  "sops" \
  "SOPS command available"

# Test: Age key exists
assert_file_exists \
  "$HOME/.config/sops/age/keys.txt" \
  "SOPS age key exists"

# Test: Age key has secure permissions
assert_file_permissions \
  "$HOME/.config/sops/age/keys.txt" \
  "600" \
  "Age key has secure permissions (600)"

test_section "Secrets Files"

# Find all secrets.yaml files
secrets_files=$(find "$REPO_ROOT/hosts" -name "secrets.yaml" 2>/dev/null || true)

if [[ -z "$secrets_files" ]]; then
  test_skip "Secrets encryption test" "No secrets.yaml files found"
  test_end
fi

test_info "Found secrets files:"
echo "$secrets_files" | while read -r file; do
  test_info "  - ${file#$REPO_ROOT/}"
done

test_section "Encryption Validation"

# Test each secrets file
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  relative_path="${file#$REPO_ROOT/}"

  # Check if file is binary (encrypted)
  if file "$file" | grep -q "data"; then
    _test_log "pass" "Encrypted: $relative_path"

    # Additional validation: check for SOPS metadata
    if sops --decrypt "$file" &> /dev/null; then
      test_verbose "SOPS can decrypt: $relative_path"
    else
      _test_log "fail" "Cannot decrypt: $relative_path" \
        "SOPS decryption failed"
    fi
  else
    _test_log "fail" "Not encrypted: $relative_path" \
      "File is plaintext, should be encrypted"
  fi
done <<< "$secrets_files"

test_section "SOPS Configuration"

# Test: .sops.yaml exists
assert_file_exists \
  "$REPO_ROOT/.sops.yaml" \
  "SOPS configuration exists"

# Test: .sops.yaml is valid YAML
if [[ -f "$REPO_ROOT/.sops.yaml" ]]; then
  if command -v yq &> /dev/null; then
    assert_command_succeeds \
      "yq eval '.' '$REPO_ROOT/.sops.yaml' > /dev/null" \
      ".sops.yaml is valid YAML"
  else
    test_skip ".sops.yaml YAML validation" "yq not installed"
  fi
fi

# Test: .sops.yaml contains age configuration
assert_file_contains \
  "$REPO_ROOT/.sops.yaml" \
  "age" \
  ".sops.yaml contains age configuration"

test_section "Encryption Patterns"

# Test: No plaintext passwords in secrets files
plaintext_found=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # If file is plaintext and contains password patterns
  if ! file "$file" | grep -q "data"; then
    if grep -E "(password|secret|key):\s*[^{]" "$file" &> /dev/null; then
      ((plaintext_found++))
      _test_log "fail" "Plaintext secrets in: ${file#$REPO_ROOT/}" \
        "Encrypt with: sops -e -i $file"
    fi
  fi
done <<< "$secrets_files"

if [[ $plaintext_found -eq 0 ]]; then
  _test_log "pass" "No plaintext secrets detected"
fi

test_end
