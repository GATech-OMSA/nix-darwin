# Testing Guide

**Comprehensive guide to the nix-darwin test framework and test suite**

---

## Overview

This nix-darwin configuration includes a comprehensive test suite with 12 test suites across 4 categories. The test framework provides systematic validation of build process, security configuration, library functions, and integration workflows.

**Why we test:**
- **Early detection** - Catch issues before they break your system
- **Confidence** - Safe to make changes knowing tests validate critical functionality
- **Documentation** - Tests serve as executable documentation of expected behavior
- **CI/CD ready** - Automated testing in continuous integration pipelines
- **Regression prevention** - Ensure fixes stay fixed and features keep working

**What we test:**
- **Build process** - Flake validation, syntax checking, darwin builds
- **Security** - SOPS encryption, file permissions, git hook protection
- **Library functions** - Helper functions, machine detection, shell functions
- **Integration** - Multi-machine configs, rebuild workflows, rollback capability

---

## Test Categories

### Build Tests (3 suites)

Validate configuration structure and build process:

**test-flake-check.sh** - Flake structure validation
- Flake metadata is accessible
- Flake outputs exist (darwinConfigurations)
- flake.lock is valid JSON with required inputs
- No uncommitted lock file changes

**test-syntax.sh** - Nix syntax validation
- All .nix files have valid syntax
- No syntax errors in configuration
- Proper formatting and structure

**test-darwin-build.sh** - Darwin build validation
- Configuration builds successfully
- No build-time errors
- System can be rebuilt

### Security Tests (3 suites)

Validate security configuration and encryption:

**test-sops-encryption.sh** - Secrets encryption validation
- SOPS and age are installed
- Age key exists with secure permissions (600)
- All secrets.yaml files are encrypted (binary format)
- SOPS configuration is valid
- No plaintext secrets detected

**test-permissions.sh** - File permission validation
- Credential files have secure permissions (600)
- Protected directories have correct access controls
- No world-readable sensitive files

**test-git-hooks.sh** - Git hook validation
- Pre-commit and pre-push hooks are installed
- Hooks have execute permissions
- Hooks validate secrets encryption
- Hooks block staging of protected credentials

### Library Tests (2 suites)

Validate helper functions and utilities:

**test-machine-detection.sh** - Machine detection logic
- Hostname detection works correctly
- Machine type (personal/work) is properly identified
- Machine-specific configuration loads correctly

**test-helpers.sh** - Helper function validation
- Update functions are available (update-all, update-nix, update-brew)
- Navigation aliases exist (dev, nixconf, repos)
- Config shortcuts work (gitconf, zshconf, vscodeconf)
- Git aliases are properly configured
- Nix helper functions are available (nix-rebuild, nix-rollback, edit-secrets)

### Integration Tests (3 suites)

Validate end-to-end workflows:

**test-multi-machine.sh** - Multi-machine configuration
- Both machine configs (mbp-jimmy, mbp-work) are valid
- Machine-specific settings apply correctly
- Mixin system works properly

**test-rebuild.sh** - Rebuild workflow validation
- System can rebuild successfully
- Configuration changes apply correctly
- No build errors or warnings

**test-rollback.sh** - Rollback capability validation
- Previous generations are available
- Rollback functionality works
- System can recover from bad changes

---

## Running Tests

### Quick Start

```bash
# Run all tests
test-all

# Run specific category
test-build      # Build tests only
test-security   # Security tests only
test-lib        # Library tests only
test-integration # Integration tests only

# Quick validation (build + security)
test-quick
```

### Using run-all-tests.sh

The test runner provides comprehensive options:

```bash
# Run all tests with detailed output
./tests/run-all-tests.sh --verbose

# Run specific category
./tests/run-all-tests.sh --category build
./tests/run-all-tests.sh --category security
./tests/run-all-tests.sh --category lib
./tests/run-all-tests.sh --category integration

# Dry-run mode (skip expensive operations)
./tests/run-all-tests.sh --dry-run

# Stop on first failure
./tests/run-all-tests.sh --stop-on-fail

# CI mode (minimal output, strict exit codes)
./tests/run-all-tests.sh --ci
```

