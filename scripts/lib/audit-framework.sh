# audit-framework.sh
#
# Shared print / check / scoring helpers for the audit scripts
# (health-check.sh, verify-backups.sh, audit-permissions.sh). Removes the
# byte-identical print_header / print_category blocks and the duplicated
# check_pass / check_fail / check_warn functions.
#
# Colors are TTY-aware (empty when stdout isn't a TTY), so output captured by
# a parent script (e.g. health-check.sh invoking the others via `2>&1`) is
# plain text — no ANSI codes to scrape around.
#
# The caller owns the counters: initialize TOTAL_CHECKS / PASSED_CHECKS /
# FAILED_CHECKS / WARNINGS (and VERBOSE) before calling check_*. This file
# defines only functions + color vars, so it's safe to source under
# `set -euo pipefail` (the `((++VAR))` form is set -e-safe).
#
# Usage:
#   source "${REPO_ROOT}/scripts/lib/audit-framework.sh"

# TTY-aware ANSI colors (empty when piped/non-TTY → machine-readable output).
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; NC=''
fi

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_category() {
  echo ""
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
  echo ""
}

check_pass() {
  ((++TOTAL_CHECKS))
  ((++PASSED_CHECKS))
  echo -e "  ${GREEN}✓${NC} $1"
  if [[ ${VERBOSE:-0} -eq 1 && -n "${2:-}" ]]; then
    echo -e "    ${CYAN}→${NC} $2"
  fi
}

check_fail() {
  ((++TOTAL_CHECKS))
  ((++FAILED_CHECKS))
  echo -e "  ${RED}✗${NC} $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "    ${RED}→${NC} $2"
  fi
}

check_warn() {
  ((++TOTAL_CHECKS))
  ((++WARNINGS))
  echo -e "  ${YELLOW}▸${NC} $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "    ${YELLOW}→${NC} $2"
  fi
}

verbose_output() {
  if [[ ${VERBOSE:-0} -eq 1 ]]; then
    echo -e "    ${CYAN}→${NC} $1"
  fi
}