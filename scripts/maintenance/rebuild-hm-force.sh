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
MACHINE_ID=$(nix eval --raw --file "${NIX_DARWIN_DIR}/config/machine-config.nix" machineId)
USERNAME=$(nix eval --raw --file "${NIX_DARWIN_DIR}/config/user-config.nix" username 2>/dev/null || echo "$USER")

WITH_SYSTEM=false
[[ "${1:-}" == "--with-system" ]] && WITH_SYSTEM=true

# ============================================
# BUILD + ACTIVATE
# ============================================
cd "$NIX_DARWIN_DIR"

echo "→ Building home-manager activation package for ${USERNAME}@${MACHINE_ID}…"
result=$(nix build --impure --print-out-paths \
  ".#darwinConfigurations.${MACHINE_ID}.config.home-manager.users.${USERNAME}.home.activationPackage")

echo "→ Activating home-manager generation…"
"$result/activate"

if [[ "$WITH_SYSTEM" == true ]]; then
  echo "→ Running full darwin-rebuild switch…"
  sudo FLAKE_ROOT="$NIX_DARWIN_DIR" darwin-rebuild switch --flake "${NIX_DARWIN_DIR}#${MACHINE_ID}" --impure
fi

echo "Restarting shell..."
exec zsh
