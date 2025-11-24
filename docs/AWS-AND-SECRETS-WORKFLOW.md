# AWS & Secrets Workflow - Complete Reference

**Complete guide to AWS configuration, secrets management, and hot reload for both work and personal profiles.**

---

## 📋 Table of Contents

1. [Quick Answers](#quick-answers)
2. [Work Profile AWS Workflow](#work-profile-aws-workflow)
3. [Personal Profile AWS Workflow](#personal-profile-aws-workflow)
4. [Hot Reload Mechanisms](#hot-reload-mechanisms)
5. [Configuration Matrix: Nix vs Local](#configuration-matrix-nix-vs-local)
6. [AWS Config Auto-Generation](#aws-config-auto-generation)
7. [Secrets Management](#secrets-management)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Quick Answers

### Q: Does `awslogin project-name env` work?
**A: YES!** But syntax is: `awslogin <project|alias> <env> [role]`

```bash
# Work profile examples:
awslogin ti dev              # Login to tririga-integrations dev (support role)
awslogin ps qa developer     # Login to paging-solution qa (developer role)
tidev && aws sso login       # Alternative: use alias then manual login

# Personal profile: Not applicable (uses IAM keys, not SSO)
```

### Q: How about on personal profile?
**A:** Personal profile uses **IAM credentials** (no SSO), stored in:
- `~/.aws/credentials` (encrypted via SOPS, auto-decrypted on rebuild)
- `~/.zsh_secrets` (API keys, tokens)

### Q: Is there AWS config auto-generation from accounts.json?
**A: YES!** For work profile:
- `~/.aws/accounts.json` → source of truth (project definitions)
- `home/_profiles/_template/programs/aws.nix` → reads accounts.json, generates all SSO profiles
- Runs on every `nix-rebuild` → updates `~/.aws/config`

### Q: Do we have hot reload for AWS/credentials?
**A: YES!** Multiple mechanisms:

| Type | Hot Reload Command | Speed | What Gets Reloaded |
|------|-------------------|-------|-------------------|
| **AWS profile** | `awsuse ti dev` | ⚡ Instant | Sets AWS_PROFILE env var immediately |
| **Secrets testing** | `reload-secrets` | ⚡ Instant | Re-sources ~/.zsh_secrets + local overrides |
| **Local secrets** | `secrets-local edit` + `reload-secrets` | ⚡ Instant | Test credentials without rebuild |
| **AWS config** | `nix-rebuild && exec zsh` | 🔄 30 sec | Regenerates ~/.aws/config from accounts.json |
| **Permanent secrets** | `edit-secrets` + `nix-rebuild` | 🔄 30 sec | Re-encrypts and deploys SOPS secrets |
| **Shell variables** | `exec zsh` | ⚡ 2 sec | Reloads ~/.zsh_secrets, AWS_PROFILE |

---

## 🏢 Work Profile AWS Workflow

### Architecture

```
.aws/accounts.json (repo)
      ↓
[nix-rebuild]
      ↓
aws.nix (reads JSON, generates profiles)
      ↓
~/.aws/config (SSO profiles auto-generated)
      ↓
awsuse/awslogin functions (shell helpers)
      ↓
AWS_PROFILE environment variable
```

### 1. Define Projects in `accounts.json`

**Location:** `.aws/accounts.json` (tracked in repo)

```json
{
  "tririga-integrations": {
    "alias": "ti",
    "description": "Tririga Integrations platform",
    "default_role": "support",
    "default_region": "us-east-1",
    "accounts": {
      "dev": {
        "id": "779846812095",
        "additional_roles": ["data-engineer"],
        "region": "us-east-1"
      },
      "sbx": "054037098480",
      "qa": "710271912324",
      "prod": "911167889615"
    }
  }
}
```

### 2. Auto-Generated Profiles

After `nix-rebuild`, these profiles appear in `~/.aws/config`:

```ini
[profile tririga-integrations-dev]
sso_session = sso-east-1
sso_account_id = 779846812095
sso_role_name = support
region = us-east-1

[profile tririga-integrations-dev-data-engineer]
sso_session = sso-east-1
sso_account_id = 779846812095
sso_role_name = data-engineer
region = us-east-1
```

### 3. Auto-Generated Aliases

From the JSON above, these shell aliases are created:

```bash
tidev           # awsuse ti dev (support role)
tidev-data-engineer  # awsuse ti dev data-engineer
tisbx           # awsuse ti sbx
tiqa            # awsuse ti qa
tiprod          # awsuse ti prod
```

### 4. Daily Usage

```bash
# Method 1: Direct alias
tidev                    # Switch to ti-dev (support)
tidev-data-engineer      # Switch to ti-dev (data-engineer role)

# Method 2: awsuse function
awsuse ti dev            # Switch to ti-dev (support)
awsuse ti dev data-engineer  # Switch to ti-dev (data-engineer)

# Method 3: awslogin (includes SSO login)
awslogin ti dev          # Login + switch to ti-dev
awslogin ti dev data-engineer  # Login + switch with role

# Discovery commands
awslist                  # List all accounts by project
awswho                   # Show current profile
awswhere 779846812095    # Find project/env by account ID
awscheck                 # Check SSO session status
awsfind developer        # Search for profiles by keyword
```

### 5. Adding New Accounts Workflow

```bash
# 1. Edit accounts.json
vim .aws/accounts.json   # Add new project/account

# 2. Rebuild to generate profiles
nix-rebuild && exec zsh

# 3. Verify generation
awslist                  # Should show new project

# 4. Login to new profile
awslogin new-project dev

# 5. Test access
aws sts get-caller-identity
```

### 6. Shell Functions Available

| Function | Purpose | Example |
|----------|---------|---------|
| `awsuse` | Switch profile (no login) | `awsuse ti dev` |
| `awslogin` | Login + switch profile | `awslogin ps qa` |
| `awswho` | Show current profile details | `awswho` |
| `awslist` | List all accounts | `awslist` |
| `awswhere` | Reverse lookup by account ID | `awswhere 123456789` |
| `awscheck` | Check SSO session status | `awscheck` |
| `awsfind` | Search profiles by keyword | `awsfind developer` |
| `awsfilter` | Filter by type | `awsfilter env prod` |

---

## 🏠 Personal Profile AWS Workflow

### Architecture

```
secrets.yaml (encrypted)
      ↓
[nix-rebuild with SOPS]
      ↓
~/.aws/credentials (auto-decrypted)
~/.zsh_secrets (auto-decrypted)
      ↓
[Shell loads on startup]
      ↓
AWS_PROFILE, API keys available
```

### 1. AWS Credentials Storage

**Encrypted in SOPS:** `nix-config/hosts/macbook-pro-m1/secrets.yaml`

```yaml
# secrets.yaml (encrypted with age)
aws_credentials: |
  [default]
  aws_access_key_id = AKIA...
  aws_secret_access_key = ...
  region = us-east-1

  [personal]
  aws_access_key_id = AKIA...
  aws_secret_access_key = ...
  region = us-east-1

zsh_secrets: |
  export OPENAI_API_KEY="sk-..."
  export ANTHROPIC_API_KEY="sk-ant-..."
  export GITHUB_TOKEN="github_pat_..."
```

### 2. Secret Deployment

Secrets are auto-decrypted on rebuild via `secrets-personal.nix`:

```nix
secrets = {
  aws_credentials = {
    path = "/Users/jimmy/.aws/credentials";
    owner = "jimmy";
    mode = "0600";
  };

  zsh_secrets = {
    path = "/Users/jimmy/.zsh_secrets";
    owner = "jimmy";
    mode = "0600";
  };
}
```

### 3. Daily Usage

```bash
# AWS credentials are automatically available
aws s3 ls                       # Uses [default] profile
AWS_PROFILE=personal aws s3 ls  # Uses [personal] profile

# API keys are auto-loaded from ~/.zsh_secrets
echo $OPENAI_API_KEY           # Available immediately

# No awslogin needed (IAM keys, not SSO)
```

### 4. Editing Secrets Workflow

```bash
# 1. Edit encrypted secrets
edit-secrets                    # Opens secrets.yaml in $EDITOR

# 2. Add/update credentials
# (Edit the file, save, exit)

# 3. Rebuild to decrypt and deploy
nix-rebuild && exec zsh

# 4. Verify deployment
cat ~/.aws/credentials          # Should show decrypted content
echo $OPENAI_API_KEY           # Should show value from ~/.zsh_secrets

# 5. Test AWS access
aws sts get-caller-identity
```

### 5. Configuration Files

| File | Purpose | Editable? | Generation |
|------|---------|-----------|------------|
| `~/.aws/config` | AWS profiles | ❌ No (managed by Nix) | Auto-generated on rebuild |
| `~/.aws/credentials` | IAM keys | ❌ No (SOPS secret) | Auto-decrypted on rebuild |
| `~/.zsh_secrets` | API keys, tokens | ❌ No (SOPS secret) | Auto-decrypted on rebuild |
| `secrets.yaml` | Encrypted source | ✅ Yes (via edit-secrets) | Manual edit |

---

## 🔄 Hot Reload Mechanisms

### AWS Profile Switching (Instant)

```bash
# No reload needed - env var changes immediately
awsuse ti dev           # AWS_PROFILE set instantly
aws sts get-caller-identity  # Uses new profile immediately
```

### AWS Config Changes (Requires Rebuild)

```bash
# Scenario: Added new account to accounts.json

# 1. Edit source
vim .aws/accounts.json

# 2. Rebuild (regenerates ~/.aws/config)
nix-rebuild

# 3. Reload shell (picks up new functions/aliases)
exec zsh

# 4. Verify
awslist                 # Should show new account
```

### Secrets Changes (Requires Rebuild)

```bash
# Scenario: Updated API key

# 1. Edit encrypted secrets
edit-secrets

# 2. Update the key
# (Edit in $EDITOR, save, exit)

# 3. Rebuild (re-decrypts and deploys)
nix-rebuild

# 4. Reload shell (sources ~/.zsh_secrets)
exec zsh

# 5. Verify
echo $OPENAI_API_KEY    # Should show new value
```

### Shell Environment Only (Fast Reload)

```bash
# If you manually edited ~/.zsh_secrets (NOT recommended, use secrets.yaml)
exec zsh                # Reloads all environment variables
```

### NEW: Secrets Hot Reload (Instant!) ⚡

**Quick reload without rebuilding** - Great for testing API keys!

```bash
# Reload secrets immediately
reload-secrets          # Re-sources ~/.zsh_secrets and ~/.zsh_secrets.local
                       # ⚡ Instant! (~0.5 seconds)

# Verify
echo $OPENAI_API_KEY   # Should show updated value
```

**Local Testing Helper:**

```bash
# Create temporary test credentials
secrets-local edit      # Opens ~/.zsh_secrets.local in $EDITOR
# Add: export TEST_API_KEY="sk-test-..."
# Save and exit

# Apply instantly
reload-secrets         # ⚡ Instant reload!

# Test your changes
echo $TEST_API_KEY

# Clean up when done
secrets-local rm       # Removes local overrides
```

**Use Cases:**
- ✅ Testing new API keys before committing to SOPS
- ✅ Temporary credential overrides
- ✅ Quick debugging without rebuild
- ✅ Local development with test credentials

**Files:**
- `~/.zsh_secrets` - SOPS-managed (permanent)
- `~/.zsh_secrets.local` - Local testing (temporary, gitignored)

**Commands:**
```bash
reload-secrets         # Reload both files
secrets-local edit     # Edit local overrides
secrets-local show     # View local secrets
secrets-local rm       # Remove local overrides
sec edit               # Shortcut for secrets-local edit
```

### Profile Auto-Restore

**On every new shell:**

```bash
# ~/.aws/.last_profile tracks your last AWS profile
# Shell auto-restores it on startup

$ zsh
🔄 Restored AWS Profile: tririga-integrations-dev
💡 Run 'awswho' for details or 'awsuse' to switch
```

---

## 🗂️ Configuration Matrix: Nix vs Local

### Work Profile

| Item | Nix (Declarative) | Local (Runtime) | Hot Reload |
|------|-------------------|-----------------|------------|
| **AWS profiles** | ✅ `accounts.json` → `aws.nix` | → `~/.aws/config` | `nix-rebuild && exec zsh` |
| **AWS credentials** | ❌ Never in Nix | ✅ `~/.aws/credentials` (SOPS) | `nix-rebuild && exec zsh` |
| **Shell functions** | ✅ `lib/aws-helpers.nix` | → Loaded in zsh | `exec zsh` |
| **Aliases** | ✅ Auto-generated from JSON | → Loaded in zsh | `exec zsh` |
| **SSO config** | ✅ `aws.nix` (sso_start_url) | → `~/.aws/config` | `nix-rebuild && exec zsh` |
| **Corporate proxy** | ✅ `user-config.nix` | → Env vars | `nix-rebuild && exec zsh` |
| **API keys** | ❌ Never in Nix | ✅ `~/.zsh_secrets` (SOPS) | `edit-secrets` + rebuild |

### Personal Profile

| Item | Nix (Declarative) | Local (Runtime) | Hot Reload |
|------|-------------------|-----------------|------------|
| **AWS profiles** | ✅ `aws.nix` (static template) | → `~/.aws/config` | `nix-rebuild && exec zsh` |
| **AWS credentials** | ❌ Never in Nix | ✅ `~/.aws/credentials` (SOPS) | `nix-rebuild && exec zsh` |
| **API keys** | ❌ Never in Nix | ✅ `~/.zsh_secrets` (SOPS) | `edit-secrets` + rebuild |
| **SSH keys** | ❌ Never in Nix | ✅ `~/.ssh/id_ed25519` (SOPS) | `nix-rebuild` |
| **Shell functions** | ✅ `zsh.nix` | → Loaded in zsh | `exec zsh` |

---

## 🤖 AWS Config Auto-Generation

### How It Works

```
1. You edit:    .aws/accounts.json
                  ↓
2. Nix reads:   builtins.fromJSON (builtins.readFile accountsPath)
                  ↓
3. Nix loops:   For each project → for each env → for each role
                  ↓
4. Nix creates: [profile project-env-role]
                sso_account_id = ...
                sso_role_name = ...
                  ↓
5. Deploys to:  ~/.aws/config (writable file, not symlink)
                  ↓
6. Creates:     Shell functions (awsuse, awslogin, etc.)
                Aliases (tidev, psqa, etc.)
```

### Parser Logic

**Location:** `nix-config/home/_profiles/_template/programs/aws.nix`

```nix
# Simplified version
generateSsoProfiles = let
  accounts = builtins.fromJSON (builtins.readFile accountsPath);

  mkProfile = project: env: accountData: role:
    let
      accountId = if builtins.isString accountData
                  then accountData
                  else accountData.id;
      profileName = "${project}-${env}" +
        (if role != "support" then "-${role}" else "");
    in ''
      [profile ${profileName}]
      sso_account_id = ${accountId}
      sso_role_name = ${role}
      ...
    '';
in
  # Generate all profiles by looping through JSON
  ...
```

### Testing Generation

```bash
# 1. Check current config
cat ~/.aws/config

# 2. Edit accounts.json
vim .aws/accounts.json

# 3. Rebuild (regenerates config)
nix-rebuild

# 4. Compare
cat ~/.aws/config       # Should show new profiles

# 5. Test new functions
awslist                 # Should list new project
```

---

## 🔐 Secrets Management

### Encryption System: SOPS + age

```
Plain text secrets
      ↓
[age encryption]
      ↓
secrets.yaml (encrypted, safe to commit)
      ↓
[nix-rebuild with SOPS]
      ↓
Decrypted files deployed to home directory
```

### Secrets Workflow

#### 1. Initial Setup (One-time)

```bash
# Age key should already exist at:
~/.config/sops/age/keys.txt

# Verify it's configured in secrets-personal.nix:
grep keyFile nix-config/hosts/macbook-pro-m1/secrets-personal.nix
```

#### 2. Editing Secrets

```bash
# Use the edit-secrets command (handles encryption/decryption)
edit-secrets

# This opens secrets.yaml in your $EDITOR
# Edit the secrets, save, exit
# SOPS automatically re-encrypts on save
```

#### 3. Secret Deployment

```bash
# After editing, rebuild to deploy
nix-rebuild && exec zsh

# SOPS decrypts during rebuild
# Secrets are placed at paths defined in secrets-personal.nix
```

### Secrets Locations

#### Work Profile

```nix
# nix-config/hosts/macbook-pro-m3/secrets-work.nix
secrets = {
  zsh_secrets = {
    path = "/Users/jimmy/.zsh_secrets";
  };
  aws_credentials = {
    path = "/Users/jimmy/.aws/credentials";
  };
}
```

#### Personal Profile

```nix
# nix-config/hosts/macbook-pro-m1/secrets-personal.nix
secrets = {
  zsh_secrets = {
    path = "/Users/jimmy/.zsh_secrets";
  };
  aws_credentials = {
    path = "/Users/jimmy/.aws/credentials";
  };
  ssh_private_key = {
    path = "/Users/jimmy/.ssh/id_ed25519";
  };
  ssh_public_key = {
    path = "/Users/jimmy/.ssh/id_ed25519.pub";
  };
}
```

### What Goes in Each Secret File?

#### `zsh_secrets`

```bash
# API Keys and Tokens
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="github_pat_..."
export HUGGINGFACE_TOKEN="hf_..."

# MCP Keys
export TAVILY_API_KEY="tvly-..."
export MORPH_API_KEY="sk-..."
export MEM0_API_KEY="m0-..."
export LINEAR_API_KEY="lin_api_..."

# Database credentials (if needed)
export DB_PASSWORD="..."
export REDIS_PASSWORD="..."
```

#### `aws_credentials`

```ini
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
region = us-east-1

[personal]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
region = us-east-1

[personal-dev]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
```

---

## 🐛 Troubleshooting

### AWS Profile Not Working

```bash
# Check current profile
awswho

# Check if profile exists in config
grep "profile ti-dev" ~/.aws/config

# Check SSO session status
awscheck

# Re-login if expired
awslogin ti dev

# Test access
aws sts get-caller-identity
```

### Secrets Not Loading

```bash
# Check if secret file exists and is readable
ls -la ~/.zsh_secrets
ls -la ~/.aws/credentials

# Verify permissions (should be 600)
stat -f "%A %N" ~/.zsh_secrets

# Check if secrets are sourced
grep "zsh_secrets" ~/.zshrc

# Manually source (testing only)
source ~/.zsh_secrets

# Rebuild to redeploy
edit-secrets            # Verify content
nix-rebuild && exec zsh
```

### AWS Config Not Regenerating

```bash
# Check if accounts.json exists
cat .aws/accounts.json

# Verify JSON syntax
jq . .aws/accounts.json

# Check Nix can read it
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./.aws/accounts.json)'

# Force regeneration
rm ~/.aws/config
nix-rebuild && exec zsh

# Verify generation
cat ~/.aws/config
```

### Shell Functions Not Available

```bash
# Check if zsh config includes AWS helpers
grep "aws.*helper" ~/.zshrc

# Reload shell
exec zsh

# Check if functions are defined
which awsuse
which awslogin

# If missing, rebuild
nix-rebuild && exec zsh
```

### Alias Not Working

```bash
# List all AWS aliases
alias | grep "aws"

# Check if alias is generated from accounts.json
jq -r '.[] | .alias' .aws/accounts.json

# Rebuild to regenerate aliases
nix-rebuild && exec zsh

# Verify alias
alias tidev
```

---

## 📚 Related Documentation

- **[AWS Quick Reference](work/aws/AWS-QUICK-REF.md)** - Daily commands and examples
- **[AWS Multi-Role Guide](work/aws/AWS-MULTI-ROLE.md)** - Role-based access patterns
- **[AWS Implementation Summary](work/aws/AWS-IMPLEMENTATION-SUMMARY.md)** - Technical details
- **[Secrets Management Guide](secrets.md)** - SOPS encryption guide
- **[CLAUDE.md](../CLAUDE.md)** - Main configuration guide

---

## 🔑 Key Takeaways

### Work Profile
✅ AWS profiles auto-generated from `accounts.json`
✅ Shell functions provide easy switching (`awsuse`, `awslogin`)
✅ Aliases created automatically (`tidev`, `psqa`)
✅ Hot reload: `nix-rebuild && exec zsh`

### Personal Profile
✅ IAM credentials encrypted in SOPS (`secrets.yaml`)
✅ Auto-decrypted on rebuild to `~/.aws/credentials`
✅ API keys in `~/.zsh_secrets` (also SOPS-encrypted)
✅ Hot reload: `edit-secrets` + `nix-rebuild && exec zsh`

### General
✅ Credentials NEVER in Nix config (always SOPS-encrypted)
✅ Config IS in Nix (profiles, SSO settings)
✅ `exec zsh` reloads environment variables
✅ `nix-rebuild` regenerates all declarative config

---

**Last Updated:** November 2025
**Version:** 2.0.0
