# ADR-007: Warning System Design

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The system performs various validation checks:
- Git hooks (SOPS encryption, credential protection)
- Health checks (system validation)
- Permission auditing (credential file permissions)
- Configuration validation (Nix syntax, build errors)

### Problem: Binary Error Handling

Initial implementation had only two states:
- ✅ **Pass**: Everything perfect → Continue
- ❌ **Fail**: Any issue → Block operation

This created problems:
1. **Non-critical issues block workflow**: Insecure permissions stop commits
2. **Important warnings hidden**: Users bypass checks with `--no-verify`
3. **All-or-nothing approach**: No middle ground for advisory issues
4. **User frustration**: Minor issues cause major disruption

### Real-World Scenario

```bash
$ git commit -m "Update config"
❌ ERROR: ~/.tokens/api_key has permissions 644 (should be 600)
Commit blocked.

# User response: "This is annoying, I'll fix it later"
$ git commit --no-verify -m "Update config"
# Now ALL validations bypassed, including critical ones
```

## Decision

**Implement three-tier validation system: Errors, Warnings, and Info.**

### Validation Tiers

```
Validation Severity Levels
├── 🔴 ERROR (Exit 1)
│   ├── Blocks operation completely
│   ├── Must be fixed before proceeding
│   └── Examples: Plaintext secrets, missing critical hooks
│
├── 🟡 WARNING (Exit 0, visible)
│   ├── Allows operation to continue
│   ├── Strongly recommends fixing
│   └── Examples: Insecure permissions, outdated packages
│
└── 🟢 INFO (Exit 0, subtle)
    ├── Informational only
    ├── Nice-to-have improvements
    └── Examples: Optimization suggestions, cleanup opportunities
```

### Severity Classification

| Validation | Severity | Rationale |
|-----------|----------|-----------|
| Plaintext SOPS secret | 🔴 ERROR | Immediate security risk, will leak on push |
| Credential file staged | 🔴 ERROR | Prevents accidental secret commit |
| Missing git hooks | 🔴 ERROR | Critical security validation missing |
| Insecure permissions (644) | 🟡 WARNING | Security risk but not immediate |
| Outdated packages | 🟡 WARNING | Affects security but not critical |
| Missing optional tools | 🟢 INFO | Reduces functionality but not broken |
| Performance suggestions | 🟢 INFO | Optimization opportunity |

### Implementation Pattern

```bash
# Validation function structure
validate_something() {
  local severity="$1"  # error|warning|info
  local message="$2"
  local check_result="$3"

  case "$severity" in
    error)
      if [[ "$check_result" == "fail" ]]; then
        echo "❌ ERROR: $message"
        return 1  # Exit code 1 = block operation
      fi
      ;;
    warning)
      if [[ "$check_result" == "fail" ]]; then
        echo "⚠️  WARNING: $message"
        return 0  # Exit code 0 = allow operation
      fi
      ;;
    info)
      if [[ "$check_result" == "fail" ]]; then
        echo "ℹ️  INFO: $message"
        return 0  # Exit code 0 = allow operation
      fi
      ;;
  esac
}
```

## Consequences

### Positive

✅ **Better UX**: Users aren't blocked by minor issues
✅ **Maintained security**: Critical validations still enforced
✅ **Fewer bypasses**: Users less likely to use `--no-verify`
✅ **Progressive enforcement**: Can start as warning, upgrade to error
✅ **Awareness**: Users see issues but can proceed
✅ **Prioritization**: Clear what must be fixed vs nice-to-fix
✅ **Flexibility**: Different severity for different contexts

### Negative

⚠️ **Warning fatigue**: Users may ignore warnings
⚠️ **Complexity**: More logic to determine severity
⚠️ **Inconsistency risk**: Misclassifying severity levels
⚠️ **Security risk**: Important warnings might be ignored

### Mitigation Strategies

**Prevent warning fatigue**:
- Limit warnings per operation (max 5)
- Suppress repeated warnings
- Make warnings actionable (provide fix command)
- Periodic summary of unresolved warnings

**Ensure correct severity**:
- Document severity decision criteria
- Review severity levels regularly
- Upgrade warnings to errors if frequently ignored
- Track warning resolution rates

## Alternatives Considered

### Alternative 1: Binary (Pass/Fail Only)

Only errors, no warnings.

**Rejected because**:
- ❌ Too restrictive for workflow
- ❌ Forces users to bypass checks
- ❌ No way to communicate non-critical issues
- ❌ All-or-nothing doesn't match reality

### Alternative 2: All Warnings

Everything is a warning, nothing blocks.

**Rejected because**:
- ❌ Critical issues not enforced
- ❌ Security validations become optional
- ❌ No teeth for important checks
- ❌ Too permissive

### Alternative 3: Configurable Severity

Users configure severity per check.

**Rejected because**:
- ❌ Complexity for users
- ❌ Can downgrade critical security checks
- ❌ Configuration drift between machines
- ❌ Defeats purpose of opinionated system

### Alternative 4: Strict Mode Toggle

`--strict` flag makes warnings into errors.

**Rejected because**:
- ❌ Adds complexity (two modes to maintain)
- ❌ Users may not use strict mode
- ❌ Default mode matters more than optional strict
- ❌ Better to have sensible defaults

### Alternative 5: Remediation Prompts

Prompt user to fix warning immediately.

**Rejected because**:
- ❌ Breaks non-interactive workflows
- ❌ Annoying in CI/CD
- ❌ Can't always fix immediately
- ❌ Better to document fix and continue

## Implementation Notes

