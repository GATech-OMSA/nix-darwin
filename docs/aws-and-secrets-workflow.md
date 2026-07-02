# AWS & Secrets Reference

Daily commands and architecture for AWS multi-account SSO and secrets management.

---

## AWS Commands

### Quick reference

```bash
awslogin <project|alias> <env> [role]   # SSO login (creates profile if missing)
awsuse   <project|alias> <env> [role]   # Switch profile (no login)
awswho                                  # Show current profile + identity
awslist                                 # List all accounts from accounts.json
awsfind  <query>                        # Search by name/alias/env/role
awswhere <account-id>                   # Reverse lookup by account ID
awscheck                                # Check SSO session status
awsfilter <type> <value>                # Filter by project/env/role
```

### Role abbreviations

| Short | Expands to |
|-------|-----------|
| `dev` | `developer` |
| `ds` | `data-scientist` |
| `de` | `data-engineer` |
| `da` | `data-analyst` |

Any other string (e.g., `admin`, `support`, `readonly`) is used as-is.
If omitted, the `default_role` from `accounts.json` is used.

### Examples

```bash
awslogin hft dev              # Login to hft dev (developer role — default)
awslogin hft dev admin        # Login to hft dev (admin role)
awsuse gen dev                # Switch to genesis dev (no login)
awsfind hft                   # Find all hft profiles
awswhere 072583797108         # Find project by account ID
```

### How profiles are created

`awslogin` reads `~/.aws/accounts.json` at runtime. If the profile doesn't
exist in `~/.aws/config`, it creates it dynamically from the account data
and SSO session, then opens the browser for SSO login.

No rebuild needed — edit `accounts.json`, run `awslogin`, done.

### Profile naming convention

```
<project>-<env>              # default role (omits suffix)
<project>-<env>-<role>       # non-default role
```

Example: project `hft` with `default_role: "developer"`:
- `hft-dev` — developer role (default, no suffix)
- `hft-dev-admin` — admin role (suffix added)

### Profile auto-restore

The last-used profile is saved to `~/.aws/.last_profile` and restored on
every new shell:

```
aws: hft-dev (restored)
```

---

## accounts.json

**Location:** `~/.aws/accounts.json` (machine-local, not in repo)

**Created by:** `configure.sh` from template, or manually

### Schema

```json
{
  "project-name": {
    "alias": "pn",
    "description": "Human-readable project description",
    "default_role": "developer",
    "default_region": "us-east-1",
    "accounts": {
      "dev": {
        "id": "111111111111",
        "region": "us-east-1",
        "additional_roles": ["admin", "data-engineer"]
      },
      "prod": {
        "id": "222222222222",
        "region": "us-east-1"
      }
    }
  }
}
```

**Fields:**
- `alias` — short name for CLI (optional, but enables `awsuse pn dev` shorthand)
- `default_role` — used when role argument is omitted
- `additional_roles` — extra roles listed by `awslist` and `awsfind`
- Account values can be objects (with `id`, `region`, `additional_roles`) or plain strings (just the account ID)

### Adding a new account

```bash
vim ~/.aws/accounts.json      # Add project + accounts
awslogin new-project dev      # Creates profile + logs in
awslist                       # Verify it shows up
```

No rebuild needed.

---

## ~/.aws/config

**Managed by:** `nix-config/home/_profiles/_template/programs/aws.nix`

On rebuild, writes the SSO session stanza + `[default]` section only.
Individual account profiles are created on-demand by `awslogin` at runtime.

```ini
[default]
region = us-east-1
output = json

[sso-session sso-personal]
sso_start_url = https://d-xxxxxxxxxx.awsapps.com/start/
sso_region = us-east-1
sso_registration_scopes = sso:account:access
duration_seconds = 57600

# Per-account profiles created by awslogin below
[profile hft-dev]
sso_session = sso-personal
sso_account_id = 072583797108
...
```

Work profile adds `ca-bundle = ~/.config/certs/cacert.pem` to the SSO session.

A backup is created at `~/.aws/backup/config-<timestamp>` before any overwrite.

---

## Secrets Commands

```bash
secrets-edit      # Edit encrypted secrets.yaml (SOPS)
secrets-deploy    # Decrypt + deploy to target paths (no rebuild needed)
respin    # Re-source ~/.zsh_secrets in current shell
secrets-status    # Show age key, encryption, tools, deployed secrets
secrets-rescan    # Discover unmanaged secrets (read-only)
secrets-view      # View decrypted secrets (read-only)
secrets-backup    # Create timestamped backup
secrets-audit     # Scan system for plaintext credential exposure
secrets-local     # Manage temporary testing overrides
```

