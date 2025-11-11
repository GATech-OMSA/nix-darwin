# Alias Naming Philosophy

**Created**: 2025-11-10
**Purpose**: Consistent, discoverable, safe alias system
**Status**: Implemented ✅

---

## 🎯 Core Principles

1. **Consistency** - One predictable pattern per category
2. **Discoverability** - Tab-completion reveals related operations
3. **Safety** - Dangerous operations use descriptive names (3+ chars)
4. **Muscle Memory** - Frequency determines length

---

## 📊 Five-Tier System

### Tier 1: Ultra-frequent tools (1 char)
**Usage**: 20+ times daily
**Pattern**: Single letter for tool launcher
**Safety**: Tool launchers only, not destructive actions

**Examples**:
- `g` = git
- `d` = docker
- `k` = kubectl
- `c` = clear
- `f` = open . (Finder)

**Rationale**: Most frequent operations deserve shortest names. These launch tools but don't perform destructive actions themselves.

---

### Tier 2: Frequent operations (tool + action)
**Usage**: 5-20 times daily
**Pattern**: tool-letter + action-abbrev
**Safety**: 3+ chars MINIMUM for dangerous operations

**Examples**:
- ✅ `gs` = git status (safe, 2 chars OK)
- ✅ `ga` = git add (safe, 2 chars OK)
- ✅ `dps` = docker ps (safe, 3 chars)
- ✅ `gdel` = git branch delete (dangerous, 4 chars) ✅
- ❌ `gd` = delete branch (dangerous, 2 chars) ❌

**Rationale**: Frequent tool operations can be abbreviated, but SAFETY FIRST - dangerous operations must be obvious.

---

### Tier 3: Domain operations (domain-action)
**Usage**: Weekly/monthly
**Pattern**: full-domain + full-action
**Tab-complete benefit**: Type domain + TAB shows all related operations

**Examples**:
```bash
# Nix operations (type "nix-" + TAB)
nix-rebuild       # System rebuild
nix-check         # Validate configuration
nix-health        # Health check
nix-rollback      # Rollback to previous generation
nix-config-diff   # Compare generations

# Secret operations (type "secret-" + TAB)
secret-edit       # Edit encrypted secrets
secret-view       # View decrypted secrets
secret-backup     # Backup secrets
secret-audit      # Audit secret locations
secret-rescan     # Rescan for secrets

# AWS operations (type "aws-" + TAB)
aws-login         # SSO login
aws-switch        # Switch profile
aws-validate      # Validate configuration
```

**Rationale**:
- **Namespace grouping** - All related operations discoverable via tab-complete
- **Full descriptive names** - Clear intent, no ambiguity
- **Consistency** - Always domain-action, never action-domain

**Why domain-action vs action-domain?**
- ✅ `secret-edit` groups all secret operations together
- ❌ `edit-secret` scatters operations across alphabet

---

### Tier 4: Abbreviated domain (letter-action)
**Usage**: Occasional operations for non-primary tools
**Pattern**: unique-letter + full-action
**Constraint**: Only if letter not already taken

**Examples**:
```bash
# Micromamba operations (type "m-" + TAB)
m-act             # micromamba activate
m-create          # micromamba create
m-list            # micromamba env list
m-install         # micromamba install
m-remove          # micromamba remove
m-deact           # micromamba deactivate
```

**Rationale**:
- Shorter than full `micromamba-` prefix
- Still discoverable via tab-complete
- Actions are full words for clarity

**Available single letters**: m, w, x (others taken by Tier 1)

---

### Tier 5: Navigation
**Pattern**: Two separate patterns for different operations

**CD Operations (simple words)**:
```bash
dev               # cd ~/Dev
downloads         # cd ~/Downloads
desktop           # cd ~/Desktop
docs              # cd ~/Documents
down              # cd ~/Downloads (shorter)
desk              # cd ~/Desktop (shorter)
```

**Finder Operations (f + target)**:
```bash
fdev              # open ~/Dev in Finder
fdown             # open ~/Downloads in Finder
fdesk             # open ~/Desktop in Finder
fdocs             # open ~/Documents in Finder
```

**Rationale**:
- Both operations available for same location
- Simple words for frequent CD operations
- `f` prefix clearly indicates Finder opening

---

## 🔒 Safety Rules

### Dangerous Operations MUST Be Descriptive (3+ chars minimum)

**Dangerous Git Operations**:
- ✅ `discard` = checkout . -- (discards ALL changes) - 7 chars ✅
- ✅ `clean-untracked` = clean -df (removes untracked files) - 14 chars ✅
- ✅ `unstage-all` = reset HEAD (unstages everything) - 11 chars ✅
- ✅ `undo` = reset HEAD~1 (undoes last commit) - 4 chars ✅
- ✅ `wipe` = nuclear reset - 4 chars, VERY descriptive name ✅
- ❌ `cod` = checkout . -- (unclear abbreviation) ❌
- ❌ `cdf` = clean -df (looks like 'cd f') ❌
- ❌ `rh` = reset HEAD (too cryptic) ❌

**Dangerous System Operations**:
- ✅ `nix-rebuild` = system rebuild (11 chars) ✅
- ✅ `nix-rollback` = rollback to previous generation (12 chars) ✅
- ❌ `rb` = rebuild (too short for system-wide changes) ❌

**Why This Matters**:
- Prevents accidental execution from typos
- Makes aliases self-documenting
- Reduces risk of data loss
- Muscle memory safety - if it's short, it's probably safe

---

## 📋 Tab-Completion Examples

### Before (Inconsistent)
```bash
secret<TAB>       # Nothing (have to know 'edit-s' or 'view-s')
health<TAB>       # Shows: health-check (orphaned, not grouped)
```

