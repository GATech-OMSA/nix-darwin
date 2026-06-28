#!/bin/bash
#
# pre-push.sh - Final security check before push
#
# Installed as .git/hooks/pre-push by Home Manager activation.
# Also usable standalone: ./scripts/git-hooks/pre-push.sh

echo "→ Final security check before push..."

# Resolve repo root: works both as the installed .git/hooks/pre-push copy and
# standalone scripts/git-hooks/pre-push.sh (both .../../ = repo root). Fail
# closed if the shared SOPS helper can't be loaded.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if ! source "$REPO_ROOT/scripts/git-hooks/lib-sops-check.sh" 2>/dev/null; then
  echo "✗ ERROR: could not load lib-sops-check.sh (expected at scripts/git-hooks/)" >&2
  exit 1
fi

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

    if is_sops_encrypted "$secrets_file"; then
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
