# Nix-Darwin Integration Test Suite

Comprehensive test suite for automated validation of nix-darwin configuration and functionality.

## Overview

This test suite provides automated testing for:

- **Build processes** - Flake validation, syntax checking, darwin-rebuild
- **Security features** - SOPS encryption, file permissions, git hooks
- **Helper functions** - Lib utilities, machine detection, navigation
- **Integration** - Multi-machine configs, rebuild cycles, rollback

## Quick Start

```bash
# Run all tests
./tests/run-all-tests.sh

# Run with detailed output
./tests/run-all-tests.sh --verbose

# Run specific category
./tests/run-all-tests.sh --category build

# Quick validation (skip expensive operations)
./tests/run-all-tests.sh --dry-run

# CI/CD mode
./tests/run-all-tests.sh --ci
```

## Test Categories

### Build Tests (`tests/build/`)

**Purpose**: Validate nix configuration and build processes

- `test-flake-check.sh` - Flake metadata, outputs, lock file validation
- `test-syntax.sh` - Nix syntax validation for all .nix files
- `test-darwin-build.sh` - Full darwin-rebuild build test (dry-run)

**When to run**: Before commits, after configuration changes

```bash
./tests/run-all-tests.sh --category build
```

### Security Tests (`tests/security/`)

**Purpose**: Validate security features and encryption

- `test-sops-encryption.sh` - Secrets encryption with SOPS
- `test-permissions.sh` - Credential file permissions (600 required)
- `test-git-hooks.sh` - Git hook validation and behavior

**When to run**: Before commits, after security changes, in CI/CD

```bash
./tests/run-all-tests.sh --category security
```

### Library Function Tests (`tests/lib/`)

**Purpose**: Validate helper functions and utilities

- `test-machine-detection.sh` - Hostname and machine mode detection
- `test-helpers.sh` - Update functions, navigation aliases, git helpers

**When to run**: After lib/ changes, before releases

```bash
./tests/run-all-tests.sh --category lib
```

### Integration Tests (`tests/integration/`)

**Purpose**: End-to-end system validation

- `test-multi-machine.sh` - Personal vs work configuration differentiation
- `test-rebuild.sh` - Full rebuild cycle validation
- `test-rollback.sh` - Rollback capability verification

**When to run**: Before major changes, periodic validation

```bash
./tests/run-all-tests.sh --category integration
```

## Test Framework

### Core Functions

```bash
# Test lifecycle
test_begin "Test Suite Name"    # Initialize test suite
test_end                         # Finalize and report results

# Assertions
assert_command_exists "cmd"                  # Command availability
assert_file_exists "/path/to/file"          # File existence
assert_directory_exists "/path/to/dir"      # Directory existence
assert_file_contains "file" "pattern"       # Content validation
assert_command_succeeds "command"            # Command success
assert_equals "actual" "expected"            # Value equality
assert_file_permissions "file" "600"         # Permission check

# Reporting
test_section "Section Name"      # Organize test output
test_info "Information"          # Informational message
test_skip "Test" "Reason"        # Skip test with reason
```

### Writing New Tests

1. **Create test script**:
```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../test-framework.sh"

test_begin "My Test Suite"

test_section "Section 1"
assert_command_exists "nix"
assert_file_exists "$HOME/.zshrc"

test_section "Section 2"
assert_command_succeeds "nix --version"

test_end
```

2. **Make executable**: `chmod +x tests/category/test-name.sh`

3. **Add to test runner**: Update `run-all-tests.sh` test_categories

4. **Test locally**: `./tests/run-all-tests.sh --category category --verbose`

## Usage Patterns

### Development Workflow

```bash
# 1. Make changes to configuration
vim modules/shared/packages.nix

# 2. Run syntax validation
./tests/run-all-tests.sh --category build --dry-run

# 3. Full build validation (if syntax passes)
./tests/run-all-tests.sh --category build

# 4. Security checks before commit
./tests/run-all-tests.sh --category security

# 5. Commit changes
git add . && git commit -m "changes"
```

### Pre-Commit Validation

```bash
# Quick validation before commit
./tests/run-all-tests.sh --dry-run --category build
./tests/run-all-tests.sh --category security

# Or comprehensive
./tests/run-all-tests.sh --verbose
```

### CI/CD Integration

```bash
# CI pipeline usage
./tests/run-all-tests.sh --ci

# Exit codes:
#   0 = All tests passed
#   1 = Some tests failed
#   2 = Invalid arguments
```

### Troubleshooting

```bash
# Verbose output for debugging
./tests/run-all-tests.sh --verbose --category build

# Stop on first failure
./tests/run-all-tests.sh --stop-on-fail

# Individual test execution
bash tests/build/test-syntax.sh

# Check test framework
bash tests/test-framework.sh  # (if standalone test added)
```

