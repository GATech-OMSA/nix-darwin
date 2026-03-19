# ADR-002: Secret Management Consolidation

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The system manages multiple types of secrets and credentials:

1. **SOPS-encrypted secrets** (`hosts/*/secrets.yaml`)
2. **Git-ignored credentials** (`~/.db/`, `~/.tokens/`, `~/.aws/credentials`)
3. **SSH keys** (`~/.ssh/`)
4. **API tokens** (various locations)

Previously, secrets were scattered across:
- `user-data/secrets/` (work tokens)
- `hosts/*/secrets.yaml` (SOPS-encrypted machine secrets)
- Various dotfiles in home directory
- Manual credential files

This created confusion about:
- **Where to store new secrets**
- **Which secrets are encrypted vs git-ignored**
- **How to backup different secret types**
- **Permission requirements for each type**

## Decision

**Consolidate to two clear secret storage patterns:**

### Pattern 1: SOPS-Encrypted Secrets (Machine-Specific)

**Location**: `hosts/*/secrets.yaml`
**For**: Machine-specific configuration secrets that need to be in Nix
**Encryption**: SOPS with age keys
**Examples**:
- AWS access keys for automation
- API tokens used in Nix config
- Machine-specific credentials

**Access**:
```bash
edit-secrets               # Edit encrypted secrets
sops -e -i hosts/mbp-work/secrets.yaml  # Manual encryption
```

### Pattern 2: Git-Ignored Credentials (User Runtime)

**Location**: Protected directories in home
**For**: Runtime credentials not needed in Nix config
**Protection**: `.gitignore` + git hooks
**Examples**:
- `~/.db/` - Database connection files
- `~/.tokens/` - API tokens for CLI tools
- `~/.aws/credentials` - AWS runtime credentials

**Required Permissions**: 600 (validated by git hooks)

### Decision Matrix

| Secret Type | Storage Location | Method | Why |
|------------|------------------|--------|-----|
| AWS keys for Nix config | `hosts/*/secrets.yaml` | SOPS | Needed during system build |
| Database credentials | `~/.db/` | Git-ignore | Runtime only, not in Nix |
| API tokens (for Nix) | `hosts/*/secrets.yaml` | SOPS | Needed during system build |
| API tokens (CLI tools) | `~/.tokens/` | Git-ignore | Runtime only, not in Nix |
| SSH keys | `~/.ssh/` | Git-ignore | Standard location, runtime |
| GitHub token | `~/.tokens/git_token` | Git-ignore | Runtime only, not in Nix |

## Consequences

### Positive

✅ **Clear decision tree**: "Is it needed in Nix? → SOPS. Runtime only? → Git-ignore"
✅ **Single source of truth**: One place per secret type
✅ **Better security**: SOPS encryption + git hook validation
✅ **Easier backup**: Two clear backup strategies
✅ **No duplication**: Secrets stored once, referenced where needed
✅ **Better documentation**: Clear guidelines for new secrets
✅ **Automated validation**: Git hooks prevent accidental commits

### Negative

⚠️ **Two different backup procedures**: SOPS secrets vs credential files
⚠️ **Permission management**: Must maintain 600 on credential files
⚠️ **Learning curve**: Users must understand the distinction

### Migration Impact

**Removed**: `user-data/secrets/` directory (consolidated into git-ignored locations)
**Added**: Git hooks for credential protection
**Updated**: Documentation to reflect new patterns

## Alternatives Considered

### Alternative 1: Everything in SOPS

Store all secrets in `hosts/*/secrets.yaml`.

**Rejected because**:
- ❌ SOPS files are versioned (larger repo)
- ❌ Unnecessary complexity for runtime-only secrets
- ❌ Harder to manage developer tokens
- ❌ All secrets tied to Nix rebuild cycle

### Alternative 2: Everything Git-Ignored

No SOPS, just git-ignore everything.

**Rejected because**:
- ❌ No version control for machine configuration
- ❌ No encryption at rest
- ❌ Can't share encrypted config between machines
- ❌ Harder disaster recovery

### Alternative 3: Separate Secret Repository

Store all secrets in a separate private repo.

**Rejected because**:
- ❌ Additional repository to maintain
- ❌ Synchronization complexity
- ❌ Harder to track config-secret relationships
- ❌ More setup steps for new machines

### Alternative 4: Cloud Secret Manager

Use AWS Secrets Manager, HashiCorp Vault, etc.

**Rejected because**:
- ❌ External dependency for personal config
- ❌ Network required for system rebuild
- ❌ Additional cost and complexity
- ❌ Offline use breaks

## Implementation Notes

### Adding a New Secret

**Decision flowchart**:

```
Is the secret needed during Nix system build?
├─ YES → Add to hosts/*/secrets.yaml (SOPS)
│         edit-secrets
│         Add key-value pair
│         Save (auto-encrypts)
│
└─ NO → Add to appropriate git-ignored location
          ~/.db/         - Database credentials
          ~/.tokens/     - API tokens
          ~/.aws/        - AWS credentials
          chmod 600 <file>
```

### Secret Access Patterns

**In Nix config**:
```nix
# Access SOPS secret
config.sops.secrets."aws/access_key".path
```

**In shell scripts**:
```bash
# Access git-ignored credential
cat ~/.tokens/api_key
cat ~/.db/oracle/prod
```

### Backup Strategy

**SOPS secrets**: Included in git (encrypted)
```bash
git push  # Backs up encrypted secrets
```

**Git-ignored credentials**: Manual backup
```bash
# Use user-data backup system
sync-user-data  # Backs up VS Code settings, not secrets
# OR manual backup
tar czf backup.tar.gz ~/.db ~/.tokens ~/.aws/credentials
```

## Security Validation

Git hooks validate both secret types:

```bash
# Pre-commit hook checks:
# 1. SOPS secrets are binary (encrypted)
# 2. No credential files in staging
# 3. Credential files have 600 permissions (warning)
```

## Documentation Updates

Updated documentation to reflect consolidation:

- [Secrets Guide](../../guides/secrets.md) - Complete secret management
- [Backup & Recovery](../../guides/backup-and-recovery.md) - Backup procedures
- [Security Features](../../../../CLAUDE.md#security-features) - Git hook validation

## References

- [SOPS Documentation](https://github.com/getsops/sops)
- [Secrets Guide](../../guides/secrets.md)
- [Security Features](../../../../CLAUDE.md#security-features)

## Revision History

- **2024-11-07**: Initial decision - Two-pattern consolidation
