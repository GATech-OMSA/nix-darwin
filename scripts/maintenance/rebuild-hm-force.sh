#!/usr/bin/env bash
#
# rebuild-hm-force.sh - Force home-manager regeneration (cache-bug workaround)
#
# Builds the home-manager activation package directly and runs its activate
# script, bypassing the home-manager generation cache. Optionally follows with
# a full darwin-rebuild switch. Restarts the shell on success.
#
# Background: see claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md
#
# Usage:
#   rebuild-hm-force.sh                # home-manager activation only
#   rebuild-hm-force.sh --with-system  # home activation + darwin-rebuild switch
#
# Aliases:
#   nix-home-rebuild-force  -> rebuild-hm-force.sh
#   nix-rebuild-hm-force    -> rebuild-hm-force.sh --with-system

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================
NIX_DARWIN_DIR="${HOME}/nix-darwin"
REPO_ROOT="$NIX_DARWIN_DIR"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner, get_machine_id
MACHINE_ID="$(get_machine_id)"
if [[ -z "$MACHINE_ID" ]]; then
  echo "error: failed to read machineId from ${NIX_DARWIN_DIR}/config/machine-config.nix" >&2
  exit 1
fi
USERNAME=$(nix eval --raw --file "${NIX_DARWIN_DIR}/config/user-config.nix" username 2>/dev/null || echo "$USER")

WITH_SYSTEM=false
[[ "${1:-}" == "--with-system" ]] && WITH_SYSTEM=true

run_banner "rebuild-hm-force" "with_system=$WITH_SYSTEM" "$@"

# ============================================
# BUILD + ACTIVATE
# ============================================
cd "$NIX_DARWIN_DIR"

echo "→ Building home-manager activation package for ${USERNAME}@${MACHINE_ID}…"
result=$(nix build --print-out-paths \
  ".#darwinConfigurations.${MACHINE_ID}.config.home-manager.users.${USERNAME}.home.activationPackage")

echo "→ Activating home-manager generation…"
"$result/activate"

if [[ "$WITH_SYSTEM" == true ]]; then
  echo "→ Running full darwin-rebuild switch…"
  sudo darwin-rebuild switch --flake "${NIX_DARWIN_DIR}#${MACHINE_ID}"
fi

echo "Restarting shell..."
exec zsh
