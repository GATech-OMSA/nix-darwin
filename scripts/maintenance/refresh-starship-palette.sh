#!/usr/bin/env bash
#
# refresh-starship-palette.sh - Refresh the starship dark/light palette cache.
#
# Detects current macOS appearance and rewrites $HOME/.cache/starship/starship.toml
# from the source nix-store starship.toml with the appropriate Catppuccin palette
# substituted in. Records mtime in $HOME/.cache/starship/.palette.mtime.
#
# Called from a backgrounded subshell during zsh init (no wait, no SIGCHLD risk
# to the shell). Safe to run repeatedly; idempotent if appearance hasn't changed.

set -euo pipefail

CACHE_DIR="$HOME/.cache/starship"
PALETTE_FILE="$CACHE_DIR/.palette"
MTIME_FILE="$CACHE_DIR/.palette.mtime"
WRITABLE_TOML="$CACHE_DIR/starship.toml"

mkdir -p "$CACHE_DIR"

# Resolve source toml from the nix-managed symlink
NIX_TOML=$(/usr/bin/readlink -f "$HOME/.config/starship.toml" 2>/dev/null || true)
if [[ -z "$NIX_TOML" || "$NIX_TOML" != /nix/store/* ]]; then
  exit 0  # No nix-managed starship config — nothing to refresh
fi

# Detect dark/light. defaults can stall on macOS 15 cfprefsd contention,
# but here we're in a backgrounded process so it doesn't block the user's shell.
# Default to mocha if the read fails or returns nothing.
PALETTE="catppuccin_mocha"
if STYLE=$(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null) && [[ "$STYLE" == "Dark" ]]; then
  PALETTE="catppuccin_mocha"
elif [[ -z "${STYLE:-}" ]]; then
  # Empty result usually means light mode (defaults exits 1 when key absent)
  PALETTE="catppuccin_latte"
fi

# Atomic palette file write
printf '%s\n' "$PALETTE" > "$PALETTE_FILE.tmp"
/bin/mv "$PALETTE_FILE.tmp" "$PALETTE_FILE"

# Always touch the mtime marker so we don't refresh again for an hour even
# if the toml didn't change.
printf '%s\n' "$(date +%s)" > "$MTIME_FILE.tmp"
/bin/mv "$MTIME_FILE.tmp" "$MTIME_FILE"

# Only rewrite the toml if needed (palette differs OR source changed)
if [[ ! -f "$WRITABLE_TOML" ]] \
  || ! /usr/bin/diff -q "$NIX_TOML" "$WRITABLE_TOML" >/dev/null 2>&1 \
  || ! /usr/bin/grep -q "palette = '$PALETTE'" "$WRITABLE_TOML" 2>/dev/null; then
  /usr/bin/sed "s/^palette = .*/palette = '$PALETTE'/" "$NIX_TOML" > "$WRITABLE_TOML.tmp"
  /bin/mv "$WRITABLE_TOML.tmp" "$WRITABLE_TOML"
fi
