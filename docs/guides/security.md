# Security Configuration Guide

**Comprehensive security best practices for nix-darwin configuration**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Security Layers](#security-layers)
3. [Secrets Management](#secrets-management)
4. [File Permissions](#file-permissions)
5. [Permission Audit System](#permission-audit-system)
6. [Warning System](#warning-system)
7. [Git Security](#git-security)
8. [Security Testing](#security-testing)
9. [Network Security](#network-security)
10. [AWS Security](#aws-security)
11. [System Hardening](#system-hardening)
12. [Defense-in-Depth Strategy](#defense-in-depth-strategy)
13. [Security Validation](#security-validation)
14. [Incident Response](#incident-response)
15. [Security Checklist](#security-checklist)

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

**Phase 4 enhancements:**

4. **Graduated Responses** - 3-level warning system (INFO → WARNING → ERROR)
5. **Continuous Monitoring** - Automated permission audits and testing
6. **Role-Based Security** - AWS multi-role boundaries and session isolation

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

### Layer 5: Permission Audit System

**What:** Automated permission scanning and reporting system

**Protects against:**
- Permission drift over time
- Insecure files created outside git workflow
- Cross-machine permission inconsistencies

**Implementation:**
```bash
# Comprehensive permission audit
audit-permissions

# Quick security scan
security-scan

# Detailed analysis with recommendations
audit-permissions --detailed
```

**See:** [Permission Audit System](#permission-audit-system) for complete usage

### Layer 6: Warning System

**What:** 3-level graduated response system for security issues

**Protects against:**
- Alert fatigue from excessive blocking
- Missing important security issues
- Unclear severity assessment

**Levels:**
- 🔵 **INFO** - Recommendations and best practices
- ⚠️ **WARNING** - Security concerns requiring attention
- ❌ **ERROR** - Critical issues blocking commits

**See:** [Warning System](#warning-system) for complete details

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

## Permission Audit System

**Purpose:** Proactive security monitoring through automated permission scanning

### Quick Start

```bash
# Run comprehensive audit
audit-permissions

# Output example:
# 🔍 Scanning credential files...
#
# ✅ Secure Files (600):
#   ~/.aws/credentials
#   ~/.tokens/github_token
#   ~/.db/oracle/prod
#
# ⚠️  Insecure Files:
#   ~/.db/postgres/dev (644) - WORLD READABLE
#
# 📊 Summary: 15 secure, 1 insecure
# 🔧 Fix: chmod 600 ~/.db/postgres/dev
```

### Audit Scope

**Scanned locations:**

```bash
# AWS credentials
~/.aws/credentials
~/.aws/config  # Not checked (public config)

# Database connections
~/.db/**/*  # All files recursively

# API tokens
~/.tokens/**/*

# SSH keys
~/.ssh/id_*  # Private keys only (not *.pub)
~/.ssh/known_hosts  # Not checked (public)

# Generic credentials
~/.credentials/**/*

# User secrets
~/nix-darwin/user-data/secrets/**/*
```

### Security Analysis

**Permission classification:**

```bash
# ✅ SECURE (600)
-rw-------  owner only read/write

# ⚠️  GROUP READABLE (640, 660)
-rw-r-----  owner + group can read
-rw-rw----  owner + group can write

# ❌ WORLD READABLE (644, 664, 666)
-rw-r--r--  anyone can read
-rw-rw-rw-  anyone can write

# 🔒 OVERLY RESTRICTIVE (400)
-r--------  owner can only read (valid for backups)
```

### Detailed Reporting

```bash
# Show detailed analysis
audit-permissions --detailed

# Output includes:
# - File path and current permissions
# - Risk assessment and exposure analysis
# - Specific remediation commands
# - Historical permission changes (if tracked)
```

**Example detailed output:**

```
🔍 Detailed Permission Audit

FILE: ~/.db/oracle/prod
├─ Current: 644 (rw-r--r--)
├─ Required: 600 (rw-------)
├─ Risk: HIGH - Database credentials world-readable
├─ Exposure: All local users can read connection string
├─ Fix: chmod 600 ~/.db/oracle/prod
└─ Impact: 2 other users on system

FILE: ~/.tokens/openai_key
├─ Current: 600 (rw-------)
├─ Status: ✅ SECURE
└─ Verified: Last checked 2025-11-07 14:30:00
```

### Integration Points

**1. Git Hooks:**
```bash
# Pre-commit runs permission check
git commit
# Automatically runs: audit-permissions --quick
```

**2. Health Check:**
```bash
# Included in system health validation
health-check
# Runs: audit-permissions as part of security scan
```

**3. Scheduled Audits:**
```bash
# Weekly cron job (optional setup)
# Add to crontab:
0 9 * * 1 audit-permissions --detailed > ~/audit-$(date +\%Y\%m\%d).log
```

### Bulk Permission Fix

**Automated remediation:**

```bash
# Fix all insecure permissions automatically
audit-permissions --fix

# Confirmation required:
# ⚠️  Found 3 insecure files:
#   ~/.db/oracle/prod (644 → 600)
#   ~/.db/postgres/dev (644 → 600)
#   ~/.tokens/slack_token (640 → 600)
#
# Fix all? [y/N]: y
# ✅ Fixed 3 files
```

**Selective fix:**

```bash
# Fix specific directory
find ~/.db -type f -exec chmod 600 {} \;

# Fix specific pattern
find ~/.tokens -name "*_key" -exec chmod 600 {} \;

# Verify after fix
audit-permissions --verify
```

### Comparison Across Machines

**Export audit report:**

```bash
# Personal Mac
audit-permissions --export > ~/Desktop/personal-audit.json

# Work Mac
audit-permissions --export > ~/Desktop/work-audit.json

# Compare
diff ~/Desktop/personal-audit.json ~/Desktop/work-audit.json
```

**Use cases:**
- Ensure consistent security posture across machines
- Identify personal-only or work-only credential patterns
- Validate migration completeness

### Performance Optimization

**Fast mode for quick checks:**

```bash
# Skip detailed analysis (3x faster)
audit-permissions --quick

# Only check recently modified files
audit-permissions --recent 7d  # Last 7 days

# Check specific directory
audit-permissions ~/.aws
```

### False Positive Handling

**Exclude known-safe files:**

```bash
# Create exclusion file
cat > ~/.audit-permissions-ignore <<EOF
~/.aws/config  # Public AWS config
~/.ssh/known_hosts  # Public SSH hosts
~/.db/readonly_config  # Read-only connection (intentionally 644)
EOF

# Run audit with exclusions
audit-permissions --ignore-file ~/.audit-permissions-ignore
```

---

## Warning System

**Purpose:** Graduated response system balancing security enforcement with developer productivity

### Severity Levels

**1. 🔵 INFO - Informational**

**What:** Best practice recommendations and optimizations

**Action:** No blocking, informational only

**Examples:**
```bash
🔵 INFO: Consider using SSO for AWS authentication
   Current: Static credentials in ~/.aws/credentials
   Better: AWS SSO with temporary credentials
   See: docs/guides/aws-sso.md

🔵 INFO: SSH key could use passphrase protection
   File: ~/.ssh/id_ed25519
   Recommendation: ssh-keygen -p -f ~/.ssh/id_ed25519
```

**When shown:**
- Best practice opportunities
- Performance optimizations
- Security enhancements (not critical)
- Documentation references

**2. ⚠️ WARNING - Security Concern**

**What:** Issues requiring attention but not immediately critical

**Action:** Show warning, allow commit, require acknowledgment

**Examples:**
```bash
⚠️  WARNING: Credential file has group-readable permissions
   File: ~/.db/oracle/prod
   Current: 640 (rw-r-----)
   Required: 600 (rw-------)
   Risk: Group members can read database credentials

   Fix: chmod 600 ~/.db/oracle/prod

   Continue anyway? [y/N]:
```

**When shown:**
- Group-readable credentials (640, 660)
- Outdated encryption methods
- Missing optional security features
- Permission issues in non-critical paths

**3. ❌ ERROR - Critical Security Issue**

**What:** Critical security violations blocking commits

**Action:** Block commit, require fix before proceeding

**Examples:**
```bash
❌ ERROR: BLOCKED - World-readable credentials detected
   File: ~/.aws/credentials
   Current: 644 (rw-r--r--)
   Required: 600 (rw-------)
   Risk: CRITICAL - All local users can read AWS credentials

   Fix: chmod 600 ~/.aws/credentials

   Commit blocked. Fix the issue or use --no-verify (NOT RECOMMENDED)
```

**When shown:**
- World-readable credentials (644+)
- Unencrypted secrets in git
- Critical file permission violations
- Staging blocked credential files

### Severity Classification Matrix

| Issue Type | Permission | Severity | Action |
|------------|------------|----------|--------|
| AWS credentials | 600 | ✅ OK | Allow |
| AWS credentials | 640 | ⚠️ WARNING | Warn + Allow |
| AWS credentials | 644+ | ❌ ERROR | Block |
| Database creds | 600 | ✅ OK | Allow |
| Database creds | 640 | ⚠️ WARNING | Warn + Allow |
| Database creds | 644+ | ❌ ERROR | Block |
| API tokens | 600 | ✅ OK | Allow |
| API tokens | 640 | ⚠️ WARNING | Warn + Allow |
| API tokens | 644+ | ❌ ERROR | Block |
| SSH private key | 600 | ✅ OK | Allow |
| SSH private key | 640+ | ❌ ERROR | Block |
| Unencrypted secret | Any | ❌ ERROR | Block |
| SOPS missing | Any | ❌ ERROR | Block |

### Warning Behavior

**INFO messages:**
```bash
# Shown but don't require interaction
git commit -m "changes"
# 🔵 INFO: 2 optimization suggestions available
# 🔵 Run 'security-recommendations' for details
# ✅ Commit successful
```

**WARNING messages:**
```bash
# Require explicit acknowledgment
git commit -m "changes"
# ⚠️  WARNING: 1 security concern detected
# ⚠️  File: ~/.db/test (640 permissions)
#
# Continue? [y/N]: y
# ⚠️  Acknowledged. Commit proceeding.
# ✅ Commit successful
```

**ERROR messages:**
```bash
# Block until fixed
git commit -m "changes"
# ❌ ERROR: Critical security issue - commit blocked
# ❌ File: ~/.aws/credentials (644 permissions)
#
# Fix: chmod 600 ~/.aws/credentials
# Commit aborted.
```

### Configuration

**Adjust warning thresholds:**

```bash
# Environment variables for customization
export SECURITY_WARNING_LEVEL=strict    # More warnings
export SECURITY_WARNING_LEVEL=normal    # Default
export SECURITY_WARNING_LEVEL=relaxed   # Fewer warnings

# Per-project override
echo "SECURITY_WARNING_LEVEL=strict" > .security-config
```

**Custom severity rules:**

```bash
# Create custom rules file
cat > ~/.security-rules.yaml <<EOF
rules:
  - path: "~/.db/readonly_*"
    max_permission: 644
    severity: info  # Read-only configs can be 644

  - path: "~/.aws/credentials"
    max_permission: 600
    severity: error  # AWS creds must be 600

  - path: "~/.tokens/*"
    max_permission: 640
    severity: warning  # Tokens warn at 640, error at 644+
EOF
```

### Workflow Integration

**1. Pre-commit validation:**
```bash
# Runs automatically on git commit
# Shows INFO/WARNING/ERROR as appropriate
# Blocks on ERROR, allows on WARNING (with confirmation)
```

**2. Manual security check:**
```bash
# Review all current warnings/errors
security-status

# Output:
# 🔍 Security Status
#
# ❌ 1 Error:
#   ~/.aws/credentials (644)
#
# ⚠️  2 Warnings:
#   ~/.db/test (640)
#   ~/.tokens/old_key (640)
#
# 🔵 3 Info:
#   Consider AWS SSO
#   SSH key passphrase recommended
#   Update to age v1.2.0
```

**3. Automated reporting:**
```bash
# Generate security report
security-report --format markdown > ~/Desktop/security-$(date +%Y%m%d).md

# Includes all INFO/WARNING/ERROR items with details
```

### Override Behavior

**Bypass WARNING (confirmation required):**
```bash
# Interactive confirmation
git commit
# ⚠️  WARNING: ...
# Continue? [y/N]: y
```

**Bypass ERROR (not recommended):**
```bash
# Emergency only - requires explicit flag
git commit --no-verify

# Warning shown:
# ⚠️  Security checks bypassed with --no-verify
# ⚠️  Fix issues immediately!
```

**Environment-based override:**
```bash
# Temporarily disable for scripting (use with caution)
export SECURITY_CHECKS_DISABLED=1
git commit -m "automated commit"
unset SECURITY_CHECKS_DISABLED
```

### Best Practices

**Responding to INFO:**
- Review periodically (weekly/monthly)
- Implement when convenient
- Document why not implementing (if skipping)

**Responding to WARNING:**
- Fix during current work session
- Acknowledge only if time-sensitive
- Track and fix within 1 week

**Responding to ERROR:**
- Fix immediately
- Never use `--no-verify` except emergencies
- Investigate root cause (why was file insecure?)

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

## Security Testing

**Purpose:** Automated security validation suite ensuring continuous protection

### Test Suite Overview

**Comprehensive security test coverage:**

```bash
# Run full security test suite
test-security

# Output:
# 🧪 Security Test Suite
#
# ✅ SOPS Encryption Tests (5/5)
#   ✓ Age key exists and valid
#   ✓ All secrets files encrypted
#   ✓ SOPS metadata present
#   ✓ MAC signatures valid
#   ✓ Decryption works
#
# ✅ Permission Tests (8/8)
#   ✓ AWS credentials 600
#   ✓ Database files 600
#   ✓ API tokens 600
#   ✓ SSH private keys 600
#   ✓ No world-readable credentials
#   ✓ No group-readable credentials
#   ✓ Symlink targets secure
#   ✓ Directory permissions correct
#
# ✅ Git Security Tests (6/6)
#   ✓ Pre-commit hook installed
#   ✓ Pre-push hook installed
#   ✓ Hooks executable
#   ✓ No credentials staged
#   ✓ Gitignore patterns correct
#   ✓ No unencrypted secrets in history
#
# ✅ AWS Security Tests (4/4)
#   ✓ Credentials file secure
#   ✓ Config file present
#   ✓ No hardcoded credentials in scripts
#   ✓ SSO configuration valid (work Mac only)
#
# 📊 Results: 23/23 tests passed
# ⏱️  Duration: 2.3 seconds
# ✅ Security posture: EXCELLENT
```

### Individual Test Categories

**1. SOPS Encryption Tests**

```bash
# Run encryption tests only
test-security --category sops

# Tests:
# - Age key exists at ~/.config/sops/age/keys.txt
# - Age key is valid (can decrypt test data)
# - secrets.yaml files are binary (encrypted)
# - SOPS metadata present in encrypted files
# - MAC signatures valid
# - Decryption produces valid YAML
# - No plaintext secrets in encrypted files
```

**2. File Permission Tests**

```bash
# Run permission tests only
test-security --category permissions

# Tests:
# - All credential files have 600 permissions
# - No world-readable files (644+) in protected dirs
# - No group-readable files (640+) in protected dirs
# - SSH private keys are 600
# - Symlinks point to secure targets
# - Parent directories have appropriate permissions
# - No executable credentials (prevent .sh leaks)
```

**3. Git Security Tests**

```bash
# Run git security tests only
test-security --category git

# Tests:
# - Pre-commit hook installed and executable
# - Pre-push hook installed and executable
# - No credential files staged for commit
# - No unencrypted secrets in commit
# - Gitignore patterns cover all credential paths
# - No secrets in git history (recent 100 commits)
# - Hook validation scripts are present
```

**4. AWS Security Tests**

```bash
# Run AWS security tests only
test-security --category aws

# Tests:
# - ~/.aws/credentials has 600 permissions
# - ~/.aws/config exists and configured
# - No AWS_ACCESS_KEY_ID in shell scripts
# - No AWS_SECRET_ACCESS_KEY in shell scripts
# - SSO configuration valid (work Mac)
# - Profile isolation works correctly
# - Session token refresh mechanism works
```

### Continuous Integration

**Run on every rebuild:**

```bash
# Pre-flight checks include security tests
nix-preflight
# Runs: test-security --quick

# Post-rebuild validation
darwin-rebuild switch --flake .
# Automatically runs: test-security --essential
```

**Scheduled testing:**

```bash
# Daily security validation (optional cron)
0 9 * * * test-security --daily-report > ~/security-daily-$(date +\%Y\%m\%d).log

# Weekly comprehensive audit
0 9 * * 1 test-security --comprehensive > ~/security-weekly-$(date +\%Y\%m\%d).log
```

### Test Reporting

**JSON output for automation:**

```bash
# Machine-readable results
test-security --format json > security-results.json

# Example output:
{
  "timestamp": "2025-11-07T14:30:00Z",
  "passed": 23,
  "failed": 0,
  "warnings": 2,
  "duration_seconds": 2.3,
  "categories": {
    "sops": {"passed": 5, "failed": 0},
    "permissions": {"passed": 8, "failed": 0},
    "git": {"passed": 6, "failed": 0},
    "aws": {"passed": 4, "failed": 0}
  },
  "details": [...]
}
```

**HTML report generation:**

```bash
# Generate visual report
test-security --format html > ~/Desktop/security-report.html

# Includes:
# - Pass/fail summary with charts
# - Detailed test results
# - Historical trend analysis
# - Remediation recommendations
```

### Regression Testing

**Test security improvements:**

```bash
# Run before making security changes
test-security --baseline > security-baseline.json

# Make changes (e.g., tighten permissions)
chmod 600 ~/.db/oracle/prod

# Verify improvement
test-security --compare security-baseline.json

# Output:
# 📊 Security Comparison
#
# Improvements:
#   ✅ ~/.db/oracle/prod: 644 → 600 (FIXED)
#
# Regressions:
#   (none)
#
# Overall: 1 improvement, 0 regressions
```

### Performance Testing

**Measure security overhead:**

```bash
# Benchmark security validation performance
test-security --benchmark

# Output:
# ⏱️  Security Performance Benchmark
#
# SOPS encryption check: 0.3s
# Permission scan (243 files): 0.8s
# Git hook validation: 0.2s
# AWS security check: 0.4s
#
# Total: 2.3s (within 5s target ✅)
```

### Failure Analysis

**When tests fail:**

```bash
# Run with detailed diagnostics
test-security --verbose

# Example failure:
❌ FAILED: Permission test for ~/.aws/credentials
   Expected: 600 (rw-------)
   Actual: 644 (rw-r--r--)
   Risk: World-readable AWS credentials
   Impact: All local users can read credentials
   Remediation: chmod 600 ~/.aws/credentials
   Documentation: docs/guides/security.md#file-permissions
   Related: AWS-001, SEC-003
```

**Failure categories:**

```bash
# List all failures with details
test-security --failures-only

# Group by severity
test-security --failures-only --group-by-severity

# Export failures for tracking
test-security --failures-only --format csv > failures.csv
```

### Test Development

**Add custom security tests:**

```bash
# Create custom test file
cat > ~/.config/security-tests/custom.sh <<'EOF'
#!/usr/bin/env bash

# Test: No hardcoded tokens in Python files
test_no_hardcoded_tokens() {
  if grep -r "api_key\s*=\s*['\"]" ~/Dev --include="*.py"; then
    echo "❌ FAILED: Hardcoded API keys in Python files"
    return 1
  fi
  echo "✅ PASSED: No hardcoded tokens"
  return 0
}

# Run test
test_no_hardcoded_tokens
EOF

# Run custom tests
test-security --include-custom ~/.config/security-tests/
```

### Integration with CI/CD

**GitHub Actions example:**

```yaml
# .github/workflows/security.yml
name: Security Tests

on: [push, pull_request]

jobs:
  security:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security tests
        run: |
          ./scripts/test-security.sh --ci
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: security-results
          path: security-results.json
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

## AWS Security

**Purpose:** Multi-role AWS security with session isolation and role-based access control

### Multi-Role Architecture

**Security model:**

```
Personal Mac (mbp-jimmy):
├─ Single role: personal
├─ Static credentials only
└─ No cross-account access

Work Mac (mbp-work):
├─ Multiple roles with isolation
├─ SSO-based authentication
├─ Temporary session tokens
└─ Role-based access control
```

### Personal Mac AWS Security

**Simple, single-profile security:**

```bash
# Configuration
AWS_PROFILE=personal  # Always set
AWS_REGION=us-east-1

# Credentials location
~/.aws/credentials  # Encrypted with SOPS
~/.aws/config       # Plain text (public config)

# Security controls
# - 600 permissions on credentials file
# - SOPS encryption at rest
# - No cross-account access
# - No temporary credentials
```

**Best practices:**

```bash
# ✅ Use named profile explicitly
export AWS_PROFILE=personal
aws s3 ls

# ❌ Don't rely on default profile
aws s3 ls  # May use wrong credentials

# ✅ Rotate credentials quarterly
edit-secrets  # Update AWS section
nix-rebuild

# ✅ Use least-privilege IAM policies
# Ensure personal IAM user has minimal required permissions
```

### Work Mac AWS Security

**Multi-role security with isolation:**

**Role structure:**

```bash
# Available roles (example)
AWS_PROFILES=(
  "work-domain"           # Default work role
  "work-admin"            # Administrative access
  "work-readonly"         # Read-only access
  "work-dev"              # Development environment
  "work-prod"             # Production environment
)

# Current role detection
awswho
# Output:
# 🔐 Current AWS Context:
#   Profile: work-domain
#   Account: 123456789012
#   User: first.last@work-domain.com
#   Session: Active (2h 45m remaining)
#   Permissions: Standard
```

**Session management:**

```bash
# Authenticate with SSO
awslogin
# Output:
# 🔐 AWS SSO Login
#   Profile: work-domain
#   SSO URL: https://work.awsapps.com/start
#   Browser opening...
#   ✅ Authentication successful
#   ⏰ Session expires: 2025-11-07 23:30:00

# Check session status
awsstatus
# Output:
# ⏰ Session Status:
#   Active: Yes
#   Expires: 2h 45m
#   Refresh: Available

# Refresh expiring session
awsrefresh
# Automatically refreshes if <30m remaining
```

**Role switching:**

```bash
# Switch to admin role (requires re-authentication)
export AWS_PROFILE=work-admin
awslogin

# Verification
awswho
# Shows: Profile: work-admin

# Return to default role
export AWS_PROFILE=work-domain
```

### Security Boundaries

**1. Profile Isolation**

```bash
# Each profile has separate:
# - Credentials/session tokens
# - Permission boundaries
# - Resource access scope
# - Audit trail

# Profiles cannot cross-contaminate
export AWS_PROFILE=work-readonly
aws s3 rm s3://prod-bucket/file  # ❌ DENIED (readonly role)

export AWS_PROFILE=work-admin
aws s3 rm s3://prod-bucket/file  # ✅ ALLOWED (admin role)
```

**2. Session Token Security**

```bash
# Temporary credentials stored securely
~/.aws/sso/cache/  # Session tokens (600 permissions)

# Tokens automatically expire
# - Default: 8 hours
# - Maximum: 12 hours
# - Re-authentication required after expiry

# Token validation on every command
aws sts get-caller-identity  # Auto-validates token freshness
```

**3. Permission Boundaries**

```bash
# IAM permission boundaries enforce least privilege
# Example: work-dev profile
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::dev-*/*",
  "Condition": {
    "StringEquals": {
      "aws:RequestedRegion": ["us-east-1"]
    }
  }
}

# Prevents:
# - Access to prod resources
# - Cross-region actions
# - Destructive operations
```

**4. Audit Trail**

```bash
# All AWS actions logged via CloudTrail
# Review recent actions
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=$(whoami) \
  --max-results 20

# Check for unauthorized access
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%S) \
  --max-results 50
```

### Credential Security

**Static credentials (personal Mac):**

```bash
# Encrypted with SOPS
edit-secrets
# Add/update AWS section:
aws:
  access_key_id: "AKIAIOSFODNN7EXAMPLE"
  secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# Decrypted to ~/.zsh_secrets at rebuild
nix-rebuild
# Sets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

# Verified at shell startup
# ✅ AWS credentials loaded from SOPS
```

**SSO credentials (work Mac):**

```bash
# SSO configuration in ~/.aws/config
[profile work-domain]
sso_start_url = https://work.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = DeveloperAccess

# Authentication flow
awslogin
# 1. Opens browser for SSO authentication
# 2. Retrieves temporary credentials
# 3. Stores in ~/.aws/sso/cache/
# 4. Credentials auto-expire after 8h

# No long-lived credentials stored
# ✅ More secure than static keys
```

### Security Validation

**AWS security checks:**

```bash
# Comprehensive AWS security audit
test-security --category aws

# Checks:
# ✓ Credentials file permissions (600)
# ✓ Config file exists
# ✓ No hardcoded credentials in scripts
# ✓ SSO configuration valid
# ✓ Session tokens not expired
# ✓ Profile isolation working
# ✓ Audit trail accessible
```

**Manual validation:**

```bash
# 1. Verify credentials secure
ls -la ~/.aws/credentials
# Should show: -rw------- (600)

# 2. Check SSO session status (work Mac)
awsstatus
# Should show: Active session with expiry time

# 3. Verify profile isolation
export AWS_PROFILE=work-readonly
aws s3 rm s3://test  # Should fail (readonly)

export AWS_PROFILE=work-admin
aws s3 rm s3://test  # Should succeed (admin)

# 4. Audit recent actions
aws cloudtrail lookup-events --max-results 10
```

### Incident Response

**Compromised AWS credentials:**

```bash
# 1. IMMEDIATE - Disable credentials in AWS Console
# For static keys:
aws iam update-access-key \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --status Inactive \
  --user-name your-username

# For SSO sessions:
# Revoke all sessions in AWS SSO console

# 2. Generate new credentials
aws iam create-access-key --user-name your-username

# 3. Update secrets
edit-secrets
# Replace old credentials with new

# 4. Rebuild
nix-rebuild

# 5. Verify new credentials
aws sts get-caller-identity

# 6. Delete old credentials
aws iam delete-access-key \
  --access-key-id AKIAIOSFODNN7EXAMPLE \
  --user-name your-username

# 7. Audit for unauthorized usage
aws cloudtrail lookup-events \
  --start-time $(date -u -v-7d +%Y-%m-%dT%H:%M:%S) \
  --max-results 100
```

**Session hijacking (work Mac):**

```bash
# 1. Immediately revoke all SSO sessions
# AWS SSO Console → Active Sessions → Revoke All

# 2. Clear local session cache
rm -rf ~/.aws/sso/cache/*

# 3. Re-authenticate
awslogin

# 4. Verify new session
awswho

# 5. Review CloudTrail for suspicious activity
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole
```

### Best Practices Summary

**Personal Mac:**
- ✅ Use SOPS-encrypted credentials
- ✅ Set 600 permissions on ~/.aws/credentials
- ✅ Explicitly use `AWS_PROFILE=personal`
- ✅ Rotate credentials quarterly
- ❌ Don't share credentials across machines
- ❌ Don't commit credentials to git

**Work Mac:**
- ✅ Use AWS SSO (not static credentials)
- ✅ Authenticate via `awslogin` before work
- ✅ Verify active session with `awsstatus`
- ✅ Use appropriate role for each task
- ✅ Review `awswho` before destructive operations
- ❌ Don't use static credentials
- ❌ Don't share session tokens
- ❌ Don't bypass role boundaries

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

## Defense-in-Depth Strategy

**Purpose:** Multiple independent security layers ensuring comprehensive protection

### Security Layer Architecture

**7-layer defense model:**

```
┌──────────────────────────────────────────────┐
│ Layer 7: Monitoring & Audit                 │  ← Continuous validation
│  - Permission audits                         │
│  - Security testing                          │
│  - CloudTrail logging                        │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 6: Warning System                     │  ← Graduated responses
│  - 3-level severity (INFO/WARNING/ERROR)    │
│  - Context-aware messaging                   │
│  - User acknowledgment tracking              │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 5: Automation                         │  ← Prevent human error
│  - Git hooks                                 │
│  - Pre-flight checks                         │
│  - Automated validation                      │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 4: Access Control                     │  ← Limit exposure
│  - File permissions (600)                    │
│  - Role-based AWS access                     │
│  - Session token isolation                   │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 3: Encryption                         │  ← Protect at rest
│  - SOPS age encryption                       │
│  - SSH key passphrases                       │
│  - FileVault disk encryption                 │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 2: Isolation                          │  ← Separate concerns
│  - Gitignore patterns                        │
│  - Directory separation                      │
│  - Profile isolation (AWS)                   │
└──────────────────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Layer 1: Secret Registry                    │  ← Centralized control
│  - Defined credential paths                 │
│  - Validation rules                          │
│  - Documentation                             │
└──────────────────────────────────────────────┘
```

### Layer Interactions

**Example: Protecting AWS Credentials**

1. **Secret Registry** - Defines `~/.aws/credentials` as protected
2. **Isolation** - Gitignore prevents accidental git tracking
3. **Encryption** - SOPS encrypts credentials in secrets.yaml
4. **Access Control** - 600 permissions limit to owner only
5. **Automation** - Git hooks validate permissions on commit
6. **Warning System** - Graduated alerts for permission violations
7. **Monitoring** - Permission audits detect drift

**Failure mode analysis:**

```bash
# Scenario: User creates ~/.aws/credentials with 644 permissions

Layer 1 (Registry):      ✅ Recognizes as protected path
Layer 2 (Isolation):     ✅ Gitignore prevents staging
Layer 3 (Encryption):    ⚠️  Not triggered (not in secrets.yaml)
Layer 4 (Access):        ❌ FAILED - File is 644 (world-readable)
Layer 5 (Automation):    ✅ Pre-commit hook detects violation
Layer 6 (Warning):       ❌ ERROR - Blocks commit
Layer 7 (Monitoring):    ✅ audit-permissions reports issue

Result: ✅ Breach prevented by Layers 5 & 6
```

### Redundancy Strategy

**Overlapping protections:**

| Threat | Primary Defense | Secondary Defense | Tertiary Defense |
|--------|----------------|-------------------|------------------|
| Secret in git | Gitignore | Pre-commit hook | Pre-push hook |
| Insecure permissions | Git hook validation | Permission audits | Manual review |
| Unencrypted secrets | SOPS encryption | Hook validation | Testing suite |
| Hardcoded credentials | Code review | Grep scanning | Security tests |
| Credential leakage | Access control | Audit logging | Incident response |

**Redundancy benefits:**
- No single point of failure
- Multiple chances to catch issues
- Graceful degradation if layer fails

### Security Validation Points

**Pre-commit (Layer 5):**
```bash
git commit
# ↓
# 1. Check permissions (Layer 4)
# 2. Verify encryption (Layer 3)
# 3. Validate gitignore (Layer 2)
# 4. Check registry compliance (Layer 1)
# 5. Apply warning system (Layer 6)
# ↓
# Commit allowed/blocked
```

**Daily operations (Layer 7):**
```bash
# Morning routine
awslogin              # Authenticate (Layer 4)
audit-permissions     # Scan state (Layer 7)
test-security --quick # Validate posture (Layer 7)

# Work session
# All operations protected by multiple layers

# End of day
security-status       # Review warnings (Layer 6)
```

**System rebuild (All layers):**
```bash
nix-rebuild
# ↓
# Pre-flight checks:
# - Layer 1: Registry validation
# - Layer 2: Gitignore patterns
# - Layer 3: Encryption status
# - Layer 4: Permission audit
# - Layer 5: Hook installation
# - Layer 6: Warning configuration
# - Layer 7: Monitoring setup
# ↓
# Post-rebuild validation:
# - Test all layers functional
# - Verify no regressions
```

### Layer Maintenance

**Layer 1 (Registry):**
```bash
# Update when adding new credential types
# Edit: lib/secrets.nix
secretPaths = [
  "\${HOME}/.aws/credentials"
  "\${HOME}/.db/*"
  # Add new paths here
];
```

**Layer 2 (Isolation):**
```bash
# Update .gitignore for new credential directories
echo "~/.newcredentials/" >> .gitignore
```

**Layer 3 (Encryption):**
```bash
# Rotate age key annually
age-keygen -o ~/.config/sops/age/keys-new.txt
sops updatekeys hosts/*/secrets.yaml
```

**Layer 4 (Access Control):**
```bash
# Regular permission audits
audit-permissions --comprehensive
```

**Layer 5 (Automation):**
```bash
# Verify hooks after git updates
test -x .git/hooks/pre-commit || echo "❌ Hook not executable"
```

**Layer 6 (Warning System):**
```bash
# Review and adjust severity thresholds
security-status --show-thresholds
```

**Layer 7 (Monitoring):**
```bash
# Weekly comprehensive audit
test-security --comprehensive
```

### Attack Surface Reduction

**Minimizing exposure:**

```bash
# 1. Credential isolation (Layer 2)
~/.aws/        # AWS only
~/.db/         # Databases only
~/.tokens/     # API tokens only
# ✅ Breach of one doesn't expose others

# 2. Time-limited credentials (Layer 4)
# SSO sessions expire after 8h
# ✅ Stolen tokens have limited validity

# 3. Least-privilege profiles (Layer 4)
# work-readonly can't modify resources
# ✅ Compromised readonly access limited

# 4. Permission enforcement (Layer 4)
# All credentials 600 (owner-only)
# ✅ Other users can't read files

# 5. Encryption at rest (Layer 3)
# SOPS age encryption
# ✅ File access doesn't expose secrets

# 6. Audit trail (Layer 7)
# CloudTrail logs all actions
# ✅ Unauthorized access detected
```

### Recovery Procedures

**Layer failure scenarios:**

**1. Layer 5 failure (Git hooks disabled):**
```bash
# Backup: Layer 6 (Warning system) still active
# Backup: Layer 7 (Manual audits) catch drift

# Recovery:
git config --unset core.hooksPath  # Clear override
nix-rebuild  # Reinstall hooks
test-security --category git  # Verify
```

**2. Layer 4 failure (Permissions drift):**
```bash
# Backup: Layer 7 (Audits) detect insecure files
# Backup: Layer 5 (Git hooks) block commits

# Recovery:
audit-permissions --fix  # Automated fix
test-security --category permissions  # Verify
```

**3. Layer 3 failure (Unencrypted secrets):**
```bash
# Backup: Layer 5 (Git hooks) block commits
# Backup: Layer 7 (Testing) detects issue

# Recovery:
sops -e -i hosts/*/secrets.yaml  # Re-encrypt
test-security --category sops  # Verify
```

**4. Multiple layer failure:**
```bash
# Defense-in-depth ensures breach unlikely
# Even with 3 layers failed, 4 remain

# Recovery priority:
# 1. Layer 3 (Encryption) - Highest priority
# 2. Layer 4 (Access Control) - High priority
# 3. Layer 5 (Automation) - Medium priority
# 4. Layers 1,2,6,7 - Lower priority (detection/monitoring)
```

### Continuous Improvement

**Security evolution:**

```bash
# Phase 1 (Initial): Layers 1-3
# - Secret registry
# - Gitignore isolation
# - SOPS encryption

# Phase 2 (Enhanced): Added Layer 4
# - File permissions
# - Access control

# Phase 3 (Automated): Added Layer 5
# - Git hooks
# - Pre-flight checks

# Phase 4 (Current): Added Layers 6-7
# - Warning system
# - Permission audits
# - Security testing

# Phase 5 (Future): Enhanced monitoring
# - Automated anomaly detection
# - Real-time alerting
# - Security metrics dashboard
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