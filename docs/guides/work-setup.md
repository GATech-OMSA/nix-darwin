# Work Mac Setup Guide

This guide covers the work Mac configuration, including hybrid installation strategy, AWS SSO workflow, and database connectivity.

---

## Installation Strategy

### Hybrid Approach: Jamf + Nix

The work Mac uses a **hybrid installation strategy** to comply with IT policies while maintaining declarative configuration.

| Category | Installation Method | Rationale |
|----------|-------------------|-----------|
| **GUI Apps** | Jamf (Corporate IT) | IT-managed, compliant with corporate policies |
| **CLI Tools** | Nix (Declarative) | Version-controlled, reproducible, automated |
| **Homebrew** | **Disabled** | IT policy compliance (can be enabled if needed) |

### Currently Installed via Jamf

✅ **Rancher Desktop** - Docker alternative (replaces Docker Desktop)
✅ **Visual Studio Code** - IDE
✅ **DBeaver** - Database client GUI
✅ **AWS CLI** - Available via both Jamf and Nix
✅ **Other corporate-approved apps**

### Currently Installed via Nix

✅ **ODBC Drivers** - unixODBC, freetds (SQL Server), PostgreSQL client
✅ **AWS CLI v2** - Command-line AWS access
✅ **Terraform CLI** - Infrastructure as code
✅ **kubectl** - Kubernetes CLI
✅ **Database CLIs** - psql, pgcli (PostgreSQL), sqlcmd (SQL Server)
✅ **Modern CLI tools** - jq, yq, fx, bat, fd, ripgrep, etc.

---

## AWS SSO Workflow

### Quick Profile Switching

Pre-configured aliases for **tririga-integrations** project:

```bash
# Quick environment switching
awsdev        # → tririga-integrations-dev
awssbx        # → tririga-integrations-sbx
awsqa         # → tririga-integrations-qa
awsprod       # → tririga-integrations-prod

# Restore last-used profile
awslast       # → Restores previous profile from session
```

### AWS Commands

```bash
# Login to AWS SSO
awslogin <profile-name>

# Switch active profile (no login required if already authenticated)
awsuse <profile-name>

# Check current identity
awswho

# List all profiles
awslist

# Check all profile statuses
awscheck

# Refresh SSO session
awsrefresh <profile-name>

# Logout (clears all SSO sessions)
awslogout
```

### Auto-Completion

Tab completion is enabled for AWS profile names:

```bash
awsuse <TAB>              # Lists all available profiles
awslogin <TAB>            # Lists all available profiles
```

### Session Persistence

Your last-used AWS profile is **automatically restored** when you open a new shell:

```bash
# On shell startup:
🔄 Restored AWS profile: tririga-integrations-dev
```

The profile is saved to `~/.aws/.last_profile` and restored on every new shell session.

---

## Database Connectivity

### Multi-Environment Support

Database connections support **4 environments** × **6 database types** = **24 total connections**

**Environments:**
- `prod` - Production
- `dev` - Development
- `qa` - QA/Testing
- `test` - Test

**Database Types:**
- `oracle` - Oracle Database
- `mssql` - Microsoft SQL Server
- `postgres` - PostgreSQL
- `oracle-ps` - Oracle PeopleSoft
- `ods` - Operational Data Store
- `dw` - Data Warehouse

### Connection Commands

```bash
# Connect to databases (defaults to prod if no environment specified)
dbconnect-oracle [env]        # Oracle: prod|dev|qa|test
dbconnect-mssql [env]          # SQL Server: prod|dev|qa|test
dbconnect-postgres [env]       # PostgreSQL: prod|dev|qa|test
dbconnect-oracle-ps [env]      # PeopleSoft: prod|dev|qa|test
dbconnect-ods [env]            # ODS: prod|dev|qa|test
dbconnect-dw [env]             # Data Warehouse: prod|dev|qa|test

# List all configured database connections
dblist
```

### Examples

```bash
# Connect to Oracle development database
dbconnect-oracle dev

# Connect to SQL Server QA environment
dbconnect-mssql qa

# Connect to PostgreSQL production (defaults to prod)
dbconnect-postgres

# Connect to Data Warehouse test environment
dbconnect-dw test
```

### Database File Structure

Credentials are stored in encrypted secrets and auto-decrypted to:

```
~/.db/
├── oracle/
│   ├── prod
│   ├── dev
│   ├── qa
│   └── test
├── mssql/
│   ├── prod
│   ├── dev
│   ├── qa
│   └── test
├── postgres/
│   ├── prod
│   ├── dev
│   ├── qa
│   └── test
├── oracle-ps/
│   ├── prod
│   ├── dev
│   ├── qa
│   └── test
├── ods/
│   ├── prod
│   ├── dev
│   ├── qa
│   └── test
└── dw/
    ├── prod
    ├── dev
    ├── qa
    └── test
```

---

## Secrets Management

All sensitive credentials are **encrypted** with sops-nix and **version-controlled** safely.

### Encrypted Secrets Include

**SSH Keys:**
- Work SSH private key: `~/.ssh/id_ed25519_work`
- Work SSH public key: `~/.ssh/id_ed25519_work.pub`

**Database Credentials:**
- 24 database connection files (6 types × 4 environments)
- Stored in `~/.db/{database_type}/{environment}`

