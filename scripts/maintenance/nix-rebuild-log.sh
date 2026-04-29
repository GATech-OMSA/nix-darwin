#!/usr/bin/env bash
#
# nix-rebuild-log.sh - Open the most recent nix-rebuild log in $PAGER.
#
# Logs are written by scripts/maintenance/rebuild.sh into
# ${XDG_STATE_HOME:-~/.local/state}/nix-rebuild/, named
# YYYYMMDDTHHMMSSZ.log (UTC). The wrapper keeps the newest 20.
#
# Usage:
#   nix-rebuild-log              # open the latest log
#   nix-rebuild-log --list       # list all logs (newest first)
#   nix-rebuild-log <N>          # open the Nth-newest log (1 = latest)

set -euo pipefail

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix-rebuild"

if [[ ! -d "$LOG_DIR" ]]; then
  echo "No log directory yet: $LOG_DIR" >&2
  echo "Run \`nix-rebuild\` once to create one." >&2
  exit 1
fi

case "${1:-}" in
  --list|-l)
    /bin/ls -lt "$LOG_DIR"/*.log 2>/dev/null \
      | /usr/bin/awk '{ printf "%-20s %s %s %s  %s\n", $9, $6, $7, $8, $5 }' \
      || { echo "No logs in $LOG_DIR" >&2; exit 1; }
    exit 0
    ;;
  --help|-h)
    /usr/bin/sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
    exit 0
    ;;
  '')
    n=1
    ;;
  *)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      n="$1"
    else
      echo "Unknown option: $1" >&2
      exit 1
    fi
    ;;
esac

# nth-newest log
target=$(/bin/ls -t "$LOG_DIR"/*.log 2>/dev/null | /usr/bin/sed -n "${n}p")
if [[ -z "${target:-}" ]]; then
  echo "No log #$n in $LOG_DIR" >&2
  exit 1
fi

# Default to less, fall back to more, then cat. Pass -R so ANSI colors render.
PAGER_BIN="${PAGER:-less}"
case "$PAGER_BIN" in
  less|*/less) exec "$PAGER_BIN" -R "$target" ;;
  *)           exec "$PAGER_BIN" "$target" ;;
esac
