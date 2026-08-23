#!/usr/bin/env bash
#
# Test: Security Pre-flight Verdict Cache
# Tests the cache-key logic in scripts/maintenance/security-preflight.sh
# WITHOUT running vulnix or building a closure. security-preflight.sh guards
# its main() behind a `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` check, so sourcing
# it here only defines the pure cache-key helper functions.
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Security Pre-flight Verdict Cache"

# security-preflight.sh sources run-banner.sh via a REPO_ROOT-relative path
# and reads FLAKE_ROOT/NIX_DIR at source time — both resolve fine against the
# real repo, and main() never runs, so this is side-effect-free.
FLAKE_ROOT="$REPO_ROOT" source "$REPO_ROOT/scripts/maintenance/security-preflight.sh"
# security-preflight.sh's `set -euo pipefail` persists into this sourcing
# shell; restore the test framework's own `set -uo pipefail` (no -e) so
# assertion helpers like _test_log's `((TEST_TOTAL++))` (0 -> falsy under -e)
# don't abort the run.
set +e -uo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

test_section "Cache Key: Same Inputs -> Same Key"

sig="$(compute_whitelist_sig "$tmp_dir")"
key1="$(compute_cache_key "/nix/store/abc-fake-target" "$sig")"
key2="$(compute_cache_key "/nix/store/abc-fake-target" "$sig")"

assert_equals "$key1" "$key2" "compute_cache_key is deterministic for identical inputs"

test_section "Cache Key: Changed Whitelist Mtime -> Different Key"

mkdir -p "$tmp_dir/scripts/validation"
whitelist="$tmp_dir/scripts/validation/vulnix-whitelist.toml"
echo "# whitelist v1" > "$whitelist"
touch -t 202001010000 "$whitelist"

sig_before="$(compute_whitelist_sig "$tmp_dir")"
key_before="$(compute_cache_key "/nix/store/abc-fake-target" "$sig_before")"

touch -t 202506150000 "$whitelist"
sig_after="$(compute_whitelist_sig "$tmp_dir")"
key_after="$(compute_cache_key "/nix/store/abc-fake-target" "$sig_after")"

assert_not_equals "$sig_before" "$sig_after" "compute_whitelist_sig changes when whitelist mtime changes"
assert_not_equals "$key_before" "$key_after" "compute_cache_key changes when whitelist mtime changes"

test_section "TTL Expiry"

now="$(date +%s)"
fresh_ts=$(( now - (2 * 86400) ))   # 2 days old
stale_ts=$(( now - (10 * 86400) ))  # 10 days old

fresh_cache_file="$tmp_dir/fresh-cache"
printf '%s\n%s\n' "$fresh_ts" "clean" > "$fresh_cache_file"

stale_cache_file="$tmp_dir/stale-cache"
printf '%s\n%s\n' "$stale_ts" "clean" > "$stale_cache_file"

fresh_age="$(cache_verdict_age_days "$fresh_cache_file" "$now")"
stale_age="$(cache_verdict_age_days "$stale_cache_file" "$now")"
default_ttl_days=7

if [[ "$fresh_age" -lt "$default_ttl_days" ]]; then
  _test_log "pass" "A 2-day-old verdict is within the default ${default_ttl_days}-day TTL (age=${fresh_age})"
else
  _test_log "fail" "A 2-day-old verdict should be within TTL" "age=${fresh_age}, ttl=${default_ttl_days}"
fi

if [[ "$stale_age" -ge "$default_ttl_days" ]]; then
  _test_log "pass" "A 10-day-old verdict is past the default ${default_ttl_days}-day TTL (age=${stale_age})"
else
  _test_log "fail" "A 10-day-old verdict should be past TTL" "age=${stale_age}, ttl=${default_ttl_days}"
fi

corrupt_cache_file="$tmp_dir/corrupt-cache"
printf 'not-a-timestamp\nclean\n' > "$corrupt_cache_file"
corrupt_age="$(cache_verdict_age_days "$corrupt_cache_file" "$now")"
assert_equals "$corrupt_age" "999" "A corrupt/non-numeric timestamp is treated as expired (age=999)"

test_section "Verdict Value Round-trip"

assert_equals \
  "$(cache_verdict_value "$fresh_cache_file")" \
  "clean" \
  "cache_verdict_value reads back the recorded verdict"

test_end
