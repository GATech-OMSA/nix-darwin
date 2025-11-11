# Clean Setup Steps - Username-Agnostic Configuration

**Status:** Ready to run setup with fixed username-agnostic machine ID generation

**What was moved:** All generated config files moved to `.temp/deprecated/configure/`:
- `config/` → `.temp/deprecated/configure/config/`
- `hosts/mbp-jimmy/` → `.temp/deprecated/configure/hosts-mbp-jimmy/`

---

## Setup Steps

### 1. Bootstrap (Install Prerequisites)

```bash
cd ~/nix-darwin

# Install Nix, nix-darwin, SOPS, age
./bootstrap.sh
```

**What this does:**
- Installs Nix package manager
- Installs nix-darwin framework
- Installs SOPS (secrets encryption)
- Installs age (encryption tool)
- Generates age encryption key at `~/.config/sops/age/keys.txt`

---

### 2. Configure (Create Config Files)

```bash
# Run interactive configuration
./configure.sh
```

**You will be prompted for:**

1. **User Information:**
   - Username (auto-detected: `jimmy`)
   - Email (auto-detected from git)
   - Full name (auto-detected from git)

2. **Machine ID (NEW - USERNAME-AGNOSTIC!):**
   ```
   Machine ID (username-agnostic identifier for this Mac)
   Suggested: macbook-pro-m1

   Enter machine ID [default: macbook-pro-m1]: _
   ```

   **Options:**
   - Press Enter → use `macbook-pro-m1` ✅ RECOMMENDED
   - Type custom: `my-laptop`, `dev-machine`, `personal-mbp`, etc.
   - **DO NOT use personal identifiers** like "jimmy-macbook"

3. **Machine Type:**
   ```
   Machine type:
     1) Personal Mac
     2) Work Mac
     3) Minimal (base only)
   Select [1-3]: 1
   ```

**What this creates:**
- `config/user-config.nix` (gitignored - contains username, email, full name)
- `config/machine-config.nix` (gitignored - contains machineId, profileName, system)
- `hosts/{machineId}/` directory
- `hosts/{machineId}/secrets.yaml` (plaintext template - needs encryption!)

**Example:** If you chose `macbook-pro-m1`:
- Creates: `hosts/macbook-pro-m1/`
- Creates: `hosts/macbook-pro-m1/secrets.yaml`

---

### 3. Configure Secrets

**IMPORTANT:** The secrets file is created as **plaintext** - you must encrypt it!

```bash
# Check your age public key
grep 'public key:' ~/.config/sops/age/keys.txt

# Verify it matches .sops.yaml
cat .sops.yaml

# Edit the plaintext secrets file
# Add your API keys, tokens, credentials
code hosts/{machineId}/secrets.yaml

# Example: hosts/macbook-pro-m1/secrets.yaml
# Add:
#   - OpenAI API key
#   - Anthropic API key
#   - GitHub token
#   - AWS credentials
#   - SSH keys (if needed)

# Encrypt the secrets file (REQUIRED!)
cd ~/nix-darwin
sops -e -i hosts/{machineId}/secrets.yaml

# Verify encryption worked
file hosts/{machineId}/secrets.yaml
# Should show: "CSV text" (encrypted format)
# NOT "ASCII text" (plaintext - dangerous!)
```

**OR restore from backup:**
```bash
# If you have encrypted secrets from old setup
cp .temp/deprecated/configure/hosts-mbp-jimmy/secrets.yaml \
   hosts/macbook-pro-m1/secrets.yaml

# Verify it's encrypted
file hosts/macbook-pro-m1/secrets.yaml
```

---

### 4. Activate (Build and Apply Configuration)

```bash
# Build and activate the configuration
./activate.sh
```

**What this does:**
- Validates config files exist
- Checks secrets are encrypted (blocks if plaintext!)
- Runs `darwin-rebuild switch --flake .`
- Installs all packages and configurations
- Sets up your shell, programs, development environment

**Expected output:**
```
✅ All config files found
✅ Secrets encrypted
🔨 Building nix-darwin configuration...
🚀 Activating configuration...
✅ Setup complete!
```

---

### 5. Verify and Test