## Test Output

### Standard Output

```
════════════════════════════════════════════════════════════
🧪 Nix-Darwin Integration Test Suite
════════════════════════════════════════════════════════════

▶ Category: BUILD

Running: test-flake-check
  ✓ Flake metadata is valid
  ✓ Flake show succeeds
  ✓ flake.lock exists
✓ PASSED: test-flake-check

Running: test-syntax
  ✓ All 42 Nix files have valid syntax
✓ PASSED: test-syntax

📊 Test Execution Summary
Total Test Suites: 12
✓ Passed:          12
✗ Failed:          0
⊘ Skipped:         0
Execution Time:    45s

✅ ALL TEST SUITES PASSED
```

### CI Mode Output

```
PASS: test-flake-check
PASS: test-syntax
PASS: test-darwin-build

===== TEST SUMMARY =====
Total:   12
Passed:  12
Failed:  0
Skipped: 0
Time:    45s
=======================
```

## Environment Variables

- `TEST_VERBOSE=1` - Enable verbose output
- `TEST_DRY_RUN=1` - Skip expensive operations
- `REPO_ROOT` - Repository root (auto-detected)

## Test Fixtures

Located in `tests/fixtures/` (if needed):

- Sample configuration files
- Mock secrets for testing
- Test data files

## Best Practices

### DO

- ✅ Run tests before commits
- ✅ Add tests for new features
- ✅ Use `--dry-run` for quick validation
- ✅ Write descriptive test names
- ✅ Document test purpose in comments
- ✅ Clean up test artifacts

### DON'T

- ❌ Commit without running tests
- ❌ Skip security tests
- ❌ Modify system state in tests (use dry-run/validation only)
- ❌ Leave test artifacts behind
- ❌ Hardcode machine-specific paths

## Integration with Existing Tools

### Pre-Flight Checks

```bash
# Pre-flight checks run before rebuild
scripts/pre-flight-checks.sh

# Test suite validates what pre-flight checks
./tests/run-all-tests.sh --category security
```

### Health Check

```bash
# Health check provides runtime validation
scripts/health-check.sh

# Test suite provides build-time validation
./tests/run-all-tests.sh
```

### Zsh Aliases

Add to `home/jimmy/shell/zsh.nix`:

```nix
# Test aliases
test-all = "cd ~/nix-darwin && ./tests/run-all-tests.sh";
test-build = "cd ~/nix-darwin && ./tests/run-all-tests.sh --category build";
test-security = "cd ~/nix-darwin && ./tests/run-all-tests.sh --category security";
test-quick = "cd ~/nix-darwin && ./tests/run-all-tests.sh --dry-run";
```

## Continuous Improvement

### Adding New Tests

1. Identify test gap
2. Choose appropriate category
3. Write test following framework patterns
4. Test locally with `--verbose`
5. Update this README if needed
6. Commit with descriptive message

### Maintaining Tests

- Review test output regularly
- Update tests when features change
- Remove obsolete tests
- Keep test execution time reasonable
- Document test dependencies

## Troubleshooting

### Common Issues

**Test fails: "Command not found"**
```bash
# Ensure shell is properly initialized
exec zsh
source ~/.zshrc
```

**Test fails: "Permission denied"**
```bash
# Make test scripts executable
chmod +x tests/**/*.sh
```

**Test fails: "Nix daemon not running"**
```bash
# Start nix daemon
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

**Test fails: "SOPS decryption failed"**
```bash
# Check SOPS key
ls -la ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

## Performance

**Typical execution times**:

- Build tests (dry-run): ~10s
- Build tests (full): 2-5 minutes
- Security tests: ~5s
- Lib tests: ~5s
- Integration tests (dry-run): ~10s
- Integration tests (full): 5-10 minutes

**Total**: ~1 minute (dry-run), ~10 minutes (full)

## Future Enhancements

Potential additions:

- [ ] Performance benchmarking tests
- [ ] Network connectivity tests
- [ ] Package availability validation
- [ ] Configuration diff tests
- [ ] Automated regression testing
- [ ] Test coverage reporting
- [ ] Parallel test execution
- [ ] Test result caching

## Contributing

When adding new tests:

1. Follow existing patterns in test-framework.sh
2. Add descriptive comments
3. Test both success and failure cases
4. Update README with new test info
5. Ensure CI-compatible exit codes

## Support

For issues or questions:

1. Check test output with `--verbose`
2. Review test source code
3. Check existing validation scripts
4. Consult nix-darwin documentation
5. Open issue with test output

---

**Last Updated**: 2025-11-06
**Test Count**: 12 test suites
**Framework Version**: 1.0
