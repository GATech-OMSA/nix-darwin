#!/usr/bin/env bash
#
# Test: Audit Framework
# Tests scripts/lib/audit-framework.sh's print/check/scoring helpers
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Audit Framework"

test_section "Counter Helpers"

# The caller owns the counters — initialize before calling check_*.
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

source "$REPO_ROOT/scripts/lib/audit-framework.sh"

check_pass "a passing check" > /dev/null
assert_equals "$TOTAL_CHECKS" "1" "check_pass increments TOTAL_CHECKS"
assert_equals "$PASSED_CHECKS" "1" "check_pass increments PASSED_CHECKS"

check_fail "a failing check" > /dev/null
assert_equals "$TOTAL_CHECKS" "2" "check_fail increments TOTAL_CHECKS"
assert_equals "$FAILED_CHECKS" "1" "check_fail increments FAILED_CHECKS"

check_warn "a warning check" > /dev/null
assert_equals "$TOTAL_CHECKS" "3" "check_warn increments TOTAL_CHECKS"
assert_equals "$WARNINGS" "1" "check_warn increments WARNINGS"

test_section "Print Helpers"

header_output="$(print_header "Section Title")"
assert_output_contains \
  "print_header 'Section Title'" \
  "Section Title" \
  "print_header includes the given title"

category_output="$(print_category "Category Name")"
assert_output_contains \
  "print_category 'Category Name'" \
  "Category Name" \
  "print_category includes the given name"

test_end
