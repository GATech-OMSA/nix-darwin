# Backup and Recovery Guide

**Complete backup strategy and disaster recovery**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Two-Tier Backup System](#two-tier-backup-system)
3. [Pre-Rebuild Safety](#pre-rebuild-safety)
4. [Common Workflows](#common-workflows)
5. [Recovery Procedures](#recovery-procedures)

---

## Overview

This system uses a **two-tier backup approach**:

1. **Tier 1: Encrypted Secrets** (sops-nix) - API keys, SSH keys, AWS credentials
2. **Tier 2: User Data** (backup scripts) - Application configs, preferences

Both tiers work together to provide complete system recovery.

---

## Two-Tier Backup System

### Tier 1: Encrypted Secrets (sops-nix)

**Location:** `hosts/*/secrets.yaml` (encrypted in git)

**What's included:**
- API keys (OpenAI, Anthropic, GitHub)
- SSH private keys
- AWS credentials
- Docker registry auth
- GPG keys
- Environment variables (.zsh_secrets)

**Backup:** Automatic via git

**Restore:** Automatic during `nix-rebuild`

**See:** [Secrets Management Guide](secrets.md)

### Tier 2: User Data (backup scripts)

**Location:** `user-data/` (version controlled)

**What's included:**
- VS Code settings, argv.json, snippets, spell dictionary
- Claude Code config
- Continue.dev settings
- Gemini preferences
- iTerm2 preferences
- Cursor configs
- Jupyter/IPython configs
- SSH known_hosts, Zoxide database
- Claude todos

**Commands:**
- `backup-user-data` - Backup configs to user-data/
- `restore-user-data` - Restore configs from user-data/
- `sync-user-data` - Backup + commit + push (recommended)

**Typical workflow:**
```bash
# After changing VS Code settings or other configs
sync-user-data
```

**See:** `user-data/README.md`

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

# 2. Backup user data (if changed)
backup-user-data

# 3. Note current state
darwin-rebuild --list-generations

# 4. Now safe to rebuild
nix-rebuild
```

### Backup Age Key

**CRITICAL:** Your age private key is the ONLY way to decrypt secrets!

**Method 1: Password Manager (Recommended)**
```bash
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into 1Password/Bitwarden
```

**Method 2: Encrypted USB Drive**
```bash
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/age-keys/mbp-jimmy-key.txt
```

**Method 3: Print on Paper**
```bash
cat ~/.config/sops/age/keys.txt
# Print and store in safe
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

# 2. Backup user data
backup-user-data

# 3. Make changes
nixconf
# Edit packages, aliases, etc.

# 4. Rebuild
nix-rebuild

# 5. Test thoroughly

# 6. If works, commit
g aa
g cm "Update packages"
g ps

# 7. If breaks, rollback
nix-rollback
exec zsh
```

### Workflow 2: New Machine Setup

**On new machine:**

```bash
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Restore age key
mkdir -p ~/.config/sops/age
# Copy from password manager or backup
nano ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# 3. Clone nix-darwin
git clone <repo> ~/nix-darwin
cd ~/nix-darwin

# 4. Copy user-data backup
cp -r /Volumes/BackupDrive/userdata/* user-data/

# 5. First build (auto-decrypts secrets)
sudo scutil --set HostName mbp-jimmy
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy

# 6. Restore user data
cd user-data
./restore.sh

# 7. Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 8. Install Zsh plugins
./scripts/install-zsh-plugins.sh

# 9. Restart
exec zsh
```

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

# 4. If config is bad, revert git changes
cd ~/nix-darwin
g l  # Find last working commit
g reset --hard <commit-hash>
nix-rebuild

# 5. If all else fails, restore from backup
# Use external backup of ~/nix-darwin
# Restore age key
# Run nix-rebuild
```

### Workflow 4: Scheduled Backups

**Weekly backup routine:**

```bash
#!/bin/bash
# Save as ~/bin/weekly-backup.sh

cd ~/nix-darwin

# Backup user data
backup-user-data

# Commit if changes
if [[ -n $(g status -s) ]]; then
  g aa
  g cm "Auto-backup: $(date)"
  g ps
fi

# Copy to external drive
cp -r user-data /Volumes/BackupDrive/nix-darwin-userdata-$(date +%Y%m%d)

echo "Backup complete: $(date)"
```

---

## Recovery Procedures

### Quick Rollback

**After bad rebuild:**

```bash
# Instant undo
nix-rollback
exec zsh
# Everything reverted!
```

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
sudo nix run nix-darwin -- switch --flake .
```

### Nuclear Option - Full Reinstall

**Last resort:**

```bash
# 1. Backup important data
cp -r ~/Dev ~/Dev.backup
cp ~/.zsh_secrets ~/.zsh_secrets.backup
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

## Rollback Guide

### View Generations

```bash
# List all generations
darwin-rebuild --list-generations
```

Output:
```
Generation 10: 2024-01-10 10:30:00
Generation 11: 2024-01-11 09:15:00
Generation 12: 2024-01-15 14:20:00 (current)
```

### Switch to Generation

```bash
# Go to generation 11
sudo darwin-rebuild switch --switch-generation 11

# Restart shell
exec zsh
```

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
```

---

## Backup Checklist

### Before Major Changes

- [ ] Commit current configuration to git
- [ ] Tag stable version
- [ ] Push to remote repository
- [ ] Run `backup-user-data`
- [ ] Copy user-data to external drive
- [ ] Verify age key is backed up
- [ ] Note current generation number

### Weekly Maintenance

- [ ] Run `backup-user-data`
- [ ] Commit any config changes
- [ ] Copy to external drive
- [ ] Verify backups are accessible
- [ ] Test restore on one file

### Before New Machine Setup

- [ ] Export current packages: `brew list`
- [ ] Backup age key to password manager
- [ ] Copy user-data to external drive
- [ ] Verify git repository is up to date
- [ ] Document any manual setup steps

---

## Restore Checklist

### New Machine Setup

- [ ] Install Nix
- [ ] Restore age key
- [ ] Clone nix-darwin repository
- [ ] Copy user-data backup
- [ ] Set correct hostname
- [ ] Run initial nix-darwin build
- [ ] Run restore-user-data script
- [ ] Install Oh-My-Zsh
- [ ] Install Zsh plugins
- [ ] Verify secrets decrypted
- [ ] Test all critical functions

---

## Links

- **[Secrets Management](secrets.md)** - sops-nix setup
- **[User Data README](../../user-data/README.md)** - Backup script details
- **[Installation Guide](installation.md)** - New machine setup
- **[Troubleshooting](troubleshooting.md)** - Recovery procedures

---
