# Secrets Management — SOPS Setup

How secrets encryption works in this repo. For daily commands and workflow, see
[AWS & Secrets Reference](aws-and-secrets-workflow.md).

---

## How It Works

```
secrets.yaml (SOPS encrypted, per-host, committed to git)
        |
        ├── [secrets-edit] ──┐
        |                    ▼
        |          (sops re-encrypt; new inode)
        |                    │
        |                    ▼
        |       ╔═══════════════════════════╗
        |       ║ launchd LaunchAgent       ║
        |       ║ WatchPaths: secrets.yaml  ║
        |       ╚═══════════════════════════╝
        |                    │
        ▼                    ▼
  [secrets-deploy] ◀── (auto-fires on save)
        │
        │  writes target files + manifest
        ▼
  ~/.zsh_secrets, ~/.ssh/*, ~/.db/*, ~/.tokens/*
  ~/.local/state/secrets-deploy/manifest

  ─────────────────────────────────────────────

  darwin-rebuild
        │
        ▼
  [verify-secrets]  ← reads manifest, checks each target
        │             exists + mode + non-empty
        │             (NEVER decrypts, NEVER writes)
        ▼
  pass → activation continues
  fail → activation aborts with the missing path
```

- **Encryption:** SOPS with age keys
- **Deployment writers (the only places that touch deployed files):**
  - `secrets-deploy` (manual, primary)
  - launchd watcher on `secrets.yaml` (auto, after `secrets-edit`)
  - `scripts/setup/activate.sh` (first-boot bootstrap)
- **Activation only verifies** — moved out of the write path on 2026-04-28
  to eliminate a corruption class (silent decrypt failure during HM activation).
- **Mappings:** defined in `deploy-secrets.sh` MAPPINGS array. Keys not in a
  machine's `secrets.yaml` are skipped, so the same script works for both
  personal and work profiles.
- **Manifest:** `~/.local/state/secrets-deploy/manifest` is the contract
  between `deploy-secrets` and `verify-secrets`. One line per deployed
  target: `target_path|mode`. Rewritten atomically on every successful deploy.

---

## Initial Setup

### 1. Generate age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### 2. Note your public key

```bash
grep "public key:" ~/.config/sops/age/keys.txt
# age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Configure .sops.yaml

The repo root `.sops.yaml` maps age keys to host paths by profile suffix:

```yaml
keys:
  - &personal_key age1pg50...
  - &work_key age1kgx3...

creation_rules:
  - path_regex: nix-config/hosts/.*-personal/secrets\.yaml$
    key_groups:
      - age:
          - *personal_key
  - path_regex: nix-config/hosts/.*-work/secrets\.yaml$
    key_groups:
      - age:
          - *work_key
