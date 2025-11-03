# Enterprise Credential Management Guide

**Complete setup guide for AWS SSO + Multi-Database credential management with rotating passwords**

---

## Overview

This guide implements enterprise-scale credential management for organizations with:
- **10+ AWS projects** with multiple environments (dev/sbx/qa/prod) and roles
- **Multiple database instances** per type (Oracle, SQL Server, PostgreSQL)
- **Rotating passwords** that require frequent updates
- **Centralized credential storage** with SOPS encryption

### Key Benefits

✅ **No Nix Rebuild** - Credential rotation only requires `exec zsh`
✅ **Centralized Management** - All credentials in one encrypted file
✅ **Instance-Based** - Organize by database instance, not type
✅ **Universal Commands** - `awsuse <project> <env> [role]` pattern
✅ **Profile Persistence** - AWS_PROFILE auto-restores across sessions

---

## Architecture

### Credential Storage

```
~/.secrets/
├── credentials.env.enc     # Encrypted with SOPS (safe to commit)
└── credentials.env          # Decrypted on shell start (auto-deleted)
```

### Variable Naming Convention

**Pattern**: `<PROJECT>_<ENV>_<TYPE>`

```bash
# Examples:
TI_PROD_USERNAME="ti_prod"
TI_PROD_PASSWORD="rotating-password"
TI_PROD_HOST="prod-oracle.company.com"
TI_PROD_PORT="1521"
TI_PROD_SERVICE="TIPROD"
```

### AWS Profile Persistence

```
~/.aws/
├── config                  # AWS SSO profiles (managed manually)
└── .last_profile           # Last used profile (auto-saved)
```

---

## Part 1: Initial Setup (One-Time)

### Step 1: Verify Age Key

```bash
# Check if age key exists
ls -la ~/.config/sops/age/keys.txt

# If not found, generate one:
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Get your public key (for .sops.yaml):
grep "public key:" ~/.config/sops/age/keys.txt
```

### Step 2: Create Encrypted Credentials File

```bash
# Run the edit-credentials command (creates template on first run)
edit-credentials
```

**What happens:**
1. Creates `~/.secrets/` directory (if needed)
2. Generates template with examples
3. Encrypts template to `.enc` file
4. Opens in your editor (via sops)

### Step 3: Update Credentials Template

When the editor opens, update the template:

```bash
# ==================================================
# LAN CREDENTIALS (Reusable)
# ==================================================
export LAN_USERNAME="your-actual-lan-id"
export LAN_PASSWORD="your-actual-lan-password"

# ==================================================
# TRIRIGA (TI) - Oracle Database
# ==================================================
# Development
export TI_DEV_USERNAME="ti_dev"
export TI_DEV_PASSWORD="actual-dev-password"
export TI_DEV_HOST="dev-oracle.company.com"
export TI_DEV_PORT="1521"
export TI_DEV_SERVICE="TIDEV"

# QA
export TI_QA_USERNAME="ti_qa"
export TI_QA_PASSWORD="actual-qa-password"
export TI_QA_HOST="qa-oracle.company.com"
export TI_QA_PORT="1521"
export TI_QA_SERVICE="TIQA"

# Production
export TI_PROD_USERNAME="ti_prod"
export TI_PROD_PASSWORD="actual-prod-password"
export TI_PROD_HOST="prod-oracle.company.com"
export TI_PROD_PORT="1521"
export TI_PROD_SERVICE="TIPROD"
```

**Save and exit** - SOPS automatically encrypts the file.

### Step 4: Reload Shell

```bash
# Reload to activate credentials
exec zsh
```

**Expected output:**
```
🔐 Loaded 15 credentials
🔄 Restored AWS Profile: ti-dev-support
💡 Run 'awswho' for details or 'awsuse' to switch
```

### Step 5: Verify Credentials Loaded

```bash
# Test that variables are set
echo $TI_PROD_USERNAME
echo $LAN_USERNAME

# List all loaded credentials
env | grep -E "(TI_|HR|PAYROLL|LAN_)" | sort
```

---

## Part 2: AWS SSO Setup

### Step 1: Configure AWS SSO Profiles

Edit `~/.aws/config`:

