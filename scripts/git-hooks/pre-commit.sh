#!/bin/bash
#
# pre-commit.sh - Check for unencrypted secrets and credential protection
#
# Installed as .git/hooks/pre-commit by Home Manager activation.
# Also usable standalone: ./scripts/git-hooks/pre-commit.sh

echo "→ Validating secrets and credentials..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/nix-config/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data-*/secrets/*.yaml"
)

BLOCKED_PATTERNS=(
  "*_credentials.txt"
  "*_credentials.json"
  "*_credentials.yaml"
  "*_password.txt"
  "*_secrets.txt"
)

# Cache staged files list once (avoid repeated git calls)
STAGED_FILES=$(git diff --cached --name-only)

# Check if any credential files are staged
echo "  → Checking for blocked credential files..."
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$STAGED_FILES" | grep -q "$pattern"; then
    echo "✗ ERROR: Attempting to commit credential file matching pattern: $pattern"
    echo "   These files should never be committed. Add to .gitignore."
    exit 1
  fi
done

# Check if .db/, .tokens/, .credentials/ directories are staged
if echo "$STAGED_FILES" | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "✗ ERROR: Attempting to commit credential directory (.db/, .tokens/, or .credentials/)"
  echo "   These directories contain plaintext credentials and should never be committed."
  echo "   Fix: Ensure .gitignore contains these directories"
  exit 1
fi

# Check SOPS-encrypted files
echo "  → Validating SOPS encryption..."
for pattern in "${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # Check if staged for commit
    rel_path="${secrets_file#$HOME/nix-darwin/}"
    if echo "$STAGED_FILES" | grep -q "$rel_path"; then
      # Check for binary format
      if ! file "$secrets_file" | grep -q "ASCII text"; then
        echo "  ✓ Encrypted (binary): $rel_path"
        continue
      fi

      # Check for SOPS YAML format (has sops: metadata section)
      if grep -q "^sops:" "$secrets_file" && grep -q "mac:" "$secrets_file"; then
        echo "  ✓ Encrypted (YAML): $rel_path"
        continue
      fi

      # Check for SOPS encrypted values (ENC[AES256_GCM pattern)
      if grep -q "ENC\[AES256_GCM" "$secrets_file"; then
        echo "  ✓ Encrypted (YAML): $rel_path"
        continue
      fi

      # Not encrypted
      echo "✗ ERROR: Unencrypted secrets file detected: $secrets_file"
      echo "   Please encrypt with: sops -e -i $secrets_file"
      exit 1
    fi
  done
done

echo "✓ All security checks passed"

# ============================================================================
# DOC DRIFT — keep app-recommendations.md in sync with homebrew.nix
# ============================================================================
# Only runs when homebrew.nix is staged; otherwise skipped (zero overhead).
if echo "$STAGED_FILES" | grep -qE '^nix-config/modules/darwin/homebrew\.nix$'; then
  echo "→ Checking docs/app-recommendations.md is up to date..."
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
  SYNC="$REPO_ROOT/scripts/docs/sync-app-recommendations.sh"
  if [ -x "$SYNC" ]; then
    if ! "$SYNC" --check; then
      echo "✗ ERROR: docs/app-recommendations.md is stale relative to homebrew.nix" >&2
      echo "   Fix: just docs-apps && git add docs/app-recommendations.md" >&2
      exit 1
    fi
    echo "  ✓ app-recommendations.md is in sync"
  fi
fi

exit 0
