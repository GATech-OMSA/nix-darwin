#!/usr/bin/env bash
#
# bench-shell.sh - Measure interactive zsh startup latency
#
# Runs N cold + warm interactive zsh starts under a TTY (via `script`)
# so the timing reflects what the user actually sees. Reports p50 / p95
# for each mode in milliseconds.
#
# Cold = fresh dyld/page cache; we approximate by sleeping briefly between
# runs and using a fresh subshell each time. True cold-cache requires a
# reboot — labeled "cold-ish" in output.
#
# Usage:
#   bench-shell.sh                # default 10 runs each
#   bench-shell.sh --runs 25      # 25 runs each
#   bench-shell.sh --json         # machine-readable
#
# Requires: bash, awk, /usr/bin/script (BSD variant on macOS), /usr/bin/perl

set -uo pipefail

RUNS=10
JSON=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --runs|-n) RUNS="$2"; shift 2 ;;
    --json|-j) JSON=true; shift ;;
    --help|-h)
      echo "Usage: bench-shell.sh [--runs N] [--json]"
      echo ""
      echo "Time interactive zsh starts under a TTY. Reports p50/p95 in ms."
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# Use perl for monotonic ms timing — `time` builtin doesn't give us a
# parseable single number across mac shells. Perl's Time::HiRes is portable.
# We discard zsh's TTY chatter by sending stdout to /dev/null. Perl writes
# its timing to STDERR so it survives the redirect.
time_one() {
  /usr/bin/perl -MTime::HiRes=time -e '
    my $t0 = time();
    system(@ARGV);
    printf STDERR "%.3f\n", (time() - $t0) * 1000;
  ' -- /usr/bin/script -q /dev/null /bin/zsh -i -c exit 2>/tmp/bench-shell.timing >/dev/null
  /bin/cat /tmp/bench-shell.timing
}

# Same, but with a hot timing — caller is responsible for warming first.
run_series() {
  local n="$1"; shift
  local i
  for ((i = 0; i < n; i++)); do
    time_one
  done
}

percentile() {
  # $1 = file with one number per line, $2 = percentile (e.g. 50, 95)
  /usr/bin/sort -g "$1" | /usr/bin/awk -v p="$2" '
    BEGIN { c = 0 }
    { v[c++] = $1 }
    END {
      if (c == 0) { print "0"; exit }
      idx = int((p / 100) * (c - 1) + 0.5)
      printf("%.0f\n", v[idx])
    }'
}

mean() {
  /usr/bin/awk '{s+=$1; n++} END { if (n>0) printf("%.0f\n", s/n); else print 0 }' "$1"
}

# Drop the in-process executor caches by calling sync — best-effort cold-ish.
prep_cold() {
  /bin/sync 2>/dev/null || true
  /bin/sleep 0.5
}

cold_file=$(/usr/bin/mktemp)
warm_file=$(/usr/bin/mktemp)
trap '/bin/rm -f "$cold_file" "$warm_file" /tmp/bench-shell.timing' EXIT

# Warm-up: discard one run so JIT/page-cache are populated for "warm" measurements.
time_one >/dev/null

# Warm series — back-to-back, no prep.
run_series "$RUNS" > "$warm_file"

# Cold-ish series — sync + small sleep before each.
for ((i = 0; i < RUNS; i++)); do
  prep_cold
  time_one
done > "$cold_file"

warm_p50=$(percentile "$warm_file" 50)
warm_p95=$(percentile "$warm_file" 95)
warm_mean=$(mean "$warm_file")
cold_p50=$(percentile "$cold_file" 50)
cold_p95=$(percentile "$cold_file" 95)
cold_mean=$(mean "$cold_file")

if [[ "$JSON" == true ]]; then
  printf '{"runs":%d,"warm":{"p50":%d,"p95":%d,"mean":%d},"cold":{"p50":%d,"p95":%d,"mean":%d}}\n' \
    "$RUNS" "$warm_p50" "$warm_p95" "$warm_mean" "$cold_p50" "$cold_p95" "$cold_mean"
else
  printf 'bench-shell — %d runs each\n' "$RUNS"
  printf '  warm    p50=%4d ms   p95=%4d ms   mean=%4d ms\n' "$warm_p50" "$warm_p95" "$warm_mean"
  printf '  cold-ish p50=%4d ms   p95=%4d ms   mean=%4d ms\n' "$cold_p50" "$cold_p95" "$cold_mean"
  printf '\nNotes:\n'
  printf '  - timing covers `script -q /dev/null zsh -i -c exit` (TTY, full init)\n'
  printf '  - "cold-ish" = sync+sleep between runs; true cold needs a reboot\n'
fi
