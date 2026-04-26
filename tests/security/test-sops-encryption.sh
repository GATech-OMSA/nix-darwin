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

# Find all secrets.yaml files (actual secrets live under nix-config/hosts)
secrets_files=$(/usr/bin/find "$REPO_ROOT/nix-config/hosts" -name "secrets.yaml" 2>/dev/null || true)

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

  # SOPS encrypts in two formats:
  # 1. Binary (completely encrypted, file reports "data")
  # 2. YAML with encrypted values (sops: metadata + mac: integrity marker)
  is_encrypted=false

  if ! file "$file" | grep -q "ASCII text"; then
    is_encrypted=true
    test_verbose "Binary encrypted: $relative_path"
  elif grep -q "^sops:" "$file" && grep -q "mac:" "$file"; then
    is_encrypted=true
    test_verbose "SOPS YAML encrypted: $relative_path"
  elif grep -q "ENC\[AES256_GCM" "$file"; then
    is_encrypted=true
    test_verbose "SOPS YAML encrypted (ENC markers): $relative_path"
  fi

  if [[ "$is_encrypted" == "true" ]]; then
    _test_log "pass" "Encrypted: $relative_path"

    if sops --decrypt "$file" &> /dev/null; then
      test_verbose "SOPS can decrypt: $relative_path"
    else
      _test_log "fail" "Cannot decrypt: $relative_path" \
        "SOPS decryption failed"
    fi
  else
    _test_log "fail" "Not encrypted: $relative_path" \
      "File is plaintext, should be encrypted with: sops -e -i $file"
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

  # If file is plaintext (ASCII text, no SOPS markers) and contains password patterns
  if file "$file" | grep -q "ASCII text" && ! grep -q "^sops:" "$file" && ! grep -q "ENC\[AES256_GCM" "$file"; then
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
