# Secrets Management with sops-nix

This directory contains encrypted secrets using SOPS (Secrets OPerationS).

## Initial Setup

### 1. Install Required Tools

Already included in your Nix configuration:
- `age` - Encryption tool
- `sops` - Secrets manager

### 2. Generate Age Key

```bash
# Create directory
mkdir -p ~/Library/Application\ Support/sops/age

# Generate key
age-keygen -o ~/Library/Application\ Support/sops/age/keys.txt

# View your public key
grep 'public key:' ~/Library/Application\ Support/sops/age/keys.txt
```

**CRITICAL**: Back up `~/Library/Application\ Support/sops/age/keys.txt` securely!
Without this file, you cannot decrypt your secrets.

### 3. Configure SOPS

1. Edit `.sops.yaml` and replace the placeholder age key with your public key
2. Keep your private key file secure and backed up

### 4. Add Secrets

1. Edit `secrets/secrets.yaml` (it's unencrypted initially)
2. Add your secrets:
   ```yaml
   openai_api_key: sk-your-actual-key
   github_token: ghp_your-actual-token
   ```
3. Encrypt the file:
   ```bash
   cd ~/nix-darwin
   sops -e -i secrets/secrets.yaml
   ```
4. Now `secrets.yaml` is encrypted and safe to commit to git!

## Using Secrets

Secrets are automatically decrypted and made available as files when you rebuild your system.

### In Shell (Zsh)

Secrets are loaded in your shell configuration:

```bash
# Access secrets
echo $OPENAI_API_KEY
echo $ANTHROPIC_API_KEY
```

### In Nix Configuration

Reference secrets in your Nix files:

```nix
programs.zsh.initExtra = ''
  export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai_api_key.path})"
'';
```

## Managing Secrets

### View Encrypted File

```bash
sops secrets/secrets.yaml
```

This opens your editor with decrypted content (temporarily).

### Edit Secrets

```bash
# Edit encrypted file (auto-decrypts, re-encrypts on save)
sops secrets/secrets.yaml

# Add new key:value
# Save and quit
```

### Add New Secret

1. Edit the encrypted file: `sops secrets/secrets.yaml`
2. Add new key:value pair
3. Save (automatically re-encrypts)
4. Update your configuration to use the new secret
5. Rebuild: `darwin-rebuild switch --flake ~/nix-darwin`

## Work Mac Secrets

For work-specific secrets, create `secrets/work-secrets.yaml`:

```bash
# Create new secrets file
cp secrets/secrets.yaml secrets/work-secrets.yaml

# Edit and add work secrets
sops secrets/work-secrets.yaml

# Configure in hosts/mbp-work/default.nix
```

## Security Best Practices

1. ✅ **Always encrypt before committing** to git
2. ✅ **Back up your age key** securely (password manager, encrypted backup)
3. ✅ **Never commit unencrypted secrets**
4. ✅ **Rotate secrets** if they're ever exposed
5. ✅ **Use different secrets** for personal vs work machines

## Troubleshooting

### "age: error: no identity matched any of the recipients"

Your age key doesn't match the public key in `.sops.yaml`. Either:
1. Update `.sops.yaml` with your correct public key, or
2. Use the correct age key file

### "failed to get the data key"

SOPS can't find your private key. Ensure:
1. Private key exists at `~/Library/Application Support/sops/age/keys.txt`
2. File has correct permissions (readable by you only)

### Secrets not loading in shell

1. Check sops configuration in your host's `default.nix`
2. Rebuild system: `darwin-rebuild switch --flake ~/nix-darwin`
3. Check secret files exist: `ls -la /run/secrets/` (after rebuild)

## Additional Resources

- SOPS documentation: https://github.com/getsops/sops
- sops-nix documentation: https://github.com/Mic92/sops-nix
- Age encryption: https://age-encryption.org/
