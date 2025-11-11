# Warning System Design Documentation

## Overview

The warning system provides reusable confirmation prompts and warning messages for high-risk operations in nix-darwin. It implements a defense-in-depth approach to prevent accidental destructive operations.

**Created**: 2025-11-06
**Location**: `lib/warnings.nix` + `home/jimmy/shell/zsh.nix`

## Design Philosophy

### Core Principles

1. **Progressive Disclosure**: Information is revealed based on risk level
2. **Explicit Confirmation**: High-risk operations require typed confirmation
3. **Visual Hierarchy**: Color and emoji convey urgency without reading
4. **Escape Hatches**: Skip flags for automation and experienced users
5. **Consistency**: Same patterns across all risky operations

### Warning Levels

| Level | Emoji | Use Case | Confirmation |
|-------|-------|----------|--------------|
| **INFO** | ℹ️ | Educational notices | None |
| **WARNING** | ⚠️ | Reversible but significant operations | Yes/No |
| **CRITICAL** | 🚨 | Irreversible or destructive operations | Type keyword |

## Architecture

### Two-Layer System

```
┌─────────────────────────────────────┐
│  Nix Layer (lib/warnings.nix)       │
│  - Pure functions                   │
│  - String generators                │
│  - Configuration                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Shell Layer (zsh.nix)              │
│  - Runtime functions                │
│  - User interaction                 │
│  - Operation wrappers               │
└─────────────────────────────────────┘
```

### Nix Layer Functions

**Message Generators**:
- `mkWarningMessage level message` - Single line warning
- `mkDetailedWarning level title details` - Multi-line with bullets
- `mkConfirmPrompt question` - Yes/No confirmation
- `mkConfirmPromptDefaultYes question` - Default to Yes
- `mkTimedConfirm seconds question` - Auto-proceed timeout

**Operation Wrappers**:
- `mkRiskyOperation { level, message, details, command, skipFlag }` - Standard risky operation
- `mkCriticalOperation { message, warningText, confirmText, command }` - Requires typed keyword
- `mkPreFlightCheck { name, check, failureMessage, level, continueOnFailure }` - Pre-execution validation
- `mkPreFlightChecks [checks]` - Multiple validations

**Specialized Warnings**:
- `mkNixRebuildWarning { showDiff }` - System rebuild warnings
- `mkCleanupWarning { cleanupType }` - Cleanup operation warnings
- `mkSecretsWarning` - Secrets editing warnings
- `mkGitForceWarning { operation }` - Git force operation warnings

### Shell Layer Functions

**Basic Helpers** (in `zsh.nix`):

```bash
# Display warning message
warn "MESSAGE" [LEVEL]

# Confirm action with user
confirm "Question?" && command

# Wrap risky command with confirmation
risky "WARNING" "This is dangerous" command args...

# Critical operation requiring explicit confirmation
critical "DELETE" "This will delete everything" command args...
```

## Implementation Examples

### Example 1: Cleanup Aggressive

**Before**:
```bash
function cleanup-aggressive() {
  # Immediately starts cleanup
  echo "Cleaning up..."
  rm -rf /path/to/data
}
```

**After**:
```bash
function cleanup-aggressive() {
  # Show critical warning unless --yes flag
  if [[ "$yes_flag" != "true" ]]; then
    echo ""
    echo "🚨 AGGRESSIVE CLEANUP"
    echo "⚠️  DESTRUCTIVE OPERATION - Will permanently delete:"
    echo "  • Nix store garbage and old generations"
    echo "  • All tool caches (Ollama models, LLM caches)"
    echo "  • Development artifacts (node_modules, .venv, builds)"
    echo ""
    read -r "confirmation?Type 'DELETE' to confirm: "

    if [[ "$confirmation" != "DELETE" ]]; then
      echo "❌ Operation cancelled (incorrect confirmation)"
      return 1
    fi
  fi

  # Proceed with cleanup...
}
```

### Example 2: Secrets Editing

**Before**:
```bash
function edit-secrets() {
  sops "$secrets_file"
}
```

**After**:
```bash
function edit-secrets() {
  # Show informational warning
  warn "Editing Encrypted Secrets" "INFO"
  echo "  • File will be decrypted temporarily"
  echo "  • Changes will be re-encrypted on save"
  echo "  • Make sure SOPS keys are configured correctly"
  echo ""

  sops "$secrets_file"
}
```

### Example 3: Nix Rebuild

**New Function**:
```bash
function nix-rebuild-confirm() {
  warn "System Rebuild" "WARNING"
  echo "  • This will rebuild your entire system configuration"
  echo "  • Changes will be applied immediately"
  echo "  • Previous generation available for rollback"
  echo ""

  if confirm "Proceed with rebuild?"; then
    # Run pre-flight checks and rebuild
  else
    echo "❌ Rebuild cancelled"
    return 1
  fi
}
```

## Protected Operations

### Current Implementation

| Operation | Risk Level | Protection | Skip Flag |
|-----------|-----------|------------|-----------|
| `cleanup-aggressive` | CRITICAL | Type "DELETE" | `--yes` |
| `edit-secrets` | INFO | Informational notice | None |
| `nix-rebuild-confirm` | WARNING | Yes/No + Pre-flight | None |

### Future Candidates

| Operation | Proposed Level | Reason |
|-----------|---------------|--------|
| `git push --force` | CRITICAL | Overwrites remote history |
| `nix-collect-garbage -d` | WARNING | Deletes old generations |
| `docker system prune -a` | WARNING | Removes all unused images |
| `brew cleanup --prune=all` | WARNING | Aggressive cache cleanup |

