# Supply Chain Security

How this system protects against dependency supply chain attacks — malicious packages,
compromised maintainer accounts, and hijacked CI pipelines.

---

## How It Works

```
Package published (potentially malicious)
        |
  [7-day quarantine]  ← npm min-release-age, uv exclude-newer
        |
  Community detects & removes bad packages
        |
  Safe package available for install
```

- **npm/Node**: 7-day quarantine via `min-release-age=7` in `~/.npmrc`
- **uv/Python**: 7-day quarantine via `exclude-newer = "7 days"` in `~/.config/uv/uv.toml`
- **Nix**: Inherently protected — `flake.lock` pins all inputs to exact git SHAs, hermetic sandboxed builds with no network access
- **Homebrew**: Manual updates only — no auto-upgrade on rebuild
- **GitHub Actions**: Pinned to commit SHAs, not mutable tags
- **direnv**: Explicit per-project allow, no blanket whitelist

---

## Protections by Layer

### Package Managers (Age-Gating)

| Manager | Protection | Config File |
|---------|-----------|-------------|
| **npm** | `min-release-age=7` — rejects packages < 7 days old | `nix-config/home/_profiles/_template/programs/node.nix` |
| **uv** | `exclude-newer = "7 days"` — same quarantine for Python | `nix-config/home/_template/development/python.nix` |
| **Nix** | `flake.lock` pins exact revisions; hermetic builds | `flake.nix` + `flake.lock` |
| **Go** | Sum database (`sum.golang.org`) verifies module integrity | Built-in to Go toolchain |
| **Homebrew** | No age-gate; mitigated by disabling auto-upgrade | `nix-config/modules/darwin/homebrew.nix` |

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
