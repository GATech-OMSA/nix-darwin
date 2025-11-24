# Work Machine Secrets Management

**Note:** This work machine uses manual secret deployment (sops CLI from nixpkgs) instead of sops-nix automatic integration, because corporate proxies block the Go module downloads required by sops-nix's `sops-install-secrets` helper during Nix builds.

## Setup

### 1. Install SOPS and Age
```bash
# SOPS and age are automatically installed via Nix packages
# (see nix-config/home/_profiles/work/packages.nix)
# Verify installation:
which sops
which age-keygen
# Should show: /nix/store/.../bin/sops and /nix/store/.../bin/age-keygen
```

### 2. Create Age Key
```bash
# Generate age encryption key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Note your public key (shown in output):
# Public key: age1...
```

### 3. Configure SOPS
```bash
# Create/update .sops.yaml in nix-darwin directory
cat > ~/nix-darwin/.sops.yaml <<EOF
keys:
  - &work_key age1YOUR_PUBLIC_KEY_HERE
creation_rules:
  - path_regex: nix-config/hosts/macbook-pro-m3/secrets.yaml
    key_groups:
      - age:
          - *work_key
EOF
```

### 4. Create Encrypted Secrets File
```bash
cd ~/nix-darwin
sops nix-config/hosts/macbook-pro-m3/secrets.yaml
```

Add your secrets in YAML format:
```yaml
# SSH Keys
work_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----

work_ssh_public_key: ssh-ed25519 AAAA... user@host

# Database Credentials
mssql_prod_connection: |
  Server=sql.company.com
  Database=ProductionDB
  User=username
  Password=secret

# API Tokens
git_token: ghp_...
hcp_terraform_token: ...
jira_api_token: ...

# AWS Accounts (for SSO multi-account setup)
aws_accounts: |
  {
    "work-domain": {
      "description": "Company AWS Organization",
      "alias": "work",
      "default_role": "support",
      "accounts": {
        "dev": {
          "id": "123456789012",
          "region": "us-east-1",
          "additional_roles": ["developer", "poweruser"]
        },
        "qa": "234567890123",
        "prod": "345678901234"
      }
    }
  }
```

## Manual Secret Deployment

Since we're not using sops-nix automatic deployment, you need to manually extract secrets:

### Extract and Deploy Secrets

```bash
#!/bin/bash
# deploy-secrets.sh - Manual secret deployment for work machine

SECRETS_FILE="$HOME/nix-darwin/nix-config/hosts/macbook-pro-m3/secrets.yaml"

# Export SOPS_AGE_KEY_FILE
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# SSH Keys
sops -d --extract '["work_ssh_private_key"]' "$SECRETS_FILE" > ~/.ssh/id_ed25519_work
chmod 600 ~/.ssh/id_ed25519_work

sops -d --extract '["work_ssh_public_key"]' "$SECRETS_FILE" > ~/.ssh/id_ed25519_work.pub
chmod 644 ~/.ssh/id_ed25519_work.pub

# Database Connections
mkdir -p ~/.db/mssql ~/.db/postgres ~/.db/ods ~/.db/dw
sops -d --extract '["mssql_prod_connection"]' "$SECRETS_FILE" > ~/.db/mssql/prod
sops -d --extract '["postgres_prod_connection"]' "$SECRETS_FILE" > ~/.db/postgres/prod
sops -d --extract '["ods_prod_connection"]' "$SECRETS_FILE" > ~/.db/ods/prod
sops -d --extract '["dw_prod_connection"]' "$SECRETS_FILE" > ~/.db/dw/prod
chmod 600 ~/.db/*/* 2>/dev/null

# API Tokens
mkdir -p ~/.tokens
sops -d --extract '["git_token"]' "$SECRETS_FILE" > ~/.tokens/git_token
sops -d --extract '["hcp_terraform_token"]' "$SECRETS_FILE" > ~/.tokens/hcp_terraform_token
sops -d --extract '["jira_api_token"]' "$SECRETS_FILE" > ~/.tokens/jira_api_token
chmod 600 ~/.tokens/*

# AWS Accounts (for multi-account SSO)
mkdir -p ~/.aws
sops -d --extract '["aws_accounts"]' "$SECRETS_FILE" > ~/.aws/accounts.json
chmod 600 ~/.aws/accounts.json

echo "✅ Secrets deployed successfully"
```

Save this script and run after editing secrets:
```bash
chmod +x ~/nix-darwin/scripts/deploy-secrets.sh
~/nix-darwin/scripts/deploy-secrets.sh
```

## Editing Secrets

```bash
# Edit encrypted secrets
cd ~/nix-darwin
sops nix-config/hosts/macbook-pro-m3/secrets.yaml

# After editing, redeploy
scripts/deploy-secrets.sh
```

## Backup Your Age Key

**CRITICAL**: Backup your age key - if lost, you cannot decrypt secrets!

```bash
# Backup age key (store securely - 1Password, USB drive, etc.)
cp ~/.config/sops/age/keys.txt ~/Backup/age-key-work-$(date +%Y%m%d).txt
```

## Comparison: Personal vs Work

| Feature | Personal Machine | Work Machine |
|---------|-----------------|--------------|
| **SOPS Installation** | nixpkgs (sops CLI) | nixpkgs (sops CLI) |
| **Secret Integration** | sops-nix (automatic) | Manual deployment |
| **Secret Deployment** | Automatic (on rebuild) | Manual (via script) |
| **Reason** | sops-nix works fine | Corporate proxy blocks sops-nix's Go module downloads |
| **Rebuild Required** | Yes (secrets auto-deployed) | No (manual deployment) |

## Troubleshooting

**Secrets not decrypting:**
```bash
# Check age key exists
ls -la ~/.config/sops/age/keys.txt

# Check SOPS can decrypt
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
sops -d nix-config/hosts/macbook-pro-m3/secrets.yaml
```

**Permission denied:**
```bash
# Fix file permissions
chmod 600 ~/.ssh/id_ed25519_work
chmod 600 ~/.db/*/* 2>/dev/null
chmod 600 ~/.tokens/*
chmod 600 ~/.aws/accounts.json
```
