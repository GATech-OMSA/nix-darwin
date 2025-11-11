# ADR-003: Git Hooks Enforcement

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The system manages sensitive information:

- SOPS-encrypted secrets in `hosts/*/secrets.yaml`
- Git-ignored credentials in `~/.db/`, `~/.tokens/`, `~/.aws/`
- User-specific configuration files

### Security Risks Identified

1. **Accidental plaintext secret commits**: Editing `secrets.yaml` with SOPS but forgetting to encrypt
2. **Credential file staging**: Accidentally staging `~/.tokens/*` or database credentials
3. **Insecure permissions**: Credential files with world-readable permissions (644 instead of 600)
4. **Multiple secret locations**: Secrets in both `hosts/*/` and `user-data/secrets/`

### Previous Incidents

- Plaintext secrets committed when SOPS editor failed
- Database credentials accidentally staged during `git add .`
- API tokens discovered with 644 permissions

## Decision

**Implement automated git hooks with multi-layered validation.**

### Hook Strategy

```
Pre-commit hook (primary defense):
├─ Block: Staging of blocked credential paths
├─ Validate: SOPS secrets are binary (encrypted)
├─ Warn: File permissions on credentials (600 required)
└─ Exit: Non-zero on blocked files, continue on warnings

Pre-push hook (final defense):
├─ Re-run all pre-commit checks
├─ Block: Any validation failures before push
└─ Exit: Non-zero on any issues
```

### Validation Layers

**Layer 1: Path Blocking**
- Block staging of `~/.db/*`, `~/.tokens/*`, `~/.aws/credentials`
- Block staging of `user-data/secrets/*`
- Fail fast with clear error message

**Layer 2: SOPS Encryption Validation**
- Check `hosts/*/secrets.yaml` files are binary
- Detect plaintext YAML (starts with `#` or `---`)
- Block commit if plaintext detected

**Layer 3: Permission Auditing**
- Warn if credential files have insecure permissions
- Check 600 permissions on all credential files
- **Non-blocking**: Warning only, allow commit to continue

## Consequences

### Positive

✅ **Prevents secret leakage**: Multiple validation layers catch mistakes
✅ **Zero-config security**: Works automatically on clone
✅ **Clear error messages**: Developers know exactly what's wrong
✅ **Fast feedback**: Catches issues before commit, not after push
✅ **Multiple locations**: Validates both hosts/ and user-data/ paths
✅ **Permission awareness**: Reminds developers of security requirements
✅ **Dual validation**: Pre-commit AND pre-push for defense-in-depth

### Negative

⚠️ **Can block workflow**: Developers must fix issues before commit
⚠️ **Manual bypass possible**: `--no-verify` flag skips hooks
⚠️ **Permission warnings non-blocking**: Insecure permissions allow commit
⚠️ **Requires git**: Won't catch issues in manual file operations

### Design Rationales

**Why warnings for permissions?**
- Permissions are often changed by system processes
- Blocking commits on permissions too disruptive
- Warning provides awareness without workflow interruption
- Can be upgraded to blocking in future if needed

**Why dual hooks (pre-commit + pre-push)?**
- Pre-commit: Fast feedback, catch most issues
- Pre-push: Final safety net, prevents accidental bypass
- Defense in depth: Multiple chances to catch issues

## Alternatives Considered

### Alternative 1: Server-Side Hooks

GitHub/GitLab server-side hooks for validation.

**Rejected because**:
- ❌ Secrets already pushed by the time server validates
- ❌ Requires server access/configuration
- ❌ Personal repo may not have server-side hooks
- ❌ Slower feedback (after push vs before commit)

### Alternative 2: CI/CD Validation

GitHub Actions to validate commits.

**Rejected because**:
- ❌ Runs after push (secrets already exposed)
- ❌ Slower feedback loop
- ❌ Requires GitHub Actions setup
- ❌ Can't prevent bad commits, only detect

### Alternative 3: Pre-Receive Hooks

Git pre-receive hooks on remote.

**Rejected because**:
- ❌ Runs on push (too late for plaintext secrets)
- ❌ Requires server-side setup
- ❌ Not available on personal GitHub repos
- ❌ Secrets already in local git history

### Alternative 4: IDE Integration

Editor plugins for validation.

**Rejected because**:
- ❌ Requires manual IDE configuration
- ❌ Not all developers use same editor
- ❌ Easy to forget or disable
- ❌ No enforcement for command-line git users

### Alternative 5: Block All Commits with Secrets

Reject any commit touching secret files.

**Rejected because**:
- ❌ Prevents legitimate encrypted secret updates
- ❌ Too restrictive for normal workflow
- ❌ Can't update SOPS secrets at all
- ❌ Forces manual workarounds

## Implementation Notes

### Hook Installation

Hooks are installed automatically on first `darwin-rebuild`:

