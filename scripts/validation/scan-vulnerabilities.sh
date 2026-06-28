#!/usr/bin/env bash
#
# scan-vulnerabilities.sh - CVE scan of the live system closure + brew cask drift
#
# Runs vulnix against /run/current-system (the active nix-darwin closure) and
# summarizes known CVEs by CVSS severity. Also surfaces Homebrew casks with
# pending updates, since brew is manual-update here (casks don't auto-patch).
#
# Whitelist (accepted/known-noise CVEs) is resolved in this order so it works
# identically whether run from the repo tree or from a packaged /nix/store copy:
#   1. $VULNIX_WHITELIST
#   2. <script-dir>/vulnix-whitelist.toml   (raw repo checkout)
#   3. $HOME/nix-darwin/scripts/validation/vulnix-whitelist.toml  (packaged)
#
# vulnix is located via $VULNIX_BIN, then PATH, then `nix run nixpkgs#vulnix`.
# The packaged tool (pkgs/security-scan) bundles vulnix in runtimeInputs, so the
# nix-run fallback only fires for an un-packaged raw invocation.
#
# Usage:
#   scan-vulnerabilities.sh [--json] [--system PATH] [--no-brew] [--strict] [--explain]
#
# Exit codes (so a pre-flight gate can tell "vulnerable" from "couldn't run"):
#   0  clean — no non-whitelisted CVEs
#   2  findings present (only signalled with --strict; informational runs stay 0)
#   1  could-not-run — missing jq/target, or vulnix/NVD failure
# A gate maps 2→prompt, 1→warn-and-proceed (never block on a scan that failed),
# 0→silent. See scripts/maintenance/security-preflight.sh.

set -euo pipefail

# ============================================
# Configuration / arguments
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN_TARGET="/run/current-system"
OUTPUT_JSON=false
CHECK_BREW=true
STRICT=false
EXPLAIN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --system) SCAN_TARGET="$2"; shift 2 ;;
    --no-brew) CHECK_BREW=false; shift ;;
    --strict) STRICT=true; shift ;;
    --explain) EXPLAIN=true; shift ;;
    -h|--help)
      cat <<'EOF'
scan-vulnerabilities.sh - CVE scan of the live system closure + brew cask drift

Usage:
  scan-vulnerabilities.sh [--json] [--system PATH] [--no-brew] [--strict] [--explain]

  --json        Emit raw vulnix JSON (for piping into other tools / a digest).
  --system PATH Scan this closure (or .drv) instead of /run/current-system.
  --no-brew     Skip the Homebrew cask drift check.
  --strict      Exit 2 when non-whitelisted CVEs are present (gate signal).
  --explain     For each affected package, show the top-level dependency root
                that pulls it in (so you know what to remove / accept).

