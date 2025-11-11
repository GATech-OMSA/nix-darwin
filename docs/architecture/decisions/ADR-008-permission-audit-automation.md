# ADR-008: Permission Audit Automation

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

Credential files require strict permissions (600) for security:
- `~/.db/*` - Database connection files
- `~/.tokens/*` - API tokens
- `~/.aws/credentials` - AWS credentials
- `~/.ssh/*` - SSH keys (managed by system)

### Security Risk

Files with overly permissive permissions (e.g., 644, 755) are readable by:
- Other users on the system
- Processes running under different users
- Potential malware or attackers

### Current State

**Manual permission management**:
```bash
# User must remember to set permissions
chmod 600 ~/.tokens/api_key
chmod 600 ~/.db/oracle/prod
```

**Problems**:
1. **Easy to forget**: Creating new credential files
2. **System changes**: macOS updates can reset permissions
3. **Application behavior**: Some apps create files with default permissions
4. **No validation**: Silent security degradation
5. **Discovery lag**: Issues found only when checking manually

### Real Incidents

- Database credentials created with 644 (world-readable)
- API tokens with 755 permissions after app update
- Credentials readable by other local users for weeks
- No notification until manual security audit

## Decision

**Implement automated permission auditing with multi-layer enforcement.**

### Audit Architecture

```
Permission Audit System
├── Detection Layer
│   ├── Git hooks (pre-commit warnings)
│   ├── Health checks (system validation)
│   └── Scheduled audits (daily cron)
│
├── Notification Layer
│   ├── Console warnings
│   ├── Summary reports
│   └── Audit logs
│
└── Enforcement Layer
    ├── Auto-fix (optional, opt-in)
    ├── Manual fix prompts
    └── Documentation
```

### Audit Strategy

**1. Pre-commit Hook (Warning)**
```bash
# Warns but doesn't block commits
for file in ~/.db/* ~/.tokens/* ~/.aws/credentials; do
  perms=$(stat -f "%Lp" "$file")
  if [[ "$perms" != "600" ]]; then
    echo "⚠️  WARNING: $file has permissions $perms"
  fi
done
```

**2. Health Check (Validation)**
```bash
# Part of health-check command
check_credential_permissions() {
  # Audit all credential locations
  # Report insecure permissions
  # Provide fix commands
}
```

**3. Scheduled Audit (Proactive)**
```bash
# Daily cron job (optional)
audit-credentials
# Checks all credential files
# Logs issues to ~/.audit-log
# Sends notification if issues found
```

### Automation Levels

Users can choose automation level:

**Level 1: Manual (Default)**
- Audit reports issues
- User manually runs `chmod 600`
- No automatic changes

**Level 2: Auto-Fix with Confirmation**
- Audit detects issues
- Prompts for permission to fix
- Fixes only after confirmation

**Level 3: Auto-Fix Silent**
- Audit detects issues
- Automatically corrects permissions
- Logs actions for review

## Consequences

### Positive

✅ **Proactive detection**: Catch permission issues early
✅ **Continuous monitoring**: Regular audit schedule
✅ **Clear guidance**: Users know exactly what to fix
✅ **Audit trail**: Log all permission changes
✅ **Prevents drift**: Catch system-caused changes
✅ **Low friction**: Warnings don't block workflow
✅ **Configurable**: Users choose automation level

### Negative

⚠️ **Additional complexity**: More automation to maintain
⚠️ **False positives**: May flag legitimately public files
⚠️ **Permission changes**: Auto-fix might break workflows
⚠️ **Performance impact**: Periodic scans use resources
⚠️ **Noise**: Frequent warnings may be ignored

### Design Rationales

**Why warnings instead of errors?**
- See [ADR-007: Warning System Design](ADR-007-warning-system-design.md)
- Permissions often changed by system processes
- Blocking commits too disruptive
- Users can fix on their schedule

**Why scheduled audits?**
- Catch issues between git operations
- System-caused permission changes
- Provides regular security validation
- Builds security awareness

**Why configurable automation?**
- Different users have different risk tolerances
- Some environments prohibit auto-fix
- Progressive enhancement (start manual, enable auto-fix later)
- Respects user control

## Alternatives Considered

### Alternative 1: Block All Operations

