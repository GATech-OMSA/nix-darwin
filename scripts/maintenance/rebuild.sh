#!/usr/bin/env bash
#
# Smart Rebuild Script for nix-darwin
#
# Wraps nh (Nix Helper) with:
# 1. Pre-flight health checks
# 2. Environment setup (FLAKE_ROOT, NH_DARWIN_FLAKE)
# 3. Proper error handling
# 4. Sudo management
# 5. Persisted activation logs (~/.local/state/nix-rebuild/<UTC>.log,
#    rotated to last 20). Opener: `nix-rebuild-log`.
#
# Usage:
#   rebuild.sh [options]
#
# Options:
#   --skip-checks    Skip pre-flight checks (emergency mode)
#   --debug          Enable verbose output and trace
#   --rollback       Rollback to previous generation
#   --legacy         Use darwin-rebuild instead of nh (fallback)

set -e

# ============================================
# CONFIGURATION
# ============================================
NIX_DARWIN_DIR="${HOME}/nix-darwin"
PRE_FLIGHT_SCRIPT="${NIX_DARWIN_DIR}/scripts/maintenance/pre-flight-checks.sh"
REPO_ROOT="$NIX_DARWIN_DIR"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner, get_machine_id
MACHINE_ID="$(get_machine_id)"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nix-rebuild"
LOG_FILE="$LOG_DIR/$(date -u +%Y%m%dT%H%M%SZ).log"
LOG_KEEP=20

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
# REBUILD BODY (runs inside the tee pipe)
# ============================================
# Defined as a function so the entire transcript (pre-flight, sudo prompts,
# nh output) lands in the log file. Returns the rc the wrapper should exit
# with on failure. Must NOT `exec zsh` — that would replace the process
# inside the pipe and leave tee hanging. The wrapper does `exec zsh` after
# the pipe drains.
_do_rebuild() {
  run_banner "nix-rebuild" "skip_checks=$SKIP_CHECKS debug=$DEBUG_MODE rollback=$ROLLBACK legacy=$USE_LEGACY" "${args[@]}"

  # PRE-FLIGHT
  if [[ "$ROLLBACK" == "false" ]] && [[ "$SKIP_CHECKS" == "false" ]]; then
    if [[ -f "$PRE_FLIGHT_SCRIPT" ]]; then
      echo "Running pre-flight checks..."
      set +e
      "$PRE_FLIGHT_SCRIPT"
      preflight_rc=$?
      set -e
      if [[ "$preflight_rc" -eq 2 ]]; then
        echo "warning: pre-flight checks reported warnings; continuing."
      elif [[ "$preflight_rc" -ne 0 ]]; then
        echo "error: pre-flight checks failed."
        echo "   Use --skip-checks to force rebuild (use with caution)."
        return 1
      fi
    else
      echo "warning: pre-flight script not found: $PRE_FLIGHT_SCRIPT"
    fi

    # Security pre-flight ("y"): scan the candidate closure before switching.
    # Same --skip-checks gate as above (nix-rebuild-skip-checks bypasses it);
    # also honors SKIP_SECURITY_PREFLIGHT=1. A non-zero return = user declined.
    SECURITY_PREFLIGHT="${NIX_DARWIN_DIR}/scripts/maintenance/security-preflight.sh"
    if [[ -x "$SECURITY_PREFLIGHT" ]]; then
      set +e
      FLAKE_ROOT="$NIX_DARWIN_DIR" MACHINE_ID="$MACHINE_ID" "$SECURITY_PREFLIGHT"
      sec_rc=$?
      set -e
      if [[ "$sec_rc" -ne 0 ]]; then
        echo "Rebuild aborted at security pre-flight (nothing switched)."
        return 1
      fi
    fi
  fi

  # EXECUTE
  echo "Starting system rebuild for machine: ${MACHINE_ID}..."

  if [[ "$ROLLBACK" == "true" ]]; then
    echo "Rolling back to previous generation..."
    if sudo darwin-rebuild --rollback; then
      echo "Rollback successful"
      return 0
    else
      echo "error: rollback failed"
      return 1
    fi
  fi

  if [[ "$USE_LEGACY" == "true" ]] || ! command -v nh &>/dev/null; then
    if [[ "$USE_LEGACY" == "true" ]]; then
      echo "Using legacy darwin-rebuild (--legacy flag)"
    else
      echo "warning: nh not found, falling back to darwin-rebuild"
    fi

    CMD="darwin-rebuild switch --flake ${NIX_DARWIN_DIR}#${MACHINE_ID}"
    [[ "$DEBUG_MODE" == "true" ]] && CMD="$CMD --show-trace --verbose --print-build-logs"
    [[ ${#args[@]} -gt 0 ]] && CMD="$CMD ${args[*]}"

    echo "Running: sudo $CMD"
    if sudo $CMD; then
      echo "Rebuild successful"
      return 0
    else
      echo "error: rebuild failed"
      return 1
    fi
  fi

  # nh path
  cd "$NIX_DARWIN_DIR" || return 1
  CMD="nh darwin switch -H ${MACHINE_ID} ."
  [[ "$DEBUG_MODE" == "true" ]] && CMD="$CMD --show-trace --print-build-logs --verbose"
  [[ ${#args[@]} -gt 0 ]] && CMD="$CMD -- ${args[*]}"

  echo "Running: $CMD"
  if $CMD; then
    echo "Rebuild successful"
    return 0
  else
    echo "error: rebuild failed"
    return 1
  fi
}

# ============================================
# LOG ROTATION — keep newest $LOG_KEEP
# ============================================
_prune_logs() {
  [[ -d "$LOG_DIR" ]] || return 0
  # ls -t prints newest-first; tail -n +$((LOG_KEEP+1)) drops the first
  # LOG_KEEP entries and lists everything older. xargs is BSD-compatible
  # (no -r); guard with [[ -n ]] for empty input instead.
  local victims
  victims=$(/bin/ls -t "$LOG_DIR"/*.log 2>/dev/null | /usr/bin/tail -n +"$((LOG_KEEP + 1))")
  [[ -n "$victims" ]] || return 0
  printf '%s\n' "$victims" | while IFS= read -r f; do
    [[ -n "$f" ]] && /bin/rm -f -- "$f"
  done
}

# ============================================
# WRAPPER — tee everything to LOG_FILE, then exec zsh on success
# ============================================
mkdir -p "$LOG_DIR"

# Run the body inside a `set +e` block so the rc propagates via PIPESTATUS
# instead of killing the script before we can read it.
set +e
_do_rebuild 2>&1 | /usr/bin/tee "$LOG_FILE"
RC=${PIPESTATUS[0]}
set -e

_prune_logs

if [[ "$RC" -eq 0 ]]; then
  echo "Restarting shell..."
  exec zsh
else
  echo "Log: $LOG_FILE"
  exit "$RC"
fi
