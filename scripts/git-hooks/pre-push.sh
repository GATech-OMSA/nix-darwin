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

# ============================================================================
# SHELL STARTUP-PERF GATE — only when shell-init files changed in this push
# ============================================================================
# The bench is TTY-bound and takes ~15-20s, so it must not run on every push.
# Gate it on a diff touching the shell init surface; skip when there's no TTY
# (scripted pushes), or when SKIP_PERF_GATE=1. Warn-only unless
# SHELL_PERF_ENFORCE=1 — startup latency is environmental, so blocking by
# default would be too noisy.
if [ "${SKIP_PERF_GATE:-0}" != "1" ] && [ -t 1 ]; then
  # Range being pushed: prefer the upstream delta, fall back to the last commit.
  perf_range="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"
  if [ -n "$perf_range" ]; then
    changed="$(git diff --name-only "$perf_range"..HEAD 2>/dev/null)"
  else
    changed="$(git diff --name-only HEAD~1..HEAD 2>/dev/null)"
  fi

  if echo "$changed" | grep -qE 'nix-config/home/_profiles/_template/shell/'; then
    echo ""
    echo "→ Shell init changed — checking startup-perf budget..."
    PERF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/maintenance/check-shell-perf.sh"
    if [ -x "$PERF" ]; then
      # Honors SHELL_PERF_ENFORCE; non-zero exit (enforce + regression) blocks the push.
      "$PERF" || exit 1
    fi
  fi
fi

exit 0
