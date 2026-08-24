#!/usr/bin/env bash
#
# Test: Machine ID Resolver
# Tests scripts/lib/machine-id.sh's get_machine_id() resolver
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Machine ID Resolver"

test_section "Resolves Repo's Configured machineId"

source "$REPO_ROOT/scripts/lib/machine-id.sh"

if [[ -f "$REPO_ROOT/config/machine-config.nix" ]]; then
  expected_id=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" machineId 2>/dev/null || echo "")
  resolved_id="$(REPO_ROOT="$REPO_ROOT" get_machine_id)"

  assert_equals \
    "$resolved_id" \
    "$expected_id" \
    "get_machine_id resolves the repo's configured machineId"
else
  test_skip "get_machine_id resolution" "config/machine-config.nix not found"
fi

test_section "Fallback When Config Is Missing"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fallback_id="$(REPO_ROOT="$tmp_dir" get_machine_id)"

assert_equals \
  "$fallback_id" \
  "" \
  "get_machine_id returns empty string when config/machine-config.nix does not exist"

test_section "Fallback When Config Has No machineId"

mkdir -p "$tmp_dir/config"
echo '{ profileName = "personal"; }' > "$tmp_dir/config/machine-config.nix"

bad_config_id="$(REPO_ROOT="$tmp_dir" get_machine_id)"

assert_equals \
  "$bad_config_id" \
  "" \
  "get_machine_id returns empty string when machineId is absent from config"

test_end
