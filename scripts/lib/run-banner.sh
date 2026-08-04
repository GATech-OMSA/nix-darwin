# run-banner.sh
#
# Shared run-header banner for user-facing scripts. Mirrors the format
# rebuild.sh has printed at the top of every run — name, UTC timestamp,
# resolved machine, invocation args, and a caller-supplied flag summary —
# so other scripts give the same at-a-glance context.
#
# Source from a script that has REPO_ROOT set (recommended, so machineId
# resolves) or standalone:
#   source "${REPO_ROOT}/scripts/lib/run-banner.sh"
# Then:
#   run_banner "<name>" "<flags summary>" "$@"
#
# Prints:
#   ===== <name> <UTC timestamp> =====
#   machine: <machineId>        (omitted if unresolvable — some scripts
#                                 run before config/machine-config.nix exists)
#   args:    <"$@" or (none)>
#   flags:   <flags summary>
#   <blank line>
#
# Machine resolution order: an already-set $MACHINE_ID wins (callers like
# rebuild.sh that already eval'd it avoid a second `nix eval` fork); else
# scripts/lib/machine-id.sh's get_machine_id is sourced (from this file's own
# directory, so it works even if REPO_ROOT isn't set yet) and called.

if ! declare -F get_machine_id &>/dev/null; then
  _run_banner_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [[ -f "${_run_banner_lib_dir}/machine-id.sh" ]] && source "${_run_banner_lib_dir}/machine-id.sh"
  unset _run_banner_lib_dir
fi

run_banner() {
  local name="$1"
  local flags="$2"
  shift 2

  echo "===== ${name} $(date -u +%Y-%m-%dT%H:%M:%SZ) ====="

  local mid="${MACHINE_ID:-}"
  if [[ -z "$mid" ]] && declare -F get_machine_id &>/dev/null; then
    mid="$(get_machine_id)"
  fi
  [[ -n "$mid" ]] && echo "machine: $mid"

  echo "args:    ${*:-(none)}"
  echo "flags:   ${flags}"
  echo
}