Treat insecure permissions as errors (exit 1).

**Rejected because**:
- ❌ Too disruptive to workflow
- ❌ Forces `--no-verify` bypass
- ❌ Permissions often changed by system
- ❌ Better as warning (see ADR-007)

### Alternative 2: Always Auto-Fix

Automatically correct permissions on every audit.

**Rejected because**:
- ❌ No user control
- ❌ Might break legitimate use cases
- ❌ Could cause confusion
- ❌ Better to be configurable

### Alternative 3: No Automation

Only manual permission checks.

**Rejected because**:
- ❌ Easy to forget
- ❌ No proactive detection
- ❌ Security issues go unnoticed
- ❌ Defeats purpose of automation

### Alternative 4: File System Monitoring

Use `fswatch` to monitor permission changes in real-time.

**Rejected because**:
- ❌ High resource usage (continuous monitoring)
- ❌ Complex setup and maintenance
- ❌ Battery drain on laptops
- ❌ Overkill for personal system
- ❌ Scheduled audits sufficient

### Alternative 5: macOS ACLs

Use macOS Access Control Lists for advanced permissions.

**Rejected because**:
- ❌ More complexity than needed
- ❌ UNIX permissions sufficient
- ❌ Harder to audit and maintain
- ❌ Not portable to Linux if needed

## Implementation Notes

### Permission Audit Implementation

```bash
#!/bin/bash
# lib/audit-permissions.sh

audit_credential_permissions() {
  local mode="${1:-report}"  # report|fix|auto-fix
  local issues=0
  local fixes=0

  echo "🔒 Auditing credential file permissions..."

  # Define credential locations
  local credential_paths=(
    ~/.db
    ~/.tokens
    ~/.aws/credentials
  )

  # Scan each location
  for path in "${credential_paths[@]}"; do
    if [[ -d "$path" ]]; then
      # Directory: scan all files
      while IFS= read -r -d '' file; do
        check_and_fix_permission "$file" "$mode"
      done < <(find "$path" -type f -print0)
    elif [[ -f "$path" ]]; then
      # Single file
      check_and_fix_permission "$path" "$mode"
    fi
  done

  # Summary
  if [[ $issues -eq 0 ]]; then
    echo "✅ All credential files have secure permissions (600)"
  else
    echo "⚠️  Found $issues file(s) with insecure permissions"
    if [[ $fixes -gt 0 ]]; then
      echo "✅ Fixed $fixes file(s)"
    else
      echo "ℹ️  Run with --fix to correct permissions"
    fi
  fi

  return $issues
}

check_and_fix_permission() {
  local file="$1"
  local mode="$2"

  # Get current permissions
  local perms=$(stat -f "%Lp" "$file" 2>/dev/null)

  # Check if secure (600)
  if [[ "$perms" != "600" ]]; then
    issues=$((issues + 1))

    echo "⚠️  $file has permissions $perms (should be 600)"

    case "$mode" in
      fix)
        # Prompt for confirmation
        read -p "Fix? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          chmod 600 "$file"
          echo "   ✅ Fixed: chmod 600 $file"
          fixes=$((fixes + 1))
        fi
        ;;
      auto-fix)
        # Fix without confirmation
        chmod 600 "$file"
        echo "   ✅ Auto-fixed: chmod 600 $file"
        fixes=$((fixes + 1))
        ;;
      *)
        # Report only
        echo "   Fix with: chmod 600 $file"
        ;;
    esac
  fi
}
```

### Git Hook Integration

```bash
# .git/hooks/pre-commit
# Permission audit (warning only)
if command -v audit-permissions &> /dev/null; then
  echo "🔒 Checking credential permissions..."
  audit-permissions --report
fi
```

### Health Check Integration

```bash
# Part of health-check command
echo "🔒 Credential File Permissions:"
audit-permissions --report
```

### Scheduled Audit (Optional)

```nix
# modules/darwin/system.nix
launchd.user.agents.credential-audit = {
  serviceConfig = {
    Label = "com.user.credential-audit";
    ProgramArguments = [
      "${pkgs.bash}/bin/bash"
      "-c"
      "audit-permissions --report >> ~/.audit-log 2>&1"
    ];
    StartCalendarInterval = [
      { Hour = 9; Minute = 0; }  # Daily at 9 AM
    ];
    StandardOutPath = "/tmp/credential-audit.log";
    StandardErrorPath = "/tmp/credential-audit.error.log";
  };
};
```

