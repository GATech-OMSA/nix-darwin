# Work Machine Secrets Management

Secrets are managed identically to the personal machine via `deploy-secrets.sh`.

## Workflow

```bash
secrets-edit           # Edit encrypted secrets.yaml
secrets-deploy         # Decrypt + deploy to target paths (no rebuild needed)
secrets-reload         # Re-source in current shell
```

On rebuild, `deploy-secrets.sh` runs automatically via Home Manager activation hook.

## Setup (first time)

```bash
# 1. Ensure age key exists
ls ~/.config/sops/age/keys.txt

# 2. Edit secrets with real values
secrets-edit

# 3. Deploy
secrets-deploy

# 4. Verify
secrets-view
```

## Backup Your Age Key

**CRITICAL**: Backup your age key — if lost, you cannot decrypt secrets.

```bash
cp ~/.config/sops/age/keys.txt ~/Backup/age-key-work-$(date +%Y%m%d).txt
```

## Adding a New Secret

1. `secrets-edit` — add key + value to secrets.yaml
2. Add mapping to `scripts/secrets/deploy-secrets.sh` MAPPINGS array
3. `secrets-deploy` — deploy to target path

## Troubleshooting

```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Check SOPS can decrypt
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d nix-config/hosts/macbook-pro-m3-work/secrets.yaml

# Fix permissions
chmod 600 ~/.ssh/id_ed25519_work
chmod 600 ~/.db/*/* 2>/dev/null
chmod 600 ~/.tokens/*
```
