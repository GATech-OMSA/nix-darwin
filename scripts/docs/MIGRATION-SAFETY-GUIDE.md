# Homebrew → Nix Migration Safety Guide

**Script**: `scripts/migrate-homebrew-to-nix.sh`

---

## Quick Safety Summary

✅ **Data Loss Risk**: NONE (application data is separate from binaries)
✅ **Rollback Available**: Multiple layers (backups, git, nix-rollback)
✅ **Dry-Run First**: Required workflow, no surprises
✅ **No Auto-Uninstall**: You control when to remove Homebrew packages
✅ **GUI Apps Protected**: Casks (GUI apps) are never migrated

---

## Understanding Package Types

### Formula vs Cask

**FORMULAE** (CLI tools, libraries):
- Examples: `node`, `python`, `git`, `wget`, `jq`, `brotli`
- Installed to: `/opt/homebrew/bin/`, `/usr/local/bin/`
- **Migration**: ✅ SAFE - These work well in Nix
- **Data Risk**: NONE - No application data, config files are separate

**CASKS** (GUI applications):
- Examples: `docker`, `vscode`, `chrome`, `slack`, `obsidian`
- Installed to: `/Applications/`
- **Migration**: ❌ NOT RECOMMENDED - Keep in Homebrew
- **Script Behavior**: Automatically keeps casks in Homebrew

### How Homebrew Differentiates

```bash
# List formulae (CLI tools)
brew list --formula

# List casks (GUI apps)
brew list --cask

# Get info about a package
brew info node          # Formula
brew info --cask docker # Cask
```

---

## Safety Mechanisms

### 1. Dry-Run Mode (Layer 1)

**Purpose**: Preview changes without modifying anything

```bash
# Run dry-run FIRST (required)
./scripts/migrate-homebrew-to-nix.sh --dry-run
```

**What it does**:
- ✅ Scans Homebrew packages
- ✅ Categorizes CLI vs GUI
- ✅ Shows what WOULD be migrated
- ❌ Does NOT modify any files
- ❌ Does NOT uninstall anything

**Output**:
```
DRY RUN: Would add the following packages to packages.nix:
  • node
  • python3
  • git

DRY RUN: No changes were made
```

---

### 2. Automatic Backups (Layer 2)

**Created automatically** when you run migration (not dry-run):

```bash
modules/shared/packages.nix.backup
modules/darwin/homebrew.nix.backup
```

**Restore from backup**:
```bash
cp modules/shared/packages.nix.backup modules/shared/packages.nix
cp modules/darwin/homebrew.nix.backup modules/darwin/homebrew.nix
nix-rebuild
```

---

### 3. No Auto-Uninstall (Layer 3)

**Script does NOT run** `brew uninstall`!

**Why**: You need to verify Nix packages work first

**Safe workflow**:
1. Migrate to Nix (packages added to packages.nix)
2. Rebuild: `nix-rebuild`
3. Test Nix versions work
4. **THEN** manually uninstall Homebrew versions (optional)

**During testing**: Both Homebrew AND Nix versions are installed
- Nix packages in `/nix/store/`
- Homebrew packages still in `/opt/homebrew/`
- PATH priority determines which is used

---

### 4. Git Version Control (Layer 4)

**All changes are tracked**:

```bash
# Before migration - create checkpoint
git status
git add -A
git commit -m "Before Homebrew migration"

# After migration - review changes
git diff HEAD

# Rollback if needed
git reset --hard HEAD
```

**Modified files**:
- `modules/shared/packages.nix` - Packages added
- `modules/darwin/homebrew.nix` - Packages commented out

---

### 5. Nix Rollback (Layer 5)

**If nix-rebuild fails or system breaks**:

```bash
# Immediate rollback to previous working state
nix-rollback

# Or manually select generation
darwin-rebuild --list-generations
darwin-rebuild rollback --generation 42
```

---

## Data Loss Risk Analysis

### What Could Be Lost?

**NOTHING** ❌

### Why Not?

**Application binaries ≠ Application data**

**Binaries** (what Homebrew/Nix install):
- `/Applications/Docker.app` ← Homebrew cask
- `/opt/homebrew/bin/node` ← Homebrew formula
- `/nix/store/.../bin/node` ← Nix package

**Application Data** (NOT touched by migration):
- `~/.docker/` ← Docker settings
- `~/.npmrc` ← npm configuration
- `~/.gitconfig` ← Git configuration
- `~/Library/Application Support/` ← App settings
- `~/Documents/` ← Your files
- `~/Desktop/` ← Your files

**The script**:
- ✅ Only modifies Nix config files
- ❌ Does NOT touch `~/.anything`
- ❌ Does NOT touch `/Applications/`
- ❌ Does NOT delete user data

### What About Formulae Data?

**Most CLI tools have NO data**:
- Libraries (`brotli`, `zstd`, `lz4`) = No config, no data
- Compilers (`gcc`, `clang`) = No user data
- Utilities (`wget`, `curl`) = No persistent data

**Tools with config files**:
- `git` → `~/.gitconfig` (separate, not touched)
- `npm` → `~/.npmrc` (separate, not touched)
- `python` → `~/.pypirc` (separate, not touched)

**These config files work with ANY installation**:
- Homebrew's `git` reads `~/.gitconfig`
- Nix's `git` reads the SAME `~/.gitconfig`
- No data loss when switching

---

## Testing Procedure

### Phase 1: Safe Preview (No Changes)

```bash
# 1. Dry-run to see what would happen
./scripts/migrate-homebrew-to-nix.sh --dry-run

# 2. Review output carefully
# Look for:
#   • Which packages would be migrated
#   • Which packages would stay in Homebrew
#   • Any packages you rely on heavily

# 3. If output looks good, proceed to Phase 2
```

