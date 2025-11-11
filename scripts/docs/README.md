# Scripts Directory

Utility scripts for nix-darwin system maintenance, validation, and testing.

## System Management

### pre-flight-checks.sh
**Purpose**: Validates system health before darwin-rebuild to prevent common failures

**Usage**:
```bash
./scripts/pre-flight-checks.sh              # Run all checks
./scripts/pre-flight-checks.sh --quiet      # Minimal output
./scripts/pre-flight-checks.sh --warnings-only  # Only warnings/errors
```

**Integrated Aliases**:
- `nix-rebuild` - Runs with pre-flight checks (default)
- `nix-rebuild-skip-checks` - Skip checks (emergency use)
- `nix-preflight` - Run checks without rebuilding

**Checks**:
1. Disk space (>5GB free)
2. Git status (uncommitted changes warning)
3. Nix daemon running
4. No active rebuild processes
5. Valid flake.nix syntax
6. Nix store integrity
7. Network connectivity
8. System load
9. Required files present
10. Secrets encryption (SOPS binary format)

**Exit Codes**:
- `0` - All checks passed
- `1` - Critical failures (rebuild blocked)
- `2` - Warnings only (proceed with caution)

### health-check.sh
**Purpose**: Comprehensive system health diagnostics

**Usage**:
```bash
./scripts/health-check.sh
```

## Security & Secrets

### check-secrets-encrypted.sh
**Purpose**: Validates that secrets files are SOPS encrypted (binary format)

**Usage**:
```bash
./scripts/check-secrets-encrypted.sh
```

**Called by**: Git pre-commit and pre-push hooks

### validate-secret-registry.sh
**Purpose**: Validates secret registry configuration and SOPS setup

**Usage**:
```bash
./scripts/validate-secret-registry.sh
```

## Documentation

### check-doc-links.py
**Purpose**: Validates markdown links in documentation files

**Usage**:
```bash
python3 scripts/check-doc-links.py
```

### count-docs.sh
**Purpose**: Count documentation files and generate statistics

**Usage**:
```bash
./scripts/count-docs.sh
```

### validate-docs.sh
**Purpose**: Comprehensive documentation validation

**Usage**:
```bash
./scripts/validate-docs.sh
```

## Configuration Validation

### validate-aws-config.sh
**Purpose**: Validates AWS configuration for multi-role setup

**Usage**:
```bash
./scripts/validate-aws-config.sh
```

### validate-package-separation.sh
**Purpose**: Ensures packages are properly separated between Nix and Homebrew

**Usage**:
```bash
./scripts/validate-package-separation.sh
```

## Testing

### test-aws-helpers.sh
**Purpose**: Tests AWS helper functions from lib/aws.nix

**Usage**:
```bash
./scripts/test-aws-helpers.sh
```

### test-git-hooks.sh
**Purpose**: Tests git hooks for credential protection and secrets validation

**Usage**:
```bash
./scripts/test-git-hooks.sh
```

## Setup & Installation

### install-zsh-plugins.sh
**Purpose**: Installs custom Oh-My-Zsh plugins

**Usage**:
```bash
./scripts/install-zsh-plugins.sh
```

**Installs**:
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- you-should-use
- zsh-history-substring-search

## Script Development Guidelines

When creating new scripts:

1. **Shebang**: Use `#!/usr/bin/env bash`
2. **Strict Mode**: Include `set -euo pipefail`
3. **Documentation**: Add comprehensive header comments
4. **Exit Codes**: Follow standard conventions (0=success, 1=error)
5. **Colors**: Use color codes for visual feedback
6. **Permissions**: Make executable with `chmod +x`
7. **Testing**: Test all modes and edge cases

## Common Patterns

### Color Codes
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color
```

### Exit Code Handling
```bash
exit_code=0
# Run checks
if ! some_check; then
  exit_code=1
fi
exit $exit_code
```

### Quiet Mode
```bash
QUIET_MODE=false
if [[ "$QUIET_MODE" == "false" ]]; then
  echo "Verbose output"
fi
```

## Maintenance

- All scripts should be kept in sync with system changes
- Update documentation when adding new scripts
- Remove deprecated scripts and update references
- Test scripts after major system changes

## See Also

- [Architecture Reference](../docs/architecture/reference.md) - File structure
- [Troubleshooting Guide](../docs/guides/troubleshooting.md) - Common issues
- [Usage Guide](../docs/guides/usage.md) - Daily workflows
