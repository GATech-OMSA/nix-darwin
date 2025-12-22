#!/usr/bin/env bash
#
# Smart Rebuild Script for nix-darwin
#
# Wraps darwin-rebuild with:
# 1. Pre-flight health checks
# 2. Environment setup (FLAKE_ROOT)
# 3. Proper error handling
# 4. Sudo management
#
# Usage:
#   rebuild.sh [options]
#
# Options:
#   --skip-checks    Skip pre-flight checks (emergency mode)
#   --debug          Enable verbose output and trace
#   --impure         Allow impure expressions (default: true)
#   --rollback       Rollback to previous generation

set -e

# ============================================
# CONFIGURATION
# ============================================
NIX_DARWIN_DIR="${HOME}/nix-darwin"
PRE_FLIGHT_SCRIPT="${NIX_DARWIN_DIR}/scripts/maintenance/pre-flight-checks.sh"
MACHINE_ID=$(nix eval --raw --file "${NIX_DARWIN_DIR}/config/machine-config.nix" machineId 2>/dev/null || echo "default")

# ============================================
# PARSE ARGUMENTS
# ============================================
SKIP_CHECKS=false
DEBUG_MODE=false
ROLLBACK=false

args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-checks)
      SKIP_CHECKS=true
      shift
      ;;
    --debug)
      DEBUG_MODE=true
      shift
      ;;
    --rollback)
      ROLLBACK=true
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

# ============================================
# PRE-FLIGHT CHECKS
# ============================================
if [[ "$ROLLBACK" == "false" ]] && [[ "$SKIP_CHECKS" == "false" ]]; then
  if [[ -f "$PRE_FLIGHT_SCRIPT" ]]; then
    echo "🔍 Running pre-flight checks..."
    if ! "$PRE_FLIGHT_SCRIPT"; then
      echo "❌ Pre-flight checks failed."
      echo "💡 Use --skip-checks to force rebuild (use with caution)."
      exit 1
    fi
  else
    echo "⚠️  Pre-flight script not found: $PRE_FLIGHT_SCRIPT"
  fi
fi

# ============================================
# EXECUTE REBUILD
# ============================================
echo "🚀 Starting system rebuild for machine: ${MACHINE_ID}..."

# Export FLAKE_ROOT for gitignored config imports in flake.nix
export FLAKE_ROOT="$NIX_DARWIN_DIR"

if [[ "$ROLLBACK" == "true" ]]; then
  echo "🔙 Rolling back to previous generation..."
  if sudo darwin-rebuild --rollback; then
    echo "✅ Rollback successful"
    echo "🔄 Restarting shell..."
    exec zsh
  else
    echo "❌ Rollback failed"
    exit 1
  fi
fi

# Construct build command
CMD="darwin-rebuild switch --flake ${NIX_DARWIN_DIR}#${MACHINE_ID} --impure"

if [[ "$DEBUG_MODE" == "true" ]]; then
  CMD="$CMD --show-trace --verbose --print-build-logs"
fi

# Add any passed arguments
if [[ ${#args[@]} -gt 0 ]]; then
  CMD="$CMD ${args[@]}"
fi

echo "Running: sudo $CMD"

# Execute with sudo
if sudo FLAKE_ROOT="$FLAKE_ROOT" $CMD; then
  echo "✅ Rebuild successful"
  
  # Restart shell to apply changes
  echo "🔄 Restarting shell..."
  exec zsh
else
  echo "❌ Rebuild failed"
  # Do NOT restart shell on failure, so user can see errors
  exit 1
fi