### Severity Decision Criteria

**🔴 ERROR: Block operation if...**
1. **Immediate security risk**: Will leak secrets, create vulnerability
2. **Data loss risk**: Could corrupt system or lose data
3. **System breakage**: Will prevent system from functioning
4. **Reversibility**: Cannot be easily undone after operation
5. **Urgency**: Must be fixed before proceeding

**🟡 WARNING: Allow but highlight if...**
1. **Security concern**: But not immediate threat
2. **Degraded functionality**: System works but suboptimally
3. **Best practice violation**: Should fix but not critical
4. **Future risk**: May cause issues later
5. **Easily fixable**: Can be corrected without disruption

**🟢 INFO: Inform only if...**
1. **Optimization**: Could be better but working fine
2. **Nice to have**: Optional improvement
3. **Awareness**: User should know but no action required
4. **Educational**: Teaching moment, not issue
5. **Context**: Helpful information for understanding

### Permission Check Example

```bash
# OLD: Binary error (blocked commits)
check_permissions() {
  for file in ~/.tokens/* ~/.db/*; do
    perms=$(stat -f "%Lp" "$file")
    if [[ "$perms" != "600" ]]; then
      echo "❌ ERROR: $file has permissions $perms"
      return 1  # Blocks commit
    fi
  done
}

# NEW: Warning system (allows commit)
check_permissions() {
  local issues=0

  for file in ~/.tokens/* ~/.db/*; do
    if [[ -f "$file" ]]; then
      perms=$(stat -f "%Lp" "$file")
      if [[ "$perms" != "600" ]]; then
        echo "⚠️  WARNING: $file has permissions $perms (should be 600)"
        echo "   Fix with: chmod 600 $file"
        issues=$((issues + 1))
      fi
    fi
  done

  if [[ $issues -gt 0 ]]; then
    echo ""
    echo "ℹ️  INFO: Found $issues permission issue(s)"
    echo "   These should be fixed but won't block your commit."
  fi

  return 0  # Allows commit despite warnings
}
```

### Progressive Enforcement

Start as warning, escalate to error if ignored:

```bash
check_outdated_packages() {
  local outdated_count=$(nix-env -q --out-path | wc -l)

  if [[ $outdated_count -gt 10 ]]; then
    # Severe: error
    echo "❌ ERROR: $outdated_count outdated packages"
    echo "   Security risk. Run: update-all"
    return 1
  elif [[ $outdated_count -gt 5 ]]; then
    # Moderate: warning
    echo "⚠️  WARNING: $outdated_count outdated packages"
    echo "   Recommended: update-all"
    return 0
  elif [[ $outdated_count -gt 0 ]]; then
    # Minor: info
    echo "ℹ️  INFO: $outdated_count outdated packages"
    return 0
  fi

  return 0
}
```

### Context-Aware Severity

Different severity in different contexts:

```bash
check_sops_encryption() {
  local context="$1"  # commit|push|build

  for file in hosts/*/secrets.yaml; do
    if head -n 1 "$file" | grep -q '^#\|^---'; then
      # Plaintext secret detected

      case "$context" in
        commit|push)
          # Critical: about to commit secret
          echo "❌ ERROR: Plaintext secret in $file"
          return 1
          ;;
        build)
          # Warning: local build only
          echo "⚠️  WARNING: Plaintext secret in $file"
          return 0
          ;;
      esac
    fi
  done
}
```

## User Experience

### Error Message

```bash
$ git commit -m "Update config"
🔍 Validating secrets and credentials...
❌ ERROR: Plaintext secret detected in hosts/mbp-work/secrets.yaml
Secrets must be encrypted before committing.

Fix with: sops -e -i hosts/mbp-work/secrets.yaml
Or use:   edit-secrets

Commit blocked.
```

### Warning Message

```bash
$ git commit -m "Update config"
🔍 Validating secrets and credentials...
  ✅ No blocked credential files
  ✅ SOPS secrets encrypted
  ⚠️  WARNING: Insecure permissions detected:
     - /Users/jimmy/.tokens/api_key (644, should be 600)

  Fix with: chmod 600 /Users/jimmy/.tokens/api_key

✅ Validation complete (with warnings)
[main abc123] Update config
```

### Info Message

```bash
$ health-check
🏥 System Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Critical systems healthy
⚠️  2 warnings found
ℹ️  3 optimization suggestions:
   - 5 package updates available (run: update-nix)
   - Homebrew cleanup recommended (run: brew cleanup)
   - Consider enabling zsh autosuggestions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Monitoring and Metrics

Track warning system effectiveness:
- **Resolution rate**: % warnings fixed within 7 days
- **Bypass rate**: Frequency of `--no-verify` usage
- **Escalation tracking**: Warnings promoted to errors
- **Warning fatigue**: Repeat warnings per user

## Severity Upgrade Path

Process for escalating warning to error:

1. **Identify pattern**: Warning frequently ignored (>30 days unresolved)
2. **Measure impact**: Assess security/functionality impact
3. **Communicate change**: Announce upcoming enforcement
4. **Grace period**: 2 weeks warning before error enforcement
5. **Upgrade**: Change warning to error with clear messaging

## References

- [ADR-003: Git Hooks Enforcement](ADR-003-git-hooks-enforcement.md)
- [ADR-005: Health Check Architecture](ADR-005-health-check-architecture.md)
- [User Experience Guidelines](https://www.nngroup.com/articles/error-message-guidelines/)

## Revision History

- **2024-11-07**: Initial decision - Three-tier validation system (Error/Warning/Info)
