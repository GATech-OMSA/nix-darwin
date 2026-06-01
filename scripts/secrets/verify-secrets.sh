#!/usr/bin/env bash
#
# verify-secrets.sh - Verify deployed secrets are present and well-formed
#
# Read-only check called from Home Manager activation. Reads the manifest
# written by deploy-secrets.sh and confirms each target exists, has the
# expected mode, is non-empty, and does not contain the SOPS file header
# (the failure mode that wedged ~/.zsh_secrets on 2026-04-28).
#
# Does NOT decrypt anything, does NOT touch sops/yq/age. The whole point
# is to keep activation off the decryption path so a silent decrypt failure
# can never corrupt user state.
#
# Usage:
#   verify-secrets.sh           # Verify per the manifest
#   verify-secrets.sh --quiet   # Only print on failure (default in activation)

set -uo pipefail

QUIET=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --quiet|-q) QUIET=true ;;
    --help|-h)
      echo "Usage: verify-secrets.sh [--quiet]"
      echo ""
      echo "Verify deployed secrets match the manifest written by secrets-deploy."
      echo "Read-only — never decrypts, never writes."
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/secrets-deploy"
MANIFEST="$STATE_DIR/manifest"

# ANSI codes only when stdout is a TTY (activation captures output, no colors)
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

log() { [ "$QUIET" = true ] || echo "$*"; }
fail() { echo "${RED}verify-secrets: $*${NC}" >&2; }

if [[ ! -f "$MANIFEST" ]]; then
  fail "no secrets manifest at $MANIFEST"
  fail "run 'secrets-deploy' before 'darwin-rebuild' (first-boot bootstrap missed)"
  exit 1
fi

# stat -f works on BSD/macOS (different flags from GNU coreutils).
# Normalize to 4-digit octal so "0600" and "600" compare equal.
file_mode() {
  local m
  m=$(/usr/bin/stat -f '%Lp' "$1" 2>/dev/null) || return 1
  printf '%04o' "0$m"
}
file_size() { /usr/bin/stat -f '%z' "$1" 2>/dev/null; }
norm_mode() { printf '%04o' "0$1"; }

errors=0
checked=0
while IFS='|' read -r path expected_mode; do
  # Skip blank lines and comments
  case "$path" in ''|\#*) continue ;; esac

  checked=$((checked + 1))

  if [[ ! -e "$path" ]]; then
    fail "missing: $path"
    errors=$((errors + 1))
    continue
  fi

  actual_mode=$(file_mode "$path")
  expected_norm=$(norm_mode "$expected_mode")
  if [[ "$actual_mode" != "$expected_norm" ]]; then
    fail "$path: mode $actual_mode != expected $expected_norm"
    errors=$((errors + 1))
    continue
  fi

  size=$(file_size "$path")
  if [[ "${size:-0}" -eq 0 ]]; then
    fail "$path: empty file"
    errors=$((errors + 1))
    continue
  fi

  # Belt-and-suspenders: catches the 2026-04-28 corruption shape (the whole
  # decrypted document landing in a single secret file). Cheap to check.
  first_line=$(/usr/bin/head -n 1 "$path" 2>/dev/null || true)
  if [[ "$first_line" == "# Edit with: sops"* ]]; then
    fail "$path: contains SOPS file header — looks like the decrypted document was written here. Re-run 'secrets-deploy'."
    errors=$((errors + 1))
    continue
  fi
done < "$MANIFEST"

if [[ "$errors" -gt 0 ]]; then
  fail "$errors of $checked secret(s) failed verification"
  exit 1
fi

log "${GREEN}✓${NC} verify-secrets: ${checked} secret(s) ok"
exit 0
