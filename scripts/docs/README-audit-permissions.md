# Security Permission Audit Script

**File**: `scripts/audit-permissions.sh`
**Purpose**: Automated security audit for credential file permissions
**Registry**: All paths defined in `lib/secrets-registry.nix`

## Overview

This script provides comprehensive security auditing of all credential and secret files registered in the centralized secret registry. It validates that sensitive files have the correct 600 permissions (owner read/write only) and provides automated fixing capabilities.

## Features

- **Comprehensive Coverage**: Audits all 42 registered secret paths across 7 categories
- **Automated Fix**: Optional `--fix` flag to automatically correct insecure permissions
- **Detailed Reporting**: Security scores, statistics, and actionable recommendations
- **Integration Ready**: Integrated into `health-check.sh` for system-wide validation
- **Color-Coded Output**: Visual feedback with green (secure), red (insecure), yellow (missing)

## Usage

### Basic Audit (No Changes)

```bash
./scripts/audit-permissions.sh
```

**Output**:
- Lists all insecure files with current permissions
- Provides security score and status (SECURE, NEEDS ATTENTION, CRITICAL)
- Shows fix recommendations

### Automated Fix Mode

```bash
./scripts/audit-permissions.sh --fix
```

**Behavior**:
- Automatically changes insecure files to 600 permissions
- Reports which files were successfully fixed
- Lists any files that failed to fix (requires manual intervention)

### Verbose Mode

```bash
./scripts/audit-permissions.sh --verbose
```

**Output**:
- Shows all files checked (including missing files)
- Displays detailed information for each category
- Useful for debugging or comprehensive review

### Show Secure Files

```bash
./scripts/audit-permissions.sh --show-secure
```

**Output**:
- Normally secure files are hidden (assumed good)
- This flag shows all secure files with 600 permissions

### Combined Options

```bash
./scripts/audit-permissions.sh --fix --verbose
./scripts/audit-permissions.sh -f -v -s
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All existing files have secure permissions |
| 1 | Insecure files found (audit mode) or fix failed |

## File Categories

The script audits files in the following categories:

### 1. AWS Credentials (4 files)
- `~/.aws/credentials` - AWS access keys
- `~/.aws/config` - AWS configuration
- `~/.aws/accounts.json` - Account mappings
- `~/.aws/.last_profile` - Session state

### 2. Database Connections (24 files)
- Oracle (prod, dev, qa, test)
- MSSQL (prod, dev, qa, test)
- PostgreSQL (prod, dev, qa, test)
- Oracle PS (prod, dev, qa, test)
- ODS (prod, dev, qa, test)
- DW (prod, dev, qa, test)

### 3. SSH Keys (5 files)
- `~/.ssh/id_ed25519` - Personal private key
- `~/.ssh/id_ed25519.pub` - Personal public key
- `~/.ssh/id_ed25519_work` - Work private key
- `~/.ssh/id_ed25519_work.pub` - Work public key
- `~/.ssh/known_hosts` - Known hosts file

### 4. API Tokens (4 files)
- `~/.tokens/git_token` - Git authentication
- `~/.tokens/hcp_terraform_token` - Terraform Cloud
- `~/.tokens/jira_api_token` - JIRA API
- `~/.tokens/confluence_token` - Confluence API

### 5. Service Credentials (2 files)
- `~/.credentials/servicenow` - ServiceNow credentials
- `~/.credentials/vpn` - VPN credentials

### 6. General Secrets (2 files)
- `~/.secrets/credentials.env` - Environment credentials
- `~/.secrets/credentials.env.enc` - Encrypted credentials

### 7. SOPS Encryption Key (1 file)
- `~/.config/sops/age/keys.txt` - SOPS age encryption key

## Output Format

### Audit Mode

```
🔒 SECURITY PERMISSION AUDIT

Checking all files in lib/secrets-registry.nix
Required permissions: 600 (owner read/write only)

▶ AWS CREDENTIALS

  ✗ /Users/jimmy/.aws/credentials (755)
  ✓ /Users/jimmy/.aws/config (600)

📊 SECURITY AUDIT SUMMARY

Files Checked:    42
✓ Secure (600):   38
✗ Insecure:       4
○ Missing:        0

Security Score:  95% (38/42 secure)
Status:          🟢 SECURE
```

### Fix Mode

```
🔒 SECURITY PERMISSION AUDIT & FIX

