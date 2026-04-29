#!/usr/bin/env bash
#
# refresh-welcome.sh - Rebuild the welcome-message cache file.
#
# Args:
#   $1 = target cache file (e.g. ~/.cache/nix-darwin/welcome.home)
#   $2 = MACHINE_MODE (e.g. "home", "work", "minimal")
#
# Called from a backgrounded subshell during zsh init. The shell does not wait
# for it, so subprocess calls here cannot trigger the SIGCHLD race in zsh's
# waitforpid that wedged earlier in-init implementations of this cache.

set -euo pipefail

target="${1:?target file required}"
mode="${2:?MACHINE_MODE required}"

mkdir -p "$(dirname "$target")"

os_version=$(/usr/bin/sw_vers -productVersion 2>/dev/null || true)
# Determinate Nix lives at /nix/var/nix/profiles/default/bin/nix; fall back via PATH
nix_bin="/nix/var/nix/profiles/default/bin/nix"
[[ -x "$nix_bin" ]] || nix_bin=$(command -v nix 2>/dev/null || echo /usr/bin/false)
nix_version=$("$nix_bin" --version 2>/dev/null | /usr/bin/awk '{print $NF}' || true)

tmp="$target.tmp.$$"
printf '\033[90m %s · macOS %s · nix %s\033[0m\n' "$mode" "$os_version" "$nix_version" > "$tmp"
/bin/mv "$tmp" "$target"
