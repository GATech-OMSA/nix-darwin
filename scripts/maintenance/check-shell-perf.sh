#!/usr/bin/env bash
#
# check-shell-perf.sh - Startup-latency regression gate for the interactive shell
#
# Wraps bench-shell.sh, compares the measured warm p50 / cold p95 against a
# committed budget, and fails when startup latency regresses past it. The heavy
# SIGCHLD/startup-perf work in zsh.nix is easy to silently undo; this gate makes
# a regression loud.
#
# The budget lives in scripts/maintenance/shell-perf-budget.env and is meant to
# be calibrated on the target machine (GitHub shared runners are too noisy for
# absolute-ms gating, so this is a local / pre-push tool, not a CI one).
#
# Usage:
#   check-shell-perf.sh                 # measure + compare to budget (warn-only)
#   check-shell-perf.sh --enforce       # non-zero exit on regression (gate mode)
#   check-shell-perf.sh --calibrate     # set budget from a fresh measurement
#   check-shell-perf.sh --runs 20       # more samples = steadier percentiles
#   check-shell-perf.sh --json          # machine-readable result
#
# Env:
#   SHELL_PERF_ENFORCE=1   same as --enforce (for hook wiring)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH="$SCRIPT_DIR/bench-shell.sh"
BUDGET_FILE="$SCRIPT_DIR/shell-perf-budget.env"

RUNS=12
ENFORCE="${SHELL_PERF_ENFORCE:-0}"
CALIBRATE=false
JSON=false
# Calibration headroom: budget = measured * (1 + MARGIN), rounded up. 25% absorbs
# normal run-to-run jitter without letting a real regression slip through.
MARGIN_PCT=25

# ============================================================================
# COLOR / OUTPUT
# ============================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[i]${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}▸${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --enforce)   ENFORCE=1; shift ;;
    --calibrate) CALIBRATE=true; shift ;;
    --runs|-n)   RUNS="$2"; shift 2 ;;
    --json|-j)   JSON=true; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) error "Unknown option: $1"; exit 2 ;;
  esac
done

if [[ ! -x "$BENCH" ]]; then
  error "bench-shell.sh not found or not executable: $BENCH"
  exit 2
fi

# ============================================================================
# MEASURE
# ============================================================================
info "Measuring shell startup ($RUNS runs each, warm + cold-ish)..."
measurement=$("$BENCH" --json --runs "$RUNS" 2>/dev/null)
if [[ -z "$measurement" ]]; then
  error "bench-shell.sh produced no output (needs a real TTY — run from a terminal)"
  exit 2
fi

# Pull the two metrics we gate on: warm p50 (typical felt latency) and
# cold p95 (worst-case after cache eviction). jq if present, else sed.
read_metric() {
  local mode="$1" pct="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${mode}.${pct}" <<< "$measurement"
  else
    sed -nE "s/.*\"${mode}\":\{[^}]*\"${pct}\":([0-9]+).*/\1/p" <<< "$measurement"
  fi
}
warm_p50=$(read_metric warm p50)
cold_p95=$(read_metric cold p95)

if [[ -z "$warm_p50" || -z "$cold_p95" ]]; then
  error "could not parse measurement: $measurement"
  exit 2
fi

# ============================================================================
# CALIBRATE
# ============================================================================
if [[ "$CALIBRATE" == true ]]; then
  ceil_with_margin() { echo $(( ($1 * (100 + MARGIN_PCT) + 99) / 100 )); }
  new_warm=$(ceil_with_margin "$warm_p50")
  new_cold=$(ceil_with_margin "$cold_p95")
  {
    printf '# shell-perf-budget.env — interactive zsh startup ceiling (milliseconds).\n'
    printf '# Regenerate on this machine with: just perf-calibrate\n'
    printf '# Measured warm p50=%s cold p95=%s, +%d%% headroom, on %s.\n' \
      "$warm_p50" "$cold_p95" "$MARGIN_PCT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'WARM_P50_MAX_MS=%s\n' "$new_warm"
    printf 'COLD_P95_MAX_MS=%s\n' "$new_cold"
  } > "$BUDGET_FILE"
  success "Calibrated budget → $BUDGET_FILE"
  info "  WARM_P50_MAX_MS=$new_warm (measured $warm_p50)"
  info "  COLD_P95_MAX_MS=$new_cold (measured $cold_p95)"
  exit 0
fi

# ============================================================================
# COMPARE
# ============================================================================
if [[ ! -f "$BUDGET_FILE" ]]; then
  warning "No budget file yet — run 'just perf-calibrate' (or --calibrate) on this machine first."
  warning "Measured: warm p50=${warm_p50}ms  cold p95=${cold_p95}ms"
  exit 0
fi

# shellcheck disable=SC1090
source "$BUDGET_FILE"

if [[ "$JSON" == true ]]; then
  printf '{"warm_p50":%d,"warm_p50_max":%d,"cold_p95":%d,"cold_p95_max":%d}\n' \
    "$warm_p50" "${WARM_P50_MAX_MS:-0}" "$cold_p95" "${COLD_P95_MAX_MS:-0}"
fi

regressed=0
[[ "$warm_p50" -gt "${WARM_P50_MAX_MS:-999999}" ]] && regressed=1
[[ "$cold_p95" -gt "${COLD_P95_MAX_MS:-999999}" ]] && regressed=1

if [[ "$regressed" -eq 0 ]]; then
  success "Shell startup within budget — warm p50=${warm_p50}/${WARM_P50_MAX_MS}ms  cold p95=${cold_p95}/${COLD_P95_MAX_MS}ms"
  exit 0
fi

error "Shell startup REGRESSED past budget:"
[[ "$warm_p50" -gt "${WARM_P50_MAX_MS:-999999}" ]] && error "  warm p50  ${warm_p50}ms > ${WARM_P50_MAX_MS}ms"
[[ "$cold_p95" -gt "${COLD_P95_MAX_MS:-999999}" ]] && error "  cold p95  ${cold_p95}ms > ${COLD_P95_MAX_MS}ms"
echo "" >&2
warning "If this is an intentional, accepted cost: just perf-calibrate (re-baseline)."
warning "Otherwise profile with: ZPROF=1 exec zsh   (see scripts/maintenance/bench-shell.sh)"

if [[ "$ENFORCE" -eq 1 ]]; then
  exit 1
fi
warning "(warn-only — pass --enforce or set SHELL_PERF_ENFORCE=1 to fail on this)"
exit 0