### Test Runner Options

| Option | Description |
|--------|-------------|
| `--verbose` | Show detailed test output with additional diagnostics |
| `--dry-run` | Skip expensive operations (builds, etc.) for quick validation |
| `--category CAT` | Run only specific category (build, security, lib, integration) |
| `--stop-on-fail` | Stop execution on first test failure |
| `--ci` | CI mode with minimal output and strict exit codes |
| `--help` | Show help message with all options |

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed
- `2` - Invalid arguments

---

## Writing Tests

### Test Structure

All test scripts follow this structure:

```bash
#!/usr/bin/env bash
#
# Test: Test Suite Name
# Description of what this test validates
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Test Suite Name"

test_section "Feature Area 1"

# Individual test assertions
assert_command_exists "nix"
assert_file_exists "/path/to/file"

test_section "Feature Area 2"

# More assertions
assert_file_contains "file.nix" "expected-content"
assert_command_succeeds "nix flake check"

test_end
```

### Test Framework Functions

The framework provides 15+ assertion functions:

#### Lifecycle Functions

**test_begin(suite_name)** - Start test suite
- Initializes counters and displays suite header
- Required at start of every test file

**test_end()** - End test suite
- Displays summary (total, passed, failed, skipped)
- Exits with appropriate code (0 = success, 1 = failure)
- Required at end of every test file

**test_section(name)** - Start new test section
- Organizes tests into logical groups
- Improves readability of output

#### Existence Assertions

**assert_command_exists(command, [message])** - Verify command is available
```bash
assert_command_exists "sops" "SOPS command available"
```

**assert_file_exists(path, [message])** - Verify file exists
```bash
assert_file_exists "$HOME/.zshrc" "Zsh config exists"
```

**assert_directory_exists(path, [message])** - Verify directory exists
```bash
assert_directory_exists "$HOME/.config" "Config directory exists"
```

**assert_symlink_exists(path, [message])** - Verify symlink exists
```bash
assert_symlink_exists "$HOME/.config/nvim" "Neovim config linked"
```

#### Content Assertions

**assert_file_contains(file, pattern, [message])** - Verify file contains pattern
```bash
assert_file_contains "flake.lock" "nixpkgs" "Lock file contains nixpkgs"
```

**assert_file_not_contains(file, pattern, [message])** - Verify file doesn't contain pattern
```bash
assert_file_not_contains "secrets.yaml" "password:" "No plaintext passwords"
```

**assert_output_contains(command, pattern, [message])** - Verify command output contains pattern
```bash
assert_output_contains "nix flake show" "darwinConfigurations" "Has darwin configs"
```

#### Execution Assertions

**assert_command_succeeds(command, [message])** - Verify command succeeds (exit code 0)
```bash
assert_command_succeeds "nix flake check" "Flake check passes"
```

**assert_command_fails(command, [message])** - Verify command fails (exit code != 0)
```bash
assert_command_fails "test -f /nonexistent" "File doesn't exist"
```

**assert_exit_code(command, expected_code, [message])** - Verify specific exit code
```bash
assert_exit_code "grep missing file.txt" "1" "Grep exits with 1 when not found"
```

#### Value Assertions

**assert_equals(actual, expected, [message])** - Verify values are equal
```bash
assert_equals "$hostname" "mbp-jimmy" "Hostname is mbp-jimmy"
```

**assert_not_equals(actual, expected, [message])** - Verify values are different
```bash
assert_not_equals "$MODE" "" "Machine mode is set"
```

**assert_file_permissions(file, perms, [message])** - Verify file permissions
```bash
assert_file_permissions "$HOME/.ssh/id_rsa" "600" "SSH key has secure permissions"
```

#### Control Functions

**test_skip(message, [reason])** - Skip a test with reason
```bash
if ! command -v sops &> /dev/null; then
  test_skip "SOPS encryption test" "SOPS not installed"
fi
```

