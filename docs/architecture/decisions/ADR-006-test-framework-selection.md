# ADR-006: Test Framework Selection

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The nix-darwin configuration requires testing at multiple levels:

1. **Configuration validation**: Nix expressions parse correctly
2. **Build testing**: Configuration builds successfully
3. **Functional testing**: Shell scripts, aliases, functions work as expected
4. **Integration testing**: Components work together correctly
5. **Regression prevention**: Changes don't break existing functionality

### Testing Needs Identified

**Unit Tests**:
- Helper functions in `lib/`
- Shell functions and aliases
- Individual configuration modules

**Integration Tests**:
- Health check scripts
- Git hooks
- User workflows (rebuild, rollback)

**System Tests**:
- Full system rebuild
- Cross-machine compatibility
- Mixin selection logic

### Requirements

1. **Nix-native**: Integrate well with Nix ecosystem
2. **Shell testing**: Support Bash/Zsh script testing
3. **Fast execution**: Quick feedback loop
4. **CI/CD friendly**: Easy to run in automation
5. **Maintainable**: Clear, readable test syntax
6. **Comprehensive**: Cover all testing needs

## Decision

**Use Nix-based testing with Bats for shell script validation.**

### Testing Architecture

```
Testing Strategy
├── Nix Evaluation Tests
│   ├── nix flake check
│   ├── Configuration parsing
│   └── Module evaluation
│
├── Build Tests (nixci)
│   ├── darwin-rebuild build
│   ├── Package availability
│   └── Configuration application
│
└── Functional Tests (Bats)
    ├── Shell script testing
    ├── Function validation
    └── Integration scenarios
```

### Framework Selection

**Primary: Nix built-in testing**
```nix
# tests/default.nix
{
  # Test configuration parses
  testConfigParse = pkgs.runCommand "test-config-parse" {} ''
    ${pkgs.nix}/bin/nix eval .#darwinConfigurations.mbp-jimmy
    touch $out
  '';

  # Test build succeeds
  testBuild = pkgs.runCommand "test-build" {} ''
    ${pkgs.nix}/bin/nix build .#darwinConfigurations.mbp-jimmy.system
    touch $out
  '';
}
```

**Secondary: Bats (Bash Automated Testing System)**
```bash
# tests/shell/test-aliases.bats
@test "git alias 'g s' works" {
  run g s
  [ "$status" -eq 0 ]
}

@test "mkcd creates and enters directory" {
  run mkcd test-dir
  [ -d "test-dir" ]
}
```

### Test Organization

```
tests/
├── default.nix           # Nix test definitions
├── shell/                # Shell script tests
│   ├── test-aliases.bats
│   ├── test-functions.bats
│   └── test-env.bats
├── integration/          # Integration tests
│   ├── test-health-check.bats
│   ├── test-git-hooks.bats
│   └── test-rebuild.bats
└── lib/                  # Helper function tests
    └── test-helpers.bats
```

## Consequences

### Positive

✅ **Nix-native**: Built-in `nix flake check` integration
✅ **Shell testing**: Bats excellent for Bash/Zsh validation
✅ **Fast feedback**: Tests run in seconds
✅ **CI/CD ready**: Easy GitHub Actions integration
✅ **Readable syntax**: TAP output, clear test descriptions
✅ **Comprehensive**: Covers all testing layers
✅ **Community standard**: Both tools widely used in Nix community

### Negative

⚠️ **Two frameworks**: Nix tests + Bats tests to maintain
⚠️ **Learning curve**: Developers must learn both
⚠️ **Setup complexity**: Bats installation and integration
⚠️ **Limited mocking**: Harder to mock in shell tests

### Design Rationales

**Why Nix built-in tests for config?**
- Native integration with Nix ecosystem
- Validates configuration before any runtime
- Catches syntax errors early
- No additional dependencies

**Why Bats for shell scripts?**
- Industry standard for Bash testing
- Clean, readable syntax
- TAP (Test Anything Protocol) output
- Excellent CI/CD integration
- Better than custom test scripts

**Why not a single framework?**
- Different testing needs require different tools
- Nix tests for static validation
- Bats tests for runtime behavior
- Separation of concerns

## Alternatives Considered

### Alternative 1: NixOS Testing Framework

Use NixOS VM-based testing infrastructure.

**Rejected because**:
- ❌ Heavy infrastructure (requires VMs)
- ❌ Slower execution (VM startup time)
- ❌ Overkill for personal configuration
- ❌ macOS-specific testing harder
- ❌ More complex setup

### Alternative 2: Pytest for Everything

Use Python pytest for all testing.

**Rejected because**:
- ❌ Not Nix-native
- ❌ Additional dependency (Python)
- ❌ Shell script testing awkward
- ❌ Harder Nix configuration validation
- ❌ Slower than Bats for shell

### Alternative 3: Custom Shell Scripts

Write custom test scripts in Bash.

**Rejected because**:
- ❌ Reinventing the wheel
- ❌ No standard test output format
- ❌ Harder CI/CD integration
- ❌ Less maintainable than Bats
- ❌ No test discovery/runner

### Alternative 4: ShellCheck Only

Use static analysis (shellcheck) instead of tests.

**Rejected because**:
- ❌ Catches syntax but not logic errors
- ❌ No functional testing
- ❌ Doesn't validate behavior
- ❌ Complement, not replacement for tests

### Alternative 5: Manual Testing Only

No automated tests, rely on manual validation.

**Rejected because**:
- ❌ Error-prone
- ❌ Time-consuming
- ❌ No regression prevention
- ❌ Hard to validate refactoring
- ❌ Can't test edge cases systematically

