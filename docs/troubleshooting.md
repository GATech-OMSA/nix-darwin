# Troubleshooting Guide

**Fix common issues quickly - v2.0.0 Profile System**

**Last Updated**: 2025-11-10 (v2.0.0 updates)

---

## Quick Symptom Finder

| Symptom | Quick Fix | Section |
|---------|-----------|---------|
| Command not found | `nix-rebuild && exec zsh` | [Shell Issues](#shell-issues) |
| Build fails | `nix-rollback` | [Build Errors](#build-errors) |
| Wrong profile active | Edit machine-config.nix | [Profile Issues](#profile-issues) |
| Config files missing | Run `./scripts/configure.sh` | [Profile Issues](#missing-configuration-files) |
| FLAKE_ROOT not set | Use `nix-rebuild` alias | [Profile Issues](#flake-root-errors) |
| Placeholders in secrets | Edit secret templates, run activate.sh | [Secrets Issues](#placeholder-detection) |
| Changes don't apply | `exec zsh` | [Silent Failures](#silent-failures) |
| Git commit blocked | Check secret encryption | [Git Problems](#commit-blocked-by-hooks) |
| Age key mismatch | Check ~/.config/sops/age/ | [Secrets Issues](#age-key-problems) |
| Build requires --impure | Use `nix-rebuild` alias (auto-handles) | [Build Errors](#impure-flag-required) |

---

## Decision Tree

```
Problem? Start here:

┌─ Did you just upgrade to v2.0.0?
│  ├─ Yes → Check Profile Issues section
│  │  ├─ Config files missing? → Run ./scripts/configure.sh
│  │  ├─ Wrong profile? → Edit config/machine-config.nix
│  │  └─ Build fails? → Check FLAKE_ROOT errors
│  │
│  └─ No → Did you just rebuild?
│     ├─ Yes → Try: exec zsh
│     │  ├─ Fixed? → Done!
│     │  └─ Still broken? → nix-rollback
│     │
│     └─ No → Check specific issue below

Emergency? → See Emergency Recovery
```

---

## Table of Contents

1. [Quick Fixes](#quick-fixes)
2. [Profile Issues (v2.0.0)](#profile-issues)
3. [Silent Failures](#silent-failures)
4. [Build Errors](#build-errors)
5. [Shell Issues](#shell-issues)
6. [Git Problems](#git-problems)
7. [Secrets Issues](#secrets-issues)
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

# 4. If still broken, check profile
echo $ACTIVE_PROFILE  # Should be personal, work, or minimal
```

### Quick Diagnostics

```bash
# Check profile status
echo $ACTIVE_PROFILE          # personal, work, or minimal
echo $MACHINE_MODE            # home, work, or minimal

# Check config files exist
ls -la config/                # Should have user-config.nix, machine-config.nix

# Check Nix
nix --version                 # 2.31.2+

# Check last build
darwin-rebuild --list-generations

# Check for errors
nix-rebuild --show-trace
```

---

## Profile Issues

**v2.0.0 introduced profile-based architecture with new configuration requirements**

### Missing Configuration Files

**Symptom:**
- Build fails with error about missing config files
- `config/user-config.nix` or `config/machine-config.nix` not found

**Why it happens:**
- v2.0.0 requires gitignored configuration files
- These files are machine-specific and not in repository

**Solution:**

```bash
# Run configuration wizard
cd ~/nix-darwin
./scripts/configure.sh

# Expected output:
# ✅ Generated config/user-config.nix
# ✅ Generated config/machine-config.nix
# ✅ Created profile-specific secret templates

# Verify files created
ls -la config/
# Should show:
#   user-config.nix (gitignored)
#   machine-config.nix (gitignored)
```

**What configure.sh creates:**

1. `config/user-config.nix` - Your personal info (username, email, fullName)
2. `config/machine-config.nix` - Machine identity (machineId, profileName)
3. Profile-specific secret templates

**After generation:**

```bash
# Build system
./scripts/activate.sh
# or
nix-rebuild && exec zsh
```

---

### Wrong Profile Active

**Symptom:**
- `echo $ACTIVE_PROFILE` shows wrong profile
- Getting personal aliases on work machine (or vice versa)
- AWS commands missing on work profile
- Work databases showing on personal machine

**Why it happens:**
- Profile selected incorrectly in `config/machine-config.nix`
- profileName doesn't match intended use

**Solution:**

```bash
# 1. Check current profile
echo $ACTIVE_PROFILE
echo $MACHINE_MODE

# 2. Edit machine config
code config/machine-config.nix

# 3. Change profileName field
# {
#   machineId = "mbp-personal-001";
#   profileName = "personal";  # ← Change this: personal, work, or minimal
#   description = "...";
# }

# 4. Rebuild
nix-rebuild && exec zsh

# 5. Verify
echo $ACTIVE_PROFILE
```

**Profile Differences:**

| Profile | ACTIVE_PROFILE | MACHINE_MODE | Features |
|---------|----------------|--------------|----------|
| personal | `personal` | `home` | Personal aliases, no databases/AWS |
| work | `work` | `work` | Work databases, AWS SSO, work email |
| minimal | `minimal` | `minimal` | Bare-bones, troubleshooting only |

---

### FLAKE_ROOT Errors

**Symptom:**
- Build fails with "FLAKE_ROOT not set"
- Error: "Could not find config files"

**Why it happens:**
- v2.0.0 uses FLAKE_ROOT environment variable to find config files
- Direct `darwin-rebuild` commands don't set this variable
- Only `nix-rebuild` alias handles FLAKE_ROOT automatically

**Solution:**

```bash
# ❌ DON'T use darwin-rebuild directly
darwin-rebuild switch --flake .

# ✅ DO use nix-rebuild alias (sets FLAKE_ROOT automatically)
nix-rebuild

# Or set manually if needed
FLAKE_ROOT="$PWD" darwin-rebuild switch --flake . --impure
```

**Why it's needed:**
- Config files are gitignored and outside Nix store
- FLAKE_ROOT tells Nix where to find config/ directory
- `nix-rebuild` alias handles this automatically

---

### Impure Flag Required

**Symptom:**
- Build fails without `--impure` flag
- Error about pure evaluation

**Why it happens:**
- v2.0.0 reads gitignored files (config/user-config.nix, config/machine-config.nix)
- Pure evaluation mode can't access files outside Nix store
- All builds require `--impure` flag

**Solution:**

```bash
# ✅ Use nix-rebuild alias (handles --impure automatically)
nix-rebuild

# Or if using darwin-rebuild directly:
darwin-rebuild switch --flake . --impure
```

**Note:** `nix-rebuild` alias automatically adds `--impure` flag

---

### Profile Switcher Script Missing

**Symptom:**
- Want to switch profiles but no convenient script exists
- Have to manually edit config/machine-config.nix

**Why it happens:**
- Profile switcher script not yet implemented (see BACKLOG.md)
- Manual editing required for now

**Solution (Manual):**

```bash
# 1. Edit machine config
code config/machine-config.nix

# 2. Change profileName
# profileName = "work";  # or "personal" or "minimal"

# 3. Rebuild
nix-rebuild && exec zsh

# 4. Verify
echo $ACTIVE_PROFILE
```

**Future:** Profile switcher script planned (scripts/switch-profile.sh)

---

## Silent Failures

**When operations appear to succeed but changes don't take effect**

### Config Changes Not Applied

**Symptom:**
- Changed alias in zsh.nix
- Ran `nix-rebuild` - succeeded ✅
- Type alias - "command not found" ❌

**Why it happens:**
- Current shell has OLD config in memory
- Shell needs restart to reload ~/.zshrc

**Solution:**

```bash
# After ANY config change, ALWAYS restart shell
nix-rebuild && exec zsh

# Standard workflow:
nixconf              # Edit config
nix-rebuild          # Build
exec zsh             # Restart shell (CRITICAL!)
myalias              # Test it works
```

**Affected by this:**
- Shell aliases
- Git aliases
- Environment variables
- Shell functions
- Starship prompt changes

---

### Package Added But Command Not Found

**Symptom:**
- Added package to packages.nix
- Ran `nix-rebuild` - succeeded ✅
- Type command - "command not found" ❌

**Why it happens:**
- Package installed to /nix/store/
- Current shell's PATH still has old value

**Solution:**

```bash
# Restart shell to reload PATH
exec zsh

# Verify package installed
which rg  # Should show /nix/store/.../bin/rg
```

---

## Build Errors

### Build Fails with Syntax Errors

**Symptom:**
- `nix-rebuild` fails with Nix syntax error
- Error about missing semicolon or invalid syntax

**Solution:**

```bash
# Show detailed trace
nix-rebuild --show-trace

# Check flake syntax
nix flake check

# Common Nix syntax issues:
# - Missing semicolon at end of line
# - Unclosed quote or bracket
# - Typo in package name
```

### Build Fails - Need to Rollback

**Symptom:**
- Build fails and system is broken
- Need to revert to previous working state

**Solution:**

```bash
# Rollback to previous generation
nix-rollback
exec zsh

# Or manually select generation
darwin-rebuild --list-generations
darwin-rebuild --rollback
```

---

## Shell Issues

### Command Not Found After Install

**Symptom:**
- Just installed nix-darwin
- Commands like `g`, `ll`, `bat` not found

**Solution:**

```bash
# Restart shell
exec zsh

# Or completely restart terminal (Cmd+Q)
```

### Shell Prompt Wrong

**Symptom:**
- Prompt doesn't show profile name
- Should show `personal |` or `work |` but doesn't

**Why it happens:**
- Starship config not loaded
- Wrong profile active

**Solution:**

```bash
# 1. Check active profile
echo $ACTIVE_PROFILE

# 2. If wrong, change in machine-config.nix
code config/machine-config.nix

# 3. Rebuild
nix-rebuild && exec zsh
```

---

## Git Problems

### Commit Blocked by Hooks

**Symptom:**
- `git commit` fails with hook error
- Error about unencrypted secrets or permissions

**Why it happens:**
- Git hooks validate secrets are encrypted (600 permissions)
- Blocks commits with unencrypted sensitive files

**Solution:**

```bash
# Check what's wrong
secrets-status

# If secret files not encrypted:
edit-secrets  # Encrypts secrets.yaml with SOPS

# If permission errors:
chmod 600 ~/.db/*
chmod 600 ~/.aws/credentials

# Verify and retry
secrets-status
git commit -m "..."
```

### Git Email Wrong

**Symptom:**
- Git commits have wrong email
- Should be personal email on personal machine, work email on work machine

**Why it happens:**
- Profile-specific email not set correctly

**Solution:**

```bash
# Check current email
g config user.email

# Check expected email for profile
echo $ACTIVE_PROFILE
# personal → personal email
# work → work email

# If wrong, check profile selection
code config/machine-config.nix

# Or edit git config
code home/_profiles/_template/programs/git.nix
```

---

## Secrets Issues

### Placeholder Detection

**Symptom:**
- `./scripts/activate.sh` fails with placeholder warnings
- "Found <PLACEHOLDER> in secrets template"

**Why it happens:**
- Secret templates contain placeholder values
- Must be replaced with real values before encryption

**Solution:**

```bash
# 1. Edit secret template
code hosts/$(hostname)/secrets-personal.nix
# or
code hosts/$(hostname)/secrets-work.nix

# 2. Replace all <PLACEHOLDER> values with real secrets:
# api_keys = {
#   openai = "<PLACEHOLDER>";  # ← Replace this
# };
#
# Becomes:
# api_keys = {
#   openai = "sk-actual-key-here";
# };

# 3. Run activation again
./scripts/activate.sh
```

### Age Key Problems

**Symptom:**
- Can't decrypt secrets
- "Error: no age key found"

**Why it happens:**
- Age encryption key missing or incorrect
- Key generated by configure.sh but not found

**Solution:**

```bash
# Check age keys exist
ls ~/.config/sops/age/

# If missing, regenerate with configure.sh
./scripts/configure.sh

# Or manually create age key
age-keygen -o ~/.config/sops/age/keys.txt
```

### Secrets Won't Decrypt

**Symptom:**
- `edit-secrets` fails
- "Failed to decrypt"

**Why it happens:**
- Wrong age key being used
- Secrets encrypted with different key

**Solution:**

```bash
# Check secrets status
secrets-status

# Check SOPS config
cat .sops.yaml

# Re-encrypt with current age key
# (backup first!)
cp hosts/$(hostname)/secrets.yaml hosts/$(hostname)/secrets.yaml.backup

# Re-run configure.sh to regenerate secrets
./scripts/configure.sh
```

---

## Emergency Recovery

### System Completely Broken

**Symptoms:**
- Can't build
- Can't rollback
- Terminal doesn't work

**Emergency Steps:**

```bash
# 1. Boot into Recovery Mode (Apple Silicon)
# Power off → Hold power button → Select Options

# 2. Open Terminal

# 3. Rollback to last working generation
/nix/var/nix/profiles/system/bin/darwin-rebuild --rollback

# 4. Reboot
sudo reboot
```

### Nuclear Option - Complete Reset

**Only if everything else fails:**

```bash
# 1. Backup your changes
cd ~/nix-darwin
git stash
cp -r config ~/config-backup

# 2. Uninstall nix-darwin
sudo /nix/nix-installer uninstall

# 3. Remove Nix completely
sudo rm -rf /nix

# 4. Remove configs
rm -rf ~/.zshrc ~/.gitconfig ~/.config/nix

# 5. Restart from scratch
# Follow installation guide
```

### Preserve Configuration

**Before nuclear option, backup:**

```bash
# Backup everything important
mkdir -p ~/nix-darwin-backup
cp -r ~/nix-darwin ~/nix-darwin-backup/
cp -r ~/.config/sops ~/nix-darwin-backup/sops-keys
cp ~/.aws/credentials ~/nix-darwin-backup/ (if exists)

# Document current state
cd ~/nix-darwin
echo "Backed up on $(date)" > ~/nix-darwin-backup/backup-info.txt
darwin-rebuild --list-generations >> ~/nix-darwin-backup/backup-info.txt
```

---

## Getting More Help

### Health Check

```bash
# Run system health check
health-check

# Shows:
# - Nix version
# - Active profile
# - Config files status
# - Secrets status
# - Git hooks status
```

### Detailed Debug Information

```bash
# Show full build trace
nix-rebuild --show-trace

# Check flake inputs
nix flake metadata

# Validate flake
nix flake check

# Show system info
darwin-rebuild --version
nix --version
echo $ACTIVE_PROFILE
echo $MACHINE_MODE
hostname
```

### Log Files

```bash
# System build logs
/nix/var/nix/profiles/system/activate.log

# Nix daemon logs
sudo launchctl list | grep nix
sudo tail -f /var/log/nix-daemon.log
```

---

## Common Issues After v2.0.0 Upgrade

### Upgraded but build fails

**Solution:**
```bash
# Run configure.sh to generate config files
./scripts/configure.sh

# Then activate
./scripts/activate.sh
```

### Wrong profile active after upgrade

**Solution:**
```bash
# Edit machine config
code config/machine-config.nix

# Set correct profileName
# Rebuild
nix-rebuild && exec zsh
```

### Secrets not working after upgrade

**Solution:**
```bash
# Check age keys
ls ~/.config/sops/age/

# Re-encrypt secrets if needed
./scripts/configure.sh  # Regenerates age keys
edit-secrets  # Re-encrypt secrets.yaml
```

---

## Related Documentation

- [Installation Guide](installation.md) - Setup from scratch
- [Secrets Management](secrets.md) - SOPS encryption details
- [Backup & Recovery](backup-and-recovery.md) - Protect your config
- [AWS Multi-Role Guide](work/aws/aws-multi-role.md) - AWS SSO troubleshooting

---

**Version**: v2.0.0
**Last Updated**: 2025-11-10
**Focus**: Profile system troubleshooting
