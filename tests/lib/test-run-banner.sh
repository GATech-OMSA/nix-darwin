#!/usr/bin/env bash
#
# Test: Run Banner
# Tests scripts/lib/run-banner.sh's run_banner() output
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Run Banner"

test_section "Banner Output"

source "$REPO_ROOT/scripts/lib/run-banner.sh"

banner_output="$(run_banner "test-script" "flag1=true flag2=false" arg1 arg2)"

if echo "$banner_output" | grep -q "test-script"; then
  _test_log "pass" "Banner output contains script name"
else
  _test_log "fail" "Banner output missing script name" "$banner_output"
fi

if echo "$banner_output" | grep -q "^args:.*arg1 arg2"; then
  _test_log "pass" "Banner output contains args line with invocation args"
else
  _test_log "fail" "Banner output missing args line" "$banner_output"
fi

if echo "$banner_output" | grep -q "^flags:.*flag1=true flag2=false"; then
  _test_log "pass" "Banner output contains flags line"
else
  _test_log "fail" "Banner output missing flags line" "$banner_output"
fi

test_section "Banner Output — No Args"

no_args_output="$(run_banner "test-script" "")"

if echo "$no_args_output" | grep -q "^args:.*(none)"; then
  _test_log "pass" "Banner output shows (none) when no args passed"
else
  _test_log "fail" "Banner output did not show (none) for empty args" "$no_args_output"
fi

test_end
