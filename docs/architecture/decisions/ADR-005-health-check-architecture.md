# ADR-005: Health Check Architecture

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The nix-darwin system has multiple layers of configuration:
- System packages (Nix + Homebrew)
- Shell configuration (Zsh, aliases, functions)
- Development environments (Python, Node.js)
- Git hooks and automation
- User-specific settings
- Machine-specific mixins

### Problems Identified

1. **Silent failures**: Issues not discovered until needed
   - Broken git hooks
   - Missing dependencies
   - Incorrect permissions
   - Outdated packages

2. **No validation**: After rebuild, unclear if everything works
   - Did shell aliases load?
   - Are git hooks active?
   - Is Python environment correct?

3. **Hard to debug**: When things break, no diagnostic tools
   - No system health overview
   - No quick validation commands
   - Manual checking required

4. **Rollback uncertainty**: After rollback, how to verify system health?

## Decision

**Implement comprehensive health check system with multiple validation layers.**

### Architecture

```
Health Check System
├── Core Health Check (health-check)
│   ├── System validation
│   ├── Package verification
│   ├── Configuration checks
│   └── Permission auditing
│
├── Specialized Checks
│   ├── Shell health (zsh-doctor)
│   ├── Git health (git-doctor)
│   ├── Python health (python-doctor)
│   └── Security health (security-audit)
│
└── Automated Triggers
    ├── Post-rebuild validation
    ├── Daily cron (optional)
    └── Manual invocation
```

### Implementation Strategy

**Phase 1: Core Health Check**
```bash
health-check
# Validates:
# ✓ System packages installed
# ✓ Homebrew apps present
# ✓ Shell configuration loaded
# ✓ Git hooks active
# ✓ Critical permissions
# ✓ Environment variables
```

**Phase 2: Specialized Diagnostics**
```bash
zsh-doctor      # Shell-specific validation
git-doctor      # Git configuration health
python-doctor   # Python environment check
security-audit  # Permission + secret validation
```

**Phase 3: Automated Validation**
```nix
# Post-rebuild hook
system.activationScripts.postActivation.text = ''
  echo "Running health check..."
  health-check --quick
'';
```

### Health Check Scope

| Category | Checks | Action on Failure |
|----------|--------|-------------------|
| **Critical** | Git hooks, SOPS encryption, core packages | ❌ Report + block |
| **Important** | Aliases, functions, dev tools | ⚠️ Warn |
| **Optional** | Optimizations, suggestions | ℹ️ Info |

## Consequences

### Positive

✅ **Early detection**: Catch issues immediately after changes
✅ **Confidence**: Know system is working correctly
✅ **Faster debugging**: Quick identification of broken components
✅ **Rollback validation**: Verify system health after rollback
✅ **Documentation**: Self-documenting system requirements
✅ **Onboarding**: New users can validate setup
✅ **Preventive**: Catch issues before they cause problems

### Negative

⚠️ **Maintenance burden**: Health checks must stay updated with config
⚠️ **Performance impact**: Health check takes time to run
⚠️ **False positives**: May report non-issues as problems
⚠️ **Complexity**: More code to maintain and debug

### Design Rationales

**Why multiple specialized checks?**
- Different users care about different components
- Allows targeted debugging (e.g., just check Python)
- Faster than running full health check
- Better organized than one monolithic script

**Why automated post-rebuild validation?**
- Immediate feedback on rebuild success
- Catches configuration errors before user encounters them
- Validates rebuild didn't break anything
- Professional CI/CD-like experience

**Why severity levels (critical/important/optional)?**
- Not all issues require immediate action
- Prevents warning fatigue
- Clear prioritization for fixes
- Allows progressive enhancement

## Alternatives Considered

### Alternative 1: No Health Checks

Rely on user testing to find issues.

**Rejected because**:
- ❌ Silent failures until user encounters them
- ❌ No systematic validation
- ❌ Harder debugging experience
- ❌ Lower confidence in system state

### Alternative 2: CI/CD Testing Only

GitHub Actions to test configuration.

**Rejected because**:
- ❌ Can't test machine-specific behavior
- ❌ No local validation before push
- ❌ Slower feedback loop
- ❌ Requires network access

### Alternative 3: NixOS Testing Framework

Use NixOS's built-in testing infrastructure.

**Rejected because**:
- ❌ Heavy infrastructure for personal config
- ❌ Requires NixOS VM setup
- ❌ Slower than lightweight health checks
- ❌ Overkill for validation needs

### Alternative 4: Manual Testing Checklists

Documentation with manual testing steps.

**Rejected because**:
- ❌ Easy to skip or forget
- ❌ Manual process is error-prone
- ❌ No automation benefits
- ❌ Time-consuming

### Alternative 5: Continuous Monitoring

Background daemon checking system health.

**Rejected because**:
- ❌ Unnecessary resource usage
- ❌ Complexity of daemon management
- ❌ System changes infrequent (rebuild-driven)
- ❌ On-demand checks sufficient

## Implementation Notes

### Core Health Check Implementation

