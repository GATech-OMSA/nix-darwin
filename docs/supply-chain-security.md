# Supply Chain Security

How this system protects against dependency supply chain attacks — malicious packages,
compromised maintainer accounts, and hijacked CI pipelines.

---

## How It Works

```
Package published (potentially malicious)
        |
  [14-day quarantine]  ← npm min-release-age, uv exclude-newer
        |
  Community detects & removes bad packages
        |
  Safe package available for install
```

- **npm/Node**: 14-day quarantine via `min-release-age=14` in `~/.npmrc`
- **uv/Python**: 14-day quarantine via `exclude-newer = "14 days"` in `~/.config/uv/uv.toml`
- **Nix**: Inherently protected — `flake.lock` pins all inputs to exact git SHAs, hermetic sandboxed builds with no network access
- **Homebrew**: Manual updates only — no auto-upgrade on rebuild; `HOMEBREW_NO_INSECURE_REDIRECT` / `NO_ANALYTICS` / `NO_AUTO_UPDATE`; third-party taps must be trusted (`buo/cask-upgrade` removed in favor of built-in `brew upgrade --greedy`)
- **GitHub Actions**: Pinned to commit SHAs, not mutable tags
- **direnv**: Explicit per-project allow, no blanket whitelist

> The 14-day window (widened from 7) trades faster security patches for more time to catch
> malicious releases. For an urgent CVE fix that's newer than the window, override per-command
> (npm `--before`, uv `--exclude-newer <date>`).

### CVE visibility — `secnow` (installed) / `secnext` (candidate)

Quarantine blocks *fresh* malicious uploads; it does nothing about *known* CVEs already in your
closure. Two commands close that gap:

- **`secnow`** — CVE scan of what's installed now (`vulnix` over `/run/current-system`).
  `secnow --explain` shows the top-level package that pulls each CVE in (what to remove).
- **`secnext`** — scans what *would* be installed before you switch: builds the candidate
  closure (no activation), diffs it against the running system, and prompts on findings.

`secnext` runs automatically before `nix-rebuild`, `update nix`, and the other `update`
subcommands. A failed/offline scan never blocks a rebuild (it warns and proceeds). Bypass with
`SKIP_SECURITY_PREFLIGHT=1` or `nix-rebuild-skip-checks`. Remediation in a Nix system, in order:
update (`update nix`), remove unused owners (`secnow --explain`), whitelist triaged
false-matches (`scripts/validation/vulnix-whitelist.toml`), or overlay-patch (rare).

### Walkthrough

```bash
# 1. See what's vulnerable right now (first run downloads NVD data, ~1 min)
secnow

# 2. For each flagged package, find the top-level tool that drags it in
secnow --explain            # e.g. "libheif ← imagemagick", "unbound ← yazi"

# 3a. Don't need that tool? Comment it out of packages.nix / profile, then:
nix-rebuild                 # secnext gates the switch automatically

# 3b. Need it (or it's an unexploitable/essential lib)? Whitelist with a reason:
#     edit scripts/validation/vulnix-whitelist.toml — add:
#       ["openssl-3.6.2"]
#       cve = [ "CVE-2026-..." ]
#     (version-pinned key auto-expires the entry on the next nixpkgs bump)

# 4. Preview the security impact of an update WITHOUT downloading everything:
secnext --fast              # eval-only; note: BUILD closure (noisier superset)

# 5. Routine: just rebuild/update — the gate runs itself
nix-rebuild                 # builds candidate → diff → scan → switch if clean,
                            # prompts [y/N] if new CVEs appear
```

**Reading `secnow` output:** packages are bucketed CRITICAL → HIGH → MEDIUM → LOW by max
CVSS, with a CVE count and the highest score per package, followed by the remediation playbook.
A clean closure prints "No known CVEs … Excellent."

**Exit codes** (for scripting / the gate): `0` clean · `2` findings (with `--strict`) ·
`1` could-not-run (missing tool / offline NVD).

---

## Protections by Layer

### Package Managers (Age-Gating)