### Workflow

```
secrets-edit  →  secrets-deploy  →  respin
  (edit yaml)     (decrypt+write)    (re-source shell)
```

All three steps work without `nix-rebuild`. On rebuild, `secrets-deploy`
runs automatically via Home Manager activation hook.

### Secret mappings

Defined in `scripts/secrets/deploy-secrets.sh` — single source of truth.
Both profiles use the same script. Keys not in a machine's `secrets.yaml`
are silently skipped.

```bash
# Shell secrets
zsh_secrets         → ~/.zsh_secrets

# SSH keys (personal)
ssh_private_key     → ~/.ssh/id_ed25519
ssh_public_key      → ~/.ssh/id_ed25519.pub

# SSH keys (work)
work_ssh_private_key     → ~/.ssh/id_ed25519_work
work_ssh_public_key      → ~/.ssh/id_ed25519_work.pub

# AWS
aws_credentials     → ~/.aws/credentials
aws_accounts        → ~/.aws/accounts.json

# API tokens, service credentials, etc.
```

### Adding a new secret

```bash
secrets-edit                          # 1. Add key + value to secrets.yaml
# Edit scripts/secrets/deploy-secrets.sh  # 2. Add mapping line
secrets-deploy                        # 3. Deploy
respin                        # 4. Re-source if shell var
```

### Hot reload

```bash
# Test credentials without touching encrypted secrets
secrets-local add OPENAI_API_KEY "sk-test-..."   # Persist + apply now
secrets-local add FEATURE_FLAG "1"               # Add another override
# ... test ...
secrets-local unset FEATURE_FLAG
secrets-local rm        # Clean up
```

```bash
# Local zsh aliases/overrides without rebuild
zsh-local alias add ccr "claude --resume"
zsh-local alias add "cc!" "claude --dangerously-skip-permissions"
zsh-local alias rm ccr
```

`secrets-local` writes to `~/.zsh_secrets.local` and reapplies secrets to the
current shell. `zsh-local` writes to `~/.zshrc.local`, which is sourced at the
end of shell startup and can also be reloaded manually.

### Encryption

Secrets stored in `nix-config/hosts/{machineId}/secrets.yaml` (SOPS encrypted with age).

Each profile has its own age key:
- Personal: `.*-personal/secrets.yaml` encrypted with `&personal_key`
- Work: `.*-work/secrets.yaml` encrypted with `&work_key`

Configured in `.sops.yaml` at repo root.

---

## Architecture

```
~/.aws/accounts.json          accounts.json (machine-local)
        │                            │
        │ [runtime]                  │ [runtime]
        ▼                            ▼
  awslogin/awsuse             secrets-deploy
  (reads with jq)             (decrypts with sops+yq)
        │                            │
        ▼                            ▼
  ~/.aws/config               ~/.zsh_secrets, ~/.ssh/*, ~/.db/*
  (SSO profiles)              (deployed secrets)
        │                            │
        ▼                            ▼
  AWS CLI                     Shell environment
```

### Key files

| File | Purpose |
|------|---------|
| `~/.aws/accounts.json` | Account IDs, roles, environments |
| `~/.aws/config` | AWS CLI profiles (SSO session + per-account) |
| `nix-config/hosts/{id}/secrets.yaml` | Encrypted secrets (SOPS) |
| `scripts/secrets/deploy-secrets.sh` | Secret mappings + deploy logic |
| `nix-config/lib/aws-helpers.nix` | Shell functions (awsuse, awslogin, etc.) |
| `nix-config/home/_profiles/_template/programs/aws.nix` | Generates ~/.aws/config SSO session |
| `nix-config/lib/reload-helpers.nix` | Hot reload functions |
| `config/user-config.nix` | SSO URL, region, proxy settings |

---

## Troubleshooting

### AWS profile not working

```bash
awswho                        # Check current profile
awscheck                      # Check all SSO sessions
awslogin <project> <env>      # Re-login if expired
```

### Secrets not loading

```bash
secrets-status                # Check age key, encryption, deployed files
secrets-deploy                # Re-deploy
respin                # Re-source in current shell
```

### Profile not found after awslogin

```bash
# awslogin creates profiles dynamically. If it fails:
cat ~/.aws/config | grep "sso-session"   # SSO session must exist
jq . ~/.aws/accounts.json               # Verify JSON syntax
```

### New account not showing in awslist

```bash
# awslist reads ~/.aws/accounts.json at runtime
jq . ~/.aws/accounts.json     # Check if entry exists
# No rebuild needed — just edit the file
```
