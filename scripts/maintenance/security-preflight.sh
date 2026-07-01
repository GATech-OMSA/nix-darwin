#!/usr/bin/env bash
#
# security-preflight.sh - "y": assess what WOULD be installed before committing.
#
# The repo-rooted orchestrator counterpart to the hermetic scan-vulnerabilities.sh
# ("x", which scans the live system). This resolves the flake + machineId, realizes
# the candidate darwin closure WITHOUT switching, scans it for CVEs, diffs it
# against the running system, and — if there are findings — prompts before the
# caller proceeds.
#
# Wired as a pre-flight into rebuild.sh, update-nix, and update-brew. Bypass with
# SKIP_SECURITY_PREFLIGHT=1 (or each caller's own skip flag).
#
# Modes:
#   (default)  build the candidate (this IS the download; the later switch reuses
#              the cached closure) → accurate runtime-closure CVE view.
#   --fast     eval only, scan the system .drv — a pre-download peek. Noisier:
#              it's the BUILD closure (build-time deps that never get installed).
#
# Verdict cache: clean AND findings verdicts are cached keyed by the candidate
#   closure path (+ whitelist mtime), so a rebuild whose closure hasn't changed
#   skips the ~50–80 s vulnix scan entirely. Findings are cached only after an
#   explicit accept (prompt approval or --no-prompt) — a cached findings verdict
#   auto-proceeds (the closure is identical → same CVEs → already triaged); a
#   no-TTY fallback or user decline is NOT cached (re-prompts next time). TTL
#   bounds staleness (NVD publishes new CVEs for the same packages); --no-cache
#   forces a fresh scan + re-prompt. SEC_PREFLIGHT_CACHE_TTL_DAYS overrides the
#   7-day default.
#
# Exit: 0 = proceed (clean, accepted at prompt, scan unavailable, or non-TTY)
#       1 = abort (user declined at the prompt). A failed scan never aborts.
#
# Usage: security-preflight.sh [--fast] [--no-prompt] [--no-cache]

set -euo pipefail

NIX_DIR="${FLAKE_ROOT:-$HOME/nix-darwin}"
FAST=false
PROMPT=true
USE_CACHE=true
CACHE_DIR="${HOME}/.cache/nix-darwin/sec-preflight"
CACHE_TTL_DAYS="${SEC_PREFLIGHT_CACHE_TTL_DAYS:-7}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) FAST=true; shift ;;
    --no-prompt) PROMPT=false; shift ;;
    --no-cache) USE_CACHE=false; shift ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -t 1 ]]; then
  YELLOW='\033[0;33m'; BLUE='\033[0;34m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
else
  YELLOW=''; BLUE=''; GREEN=''; BOLD=''; NC=''