**API Tokens:**
- Git (GitHub/GitLab) token: `~/.tokens/git_token`
- HCP Terraform token: `~/.tokens/hcp_terraform_token`
- Jira API token: `~/.tokens/jira_api_token`
- Confluence token: `~/.tokens/confluence_token`
- ServiceNow credentials: `~/.credentials/servicenow`
- VPN credentials: `~/.credentials/vpn`

### Managing Secrets

```bash
# Edit encrypted secrets (opens secrets.yaml in SOPS)
edit-secrets

# Rebuild system to apply secret changes
nix-rebuild

# Verify secrets are encrypted
file hosts/mbp-work/secrets.yaml
# Output: data (encrypted, not ASCII text)
```

### Token Helper Commands

Copy API tokens to clipboard:

```bash
git-token         # Copy Git token to clipboard
terraform-token   # Copy HCP Terraform token to clipboard
jira-token        # Copy Jira API token to clipboard
```

---

## ODBC Configuration

### Installed ODBC Drivers

✅ **unixODBC** - ODBC driver manager
✅ **FreeTDS** - ODBC driver for SQL Server
✅ **PostgreSQL libpq** - PostgreSQL client library

### ODBC Environment Variables

Automatically configured:

```bash
ODBCSYSINI=/usr/local/etc
ODBCINI=/usr/local/etc/odbc.ini
```

### Verify ODBC Installation

```bash
# Check ODBC installation
odbcinst -j

# List available drivers
odbcinst -q -d

# Check SQL Server tool
sqlcmd -?

# Check PostgreSQL
psql --version
```

---

## Project Directory Shortcuts

Quick navigation to work projects:

```bash
scst         # cd ~/Dev/scst
ti           # cd ~/Dev/tririga
ps-proj      # cd ~/Dev/paging-solution
mp           # cd ~/Dev/misc-projects
wfhub        # cd ~/Dev/workforce-hub
ap           # cd ~/Dev/webMethods/api
deploys      # cd ~/Dev/production-deploys
```

---

## Work-Specific Tools

### HRStringCrypter

```bash
crypter      # Launch HRStringCrypter Python tool
```

### Terraform Workspace Shortcuts

```bash
tfdev        # terraform workspace select dev
tfprod       # terraform workspace select prod
```

### VPN & Corporate Tools

```bash
vpn          # Open Cisco AnyConnect
cdwork       # cd ~/Work
cdrepo       # cd ~/Work/repositories
```

---

## First-Time Setup

### 1. Generate Age Key (for secrets encryption)

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Note: Save the public key to add to .sops.yaml
```

### 2. Add Actual Secrets

```bash
# Edit secrets file (all values are currently placeholders)
edit-secrets

# Replace [PLACEHOLDER] values with actual:
# - Work SSH keys
# - Database credentials (24 environments)
# - API tokens (Git, Terraform, Jira, etc.)
```

### 3. Rebuild System

```bash
# Apply all changes (from nix-darwin directory)
darwin-rebuild switch --flake .#mbp-work

# Restart shell to load new configurations
exec zsh
```

### 4. Verify Everything Works

```bash
# Check ODBC
odbcinst -j

# Check AWS SSO
awslist

# Check database connections
dblist

# Check secrets restored
ls -la ~/.ssh/id_ed25519_work
ls -la ~/.db/
ls -la ~/.tokens/
```

---

## Troubleshooting

### Homebrew Disabled

If you need a specific app:
1. **Check if available via Nix**: Search at https://search.nixos.org/packages
2. **Request from IT**: Use Jamf Self Service
3. **Manual install**: Download from vendor website
4. **Enable Homebrew**: Set `homebrew.enable = true` in `hosts/mbp-work/default.nix` (if IT allows)

### AWS SSO Issues

```bash
# Clear SSO cache
awslogout

# Re-login
awslogin <profile-name>

# If profile not found
awslist                    # Check available profiles
```

### Database Connection Issues

```bash
# List configured connections
dblist

# Check if credentials file exists
ls -la ~/.db/{database_type}/{environment}

# Check ODBC drivers
odbcinst -q -d

# Re-decrypt secrets
nix-rebuild
```

### Secrets Not Decrypting

```bash
# Verify age key exists
ls -la ~/.config/sops/age/keys.txt

# Verify secrets.yaml is encrypted
file hosts/mbp-work/secrets.yaml

# Check sops-nix service
launchctl list | grep sops

# Rebuild system
nix-rebuild
```

---

## Daily Workflow

### Starting Your Day

```bash
# 1. Open terminal - AWS profile auto-restores
🔄 Restored AWS profile: tririga-integrations-dev

# 2. Verify AWS identity
awswho

# 3. Connect to databases as needed
dbconnect-oracle dev
dbconnect-mssql qa
```

### Switching Projects

```bash
# Switch AWS environment
awsqa                      # Quick switch to QA
awswho                     # Verify identity

# Connect to QA databases
dbconnect-oracle qa
dbconnect-dw qa
```

### End of Day

```bash
# Optional: Clear AWS SSO sessions for security
awslogout
```

---

## Additional Resources

- [Installation Guide](installation.md) - Complete nix-darwin setup
- [Secrets Guide](secrets.md) - Managing encrypted secrets with sops-nix
- [Backup & Recovery](backup-and-recovery.md) - Disaster recovery procedures
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

---

**Last Updated:** 2025-11-03
**Work Mac:** mbp-work (M3)
**Configuration Version:** 2.0