| Manager | Protection | Config File |
|---------|-----------|-------------|
| **npm** | `min-release-age=14` — rejects packages < 14 days old | `nix-config/home/_profiles/_template/programs/node.nix` |
| **uv** | `exclude-newer = "14 days"` — same quarantine for Python | `nix-config/home/_template/development/python.nix` |
| **Nix** | `flake.lock` pins exact revisions; hermetic builds | `flake.nix` + `flake.lock` |
| **Go** | Sum database (`sum.golang.org`) verifies module integrity; **disabled on work profile** (`GOSUMDB=off`) when corporate proxy is enabled — proxy provides its own integrity checks | Built-in to Go toolchain; proxy override in `work/default.nix` |
| **Homebrew** | No age-gate; mitigated by manual-update + `HOMEBREW_NO_INSECURE_REDIRECT` / `NO_ANALYTICS` / `NO_AUTO_UPDATE`; tap-trust enforced (no untrusted third-party taps); cask drift surfaced by `secnow` | `nix-config/modules/darwin/homebrew.nix` |

### CI/CD Pipeline

GitHub Actions are pinned to **commit SHAs** (not tags or branches) in `.github/workflows/ci.yml`:

```yaml
- uses: actions/checkout@<sha>                              # not @v4
- uses: DeterminateSystems/determinate-nix-action@<sha>     # not @v3
- uses: DeterminateSystems/magic-nix-cache-action@<sha>     # not @main
```

**Why:** Tags are mutable — they can be force-pushed. A compromised upstream repo could
redirect `@v4` to malicious code. SHAs are immutable.

**Updating:** When updating action versions, look up the new SHA:
```bash
gh api repos/actions/checkout/git/ref/tags/v4 --jq '.object.sha'
```

### Development Environment (direnv)

direnv requires **explicit opt-in** per project:

```toml
# ~/.config/direnv/direnv.toml
[global]
load_dotenv = false    # Don't auto-load .env files
strict_env = true      # Strict variable handling
# No [whitelist] — every project needs `direnv allow`
```

**Why:** A malicious repo with a crafted `.envrc` could execute arbitrary code
the moment you `cd` into it. Requiring `direnv allow` forces you to review first.

**Workflow:**
```bash
cd ~/Dev/new-project
# direnv: error .envrc is blocked. Run `direnv allow` to approve.
cat .envrc                    # Review it first
direnv allow                  # One-time approval
```

### Homebrew (GUI Apps)

```nix
# homebrew.nix
onActivation = {
  autoUpdate = false;   # Don't pull latest formulae on rebuild
  upgrade = false;      # Don't auto-upgrade casks
};
```

**Why:** Every `nix-rebuild` was blindly upgrading all GUI apps. If a Homebrew cask
was compromised, it would be pulled in automatically with zero delay.

**Workflow:**
```bash
brew update                   # Fetch latest formulae when ready
brew upgrade                  # Upgrade apps after reviewing changes
brew upgrade --cask slack     # Or upgrade specific apps
```

---

## What Nix Already Provides

Nix is inherently strong against supply chain attacks:

- **`flake.lock`** — Pins every input (nixpkgs, home-manager, sops-nix) to an exact git commit SHA
- **Hermetic builds** — Build sandbox has no network access; can't fetch malicious code at build time
- **Content-addressed store** — Every package identified by hash of all inputs; tampering changes the hash
- **Reproducibility** — Same inputs always produce same output
- **Explicit updates** — You control when `nix flake update` runs

---

## Remaining Risks & Mitigations

| Risk | Status | Mitigation |
|------|--------|------------|
| `nixpkgs-unstable` has faster package churn | Accepted | `flake.lock` protects between updates; review `nix flake update` diffs |
| `trusted-users` includes your account | Accepted | Needed for substituter workflows; monitor for unauthorized cache additions |
| GOSUMDB disabled behind corporate proxy | Work profile only | Corporate proxy provides its own integrity checks |
| VS Code extensions unmanaged | Accepted | Extensions from marketplace; consider periodic review |
| Homebrew third-party taps | Low risk | Only 2 taps (`buo/cask-upgrade`, `anomalyco/tap`); review before adding more |

---

## Quick Reference

| Task | Command |
|------|---------|
| Update Homebrew apps | `brew update && brew upgrade` |
| Update Nix inputs | `nix flake update` (review `flake.lock` diff) |
| Allow direnv for a project | `direnv allow` (after reviewing `.envrc`) |
| Update CI action SHAs | `gh api repos/OWNER/REPO/git/ref/tags/TAG --jq '.object.sha'` |
| Check npm quarantine | `npm config get min-release-age` |
| Check uv quarantine | `cat ~/.config/uv/uv.toml` |
