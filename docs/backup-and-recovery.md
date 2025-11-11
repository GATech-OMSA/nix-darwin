# Backup and Recovery Guide

**Complete backup strategy and disaster recovery - v2.0.0**

**Last Updated**: 2025-11-10 (v2.0.0 - Profile architecture)

---

## Table of Contents

1. [Overview](#overview)
2. [Critical Files to Backup](#critical-files-to-backup)
3. [Two-Tier Backup System](#two-tier-backup-system)
4. [Pre-Rebuild Safety](#pre-rebuild-safety)
5. [Common Workflows](#common-workflows)
6. [Recovery Procedures](#recovery-procedures)
7. [Backup Checklists](#backup-checklists)

---

## Overview

**v2.0.0 introduces new backup requirements:**

- **Gitignored config files** - Machine-specific configs not in repository
- **SOPS age keys** - Required for secret decryption
- **Profile-specific data** - Different profiles have different backup needs
- **Workspace directory** - Machine-specific workspace data

This system uses a **two-tier backup approach**:

1. **Tier 1: Encrypted Secrets** (SOPS age) - API keys, credentials, SSH keys
2. **Tier 2: User Data** (workspace/) - Application configs, preferences

Both tiers work together to provide complete system recovery.

---

## Critical Files to Backup

### 🔴 CRITICAL - Cannot Recover Without These

**1. Age Encryption Keys** (Required for secret decryption)
```bash
~/.config/sops/age/keys.txt
```

**Backup methods:**
```bash
# Method 1: Password Manager (Recommended)
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into 1Password/Bitwarden as "nix-darwin age key"

# Method 2: Encrypted USB Drive
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/age-keys/$(hostname)-key.txt

# Method 3: Print on Paper (Air-gapped backup)
cat ~/.config/sops/age/keys.txt
# Print and store in safe
```

**2. Machine Configuration Files** (Gitignored - not in repository)
```bash
config/user-config.nix       # Your username, email, fullName
config/machine-config.nix    # Machine ID, profile selection
```

**Backup:**
```bash
# Backup to workspace
mkdir -p workspace/$(hostname)/config-backup
cp config/user-config.nix workspace/$(hostname)/config-backup/
cp config/machine-config.nix workspace/$(hostname)/config-backup/

# Or to external drive
cp config/*.nix /Volumes/BackupDrive/nix-darwin-config-$(date +%Y%m%d)/
```

**3. Encrypted Secrets** (Committed to git, but backup separately)
```bash
hosts/$(hostname)/secrets.yaml        # Encrypted with age
```

**Recovery:** Age keys required to decrypt

---

## Two-Tier Backup System

### Tier 1: Encrypted Secrets (SOPS age)

**Location:** `hosts/$(hostname)/secrets.yaml` (encrypted in git)

**What's included:**
- API keys (OpenAI, Anthropic, GitHub)
- SSH private keys
- AWS credentials
- Environment variables (.zsh_secrets)
- Database connection credentials
- Docker registry auth

**Backup:** Automatic via git (encrypted form)

**Restore:** Automatic during `./scripts/activate.sh` or `nix-rebuild`

**Requirement:** Age private key in `~/.config/sops/age/keys.txt`

**See:** [Secrets Management Guide](SECRETS.md)

---

### Tier 2: User Data (workspace/)

**Location:** `workspace/$(hostname)/` (gitignored)

**What's included:**
- Application configs (VS Code, Claude Code, Cursor)
- User preferences
- Backups (age key backups, secret backups)
- App-specific configs (claude.json with UUIDs)
- User content (todos, session data)

**v2.0.0 Structure:**
```
workspace/$(hostname)/
├── app-configs/           # Application-specific configs
│   ├── claude.json        # Claude Code (PII: email, UUIDs)
│   ├── cursor/            # Cursor configs
│   └── vscode/            # VS Code settings
├── user-content/          # User-generated content
│   └── claude/            # Todos, session data
└── backups/               # Local backups
    ├── age-keys/          # Age key backups
    └── secrets/           # Secret backups
```

**Backup commands:**
```bash
# Backup entire workspace
cp -r workspace/$(hostname) /Volumes/BackupDrive/workspace-backup-$(date +%Y%m%d)

# Backup specific app configs
cp -r workspace/$(hostname)/app-configs /Volumes/BackupDrive/app-configs-$(date +%Y%m%d)
```

---

## Pre-Rebuild Safety

### Before Every Rebuild

**Run pre-rebuild checklist:**

```bash
# 1. Commit current state
cd ~/nix-darwin
g s
g aa
g cm "Pre-rebuild backup: $(date)"
g ps

# 2. Backup gitignored config files
mkdir -p workspace/$(hostname)/config-backup
cp config/user-config.nix workspace/$(hostname)/config-backup/
cp config/machine-config.nix workspace/$(hostname)/config-backup/

# 3. Note current state
darwin-rebuild --list-generations

# 4. Now safe to rebuild
nix-rebuild
```

---

### Backup Age Key (CRITICAL)

**Your age private key is the ONLY way to decrypt secrets!**

**Without this key:**
- ❌ Cannot decrypt secrets.yaml
- ❌ Cannot access AWS credentials
- ❌ Cannot access API keys
- ❌ Cannot access SSH keys
- ❌ System cannot be fully restored

**Backup immediately after running `./scripts/configure.sh`:**

```bash
# Method 1: Password Manager (Recommended)
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into 1Password/Bitwarden
# Title: "nix-darwin age key - $(hostname)"
# Include: Machine name, date created

# Method 2: Encrypted USB Drive
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/age-keys/$(hostname)-key-$(date +%Y%m%d).txt
chmod 600 /Volumes/SecureBackup/age-keys/$(hostname)-key-$(date +%Y%m%d).txt

# Method 3: Print on Paper (Air-gapped)
cat ~/.config/sops/age/keys.txt
# Print and store in physical safe
# Label: "nix-darwin age key - $(hostname) - $(date +%Y-%m-%d)"
```

**Verify backup:**
```bash
# Check key exists in password manager or backup location
# Test decryption works:
sops --decrypt hosts/$(hostname)/secrets.yaml
```

---

## Common Workflows

### Workflow 1: Pre-Rebuild Backup

**Before major changes:**

```bash
cd ~/nix-darwin

# 1. Commit current config
g aa
g cm "Stable config before updating packages"
g tag stable-$(date +%Y%m%d)
g ps
g push --tags

# 2. Backup gitignored configs
mkdir -p workspace/$(hostname)/config-backup-$(date +%Y%m%d)
cp config/*.nix workspace/$(hostname)/config-backup-$(date +%Y%m%d)/

# 3. Make changes
nixconf
# Edit packages, aliases, etc.

# 4. Rebuild
nix-rebuild

# 5. Test thoroughly
echo $ACTIVE_PROFILE  # Check profile is correct
which rg              # Check new packages work

# 6. If works, commit
g aa
g cm "Update packages"
g ps

# 7. If breaks, rollback
nix-rollback
exec zsh
```

---

### Workflow 2: New Machine Setup

**On new machine:**

```bash
# 1. Install Nix + nix-darwin + SOPS + age
cd ~/nix-darwin
./scripts/bootstrap.sh

# 2. Restore age key (CRITICAL - do this first!)
mkdir -p ~/.config/sops/age
# Copy from password manager or backup
nano ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Verify age key works
cat ~/.config/sops/age/keys.txt
# Should show: AGE-SECRET-KEY-1...

# 4. Clone nix-darwin repository
git clone <repo> ~/nix-darwin
cd ~/nix-darwin

# 5. Run configuration wizard
./scripts/configure.sh
# - Enter username, email, fullName
# - Select machine profile (personal/work/minimal)
# - Wizard will generate config/user-config.nix and config/machine-config.nix

# 6. Activate system (first build)
./scripts/activate.sh
# This will:
# - Build nix-darwin configuration
# - Decrypt secrets.yaml with age key
# - Apply system settings
# - Set up shell environment

# 7. Restore workspace data (if from backup)
cp -r /Volumes/BackupDrive/workspace-backup/* workspace/$(hostname)/

# 8. Restart shell
exec zsh

# 9. Verify
echo $ACTIVE_PROFILE        # Should show: personal, work, or minimal
secrets-status              # Should show: All secrets decrypted ✅
```

---

### Workflow 3: Disaster Recovery

**If system breaks:**

```bash
# 1. Try rollback first
nix-rollback
exec zsh

# 2. If still broken, check generations
darwin-rebuild --list-generations

# 3. Switch to specific working generation
sudo darwin-rebuild switch --switch-generation 10
exec zsh

# 4. If config is bad, revert git changes
cd ~/nix-darwin
g l  # Find last working commit
g reset --hard <commit-hash>
nix-rebuild

# 5. If gitignored configs are corrupt, restore from backup
cp workspace/$(hostname)/config-backup/* config/

# 6. If age key is lost, restore from password manager
mkdir -p ~/.config/sops/age
# Copy from backup
nano ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 7. Rebuild
./scripts/activate.sh
```

---

### Workflow 4: Profile Switching Backup

**When switching profiles (personal ↔ work):**

```bash
cd ~/nix-darwin

# 1. Backup current profile state
mkdir -p workspace/$(hostname)/profile-backups/$(echo $ACTIVE_PROFILE)-$(date +%Y%m%d)
cp config/machine-config.nix workspace/$(hostname)/profile-backups/$(echo $ACTIVE_PROFILE)-$(date +%Y%m%d)/

# 2. Switch profile
scripts/switch-profile.sh work  # or personal

# 3. If issues, restore previous profile
cp workspace/$(hostname)/profile-backups/personal-*/machine-config.nix config/
nix-rebuild && exec zsh
```

---

### Workflow 5: Weekly Backup Routine

**Recommended weekly maintenance:**

```bash
#!/bin/bash
# Save as ~/bin/weekly-backup.sh

cd ~/nix-darwin

# 1. Backup gitignored configs
mkdir -p workspace/$(hostname)/weekly-backup-$(date +%Y%m%d)
cp config/*.nix workspace/$(hostname)/weekly-backup-$(date +%Y%m%d)/

# 2. Backup age key
mkdir -p workspace/$(hostname)/backups/age-keys
cp ~/.config/sops/age/keys.txt workspace/$(hostname)/backups/age-keys/backup-$(date +%Y%m%d).txt

# 3. Commit any config changes
if [[ -n $(g status -s) ]]; then
  g aa
  g cm "Auto-backup: $(date)"
  g ps
fi

# 4. Copy workspace to external drive
cp -r workspace/$(hostname) /Volumes/BackupDrive/nix-darwin-workspace-$(date +%Y%m%d)

echo "✅ Backup complete: $(date)"
```

---

## Recovery Procedures

### Quick Rollback

**After bad rebuild:**

```bash
# Instant undo
nix-rollback
exec zsh
# Everything reverted to previous generation!
```

---

### Rollback Specific File

**Restore single config:**

```bash
cd ~/nix-darwin

# View changes
g diff home/jimmy/shell/zsh.nix

# Restore to last commit
g restore home/jimmy/shell/zsh.nix

# Rebuild
nix-rebuild
```

---

### Rollback Flake Update

**After `nix flake update` breaks things:**

```bash
cd ~/nix-darwin

# Undo flake update
g restore flake.lock

# Rebuild with old lock
nix-rebuild

# If committed, revert
g revert HEAD
nix-rebuild
```

---

### Emergency Recovery

**System completely broken:**

```bash
# 1. Boot to recovery mode (Cmd+R during startup)

# 2. Use terminal in recovery

# 3. Remove Nix symlinks
rm /etc/zshrc
rm /etc/bashrc

# 4. Reboot normally

# 5. Reinstall
cd ~/nix-darwin

# Restore age key first!
mkdir -p ~/.config/sops/age
# Copy from backup
nano ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Run activation
./scripts/activate.sh
```

---

### Nuclear Option - Full Reinstall

**Last resort:**

```bash
# 1. Backup critical data
mkdir -p ~/emergency-backup
cp -r ~/Dev ~/emergency-backup/
cp ~/.config/sops/age/keys.txt ~/emergency-backup/age-key.txt
cp -r ~/nix-darwin/config ~/emergency-backup/
cp -r ~/nix-darwin/workspace/$(hostname) ~/emergency-backup/workspace

# 2. Uninstall Nix
sudo /nix/nix-installer uninstall
sudo rm -rf /nix

# 3. Remove configs
rm ~/.zshrc ~/.gitconfig

# 4. Reinstall from scratch
cd ~/nix-darwin
./scripts/bootstrap.sh

# 5. Restore age key
mkdir -p ~/.config/sops/age
cp ~/emergency-backup/age-key.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 6. Restore configs
cp ~/emergency-backup/config/* ~/nix-darwin/config/

# 7. Activate
./scripts/activate.sh

# 8. Restore workspace
cp -r ~/emergency-backup/workspace ~/nix-darwin/workspace/$(hostname)
```

---

## Backup Checklists

### Before Major Changes

- [ ] Commit current configuration to git
- [ ] Tag stable version: `g tag stable-$(date +%Y%m%d)`
- [ ] Push to remote repository: `g ps && g push --tags`
- [ ] Backup gitignored configs: `cp config/*.nix workspace/$(hostname)/config-backup/`
- [ ] Verify age key is backed up in password manager
- [ ] Note current generation number: `darwin-rebuild --list-generations`
- [ ] Copy workspace to external drive (if critical data)

---

### Weekly Maintenance

- [ ] Backup gitignored configs to workspace
- [ ] Backup age key to workspace/backups/age-keys/
- [ ] Commit any config changes to git
- [ ] Copy workspace to external drive
- [ ] Verify backups are accessible
- [ ] Test restore on one file
- [ ] Run `health-check` to verify system status

---

### Before New Machine Setup

- [ ] Export current profile: `echo $ACTIVE_PROFILE`
- [ ] Backup age key to password manager (CRITICAL)
- [ ] Backup gitignored configs: config/user-config.nix, config/machine-config.nix
- [ ] Copy workspace directory to external drive
- [ ] Verify git repository is up to date: `g ps`
- [ ] Document any manual setup steps
- [ ] Note which profile was active (personal/work/minimal)

---

### New Machine Restore

- [ ] Install Nix via bootstrap.sh
- [ ] Restore age key to ~/.config/sops/age/keys.txt (CRITICAL - do first!)
- [ ] Verify age key: `cat ~/.config/sops/age/keys.txt`
- [ ] Clone nix-darwin repository
- [ ] Run configuration wizard: `./scripts/configure.sh`
- [ ] Activate system: `./scripts/activate.sh`
- [ ] Verify secrets decrypted: `secrets-status`
- [ ] Restore workspace data from backup
- [ ] Verify profile active: `echo $ACTIVE_PROFILE`
- [ ] Test all critical functions

---

## Profile-Specific Backup Considerations

### Personal Profile

**Additional backup needs:**
- Personal aliases (home/_profiles/personal/aliases.nix)
- Personal Git email (set in config/user-config.nix)
- Personal SSH keys (encrypted in secrets.yaml)

**Not in backups (by design):**
- Work databases
- Work AWS credentials
- Work-specific aliases

---

### Work Profile

**Additional backup needs:**
- Work database connections (home/_profiles/work/databases.nix)
- AWS SSO configuration (~/.aws/config generated, but source in home/_profiles/work/aws.nix)
- AWS account mappings (~/.aws/accounts.json - gitignored, manual backup)
- Work-specific aliases (home/_profiles/work/aliases.nix)

**CRITICAL for work profile:**
```bash
# Backup AWS accounts.json (if exists)
cp ~/.aws/accounts.json workspace/$(hostname)/backups/aws-accounts-$(date +%Y%m%d).json

# Backup work-specific configs
cp config/machine-config.nix workspace/$(hostname)/backups/work-config-$(date +%Y%m%d).nix
```

---

### Minimal Profile

**Minimal backup needs:**
- Just core configs (config/user-config.nix, config/machine-config.nix)
- Age key (always required)
- No profile-specific data

**Purpose:** Troubleshooting only, not for daily use

---

## Rollback Guide

### View Generations

```bash
# List all generations
darwin-rebuild --list-generations
```

Output:
```
Generation 10: 2024-11-08 10:30:00
Generation 11: 2024-11-09 09:15:00
Generation 12: 2024-11-10 14:20:00 (current)
```

---

### Switch to Generation

```bash
# Go to generation 11
sudo darwin-rebuild switch --switch-generation 11

# Restart shell
exec zsh

# Verify
echo $ACTIVE_PROFILE
darwin-rebuild --list-generations
```

---

### Git Rollback

**Undo last commit:**
```bash
cd ~/nix-darwin
g reset HEAD~1  # Keeps changes
# or
g reset --hard HEAD~1  # Discards changes
```

**Revert specific commit:**
```bash
g l  # View history
g revert <commit-hash>
```

---

### Test Before Committing

**Safe experimentation:**

```bash
# 1. Commit working state
g aa && g cm "Working config" && g ps

# 2. Make experimental changes
nixconf

# 3. Test
nix-rebuild
exec zsh

# 4. If works, commit
g aa && g cm "Add feature" && g ps

# 5. If doesn't work, rollback
nix-rollback
g reset --hard HEAD
exec zsh
```

---

## Links

- **[Installation Guide](INSTALLATION.md)** - New machine setup with v2.0.0
- **[Secrets Management](SECRETS.md)** - SOPS age encryption setup
- **[Troubleshooting](TROUBLESHOOTING.md)** - Recovery procedures
- **[AWS Multi-Role Guide](../reference/aws/AWS-MULTI-ROLE.md)** - Work profile AWS setup

---

**Version**: v2.0.0
**Last Updated**: 2025-11-10
**Focus**: Profile architecture backup requirements
