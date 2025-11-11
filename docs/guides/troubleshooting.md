# Troubleshooting Guide

**Fix common issues quickly**

[← Back to Index](../index.md)

---

## Quick Symptom Finder

| Symptom | Quick Fix | Section |
|---------|-----------|---------|
| Command not found | `nix-rebuild && exec zsh` | [Shell Issues](#shell-issues) |
| Build fails | `nix-rollback` | [Build Errors](#build-errors) |
| Need debug info | `nix-rebuild-debug` | [Debugging](#debugging-with-verbose-output) |
| **Changes don't apply** | `exec zsh` | [Silent Failures](#silent-failures) |
| **Package added but missing** | `nix-rebuild` | [Silent Failures](#package-added-but-command-not-found) |
| Git aliases broken | Use `g` prefix: `g s` | [Git Problems](#git-problems) |
| Commit blocked by hook | `chmod 600 <file>` or encrypt | [Git Problems](#git-problems), [Security](#permission--security-issues) |
| Slow shell | Check plugins | [Performance](#performance-problems) |
| Secrets won't decrypt | Check age key | [Secrets Issues](#secrets-issues) |
| Python venv not working | Re-enter directory | [Python Issues](#python-issues) |
| Tests failing | `test-quick` then fix | [Test Failures](#test-failures) |
| Permission audit failed | `audit-permissions --fix` | [Security](#permission--security-issues) |
| Commit blocked (syntax) | `nix flake check --show-trace` | [Build Validation](#build-validation-problems) |
| Wrong machine settings | Check `hostname` & `$MACHINE_MODE` | [Multi-Machine](#multi-machine-configuration-issues) |

---

## Decision Tree

```
Problem? Start here:

┌─ Did you just rebuild?
│  ├─ Yes → Try: exec zsh
│  │  ├─ Fixed? → Done!
│  │  └─ Still broken? → nix-rollback
│  │
│  └─ No → Did you change config?
│     ├─ Yes → nix-rebuild
│     └─ No → Check specific issue below
│
└─ Emergency? → See Emergency Recovery
```

---

## Table of Contents

1. [Quick Fixes](#quick-fixes)
2. [Silent Failures](#silent-failures)
3. [Build Errors](#build-errors)
4. [Shell Issues](#shell-issues)
5. [Git Problems](#git-problems)
6. [Python Issues](#python-issues)
7. [Secrets Issues](#secrets-issues)
8. [Performance Problems](#performance-problems)
9. [Test Failures](#test-failures)
10. [Permission & Security Issues](#permission--security-issues)
11. [Build Validation Problems](#build-validation-problems)
12. [Multi-Machine Configuration Issues](#multi-machine-configuration-issues)
13. [Emergency Recovery](#emergency-recovery)

---

## Quick Fixes

### Try These First (90% of issues)

```bash
# 1. Restart shell
exec zsh

# 2. Rebuild system
nix-rebuild

# 3. If rebuild fails, rollback
nix-rollback
exec zsh

# 4. If still broken, reboot
sudo reboot
```

### Quick Diagnostics

```bash
# Check system status
hostname                    # Should be mbp-jimmy or mbp-work
echo $MACHINE_MODE          # Should be home or work
nix --version              # Check Nix installed

# Check last build
darwin-rebuild --list-generations

# Check for errors
darwin-rebuild switch --flake . --show-trace
```

---

## Silent Failures

**When operations appear to succeed but changes don't take effect**

These are the most frustrating issues - no error messages, but your changes simply don't work. The system "lies" to you by appearing to succeed.

### Understanding Silent Failures

**What are silent failures?**
- Build completes successfully ✅
- No error messages shown ✅
- But your changes don't actually work ❌

**Why do they happen?**
- Shell needs restart to load new config
- Package installed but not in current PATH
- Git config cached in memory
- Secrets not exported to environment
- Homebrew cask needs manual intervention

**General fix pattern:**
```bash
# 1. Make change
# 2. Rebuild
nix-rebuild
# 3. Restart shell (CRITICAL!)
exec zsh
# 4. Test the change
```

---

### Config Changes Not Applied

**Symptom:**
- Changed `zsh.nix` to add alias `myalias="echo test"`
- Ran `nix-rebuild` - succeeded ✅
- Type `myalias` - "command not found" ❌

**Why it happens:**
- Nix rebuilds system files
- But your current shell still has OLD config in memory
- Shell needs restart to reload `~/.zshrc`

**Solution:**
```bash
# After ANY config change, ALWAYS restart shell
exec zsh

# Or reload zshrc manually (less reliable)
source ~/.zshrc

# Verify change applied
alias myalias
```

**Prevention:**
```bash
# Make this your standard workflow
nix-rebuild && exec zsh

# Or use the pattern
nixconf              # Edit config
nix-rebuild          # Build
exec zsh             # Restart shell
myalias              # Test it works
g aa && g cm "..." && g ps  # Commit
```

**Examples affected:**
- ✅ Shell aliases (zsh.nix)
- ✅ Git aliases (git.nix)
- ✅ Environment variables (zsh.nix)
- ✅ Shell functions (zsh.nix)
- ✅ Starship prompt changes (base.nix)

---

### Package Added But Command Not Found

**Symptom:**
- Added `ripgrep` to `packages.nix`
- Ran `nix-rebuild` - succeeded ✅
- Type `rg` - "command not found" ❌

**Why it happens:**
- Package installed to `/nix/store/...`
- But current shell's PATH still has old value
- Need to restart shell to get updated PATH

**Solution:**
```bash
# Restart shell to reload PATH
exec zsh

# Verify package installed
which rg
# Should show: /nix/store/.../bin/rg

# Test it works
rg --version
```

**Prevention:**
```bash
# Standard workflow when adding packages
code modules/shared/packages.nix   # Add package
nix-rebuild                         # Install it
exec zsh                            # Load new PATH
which newcommand                    # Verify
newcommand --help                   # Test
```

**Common mistakes:**
```bash
# ❌ Wrong: Forgot exec zsh
add package → nix-rebuild → test command → fails

# ✅ Right: Include exec zsh
add package → nix-rebuild → exec zsh → test command → works
```

---

### Git Aliases Don't Work

**Symptom:**
- Changed `git.nix` to add alias
- Ran `nix-rebuild` - succeeded ✅
- Type `g myalias` - "error: unknown option" ❌

**Why it happens:**
- Git config file updated at `~/.config/git/config`
- But git has config cached in memory
- OR: Forgot to use `g` prefix

**Solution:**
```bash
# 1. Check if you're using correct prefix
g myalias    # ✅ Correct (with g prefix)
myalias      # ❌ Wrong (missing g)

# 2. Restart shell to reload config
exec zsh

# 3. Verify alias exists
g config --list | grep alias.myalias

# 4. Test it
g myalias
```

**Common issues:**

**Issue 1: Missing `g` prefix**
```bash
# ❌ This won't work:
gs           # Old pattern
gaa          # Old pattern
gco          # Old pattern

# ✅ Use g prefix:
g s          # git status -s
g aa         # git add --all
g co         # git checkout
```

**Issue 2: Config not reloaded**
```bash
# After editing git.nix
nix-rebuild
exec zsh     # CRITICAL: Reload git config

# Verify
g config --list | grep alias
```

**Prevention:**
See [Shell Reference - Git](../reference/shell.md#git) for all 60+ aliases.

---

### Secrets Not Available in Shell

**Symptom:**
- Added secret to `secrets.yaml`
- Ran `nix-rebuild` - succeeded ✅
- Echo `$MY_SECRET` - empty ❌

**Why it happens:**
- Secrets decrypted to `~/.zsh_secrets`
- But current shell hasn't sourced the file
- OR: Missing age key configuration

**Solution:**

**Step 1: Verify secrets file exists**
```bash
# Check file created
ls -la ~/.zsh_secrets

# If missing, check SOPS config
echo $SOPS_AGE_KEY_FILE
# Should show: /Users/jimmy/.config/sops/age/keys.txt

# Check age key exists
ls -la ~/.config/sops/age/keys.txt
```

**Step 2: Restart shell**
```bash
exec zsh

# Verify secret loaded
echo $MY_SECRET
# Should show the decrypted value
```

**Step 3: If still empty, check secrets config**
```bash
# View decrypted secrets
edit-secrets

# Check sops configuration
cat hosts/$(hostname)/default.nix | grep -A 10 "sops ="

# Manual decrypt test
sops -d hosts/$(hostname)/secrets.yaml
```

**Prevention:**
```bash
# When adding secrets
edit-secrets              # Add secret
nix-rebuild               # Decrypt and install
exec zsh                  # Source ~/.zsh_secrets
echo $MY_SECRET           # Verify

# If doesn't work, debug
nix-rebuild-debug         # See decryption output
```

**Common causes:**
- ❌ Forgot `exec zsh` after rebuild
- ❌ Age key not configured (`SOPS_AGE_KEY_FILE` not set)
- ❌ Secret not added to `sops.secrets` in host config
- ❌ Secrets file not encrypted (plaintext yaml)

See [Secrets Guide](secrets.md) for complete setup.

---

### Homebrew App Not Installed

**Symptom:**
- Added app to `homebrew.nix` casks
- Ran `nix-rebuild` - succeeded ✅
- App not in Applications folder ❌

**Why it happens:**
- `darwin-rebuild` manages Homebrew config
- But doesn't always auto-install casks
- Sometimes needs manual `brew install`

**Solution:**
```bash
# Check if Homebrew knows about it
brew list --cask | grep appname

# If missing, install manually
brew install --cask appname

# Or reinstall all casks
brew bundle install --file=~/.config/Brewfile

# Verify
open -a AppName
```

**Prevention:**
```bash
# When adding GUI apps
code modules/darwin/homebrew.nix   # Add to casks
nix-rebuild                         # Update Brewfile
brew install --cask newapp          # Install manually
open -a NewApp                      # Verify works
```

**Note:** This is a known limitation of nix-darwin's Homebrew integration. Cask management is declarative (adds to Brewfile) but installation may need manual trigger.

---

### VS Code Extensions Not Installing

**Symptom:**
- Added extension to `vscode.nix`
- Ran `nix-rebuild` - succeeded ✅
- Extension not in VS Code ❌

**Why it happens:**
- VS Code needs restart to load new extension config
- OR: Extension ID incorrect
- OR: Extension requires manual install

**Solution:**
```bash
# 1. Rebuild
nix-rebuild

# 2. Fully quit VS Code
# Cmd+Q (not just close window)

# 3. Reopen VS Code
code .

# 4. Check extensions
code --list-extensions | grep extensionname

# If still missing, check extension ID
code modules/jimmy/programs/vscode.nix
# Verify publisher.extension format
```

**Prevention:**
```bash
# Get correct extension ID from VS Code
# Extensions → Click extension → Copy Extension ID

# Add to vscode.nix with exact ID
code modules/jimmy/programs/vscode.nix

# Rebuild and restart VS Code
nix-rebuild
# Cmd+Q to quit VS Code
code .
```

**Note:** VS Code settings are in `user-data/` and managed separately. See [Usage Guide - VS Code Settings](usage.md#vs-code-settings).

---

### Environment Variables Not Set

**Symptom:**
- Added `MYVAR="value"` to `zsh.nix`
- Ran `nix-rebuild` - succeeded ✅
- Echo `$MYVAR` - empty ❌

**Why it happens:**
- Variable defined in new `~/.zshrc`
- But current shell has old environment
- Shell needs restart to load new variables

**Solution:**
```bash
# Restart shell
exec zsh

# Verify variable set
echo $MYVAR
# Should show: value

# Check if defined in zshrc
grep MYVAR ~/.zshrc
```

**Prevention:**
```bash
# Standard workflow for env vars
code home/jimmy/shell/zsh.nix     # Add: sessionVariables.MYVAR = "value"
nix-rebuild                        # Generate new .zshrc
exec zsh                           # Load environment
echo $MYVAR                        # Verify
```

**Common issues:**

**Issue 1: Forgot exec zsh**
```bash
# ❌ Wrong
add var → nix-rebuild → echo $MYVAR → empty

# ✅ Right
add var → nix-rebuild → exec zsh → echo $MYVAR → works
```

**Issue 2: Variable scope**
```nix
# In zsh.nix
sessionVariables = {
  MYVAR = "value";     # ✅ Available in all shells
};

# vs local in shellInit
shellInit = ''
  export MYVAR="value"  # ✅ Also works
'';
```

---

### Shell Functions Not Working

**Symptom:**
- Added function to `zsh.nix`
- Ran `nix-rebuild` - succeeded ✅
- Call function - "command not found" ❌

**Why it happens:**
- Function added to `~/.zshrc`
- But current shell parsed old file
- Need restart to parse new functions

**Solution:**
```bash
# Restart shell
exec zsh

# Verify function exists
type functionname
# Should show: functionname is a shell function

# Test it
functionname
```

**Example:**
```nix
# In zsh.nix
initExtra = ''
  myfunction() {
    echo "Hello from function"
  }
'';
```

```bash
# After rebuild
nix-rebuild
exec zsh          # MUST restart
myfunction        # Now works
```

**Prevention:**
- Always `exec zsh` after changing `initExtra` or `shellInit`
- Test functions after restart
- Functions can't be reloaded with `source ~/.zshrc` (use exec)

---

### PATH Changes Not Applied

**Symptom:**
- Added directory to PATH in `zsh.nix`
- Ran `nix-rebuild` - succeeded ✅
- Directory not in PATH ❌

**Why it happens:**
- PATH updated in `~/.zshrc`
- But shell still has old PATH in memory
- PATH is set during shell initialization

**Solution:**
```bash
# Restart shell to reinitialize PATH
exec zsh

# Verify PATH updated
echo $PATH | tr ':' '\n' | grep mynewdir

# Test commands from new directory work
which mycommand
```

**Prevention:**
```nix
# In zsh.nix - Add to PATH
sessionVariables = {
  PATH = "$HOME/mydir/bin:$PATH";  # Prepend
};

# After adding
nix-rebuild
exec zsh       # CRITICAL: Reload PATH
which mycommand
```

**Common mistake:**
```bash
# ❌ This won't work in current shell:
nix-rebuild
echo $PATH     # Still old PATH

# ✅ This works:
nix-rebuild
exec zsh
echo $PATH     # New PATH loaded
```

---

### Quick Checklist: "Why Didn't My Change Work?"

**After making ANY config change:**

```bash
# 1. Did you rebuild?
nix-rebuild   # ✅ Yes → Continue
              # ❌ No → Run it now

# 2. Did you restart shell?
exec zsh      # ✅ Yes → Continue
              # ❌ No → Run it now

# 3. Did you test the specific change?
# Example: If added alias
alias myalias
# Example: If added package
which newcommand
# Example: If added secret
echo $SECRET_VAR

# 4. Still doesn't work?
nix-rebuild-debug    # See what's happening
g l --oneline -5     # Check recent changes
nix-rollback         # Undo if broken
```

**Memory aid: "The Three Rs"**
1. **R**ebuild → `nix-rebuild`
2. **R**estart → `exec zsh`
3. **R**e-test → Verify it works

**Prevention: Standard workflow**
```bash
nixconf                  # Edit
nix-rebuild              # Build
exec zsh                 # Restart
test-change              # Verify
g aa && g cm "..." && g ps  # Commit
```

---

## Build Errors

### Error: File exists

**Symptom:**
```
error: File exists and is not a symlink: /Users/jimmy/.zshrc
```

**Fix:**
```bash
mv ~/.zshrc ~/.zshrc.backup
nix-rebuild
```

### Error: Unknown option

**Symptom:**
```
error: anonymous function called with unexpected argument
```

**Fix:**
```bash
# Check for typos in .nix files
nixconf

# Common issues:
# - Missing semicolons
# - Misspelled options
# - Extra commas

# Fix and rebuild
nix-rebuild
```

### Error: Package not found

**Symptom:**
```
error: attribute 'packagename' missing
```

**Fix:**
```bash
# Search for correct name
nix search nixpkgs packagename

# Update flake inputs
nix flake update
nix-rebuild
```

### Error: Hash mismatch

**Symptom:**
```
error: hash mismatch in fixed-output derivation
```

**Fix:**
```bash
# Update and clean
nix flake lock --update-input nixpkgs
nix-collect-garbage
nix-rebuild
```

### Build hangs/takes forever

**Fix:**
```bash
# Cancel with Ctrl+C

# Debug what's building with verbose output
nix-rebuild-debug

# Or manually with full flags
darwin-rebuild switch --flake . --show-trace --verbose --print-build-logs

# Check disk space
duf

# Clean old generations
nix-clean

# Try again
nix-rebuild
```

### Debugging with Verbose Output

**When to use debug mode:**
- Home Manager activation failures
- Configuration changes not applying
- Build succeeds but changes don't work
- Need to see what's happening during rebuild

**Debug commands:**
```bash
# Full verbose rebuild (recommended for troubleshooting)
nix-rebuild-debug

# Check configuration without building
nix-check

# Manual debug (equivalent to nix-rebuild-debug)
darwin-rebuild switch --flake ~/nix-darwin --show-trace --verbose --print-build-logs
```

**What debug output shows:**
- ✅ Detailed build logs for each derivation
- ✅ Full stack traces on errors
- ✅ Home Manager activation steps
- ✅ File installation and linking operations
- ✅ Script execution output

**Tip:** Pipe to file for analysis:
```bash
nix-rebuild-debug 2>&1 | tee rebuild.log
```

---

## Shell Issues

### Aliases not working

**Symptom:** `g s` shows "command not found"

**Fix:**
```bash
# Restart shell
exec zsh

# If still broken, rebuild
nix-rebuild
exec zsh

# Verify alias exists
alias g
g config --list | grep alias
```

### Command not found

**Symptom:** Command that should exist is missing

**Fix:**
```bash
# Check if it's an alias
alias | grep commandname

# Check PATH
echo $PATH | tr ':' '\n'

# Rebuild and restart
nix-rebuild
exec zsh

# Check package installed
which commandname
```

### Prompt looks wrong

**Symptom:** Starship prompt broken or missing

**Fix:**
```bash
# Check starship installed
which starship

# Check font (must be Nerd Font)
# iTerm2: Preferences → Profiles → Text
# Font: MesloLGM Nerd Font

# Restart shell
exec zsh

# If still broken
cat ~/.config/starship.toml
```

### No syntax highlighting

**Symptom:** No colors in shell

**Fix:**
```bash
# Check plugins installed
ls ~/.oh-my-zsh/custom/plugins/

# Should have:
# - zsh-autosuggestions
# - zsh-syntax-highlighting

# If missing, reinstall
cd ~/nix-darwin
./scripts/install-zsh-plugins.sh

exec zsh
```

### History not working

**Symptom:** Ctrl+R doesn't work

**Fix:**
```bash
# Check fzf installed
which fzf

exec zsh

# If still broken
cat ~/.zshrc | grep fzf
```

---

## Git Problems

### Git aliases don't work

**Symptom:** `g recent` shows error

**Fix:**
```bash
# Check aliases loaded
g config --list | grep alias

# If empty, rebuild
nix-rebuild
exec zsh

# Remember: use `g` prefix
g s    # not: gs
g co   # not: gco
```

### Wrong git email

**Symptom:** Commits using wrong email

**Fix:**
```bash
# Check current
g config user.email

# Edit config
gitconf
# Change userEmail

nix-rebuild

# Verify
g config user.email
```

### Can't push to GitHub

**Symptom:** Permission denied (publickey)

**Fix:**
```bash
# Check SSH key
ls -la ~/.ssh/id_ed25519*

# If missing, generate
ssh-keygen -t ed25519 -C "your@email.com"

# Add to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub | pbcopy

# Add to GitHub: Settings → SSH keys

# Test
ssh -T git@github.com
```

### Git keeps asking for password

**Fix:**
```bash
# Switch to SSH
g remote -v
g remote set-url origin git@github.com:user/repo.git

# Or use credential helper
g config --global credential.helper osxkeychain
```

### Commit blocked by pre-commit hook

**Symptom:** `❌ BLOCKED: Insecure file permissions detected`

**Cause:** Credential file has insecure permissions (not 600)

**Fix:**
```bash
# Fix the file permissions as shown in error
chmod 600 <file-path>

# Retry commit
git commit -m "message"
```

**Example:**
```bash
# Error shows:
# File: ~/.aws/credentials
# Current: 644 (readable by group/others)
# Required: 600 (owner read/write only)

# Fix it:
chmod 600 ~/.aws/credentials

# Retry:
git commit -m "update config"
```

### Hook blocking valid change

**Symptom:** Hook blocks commit but file permissions are actually correct

**Diagnosis:**
```bash
# Verify actual permissions
ls -la <file>

# Check if it's a symlink
file <file>

# If symlink, check target
ls -la $(readlink <file>)
```

**Solutions:**

**If hook is wrong (bug):**
```bash
# Bypass and report issue
git commit --no-verify -m "message"

# Report the issue so hook can be fixed
```

**If permissions are actually wrong:**
```bash
# Fix permissions
chmod 600 <file>

# Retry commit
git commit -m "message"
```

### Emergency bypass of hooks

**When to use:**
- ✅ Emergency production fix needed NOW
- ✅ Reverting broken change to unblock team
- ✅ Hook has a bug blocking valid change

**When NOT to use:**
- ❌ "I'll fix permissions later" (fix now!)
- ❌ "The warning is annoying" (warnings exist for security)
- ❌ "It's just dev environment" (security matters everywhere)

**How to bypass:**
```bash
# Skip pre-commit hook
git commit --no-verify -m "emergency fix"

# Skip both hooks
git commit --no-verify -m "fix"
git push --no-verify
```

**After bypass:** Fix the underlying issue immediately!

---

## Python Issues

### Venv not auto-activating

**Symptom:** Python venv doesn't activate when entering directory

**Fix:**
```bash
# Check venv exists
ls -la .venv/

# If missing, create
python -m venv .venv

# Leave and re-enter
cd ..
cd your-project
# Should show: 🐍 Activated virtual environment

# If still not working
cat ~/.zshrc | grep "Auto-activate"
```

### Wrong Python version

**Symptom:** Unexpected Python version

**Fix:**
```bash
# Check which python
which python

# If in venv, should be from venv
# If not, activate venv

# Check venv Python
.venv/bin/python --version

# If wrong, recreate venv
rm -rf .venv
python -m venv .venv
```

### UV commands not found

**Symptom:** `uv-new` not found

**Fix:**
```bash
# Check aliases
alias | grep uv

# If missing, rebuild
nix-rebuild
exec zsh

# Check UV installed
which uv
```

### Micromamba not working

**Symptom:** `base` command not found

**Fix:**
```bash
# Check micromamba installed
which micromamba

# Check function exists
type base

# If missing, rebuild
nix-rebuild
exec zsh

# Initialize micromamba
micromamba shell init -s zsh -p ~/micromamba
exec zsh
```

---

## Secrets Issues

### Failed to decrypt

**Symptom:**
```
error: Failed to decrypt secrets.yaml
```

**Fix:**
```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Get public key
grep "public key:" ~/.config/sops/age/keys.txt

# Check matches .sops.yaml
cat secrets/.sops.yaml | grep age1

# Test decryption manually
sops -d hosts/mbp-jimmy/secrets.yaml
```

### Secrets not appearing

**Symptom:** `~/.zsh_secrets` not created

**Fix:**
```bash
# Check sops-nix config
cat hosts/mbp-jimmy/default.nix | grep -A 20 "sops ="

# Rebuild with verbose
darwin-rebuild switch --flake ~/nix-darwin --show-trace

# Check sops-nix loaded
grep "sops-nix" flake.nix
```

### Can't edit secrets

**Symptom:** `edit-secrets` fails

**Fix:**
```bash
# Install sops
nix-env -iA nixpkgs.sops

# Or add to packages.nix
nixconf
# Add: sops

nix-rebuild
```

### Secrets not encrypted

**Symptom:** Plain text after saving

**Fix:**
```bash
# Check .sops.yaml path
cat ~/nix-darwin/secrets/.sops.yaml

# Manually encrypt
cd ~/nix-darwin
sops -e -i hosts/mbp-jimmy/secrets.yaml

# Verify
cat hosts/mbp-jimmy/secrets.yaml | grep "ENC\["
```

---

## Performance Problems

### Slow shell startup

**Symptom:** Shell takes long to start

**Fix:**
```bash
# Profile startup time
time zsh -i -c exit
# Should be < 1 second

# Check plugins
# Temporarily disable in zsh.nix

# Common culprits:
# - Too many plugins
# - Slow starship config
# - Network checks
```

### High CPU usage

**Fix:**
```bash
# Check processes
btop

# Common issues:
# - Docker containers
# - Runaway process
# - Background indexing

# Stop Docker
docker stop $(docker ps -q)

# Kill process
kill <PID>
```

### Disk space full

**Fix:**
```bash
# Check usage
duf

# Check what's using space
dust ~

# Clean Nix store
nix-collect-garbage -d
nix-clean

# Clean Homebrew
brew cleanup

# Clean Docker
docker-prune

# Check again
duf
```

---

## Test Failures

**When automated tests fail or show unexpected results**

### Understanding the Test Framework

The nix-darwin configuration includes a comprehensive test suite with 12 test suites across 4 categories:
- **Build Tests** (3): Flake validation, syntax checking, darwin-rebuild
- **Security Tests** (3): SOPS encryption, permissions, git hooks
- **Library Tests** (2): Machine detection, helper functions
- **Integration Tests** (3): Multi-machine, rebuild, rollback

### Quick Test Commands

```bash
# Run all tests
test-all

# Quick validation (dry-run mode, ~12 seconds)
test-quick

# Run specific test category
test-build          # Build and syntax tests
test-security       # Security validation tests
test-lib            # Library function tests
test-integration    # Integration tests

# Verbose test output
test-verbose
```

### Test Failure: Build Tests

**Symptom:** `test-build` fails with flake validation errors

**Common causes:**
- Syntax errors in .nix files
- Missing dependencies in flake.nix
- Broken module imports
- Invalid configuration options

**Fix:**
```bash
# Check flake syntax
nix flake check --show-trace

# Validate specific files
nix-instantiate --parse home/jimmy/shell/zsh.nix

# If syntax error found
nixconf                    # Open config
# Fix syntax error
nix-rebuild               # Verify fix
test-build                # Rerun tests
```

### Test Failure: Security Tests

**Symptom:** `test-security` fails with permission or encryption errors

**Common causes:**
- Secrets file not encrypted (plaintext YAML)
- File permissions not 600 on credentials
- Git hooks not executable
- SOPS age key missing

**Fix for unencrypted secrets:**
```bash
# Check if secrets are encrypted
cat hosts/$(hostname)/secrets.yaml | head -5
# Should show binary data, not plaintext

# If plaintext, encrypt it
cd ~/nix-darwin
sops -e -i hosts/$(hostname)/secrets.yaml

# Verify encryption
cat hosts/$(hostname)/secrets.yaml | grep "ENC\["
# Should show: sops_age__encrypted...

# Rerun tests
test-security
```

**Fix for permission errors:**
```bash
# Check permissions
ls -la ~/.aws/credentials ~/.db/* ~/.tokens/*

# Fix permissions (shown in test output)
chmod 600 ~/.aws/credentials
chmod 600 ~/.db/oracle/prod
chmod 600 ~/.tokens/git_token

# Rerun tests
test-security
```

### Test Failure: Library Tests

**Symptom:** `test-lib` fails with helper function errors

**Common causes:**
- Machine detection logic broken
- Helper functions returning incorrect values
- Missing lib exports

**Fix:**
```bash
# Test machine detection manually
hostname
# Should be: mbp-jimmy or mbp-work

echo $MACHINE_MODE
# Should be: home or work

# Check lib exports
nix eval .#lib --apply 'lib: builtins.attrNames lib'

# If broken, check lib/default.nix
nixconf
# Navigate to lib/default.nix
# Verify all modules exported

nix-rebuild
test-lib
```

### Test Failure: Integration Tests

**Symptom:** `test-integration` fails with rebuild or rollback errors

**Common causes:**
- System in inconsistent state
- No previous generation for rollback test
- Build cache corrupted

**Fix:**
```bash
# Check generations exist
darwin-rebuild --list-generations
# Should show multiple generations

# If only 1 generation (can't test rollback)
nix-rebuild                # Create new generation
test-integration           # Now has 2+ generations

# If rebuild fails
nix-collect-garbage        # Clean cache
nix flake update           # Update inputs
nix-rebuild                # Fresh rebuild
test-integration
```

### Understanding Test Exit Codes

The test framework uses standardized exit codes:
- **0**: All tests passed
- **1**: Tests failed
- **2**: Invalid arguments or setup

**CI/CD Integration:**
```bash
# Run tests in CI-friendly mode
test-all --ci

# Check exit code
echo $?
# 0 = success, 1 = failure, 2 = invalid
```

### Dry-Run Mode for Fast Validation

**Use dry-run mode** when you need fast feedback:

```bash
# Quick validation (~12 seconds)
test-quick

# This runs tests without actual builds
# Catches most issues quickly
# Use before committing changes
```

**When to use full tests:**
```bash
# Full test run (~2-5 minutes)
test-all

# Use when:
# - Before merging to main
# - After major changes
# - Before deployment
```

### Test Framework Troubleshooting

**Symptom:** Test framework itself has errors

**Common issues:**

**Issue 1: Tests not found**
```bash
# Check test directory exists
ls -la ~/nix-darwin/tests/

# Should show:
# - test-framework.sh
# - run-all-tests.sh
# - build/
# - security/
# - lib/
# - integration/

# If missing, check git
cd ~/nix-darwin
g status
# Restore if needed
g reset --hard origin/main
```

**Issue 2: Tests not executable**
```bash
# Fix permissions
chmod +x ~/nix-darwin/tests/*.sh
chmod +x ~/nix-darwin/tests/*/*.sh

# Verify
ls -la ~/nix-darwin/tests/run-all-tests.sh
# Should show: -rwxr-xr-x
```

**Issue 3: Missing test dependencies**
```bash
# Check test framework loaded
which test-all
# Should show: test-all: aliased to...

# If not found
nix-rebuild
exec zsh
test-all
```

### Reading Test Output

**Successful test:**
```
✅ test-build-flake-check
   Flake validation passed
   Duration: 2.3s
```

**Failed test:**
```
❌ test-build-flake-check
   Error: syntax error in home/jimmy/shell/zsh.nix
   Line 42: unexpected token ';'
   Duration: 0.5s
```

**Test tips:**
- ✅ Run tests before committing
- ✅ Use `test-quick` for fast feedback
- ✅ Read error messages carefully
- ✅ Fix one test at a time
- ✅ Rerun full suite after fixes

---

## Permission & Security Issues

**Security validation and permission problems**

### Security Audit System

The system includes automated security auditing:

```bash
# Run complete security audit
audit-permissions

# Auto-fix insecure permissions
audit-permissions --fix

# Verbose output with details
audit-permissions --verbose

# Check specific category
# Categories: aws, database, ssh, tokens, credentials, secrets, sops
```

### Understanding Permission Requirements

**Critical files must have 600 permissions** (owner read/write only):

| Category | Files | Required Perms |
|----------|-------|----------------|
| AWS | `~/.aws/credentials` | 600 |
| Database | `~/.db/*` | 600 |
| SSH | `~/.ssh/id_*` (private keys) | 600 |
| Tokens | `~/.tokens/*` | 600 |
| Credentials | `~/.credentials/*` | 600 |
| Secrets | `hosts/*/secrets.yaml` | 600 |
| SOPS | `~/.config/sops/age/keys.txt` | 600 |

### Permission Audit Failures

**Symptom:** `audit-permissions` shows failing checks

**Example output:**
```
🔍 Auditing file permissions...

❌ AWS Credentials (1/1 files checked)
   ~/.aws/credentials: 644 (should be 600)

✅ Database Credentials (2/2 files checked)
✅ SSH Keys (3/3 files checked)

Score: 83% (5/6 checks passed)
Status: ⚠️  NEEDS ATTENTION
```

**Fix:**
```bash
# Option 1: Auto-fix (recommended)
audit-permissions --fix

# Option 2: Manual fix
chmod 600 ~/.aws/credentials

# Verify
audit-permissions
# Should show: ✅ AWS Credentials
```

### SOPS Encryption Issues

**Symptom:** Secrets not encrypted or decryption fails

**Check encryption status:**
```bash
# Secrets should be binary (encrypted)
file hosts/$(hostname)/secrets.yaml
# Should show: data

# If shows: ASCII text
# Then file is plaintext (NOT ENCRYPTED)
```

**Fix plaintext secrets:**
```bash
# Encrypt secrets file
cd ~/nix-darwin
sops -e -i hosts/$(hostname)/secrets.yaml

# Verify encryption
cat hosts/$(hostname)/secrets.yaml | grep "ENC\["
# Should show: sops_age__encrypted

# Test decryption
sops -d hosts/$(hostname)/secrets.yaml
# Should show decrypted YAML
```

**Symptom:** Cannot decrypt secrets

**Common causes:**
- Age key missing
- Age key not in .sops.yaml
- Wrong key format

**Fix:**
```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# If missing, generate new key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key
grep "public key:" ~/.config/sops/age/keys.txt
# Example: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Update .sops.yaml with public key
cd ~/nix-darwin
nixconf
# Edit secrets/.sops.yaml
# Add your public key under creation_rules → age

# Re-encrypt secrets with new key
sops updatekeys hosts/$(hostname)/secrets.yaml
```

### Git Hook Security Validation

**The pre-commit hook performs security checks:**

1. **Blocks credential files** from being staged
2. **Validates SOPS encryption** (binary format required)
3. **Checks file permissions** (warnings for insecure files)

**Symptom:** Commit blocked by security checks

**Example:**
```bash
$ git commit -m "update config"

🔍 Validating secrets and credentials...

❌ BLOCKED: Plaintext secrets detected
   File: hosts/mbp-jimmy/secrets.yaml
   Status: Not encrypted (must be SOPS binary format)
   
   Fix: sops -e -i hosts/mbp-jimmy/secrets.yaml
```

**Fix based on block reason:**

**Blocked: Credential files staged**
```bash
# Remove credentials from staging
git reset ~/.aws/credentials

# Check .gitignore
cat .gitignore | grep credentials
# Should include: **/.credentials/

# Commit without credentials
git commit -m "update config"
```

**Blocked: Plaintext secrets**
```bash
# Encrypt secrets
sops -e -i hosts/$(hostname)/secrets.yaml

# Retry commit
git commit -m "update config"
```

**Warning: Insecure permissions**
```bash
# Fix permissions as shown in warning
chmod 600 <file-path>

# Retry commit
git commit -m "update config"
```

### Permission Bypass (Emergency Only)

**When to bypass:** ONLY in emergencies (production outage, urgent fix)

**How to bypass:**
```bash
# Skip ALL hooks (use with extreme caution)
git commit --no-verify -m "emergency fix"

# After emergency
# 1. Fix permissions immediately
chmod 600 <all-credential-files>

# 2. Run security audit
audit-permissions --fix

# 3. Verify security
test-security
```

**DON'T bypass just because:**
- ❌ "I'll fix it later" (fix now!)
- ❌ "Warning is annoying" (it's protecting you)
- ❌ "It's just dev" (security matters everywhere)

### Centralized Security Registry

**All secure paths are registered** in `lib/secrets-registry.nix`

**Check what's protected:**
```bash
# View registry
cat ~/nix-darwin/lib/secrets-registry.nix

# Shows:
# - All protected directories
# - All credential file patterns
# - All secret file locations
```

**Add new secure path:**
```nix
// In lib/secrets-registry.nix
{
  credentials = [
    "~/.aws/credentials"
    "~/.db"
    "~/.tokens"
    "~/.new-secure-path"  // Add here
  ];
}
```

### Defense-in-Depth Security

The system has **5 security layers**:

1. **Prevention**: Git hooks block bad commits
2. **Detection**: Audit scripts identify issues
3. **Remediation**: Auto-fix capabilities
4. **Validation**: Health check monitoring
5. **Registry**: Centralized truth (secrets-registry.nix)

**Verify all layers:**
```bash
# Layer 1: Test hooks
git commit --dry-run -m "test"

# Layer 2: Run audit
audit-permissions

# Layer 3: Auto-fix
audit-permissions --fix

# Layer 4: Health check
health-check

# Layer 5: Check registry
cat lib/secrets-registry.nix
```

---

## Build Validation Problems

**Configuration syntax and build validation issues**

### Pre-Commit Nix Validation

**Git hooks validate Nix syntax** before allowing commits.

**How it works:**
```bash
# When you commit
git commit -m "update config"

# Hook runs automatically:
# 1. Checks if .nix files staged
# 2. Runs: nix flake check --no-build
# 3. Blocks commit if syntax errors found
```

**Symptom:** Commit blocked by Nix validation

**Example:**
```bash
$ git commit -m "add package"

🔍 Validating Nix configuration...
error: syntax error, unexpected ';'
at /Users/jimmy/nix-darwin/home/jimmy/shell/zsh.nix:42:15

❌ Nix validation failed
   Fix syntax errors and try again
   Hint: nix flake check --show-trace
```

**Fix:**
```bash
# Check syntax
nix flake check --show-trace

# Error shows file and line number
# Fix the syntax error
nixconf                    # Open config
# Navigate to problematic file
# Fix syntax error at line shown

# Verify fix
nix flake check

# Should show:
# warning: ...  (warnings OK)
# (no errors)

# Retry commit
git commit -m "add package"
# Should succeed now
```

### Common Nix Syntax Errors

**Error 1: Missing semicolon**
```nix
# ❌ Wrong
packages = [
  pkgs.ripgrep
  pkgs.fd  // Missing ;
]

# ✅ Right
packages = [
  pkgs.ripgrep;
  pkgs.fd;
];
```

**Error 2: Extra comma**
```nix
# ❌ Wrong
{
  option = "value";
  other = "value";,  // Extra comma
}

# ✅ Right
{
  option = "value";
  other = "value";
}
```

**Error 3: Unmatched brackets**
```nix
# ❌ Wrong
mkIf (condition) {
  setting = value;
// Missing }

# ✅ Right
mkIf (condition) {
  setting = value;
}
```

**Error 4: String not closed**
```nix
# ❌ Wrong
message = "Hello world;  // Missing closing "

# ✅ Right
message = "Hello world";
```

### Fast Syntax Validation

**Validate without full build** (~2 seconds):

```bash
# Quick check (no build)
nix flake check --no-build

# This is what git hook runs
# Catches syntax errors fast
# Use before committing
```

**Validate specific file:**
```bash
# Parse single file
nix-instantiate --parse home/jimmy/shell/zsh.nix

# Shows:
# - Success: Shows parsed structure
# - Failure: Shows syntax error
```

### Build vs. Syntax Errors

**Understand the difference:**

**Syntax errors** (caught by pre-commit):
- Missing semicolons, brackets
- Unclosed strings
- Invalid Nix expressions
- Caught by: `nix flake check --no-build`

**Build errors** (caught by rebuild):
- Missing packages
- Invalid options
- Undefined variables
- Module conflicts
- Caught by: `darwin-rebuild`

**Workflow:**
```bash
# 1. Syntax check (fast, ~2s)
nix flake check --no-build

# 2. If passes, full build
nix-rebuild

# 3. If build fails
nix-rebuild-debug        # See detailed errors
```

### Configuration Diff for Validation

**Preview changes before rebuilding:**

```bash
# See what changed
config-diff

# Package changes only
config-diff-packages

# Detailed diff
config-diff-verbose

# Compare specific generations
config-diff --generations 8 10
```

**Use before rebuilding:**
```bash
# Standard workflow
nixconf                    # Edit config
config-diff-packages       # Preview changes
nix-rebuild                # Apply if looks good
config-diff                # Verify changes
```

### Flake Lock Issues

**Symptom:** Build fails with hash mismatch or outdated inputs

**Fix:**
```bash
# Update flake inputs
nix flake update

# Or update specific input
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Rebuild with updated inputs
nix-rebuild
```

### Build Cache Problems

**Symptom:** Build succeeds but changes don't apply

**Common cause:** Nix cache corrupted or stale

**Fix:**
```bash
# Clean cache
nix-collect-garbage -d

# Clear build cache
nix-clean

# Fresh rebuild
nix-rebuild

# Should rebuild cleanly
```

---

## Multi-Machine Configuration Issues

**Problems specific to managing multiple machines (personal + work)**

### Understanding Multi-Machine Setup

The configuration supports 2 machines:
- **mbp-jimmy** (personal) - Uses `personal.nix` mixin
- **mbp-work** (work) - Uses `work.nix` mixin

**Machine-specific differences:**

| Setting | Personal (mbp-jimmy) | Work (mbp-work) |
|---------|---------------------|-----------------|
| Hostname | mbp-jimmy | mbp-work |
| MACHINE_MODE | home | work |
| AWS_PROFILE | personal | work-domain |
| Git email | jimmy-jain@... | first.last@work... |
| Mixins | personal.nix | work.nix |
| Special functions | None | awslogin, awswho |

### Wrong Machine Detection

**Symptom:** System loads wrong mixin (work settings on personal Mac)

**Diagnose:**
```bash
# Check hostname
hostname
# Should match: mbp-jimmy OR mbp-work

# Check machine mode
echo $MACHINE_MODE
# Should match: home OR work

# If mismatch:
hostname               # Shows: mbp-jimmy
echo $MACHINE_MODE     # Shows: work (WRONG!)
```

**Fix:**
```bash
# Set correct hostname
sudo scutil --set HostName mbp-jimmy
# or
sudo scutil --set HostName mbp-work

# Rebuild to reload mixin
nix-rebuild

# Restart shell
exec zsh

# Verify
hostname
echo $MACHINE_MODE
# Should both match now
```

### Mixin Not Loading

**Symptom:** Machine-specific settings not applied

**Check which mixin loaded:**
```bash
# Check MACHINE_MODE
echo $MACHINE_MODE

# Check git email (machine-specific)
g config user.email

# Personal should show: jimmy-jain@users.noreply.github.com
# Work should show: first.last@work-domain.com

# If wrong, check mixin import
nixconf
# Navigate to hosts/$(hostname)/default.nix
# Verify imports section includes:
# home/_mixins/${hostname}.nix
```

**Fix mixin import:**
```nix
// In hosts/mbp-jimmy/default.nix or hosts/mbp-work/default.nix
{
  imports = [
    ../../modules/darwin
    ../../modules/shared
    ../../home/jimmy
    ../../home/_mixins/base.nix
    ../../home/_mixins/personal.nix  // For mbp-jimmy
    // OR
    ../../home/_mixins/work.nix      // For mbp-work
  ];
}
```

### Wrong AWS Profile

**Symptom:** AWS commands use wrong profile

**Check:**
```bash
# Check default AWS profile
echo $AWS_PROFILE

# Personal machine should show: personal
# Work machine should show: work-domain

# Check AWS config
cat ~/.aws/config | grep "\[profile"

# Should have profiles matching hostname
```

**Fix:**
```bash
# Check mixin sets correct profile
nixconf
# Navigate to home/_mixins/personal.nix or work.nix
# Verify sessionVariables.AWS_PROFILE

# Rebuild
nix-rebuild
exec zsh

# Verify
echo $AWS_PROFILE
```

### Work-Only Functions Not Available

**Symptom:** `awslogin` or `awswho` not found on work Mac

**Diagnose:**
```bash
# Check hostname
hostname
# Should be: mbp-work

# Check if function exists
type awslogin
# Should show: awslogin is a shell function

# If not found, check mixin
nixconf
# Check home/_mixins/work.nix
# Should have AWS SSO functions
```

**Fix:**
```bash
# Ensure work.nix is imported
# Check hosts/mbp-work/default.nix

# Rebuild
nix-rebuild
exec zsh

# Verify
type awslogin
awswho
```

### Secrets Per Machine

**Each machine has its own secrets file:**
- `hosts/mbp-jimmy/secrets.yaml`
- `hosts/mbp-work/secrets.yaml`

**Symptom:** Secrets from wrong machine loaded

**Check:**
```bash
# Which secrets file is active?
ls -la ~/.zsh_secrets
# This is symlink to active secrets

# Should point to:
# Personal: hosts/mbp-jimmy/secrets.yaml
# Work: hosts/mbp-work/secrets.yaml

# If wrong, check sops config
cat hosts/$(hostname)/default.nix | grep -A 10 "sops ="
```

**Fix:**
```bash
# Ensure host config has correct sops.secrets
# In hosts/mbp-jimmy/default.nix (or mbp-work)
sops = {
  defaultSopsFile = ./secrets.yaml;  # Correct path
  secrets = {
    # ... secret definitions
  };
};

# Rebuild
nix-rebuild
exec zsh

# Verify
ls -la ~/.zsh_secrets
```

### Machine-Specific Testing

**Test multi-machine setup:**
```bash
# Run integration tests
test-integration

# This includes:
# - Machine detection tests
# - Mixin loading tests
# - Profile selection tests

# Specifically test machine detection
test-lib

# Check machine detection functions
nix eval .#lib.selectByMachine --apply 'f: f "mbp-jimmy" { personal = "personal-value"; work = "work-value"; }'
# Should show: "personal-value" for mbp-jimmy
# Should show: "work-value" for mbp-work
```

### Syncing Configurations

**Keep machines in sync:**

```bash
# On machine 1
cd ~/nix-darwin
g aa && g cm "update config" && g ps

# On machine 2
cd ~/nix-darwin
g pl                       # Pull changes
nix-rebuild                # Apply changes
exec zsh                   # Reload
```

**Common mistake:**
```bash
# ❌ Wrong: Edit on one machine, forget to push
edit config → rebuild → works locally → forget to push

# Other machine doesn't get changes!

# ✅ Right: Always push after testing
edit config → rebuild → test → commit → push

# Now other machines can pull changes
```

### Machine-Specific Packages

**Some packages only on specific machines:**

```nix
// In home/_mixins/work.nix
{
  home.packages = with pkgs; [
    # Work-only packages
    awscli2
    terraform
    kubectl
  ];
}

// In home/_mixins/personal.nix
{
  home.packages = with pkgs; [
    # Personal-only packages
    steam
    discord
  ];
}
```

**Symptom:** Package missing on one machine

**Fix:**
```bash
# Check which mixin loaded
echo $MACHINE_MODE

# Check if package in correct mixin
nixconf
# Navigate to home/_mixins/personal.nix or work.nix
# Add package to home.packages

# Rebuild
nix-rebuild
exec zsh

# Verify
which package-name
```

---

## Emergency Recovery

### Quick Recovery Steps

```bash
# 1. Try rollback
nix-rollback
exec zsh

# 2. If doesn't work, check generations
darwin-rebuild --list-generations

# 3. Switch to working generation
sudo darwin-rebuild switch --switch-generation 10

# 4. If config broken, revert git
cd ~/nix-darwin
g reset --hard <working-commit>
nix-rebuild

# 5. Nuclear option
sudo /nix/nix-installer uninstall
sudo rm -rf /nix
# Reinstall from scratch
```

### System won't boot

**Steps:**
1. Boot to recovery (Cmd+R during startup)
2. Use terminal in recovery
3. Remove Nix symlinks:
   ```bash
   rm /etc/zshrc
   rm /etc/bashrc
   ```
4. Reboot normally
5. Reinstall

### Complete reset

**Last resort:**
```bash
# 1. Backup data
cp -r ~/Dev ~/Dev.backup
backup-user-data

# 2. Uninstall Nix
sudo /nix/nix-installer uninstall
sudo rm -rf /nix

# 3. Remove configs
rm ~/.zshrc ~/.gitconfig

# 4. Reinstall from scratch
# Follow installation guide
```

---

## Prevention Tips

### 1. Commit before changes

```bash
g aa && g cm "Working config $(date)" && g ps
```

### 2. Test in stages

```bash
# Change 1 thing
nix-rebuild
# Test
# Commit
```

### 3. Pull before editing

```bash
cd ~/nix-darwin
g pl
```

### 4. Keep secrets out of git

```bash
# Before committing
g d  # Review all changes
```

### 5. Use branches for experiments

```bash
g cob experiment/new-feature
# If works: merge
# If doesn't: delete branch
```

---

## Common Error Messages

### "command not found"

```bash
nix-rebuild && exec zsh
```

### "Permission denied"

```bash
ls -la <file>
chmod 600 <file>  # For secrets
chmod 644 <file>  # For regular files
```

### "No space left"

```bash
nix-collect-garbage -d
nix-clean
brew cleanup
```

### "hash mismatch"

```bash
nix flake update
nix-rebuild
```

### "infinite recursion"

```bash
# Check for circular imports
darwin-rebuild switch --flake . --show-trace
```

---

## Getting Help

### Before asking for help

1. Try quick fixes (restart shell, rebuild, rollback)
2. Check this guide
3. Search error message
4. Check git history - what changed?

### Provide this information

```bash
# System info
hostname
sw_vers

# Nix info
nix --version

# Error with trace
darwin-rebuild switch --flake . --show-trace 2>&1 | tee error.log

# Recent changes
cd ~/nix-darwin
g l --oneline -10
```

---

## Quick Reference Card

```bash
# First Aid
exec zsh                 # Restart shell
nix-rebuild              # Rebuild system
nix-rollback             # Undo last rebuild

# Diagnostics
darwin-rebuild --list-generations
nix flake check
g s

# Cleanup
nix-clean
brew cleanup
docker-prune

# Emergency
sudo reboot
nix-rollback
```

---

## Links

- **[Installation Guide](installation.md)** - Setup from scratch
- **[Usage Guide](usage.md)** - Daily workflows
- **[Backup & Recovery](backup-and-recovery.md)** - Recovery procedures
- **[FAQ](../appendix/faq.md)** - Common questions

---

**When in doubt, rollback and try again!**