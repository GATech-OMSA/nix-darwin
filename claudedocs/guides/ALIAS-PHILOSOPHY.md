# Alias Naming Philosophy

**Purpose**: Consistent, discoverable, safe alias system
**Status**: Implemented

---

## Core Principles

1. **Consistency** - One predictable pattern per category
2. **Discoverability** - Tab-completion reveals related operations
3. **Safety** - Dangerous operations use descriptive names (3+ chars)
4. **Muscle Memory** - Frequency determines length

---

## Tier 0: Umbrella dispatchers (discoverable entry points)

**Status**: Implemented — zsh functions in
`nix-config/home/_profiles/_template/shell/functions/dispatch.zsh`.

**Pattern**: Five top-level verbs, each a bare command with an obvious default
action plus subcommands for everything else. Tiers 1-5 below still exist for
muscle memory — Tier 0 exists so a new user (or a rusty one) can type a plain
English verb and get somewhere useful without memorizing the tier system.

| Verb | Bare behavior | Subcommands |
|------|---------------|--------------|
| `update` | `update-all` | `nix`, `brew`, `vscode`, `mas`, `dev`, `system` |
| `clean` | `cleanup-standard` | `quick`, `safe`, `dev`, `aggressive`, `nix`, `docker`, `python`, `deep` |
| `secrets` | status | `edit`, `view`, `deploy`, `rescan`, `audit`, `backup` |
| `status` | health check | `secrets`, `git` |
| `fix` | menu | `rollback`, `rebuild`, `rebuild-force` |

Frame it as: Tier 0 is what you type when you don't remember the tier-3/4
name; the longer forms remain available (and faster once memorized).

---

## Five-Tier System

### Tier 1: Ultra-frequent tools (1 char)
**Usage**: 20+ times daily
**Pattern**: Single letter for tool launcher

| Alias | Command |
|-------|---------|
| `g` | git |
| `d` | docker |
| `k` | kubectl |
| `c` | clear |
| `f` | open . (Finder) |

---

### Tier 2: Frequent operations (tool + action)
**Usage**: 5-20 times daily
**Pattern**: tool-letter + action-abbrev
**Safety**: 3+ chars MINIMUM for dangerous operations

| Alias | Command | Notes |
|-------|---------|-------|
| `gs` | git status | safe, 2 chars OK |
| `ga` | git add | safe, 2 chars OK |
| `dps` | docker ps | safe, 3 chars |
| `dc` | docker compose | safe, 2 chars |
| `ll` | eza -al | safe, 2 chars |
| `lt` | eza --tree | safe, 2 chars |

---

### Tier 3: Domain operations (domain-action)
**Usage**: Weekly/monthly
**Pattern**: full-domain + full-action
**Tab-complete benefit**: Type domain + TAB shows all related operations

**Nix operations** (`nix-` + TAB):
```
nix-rebuild            # System rebuild with pre-flight checks
nix-rebuild-skip-checks # Emergency rebuild
nix-rebuild-debug      # Verbose rebuild
nix-check              # Validate configuration
nix-health             # System health check
nix-rollback           # Rollback to previous generation
nix-config-diff        # Compare generations
nix-config-diff-packages # Package changes only
nix-preflight          # Run pre-flight checks manually
nix-verify-backups     # Verify backup integrity
nix-brew-audit         # Check Homebrew apps for Nix alternatives
nix-scaffold-machine   # Create new machine config from template
```

**Secrets operations** (`secrets-` + TAB):
```
secrets-edit           # Edit encrypted secrets with SOPS
secrets-deploy         # Decrypt and deploy to target paths
respin         # Re-source secrets in current shell
secrets-view           # View decrypted secrets (read-only)
secrets-rescan         # Discover unmanaged secrets (read-only)
secrets-status         # Show age key, encryption, deployed files
secrets-backup         # Backup secrets.yaml
secrets-audit          # Scan for plaintext credential exposure
secrets-local edit     # Edit ~/.zsh_secrets.local (gitignored testing overrides) (also: e)
secrets-local add      # Set one var: secrets-local add VAR value (also: set)
secrets-local unset    # Remove one var (also: rm-key/delete-key/remove-key)
secrets-local show     # Print ~/.zsh_secrets.local contents (also: s/cat)
secrets-local rm       # Delete ~/.zsh_secrets.local (also: delete/remove)
secrets-local path     # Show file location (also: location)
secrets-local help     # Usage + workflow (also: h, or bare secrets-local)
sec                    # Short alias for secrets-local
```

