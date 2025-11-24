# ADR-005: Validation and Testing Systems

**Status**: Accepted
**Date**: 2024-11-07 (Consolidated 2024-11-10)
**Author**: System Architecture

**Note**: This ADR consolidates ADR-005 (Health Check), ADR-006 (Test Framework), ADR-007 (Warning System), and ADR-008 (Permission Audit) into a unified validation and testing architecture.

---

## Context

nix-darwin configuration requires comprehensive validation and testing infrastructure to ensure system reliability and catch failures early. The system needs multiple validation layers:

1. **Health Checks**: Detect silent failures and system misconfigurations
2. **Testing Framework**: Validate configurations before deployment
3. **Warning System**: Handle non-critical issues without blocking builds
4. **Permission Audit**: Ensure credential files maintain secure permissions

### Requirements

- **Early Detection**: Catch issues before they cause failures
- **Clear Diagnostics**: Provide actionable error messages
- **Non-Blocking Warnings**: Advisory messages for non-critical issues
- **Automated Validation**: Git hooks and pre-flight checks
- **Multi-Layer Testing**: Unit, integration, and system tests

---

## Decision

Implement a **four-layer validation and testing architecture**:

### Layer 1: Health Check System

**Purpose**: System diagnostics and runtime validation

**Implementation**:
```bash
health-check  # Validates Nix, packages, paths, configs, secrets
```

**Checks**:
- Nix daemon status
- Critical package availability
- PATH configuration
- Config file existence
- Secret encryption status
- Git repository state

**Exit Codes**:
- `0` - All checks passed
- `1` - Critical failure (system unusable)
- `2` - Warning (system usable, attention needed)

### Layer 2: Test Framework

**Purpose**: Pre-deployment configuration validation

**Test Hierarchy**:

**Unit Tests** (Individual component validation):
- Single function behavior
- Isolated configuration logic
- Helper function correctness
- Example: `myLib.selectByMachine` behavior

**Integration Tests** (Component interaction):
- Module combinations
- Profile loading
- Secret decryption
- Example: Personal profile + SOPS integration

**System Tests** (End-to-end validation):
- Full system build
- Activation validation
- Cross-component functionality
- Example: Complete rebuild succeeds

**Implementation**:
```bash
./tests/run-all-tests.sh       # All tests
./tests/unit/test-lib.sh       # Unit tests only
./tests/integration/           # Integration tests
./tests/system/                # System tests
```

### Layer 3: Warning System

**Purpose**: Handle non-critical issues without blocking operations

**Design Philosophy**:
- **Binary for critical**: SOPS encryption, missing dependencies (fail immediately)
- **Advisory for non-critical**: File permissions, outdated packages (warn and continue)

**Warning Categories**:

| Category | Severity | Action |
|----------|----------|--------|
| Security | HIGH | Warn, log, continue |
| Permissions | MEDIUM | Warn, provide fix command |
| Performance | LOW | Inform, suggest optimization |
| Deprecation | LOW | Inform about future changes |

**Implementation**:
```nix
# lib/warnings.nix
mkWarning = level: message: action:
  builtins.trace "[${level}] ${message}" action;
```

### Layer 4: Permission Audit Automation

**Purpose**: Ensure secure file permissions on credentials

**Protected Patterns**:
- `~/.db/*` - Database connection files
- `~/.tokens/*` - API tokens
- `~/.aws/credentials` - AWS credentials
- `~/.ssh/id_*` - SSH private keys

**Validation Points**:

**Git Pre-Commit Hook**:
```bash
# Checks before commit:
# 1. SOPS secrets are encrypted (binary check)
# 2. No credential files in staging
# 3. Credential files have 600 permissions (warning if wrong)
```

**System Health Check**:
```bash
health-check  # Validates permissions, warns if incorrect
```

**Auto-Fix Script**:
```bash
fix-permissions  # chmod 600 all credential files
```

---

## Consequences

### Positive

✅ **Early Detection**: Issues caught before system failures
✅ **Clear Diagnostics**: Health check pinpoints problems
✅ **Flexible Validation**: Warnings don't block non-critical issues
✅ **Automated Security**: Git hooks prevent credential leaks
✅ **Multi-Layer Testing**: Comprehensive validation coverage
✅ **Developer Experience**: Fast feedback, clear error messages
✅ **Production Safety**: System tests validate before deployment

### Negative

⚠️ **Test Maintenance**: Tests require updates with config changes
⚠️ **Warning Fatigue**: Too many warnings reduce effectiveness
⚠️ **Performance Overhead**: Health checks add startup time
⚠️ **Complexity**: Four layers require coordination

### Mitigation

- **Test Documentation**: Clear test writing guidelines
- **Warning Discipline**: Only essential warnings, grouped by severity
- **Caching**: Health check results cached for 5 minutes
- **Layered Approach**: Run appropriate validation level per context

---

## Implementation Details

### Health Check Architecture

**Location**: `scripts/health-check.sh`

**Check Categories**:

**System Checks**:
- Nix daemon running
- nix-darwin installed
- Correct Nix version

**Configuration Checks**:
- Flake syntax valid
- Config files exist
- Symlinks correct

**Security Checks**:
- SOPS secrets encrypted
- Credential permissions correct
- No unencrypted secrets

**Package Checks**:
- Critical packages available
- PATH configured correctly
- Shell environment valid

**Output Format**:
```
✅ Nix daemon: running
✅ Config files: found
⚠️  Permissions: ~/.db/prod should be 600 (currently 644)
   Fix: chmod 600 ~/.db/prod
✅ Secrets: encrypted
```

