# Security Configuration Guide

**Comprehensive security best practices for nix-darwin configuration**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Security Layers](#security-layers)
3. [Secrets Management](#secrets-management)
4. [File Permissions](#file-permissions)
5. [Git Security](#git-security)
6. [Network Security](#network-security)
7. [System Hardening](#system-hardening)
8. [Security Validation](#security-validation)
9. [Incident Response](#incident-response)
10. [Security Checklist](#security-checklist)

---

## Overview

This nix-darwin configuration implements **defense-in-depth** security with multiple layers:

- **Encryption at rest**: SOPS-encrypted secrets
- **Access control**: 600 permissions on credentials
- **Automated validation**: Git hooks prevent insecure commits
- **Secret isolation**: Gitignored credential directories
- **Audit trail**: Git history for configuration changes

### Security Philosophy

**Three core principles:**

1. **Prevention > Detection** - Block security issues before they occur
2. **Automation > Manual** - Automated checks catch human errors
3. **Fail-Safe > Fail-Silent** - Block commits on security violations

---

## Security Layers

### Layer 1: Encryption (SOPS)

**What:** Encrypt all secrets at rest using age encryption

**Protects against:**
- Accidental secret exposure in git
- Unauthorized access to configuration repo
- Secret leakage in backups

**Implementation:**
```bash
# All secrets encrypted with age
sops hosts/mbp-jimmy/secrets.yaml

# Verification
cat hosts/mbp-jimmy/secrets.yaml | head -5
# Should see: ENC[AES256_GCM,data:...]
```

**See:** [Secrets Guide](secrets.md) for complete SOPS setup

### Layer 2: File Permissions

**What:** 600 permissions (owner read/write only) on all credential files

**Protects against:**
- Other users on system reading credentials
- Accidental world-readable credential files
- Group access to sensitive data

**Implementation:**
```bash
# Automatically validated by git hooks
chmod 600 ~/.aws/credentials
chmod 600 ~/.db/oracle/prod
chmod 600 ~/.tokens/github_token

# Verification
ls -la ~/.aws/credentials
# Should show: -rw------- (600)
```

### Layer 3: Git Hooks

**What:** Pre-commit and pre-push validation of security posture

**Protects against:**
- Committing unencrypted secrets
- Pushing files with insecure permissions
- Accidental credential exposure

**Implementation:**
- `.git/hooks/pre-commit` - Blocks commits (BLOCKING)
- `.git/hooks/pre-push` - Final safeguard before push
- Automatically installed, locally executed

**See:** [Git Security](#git-security) for details

### Layer 4: Gitignore

**What:** Never track credential directories in git

**Protects against:**
- Accidentally adding credential files to git
- Secret leakage in repository

**Protected paths:**
```
~/.db/*
~/.tokens/*
~/.credentials/*
user-data/secrets/*
```

### Layer 5: Secret Registry

**What:** Centralized list of all credential paths

**Protects against:**
- Forgetting to protect new credential types
- Inconsistent validation across scripts

**Implementation:**
```nix
# lib/secrets.nix
secretPaths = [
  "\${HOME}/.aws/credentials"
  "\${HOME}/.db/*"
  "\${HOME}/.tokens/*"
  # ...
];
```

---

## Secrets Management

### SOPS Encryption

**Best practices:**

✅ **Always use `edit-secrets` to modify secrets**
```bash
edit-secrets  # Automatically encrypts on save
```

✅ **Verify encryption before committing**
```bash
cat hosts/mbp-jimmy/secrets.yaml | grep "ENC\["
# Should see encrypted data
```

✅ **Backup age key immediately**
```bash
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into password manager
```

❌ **Never edit `~/.zsh_secrets` directly** (managed by sops-nix)

❌ **Never commit unencrypted secrets.yaml**

### Secret Types

**Encrypted with SOPS:**
- API keys (OpenAI, Anthropic, GitHub)
- SSH private keys
- AWS credentials
- Environment variables (.zsh_secrets)

**Gitignored (not tracked):**
- Database connection files (`~/.db/*`)
- API tokens (`~/.tokens/*`)
- Generic credentials (`~/.credentials/*`)
- User secrets (`user-data/secrets/*`)

**Safe to commit:**
- System configuration (flake.nix, modules/)
- Shell configuration (zsh.nix, git.nix)
- Application settings (VS Code extensions)

### Age Key Management

**Critical:** Your age private key is the master key for all secrets

**Backup strategy:**

1. **Primary backup:** Password manager (1Password, Bitwarden)
   ```bash
   cat ~/.config/sops/age/keys.txt | pbcopy
   ```

2. **Secondary backup:** Encrypted USB drive
   ```bash
   cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/
   ```

3. **Verify backup:** Test decryption
   ```bash
   sops -d hosts/mbp-jimmy/secrets.yaml
   ```

**Key rotation:**

Only rotate if key is compromised or lost:

```bash
# Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# Get new public key
grep "public key:" ~/.config/sops/age/keys-new.txt

# Update .sops.yaml with new public key
code ~/nix-darwin/secrets/.sops.yaml

# Re-encrypt all secrets
sops updatekeys hosts/mbp-jimmy/secrets.yaml
sops updatekeys hosts/mbp-work/secrets.yaml

# Replace old key
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt

# Backup new key
cat ~/.config/sops/age/keys.txt | pbcopy
```

---

## File Permissions

### Permission Requirements

**All credential files MUST be 600:**

```bash
# AWS credentials
chmod 600 ~/.aws/credentials

# Database connections
chmod 600 ~/.db/oracle/prod
chmod 600 ~/.db/postgres/dev

# API tokens
chmod 600 ~/.tokens/github_token
chmod 600 ~/.tokens/openai_key

# SSH keys
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519_work
```

### Why 600?

**Permission breakdown:**
- `6` (owner) = read + write
- `0` (group) = no access
- `0` (other) = no access

**Without 600:**
```bash
# Bad: 644 (world-readable)
-rw-r--r--  ~/.aws/credentials  # ❌ Other users can read!

# Good: 600 (owner-only)
-rw-------  ~/.aws/credentials  # ✅ Only you can read
```

### Symlink Handling

Git hooks follow symlinks to check target permissions:

```bash
# Example: VS Code settings symlink
ln -s ~/nix-darwin/user-data/vscode/settings.json ~/.config/Code/User/settings.json

# Hook checks target file permissions
chmod 600 ~/nix-darwin/user-data/vscode/settings.json
```

### Bulk Permission Fix

```bash
# Fix all AWS credentials
find ~/.aws -type f -exec chmod 600 {} \;

# Fix all database credentials
find ~/.db -type f -exec chmod 600 {} \;

# Fix all API tokens
find ~/.tokens -type f -exec chmod 600 {} \;

# Fix all SSH keys
find ~/.ssh -type f -name "id_*" -not -name "*.pub" -exec chmod 600 {} \;
```

---

## Git Security

### Pre-Commit Hook

**Purpose:** Block commits with security violations

**What it checks:**

1. **File permissions** (BLOCKING)
   - All credential files must be 600
   - Checks symlink targets correctly

2. **SOPS encryption** (BLOCKING)
   - All `secrets.yaml` files must be encrypted
   - Validates SOPS metadata and MAC signature

3. **Documentation links** (BLOCKING for docs/)
   - Validates internal links when docs/ changes

**Example output:**

✅ **All checks pass:**
```
🔍 Validating file permissions...
   ✅ All credential files have secure permissions (600)

🔍 Validating secrets encryption...
   ✅ All secrets files are properly encrypted

✅ All security checks passed
```

❌ **Permission violation:**
```
🔍 Validating file permissions...

❌ BLOCKED: Insecure file permissions detected

File: ~/.aws/credentials
Current: 644 (readable by group and others)
Required: 600 (owner read/write only)

Fix with:
  chmod 600 ~/.aws/credentials

Or skip this check (NOT RECOMMENDED):
  git commit --no-verify
```

❌ **Unencrypted secrets:**
```
🔍 Validating secrets encryption...

❌ BLOCKED: Unencrypted secrets files detected

File: hosts/mbp-work/secrets.yaml
Status: Missing SOPS metadata or MAC signature

Fix with:
  sops -e -i hosts/mbp-work/secrets.yaml
```

### Pre-Push Hook

**Purpose:** Final safeguard before remote push

**What it checks:**
- All secrets files in repository are encrypted
- Catches anything that bypassed pre-commit (e.g., `--no-verify`)

### Bypassing Hooks

**When to use `--no-verify`:**

✅ **Valid reasons:**
- Emergency production fix
- Reverting broken change
- Hook incorrectly blocking valid change (report issue!)

❌ **Invalid reasons:**
- "I'll fix permissions later"
- "The warning is annoying"
- "It's just a dev environment"

**How to bypass:**
```bash
# Emergency only!
git commit --no-verify -m "emergency fix"
git push --no-verify
```

**After bypass:** Fix the underlying issue IMMEDIATELY!

### Manual Validation

Run checks without committing:

```bash
# Comprehensive security check
secrets-check

# Or run hook directly
./.git/hooks/pre-commit

# Or run validation script
./scripts/check-secrets-encrypted.sh
```

---

## Network Security

### AWS Credentials

**Multi-role security:**

**Personal Mac:**
- Single AWS profile: `personal`
- Credentials in `~/.aws/credentials`
- No work-related access

**Work Mac:**
- Multiple profiles with SSO
- Role-based access control
- Session token management

**Best practices:**

✅ **Use SSO when available**
```bash
awslogin  # Work Mac only
```

✅ **Rotate credentials regularly**
```bash
# Edit credentials
edit-secrets

# Update AWS keys section
# Rebuild to apply
nix-rebuild
```

✅ **Use least-privilege profiles**
```bash
# Use specific profile, not default
export AWS_PROFILE=readonly
aws s3 ls
```

❌ **Never hardcode credentials in scripts**
```bash
# Bad
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"

# Good - use credentials file
export AWS_PROFILE=personal
```

### SSH Keys

**Key management:**

```bash
# Personal key
~/.ssh/id_ed25519       # Private (600)
~/.ssh/id_ed25519.pub   # Public (644)

# Work key (if separate)
~/.ssh/id_ed25519_work       # Private (600)
~/.ssh/id_ed25519_work.pub   # Public (644)
```

**SSH config security:**
```bash
# ~/.ssh/config
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes  # Don't try other keys

Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
```

**Best practices:**

✅ **Use ed25519 keys** (not RSA)
```bash
ssh-keygen -t ed25519 -C "your@email.com"
```

✅ **Passphrase-protect keys**
```bash
# Use SSH agent to avoid re-entering
ssh-add ~/.ssh/id_ed25519
```

✅ **Separate work and personal keys**

❌ **Never share private keys**
❌ **Never commit private keys unencrypted**

---

## System Hardening

### macOS Security Settings

**Managed by nix-darwin:**

```nix
# modules/darwin/system.nix
system.defaults = {
  # Require password immediately after sleep
  screensaver.askForPasswordDelay = 0;

  # Disable guest account
  loginwindow.GuestEnabled = false;

  # Enable firewall
  alf.globalstate = 1;
};
```

### Package Security

**Trusted sources:**

1. **nixpkgs** - Primary source (curated, reproducible)
2. **Homebrew** - GUI apps only (Apple-signed)
3. **Custom packages** - Only when necessary (in `pkgs/`)

**Avoid:**
- Downloading and running random scripts
- Installing from untrusted package repositories
- Using `curl | bash` installers

### Secret Isolation

**Principle:** Each credential type in separate directory

```
~/.aws/credentials       # AWS only
~/.db/oracle/prod        # Database only
~/.tokens/github_token   # API tokens only
~/.credentials/          # Generic credentials
```

**Benefits:**
- Easier permission management
- Clearer audit trail
- Simpler backup strategy

---

## Security Validation

### Health Check

Run comprehensive security validation:

```bash
health-check
```

**Security checks:**
1. SOPS age key exists and valid
2. Secrets files properly encrypted
3. File permissions on credentials
4. Git hooks installed and working

### Pre-Flight Checks

Validate system before rebuild:

```bash
nix-preflight
```

**Security checks:**
1. No uncommitted credential changes
2. Secrets files encrypted
3. Required secrets present

### Manual Audits

**Monthly security audit:**

```bash
# 1. Check credential file permissions
find ~/.aws ~/.db ~/.tokens -type f -exec ls -la {} \;

# 2. Verify secrets encryption
secrets-check

# 3. Review git hooks
cat .git/hooks/pre-commit | grep "EXIT_STATUS"

# 4. Audit recent git commits
g log --oneline -20

# 5. Check for untracked credentials
git status --ignored | grep -E "\.db|\.tokens|credentials"
```

**Quarterly key rotation:**

```bash
# 1. Rotate AWS credentials
aws iam create-access-key

# 2. Update secrets file
edit-secrets

# 3. Rebuild
nix-rebuild

# 4. Test new credentials
aws sts get-caller-identity

# 5. Revoke old credentials
aws iam delete-access-key --access-key-id OLD_KEY
```

---

## Incident Response

### Compromised Credentials

**If credentials are leaked:**

1. **Immediate action:**
   ```bash
   # Revoke compromised credentials in provider (AWS, GitHub, etc.)
   # Do this FIRST before rotating
   ```

2. **Rotate credentials:**
   ```bash
   edit-secrets
   # Replace leaked credentials with new ones
   ```

3. **Rebuild and test:**
   ```bash
   nix-rebuild
   # Verify new credentials work
   ```

4. **Audit access:**
   ```bash
   # Check for unauthorized usage
   aws cloudtrail lookup-events --max-results 50
   ```

5. **Update git history (if committed):**
   ```bash
   # Use git-filter-repo or BFG Repo-Cleaner
   # WARNING: This rewrites history
   git filter-repo --path hosts/mbp-jimmy/secrets.yaml --invert-paths
   ```

### Compromised Age Key

**If age key is compromised:**

1. **Generate new key immediately:**
   ```bash
   age-keygen -o ~/.config/sops/age/keys-new.txt
   ```

2. **Update .sops.yaml:**
   ```bash
   code ~/nix-darwin/secrets/.sops.yaml
   # Replace old public key with new
   ```

3. **Re-encrypt all secrets:**
   ```bash
   sops updatekeys hosts/mbp-jimmy/secrets.yaml
   sops updatekeys hosts/mbp-work/secrets.yaml
   ```

4. **Replace old key:**
   ```bash
   mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt
   ```

5. **Verify and commit:**
   ```bash
   sops -d hosts/mbp-jimmy/secrets.yaml  # Test decryption
   g aa && g cm "Rotate age encryption key" && g ps
   ```

6. **Backup new key:**
   ```bash
   cat ~/.config/sops/age/keys.txt | pbcopy
   # Save to password manager
   ```

### Lost Age Key

**If age key is lost but you have backups:**

1. **Restore from backup:**
   ```bash
   # From password manager or USB backup
   cat > ~/.config/sops/age/keys.txt
   # Paste backup key
   ```

2. **Verify decryption:**
   ```bash
   sops -d hosts/mbp-jimmy/secrets.yaml
   ```

3. **Continue normally**

**If no backup exists:**

❌ **All secrets are PERMANENTLY LOST**

You must:
1. Generate new age key
2. Manually re-create all secrets from original sources
3. Update all secrets files
4. Learn from this mistake - backup immediately!

---

## Security Checklist

### Initial Setup

- [ ] Generate age key
- [ ] Backup age key to password manager
- [ ] Backup age key to encrypted USB
- [ ] Configure .sops.yaml with public key
- [ ] Create encrypted secrets.yaml
- [ ] Verify git hooks installed
- [ ] Test git hook validation
- [ ] Set 600 permissions on all credential files
- [ ] Review gitignore patterns
- [ ] Test secrets-check command

### Daily Operations

- [ ] Use `edit-secrets` for all secret changes
- [ ] Run `nix-preflight` before rebuilds
- [ ] Verify git hooks pass before commit
- [ ] Never use `--no-verify` without reason
- [ ] Check `secrets-status` after rebuild

### Monthly Maintenance

- [ ] Run `health-check` for security validation
- [ ] Audit credential file permissions
- [ ] Review recent git commits
- [ ] Verify all secrets still encrypted
- [ ] Test secret decryption
- [ ] Review git hook logs

### Quarterly Tasks

- [ ] Rotate AWS credentials
- [ ] Review SSH keys (delete unused)
- [ ] Audit access logs
- [ ] Review credential inventory
- [ ] Test backup restoration
- [ ] Update security documentation

### New Machine Setup

- [ ] Generate new age key (or restore backup)
- [ ] Configure .sops.yaml
- [ ] Set up git hooks
- [ ] Set 600 permissions on credentials
- [ ] Test secret decryption
- [ ] Verify security validation

---

## Best Practices Summary

### Do's ✅

- ✅ Use SOPS for all secrets
- ✅ Set 600 permissions on credentials
- ✅ Backup age key immediately
- ✅ Use separate work/personal keys
- ✅ Rotate credentials regularly
- ✅ Verify encryption before committing
- ✅ Run security validation monthly
- ✅ Use git hooks for automation
- ✅ Isolate credentials by type
- ✅ Test backups regularly

### Don'ts ❌

- ❌ Never commit unencrypted secrets
- ❌ Never share age private key
- ❌ Never use 644+ permissions on credentials
- ❌ Don't edit ~/.zsh_secrets directly
- ❌ Don't skip git hook validation
- ❌ Don't store secrets in environment variables
- ❌ Don't hardcode credentials in scripts
- ❌ Don't forget to backup age key
- ❌ Don't mix work and personal credentials
- ❌ Don't bypass security without reason

---

## Links

**Related documentation:**
- **[Secrets Guide](secrets.md)** - SOPS setup and secret management
- **[Backup & Recovery](backup-and-recovery.md)** - Backup strategy
- **[Troubleshooting](troubleshooting.md)** - Common issues
- **[System Health](system-health.md)** - Health validation

**External resources:**
- **[SOPS Documentation](https://github.com/Mic92/sops-nix)**
- **[Age Encryption](https://github.com/FiloSottile/age)**
- **[macOS Security](https://support.apple.com/guide/security/welcome/web)**

---

**Last Updated:** 2025-11-06
**Maintainer:** Jimmy
**Review Frequency:** Quarterly