**test_info(message)** - Display informational message
```bash
test_info "Testing with hostname: $hostname"
```

**test_verbose(message)** - Display message only in verbose mode
```bash
test_verbose "Detailed diagnostic information"
```

#### Fixture Helpers

**create_temp_file([content])** - Create temporary file with optional content
```bash
temp_file=$(create_temp_file "test content")
# Use temp file...
cleanup_temp_file "$temp_file"
```

**cleanup_temp_file(path)** - Remove temporary file
```bash
cleanup_temp_file "$temp_file"
```

### Example Test Suite

Complete example demonstrating framework usage:

```bash
#!/usr/bin/env bash
#
# Test: Nix Configuration
# Validates Nix and darwin-rebuild functionality
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Nix Configuration"

test_section "Nix Installation"

# Test: Nix command exists
assert_command_exists "nix" "Nix command available"

# Test: Darwin-rebuild exists
assert_command_exists "darwin-rebuild" "darwin-rebuild available"

test_section "Configuration Files"

# Test: Flake exists
assert_file_exists "$REPO_ROOT/flake.nix" "flake.nix exists"

# Test: Flake contains darwin
assert_file_contains "$REPO_ROOT/flake.nix" "nix-darwin" \
  "Flake imports nix-darwin"

test_section "Build Validation"

# Test: Flake check passes
if [[ $TEST_DRY_RUN -eq 0 ]]; then
  assert_command_succeeds \
    "cd '$REPO_ROOT' && nix flake check --no-write-lock-file" \
    "Flake check passes"
else
  test_skip "Flake check" "Dry-run mode enabled"
fi

test_section "Helper Functions"

# Test: Rebuild alias exists
assert_command_exists "nix-rebuild" "nix-rebuild alias exists"

# Test: Rollback alias exists
assert_command_exists "nix-rollback" "nix-rollback alias exists"

test_end
```

### Writing Guidelines

**Structure:**
- Start with `test_begin` and end with `test_end`
- Group related tests in sections with `test_section`
- Use descriptive test names and messages