### After (Namespace Grouping)
```bash
nix-<TAB>         # Shows: nix-rebuild, nix-check, nix-health, nix-rollback, etc.
secret-<TAB>      # Shows: secret-edit, secret-view, secret-backup, secret-audit
m-<TAB>           # Shows: m-act, m-create, m-list, m-install, m-remove
f<TAB>            # Shows: f, fdev, fdown, fdesk, fdocs, finder
```

---

## 🔄 Migration Guide

### Renamed Aliases (Old → New)

**Secret Management**:
- `edit-secrets` → `secret-edit`
- `view-secrets` → `secret-view`
- `backup-secrets` → `secret-backup`
- `rescan-secrets` → `secret-rescan`

**System Management**:
- `health-check` → `nix-health-check` (or `nix-health`)
- `system-health` → `nix-health`
- `config-diff` → `nix-config-diff`
- `config-diff-packages` → `nix-config-diff-packages`
- `config-diff-verbose` → `nix-config-diff-verbose`
- `home-rebuild-force` → `nix-home-rebuild-force`
- `scaffold-machine` → `nix-scaffold-machine`
- `new-machine` → `nix-new-machine`

**Git Safety**:
- `cod` → `discard`
- `cdf` → `clean-untracked`
- `rh` → `unstage-all`

**Micromamba**:
- `list-envs` → `m-list`
- `lsenv` → `m-list`
- `mambalist` → `m-list`

### Removed Aliases

**Test Suite** (use full scripts/paths for development):
- ❌ `test-all`, `test-build`, `test-security`, `test-lib`, `test-integration`, `test-quick`, `test-verbose`

**Short Nix Development** (use full commands for clarity):
- ❌ `ns` → use `nix-shell`
- ❌ `nd` → use `nix develop`
- ❌ `nb` → use `nix build`
- ❌ `nf` → use `nix flake`

**Rationale**: These are infrequent developer operations where full commands are clearer.

---

## ✅ Implementation Checklist

### Files Modified:
- [x] `nix-config/home/_profiles/_template/shell/zsh.nix`
  - [x] Renamed secret-* to domain-action pattern
  - [x] Added nix- prefix to system aliases
  - [x] Removed test suite aliases
  - [x] Removed short nix dev aliases (ns, nd, nb, nf)
  - [x] Added micromamba tier-4 aliases (m-*)
  - [x] Removed old micromamba aliases
  - [x] Added Finder navigation aliases (fdev, fdown, fdesk, fdocs)
  - [x] Added secret-audit and nix-verify-backups

- [x] `nix-config/home/_profiles/_template/programs/git.nix`
  - [x] Renamed dangerous aliases: cod→discard, cdf→clean-untracked, rh→unstage-all

### Documentation:
- [x] Created this philosophy document
- [ ] Updated my-aliases-complete.md with new aliases
- [ ] Run nix-rebuild to apply changes

---

## 📚 Quick Reference by Category

### System Management (nix-*)
```bash
nix-rebuild               # Full rebuild with checks
nix-check                 # Validate without building
nix-health                # System health check
nix-rollback              # Rollback to previous generation
nix-config-diff           # Compare generations
nix-scaffold-machine      # Create new machine config
nix-verify-backups        # Verify backup integrity
```

### Secret Management (secret-*)
```bash
secret-edit               # Edit encrypted secrets with SOPS
secret-view               # View decrypted secrets
secret-backup             # Backup all secrets
secret-audit              # Audit secret locations
secret-rescan             # Rescan for untracked secrets
```

### Micromamba (m-*)
```bash
m-act <env>               # Activate environment (function with usage help)
m-create <name>           # Create new environment
m-list                    # List environments
m-install <pkg>           # Install package
m-remove <pkg>            # Remove package
m-deact                   # Deactivate current environment (function)
```

**Note**: `m-act` and `m-deact` use functions (not aliases) to provide usage help when called without arguments.

### Navigation
```bash
# CD operations
dev, down, desk, docs     # cd to common directories

# Finder operations
fdev, fdown, fdesk, fdocs # Open in Finder
```

### Git Operations
```bash
# Safe shortcuts (Tier 2)
gs, ga, gc, gp, gl        # status, add, commit, push, log

# Dangerous operations (descriptive names)
discard                   # Discard all changes (⚠️ dangerous)
clean-untracked           # Remove all untracked files (⚠️ dangerous)
unstage-all               # Unstage everything (⚠️ dangerous)
```

---

## 🎓 Learning the System

### For Existing Users:
1. Run `nix-rebuild && exec zsh` to load new aliases
2. Use tab-completion to discover renamed aliases:
   - Type `secret-` + TAB to find secret operations
   - Type `nix-` + TAB to find system operations
   - Type `m-` + TAB to find micromamba operations
3. Old aliases will fail with "command not found" - use error as reminder to learn new pattern

### For New Users:
1. Learn tier system: ultra-frequent (1 char) → frequent (2-3 chars) → domain operations (full words)
2. Remember: If it's dangerous, it's descriptive (3+ chars minimum)
3. Use tab-completion as discovery tool - type prefix + TAB to see all related operations

---

## 🚀 Benefits Achieved

1. ✅ **Second Nature** - Predictable patterns enable muscle memory
2. ✅ **Quick Discovery** - Tab-completion by namespace groups related operations
3. ✅ **Safe by Design** - Dangerous operations are always obvious
4. ✅ **Consistent** - One philosophy throughout, not a mixed bag
5. ✅ **Scalable** - Easy to add new aliases following established tiers

---

**Version**: 1.0
**Status**: Implemented and Active
**Last Updated**: 2025-11-10
