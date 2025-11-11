# Secrets Management Guide

**Complete guide to managing sensitive data with SOPS and age encryption - v2.0.0**

**Last Updated**: 2025-11-10 (v2.0.0 - Profile architecture)

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Profile-Specific Secrets](#profile-specific-secrets)
4. [Adding Secrets](#adding-secrets)
5. [Updating Secrets](#updating-secrets)
6. [Rotating Keys](#rotating-keys)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This system uses **SOPS** (Secrets OPerationS) with **age encryption** for secrets management.

### v2.0.0 Changes

**New in v2.0.0:**
- Profile-based secret templates (personal vs work secrets)
- `./scripts/configure.sh` generates secret templates automatically
- Secret scanning detects existing credentials (~/.aws/, ~/.db/, .env files)
- Profile-specific secret organization

**Secret workflow:**
```
configure.sh (scan & template) → edit secrets → activate.sh (encrypt & deploy)
```

---

### What Gets Encrypted

**Managed by SOPS:**
- API keys (OpenAI, Anthropic, GitHub)
- SSH private keys
- AWS credentials
- Environment variables (.zsh_secrets)
- Database connection credentials (work profile)
- Docker registry auth

**Stored separately (workspace/):**
- Application configs (Claude, Cursor) - PII (email, UUIDs)
- User-generated content (todos, session data)
- Age key backups

---

### How It Works

```
1. Run configure.sh → Scan secrets → Generate templates
2. Edit secret templates → Replace <PLACEHOLDER> values
3. Run activate.sh → Encrypt with age → Deploy to home
4. Commit encrypted files → Git stores safely
5. Next rebuild → SOPS decrypts → Apps use secrets
```

---

### Format: Binary Encryption

**This system uses SOPS binary format** (not YAML format) for encrypted secrets.

**Binary format advantages:**
```bash
$ cat hosts/$(hostname)/secrets.yaml
# Binary data (appears as gibberish in terminal)
```

- ✅ **Obviously encrypted** (won't mistake for plaintext)
- ✅ **Git diffs** clearly show "binary file changed"
- ✅ **Impossible to leak** structure or key names
- ✅ **Git hooks validate** binary format automatically

**Verify encryption:**
```bash
# Check file is binary (encrypted)
file hosts/$(hostname)/secrets.yaml
# Output: hosts/$(hostname)/secrets.yaml: data

# View decrypted content
sops --decrypt hosts/$(hostname)/secrets.yaml
```

**Editing workflow:**
```bash
# SOPS handles encryption/decryption automatically
edit-secrets  # Opens in editor as YAML
# Make changes, save → auto-converts to binary format
```

---

## Quick Start

### Initial Setup (v2.0.0 Three-Script Workflow)

**Step 1: Bootstrap (Install dependencies)**
```bash
cd ~/nix-darwin
./scripts/bootstrap.sh
# Installs: Nix, nix-darwin, SOPS, age
```

**Step 2: Configure (Generate age keys & secret templates)**
```bash
./scripts/configure.sh
```

**Configuration wizard will:**
1. Generate age encryption keys (~/.config/sops/age/keys.txt)
2. Scan for existing secrets:
   - AWS credentials (~/.aws/credentials)
   - Database connections (~/.db/*)
   - Environment files (~/.env*)
3. Generate profile-specific secret templates:
   - Personal: hosts/$(hostname)/secrets-personal.nix
   - Work: hosts/$(hostname)/secrets-work.nix
4. Create config files (config/user-config.nix, config/machine-config.nix)

**Step 3: Edit Secret Templates**
```bash
# Edit your profile's secret template
code hosts/$(hostname)/secrets-personal.nix  # Personal profile
# or
code hosts/$(hostname)/secrets-work.nix      # Work profile

# Replace ALL <PLACEHOLDER> values with real secrets:
# api_keys = {
#   openai = "<PLACEHOLDER>";  # ← Replace with real API key
# };
```

**Step 4: Activate (Encrypt & Deploy)**
```bash
./scripts/activate.sh
```

**Activation script will:**
1. Detect placeholders and warn if any remain
2. Convert secret template (Nix) → secrets.yaml (YAML)
3. Encrypt secrets.yaml with age → binary format
4. Build nix-darwin configuration
5. Deploy encrypted secrets to home directory

**Step 5: Verify**
```bash
# Check secrets status
secrets-status

# Should show:
# ✅ Age key exists: ~/.config/sops/age/keys.txt
# ✅ Secrets encrypted: hosts/$(hostname)/secrets.yaml (binary format)
# ✅ Secrets deployed: ~/.zsh_secrets, ~/.ssh/id_ed25519
```

---

### Backup Age Key (CRITICAL)

**Your age private key is the ONLY way to decrypt secrets!**

**Backup immediately after `./scripts/configure.sh`:**

```bash
# Method 1: Password Manager (Recommended)
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into 1Password/Bitwarden
# Title: "nix-darwin age key - $(hostname)"

# Method 2: Encrypted USB Drive
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/age-keys/$(hostname)-key.txt
chmod 600 /Volumes/SecureBackup/age-keys/$(hostname)-key.txt

# Method 3: Print on Paper (Air-gapped backup)
cat ~/.config/sops/age/keys.txt
# Print and store in physical safe
```

**Without this key:**
- ❌ Cannot decrypt secrets.yaml
- ❌ Cannot access API keys
- ❌ Cannot access AWS credentials
- ❌ System cannot be fully restored

See [Backup & Recovery Guide](backup-and-recovery.md) for complete backup procedures.

---

## Secret Scanning

### Automatic Discovery (configure.sh)

During initial setup, `configure.sh` automatically scans your system for existing secrets to help populate your `secrets.yaml`.

**Scan depth:** 4 directory levels (configurable via `SECRET_SCAN_DEPTH` environment variable)

### What Gets Scanned

#### Known Secret Directories
- `~/.db/` - Database credentials (PostgreSQL, MySQL connection files)
- `~/.tokens/` - API tokens (GitHub, OpenAI, Anthropic)
- `~/.credentials/` - Generic credential storage
- `~/.aws/` - AWS credentials and config files
- `~/.ssh/` - SSH private keys (id_*, excludes .pub files)
- `~/.gnupg/` - GPG private keys (secring.gpg, private-keys-v1.d/)
- `~/.vpn/` - VPN credentials and certificates

#### CLI Configuration Files
- `~/.kube/config` - Kubernetes cluster credentials
- `~/.npmrc` - npm registry authentication tokens
- `~/.pypirc` - PyPI upload credentials
- `~/.docker/config.json` - Docker registry authentication
- `~/.netrc` - Network credentials for various tools
- `~/.pgpass` - PostgreSQL password file
- `~/.my.cnf` - MySQL credentials
- `~/.gem/credentials` - Ruby gem API keys
- `~/.wakatime.cfg` - WakaTime API key

#### Environment Files (Deep Scan)
- `.env` - Environment variables with secrets
- `.env.*` - All variations (.env.test, .env.local, .env.production, etc.)
- `.envrc` - direnv environment files

**Exclusions:** Skips node_modules/, .git/, dist/, build/ directories

#### Wildcard Pattern Matching
- `*secret*` - Files with "secret" in name
- `*credential*` - Files with "credential" in name
- `*.pem` - PEM certificate files
- `*.p12` - PKCS#12 certificate files
- `*.pfx` - Personal Information Exchange files
- `*.key` - Private key files

**Limit:** First 20 matches per pattern (prevents spam)

#### Generated Alias Files
Scans `~/.config/` for alias files that may contain secrets from previous Nix configurations:
- `*alias*` - Alias definition files
- `*aliases*` - Alias configuration files

**What it looks for:**
- Hardcoded credentials in aliases (e.g., `alias mysql-prod="mysql -u admin -pPASSWORD"`)
- API tokens in curl commands
- Database connection strings with embedded credentials

#### Shell History Files
- `~/.zsh_history` - Zsh command history
- `~/.bash_history` - Bash command history
- `~/.history` - Generic shell history

**Detection patterns:**
- `export SECRET=...`
- `API_KEY=...`
- `TOKEN=...`
- `PASSWORD=...`
- Commands with `-p` flag followed by passwords

#### SOPS Age Keys
- `$SOPS_AGE_KEY_FILE` - Environment variable location
- `~/.config/sops/age/keys.txt` - Default location

### Configuring Scan Depth

**Default:** 4 directory levels deep

**Custom depth:**
```bash
# Scan 3 levels deep instead of 4
export SECRET_SCAN_DEPTH=3
./scripts/configure.sh
```

**Why configurable?**
- **Deeper scans** (5-6 levels) find more secrets but take longer
- **Shallow scans** (2-3 levels) are faster but may miss nested secrets
- **4 levels** is optimal for most users (balances thoroughness and speed)

### Rescan Workflow

**When to rescan:**
- Monthly maintenance check
- After major system changes
- After installing new applications
- After cloning new projects with .env files

**Run rescan:**
```bash
# Interactive rescan with preview
./scripts/rescan-secrets.sh

# Custom scan depth
./scripts/rescan-secrets.sh --depth 3

# Auto-confirm changes
./scripts/rescan-secrets.sh --yes

# Dry run (preview only)
./scripts/rescan-secrets.sh --dry-run
```

**Deduplication logic:**
The rescan script uses smart deduplication to prevent duplicate entries:
- ✅ Checks **both** secret name AND path
- ✅ Skips if secret name already exists
- ✅ Skips if secret path already exists
- ✅ Only appends genuinely new discoveries

**Example:**
```yaml
# Existing secrets.yaml:
db_prod: ~/.db/prod

# Rescan finds:
~/.db/prod        # SKIPPED (path exists)
~/.db/staging     # ADDED (new path, new name)
```

### Scan Output Example

```
◆ Scanning for Existing Secrets

Detecting secrets in your home directory...
Scan depth: 4 directory levels

Found 12 existing secret(s):

✓ AWS credentials: ~/.aws/credentials
✓ Database credential: ~/.db/prod
✓ Database credential: ~/.db/staging
✓ API token: ~/.tokens/github
✓ API token: ~/.tokens/openai
✓ SSH key: ~/.ssh/id_ed25519
✓ SSH key: ~/.ssh/id_rsa
✓ Environment file: ~/projects/app/.env.local
✓ Environment file: ~/projects/api/.env
✓ Certificate: ~/.vpn/client.pem
✓ SOPS age key: ~/.config/sops/age/keys.txt
✓ Alias file with potential secrets: ~/.config/zsh/aliases.zsh

These secrets should be encrypted in nix-config/hosts/macbook-pro-m1/secrets.yaml
See docs/secrets.md for SOPS setup instructions

To change scan depth: export SECRET_SCAN_DEPTH=3  # Default: 4
```

### Security Considerations

**What gets scanned:**
- ✅ File paths and names (to identify secrets)
- ✅ File content patterns (to detect embedded credentials)

**What doesn't get logged:**
- ❌ Actual secret values
- ❌ File contents (except pattern matching)

**Scan safety:**
- All scanning is read-only
- No secrets are copied or transmitted
- Results shown locally only
- No network requests during scan

---

## Profile-Specific Secrets

### Personal Profile

**Secret template:** `hosts/$(hostname)/secrets-personal.nix`

**What's included:**
- Personal API keys (OpenAI, Anthropic, GitHub)
- Personal SSH keys
- Personal Git credentials
- Personal environment variables

**Example template:**
```nix
{
  # API keys for personal projects
  api_keys = {
    openai = "<PLACEHOLDER>";
    anthropic = "<PLACEHOLDER>";
    github = "<PLACEHOLDER>";
  };

  # Personal SSH key
  ssh_private_key = ''
    <PLACEHOLDER>
  '';

  # Environment variables
  env_vars = {
    PERSONAL_VAR = "<PLACEHOLDER>";
  };
}
```

**Edit:**
```bash
code hosts/$(hostname)/secrets-personal.nix
# Replace <PLACEHOLDER> with real values
./scripts/activate.sh
```

---

### Work Profile

**Secret template:** `hosts/$(hostname)/secrets-work.nix`

**What's included:**
- Work AWS credentials (SSO)
- Database connection credentials (prod, dev, staging databases)
- Work-specific API keys
- Work SSH keys
- Work environment variables

**Example template:**
```nix
{
  # AWS credentials (scanned from ~/.aws/credentials)
  aws_credentials = ''
    [work-domain]
    aws_access_key_id = <PLACEHOLDER>
    aws_secret_access_key = <PLACEHOLDER>
    aws_session_token = <PLACEHOLDER>
  '';

  # Database connections (scanned from ~/.db/)
  databases = {
    prod_oracle = {
      host = "<PLACEHOLDER>";
      port = "<PLACEHOLDER>";
      username = "<PLACEHOLDER>";
      password = "<PLACEHOLDER>";
    };
    dev_postgres = {
      host = "<PLACEHOLDER>";
      port = "<PLACEHOLDER>";
      username = "<PLACEHOLDER>";
      password = "<PLACEHOLDER>";
    };
  };

  # Work-specific API keys
  api_keys = {
    work_service = "<PLACEHOLDER>";
  };
}
```

**Edit:**
```bash
code hosts/$(hostname)/secrets-work.nix
# Replace <PLACEHOLDER> with real values
./scripts/activate.sh
```

---

### Minimal Profile

**Minimal profile has no secrets by default** (troubleshooting only).

If needed, create minimal secret template manually:
```bash
cp hosts/$(hostname)/secrets-personal.nix hosts/$(hostname)/secrets-minimal.nix
# Edit to include only essential secrets
```

---

## Adding Secrets

### Add API Key to Existing Profile

**Step 1: Edit secret template**
```bash
code hosts/$(hostname)/secrets-personal.nix
```

**Step 2: Add new API key**
```nix
{
  api_keys = {
    openai = "sk-...";
    anthropic = "sk-ant-...";

    # Add new key
    replicate = "r8_...";
  };
}
```

**Step 3: Activate**
```bash
./scripts/activate.sh
```

**Step 4: Verify**
```bash
# Check environment variable created
echo $REPLICATE_API_KEY

# Or check secrets status
secrets-status
```

**Step 5: Commit**
```bash
g aa && g cm "Add Replicate API key" && g ps
```

---

### Add New Database Connection (Work Profile)

**Step 1: Edit work secret template**
```bash
code hosts/$(hostname)/secrets-work.nix
```

**Step 2: Add database**
```nix
{
  databases = {
    # Existing databases...

    # Add new database
    staging_mysql = {
      host = "staging-db.company.com";
      port = "3306";
      username = "admin";
      password = "secure-password";
    };
  };
}
```

**Step 3: Update database configuration**
```bash
code home/_profiles/work/databases.nix
```

```nix
databases = [
  # Existing databases...

  # Add new database instance
  (myLib.mkDatabaseInstance "staging-mysql" {
    name = "Staging MySQL";
    description = "Staging environment database";
    type = "mysql";
    connectionString = "mysql://${username}:${password}@${host}:${port}/dbname";
  })
];
```

**Step 4: Activate**
```bash
./scripts/activate.sh
exec zsh
```

**Step 5: Test connection**
```bash
dbconnect-staging-mysql
```

---

### Add SSH Key

**Step 1: Edit secret template**
```bash
code hosts/$(hostname)/secrets-personal.nix
```

**Step 2: Add SSH key**
```nix
{
  ssh_private_key = ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
    ...
    -----END OPENSSH PRIVATE KEY-----
  '';
}
```

**Step 3: Activate**
```bash
./scripts/activate.sh
```

**Step 4: Verify**
```bash
ls -la ~/.ssh/id_ed25519
# Should show: -rw------- (600 permissions)

# Test SSH key
ssh-add -l
```

---

## Updating Secrets

### Edit Existing Secrets

**Workflow:**
```bash
# 1. Edit secret template
code hosts/$(hostname)/secrets-personal.nix

# 2. Make changes (update API keys, credentials, etc.)

# 3. Activate immediately
./scripts/activate.sh

# 4. Test new values
echo $OPENAI_API_KEY

# 5. Commit
g aa && g cm "Update API keys" && g ps
```

---

### Rotating Credentials

**When keys leak or need rotation:**

```bash
# 1. Generate new credentials from provider
# (e.g., GitHub → Settings → Developer settings → New token)

# 2. Update secret template
code hosts/$(hostname)/secrets-personal.nix
# Replace old keys with new

# 3. Activate immediately
./scripts/activate.sh

# 4. Test new credentials work
gh auth status  # Test GitHub token

# 5. Commit
g aa && g cm "Rotate GitHub token" && g ps

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
# Output: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7...

# 3. Update .sops.yaml
code .sops.yaml
# Replace old public key with new

# 4. Re-encrypt all secrets
sops updatekeys hosts/$(hostname)/secrets.yaml

# 5. Replace old key
mv ~/.config/sops/age/keys.txt ~/.config/sops/age/keys-old.txt
mv ~/.config/sops/age/keys-new.txt ~/.config/sops/age/keys.txt

# 6. Test decryption works
sops --decrypt hosts/$(hostname)/secrets.yaml

# 7. Commit
g aa && g cm "Rotate age keys" && g ps

# 8. Backup new key (CRITICAL)
cat ~/.config/sops/age/keys.txt | pbcopy
# Paste into password manager
```

---

## Common Patterns

### Per-Machine Secrets

**Personal machine secrets:**
```bash
hosts/mbp-personal-001/secrets-personal.nix
hosts/mbp-personal-001/secrets.yaml (encrypted)
```

**Work machine secrets:**
```bash
hosts/mbp-work-001/secrets-work.nix
hosts/mbp-work-001/secrets.yaml (encrypted)
```

**Each machine has:**
- Unique age key (~/.config/sops/age/keys.txt)
- Unique secret template (secrets-personal.nix or secrets-work.nix)
- Unique encrypted secrets file (secrets.yaml)

---

### Environment Variables

**Secret template:**
```nix
{
  env_vars = {
    OPENAI_API_KEY = "sk-...";
    GITHUB_TOKEN = "ghp_...";
    CUSTOM_VAR = "value";
  };
}
```

**Deployed to:**
```bash
~/.zsh_secrets
```

**Loaded automatically in shell:**
```bash
# Check loaded
echo $OPENAI_API_KEY

# Check file
cat ~/.zsh_secrets
```

---

### AWS Credentials (Work Profile)

**Secret template:**
```nix
{
  aws_credentials = ''
    [work-domain]
    aws_access_key_id = AKIA...
    aws_secret_access_key = abc123...
    aws_session_token = IQoJ...
  '';
}
```

**Deployed to:**
```bash
~/.aws/credentials
```

**Usage:**
```bash
# Check profile
aws --profile work-domain sts get-caller-identity

# Use with AWS SSO
aws sso login --profile work-domain
awslogin  # Alias for SSO login
```

---

## Checking Status

### Secrets Status Command

```bash
secrets-status
```

**Shows:**
- Age key status (~/.config/sops/age/keys.txt)
- Secrets file encryption status (binary format check)
- Active profile (personal/work/minimal)
- Deployed secrets in home directory
- Available secret management commands

**Example output:**
```
🔐 Secrets Status

Age Key: ✅ ~/.config/sops/age/keys.txt
Profile: work
Secrets: ✅ hosts/mbp-work-001/secrets.yaml (encrypted, binary format)

Deployed Secrets:
  ✅ ~/.zsh_secrets (600)
  ✅ ~/.ssh/id_ed25519 (600)
  ✅ ~/.aws/credentials (600)
  ✅ ~/.db/prod (600)

Commands:
  edit-secrets    - Edit encrypted secrets
  secrets-check   - Validate encryption
```

---

### Manual Checks

```bash
# 1. Check age key exists
ls -la ~/.config/sops/age/keys.txt
# Should show: -rw------- (600 permissions)

# 2. Check secrets encrypted (binary format)
file hosts/$(hostname)/secrets.yaml
# Should show: data (binary)
# NOT: ASCII text (unencrypted)

# 3. Check secrets decrypted in home
ls -la ~/.zsh_secrets ~/.ssh/id_ed25519 ~/.aws/credentials
# All should show: -rw------- (600 permissions)

# 4. Test decryption manually
sops --decrypt hosts/$(hostname)/secrets.yaml
# Should show decrypted YAML content

# 5. Check current profile
echo $ACTIVE_PROFILE
# Should show: personal, work, or minimal
```

---

## Troubleshooting

### "Failed to decrypt"

**Symptom:** `sops --decrypt` fails or secrets not deployed

**Check age key:**
```bash
# 1. Verify key exists
ls -la ~/.config/sops/age/keys.txt

# 2. Check key format
cat ~/.config/sops/age/keys.txt
# Should start with: AGE-SECRET-KEY-1...

# 3. Check public key
grep "public key:" ~/.config/sops/age/keys.txt
```

**Check .sops.yaml:**
```bash
# Verify public key matches
cat .sops.yaml | grep age1
# Should match public key from keys.txt
```

**Test manually:**
```bash
sops --decrypt hosts/$(hostname)/secrets.yaml
# If fails, age key doesn't match
```

---

### "Placeholder detection" during activate.sh

**Symptom:** `./scripts/activate.sh` warns about <PLACEHOLDER> values

**Cause:** Secret template not fully edited

**Solution:**
```bash
# 1. Edit secret template
code hosts/$(hostname)/secrets-personal.nix

# 2. Find all <PLACEHOLDER> strings
# Replace with real values:
# api_keys = {
#   openai = "<PLACEHOLDER>";  # ← Replace this
# };

# 3. Run activation again
./scripts/activate.sh
```

---

### "Secrets not appearing in home directory"

**Check deployment:**
```bash
# 1. Check secrets.yaml exists and is encrypted
file hosts/$(hostname)/secrets.yaml
# Should show: data (binary)

# 2. Check nix-darwin configuration
darwin-rebuild --list-generations
# Verify latest generation applied

# 3. Check secret paths in host config
code hosts/$(hostname)/default.nix
# Verify sops.secrets paths are correct

# 4. Rebuild with verbose output
nix-rebuild --show-trace
```

---

### "Permission denied on secrets"

**Symptom:** Cannot read ~/.zsh_secrets or ~/.ssh/id_ed25519

**Check permissions:**
```bash
# Should all be 600 (owner read/write only)
ls -la ~/.zsh_secrets ~/.ssh/id_ed25519 ~/.aws/credentials
```

**Fix permissions:**
```bash
chmod 600 ~/.zsh_secrets
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.aws/credentials
```

**Check ownership in host config:**
```nix
# hosts/$(hostname)/default.nix
sops.secrets.zsh_secrets = {
  owner = config.machineConfig.username;  # Must match your username
  mode = "0600";
};
```

---

### "Can't edit secrets" (sops not installed)

**Install sops:**
```bash
# Via Nix
nix-env -iA nixpkgs.sops

# Or add to packages.nix
# modules/shared/packages.nix
environment.systemPackages = with pkgs; [
  sops
  age
];
```

**Or use bootstrap script:**
```bash
./scripts/bootstrap.sh
# Installs sops and age
```

---

## Security Best Practices

### Do's ✅

- ✅ **Always use SOPS** to edit secrets (never edit ~/.zsh_secrets directly)
- ✅ **Backup age key securely** (password manager + USB + paper)
- ✅ **Use separate keys per machine** (don't share keys across machines)
- ✅ **Rotate credentials regularly** (quarterly for critical credentials)
- ✅ **Verify encryption before committing** (use secrets-check)
- ✅ **Use profile-specific secrets** (separate personal vs work)
- ✅ **Run ./scripts/activate.sh** after editing secret templates

---

### Don'ts ❌

- ❌ **Never commit unencrypted secrets** (git hooks will block)
- ❌ **Never share age private key** (each machine needs unique key)
- ❌ **Don't edit ~/.zsh_secrets directly** (managed by SOPS, changes will be lost)
- ❌ **Don't skip backups** (age key is irreplaceable)
- ❌ **Don't use <PLACEHOLDER> in production** (replace all placeholders)
- ❌ **Don't commit secrets-personal.nix or secrets-work.nix** (gitignored templates)

---

### Verification Before Committing

```bash
# 1. Check all secrets are encrypted (binary format)
file hosts/*/secrets.yaml
# All should show: data (binary)

# 2. Check no plaintext secrets in git
g diff
# Should only show encrypted (binary) secrets.yaml changes

# 3. Run validation
secrets-check
# Should show: ✅ All secrets encrypted

# 4. Check permissions
ls -la ~/.zsh_secrets ~/.ssh/id_ed25519 ~/.aws/credentials
# All should show: -rw------- (600)

# 5. Commit safely
g aa && g cm "Update secrets" && g ps
```

---

### Git Protection (Automated Safeguards)

**Pre-commit hook (BLOCKING):**
- Validates SOPS encryption on all secrets.yaml files
- Checks file permissions on credential files (must be 600)
- Handles symlinks correctly (checks target permissions)
- Provides fix instructions with exact commands
- Collects ALL issues before failing

**What gets checked:**
- `hosts/*/secrets.yaml` - Must be encrypted (binary format)
- `~/.aws/credentials` - Must be 600 permissions
- `~/.db/*` - Must be 600 permissions
- `~/.tokens/*` - Must be 600 permissions

**Example error:**
```
❌ BLOCKED: Insecure file permissions detected

File: ~/.aws/credentials
Current: 644 (readable by group and others)
Required: 600 (owner read/write only)

Fix with:
  chmod 600 ~/.aws/credentials
```

**Bypass (emergencies only):**
```bash
# Skip hooks if absolutely necessary
git commit --no-verify -m "emergency fix"

# Then fix immediately!
chmod 600 ~/.aws/credentials
secrets-check
```

**Manual validation:**
```bash
./scripts/check-secrets-encrypted.sh
```

---

## Helper Commands

```bash
edit-secrets         # Edit encrypted secrets (auto-encrypts on save)
secrets-status       # Check secrets configuration and status
secrets-check        # Validate all secrets are encrypted
backup-age-key       # Backup age key to clipboard
```

**v2.0.0 Scripts:**
```bash
./scripts/bootstrap.sh    # Install Nix, nix-darwin, SOPS, age
./scripts/configure.sh    # Generate age keys, scan secrets, create templates
./scripts/activate.sh     # Encrypt secrets, build system, deploy
```

---

## Links

- **[Installation Guide](INSTALLATION.md)** - Complete v2.0.0 setup
- **[Backup & Recovery](backup-and-recovery.md)** - Age key backup procedures
- **[Troubleshooting](TROUBLESHOOTING.md)** - Secret-related issues
- **[SOPS Documentation](https://github.com/getsops/sops)** - SOPS project
- **[age Encryption](https://github.com/FiloSottile/age)** - age project

---

**Version**: v2.0.0
**Last Updated**: 2025-11-10
**Focus**: Profile-based secret management with SOPS age encryption