Exit codes: 0 clean · 2 findings (--strict) · 1 could-not-run.
Whitelist resolution: $VULNIX_WHITELIST, then <script-dir>/vulnix-whitelist.toml,
then $HOME/nix-darwin/scripts/validation/vulnix-whitelist.toml.
EOF
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ANSI colors (disabled when not a TTY)
if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi
info()    { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
errmsg()  { echo -e "${RED}✗${NC} $*" >&2; }

# ============================================
# Locate dependencies
# ============================================
if ! command -v jq >/dev/null 2>&1; then
  errmsg "jq is required but not found on PATH."
  exit 1
fi

# vulnix invocation as an array (avoids word-split / SC2086).
if [[ -n "${VULNIX_BIN:-}" ]]; then
  VULNIX=("$VULNIX_BIN")
elif command -v vulnix >/dev/null 2>&1; then
  VULNIX=(vulnix)
else
  warning "vulnix not on PATH — falling back to 'nix run nixpkgs#vulnix'."
  VULNIX=(nix run nixpkgs#vulnix --)
fi

# ============================================
# Resolve whitelist (optional)
# ============================================
WHITELIST=""
for candidate in \
  "${VULNIX_WHITELIST:-}" \
  "$SCRIPT_DIR/vulnix-whitelist.toml" \
  "$HOME/nix-darwin/scripts/validation/vulnix-whitelist.toml"; do
  if [[ -n "$candidate" && -f "$candidate" ]]; then
    WHITELIST="$candidate"
    break
  fi
done

# ============================================
# Run the scan
# ============================================
if [[ ! -e "$SCAN_TARGET" ]]; then
  errmsg "Scan target does not exist: $SCAN_TARGET"
  exit 1
fi

# A .drv is scanned via its requisites (build closure — a SUPERSET that includes
# build-time deps never installed at runtime). An output path uses -C (runtime
# closure only). This lets the same scanner serve both `x` (built system) and the
# eval-only `y --fast` preview (system .drv).
VULNIX_ARGS=(-j)
[[ -n "$WHITELIST" ]] && VULNIX_ARGS+=(-w "$WHITELIST")
if [[ "$SCAN_TARGET" == *.drv ]]; then
  VULNIX_ARGS+=("$SCAN_TARGET")
  IS_DRV=true
else
  VULNIX_ARGS+=(-C "$SCAN_TARGET")
  IS_DRV=false
fi

[[ "$OUTPUT_JSON" == false ]] && info "Scanning closure of ${BOLD}$SCAN_TARGET${NC} (first run downloads NVD data)…"
[[ "$OUTPUT_JSON" == false && "$IS_DRV" == true ]] && warning "Derivation scan: BUILD-closure superset (includes build-time deps not installed at runtime)."
[[ -n "$WHITELIST" && "$OUTPUT_JSON" == false ]] && info "Whitelist: $WHITELIST"

# vulnix exits 2 both for "advisories found" and for an NVD runtime error; we
# disambiguate below by whether stdout parses as a JSON array. Capture rather
# than let `set -e` abort on the expected non-zero.
rc=0
RESULT="$("${VULNIX[@]}" "${VULNIX_ARGS[@]}" 2>/tmp/vulnix-scan.$$.err)" || rc=$?

if ! echo "$RESULT" | jq -e 'type == "array"' >/dev/null 2>&1; then
  errmsg "vulnix did not return valid JSON (exit $rc). Likely an NVD fetch error:"
  sed 's/^/    /' "/tmp/vulnix-scan.$$.err" >&2 || true
  /bin/rm -f "/tmp/vulnix-scan.$$.err"
  exit 1
fi
/bin/rm -f "/tmp/vulnix-scan.$$.err"

# Raw JSON passthrough for piping into other tools / the digest.
if [[ "$OUTPUT_JSON" == true ]]; then
  echo "$RESULT"
  # In --strict, signal findings via exit 2 (1 is reserved for could-not-run).
  if [[ "$STRICT" == true ]] && [[ "$(echo "$RESULT" | jq 'length')" -gt 0 ]]; then
    exit 2
  fi
  exit 0
fi

# ============================================
# Human-readable severity summary
# ============================================
AFFECTED_PKGS="$(echo "$RESULT" | jq 'length')"

if [[ "$AFFECTED_PKGS" -eq 0 ]]; then
  success "No known CVEs in the system closure. ${BOLD}Excellent.${NC}"
else
  # Bucket each affected package by its highest CVSS v3 base score. A leading
  # numeric rank (0=CRITICAL … 4=UNKNOWN) gives deterministic severity ordering
  # for both the summary and the list — alphabetic sort would misorder LOW.
  echo "$RESULT" | jq -r '
    def rank($s): if $s >= 9 then "0\tCRITICAL"
                  elif $s >= 7 then "1\tHIGH"
                  elif $s >= 4 then "2\tMEDIUM"
                  elif $s > 0  then "3\tLOW"
                  else "4\tUNKNOWN" end;
    .[] | . as $p
    | ([$p.cvssv3_basescore[]?] | max? // 0) as $max
    | "\(rank($max))\t\($p.name)\t\($p.affected_by | length) CVE(s)\tmax CVSS \(if $max>0 then ($max|tostring) else "n/a" end)"
  ' | sort -t"$(printf '\t')" -k1,1n -k3,3 | awk -F'\t' '
      { count[$2]++; lines = lines sprintf("    %-9s %-26s %-11s %s\n", $2, $3, $4, $5) }
      END {
        printf "\n  By severity:\n"
        n = split("CRITICAL HIGH MEDIUM LOW UNKNOWN", sevs, " ")
        for (i = 1; i <= n; i++) if (count[sevs[i]]) printf "    %-9s %d package(s)\n", sevs[i], count[sevs[i]]
        printf "\n  Affected packages:\n"
        printf "%s", lines
      }' | sed 's/^/  /'

  warning "$AFFECTED_PKGS package(s) in the closure have known CVEs (after whitelist)."

  # --explain: show the top-level dependency root that pulls each package in, so
  # the user knows what to remove (attack-surface reduction) vs accept. Only on
  # output-path scans (why-depends needs a realized closure, not a .drv).
  if [[ "$EXPLAIN" == true && "$IS_DRV" == false ]]; then
    echo ""
    info "Why each package is here (top-level dependent → remove it to drop the CVE):"
    # Resolve the runtime closure once; match each affected pname to its output
    # path, then ask why-depends for the shallowest owner. Every step is wrapped
    # so a no-match (grep exit 1) can't trip set -e / pipefail and abort the run.
    closure_paths="$(nix-store -qR "$SCAN_TARGET" 2>/dev/null || true)"
    while IFS= read -r pname; do
      [[ -z "$pname" ]] && continue
      outpath="$(printf '%s\n' "$closure_paths" | grep -E -- "-${pname}(\$|-)" | head -1 || true)"
      root=""
      if [[ -n "$outpath" ]]; then
        root="$( { NO_COLOR=1 nix why-depends "$SCAN_TARGET" "$outpath" 2>/dev/null \
          | grep -oE '[a-z0-9]{32}-[^/[:space:]]+' \
          | grep -vE 'system-path|darwin-system' \
          | head -1; } || true )"
        root="${root#*-}"   # drop the store hash, keep the package name
      fi
      printf "    %-26s ← %s\n" "$pname" "${root:-<unresolved>}"
    done < <(echo "$RESULT" | jq -r '.[].name')
  fi

  # ============================================
  # Remediation playbook — "I have CVEs, now what?"
  # ============================================
  echo ""
  echo -e "${BOLD}  How to remediate (Nix model — in priority order):${NC}"
  cat <<EOF
    1. UPDATE   \`update-nix\` pulls a newer nixpkgs; CVEs patched upstream since
                your lock disappear. Run \`secnext\` first to preview which ones
                actually clear (a recent lock fixes only a few).
    2. REMOVE   Most CVEs are TRANSITIVE deps of tools you installed. Re-run with
                --explain to see the top-level owner; drop unused ones from
                nix-config/modules/darwin/packages.nix to shrink attack surface.
    3. WHITELIST For triaged false-matches / unexploitable CVEs (many vim/jq/git
                ones need a crafted local file), add them to
                scripts/validation/vulnix-whitelist.toml with a dated reason.
    4. OVERRIDE (rare) Patch a single package via an overlay in
                nix-config/overlays/ when upstream hasn't fixed it yet.
    Downgrading is almost never the answer in Nix — prefer 1–4.
EOF
  [[ -z "$WHITELIST" ]] && info "No whitelist in effect — snapshot current matches: ${VULNIX[*]} -W vulnix-whitelist.toml -C $SCAN_TARGET"
fi

# ============================================
# Homebrew cask drift (manual-update → security relevance)
# ============================================
if [[ "$CHECK_BREW" == true ]] && command -v brew >/dev/null 2>&1; then
  echo ""
  info "Homebrew casks with pending updates (brew is manual-update here):"
  OUTDATED="$(brew outdated --cask --greedy --verbose 2>/dev/null || true)"
  if [[ -z "$OUTDATED" ]]; then
    success "All casks current."
  else
    echo "    ${OUTDATED//$'\n'/$'\n'    }"
    warning "Run 'brew upgrade --cask <name>' to apply security updates."
  fi
fi

# ============================================
# Exit code (0 clean · 2 findings under --strict · 1 could-not-run handled above)
# ============================================
if [[ "$STRICT" == true && "$AFFECTED_PKGS" -gt 0 ]]; then
  exit 2
fi
exit 0