```ini
[sso-session domain-sso]
sso_start_url = https://your-domain.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access

# Tririga Integrations - Dev
[profile tririga-integrations-dev-support]
sso_session = domain-sso
sso_account_id = 123456789012
sso_role_name = SupportRole
region = us-east-1
output = json

# Tririga Integrations - SBX - Developer
[profile tririga-integrations-sbx-developer]
sso_session = domain-sso
sso_account_id = 123456789013
sso_role_name = DeveloperRole
region = us-east-1
output = json

# Tririga Integrations - QA
[profile tririga-integrations-qa-support]
sso_session = domain-sso
sso_account_id = 123456789014
sso_role_name = SupportRole
region = us-east-1
output = json

# HR System - Prod
[profile hr-system-prod-support]
sso_session = domain-sso
sso_account_id = 123456789015
sso_role_name = SupportRole
region = us-east-1
output = json
```

### Step 2: Test AWS SSO Login

```bash
# Login to a project (full name or short name)
awslogin tririga-integrations dev

# OR use short name:
awslogin ti dev

# With specific role:
awslogin ti sbx developer
```

**What happens:**
1. Browser opens for SSO login
2. AWS_PROFILE set automatically
3. Profile saved to `~/.aws/.last_profile`
4. Auto-restores on next shell session

### Step 3: Switch Profiles (Without Re-Login)

```bash
# Switch to different profile (no SSO login)
awsuse tririga-integrations qa
awsuse ti prod
awsuse hr prod
```

### Step 4: Check Current Profile

```bash
# Show current profile details
awswho

# List all available profiles
awslist
```

---

## Part 3: Database Connection Setup

### Step 1: Add Database Instances to work.nix

Your database instances are already configured in `home/_mixins/work.nix`. To add a new one:

```nix
# In work.nix programs.zsh.initExtra
${myLib.database.mkDatabaseInstances [
  # Existing instances...

  # Add new instance:
  {
    instance = "newdb";
    type = "oracle";  # or mssql, postgres, mysql
    environments = [ "dev" "qa" "prod" ];
    description = "New Database Description";
  }
]}
```

### Step 2: Add Credentials for New Instance

```bash
# Edit credentials
edit-credentials
```

Add variables following the naming pattern:

```bash
# ==================================================
# NEW DATABASE - Oracle
# ==================================================
export NEWDB_DEV_USERNAME="newdb_dev"
export NEWDB_DEV_PASSWORD="dev-password"
export NEWDB_DEV_HOST="dev.company.com"
export NEWDB_DEV_PORT="1521"
export NEWDB_DEV_SERVICE="NEWDEV"

export NEWDB_QA_USERNAME="newdb_qa"
export NEWDB_QA_PASSWORD="qa-password"
export NEWDB_QA_HOST="qa.company.com"
export NEWDB_QA_PORT="1521"
export NEWDB_QA_SERVICE="NEWQA"

export NEWDB_PROD_USERNAME="newdb_prod"
export NEWDB_PROD_PASSWORD="prod-password"
export NEWDB_PROD_HOST="prod.company.com"
export NEWDB_PROD_PORT="1521"
export NEWDB_PROD_SERVICE="NEWPROD"
```

### Step 3: Rebuild Nix (For New Instance Only)

```bash
# Only needed when ADDING new database instance
nix-rebuild
```

### Step 4: Test Database Connection

```bash
# Connect to database
dbconnect-newdb dev
dbconnect-newdb qa
dbconnect-newdb prod

# List all configured instances
dblist-instances
```

---

## Part 4: Daily Usage

### AWS Workflow

```bash
# Morning: Shell starts, profile auto-restored
# Output: "🔄 Restored AWS Profile: ti-dev-support"

# Switch projects as needed (no re-login)
awsuse hr qa
awsuse wfh prod

# Check current profile
awswho

# Need to switch role? (requires re-login)
awslogin ti sbx developer
```

### Database Workflow

```bash
# Connect to any configured database
dbconnect-ti dev
dbconnect-hrdb prod
dbconnect-ps qa
dbconnect-ods prod
dbconnect-dw prod
dbconnect-payroll qa

# Check what's available
dblist-instances
```

---

## Part 5: Credential Rotation (Common!)

### Scenario: Password Changed for TI Production

**Old workflow (painful):**
- Update 10+ credential files
- chmod each file
- Test each environment
- 30+ minutes

**New workflow (easy):**

```bash
# 1. Edit credentials
edit-credentials

# 2. Find and update the password
# Change: export TI_PROD_PASSWORD="old-password"
# To:     export TI_PROD_PASSWORD="new-password"

# 3. Save and exit

# 4. Reload shell (NO nix rebuild!)
exec zsh

# 5. Test immediately
dbconnect-ti prod
```

**Time: 2 minutes!**