### Test Framework Structure

**Directory Layout**:
```
tests/
├── run-all-tests.sh          # Master test runner
├── unit/                     # Unit tests
│   ├── test-lib.sh          # Library function tests
│   └── test-helpers.sh      # Helper validation
├── integration/              # Integration tests
│   ├── test-profiles.sh     # Profile loading
│   └── test-secrets.sh      # SOPS integration
└── system/                   # System tests
    └── test-rebuild.sh      # Full system build
```

**Test Writing Guidelines**:
- Use descriptive test names
- One assertion per test when possible
- Provide clear failure messages
- Clean up test artifacts

**Example Unit Test**:
```bash
test_selectByMachine_personal() {
  result=$(nix eval --expr '
    let lib = import ./lib;
    in lib.selectByMachine "macbook-pro-m1" {
      personal = "personal-value";
      work = "work-value";
    }
  ')
  assertEquals "personal-value" "$result"
}
```

### Warning System Implementation

**Warning Levels**:
- `CRITICAL` - Requires immediate attention
- `WARNING` - Should be addressed soon
- `INFO` - Informational, no action required

**Usage in Nix**:
```nix
{ myLib, ... }:
{
  warnings = myLib.mkWarnings [
    (myLib.mkWarning "WARNING"
      "Credential file has incorrect permissions"
      "Run: chmod 600 ~/.db/prod")
  ];
}
```

**Warning Display**:
```
⚠️  [WARNING] Credential file has incorrect permissions
    Action: Run: chmod 600 ~/.db/prod
```

### Permission Audit System

**Automated Checks**:

**Pre-Commit Hook** (`.git/hooks/pre-commit`):
```bash
# 1. Check staged files
# 2. Detect credential patterns
# 3. Validate SOPS encryption
# 4. Check file permissions
# 5. Block commit if critical issues
# 6. Warn if non-critical issues
```

**Health Check Integration**:
```bash
health-check --permissions  # Permission-only check
```

**Auto-Fix Utility**:
```bash
fix-permissions           # Fix all credential permissions
fix-permissions ~/.db/*   # Fix specific directory
```

**Protected Patterns**:
```bash
# .gitignore patterns that require permission checks
~/.db/**
~/.tokens/**
~/.aws/credentials
user-data/secrets/**
```

---

## Usage Examples

### Daily Development Workflow

```bash
# 1. Start work - health check
health-check

# 2. Make changes
nixconf

# 3. Run tests
./tests/run-all-tests.sh

# 4. Rebuild with validation
nix-rebuild

# 5. Commit (auto-validation via hooks)
git commit -m "feat: add feature"
```

### Troubleshooting Workflow

```bash
# System not working correctly
health-check --verbose

# Check specific layer
health-check --secrets      # Secret-only validation
health-check --permissions  # Permission-only validation
health-check --packages     # Package availability

# Fix issues
fix-permissions             # Auto-fix permission issues
edit-secrets               # Fix secret issues
nix-rebuild                # Re-apply configuration
```

### Test Development Workflow

```bash
# Add new unit test
vim tests/unit/test-myfeature.sh

# Run specific test
./tests/unit/test-myfeature.sh

# Run all tests
./tests/run-all-tests.sh

# CI integration
./tests/run-all-tests.sh --ci  # Exit non-zero on failure
```

---

## Alternatives Considered

### Alternative 1: Single Validation Script

Run all validation in one script.

**Rejected because**:
- ❌ No layered validation (all or nothing)
- ❌ Slow (always runs everything)
- ❌ Hard to extend
- ❌ Poor separation of concerns

### Alternative 2: Only Git Hooks

Validate everything in git hooks only.

**Rejected because**:
- ❌ No runtime validation
- ❌ No pre-rebuild checks
- ❌ Can be bypassed with `--no-verify`
- ❌ Slow commits

### Alternative 3: External Testing Framework

Use bats, shunit2, or other testing framework.

**Rejected because**:
- ❌ Additional dependency
- ❌ Learning curve
- ❌ May not integrate well with Nix
- ✅ **Future consideration** for complex test needs

### Alternative 4: No Warning System

Binary only - pass or fail.

**Rejected because**:
- ❌ Blocks builds for minor issues
- ❌ Poor developer experience
- ❌ No differentiation of severity
- ❌ Forces workarounds

---

## Integration with Git Workflow

**Pre-Commit Hook Validation**:
```bash
# Automatically runs:
# 1. Check SOPS secrets encrypted
# 2. Validate credential permissions
# 3. Prevent accidental credential commits
# 4. Run quick smoke tests (optional)
```

**Pre-Push Hook** (Optional):
```bash
# Runs more expensive checks:
# 1. Full test suite
# 2. System build validation
# 3. Integration tests
```

**Post-Merge Hook**:
```bash
# Suggests rebuild if needed:
# 1. Detect config changes
# 2. Recommend nix-rebuild
# 3. Run health check
```

---

## References

- [Health Check Script](../../../scripts/health-check.sh)
- [Test Framework](../../../tests/)
- [Git Hooks](../../../.git/hooks/)
- [Warning System](../../../lib/warnings.nix)
- [Secrets Guide](../../docs/SECRETS.md)
- [Troubleshooting Guide](../../docs/TROUBLESHOOTING.md)

---

## Revision History

- **2024-11-07**: Original ADRs (005, 006, 007, 008) created
- **2024-11-10**: Consolidated into unified validation architecture
