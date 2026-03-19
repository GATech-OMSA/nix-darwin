# Scripts Directory

Utility scripts for nix-darwin system maintenance, setup, validation, and testing.

## Directory Structure

```
scripts/
├── app-catalog/      # Homebrew app management
├── docs/             # This README
├── maintenance/      # System maintenance and diagnostics
├── profiles/         # Profile switching
├── secrets/          # SOPS secrets management
├── setup/            # Initial machine setup (3-script workflow)
├── testing/          # Test suites
├── validation/       # Configuration validation
└── workspace/        # User data backup/restore
```

---

## Setup (`scripts/setup/`)

Three-script installation workflow (see `docs/installation.md`):

| Script | Purpose | Step |
|--------|---------|------|
| `bootstrap.sh` | Install Nix, Homebrew, prerequisites | 1 |
| `configure.sh` | Generate machine config, scan secrets | 2 |
| `activate.sh` | Build and activate nix-darwin | 3 |

Additional:
- `scaffold-new-machine.sh` — Create new host config from template
- `migrate-homebrew-to-nix.sh` — Audit and migrate Homebrew packages to Nix

---

## Maintenance (`scripts/maintenance/`)

| Script | Purpose | Alias |
|--------|---------|-------|
| `rebuild.sh` | Smart rebuild with pre-flight checks and rollback | `nix-rebuild` |
| `pre-flight-checks.sh` | Validate system health before rebuilds | `nix-preflight` |
| `health-check.sh` | Comprehensive system diagnostics | `nix-health` |
| `config-diff.sh` | Compare generations (packages, configs) | `nix-config-diff` |
| `system-cleanup.sh` | Interactive guided cleanup (Nix, Brew, Docker) | `just cleanup` |
| `verify-backups.sh` | Validate backup completeness and freshness | `nix-verify-backups` |
| `brew-nix-audit.sh` | Check Homebrew apps for Nix alternatives | `nix-brew-audit` |
| `count-docs.sh` | Documentation file statistics | — |

---

## Secrets (`scripts/secrets/`)

| Script | Purpose | Alias |
|--------|---------|-------|
| `edit-secrets.sh` | Safe SOPS editing with auto-backup | `secrets-edit` |
| `view-secrets.sh` | Read-only decrypted secrets view | `secrets-view` |
| `rescan-secrets.sh` | Scan for new secrets, add to SOPS | `secrets-rescan` |
| `backup-secrets.sh` | Timestamped secrets.yaml backup | `secrets-backup` |
| `audit-secrets.sh` | System-wide secret scanning | `secrets-audit` |

---

## Validation (`scripts/validation/`)

| Script | Purpose |
|--------|---------|
| `audit-permissions.sh` | Check credential file permissions (600) |
| `check-secrets-encrypted.sh` | Verify SOPS encryption (used by git hooks) |
| `validate-aws-config.sh` | Validate AWS multi-role configuration |
| `validate-docs.sh` | Documentation link validation |
| `validate-machine-config.sh` | Check machine-config.nix syntax |
| `validate-secret-registry.sh` | Validate secret registry and SOPS setup |

---

## Testing (`scripts/testing/`)

| Script | Purpose |
|--------|---------|
| `test-aws-helpers.sh` | Test AWS helper functions and aliases |
| `test-git-hooks.sh` | Test git hooks for credential protection |

---

## Workspace (`scripts/workspace/`)

| Script | Purpose |
|--------|---------|
| `backup.sh` | Back up app configs and user content |
| `restore.sh` | Restore from workspace backup |

---

## Other

| Script | Purpose |
|--------|---------|
| `app-catalog/install-apps.sh` | Manage Homebrew apps from catalog |
| `profiles/switch-profile.sh` | Switch between personal/work/minimal profiles |

---

## Script Development Guidelines

1. **Shebang**: `#!/usr/bin/env bash`
2. **Strict mode**: `set -euo pipefail`
3. **Repo root**: `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"`
4. **Exit codes**: 0 = success, 1 = error, 2 = warnings only
5. **Colors**: Use standard ANSI codes (RED, GREEN, YELLOW, BLUE, NC)
6. **Permissions**: `chmod +x` all scripts