```bash
#!/bin/bash
# lib/health-check.sh

health_check() {
  echo "🏥 System Health Check"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Critical checks
  echo "🔴 Critical Systems:"
  check_git_hooks
  check_sops_encryption
  check_core_packages

  # Important checks
  echo "🟡 Important Components:"
  check_shell_config
  check_aliases
  check_dev_tools

  # Optional checks
  echo "🟢 Optimizations:"
  check_performance
  check_updates_available

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print_summary
}
```

### Check Pattern

```bash
check_git_hooks() {
  local status="✅"

  if [[ ! -x ".git/hooks/pre-commit" ]]; then
    status="❌"
    echo "$status Git pre-commit hook missing or not executable"
    return 1
  fi

  if [[ ! -x ".git/hooks/pre-push" ]]; then
    status="❌"
    echo "$status Git pre-push hook missing or not executable"
    return 1
  fi

  echo "$status Git hooks active"
  return 0
}
```

### Specialized Check Implementation

```bash
# Shell-specific health check
zsh-doctor() {
  echo "🐚 Zsh Configuration Health Check"

  # Check plugins loaded
  check_plugin "zsh-autosuggestions"
  check_plugin "zsh-syntax-highlighting"

  # Check critical aliases
  check_alias "ll"
  check_alias "g"

  # Check functions available
  check_function "mkcd"
  check_function "extract"

  # Check environment variables
  check_env "EDITOR"
  check_env "MACHINE_MODE"
}
```

### Automated Post-Rebuild Validation

```nix
# modules/darwin/system.nix
system.activationScripts.postActivation.text = ''
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏥 Running post-rebuild health check..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Quick health check (critical only)
  ${pkgs.bash}/bin/bash ${./health-check.sh} --quick

  if [[ $? -eq 0 ]]; then
    echo "✅ System rebuild successful and healthy"
  else
    echo "⚠️  System rebuilt but health check found issues"
    echo "Run 'health-check' for detailed diagnostics"
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
'';
```

## User Experience

### Successful Health Check

```bash
$ health-check
🏥 System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 Critical Systems:
  ✅ Git pre-commit hook active
  ✅ Git pre-push hook active
  ✅ SOPS secrets encrypted
  ✅ Core packages installed (nix, git, zsh)

🟡 Important Components:
  ✅ Shell configuration loaded
  ✅ Aliases available (150 total)
  ✅ Development tools present

🟢 Optimizations:
  ℹ️  2 package updates available
  ℹ️  Homebrew cleanup recommended

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ System healthy (0 critical issues, 0 warnings)
```

### Failed Health Check

```bash
$ health-check
🏥 System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 Critical Systems:
  ❌ Git pre-commit hook missing
  ❌ SOPS secret plaintext detected: hosts/mbp-work/secrets.yaml
  ✅ Core packages installed

🟡 Important Components:
  ⚠️  Python virtual environment not activated
  ✅ Shell configuration loaded

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ System unhealthy (2 critical issues, 1 warning)

Run with --verbose for detailed diagnostics
Run with --fix to attempt automatic repairs
```

### Specialized Check

```bash
$ zsh-doctor
🐚 Zsh Configuration Health Check

Plugins:
  ✅ zsh-autosuggestions loaded
  ✅ zsh-syntax-highlighting loaded

Aliases:
  ✅ ll → ls -lah
  ✅ g → git
  ✅ nixconf → code ~/nix-darwin

Functions:
  ✅ mkcd available
  ✅ extract available

Environment:
  ✅ EDITOR=code
  ✅ MACHINE_MODE=work

✅ Shell configuration healthy
```

## Testing Strategy

### Unit Tests

Test individual check functions:
```bash
test_check_git_hooks() {
  # Setup: remove hook
  rm .git/hooks/pre-commit

  # Test
  check_git_hooks

  # Assert: should fail
  [[ $? -eq 1 ]]
}
```

### Integration Tests

Test full health check:
```bash
test_full_health_check() {
  # Run health check
  output=$(health-check)

  # Assert: all critical checks pass
  echo "$output" | grep "✅.*Git.*hook"
  echo "$output" | grep "✅.*SOPS"
}
```

### Automated Testing

Run health checks in CI:
```yaml
# .github/workflows/health-check.yml
- name: Run health check
  run: |
    darwin-rebuild switch --flake .
    health-check
```

## Monitoring and Metrics

Track health check effectiveness:
- Issues detected per month
- Time to detect vs time to encounter
- False positive rate
- Health check execution time

## Future Enhancements

**Potential improvements**:
1. **Auto-fix mode**: `health-check --fix` repairs common issues
2. **Scheduled checks**: Daily health check cron job
3. **Notification integration**: Slack/email on health degradation
4. **Historical tracking**: Track health over time
5. **Machine learning**: Predict issues before they occur
6. **Performance monitoring**: Track system performance metrics
7. **Dependency graph**: Visualize component health dependencies

## References

- [NixOS Testing](https://nixos.wiki/wiki/NixOS_Testing)
- [Bash Testing with Bats](https://github.com/bats-core/bats-core)
- [Architecture Overview](../overview.md)
- [Troubleshooting Guide](../../guides/troubleshooting.md)

## Revision History

- **2024-11-07**: Initial decision - Comprehensive health check system
