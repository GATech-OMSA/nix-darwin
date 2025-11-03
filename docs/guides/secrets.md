# Secrets Management Guide

**Complete guide to managing sensitive data with sops-nix and age encryption**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Adding Secrets](#adding-secrets)
4. [Updating Secrets](#updating-secrets)
5. [Rotating Keys](#rotating-keys)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This system uses **sops-nix** with **age encryption** for secrets management.

### What Gets Encrypted

**Managed by sops-nix:**
- API keys (OpenAI, Anthropic, GitHub)
- SSH private keys
- AWS credentials
- Docker registry auth
- GPG keys
- Environment variables (.zsh_secrets)

**Stored separately:**
- Application configs (Claude, Continue.dev) - see `user-data/`
- User-generated content (VS Code snippets)

### How It Works

```
1. Generate age key → 2. Configure sops → 3. Encrypt secrets →
4. Commit to git → 5. nix-rebuild decrypts → 6. Apps use secrets
```

---

## Quick Start

### Initial Setup

```bash
# 1. Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. View public key
grep "public key:" ~/.config/sops/age/keys.txt
# Output: Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7...

# 3. Update .sops.yaml with your public key
code ~/nix-darwin/secrets/.sops.yaml
# Replace YOUR_PUBLIC_AGE_KEY_HERE

# 4. Create secrets file
cd ~/nix-darwin
sops hosts/mbp-jimmy/secrets.yaml

# 5. Add secrets (example):
```

```yaml
zsh_secrets: |
  export OPENAI_API_KEY="sk-..."
  export GITHUB_TOKEN="ghp_..."

ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

```bash
# 6. Save (auto-encrypts)

# 7. Verify encryption
cat hosts/mbp-jimmy/secrets.yaml
# Should see: ENC[AES256_GCM,data:...]

# 8. Commit safely
g aa && g cm "Add encrypted secrets" && g ps

# 9. Rebuild (auto-decrypts)
nix-rebuild

# 10. Check secrets installed
secrets-status
```

### Backup Age Key

**CRITICAL:** Backup immediately!

```bash
# Copy to password manager
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into 1Password/Bitwarden

# Or copy to encrypted USB
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/
```

---

## Adding Secrets

### Add API Key

```bash
# 1. Edit secrets
edit-secrets

# 2. Add to zsh_secrets section:
```

```yaml
zsh_secrets: |
  # Existing keys...
  export OPENAI_API_KEY="sk-..."

  # New key
  export REPLICATE_API_KEY="r8_..."
```

```bash
# 3. Save (auto-encrypts)

# 4. Rebuild
nix-rebuild

# 5. Verify
echo $REPLICATE_API_KEY

# 6. Commit
g aa && g cm "Add Replicate API key" && g ps
```

### Add New Secret Type

**Example: GPG private key**

**1. Update host config** (`hosts/mbp-jimmy/default.nix`):

```nix
sops.secrets = {
  # ... existing ...

  gpg_private_key = {
    path = "/Users/${username}/.gnupg/private-key.asc";
    owner = username;
    mode = "0600";
  };
};
```

**2. Add to secrets file:**

```bash
edit-secrets
```

```yaml
gpg_private_key: |
  -----BEGIN PGP PRIVATE KEY BLOCK-----
  ...
  -----END PGP PRIVATE KEY BLOCK-----
```

**3. Rebuild:**

```bash
nix-rebuild
ls -la ~/.gnupg/private-key.asc
```

---

## Updating Secrets

### Edit Existing Secrets

```bash
# 1. Edit secrets file
edit-secrets

# 2. Make changes

# 3. Save (auto-encrypts)

# 4. Rebuild immediately
nix-rebuild

# 5. Test new values
echo $MY_API_KEY

# 6. Commit
g aa && g cm "Update API keys" && g ps
```

### Rotating Credentials

**When keys leak:**

```bash
# 1. Generate new credentials from provider

# 2. Update secrets
edit-secrets
# Replace old keys with new

# 3. Rebuild immediately
nix-rebuild

# 4. Test new credentials
aws sts get-caller-identity

# 5. Commit
g aa && g cm "Rotate AWS credentials" && g ps

# 6. Revoke old credentials in provider
```

---

## Rotating Keys

### Generate New Age Key

**If key compromised or lost:**

```bash
# 1. Generate new key
age-keygen -o ~/.config/sops/age/keys-new.txt

# 2. Get new public key
grep "public key:" ~/.config/sops/age/keys-new.txt

# 3. Update .sops.yaml
code ~/nix-darwin/secrets/.sops.yaml
# Add new public key

# 4. Re-encrypt all secrets
sops updatekeys hosts/mbp-jimmy/secrets.yaml
sops updatekeys hosts/mbp-work/secrets.yaml

# 5. Replace old key
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt

# 6. Test
sops -d hosts/mbp-jimmy/secrets.yaml

# 7. Commit
g aa && g cm "Rotate age keys" && g ps

# 8. Backup new key
cat ~/.config/sops/age/keys.txt | pbcopy
```

---

## Common Patterns

### Per-Machine Secrets

**Personal Mac secrets:**
```bash
sops hosts/mbp-jimmy/secrets.yaml
```

**Work Mac secrets:**
```bash
sops hosts/mbp-work/secrets.yaml
```

### Shared Secrets

**Create shared secrets file:**

```yaml
# secrets/.sops.yaml
creation_rules:
  - path_regex: secrets/shared\.yaml$
    key_groups:
      - age:
          - *jimmy_personal
          - *jimmy_work  # Both can decrypt
```

### Secret References

**In Nix config:**
```nix
sops.secrets.my_secret = {
  path = "/Users/${username}/.my_secret";
  owner = username;
  mode = "0600";
};
```

**Access in shell:**
```bash
cat ~/.my_secret
```

---

## Checking Status

### Secrets Status Command

```bash
secrets-status
```

**Shows:**
- Age key status
- Secrets file encryption
- Active secrets in home
- Available commands

### Manual Checks

```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Check secrets encrypted
head hosts/mbp-jimmy/secrets.yaml
# Should see: ENC[...]

# Check secrets decrypted
ls -la ~/.zsh_secrets ~/.ssh/id_ed25519

# Test decryption manually
sops -d hosts/mbp-jimmy/secrets.yaml
```

---

## Troubleshooting

### "Failed to decrypt"

**Check age key:**
```bash
ls -la ~/.config/sops/age/keys.txt
grep "public key:" ~/.config/sops/age/keys.txt
```

**Check .sops.yaml:**
```bash
cat secrets/.sops.yaml | grep age1
# Should match your public key
```

**Test manually:**
```bash
sops -d hosts/mbp-jimmy/secrets.yaml
```

### "Secrets not appearing"

**Check sops-nix config:**
```bash
cat hosts/mbp-jimmy/default.nix | grep -A 20 "sops ="
```

**Rebuild with verbose:**
```bash
darwin-rebuild switch --flake ~/nix-darwin --show-trace
```

### "Can't edit secrets"

**Install sops:**
```bash
nix-env -iA nixpkgs.sops
```

**Or add to packages.nix:**
```nix
environment.systemPackages = [ pkgs.sops ];
```

### "Permission denied on secrets"

**Check ownership in config:**
```nix
sops.secrets.zsh_secrets = {
  owner = username;  # Must match your username
  mode = "0600";
};
```

---

## Security Best Practices

### Do's ✅

- ✅ Always use sops to edit secrets
- ✅ Backup age key securely (password manager + USB)
- ✅ Use separate keys per machine
- ✅ Rotate credentials regularly
- ✅ Verify encryption before committing
- ✅ Use machine-specific secrets when needed

### Don'ts ❌

- ❌ Never commit unencrypted secrets
- ❌ Never share age private key
- ❌ Don't edit ~/.zsh_secrets directly (managed by sops)
- ❌ Don't skip backups

### Verification

**Before committing:**
```bash
# Check all secrets are encrypted
cat hosts/*/secrets.yaml | grep -v "ENC\["
# Should have no output (except comments)

# Review all changes
g diff
```

---

## Helper Commands

```bash
edit-secrets         # Edit encrypted secrets
secrets-status       # Check secrets configuration
backup-age-key       # Backup age key to clipboard
```

---

## Links

- **[secrets/SETUP.md](../../secrets/SETUP.md)** - Quick setup guide
- **[user-data/README.md](../../user-data/README.md)** - Non-secret backups
- **[Backup & Recovery](backup-and-recovery.md)** - Complete backup strategy
- **[sops-nix Documentation](https://github.com/Mic92/sops-nix)**
- **[age Encryption](https://github.com/FiloSottile/age)**

---
