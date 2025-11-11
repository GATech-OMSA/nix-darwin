# System Health Check

The health check script provides comprehensive validation of your nix-darwin system state across multiple categories with scoring and recommendations.

## Quick Start

```bash
# Run health check (normal mode)
health-check

# Run with detailed output
health-check --verbose

# Or use alternative alias
system-health
```

## What It Checks

### 1. Nix Daemon & Core
- ✓ Nix daemon running
- ✓ Nix command available
- ✓ Nix store accessible
- ✓ Flake lock file exists

### 2. Darwin System
- ✓ darwin-rebuild command available
- ✓ System activation status
- ✓ LaunchD services running
- ✓ System generations available

### 3. Home Manager
- ✓ Home Manager profile activated
- ✓ Config files properly linked (.zshrc, git config, starship.toml)
- ✓ Generations directory exists

### 4. Shell Configuration
- ✓ Current shell is zsh
- ✓ .zshrc exists and is managed
- ✓ Critical aliases available (nix-rebuild, etc.)
- ✓ Starship prompt installed
- ✓ Oh-My-Zsh status (optional)

### 5. Git Configuration
- ✓ Git command available
- ✓ Git config exists
- ✓ Git hooks installed (pre-commit, pre-push)
- ✓ Git user configured

### 6. Secrets & Encryption
- ✓ SOPS command available
- ✓ SOPS age key exists with secure permissions
- ✓ All secrets files encrypted
- ✓ Credential file permissions (600)

### 7. Critical Packages
- ✓ Essential packages installed (git, curl, jq, vim, zsh)
- ✓ Package managers available (Nix, Homebrew)

### 8. Repository State
- ✓ Git repository initialized
- ✓ Current branch
- ✓ Working directory status
- ✓ Git remote configured

## Health Scores

The script calculates a health percentage and status:

| Score | Status | Emoji |
|-------|--------|-------|
| 90%+ | HEALTHY | 🟢 |
| 80-89% | FAIR | 🟡 |
| 60-79% | NEEDS ATTENTION | 🟡 |
| <60% | CRITICAL | 🔴 |

Status is also downgraded based on:
- **>5 failed checks** → CRITICAL
- **>2 failed checks** → NEEDS ATTENTION
- **>3 warnings** → FAIR

## Sample Output

### Normal Mode
```
🏥 NIX-DARWIN SYSTEM HEALTH CHECK

▶ NIX DAEMON & CORE
  ✓ Nix daemon is running
  ✓ Nix command available
  ✓ Nix store accessible
  ✓ Flake lock file exists

▶ DARWIN SYSTEM
  ✓ darwin-rebuild command available
  ✓ System is activated
  ⚠ No LaunchD services detected
  ✓ System generations available

...

📊 HEALTH REPORT

Total Checks: 31
✓ Passed:     27
✗ Failed:     0
⚠ Warnings:   4

Health Score: 87% (27/31 checks passed)
Status:       🟡 FAIR

Recommendations:
  • Review warnings (marked with ⚠) for potential issues
  • Run with --verbose flag for detailed information
```

### Verbose Mode
```
▶ NIX DAEMON & CORE
  ✓ Nix daemon is running
  ✓ Nix command available
    → nix (Nix) 2.31.2
  ✓ Nix store accessible
    → Size: 7.5G
  ✓ Flake lock file exists
    → Last updated: 2025-11-06 16:35

▶ CRITICAL PACKAGES
  ✓ Git version control (git)
  ✓ HTTP client (curl)
  ✓ JSON processor (jq)
  ✓ Text editor (vim)
  ✓ Z shell (zsh)
  ✓ Package managers available
    → Nix + Homebrew
```

## Usage Scenarios

### After System Rebuild
```bash
nix-rebuild
health-check
```

Validates that rebuild succeeded and system is healthy.

### Troubleshooting
```bash
health-check --verbose
```

Detailed output helps diagnose issues:
- Which configs are missing
- Service status
- Permission problems
- Package availability

### Regular Maintenance
```bash
# Monthly health check
health-check

# If warnings/failures found
health-check --verbose
# Review specific issues and fix
```

### Pre-Push Validation
```bash
# Before committing system changes
health-check
git add .
git commit -m "Update config"
```

## Common Issues

### Warning: nix-rebuild alias not found
**Cause**: Shell hasn't loaded new config after rebuild
**Fix**:
```bash
exec zsh
health-check
```

### Warning: Credential file permissions insecure
**Cause**: Credential files not 600
**Fix**:
```bash
# Check which files
ls -la ~/.aws/credentials ~/.ssh/id_*

# Fix permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.ssh/id_ed25519*
```

### Warning: Oh-My-Zsh not installed
**Cause**: Optional component not installed
**Fix** (optional):
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Failed: Git user not configured
**Cause**: Git user.name or user.email missing
**Fix**:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Failed: System not activated
**Cause**: darwin-rebuild hasn't been run
**Fix**:
```bash
nix-rebuild
```

## Exit Codes

- **0**: All checks passed (or only warnings)
- **1**: One or more checks failed

Use in scripts:
```bash
if health-check; then
  echo "System healthy!"
else
  echo "System has issues, run: health-check --verbose"
  exit 1
fi
```

## Performance Notes

### Fast Operations
- Most checks complete in <2 seconds
- Normal mode prioritizes speed

### Slow Operations (verbose only)
- **Nix store size calculation** (`du -sh /nix/store`)
  - Skipped in normal mode
  - Shown in verbose mode (~3-5 seconds)

## Integration

### In Scripts
```bash
#!/bin/bash
# Example: Pre-deployment validation

echo "Validating system health..."
if ! health-check; then
  echo "ERROR: System not healthy"
  exit 1
fi

echo "Deploying..."
# deployment commands
```

### In CI/CD
```yaml
# Example GitHub Actions workflow
- name: Health Check
  run: |
    nix-darwin/scripts/health-check.sh --verbose
```

### With Other Tools
```bash
# With update workflow
update-all
health-check

# With rollback
nix-rollback
health-check --verbose
```

## Customization

The script is located at:
```
scripts/health-check.sh
```

You can customize:
- Check categories
- Critical packages list
- Health score thresholds
- Warning vs error classification

## Related Commands

| Command | Purpose |
|---------|---------|
| `nix-check` | Check flake configuration validity |
| `nix-preflight` | Run pre-flight checks before rebuild |
| `nix-rebuild` | Rebuild system (includes pre-flight) |
| `health-check` | Validate system state after rebuild |
| `nix-rebuild-debug` | Rebuild with verbose output |

## See Also

- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Usage Guide](usage.md) - Daily usage patterns
- [Backup & Recovery](backup-and-recovery.md) - Rollback procedures
