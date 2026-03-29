# Secrets Management — SOPS Setup

How secrets encryption works in this repo. For daily commands and workflow, see
[AWS & Secrets Reference](aws-and-secrets-workflow.md).

---

## How It Works

```
secrets.yaml (SOPS encrypted, per-host, committed to git)
        |
  [secrets-deploy]  ← runs on rebuild or manually
        |
  ~/.zsh_secrets, ~/.ssh/*, ~/.db/*, ~/.tokens/*  (deployed files)
        |
  [secrets-reload]  ← re-source in current shell
```

- **Encryption:** SOPS with age keys
- **Deployment:** `scripts/secrets/deploy-secrets.sh` (single source of truth)
- **Mappings:** defined in `deploy-secrets.sh` MAPPINGS array
- **Both profiles** use the same script; keys not in a machine's secrets.yaml are skipped

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
3. `secrets-deploy` — deploy to target path
4. `secrets-reload` — re-source if it's a shell variable

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
secrets-edit      # Edit encrypted secrets.yaml
secrets-deploy    # Decrypt + deploy to target paths
secrets-reload    # Re-source in current shell
secrets-status    # Show age key, encryption, deployed files
secrets-rescan    # Discover unmanaged secrets (read-only)
secrets-view      # View decrypted secrets (read-only)
secrets-backup    # Create timestamped backup
secrets-audit     # Scan for plaintext credential exposure
secrets-local     # Manage temporary testing overrides
zsh-local         # Manage ~/.zshrc.local aliases/overrides
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
```
