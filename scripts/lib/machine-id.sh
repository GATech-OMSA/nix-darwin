# scripts/lib/machine-id.sh
#
# Canonical machineId resolver for shell scripts. Uses `nix eval` against
# config/machine-config.nix — the same source rebuild.sh and security-preflight
# use. Replaces the fragile `grep 'machineId' | sed/cut` pattern that breaks
# if the quoting/whitespace in machine-config.nix changes.
#
# Source from a script that has REPO_ROOT set:
#   source "${REPO_ROOT}/scripts/lib/machine-id.sh"
# Then:  MACHINE_ID="$(get_machine_id)"   # empty if unset/unavailable

get_machine_id() {
  local cfg="${REPO_ROOT:-$HOME/nix-darwin}/config/machine-config.nix"
  [[ -f "$cfg" ]] || return 0
  nix eval --raw --file "$cfg" machineId 2>/dev/null || true
}