## Implementation Notes

### Nix Test Implementation

```nix
# tests/default.nix
{ pkgs, lib, ... }:

{
  # Test: Configuration parses without errors
  testConfigParse = pkgs.runCommand "test-config-parse" {} ''
    ${pkgs.nix}/bin/nix eval .#darwinConfigurations.mbp-jimmy.config.system.stateVersion
    touch $out
  '';

  # Test: Helper functions work correctly
  testHelperFunctions = pkgs.runCommand "test-helpers" {} ''
    ${pkgs.nix}/bin/nix eval --expr '
      let
        myLib = import ./lib { };
      in
        assert myLib.isWork "mbp-work" == true;
        assert myLib.isPersonal "mbp-jimmy" == true;
        "ok"
    '
    touch $out
  '';

  # Test: Build succeeds for all machines
  testBuildAll = pkgs.runCommand "test-build-all" {} ''
    ${pkgs.nix}/bin/nix build .#darwinConfigurations.mbp-jimmy.system
    ${pkgs.nix}/bin/nix build .#darwinConfigurations.mbp-work.system
    touch $out
  '';
}
```

### Bats Test Implementation

```bash
# tests/shell/test-aliases.bats
#!/usr/bin/env bats

setup() {
  # Load shell configuration
  source ~/.zshrc
}

@test "git status alias works" {
  run g s
  [ "$status" -eq 0 ]
}

@test "nix-rebuild alias exists" {
  run command -v nix-rebuild
  [ "$status" -eq 0 ]
}

@test "mkcd creates directory and changes into it" {
  temp_dir=$(mktemp -d)
  cd "$temp_dir"

  run mkcd test-directory
  [ "$status" -eq 0 ]
  [ -d "test-directory" ]
  [ "$PWD" = "$temp_dir/test-directory" ]

  # Cleanup
  cd ..
  rm -rf "$temp_dir"
}
```

### Integration Test Example

```bash
# tests/integration/test-health-check.bats
#!/usr/bin/env bats

@test "health-check command exists" {
  run command -v health-check
  [ "$status" -eq 0 ]
}

@test "health-check reports git hooks" {
  run health-check
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Git.*hook" ]]
}

@test "health-check detects missing hooks" {
  # Temporarily remove hook
  mv .git/hooks/pre-commit .git/hooks/pre-commit.bak

  run health-check
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌.*hook.*missing" ]]

  # Restore
  mv .git/hooks/pre-commit.bak .git/hooks/pre-commit
}
```

### Running Tests

```bash
# Nix tests
nix flake check                    # All Nix tests
nix build .#tests.testConfigParse  # Specific test

# Bats tests
bats tests/shell/                  # All shell tests
bats tests/shell/test-aliases.bats # Specific file

# All tests
./scripts/run-tests.sh             # Convenience script
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  nix-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20

      - name: Run Nix tests
        run: nix flake check

      - name: Test builds
        run: |
          nix build .#darwinConfigurations.mbp-jimmy.system
          nix build .#darwinConfigurations.mbp-work.system

  shell-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Bats
        run: brew install bats-core

      - name: Run shell tests
        run: bats tests/shell/

      - name: Run integration tests
        run: bats tests/integration/
```

## Test Coverage Goals

| Component | Target Coverage | Method |
|-----------|----------------|--------|
| Nix configuration | 100% parse | `nix flake check` |
| Helper functions | 90% logic | Nix + Bats |
| Shell scripts | 80% functions | Bats |
| Git hooks | 100% critical | Bats |
| Health checks | 90% validation | Bats |
| Integration | Key workflows | Bats |

## Testing Best Practices

### Nix Tests

1. **Fast evaluation**: Tests should evaluate quickly
2. **Pure**: No network calls, no side effects
3. **Deterministic**: Same input = same output
4. **Isolated**: Tests don't depend on each other

### Bats Tests

1. **Setup/teardown**: Use `setup()` and `teardown()` functions
2. **Descriptive names**: Test names explain what's tested
3. **One assertion**: Each test checks one thing
4. **Cleanup**: Always clean up temporary files
5. **Idempotent**: Tests can run multiple times

### Integration Tests

1. **Real scenarios**: Test actual user workflows
2. **State management**: Handle test state carefully
3. **Error cases**: Test both success and failure
4. **Performance**: Track test execution time

## Maintenance Strategy

### When to Add Tests

**Always**:
- New helper functions
- New shell functions/aliases
- Critical workflows (rebuild, rollback)
- Bug fixes (regression tests)

**Sometimes**:
- Configuration changes
- Documentation updates
- Refactoring (if behavior changes)

**Never**:
- Trivial aliases
- Pure documentation
- Temporary experiments

### Test Maintenance

**Monthly**:
- Review test coverage
- Remove obsolete tests
- Update for configuration changes
- Check CI/CD status

**Per-change**:
- Run relevant tests locally
- Add tests for new functionality
- Update tests for changed behavior
- Verify CI passes

## Future Enhancements

**Potential improvements**:
1. **Coverage reporting**: Track test coverage metrics
2. **Performance benchmarks**: Test system performance
3. **Snapshot testing**: Compare system state snapshots
4. **Property-based testing**: Generate test cases automatically
5. **Visual regression**: Test UI changes (Homebrew apps)
6. **Fuzz testing**: Test with random inputs

## References

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [Nix Testing](https://nixos.wiki/wiki/NixOS_Testing)
- [GitHub Actions + Nix](https://github.com/cachix/install-nix-action)
- [TAP Protocol](https://testanything.org/)

## Revision History

- **2024-11-07**: Initial decision - Nix + Bats testing framework