```bash
# Restart shell to load new configuration
exec zsh

# Verify profile
echo $ACTIVE_PROFILE
# Should show: "personal"

echo $MACHINE_ID
# Should show: "macbook-pro-m1" (or whatever you chose)

# Test edit-secrets function
edit-secrets
# Should open encrypted secrets in your editor

# Test config shortcuts
nixconf    # Opens nix-darwin in VS Code
zshconf    # Opens zsh.nix in VS Code

# Verify AWS credentials loaded (if configured)
aws configure list

# Verify secrets loaded
echo $OPENAI_API_KEY    # Should show your key
echo $GITHUB_TOKEN      # Should show your token
```

---

## What Gets Created

### Gitignored (Local Only)
```
config/
├── user-config.nix         # Your username, email, full name
└── machine-config.nix      # Machine ID, profile, system arch

hosts/{machineId}/
└── secrets.yaml            # Encrypted secrets (safe to keep)
```

### Committed (In Git)
```
config/
├── user-config.nix.template    # Template for user config
└── machine-config.nix.template # Template for machine config

hosts/
└── _template/                  # Template for new hosts
```

---

## Directory Structure After Setup

```
~/nix-darwin/
├── config/
│   ├── user-config.nix              # (gitignored) Your info
│   ├── machine-config.nix           # (gitignored) Machine settings
│   ├── user-config.nix.template     # (committed) Template
│   └── machine-config.nix.template  # (committed) Template
├── hosts/
│   ├── macbook-pro-m1/              # (gitignored) Your host
│   │   └── secrets.yaml             # (gitignored) Encrypted secrets
│   └── _template/                   # (committed) Template
├── nix-config/
│   ├── home/
│   │   ├── _profiles/
│   │   │   ├── personal/            # Personal profile
│   │   │   ├── work/                # Work profile
│   │   │   ├── minimal/             # Minimal profile
│   │   │   └── _template/           # Profile-shared configs
│   │   │       ├── shell/zsh.nix
│   │   │       └── programs/
│   │   ├── _template/               # Username-agnostic base
│   │   │   ├── default.nix
│   │   │   └── development/
│   │   └── _mixins/                 # Reusable configs
│   └── modules/                     # System-level modules
└── .temp/deprecated/configure/      # Old config (backup)
    ├── config/                      # Old config files
    └── hosts-mbp-jimmy/             # Old host directory
```

---

## Troubleshooting

### "secrets file not found"
```bash
# Check machine ID
cat config/machine-config.nix | grep machineId

# Verify secrets exist at correct path
ls -la hosts/{machineId}/secrets.yaml
```

### "secrets file is not encrypted"
```bash
# Encrypt the file
cd ~/nix-darwin
sops -e -i hosts/{machineId}/secrets.yaml
```

### "age: no identity matched"
```bash
# Check your age key
cat ~/.config/sops/age/keys.txt

# Check .sops.yaml has correct public key
cat .sops.yaml

# If mismatch, update .sops.yaml with your public key
```

### "Build failed"
```bash
# Check for syntax errors
nix flake check

# View detailed error output
darwin-rebuild switch --flake . --show-trace

# Rollback to previous generation
nix-rollback
```

---

## Post-Setup

After successful setup:

1. **Commit your changes:**
   ```bash
   # Only templates are committed, not your personal config
   git add .
   git commit -m "feat: Clean username-agnostic setup complete"
   ```

2. **Backup your age key:**
   ```bash
   # CRITICAL - without this you can't decrypt secrets!
   cp ~/.config/sops/age/keys.txt ~/secure-backup-location/
   ```

3. **Remove old deprecated files (optional):**
   ```bash
   # After confirming everything works
   rm -rf .temp/deprecated/configure
   ```

4. **Test machine portability:**
   - Clone repo on another Mac
   - Run setup with different username
   - Should work without any "jimmy" references!

---

## Summary

✅ **Username-agnostic:** No "jimmy" in machine IDs
✅ **Portable:** Same repo works for any username
✅ **Secure:** All secrets encrypted with SOPS
✅ **Gitignored:** Personal info never committed
✅ **Template-based:** Easy to set up new machines

**Machine ID examples:**
- `macbook-pro-m1` ← Recommended
- `macbook-air-m2`
- `personal-laptop`
- `dev-machine-2024`

**NOT recommended:**
- `jimmy-macbook` ← Contains username!
- `mbp-jimmy` ← Contains username!