```

### 4. Create or edit secrets

```bash
secrets-edit    # Opens secrets.yaml in $EDITOR via SOPS (auto-encrypts on save)
```

### 5. Deploy

```bash
secrets-deploy  # Decrypt + write to target paths
secrets-reload  # Re-source in current shell
```

---

## Adding a New Secret

1. `secrets-edit` — add key + value to secrets.yaml
2. Edit `scripts/secrets/deploy-secrets.sh` — add mapping: `"key|path|mode"`
3. The launchd watcher fires `secrets-deploy` automatically on save. If you
   skipped step 2 (or want to deploy before the watcher coalesces), run
   `secrets-deploy` manually.
4. `secrets-reload` — re-source if it's a shell variable

### Watcher behavior

- Definition: `nix-config/modules/darwin/secrets-watcher.nix`
- LaunchAgent label: `dev.nixconf.secrets-deploy-watcher`
- Throttle: 10s — coalesces rapid consecutive saves into one deploy.
- Logs: `~/.local/state/secrets-deploy/<UTC-timestamp>.log` (newest 10 kept).
- Inspect: `launchctl list | grep secrets-deploy-watcher`
- Tail latest: `ls -t ~/.local/state/secrets-deploy/*.log | head -1 | xargs cat`

---

## secrets.yaml Format

```yaml
# Shell environment (exported as env vars)
zsh_secrets: |
  export OPENAI_API_KEY="sk-..."
  export GITHUB_TOKEN="ghp_..."
  export LAN_USERNAME="jimmy"
  export LAN_PASSWORD="corp-pass"

# SSH keys (multiline block scalar)
ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----

ssh_public_key: "ssh-ed25519 AAAA... user@host"

# AWS credentials
aws_credentials: |
  [default]
  aws_access_key_id = AKIA...
  aws_secret_access_key = ...

# Database connections
mssql_prod_connection: |
  Server=sql.company.com
  Database=ProdDB
  User=jimmy
  Password=secret
```

---

## Key Rotation

```bash
# 1. Generate new age key
age-keygen -o ~/.config/sops/age/keys.txt.new

# 2. Update .sops.yaml with new public key

# 3. Re-encrypt with both old and new keys, then remove old
sops updatekeys nix-config/hosts/macbook-pro-m1-personal/secrets.yaml

# 4. Replace old key file
mv ~/.config/sops/age/keys.txt.new ~/.config/sops/age/keys.txt

# 5. Deploy
secrets-deploy
```

---

## Commands

```bash
secrets-edit      # Edit encrypted secrets.yaml (launchd auto-deploys on save)
secrets-deploy    # Decrypt + deploy to target paths (writes manifest)
secrets-reload    # Re-source in current shell
secrets-status    # Show age key, encryption, deployed files
secrets-rescan    # Discover unmanaged secrets (read-only)
secrets-view      # View decrypted secrets (read-only)
secrets-backup    # Create timestamped backup
secrets-audit     # Scan for plaintext credential exposure
secrets-local     # Manage temporary testing overrides
zsh-local         # Manage ~/.zshrc.local aliases/overrides

# Read-only verifier (called from HM activation; safe to run manually)
scripts/secrets/verify-secrets.sh         # Verify each manifest target exists/mode/non-empty
scripts/secrets/verify-secrets.sh --quiet # Same, only print on failure
```

### Local Overrides

```bash
# Runtime-only secret overrides
secrets-local add OPENAI_API_KEY "sk-test-..."
secrets-local add FEATURE_FLAG "1"
secrets-local unset FEATURE_FLAG

# Local shell aliases without rebuild
zsh-local alias add ccr "claude --resume"
zsh-local alias add "cc!" "claude --dangerously-skip-permissions"
zsh-local alias rm ccr
```

Use `secrets-local` for temporary values in `~/.zsh_secrets.local`.
Use `zsh-local` for aliases and shell tweaks in `~/.zshrc.local`.
Permanent secrets should still go through `secrets-edit` and `secrets-deploy`.

---

## Troubleshooting

```bash
# Check everything
secrets-status

# Can't decrypt
ls -la ~/.config/sops/age/keys.txt          # Key exists?
grep "public key:" ~/.config/sops/age/keys.txt  # Get public key
grep "age1" .sops.yaml                      # Key in .sops.yaml?

# Deploy fails
secrets-deploy --dry-run    # See what would happen
which sops yq               # Tools installed?

# Permissions wrong
secrets-deploy              # Re-deploys with correct chmod

# Activation fails with "no secrets manifest"
secrets-deploy              # First-boot or manifest deleted — re-deploy

# Activation fails with "missing: <path>"
secrets-deploy              # File got deleted/moved; re-deploy restores it

# Activation fails with "contains SOPS file header"
# Means the deployed file got the whole decrypted document.
# This was the 2026-04-28 bug — should not recur, but if it does:
cat ~/.local/state/secrets-deploy/manifest    # See affected target
secrets-deploy              # Re-deploy correctly

# Watcher not firing after secrets-edit
launchctl list | grep secrets-deploy-watcher  # Confirm agent loaded
ls -t ~/.local/state/secrets-deploy/*.log | head -1 | xargs cat  # Last event log
```