```nix
# modules/darwin/system.nix
system.activationScripts.postActivation.text = ''
  # Install git hooks
  if [[ -f "${config.users.users.jimmy.home}/.git/hooks/pre-commit" ]]; then
    chmod +x "${config.users.users.jimmy.home}/.git/hooks/pre-commit"
    chmod +x "${config.users.users.jimmy.home}/.git/hooks/pre-push"
  fi
'';
```

### Hook Logic

**Pre-commit hook**:
```bash
#!/bin/bash
# 1. Check for blocked credential files
blocked_files=$(git diff --cached --name-only | grep -E '(\.db/|\.tokens/|\.aws/credentials|user-data/secrets/)')
if [[ -n "$blocked_files" ]]; then
  echo "❌ Blocked: Cannot commit credential files"
  exit 1
fi

# 2. Validate SOPS encryption
for file in $(git diff --cached --name-only | grep 'secrets\.yaml$'); do
  if head -n 1 "$file" | grep -q '^#\|^---'; then
    echo "❌ Plaintext secret detected in $file"
    exit 1
  fi
done

# 3. Check permissions (warning only)
for file in ~/.db/* ~/.tokens/* ~/.aws/credentials; do
  if [[ -f "$file" ]]; then
    perms=$(stat -f "%Lp" "$file")
    if [[ "$perms" != "600" ]]; then
      echo "⚠️  Warning: $file has permissions $perms (should be 600)"
    fi
  fi
done

exit 0
```

### Bypassing Hooks

**When bypass is acceptable**:
- Testing hook changes themselves
- Emergency commits during outage
- Automated CI/CD processes

**How to bypass**:
```bash
git commit --no-verify -m "emergency fix"
```

**Warning**: Bypass should be rare and documented in commit message.

### Testing Hooks

```bash
# Test blocked file staging
echo "test" > ~/.tokens/test_token
git add ~/.tokens/test_token
git commit -m "test"
# Should fail with blocked file error

# Test SOPS plaintext detection
echo "# plaintext" > hosts/mbp-work/secrets.yaml
git add hosts/mbp-work/secrets.yaml
git commit -m "test"
# Should fail with plaintext secret error

# Test permission warning
chmod 644 ~/.tokens/api_key
git commit -m "test"
# Should show warning but allow commit
```

## Validation Coverage

| Risk | Detection Method | Action | Timing |
|------|-----------------|--------|--------|
| Plaintext secrets | Binary file check | Block | Pre-commit |
| Credential staging | Path pattern match | Block | Pre-commit |
| Insecure permissions | Permission audit | Warn | Pre-commit |
| Bypass attempts | Duplicate checks | Block | Pre-push |

## User Experience

### Success Case

```bash
$ git commit -m "Update configuration"
🔍 Validating secrets and credentials...
  🛡️  Checking for blocked credential files...
  🔐 Validating SOPS encryption...
  🔒 Validating file permissions...
✅ All security checks passed
[main abc123] Update configuration
```

### Blocked Credential

```bash
$ git add ~/.tokens/api_key
$ git commit -m "Update config"
🔍 Validating secrets and credentials...
  🛡️  Checking for blocked credential files...
❌ BLOCKED: Cannot commit credential files:
   - /Users/jimmy/.tokens/api_key

These files are protected and should not be committed.
Remove from staging with: git reset HEAD <file>
```

### Plaintext Secret

```bash
$ git commit -m "Update secrets"
🔍 Validating secrets and credentials...
  🔐 Validating SOPS encryption...
❌ BLOCKED: Plaintext secret detected in hosts/mbp-work/secrets.yaml
Secrets must be encrypted with SOPS before committing.

Fix with: sops -e -i hosts/mbp-work/secrets.yaml
Or use:   edit-secrets
```

### Permission Warning

```bash
$ git commit -m "Update config"
🔍 Validating secrets and credentials...
  🔒 Validating file permissions...
⚠️  WARNING: Insecure permissions detected:
   - /Users/jimmy/.tokens/api_key (644, should be 600)

Fix with: chmod 600 /Users/jimmy/.tokens/api_key

✅ Validation complete (with warnings)
[main abc123] Update config
```

## Monitoring and Metrics

Track hook effectiveness:
- Number of blocked commits per month
- Types of violations caught
- Permission warnings issued
- Bypass frequency (`--no-verify` usage)

## Future Enhancements

**Potential improvements**:
1. **Strict mode**: Make permission warnings blocking
2. **Automated fixing**: Auto-chmod credential files to 600
3. **Secret scanning**: Detect secret patterns in diffs
4. **Encryption helper**: Auto-encrypt on save
5. **Audit logging**: Track validation events

## References

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [SOPS Documentation](https://github.com/getsops/sops)
- [Security Features](../../../CLAUDE.md#security-features)
- [Secrets Guide](../../guides/secrets.md)

## Revision History

- **2024-11-07**: Initial decision - Multi-layer git hook validation
