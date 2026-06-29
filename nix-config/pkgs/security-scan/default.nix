# security-scan
#
# Hermetic wrapper around scripts/validation/scan-vulnerabilities.sh: a CVE scan
# of the live system closure (vulnix) plus Homebrew cask drift.
#
# Why package it: the tool carries its own closure (vulnix, jq, sed, awk, sort)
# via runtimeInputs instead of relying on whatever happens to be on PATH at the
# call site. `brew` is deliberately NOT bundled — it lives outside Nix and the
# script guards it with `command -v brew`.
#
# Note: this script is closure-only (it reads /run/current-system and an
# optional whitelist by absolute path), so it has no working-tree dependency and
# packages cleanly. Repo-rooted tools like deploy-secrets do NOT — see
# ../README.md for that caveat.

{ writeShellApplication
, vulnix
, jq
, gnused
, gawk
, coreutils
}:

writeShellApplication {
  name = "security-scan";

  runtimeInputs = [ vulnix jq gnused gawk coreutils ];

  # The script is already shellcheck-clean and `set -euo pipefail`-safe, so it
  # passes writeShellApplication's build-time shellcheck unchanged.
  text = builtins.readFile ../../../scripts/validation/scan-vulnerabilities.sh;
}