**Cleanup operations** (`cleanup-` + TAB):
```
cleanup                # Standard cleanup (alias for cleanup-standard)
clean                  # Quick cleanup (alias for cleanup-quick)
cleanup-safe           # Logs/temp only
cleanup-quick          # Safe + brew cleanup
cleanup-standard       # Quick + Docker prune + Nix GC
cleanup-dev            # Standard + dev artifacts
cleanup-aggressive     # Deep clean (requires confirmation)
cleanup-nix            # Nix generations only
cleanup-docker         # Docker cleanup only
cleanup-python         # Python cache cleanup only
system-cleanup         # Interactive guided cleanup script
```

**Update operations** (`update-` + TAB):
```
update-nix             # Flake update + security pre-flight + darwin-rebuild switch
update-brew            # brew update + upgrade + greedy cask upgrade + cleanup + doctor
update-vscode          # Reinstall (force-update) all installed VS Code extensions
update-mas             # mas upgrade (Mac App Store apps)
update-dev             # update-nix + update-vscode (quick dev-loop update)
update-system          # update-nix + update-brew
update-all             # update-nix + update-brew + update-vscode + update-mas
                        # + macOS softwareupdate --list (full sweep)
```
Defined in `nix-config/home/_profiles/_template/shell/functions/update.zsh`.

---

### Tier 4: Abbreviated domain (letter-action)
**Usage**: Occasional operations for non-primary tools
**Pattern**: unique-letter + full-action

**Micromamba** (`m-` + TAB):
```
m-act <env>            # Activate environment
m-create <name>        # Create new environment
m-list                 # List environments
m-install <pkg>        # Install package
m-remove <pkg>         # Remove package
m-deact                # Deactivate current environment
```

**Claude Code** (`cc` + TAB):
```
cc                     # claude
ccr                    # claude --resume
ccc                    # claude --continue
cca                    # claude --add-dir
ccw                    # claude -w
ccwt                   # claude -w --tmux
ccq                    # claude --bare -p  (query/pipe mode)
ccs                    # claude --model sonnet
ccm                    # claude --effort max

# Dangerous variants — ! suffix signals skip-permissions
cc!                    # claude --dangerously-skip-permissions
ccr!                   # claude --dangerously-skip-permissions --resume
ccc!                   # claude --dangerously-skip-permissions --continue
```
Note: `!` suffix is a deliberate exception to the "short = safe" rule.
The `!` is a universally understood danger signal (shell/markdown convention).
Defined in `~/.zshrc.local` — no rebuild needed to change.

---

### Tier 5: Navigation
**Pattern**: Two separate patterns for different operations

**CD operations** (simple words):
```
dev, down, desk, docs, apps, downloads, desktop
```

**Finder operations** (`f` + target):
```
fdev, fdown, fdesk, fdocs
```

---

## Safety Rules

### Dangerous operations MUST be descriptive (3+ chars minimum)

**Dangerous Git Operations** (in git.nix):

| Alias | Command | Chars |
|-------|---------|-------|
| `discard` | checkout . -- | 7 |
| `clean-untracked` | clean -df | 15 |
| `unstage-all` | reset HEAD | 11 |
| `undo` | reset HEAD~1 --mixed | 4 |
| `wipe` | nuclear reset to last commit | 4 |

**Dangerous System Operations**:

| Alias | Action | Chars |
|-------|--------|-------|
| `nix-rebuild` | System rebuild | 11 |
| `nix-rollback` | Rollback generation | 12 |
| `cleanup-aggressive` | Deep clean | 20 |

**Principle**: If it's short, it's safe. If it's dangerous, it's descriptive.

---

## Modern CLI Replacements

These aliases map modern tools over standard Unix commands:

| Alias | Modern Tool | Replaces |
|-------|------------|----------|
| `ls` | eza | ls |
| `ll` | eza -al | ls -la |
| `cat` | bat | cat |
| `du` | dust | du |
| `df` | duf | df |
| `top` | btop | top/htop |

`grep` and `find` are **deliberately NOT aliased** to `rg`/`fd` — those tools
take different syntax (not just different output), so overriding the builtins
would silently break `grep -rn ...` / `find . -name ...` muscle memory. Use
`rg`/`fd` by their own names when you want them; `rgi` is a short alias for
`rg -i`.

---

## Source Files

| File | What it defines |
|------|----------------|
| `nix-config/home/_profiles/_template/shell/zsh.nix` | All shell aliases (shellAliases block) |
| `nix-config/home/_profiles/_template/programs/git.nix` | Git aliases (g prefix) |
| `nix-config/home/_profiles/personal/aliases.nix` | Personal-only aliases |
| `nix-config/home/_profiles/work/aliases.nix` | Work-only aliases |
| `~/.zshrc.local` | Claude Code aliases + local config shortcuts (not Nix-managed) |

---

**Last Updated**: 2026-03-15