fi
info()    { echo -e "${BLUE}→${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }

# Honor the global skip switch.
if [[ "${SKIP_SECURITY_PREFLIGHT:-0}" == "1" ]]; then
  info "Security pre-flight skipped (SKIP_SECURITY_PREFLIGHT=1)."
  exit 0
fi

# ── Resolve machineId (flake config name != hostname) ──────────────────────
# Prefer a MACHINE_ID passed by the caller (rebuild.sh already eval'd it) to
# avoid a second `nix eval` fork per rebuild; fall back to evaluating it here.
machine_id="${MACHINE_ID:-$(nix eval --raw --file "$NIX_DIR/config/machine-config.nix" machineId 2>/dev/null || true)}"
if [[ -z "$machine_id" ]]; then
  warning "Could not read machineId — skipping security pre-flight (proceeding)."
  exit 0
fi
flake_attr=".#darwinConfigurations.${machine_id}.system"

# The scanner: prefer the packaged command, else the repo script.
if command -v security-scan >/dev/null 2>&1; then
  SCAN=(security-scan)
else
  SCAN=("$NIX_DIR/scripts/validation/scan-vulnerabilities.sh")
fi

cd "$NIX_DIR" || { warning "Cannot cd to $NIX_DIR — skipping pre-flight."; exit 0; }

echo ""
echo -e "${BOLD}🔒 Security pre-flight — assessing what would be installed${NC}"

# ── Realize the candidate ──────────────────────────────────────────────────
# --impure + FLAKE_ROOT mirror the real switch (overlays read getEnv HOME/FLAKE_ROOT);
# a bare build would eval-fail where the real build succeeds.
if [[ "$FAST" == true ]]; then
  info "Fast mode: evaluating candidate derivation (no download)…"
  target="$(FLAKE_ROOT="$NIX_DIR" nix path-info --impure --derivation "$flake_attr" 2>/dev/null || true)"
  [[ -z "$target" ]] && { warning "Could not evaluate candidate .drv — skipping (proceeding)."; exit 0; }
  warning "Fast scan is the BUILD closure (superset incl. build-time deps not installed)."
else
  info "Building candidate closure (no switch; the switch will reuse this)…"
  if ! target="$(FLAKE_ROOT="$NIX_DIR" nix build --impure --no-link --print-out-paths "$flake_attr" 2>&1 | tail -1)" \
     || [[ ! -e "$target" ]]; then
    warning "Candidate build failed — skipping security pre-flight (proceeding)."
    exit 0
  fi
fi

# ── Verdict cache (skip the ~50–80s scan when the closure is unchanged) ─────
# Key = candidate path (content-addressed, stable for unchanged inputs) + the
# whitelist mtime (whitelist edits must invalidate). BOTH clean and findings
# verdicts are cached — but findings only after an explicit accept (prompt
# approval or --no-prompt), never after a no-TTY fallback or a user decline.
# A cached findings verdict auto-proceeds: the closure is identical → same
# CVEs → the user already triaged it. TTL bounds staleness (NVD publishes new
# CVEs for the same packages); --no-cache forces a fresh scan + re-prompt.
# Cache file: "<unix-ts>\n<verdict: clean|findings>".
if [[ "$USE_CACHE" == true ]]; then
  whitelist_sig=""
  for _w in "${VULNIX_WHITELIST:-}" "$NIX_DIR/scripts/validation/vulnix-whitelist.toml"; do
    [[ -n "$_w" && -f "$_w" ]] && whitelist_sig="${whitelist_sig}$(stat -f '%m' "$_w" 2>/dev/null || echo 0)"
  done
  cache_key="$(printf '%s|%s' "$target" "$whitelist_sig" | /usr/bin/shasum -a 256 | awk '{print $1}')" || cache_key=""
  cache_file="$CACHE_DIR/${cache_key}"
  if [[ -n "$cache_key" && -f "$cache_file" ]]; then
    cached_ts="$(head -1 "$cache_file" 2>/dev/null || echo 0)"
    cached_verdict="$(sed -n '2p' "$cache_file" 2>/dev/null || echo "")"
    now="$(date +%s)"
    # Guard against a corrupt/non-numeric ts: treat as expired so we re-scan
    # rather than trip set -e in the arithmetic below.
    if [[ "$cached_ts" =~ ^[0-9]+$ ]]; then
      age_days=$(( (now - cached_ts) / 86400 ))
    else
      age_days=999
    fi
    if [[ "$age_days" -lt "$CACHE_TTL_DAYS" ]]; then
      if [[ "$cached_verdict" == "clean" ]]; then
        echo -e "${GREEN}✓ (cached) Candidate closure unchanged — no known non-whitelisted CVEs (last scanned ${age_days} day(s) ago; --no-cache re-scans).${NC}"
        exit 0
      elif [[ "$cached_verdict" == "findings" ]]; then
        echo -e "${YELLOW}⚠ (cached) Candidate closure unchanged — same known CVEs as last scan (${age_days} day(s) ago), previously accepted. Proceeding.${NC}"
        echo -e "${YELLOW}  Run 'secnext --no-cache' for the full CVE list or to re-review.${NC}"
        exit 0
      fi
    fi
  fi
fi

# ── What changes vs the running system (nvd diff) ──────────────────────────
if [[ "$FAST" == false ]] && command -v nvd >/dev/null 2>&1 && [[ -e /run/current-system ]]; then
  echo ""
  info "Package changes vs current system:"
  nvd diff /run/current-system "$target" 2>/dev/null | sed 's/^/    /' || true
fi

# ── Scan the candidate (single run; exit code carries the verdict) ──────────
echo ""
set +e
"${SCAN[@]}" --system "$target" --no-brew --strict
scan_rc=$?
set -e

# write_cache <verdict>: persist a clean/findings verdict so the next rebuild
# of this same closure skips the scan. No-op when --no-cache or no key. Findings
# are only written on an EXPLICIT accept (clean, --no-prompt, or prompt yes) —
# never after a no-TTY fallback or a user decline (those re-prompt next time).
write_cache() {
  [[ "$USE_CACHE" == true && -n "${cache_key:-}" ]] || return 0
  [[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"
  printf '%s\n%s\n' "$(date +%s)" "$1" > "$cache_file"
}

# Exit-code contract: 0 clean · 2 findings · 1 could-not-run.
case "$scan_rc" in
  0)
    echo -e "${GREEN}✓ Candidate system has no known non-whitelisted CVEs.${NC}"
    write_cache "clean"
    exit 0
    ;;
  1)
    warning "CVE scan could not run (offline / NVD unavailable) — proceeding without a gate."
    exit 0
    ;;
esac

# scan_rc == 2 → findings present.
if [[ "$PROMPT" == false ]]; then
  warning "Candidate carries known CVEs (pre-flight informational; proceeding)."
  write_cache "findings"   # --no-prompt is an explicit accept → cache
  exit 0
fi
# Prompt only with a real TTY; scripted/cron contexts proceed with a warning
# (matches the chosen 'prompt', not 'block', semantics). Don't cache: an
# implicit no-TTY proceed isn't an explicit accept — preserve the prompt for
# the next interactive rebuild of this closure.
if [[ ! -t 0 ]]; then
  warning "Candidate carries known CVEs; no TTY to prompt — proceeding. Run 'secnext' to review."
  exit 0
fi

echo ""
warning "The candidate system carries known CVEs (see above)."
info "Remediation: 'secnow --explain' to find owners · whitelist accepted ones · or continue."
printf "Proceed with install/switch anyway? [y/N] "
read -r reply </dev/tty
case "$reply" in
  [yY]|[yY][eE][sS]) write_cache "findings"; exit 0 ;;
  *) warning "Aborted by user. Nothing was switched."; exit 1 ;;
esac
