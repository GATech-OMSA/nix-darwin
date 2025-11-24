# Host Configuration Template

Template for creating new machine configurations.

## Quick Start

### 1. Copy Template

```bash
# Copy template to new hostname
cp -r hosts/_template hosts/NEW-HOSTNAME

# Example
cp -r hosts/_template hosts/mbp-alice
```

### 2. Customize Configuration

Edit `hosts/NEW-HOSTNAME/default.nix`:

```nix
networking = {
  computerName = "Alice's MacBook Pro";  # Change this
  # ...
};
```

### 3. Register Machine

Add to `hosts/machines.nix`:

```nix
{
  "mbp-alice" = "personal";  # or "work"
}
```

### 4. Add to Flake

Add to `flake.nix`:

```nix
darwinConfigurations."mbp-alice" = mkDarwinSystem {
  hostname = "mbp-alice";
  system = "aarch64-darwin";  # or "x86_64-darwin"
  username = "alice";
  mixins = [ "base" "dev" "personal" ];  # or "work"
};
```

### 5. Setup Secrets

```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key
grep "public key:" ~/.config/sops/age/keys.txt

# Update .sops.yaml
code secrets/.sops.yaml
# Add your public key

# Encrypt secrets
sops hosts/mbp-alice/secrets.yaml
# Add your actual secrets

# Verify encryption
cat hosts/mbp-alice/secrets.yaml | head -5
# Should see: ENC[AES256_GCM,data:...]
```

### 6. Build

```bash
# First time setup
sudo nix run nix-darwin -- switch --flake .#mbp-alice

# Subsequent rebuilds
darwin-rebuild switch --flake ~/nix-darwin
```

## What to Customize

### Required

- [ ] `networking.computerName` - Display name
- [ ] `hosts/machines.nix` - Add hostname mapping
- [ ] `flake.nix` - Add darwinConfiguration
- [ ] `secrets.yaml` - Add encrypted secrets

### Optional

- [ ] SOPS secrets configuration (add/remove as needed)
- [ ] Homebrew packages (in modules/darwin/homebrew.nix)
- [ ] Shell aliases (in home/USERNAME/shell/zsh.nix)
- [ ] Git config (in home/USERNAME/programs/git.nix)

## Files in Template

```
_template/
├── default.nix      # Main host configuration
├── secrets.yaml     # Encrypted secrets (template)
└── README.md        # This file
```

## Machine Types

Choose mixin based on machine purpose:

**Personal machine:**
```nix
mixins = [ "base" "dev" "personal" ];
```

**Work machine:**
```nix
mixins = [ "base" "dev" "work" ];
```

**Minimal machine:**
```nix
mixins = [ "base" ];
```

## Secret Configuration Examples

### Basic Setup (Personal Machine)

```nix
secrets = {
  zsh_secrets = { path = "/Users/${username}/.zsh_secrets"; mode = "0600"; };
  ssh_private_key = { path = "/Users/${username}/.ssh/id_ed25519"; mode = "0600"; };
  ssh_public_key = { path = "/Users/${username}/.ssh/id_ed25519.pub"; mode = "0644"; };
  aws_credentials = { path = "/Users/${username}/.aws/credentials"; mode = "0600"; };
};
```

### Work Machine with Databases

```nix
secrets = {
  # Core secrets
  zsh_secrets = { ... };
  ssh_private_key = { ... };

  # Multi-environment databases
  postgres_prod_connection = {
    path = "/Users/${username}/.db/postgres/prod";
    mode = "0600";
  };

  postgres_dev_connection = {
    path = "/Users/${username}/.db/postgres/dev";
    mode = "0600";
  };

  # API tokens
  github_token = {
    path = "/Users/${username}/.tokens/github_token";
    mode = "0600";
  };
};
```

### Corporate Environment (Proxy Blocks SOPS)

```nix
# DISABLED: sops-nix module requires Go modules blocked by corporate proxy
# Alternative: Manage secrets manually
/*
sops = {
  # ... all your secrets config here
};
*/

# Create secret files manually:
# mkdir -p ~/.db/postgres
# echo "connection_string" > ~/.db/postgres/prod
# chmod 600 ~/.db/postgres/prod
```

## Multi-Machine Setup Patterns

### Pattern 1: Personal + Work Machines

**Personal** (mbp-alice):
- Mixins: `[ "base" "dev" "personal" ]`
- Homebrew: `enabled`
- Secrets: SSH keys, AWS (personal), Ollama keys
- Apps: Browsers, AI tools, personal productivity

**Work** (mbp-alice-work):
- Mixins: `[ "base" "dev" "work" ]`
- Homebrew: `disabled` (if corporate policy)
- Secrets: Work SSH, databases, API tokens, VPN
- Apps: Corporate tools, work-specific configs

### Pattern 2: Multiple Personal Machines

**Desktop** (mac-studio-alice):
- Mixins: `[ "base" "dev" "personal" ]`
- Heavy workloads, all tools installed

**Laptop** (mbp-alice):
- Mixins: `[ "base" "personal" ]` (no dev)
- Minimal, lightweight setup for travel

## Homebrew Toggle Strategy

```nix
# Personal machine (apps via Homebrew)
homebrew.enable = true;

# Work machine (corporate MDM manages apps)
homebrew.enable = false;

# Minimal machine (no GUI apps)
homebrew.enable = false;
```

## See Also

- [Installation Guide](../../docs/guides/installation.md) - Complete setup
- [Multi-User Setup](../../docs/guides/multi-user-setup.md) - Multiple users
- [Secrets Guide](../../docs/guides/secrets.md) - SOPS encryption
- [Architecture Overview](../../docs/architecture/overview.md) - System design
- [Work Setup Guide](../../docs/guides/work-setup.md) - Corporate environments