▶ AWS CREDENTIALS

  ✗ /Users/jimmy/.aws/credentials (755)
  ✓ Fixed: /Users/jimmy/.aws/credentials (600 → 600)

📊 SECURITY AUDIT SUMMARY

Files Checked:    42
✓ Secure (600):   42
✗ Insecure:       0
○ Missing:        0
🔧 Fixed:         4

Security Score:  100% (42/42 secure)
Status:          🟢 SECURE

✓ Successfully fixed 4 file(s)
✓ All existing credential files have secure permissions!
```

## Integration with Health Check

The script is automatically integrated into `scripts/health-check.sh`:

```bash
./scripts/health-check.sh
```

**Integration Features**:
- Runs during "SECRETS & ENCRYPTION" section
- Parses audit output and reports summary
- Shows full audit in verbose mode: `--verbose`
- Provides actionable fix recommendations

**Example Output**:
```
▶ SECRETS & ENCRYPTION

  ✓ SOPS command available
  ✓ SOPS age key exists
  ✓ All secrets files encrypted

  Running comprehensive permission audit...
  ✓ Credential file permissions secure (42/42 files with 600 permissions)
```

## Security Scores

| Score | Status | Color | Meaning |
|-------|--------|-------|---------|
| 100% | SECURE | 🟢 Green | All files secure |
| 80-99% | FAIR | 🟡 Yellow | Minor issues |
| 60-79% | NEEDS ATTENTION | 🟡 Yellow | Multiple issues |
| <60% | CRITICAL | 🔴 Red | Severe issues |

## Best Practices

### Regular Audits

Run periodic security audits:

```bash
# Weekly security audit
./scripts/audit-permissions.sh

# Automated fix if needed
./scripts/audit-permissions.sh --fix
```

### CI/CD Integration

Add to CI/CD pipelines:

```bash
# Fail build if insecure permissions detected
./scripts/audit-permissions.sh || exit 1
```

### After Adding New Credentials

When adding new credential files:

1. Add path to `lib/secrets-registry.nix`
2. Run audit to verify: `./scripts/audit-permissions.sh`
3. Fix if needed: `./scripts/audit-permissions.sh --fix`

## Troubleshooting

### Permission Denied Errors

Some system files may be protected:

```bash
chmod: Unable to change file mode on /Users/jimmy/.aws/config: Operation not permitted
```

**Solution**: Fix manually with elevated permissions or check file flags:
```bash
ls -lO ~/.aws/config  # Check for immutable flag
sudo chflags nouchg ~/.aws/config  # Remove immutable flag
chmod 600 ~/.aws/config
```

### Missing Files

Missing files are normal - not all registered paths exist on all machines:

- **Personal Mac**: No work SSH keys, no work AWS configs
- **Work Mac**: No personal tokens, no personal credentials

Missing files do not affect security score (only existing files counted).

### False Positives

Public key files (`.pub`) technically don't need 600 permissions, but we enforce it for consistency and defense-in-depth security.

## Technical Details

### Permission Check Logic

```bash
# Get file permissions (3 digits only)
perms=$(stat -f "%A" "$file" 2>/dev/null || echo "000")

# Check if secure (600 = owner read/write only)
if [[ "$perms" == "600" ]]; then
  # Secure
else
  # Insecure
fi
```

### Path Expansion

```bash
# Expand ${HOME} variable in paths
expand_path() {
  local path="$1"
  echo "${path//\$\{HOME\}/$HOME}"
}
```

### Color Code Stripping

For integration with health-check.sh:

```bash
# Strip ANSI color codes for parsing
audit_clean=$(echo "$audit_output" | sed 's/\x1b\[[0-9;]*m//g')
```

## Related Files

- **Registry**: `lib/secrets-registry.nix` - Centralized secret path registry
- **Health Check**: `scripts/health-check.sh` - System health validation
- **Git Hooks**: `.git/hooks/pre-commit` - Pre-commit permission validation
- **Git Hooks**: `.git/hooks/pre-push` - Pre-push permission validation

## Security Philosophy

This script implements **defense-in-depth** security principles:

1. **Prevention**: Git hooks block commits with insecure permissions
2. **Detection**: Automated audits detect permission issues
3. **Remediation**: Automated fix capabilities restore secure state
4. **Validation**: Health checks ensure ongoing compliance

All credential files must have 600 permissions:
- **Owner**: Read + Write
- **Group**: No access
- **Others**: No access

This ensures only the file owner can access sensitive credentials.