### Scenario: Rotating Multiple Passwords

```bash
# 1. Edit credentials
edit-credentials

# 2. Update all rotating passwords in one place:
export TI_DEV_PASSWORD="new-dev-pass"
export TI_QA_PASSWORD="new-qa-pass"
export TI_PROD_PASSWORD="new-prod-pass"
export HRDB_PROD_PASSWORD="new-hr-pass"
export LAN_PASSWORD="new-lan-pass"  # Used by multiple DBs!

# 3. Save, reload, test
exec zsh
dbconnect-ti prod
dbconnect-hrdb prod
```

---

## Part 6: Adding New Projects

### Scenario: New Project "Analytics Platform" (AP)

#### Step 1: Add AWS Profiles

Edit `~/.aws/config`:

```ini
[profile analytics-platform-dev-support]
sso_session = domain-sso
sso_account_id = 999888777666
sso_role_name = SupportRole
region = us-east-1

[profile analytics-platform-prod-support]
sso_session = domain-sso
sso_account_id = 999888777667
sso_role_name = SupportRole
region = us-east-1
```

#### Step 2: Add to work.nix AWS Configuration

```nix
# In work.nix, add to both mkAwsUniversalCommand and mkAwsSsoLogin:
{
  name = "analytics-platform";
  short = "ap";
  environments = [ "dev" "prod" ];
  roles = [ "support" "data-engineer" ];
}
```

#### Step 3: Add Database Instance

```nix
# In work.nix mkDatabaseInstances:
{
  instance = "analytics";
  type = "postgres";
  environments = [ "dev" "prod" ];
  description = "Analytics Platform PostgreSQL";
}
```

#### Step 4: Add Credentials

```bash
edit-credentials

# Add variables:
export ANALYTICS_DEV_USERNAME="analytics_dev"
export ANALYTICS_DEV_PASSWORD="dev-password"
export ANALYTICS_DEV_HOST="dev-postgres.company.com"
export ANALYTICS_DEV_PORT="5432"
export ANALYTICS_DEV_DATABASE="analytics"

export ANALYTICS_PROD_USERNAME="analytics_prod"
export ANALYTICS_PROD_PASSWORD="prod-password"
export ANALYTICS_PROD_HOST="prod-postgres.company.com"
export ANALYTICS_PROD_PORT="5432"
export ANALYTICS_PROD_DATABASE="analytics"
```

#### Step 5: Rebuild and Test

```bash
# Rebuild for new AWS/DB config
nix-rebuild

# Test AWS
awslogin ap dev
awswho

# Test Database
dbconnect-analytics dev
```

---

## Part 7: Security Best Practices

### Encryption Verification

```bash
# Check encrypted file exists
ls -la ~/.secrets/credentials.env.enc

# Verify unencrypted file is auto-deleted after loading
ls -la ~/.secrets/credentials.env
# Should show: "No such file or directory"
```

### File Permissions

```bash
# Check age key permissions
ls -l ~/.config/sops/age/keys.txt
# Should show: -rw------- (600)

# Check encrypted credentials
ls -l ~/.secrets/credentials.env.enc
# Should show: -rw------- (600)
```

### Gitignore Verification

```bash
# Ensure unencrypted credentials are ignored
cd ~/nix-darwin
git status

# Should NOT show:
#   .secrets/credentials.env
#   ~/.config/sops/age/keys.txt
```

### Emergency: Credentials Exposed

```bash
# 1. Immediately rotate all passwords
#    (use company password rotation tool)

# 2. Update credentials file
edit-credentials

# 3. Verify old file is deleted
rm ~/.secrets/credentials.env.enc.old

# 4. Reload
exec zsh

# 5. Test all connections with new passwords
```

---

## Part 8: Troubleshooting

### Credentials Not Loading

**Symptom**: No "🔐 Loaded N credentials" message on shell start

**Checks**:
```bash
# 1. Check encrypted file exists
ls -la ~/.secrets/credentials.env.enc

# 2. Check sops is installed
which sops

# 3. Check age key exists
ls -la ~/.config/sops/age/keys.txt

# 4. Try manual decryption
cd ~/.secrets
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --decrypt credentials.env.enc
```

**Solutions**:
- If no encrypted file: Run `edit-credentials` to create
- If no sops: Run `nix-rebuild` (sops included)
- If no age key: Run `age-keygen -o ~/.config/sops/age/keys.txt`

### Database Connection Fails

**Symptom**: "❌ Credentials not found for TI_PROD_USERNAME"