## Usage Guidelines

### When to Use Each Level

**INFO** ℹ️:
- Educational purposes
- First-time operation guidance
- Important but non-destructive
- Example: Editing encrypted files

**WARNING** ⚠️:
- Significant system changes
- Operations with rollback available
- Resource-intensive operations
- Example: System rebuilds, major updates

**CRITICAL** 🚨:
- Irreversible data loss
- Affects production systems
- Multi-user impact
- Example: Aggressive cleanup, force push

### Best Practices

1. **Always provide context**: Explain what will happen
2. **Offer alternatives**: Suggest --dry-run or safer options
3. **Be specific**: List exactly what will be affected
4. **Stay consistent**: Use same patterns for similar operations
5. **Test warnings**: Verify readability and clarity

### Anti-Patterns

❌ **Don't**:
- Add warnings to fast, frequently-used commands
- Make warnings too verbose (TL;DR effect)
- Use CRITICAL for reversible operations
- Skip warnings in scripts without --yes flag
- Make confirmations too easy to bypass

✅ **Do**:
- Reserve warnings for truly risky operations
- Keep messages concise and actionable
- Provide escape hatches (--yes, --force)
- Test user experience with fresh eyes
- Document all protected operations

## Testing

### Manual Testing Checklist

```bash
# Test INFO level (edit-secrets)
edit-secrets
# Should show ℹ️ INFO with guidance

# Test WARNING level (nix-rebuild-confirm)
nix-rebuild-confirm
# Should prompt Yes/No, allow cancellation

# Test CRITICAL level (cleanup-aggressive)
cleanup-aggressive
# Should require typing "DELETE"

# Test skip flags
cleanup-aggressive --yes
# Should skip confirmation

# Test dry-run integration
cleanup-aggressive --dry-run
# Should preview without executing
```

### Validation Criteria

- [ ] Warning appears before risky operation
- [ ] Emoji and color-coding are correct
- [ ] Confirmation works (accepts y/Y, rejects n/N)
- [ ] Critical operations require exact keyword
- [ ] Skip flags work as documented
- [ ] Error messages are clear
- [ ] Operation cancels cleanly on rejection

## Extension Points

### Adding New Protected Operation

1. **Choose warning level** based on risk and reversibility
2. **Add to function** using helper functions:
   ```bash
   function my-risky-operation() {
     warn "Operation Name" "WARNING"
     echo "  • What it does"
     echo "  • Why it's risky"
     echo ""

     if confirm "Proceed?"; then
       # Do operation
     else
       echo "❌ Operation cancelled"
       return 1
     fi
   }
   ```
3. **Test thoroughly** with confirmation and cancellation
4. **Document** in this file and user-facing docs

### Custom Warning Templates

For repeated patterns, create specialized generators in `lib/warnings.nix`:

```nix
# Example: Warning for database operations
mkDatabaseWarning = { operation, database }:
  mkRiskyOperation {
    level = "CRITICAL";
    message = "Database ${operation}";
    details = [
      "Will modify database: ${database}"
      "Backup recommended before proceeding"
      "Operation cannot be rolled back"
    ];
    command = ""; # Filled by caller
  };
```

## Performance Impact

### Overhead Analysis

- **Nix layer**: Zero runtime cost (compile-time only)
- **Shell layer**: Negligible (<100ms for user interaction)
- **User experience**: Improved safety vs. minor delay tradeoff

### Optimization Strategies

1. **Lazy loading**: Warnings only shown when operation runs
2. **Skip flags**: Automation can bypass with `--yes`
3. **Caching**: No repeated warnings in same session
4. **Minimal dependencies**: Pure shell functions, no external tools

## Future Enhancements

### Planned Features

1. **Warning history**: Log all risky operations attempted
2. **Undo hints**: Suggest rollback commands after operations
3. **Dry-run integration**: Auto-suggest --dry-run for new users
4. **Context-aware warnings**: Adjust based on system state
5. **Machine learning**: Learn user patterns, reduce noise

### Integration Opportunities

- **Pre-commit hooks**: Warn about committing secrets
- **CI/CD**: Different warning levels for production
- **Monitoring**: Track confirmation bypass patterns
- **Analytics**: Measure warning effectiveness

## Metrics & Success Criteria

### Quantitative Metrics

- **Prevented accidents**: Operations cancelled via warnings
- **User satisfaction**: Feedback on warning usefulness
- **False positives**: Unnecessary warnings that annoy users
- **Bypass rate**: How often --yes is used vs. normal flow

### Success Indicators

✅ **Good signs**:
- Users understand warnings without reading docs
- Confirmations feel appropriate to risk level
- Dry-run is used before destructive operations
- No accidental data loss from warned operations

⚠️ **Warning signs**:
- Users always use --yes to skip warnings
- Complaints about "too many confirmations"
- Warnings ignored due to length/complexity
- Accidents still happen despite warnings

## Maintenance

### Regular Reviews

- **Monthly**: Check for new risky operations to protect
- **Quarterly**: User feedback survey on warning usefulness
- **Yearly**: Major refactor based on lessons learned

### Documentation Updates

When adding new protected operations:
1. Update this design doc (Protected Operations section)
2. Update user-facing docs (QUICK-REFERENCE.md)
3. Add examples to relevant guides
4. Update CHANGELOG.md

---

**Version**: 1.0.0
**Last Updated**: 2025-11-06
**Maintainer**: @jimmy-jain