---

### Phase 2: Checkpoint & Migrate

```bash
# 1. Create git checkpoint
git status
git add -A
git commit -m "Before Homebrew migration"

# 2. Run migration (creates automatic backups)
./scripts/migrate-homebrew-to-nix.sh

# OR interactive mode to choose specific packages
./scripts/migrate-homebrew-to-nix.sh
# Answer y/n for each package

# 3. Review changes before rebuilding
git diff HEAD
cat modules/shared/packages.nix  # See what was added
```

---

### Phase 3: Build & Test

```bash
# 1. Rebuild Nix configuration
nix-rebuild

# 2. Check if build succeeded
echo $?  # Should be 0

# 3. Verify packages are available
which node
# Should show: /nix/store/.../bin/node

node --version
# Should work

# 4. Test a few more packages
which python3
python3 --version

which git
git --version

# 5. Reload shell (to pick up new paths)
exec zsh
```

---

### Phase 4: Verify or Rollback

**If everything works** ✅:

```bash
# 1. Commit changes
git add -A
git commit -m "Migrated Homebrew packages to Nix

Migrated CLI tools: node, python3, git, ...
Kept in Homebrew: docker, vscode (casks)"

# 2. Optionally uninstall Homebrew versions
brew uninstall node python3 git
# (Only after verifying Nix versions work!)
```

**If something breaks** ❌:

```bash
# Option 1: Nix rollback (fastest)
nix-rollback

# Option 2: Git rollback
git reset --hard HEAD

# Option 3: Restore from backups
cp modules/shared/packages.nix.backup modules/shared/packages.nix
cp modules/darwin/homebrew.nix.backup modules/darwin/homebrew.nix
nix-rebuild

# 4. Report issue (what broke?)
# Then we can fix the script or blacklist problematic packages
```

---

## Risk Levels by Package Type

### Low Risk (Safe to Migrate First)

**Compression/Archive**:
- `brotli`, `zstd`, `lz4`, `xz` - No data, just libraries

**Text Processing**:
- `jq`, `yq` - No config, stateless

**Download Tools**:
- `wget`, `curl` - Minimal config in `~/.wgetrc` (separate)

---

### Medium Risk (Test Carefully)

**Development Tools**:
- `node`, `python3`, `ruby` - Have npm/pip/gem configs (separate files)
- `git` - Uses `~/.gitconfig` (separate, safe)

**Why medium**: Active projects may depend on specific versions

**Mitigation**:
1. Check versions match: `brew info node` vs `nix search nixpkgs node`
2. Test in one project first
3. Keep Homebrew version until verified

---

### High Risk (Keep in Homebrew)

**System-Critical Tools**:
- Anything your job depends on daily
- Tools with complex setups

**Why high**: Breaking these impacts productivity

**Recommendation**: Migrate later, after confidence builds

---

### Never Migrate (Auto-Protected)

**GUI Applications (Casks)**:
- `docker`, `vscode`, `chrome`, `slack`, etc.

**Why**: macOS GUI apps don't work well via Nix

**Script behavior**: Automatically keeps all casks in Homebrew

---

## Troubleshooting

### Build Fails After Migration

```bash
# Error: "package 'X' not found"
# Cause: Package name differs in nixpkgs

# Solution 1: Find correct name
nix search nixpkgs X

# Solution 2: Rollback and try again
nix-rollback
# Edit packages.nix manually with correct name
nix-rebuild
```

---

### Package Doesn't Work

```bash
# Symptom: Command not found or wrong version

# Check which version is being used
which node
echo $PATH

# Reload shell
exec zsh

# Check Nix package installed
ls /nix/store/ | grep node

# If still broken: Use Homebrew version temporarily
brew reinstall node
```

---

### Want to Undo Migration

```bash
# Option 1: Git revert
git log  # Find commit hash
git revert <hash>
nix-rebuild

# Option 2: Manual restore
cp modules/shared/packages.nix.backup modules/shared/packages.nix
cp modules/darwin/homebrew.nix.backup modules/darwin/homebrew.nix
nix-rebuild

# Option 3: Reinstall via Homebrew
brew reinstall node python3 git
# Then remove from packages.nix manually
```

---

## FAQ

### Q: Will my data be lost?
**A**: No. Application data lives in `~/` directories, completely separate from binaries.

### Q: What if I need to rollback?
**A**: Multiple options: `nix-rollback`, git reset, restore from automatic backups.

### Q: Does the script uninstall Homebrew packages?
**A**: No! Script does NOT run `brew uninstall`. You control that step.

### Q: Can I test without risk?
**A**: Yes! Run `--dry-run` first to preview all changes. No modifications made.

### Q: What happens to my GUI apps?
**A**: Casks (GUI apps) are automatically kept in Homebrew. Never migrated.

### Q: Can I choose which packages to migrate?
**A**: Yes! Interactive mode lets you select y/n for each package.

### Q: What if a package breaks?
**A**: Keep Homebrew version installed during testing. Only uninstall after verifying Nix works.

### Q: How do I know if a package is in Nix?
**A**: Script uses heuristic (all formulae likely available). You can verify:
```bash
nix search nixpkgs package-name
```

---

## Summary: Why It's Safe

1. **Dry-run first** - Preview changes before making them
2. **Automatic backups** - Created before any modifications
3. **No auto-uninstall** - Homebrew packages stay until you remove them
4. **Git tracked** - Easy rollback via version control
5. **Nix generations** - System-level rollback capability
6. **Data separation** - Application data completely separate from binaries
7. **Cask protection** - GUI apps never migrated (script knows the difference)

**Bottom line**: Start with dry-run, test carefully, rollback is always available.