**Assertions:**
- Use specific assertion functions (don't just run commands)
- Provide clear, descriptive messages
- Test one thing per assertion
- Always return 0 (framework handles failures internally)

**Performance:**
- Skip expensive operations in dry-run mode
- Check `$TEST_DRY_RUN` before running builds
- Use `test_skip` for conditional tests

**Output:**
- Use `test_info` for important context
- Use `test_verbose` for detailed diagnostics
- Keep test messages concise but clear

---

## CI/CD Integration

### GitHub Actions

Example workflow for automated testing:

```yaml
name: Test Suite

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Nix
        uses: cachix/install-nix-action@v22
        with:
          nix_path: nixpkgs=channel:nixpkgs-unstable

      - name: Run Tests
        run: |
          chmod +x tests/run-all-tests.sh
          ./tests/run-all-tests.sh --ci

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### Pre-commit Integration

Run tests automatically before commits:

```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
./tests/run-all-tests.sh --category build --category security --ci
```

### Pre-push Validation

Comprehensive validation before push:

```bash
# Add to .git/hooks/pre-push
#!/bin/bash
./tests/run-all-tests.sh --ci
```

---

## Troubleshooting Test Failures

### Build Test Failures

**Flake check fails:**
```bash
# View detailed trace
nix flake check --show-trace

# Common issues:
# - Syntax errors in .nix files
# - Missing inputs in flake.lock
# - Incompatible nixpkgs versions
```

**Syntax test fails:**
```bash
# Check specific file
nix-instantiate --parse file.nix

# Common issues:
# - Missing semicolons
# - Unbalanced braces/brackets
# - Incorrect attribute syntax
```

**Darwin build fails:**
```bash
# Try manual build with trace
darwin-rebuild build --flake . --show-trace

# Common issues:
# - Package conflicts
# - Invalid configuration options
# - Missing dependencies
```

### Security Test Failures

**SOPS encryption fails:**
```bash
# Check if file is encrypted
file hosts/*/secrets.yaml

# Re-encrypt if needed
sops -e -i hosts/mbp-work/secrets.yaml

# Common issues:
# - Plaintext secrets.yaml
# - Missing age key
# - Incorrect .sops.yaml configuration
```

**Permission test fails:**
```bash
# Fix permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.config/sops/age/keys.txt

# Common issues:
# - Files created with default permissions
# - Restored from backup with wrong permissions
```

**Git hook test fails:**
```bash
# Reinstall hooks
./scripts/install-hooks.sh

# Make executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push

# Common issues:
# - Hooks not installed
# - Hooks missing execute permission
# - Hooks not sourcing test framework
```

### Library Test Failures

**Helper function missing:**
```bash
# Rebuild to regenerate shell configuration
nix-rebuild

# Restart shell to reload functions
exec zsh

# Common issues:
# - Shell not restarted after rebuild
# - Function definition syntax error
# - Missing function export
```

**Alias not found:**
```bash
# Check if defined
type alias-name

# View all aliases
alias | grep alias-name

# Common issues:
# - Alias defined in wrong file
# - Shell not restarted
# - Syntax error in alias definition
```

### Integration Test Failures

**Multi-machine test fails:**
```bash
# Test each machine configuration
nix build .#darwinConfigurations.mbp-jimmy.system
nix build .#darwinConfigurations.mbp-work.system

# Common issues:
# - Machine-specific configuration errors
# - Mixin not applied correctly
# - Hostname detection failure
```

**Rebuild test fails:**
```bash
# Try manual rebuild
darwin-rebuild switch --flake .

# Common issues:
# - Build failures (see build tests)
# - Permission issues
# - Lock file conflicts
```

**Rollback test fails:**
```bash
# Check available generations
darwin-rebuild --list-generations

# Try manual rollback
darwin-rebuild rollback

# Common issues:
# - No previous generations
# - Generation corruption
# - Profile symlink issues
```

---

## Best Practices

### Test Development

**Write tests first:**
- Define expected behavior before implementation
- Tests serve as specification
- Easier to validate changes

**Keep tests focused:**
- One test suite per feature area
- One assertion per concept
- Clear, descriptive names

**Use appropriate categories:**
- Build tests for configuration validation
- Security tests for protection verification
- Library tests for function behavior
- Integration tests for end-to-end workflows

### Test Execution

**Run tests frequently:**
- Before commits: `test-quick`
- Before push: `test-all`
- After changes: relevant category

**Use dry-run for quick checks:**
```bash
# Quick syntax validation
./tests/run-all-tests.sh --dry-run --category build
```

**Verbose mode for debugging:**
```bash
# Detailed output for investigation
./tests/run-all-tests.sh --verbose --category security
```

### Test Maintenance

**Update tests when:**
- Adding new features
- Changing configuration structure
- Fixing bugs (add regression test)
- Deprecating functionality

**Review test failures:**
- Don't ignore failing tests
- Fix or update tests to match new behavior
- Document why tests were changed

**Keep tests fast:**
- Skip expensive operations in quick mode
- Use dry-run for syntax-only checks
- Parallelize independent tests

---

## Next Steps

**For users:**
- Run `test-all` to validate your system
- Run `test-quick` before making changes
- Check specific categories after edits

**For developers:**
- Write tests for new features
- Add regression tests for bug fixes
- Keep test coverage comprehensive

**For CI/CD:**
- Integrate tests in pipelines
- Use `--ci` mode for automated runs
- Upload test results as artifacts

---

## Additional Resources

- **Test Framework:** [tests/test-framework.sh](/Users/jimmy/nix-darwin/tests/test-framework.sh)
- **Test Runner:** [tests/run-all-tests.sh](/Users/jimmy/nix-darwin/tests/run-all-tests.sh)
- **Test Suites:** [tests/](/Users/jimmy/nix-darwin/tests/)
- **Shell Reference:** [reference/shell.md](../reference/shell.md) - Test aliases
- **Troubleshooting:** [troubleshooting.md](troubleshooting.md) - General debugging

---

**Comprehensive testing for confident configuration management!**
