#!/usr/bin/env bash
#
# lib-sops-check.sh - Shared SOPS-encryption detection for git hooks
#
# Sourced by pre-commit.sh and pre-push.sh. Security-critical logic kept in
# one place so the two hooks can never drift on what counts as "encrypted".
# (The per-script color/output helpers stay duplicated by convention; this is
# not cosmetic boilerplate.)
#
# Usage:
#   source "$REPO_ROOT/scripts/git-hooks/lib-sops-check.sh"
#   if is_sops_encrypted "$file"; then ... ; fi

# Return 0 if $1 is a SOPS-encrypted secrets file, 1 otherwise.
# A file counts as encrypted if ANY of:
#   - it is binary (not ASCII text)         — encrypted blob
#   - it has a `sops:`/`mac:` metadata block — encrypted YAML
#   - it contains an ENC[AES256_GCM value    — encrypted YAML values
is_sops_encrypted() {
  local file="$1"

  # Binary format → encrypted blob
  if ! file "$file" | grep -q "ASCII text"; then
    return 0
  fi

  # SOPS YAML metadata section
  if grep -q "^sops:" "$file" && grep -q "mac:" "$file"; then
    return 0
  fi

  # SOPS-encrypted values
  if grep -q "ENC\[AES256_GCM" "$file"; then
    return 0
  fi

  return 1
}
