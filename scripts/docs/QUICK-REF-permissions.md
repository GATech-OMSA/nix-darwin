# Permission Audit Quick Reference

**Script**: `scripts/audit-permissions.sh`
**Registry**: `lib/secrets-registry.nix` (42 paths)

## Common Commands

```bash
# Quick audit (recommended daily)
./scripts/audit-permissions.sh

# Auto-fix all insecure permissions
./scripts/audit-permissions.sh --fix

# Detailed audit with all files shown
./scripts/audit-permissions.sh --verbose --show-secure

# Combined options
./scripts/audit-permissions.sh -f -v -s

# Run as part of health check
./scripts/health-check.sh
./scripts/health-check.sh --verbose  # Show full audit
```

## Options Quick Reference

| Flag | Short | Purpose |
|------|-------|---------|
| `--fix` | `-f` | Auto-fix insecure permissions to 600 |
| `--verbose` | `-v` | Show all files (including missing) |
| `--show-secure` | `-s` | Show secure files (normally hidden) |
| `--help` | `-h` | Show help message |

## File Categories (42 total)

| Category | Count | Example |
|----------|-------|---------|
| AWS | 4 | `~/.aws/credentials` |
| Database | 24 | `~/.db/oracle/prod` |
| SSH | 5 | `~/.ssh/id_ed25519` |
| Tokens | 4 | `~/.tokens/git_token` |
| Credentials | 2 | `~/.credentials/servicenow` |
| Secrets | 2 | `~/.secrets/credentials.env` |
| SOPS | 1 | `~/.config/sops/age/keys.txt` |

## Security Scores

| Score | Status | Action |
|-------|--------|--------|
| 100% | 🟢 SECURE | ✅ No action needed |
| 80-99% | 🟡 FAIR | Review and fix |
| 60-79% | 🟡 NEEDS ATTENTION | Fix immediately |
| <60% | 🔴 CRITICAL | Emergency fix |

## Output Indicators

| Symbol | Meaning | Color |
|--------|---------|-------|
| ✓ | Secure (600) | Green |
| ✗ | Insecure (not 600) | Red |
| ○ | Missing file | Yellow |
| 🔧 | Fixed | Cyan |

## Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 0 | All secure | CI/CD pass |
| 1 | Issues found | CI/CD fail |

## Workflow Examples

### Daily Security Check
```bash
# Option 1: Standalone audit
./scripts/audit-permissions.sh

# Option 2: Full health check (includes audit)
./scripts/health-check.sh
```

### Fix Insecure Permissions
```bash
# Automated (recommended)
./scripts/audit-permissions.sh --fix

# Manual (if needed)
chmod 600 ~/.aws/credentials
chmod 600 ~/.ssh/id_ed25519
```

### After Adding New Credentials
```bash
# 1. Add path to registry
vim lib/secrets-registry.nix

# 2. Rebuild system
nix-rebuild

# 3. Run audit
./scripts/audit-permissions.sh

# 4. Fix if needed
./scripts/audit-permissions.sh --fix
```

### CI/CD Integration
```bash
# Fail build if insecure permissions
./scripts/audit-permissions.sh || exit 1

# Generate audit report
./scripts/audit-permissions.sh > security-audit-$(date +%Y%m%d).log
```

## Required Permissions

**All credential files must be 600:**
- Owner: Read + Write
- Group: No access
- Others: No access

```bash
# Correct
-rw-------  1 jimmy  staff  credentials

# Incorrect (too permissive)
-rw-r--r--  1 jimmy  staff  credentials  # ❌ 644
-rwxr-xr-x  1 jimmy  staff  credentials  # ❌ 755
```

## Troubleshooting

### Operation Not Permitted
```bash
# Check for protected files
ls -lO ~/.aws/config

# Remove immutable flag
sudo chflags nouchg ~/.aws/config
chmod 600 ~/.aws/config
```

### Missing Files Normal?
Yes! Registry includes all possible paths:
- Personal Mac: No work credentials
- Work Mac: No personal credentials
- Missing files don't affect security score

### False Positives?
Public keys (`.pub`) technically safe with 644, but we enforce 600 for:
- Consistency across all credential files
- Defense-in-depth security
- Simpler permission model

## Integration Points

**Git Hooks**: Pre-commit/pre-push validate permissions
**Health Check**: Automatic audit during health checks
**Registry**: Single source of truth for all paths
**CI/CD**: Exit codes enable automated enforcement

## Help & Documentation

```bash
# Quick help
./scripts/audit-permissions.sh --help

# Full documentation
cat scripts/README-audit-permissions.md

# Implementation details
cat claudedocs/TASK-4.6-SUMMARY.md
```

## Defense-in-Depth Layers

| Layer | Tool | Purpose |
|-------|------|---------|
| Prevention | Git hooks | Block insecure commits |
| Detection | audit script | Find permission issues |
| Remediation | `--fix` flag | Auto-restore security |
| Validation | health check | Ongoing compliance |
| Registry | secrets-registry.nix | Centralized truth |

---

**Quick Start**: `./scripts/audit-permissions.sh --fix`
**Documentation**: `scripts/README-audit-permissions.md`
**Support**: Check health-check.sh integration for automated monitoring
