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
| Git aliases broken | Use `g` prefix: `g s` | [Git Problems](#git-problems) |
| Commit blocked by hook | `chmod 600 <file>` | [Git Problems](#commit-blocked-by-pre-commit-hook) |
| Slow shell | Check plugins | [Performance](#performance-problems) |
| Secrets won't decrypt | Check age key | [Secrets Issues](#secrets-issues) |
| Python venv not working | Re-enter directory | [Python Issues](#python-issues) |

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
2. [Build Errors](#build-errors)
3. [Shell Issues](#shell-issues)
4. [Git Problems](#git-problems)
5. [Python Issues](#python-issues)
6. [Secrets Issues](#secrets-issues)
7. [Performance Problems](#performance-problems)
8. [Emergency Recovery](#emergency-recovery)

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
