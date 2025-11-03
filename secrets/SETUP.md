# Secrets Management Setup Guide

## Step 1: Install age and Generate Your Key

**Run these commands ONCE (before first nix-rebuild with sops):**

```bash
# Install age temporarily
nix-shell -p age sops

# Generate your age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# IMPORTANT: Save this output!
# It will show your public key like: "Public key: age1xxxxxxxxxxxxxx..."
```

## Step 2: Copy Your Public Key

```bash
# Display your public key
grep "public key:" ~/.config/sops/age/keys.txt

# Copy the key (looks like: age1xxxxxxxxxxxxxx...)
# You'll need this for .sops.yaml
```

## Step 3: Update .sops.yaml

Edit `secrets/.sops.yaml` and replace `YOUR_PUBLIC_AGE_KEY_HERE` with your actual public key.

## Step 4: Create Your First Secrets File

```bash
# Create and edit encrypted secrets
cd ~/nix-darwin
sops hosts/mbp-jimmy/secrets.yaml
```

This will open your editor. Add secrets in YAML format:

```yaml
zsh_secrets: |
  # Add your environment secrets here
  export OPENAI_API_KEY="sk-..."
  export GITHUB_TOKEN="ghp_..."

ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  paste your SSH private key here
  -----END OPENSSH PRIVATE KEY-----
```

Save and exit. The file will be automatically encrypted.

## Step 5: Rebuild

```bash
darwin-rebuild switch --flake ~/nix-darwin
```

Your secrets will be decrypted and placed in the correct locations!

## Security Notes

1. **NEVER commit ~/.config/sops/age/keys.txt to git!**
2. **Backup your age key** to a secure location (password manager, encrypted USB)
3. **Without your age key, you cannot decrypt secrets!**
4. The encrypted secrets.yaml CAN be safely committed to git

## Backup Your Age Key

```bash
# Copy to secure location
cp ~/.config/sops/age/keys.txt /path/to/secure/backup/
```

## Emergency: Lost Age Key

If you lose your age key:
1. Generate a new age key
2. Update .sops.yaml with new public key
3. Re-encrypt all secrets files:
   ```bash
   sops updatekeys hosts/mbp-jimmy/secrets.yaml
   ```
