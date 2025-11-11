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

## See Also

- [Installation Guide](../../docs/guides/installation.md) - Complete setup
- [Multi-User Setup](../../docs/guides/multi-user-setup.md) - Multiple users
- [Secrets Guide](../../docs/guides/secrets.md) - SOPS encryption
- [Architecture Overview](../../docs/architecture/overview.md) - System design