**Checks**:
```bash
# 1. Verify credentials loaded
env | grep TI_PROD

# 2. Check variable names match
#    Instance: ti, Environment: prod
#    Expected: TI_PROD_USERNAME (uppercase!)

# 3. Reload shell
exec zsh
```

**Solutions**:
- Check variable naming: `<INSTANCE>_<ENV>_<TYPE>` (all uppercase)
- Verify credentials saved: `edit-credentials`
- Reload shell: `exec zsh`

### AWS Profile Not Persisting

**Symptom**: AWS_PROFILE not set after new shell

**Checks**:
```bash
# 1. Check last profile file
cat ~/.aws/.last_profile

# 2. Check profile exists in config
grep "profile $(cat ~/.aws/.last_profile)" ~/.aws/config
```

**Solutions**:
- Re-login: `awslogin <project> <env>`
- Manual set: `awsuse <project> <env>`

### Wrong Database Type Connection

**Symptom**: Using SQL Server command for Oracle database

**Check Configuration**:
```bash
# View instance configurations
dblist-instances

# Verify in work.nix:
# - instance name matches
# - type is correct (oracle/mssql/postgres)
```

### SOPS Decryption Fails

**Symptom**: "Error decrypting file"

**Common Causes**:
1. Wrong age key
2. File corrupted
3. Encrypted with different key

**Recovery**:
```bash
# 1. Backup current encrypted file
cp ~/.secrets/credentials.env.enc ~/.secrets/backup.env.enc

# 2. Recreate from template
rm ~/.secrets/credentials.env.enc
edit-credentials

# 3. Manually copy values from backup
#    (decrypt backup with sops if you have the key)
```

---

## Part 9: Command Reference

### Credential Management

```bash
edit-credentials         # Edit encrypted credentials
exec zsh                # Reload credentials (after edit)
env | grep TI_          # Check loaded credentials
```

### AWS Commands

```bash
awsuse <project> <env> [role]     # Switch profile (no login)
awslogin <project> <env> [role]   # SSO login + set profile
awswho                             # Show current profile
awslist                            # List all profiles
```

### Database Commands

```bash
dbconnect-<instance> <env>        # Connect to database
dblist-instances                  # List all instances
```

### Troubleshooting

```bash
secrets-status           # Check secrets configuration
nix-health              # System health check
nix-rebuild             # Rebuild (only for config changes)
```

---

## Part 10: Quick Wins vs When to Rebuild

### ✅ **NO REBUILD NEEDED** (2 minutes)

- **Credential rotation**: `edit-credentials` → `exec zsh`
- **AWS profile switching**: `awsuse <project> <env>`
- **Password updates**: `edit-credentials` → `exec zsh`
- **Adding variables**: `edit-credentials` → `exec zsh`

### 🔧 **REBUILD REQUIRED** (5 minutes)

- **New database instance**: Add to work.nix → `nix-rebuild`
- **New AWS project**: Add to work.nix → `nix-rebuild`
- **New database type**: Add to work.nix → `nix-rebuild`
- **Function logic changes**: Edit helpers → `nix-rebuild`

---

## Part 11: Migration from Old System

### If You Have Existing File-Based Credentials

```bash
# 1. List existing credential files
ls -la ~/.db/
ls -la ~/.tokens/

# 2. Extract variables from files
#    Example: ~/.db/tririga-oracle/prod contains:
#    USERNAME=ti_prod
#    PASSWORD=secret123
#    HOST=prod.company.com

# 3. Add to new system
edit-credentials

# Add as environment variables:
export TI_PROD_USERNAME="ti_prod"
export TI_PROD_PASSWORD="secret123"
export TI_PROD_HOST="prod.company.com"

# 4. Test new connections
exec zsh
dbconnect-ti prod

# 5. Once verified, delete old files
rm -rf ~/.db/tririga-oracle/
```

---

## Summary

**One-Time Setup**: ~15 minutes
- Generate age key
- Run `edit-credentials`
- Configure AWS profiles
- Add credentials

**Daily Usage**: Instant
- Shell auto-loads credentials
- AWS profile auto-restores
- Database connections ready

**Credential Rotation**: 2 minutes
- `edit-credentials`
- Update password
- `exec zsh`
- ✅ Done!

**Adding New Project**: 5 minutes
- Add to work.nix
- Add credentials
- `nix-rebuild`
- Test connections

---

**Version**: 1.0.0
**Last Updated**: 2025-11-03
**Status**: Production Ready ✅
