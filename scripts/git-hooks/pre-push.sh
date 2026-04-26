#!/bin/bash
#
# pre-push.sh - Final security check before push
#
# Installed as .git/hooks/pre-push by Home Manager activation.
# Also usable standalone: ./scripts/git-hooks/pre-push.sh

echo "→ Final security check before push..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/nix-config/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data-*/secrets/*.yaml"
)

# Check SOPS-encrypted files
echo "  → Validating all SOPS-encrypted files..."
error_found=0

for pattern in "${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # Check for binary format (skip ASCII text check if binary)
    if ! file "$secrets_file" | grep -q "ASCII text"; then
      continue
    fi

    # Check for SOPS YAML format (has sops: metadata section)
    if grep -q "^sops:" "$secrets_file" && grep -q "mac:" "$secrets_file"; then
      continue
    fi

    # Check for SOPS encrypted values (ENC[AES256_GCM pattern)
    if grep -q "ENC\[AES256_GCM" "$secrets_file"; then
      continue
    fi

    # Not encrypted
    echo "✗ ERROR: Unencrypted secrets file detected: $secrets_file"
    echo "   Please encrypt with: sops -e -i $secrets_file"
    error_found=1
  done
done

# Final check: ensure no credential directories in git index
echo "  → Checking git index for credential files..."
if git ls-files | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "✗ ERROR: Credential files found in git index"
  echo "   These should never be committed. Remove with: git rm --cached <file>"
  error_found=1
fi

if [ $error_found -eq 1 ]; then
  echo ""
  echo "✗ Push blocked due to security issues. Please fix the above errors."
  exit 1
fi

echo "✓ All security checks passed - safe to push"
exit 0
