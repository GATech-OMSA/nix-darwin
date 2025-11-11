# Backup Verification Script

## Overview

The `verify-backups.sh` script provides automated validation of backup completeness, integrity, and restore capability for the nix-darwin configuration.

## Features

### Verification Checks

1. **Directory Structure**
   - Validates backup directory exists
   - Checks for required subdirectories (app-configs, user-content)
   - Verifies backup script is executable

2. **Application Configs**
   - Claude Code configuration
   - Continue.dev configuration
   - Gemini configuration
   - iTerm2 preferences
   - Cursor configuration
   - Docker user config

3. **User Content**
   - VS Code snippets and settings
   - Jupyter/IPython configs
   - SSH known_hosts
   - Zoxide database

4. **Backup Integrity**
   - Calculates total backup size
   - Counts backed up files
   - Detects empty directories (potential issues)
   - Checks for .DS_Store pollution

5. **Restore Capability**
   - Tests file restoration to temporary location
   - Tests directory restoration
   - Validates restore process works correctly

6. **Backup Freshness**
   - Checks when backup was last updated
   - Warns if backup is stale (>24 hours old)
   - Fails if backup is very old (>1 week)

7. **Critical Files**
   - Ensures critical files are backed up
   - Provides clear warnings for missing critical data

## Usage

### Basic Verification

```bash
./scripts/verify-backups.sh
```

### Verbose Output

```bash
./scripts/verify-backups.sh --verbose
```

### Help

```bash
./scripts/verify-backups.sh --help
```

## Integration

### Health Check Integration

The backup verification is automatically included in the system health check:

```bash
./scripts/health-check.sh          # Includes backup verification
./scripts/health-check.sh --verbose # Shows detailed backup verification
```

### Exit Codes

- **0**: All verifications passed
- **1**: One or more verifications failed

## Output

### Summary Report

```
📊 VERIFICATION REPORT

Total Checks: 17
✓ Passed:     16
✗ Failed:     0
⚠ Warnings:   1

Verification Score: 94% (16/17 checks passed)
Status:             🟢 VERIFIED
```

### Status Indicators

- 🟢 **VERIFIED**: All checks passed (>90%)
- 🟡 **FAIR**: Some warnings or minor issues (80-90%)
- 🟡 **NEEDS ATTENTION**: Multiple warnings or failures (60-80%)
- 🔴 **CRITICAL**: Major failures (<60%)

## Recommendations

### If Verification Fails

1. Run backup script:
   ```bash
   ~/nix-darwin/user-data/backup.sh
   ```

2. Check verbose output:
   ```bash
   ./scripts/verify-backups.sh --verbose
   ```

3. Address specific failures shown in output

### If Backup is Stale

Run the backup script to refresh:
```bash
cd ~/nix-darwin/user-data
./backup.sh
```

### Best Practices

- Run verification weekly
- Verify after major system changes
- Test restore capability periodically
- Keep backups on external storage or cloud
- Monitor backup freshness

## Technical Details

### Temporary Directory

The script creates a temporary directory for restore testing:
- Location: `/tmp/nix-darwin-restore-test-<PID>`
- Automatically cleaned up on exit
- Used to test restore without affecting live data

### Checksums

Currently, the script validates existence and accessibility. Future enhancements may include:
- MD5/SHA checksums for integrity validation
- Incremental backup detection
- Differential verification

## Files Checked

### Critical Backups
- Claude Code configuration (~/.claude/)
- SSH known_hosts (~/.ssh/known_hosts)

### Application Configs
- All files in `user-data/app-configs/`

### User Content
- All files in `user-data/user-content/`

## See Also

- `backup.sh` - Creates the backup
- `health-check.sh` - Comprehensive system health check
- `audit-permissions.sh` - Security permission audit