## User Experience

### Report Mode (Default)

```bash
$ audit-permissions
🔒 Auditing credential file permissions...
⚠️  /Users/jimmy/.tokens/api_key has permissions 644 (should be 600)
   Fix with: chmod 600 /Users/jimmy/.tokens/api_key
⚠️  /Users/jimmy/.db/oracle/prod has permissions 755 (should be 600)
   Fix with: chmod 600 /Users/jimmy/.db/oracle/prod

⚠️  Found 2 file(s) with insecure permissions
ℹ️  Run with --fix to correct permissions
```

### Fix Mode (Interactive)

```bash
$ audit-permissions --fix
🔒 Auditing credential file permissions...
⚠️  /Users/jimmy/.tokens/api_key has permissions 644 (should be 600)
Fix? (y/N) y
   ✅ Fixed: chmod 600 /Users/jimmy/.tokens/api_key
⚠️  /Users/jimmy/.db/oracle/prod has permissions 755 (should be 600)
Fix? (y/N) y
   ✅ Fixed: chmod 600 /Users/jimmy/.db/oracle/prod

⚠️  Found 2 file(s) with insecure permissions
✅ Fixed 2 file(s)
```

### Auto-Fix Mode (Silent)

```bash
$ audit-permissions --auto-fix
🔒 Auditing credential file permissions...
⚠️  /Users/jimmy/.tokens/api_key has permissions 644 (should be 600)
   ✅ Auto-fixed: chmod 600 /Users/jimmy/.tokens/api_key
⚠️  /Users/jimmy/.db/oracle/prod has permissions 755 (should be 600)
   ✅ Auto-fixed: chmod 600 /Users/jimmy/.db/oracle/prod

⚠️  Found 2 file(s) with insecure permissions
✅ Fixed 2 file(s)
```

### Health Check Integration

```bash
$ health-check
🏥 System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔒 Credential File Permissions:
  ⚠️  2 file(s) with insecure permissions
     - /Users/jimmy/.tokens/api_key (644)
     - /Users/jimmy/.db/oracle/prod (755)

  Fix with: audit-permissions --fix

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Audit Logging

Log all permission audits and fixes:

```bash
# ~/.audit-log
2024-11-07 09:00:00 [INFO] Permission audit started
2024-11-07 09:00:01 [WARN] Insecure: ~/.tokens/api_key (644)
2024-11-07 09:00:01 [FIX]  Auto-fixed: ~/.tokens/api_key → 600
2024-11-07 09:00:01 [INFO] Permission audit complete (1 issue fixed)
```

## Configuration

Users can configure audit behavior:

```nix
# home/jimmy/default.nix
home.sessionVariables = {
  # Audit automation level: report|fix|auto-fix
  AUDIT_MODE = "report";

  # Additional credential paths to audit
  AUDIT_PATHS = "~/.custom-creds:~/.secrets";

  # Enable scheduled audit
  AUDIT_SCHEDULED = "true";
};
```

## Monitoring and Metrics

Track audit effectiveness:
- **Issues detected per week**
- **Time to resolution** (detection → fix)
- **System-caused changes** (identify patterns)
- **False positive rate**
- **Auto-fix adoption rate**

## Future Enhancements

**Potential improvements**:
1. **Smart detection**: Learn which files are credentials
2. **Context awareness**: Different permissions for different file types
3. **Notification system**: Email/Slack on critical issues
4. **Integration with secrets manager**: Auto-protect SOPS secrets
5. **Cross-platform**: Extend to Linux permission models
6. **Audit reports**: Weekly summary of security posture

## References

- [UNIX File Permissions](https://www.unixtutorial.org/commands/chmod)
- [macOS Security Best Practices](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/)
- [ADR-002: Secret Management Consolidation](ADR-002-secret-management-consolidation.md)
- [ADR-003: Git Hooks Enforcement](ADR-003-git-hooks-enforcement.md)
- [ADR-007: Warning System Design](ADR-007-warning-system-design.md)

## Revision History

- **2024-11-07**: Initial decision - Automated permission audit system
