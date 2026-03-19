#!/usr/bin/env bash
#
# Smart Rebuild Script for nix-darwin
#
# Wraps nh (Nix Helper) with:
# 1. Pre-flight health checks
# 2. Environment setup (FLAKE_ROOT, NH_DARWIN_FLAKE)
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
#   --legacy         Use darwin-rebuild instead of nh (fallback)

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
USE_LEGACY=false

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
    --legacy)
      USE_LEGACY=true
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
    echo "Running pre-flight checks..."
    if ! "$PRE_FLIGHT_SCRIPT"; then
      echo "error: pre-flight checks failed."
      echo "   Use --skip-checks to force rebuild (use with caution)."
      exit 1
    fi
  else
    echo "warning: pre-flight script not found: $PRE_FLIGHT_SCRIPT"
  fi
fi

# ============================================
# EXECUTE REBUILD
# ============================================
echo "Starting system rebuild for machine: ${MACHINE_ID}..."

if [[ "$ROLLBACK" == "true" ]]; then
  echo "Rolling back to previous generation..."
  if sudo darwin-rebuild --rollback; then
    echo "Rollback successful"
    echo "Restarting shell..."
    exec zsh
  else
    echo "error: rollback failed"
    exit 1
  fi
fi

# Use nh by default, darwin-rebuild as fallback
if [[ "$USE_LEGACY" == "true" ]] || ! command -v nh &>/dev/null; then
  # Legacy mode: use darwin-rebuild directly
  if [[ "$USE_LEGACY" == "true" ]]; then
    echo "Using legacy darwin-rebuild (--legacy flag)"
  else
    echo "warning: nh not found, falling back to darwin-rebuild"
  fi

  # Export FLAKE_ROOT for gitignored config imports in flake.nix (legacy only)
  export FLAKE_ROOT="$NIX_DARWIN_DIR"

  CMD="darwin-rebuild switch --flake ${NIX_DARWIN_DIR}#${MACHINE_ID} --impure"

  if [[ "$DEBUG_MODE" == "true" ]]; then
    CMD="$CMD --show-trace --verbose --print-build-logs"
  fi

  if [[ ${#args[@]} -gt 0 ]]; then
    CMD="$CMD ${args[@]}"
  fi

  echo "Running: sudo $CMD"

  if sudo FLAKE_ROOT="$FLAKE_ROOT" $CMD; then
    echo "Rebuild successful"
    echo "Restarting shell..."
    exec zsh
  else
    echo "error: rebuild failed"
    exit 1
  fi
else
  # Modern mode: use nh (better output, package diff)
  # cd to flake directory (nh works better from within the flake dir)
  cd "$NIX_DARWIN_DIR" || exit 1
  CMD="nh darwin switch -H ${MACHINE_ID} . --impure"

  if [[ "$DEBUG_MODE" == "true" ]]; then
    CMD="$CMD --show-trace --print-build-logs --verbose"
  fi

  if [[ ${#args[@]} -gt 0 ]]; then
    CMD="$CMD -- ${args[@]}"
  fi

  echo "Running: $CMD"

  # nh resolves the flake from CWD (cd done above), so FLAKE_ROOT is not needed.
  # Setting FLAKE_ROOT with nh causes double-resolution and build failures.
  # In legacy mode, FLAKE_ROOT is explicitly exported for flake.nix's getEnv call.
  if $CMD; then
    echo "Rebuild successful"
    echo "Restarting shell..."
    exec zsh
  else
    echo "error: rebuild failed"
    exit 1
  fi
fi
