#!/bin/bash
#
# pre-commit.sh - Check for unencrypted secrets and credential protection
#
# Installed as .git/hooks/pre-commit by Home Manager activation.
# Also usable standalone: ./scripts/git-hooks/pre-commit.sh

echo "→ Validating secrets and credentials..."

# Resolve repo root: works both as the installed .git/hooks/pre-commit copy
# (.git/hooks/../.. = repo root) and standalone scripts/git-hooks/pre-commit.sh
# (scripts/git-hooks/../.. = repo root). Fail closed if the shared SOPS helper
# can't be loaded — a security hook that can't check must not pass silently.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
source "${REPO_ROOT}/scripts/lib/machine-id.sh"  # get_machine_id
if ! source "$REPO_ROOT/scripts/git-hooks/lib-sops-check.sh" 2>/dev/null; then
  echo "✗ ERROR: could not load lib-sops-check.sh (expected at scripts/git-hooks/)" >&2
  exit 1
fi

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
      if is_sops_encrypted "$secrets_file"; then
        echo "  ✓ Encrypted: $rel_path"
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
# NIX FLAKE INTEGRITY — gated on staged .nix or flake.lock changes
# ============================================================================
# Two checks, both required for catching real breakage:
#
# 1) `nix flake check --no-build` — fast (~100 ms warm) structural check.
#    Validates flake outputs that nix knows about (lib, etc.) and inputs.
#    Does NOT deep-eval `darwinConfigurations` because nix-darwin uses a
#    non-standard output category — empirically, syntax errors in any
#    imported darwin module pass this check with exit 0.
#
# 2) `nix eval --raw .#darwinConfigurations.<id>.system.drvPath` — forces
#    full evaluation of the entire darwin module tree. Catches syntax
#    errors, type errors, missing imports, etc. ~3.4 s warm, ~5.5 s cold.
#
# Combined cost ~3.5 s warm, gated on .nix/flake.lock staged — most
# commits pay zero overhead.
if echo "$STAGED_FILES" | grep -qE '(\.nix$|^flake\.lock$)'; then
  echo "→ Validating nix flake..."
  if [ -f "$REPO_ROOT/flake.nix" ] && command -v nix >/dev/null 2>&1; then
    nix_err=/tmp/.nix-precommit-err.$$
    trap 'rm -f "$nix_err"' EXIT

    # Cheap structural check first.
    if ! nix flake check --no-build > "$nix_err" 2>&1; then
      echo "✗ ERROR: nix flake check --no-build failed" >&2
      grep -v '^warning: ' "$nix_err" >&2 || true
      exit 1
    fi

    # Force-eval the active darwinConfiguration so module-tree errors fail here.
    machine_id="$(get_machine_id)"
    if [ -z "$machine_id" ]; then
      echo "  ▸ skipping deep eval: could not determine machineId" >&2
    else
      eval_attr=".#darwinConfigurations.${machine_id}.system.drvPath"
      if ! nix eval --raw "$eval_attr" > /dev/null 2> "$nix_err"; then
        echo "✗ ERROR: nix evaluation failed for $eval_attr" >&2
        echo "" >&2
        cat "$nix_err" >&2
        echo "" >&2
        echo "   Fix the syntax/eval error above before committing." >&2
        exit 1
      fi
    fi
    echo "  ✓ flake evaluates cleanly"
  fi
fi

# ============================================================================
# DOC DRIFT — keep app-recommendations.md in sync with homebrew.nix
# ============================================================================
# Only runs when homebrew.nix is staged; otherwise skipped (zero overhead).
if echo "$STAGED_FILES" | grep -qE '^nix-config/modules/darwin/homebrew\.nix$'; then
  echo "→ Checking docs/app-recommendations.md is up to date..."
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
