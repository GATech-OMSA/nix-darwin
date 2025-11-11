# Multi-Machine Setup Guide

**How to manage multiple machines with a single nix-darwin configuration**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Overview](#overview)
2. [How It Works](#how-it-works)
3. [Setting Up a New Machine](#setting-up-a-new-machine)
4. [Sharing Configuration](#sharing-configuration)
5. [Syncing Changes](#syncing-changes)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This nix-darwin configuration is designed from the ground up to support multiple machines with a single repository. Whether you're managing a personal laptop and work laptop, or multiple machines for different purposes, the mixin system makes it easy to:

- **Share common configuration** across all machines
- **Customize** specific settings per machine
- **Sync changes** via git
- **Maintain consistency** while allowing flexibility

**Key Benefits:**

- ✅ **Single source of truth** - One repository for all machines
- ✅ **Machine-specific settings** - Automatic detection via hostname
- ✅ **Easy synchronization** - Git-based workflow
- ✅ **No duplication** - Shared configs via mixins
- ✅ **Type safety** - Nix ensures consistency

---

## How It Works

### Architecture Overview

The multi-machine system uses three layers:

```
┌─────────────────────────────────────┐
│  Machine Detection (hostname)       │
│  ↓                                  │
│  mbp-jimmy → personal.nix           │
│  mbp-work  → work.nix               │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Mixin System                       │
│  ↓                                  │
│  base.nix    (all machines)         │
│  dev.nix     (development tools)    │
│  personal.nix (personal settings)   │
│  work.nix    (work settings)        │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Configuration Application          │
│  ↓                                  │
│  Environment variables              │
│  Packages                           │
│  Shell aliases                      │
│  Applications                       │
└─────────────────────────────────────┘
```

### The Mixin System

**Mixins** are modular configuration files that define settings for different machine types:

| Mixin | Purpose | Applied To |
|-------|---------|------------|
| **base.nix** | Essential tools and settings for all machines | All machines |
| **dev.nix** | Development packages and configurations | Development machines |
| **personal.nix** | Personal machine settings (home AWS, personal email) | Personal machines |
| **work.nix** | Work machine settings (work AWS, corporate configs) | Work machines |

**Location:** `home/_mixins/`

### Hostname-Based Detection

The system automatically detects which machine it's running on using the hostname:

```nix
# In flake.nix
darwinConfigurations."mbp-jimmy" = mkDarwinSystem {
  hostname = "mbp-jimmy";
  username = "jimmy";
  mixins = [ "base" "dev" "personal" ];  # ← Personal machine mixins
};

darwinConfigurations."mbp-work" = mkDarwinSystem {
  hostname = "mbp-work";
  username = "jimmy";
  mixins = [ "base" "dev" "work" ];  # ← Work machine mixins
};
```

**Result:**

- `mbp-jimmy` → Gets personal.nix configuration
- `mbp-work` → Gets work.nix configuration

### What Gets Customized

Each mixin can customize:

```nix
# personal.nix example
{
  # Environment variables
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };

  # Packages unique to personal machines
  home.packages = with pkgs; [
    neofetch
  ];

  # Shell aliases
  programs.zsh.shellAliases = {
    learning = "cd ~/Dev/learning";
  };
}
```

---

## Setting Up a New Machine

### Step 1: Choose Hostname

Pick a unique hostname that follows the convention:

```bash
# Personal machines
mbp-jimmy       # Personal MacBook Pro
imac-jimmy      # Personal iMac

# Work machines
mbp-work        # Work MacBook Pro
mac-studio-work # Work Mac Studio
```

### Step 2: Create Host Configuration

```bash
cd ~/nix-darwin

# Create host directory
mkdir -p hosts/your-hostname

# Create configuration files
cd hosts/your-hostname
```

**Create `default.nix`:**

```nix
{ config, pkgs, lib, ... }:

{
  # Import shared host configuration
  imports = [ ./configuration.nix ];

  # State version (don't change)
  system.stateVersion = 5;
}
```

**Create `configuration.nix`:**

```nix
{ config, pkgs, ... }:

{
  # System settings
  networking = {
    computerName = "Your Machine Name";
    hostName = "your-hostname";
    localHostName = "your-hostname";
  };

  # User configuration
  users.users.jimmy = {
    name = "jimmy";
    home = "/Users/jimmy";
  };

  # Machine-specific settings
  # Add any host-specific configurations here
}
```

**Optional: Create `secrets.yaml`** (if using encrypted secrets):

```bash
# Copy template from another host
cp ../mbp-jimmy/secrets.yaml secrets.yaml

# Edit with SOPS
sops secrets.yaml
```

### Step 3: Add to Flake

Edit `flake.nix` and add your machine:

```nix
{
  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, sops-nix }:
  {
    # Existing machines...

    # Your new machine
    darwinConfigurations."your-hostname" = mkDarwinSystem {
      hostname = "your-hostname";
      username = "jimmy";
      mixins = [ "base" "dev" "personal" ];  # or "work"
    };
  };
}
```

### Step 4: Set System Hostname

```bash
sudo scutil --set HostName your-hostname
sudo scutil --set LocalHostName your-hostname
sudo scutil --set ComputerName "Your Machine Name"

# Verify
hostname
```

### Step 5: Install

```bash
cd ~/nix-darwin

# First installation
sudo nix run nix-darwin -- switch --flake .#your-hostname

# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Zsh plugins
./scripts/install-zsh-plugins.sh

# Restart terminal
exec zsh
```

### Step 6: Verify

```bash
# Check machine mode
echo $MACHINE_MODE  # Should show "home" or "work"

# Check AWS profile (work machines)
echo $AWS_PROFILE

# Test commands
g s  # Git status
ll   # Modern ls
```

---

## Sharing Configuration

### What's Shared Automatically

Through the mixin system, these are shared across all machines:

**From base.nix:**
- Starship prompt
- Modern CLI tools (bat, eza, fzf, zoxide)
- direnv integration
- Common shell utilities

**From dev.nix:**
- Development tools
- Language environments
- Build tools

### Adding Shared Configuration

**To share across ALL machines:**

Edit `home/_mixins/base.nix`:

```nix
{
  # This alias will be available on ALL machines
  programs.zsh.shellAliases = {
    myalias = "echo 'Available everywhere'";
  };
}
```

**To share across development machines only:**

Edit `home/_mixins/dev.nix`:

```nix
{
  # Only on machines with "dev" mixin
  home.packages = with pkgs; [
    my-dev-tool
  ];
}
```

### Machine-Specific Configuration

**Personal machines only:**

Edit `home/_mixins/personal.nix`:

```nix
{
  programs.zsh.shellAliases = {
    gaming = "cd ~/Games";
  };
}
```

**Work machines only:**

Edit `home/_mixins/work.nix`:

```nix
{
  programs.zsh.shellAliases = {
    vpn = "sudo openconnect vpn.company.com";
  };
}
```

---

## Syncing Changes

### Basic Workflow

**On Machine A (make changes):**

```bash
cd ~/nix-darwin

# Edit configuration
nixconf  # or gitconf, zshconf, etc.

# Rebuild to test
nix-rebuild

# Commit and push
g aa
g cm "Add new git alias for quick commits"
g ps
```

**On Machine B (apply changes):**

```bash
cd ~/nix-darwin

# Pull changes
g pl

# Rebuild
nix-rebuild

# Restart shell if needed
exec zsh
```

### What Gets Synced

**Automatically synced:**
- ✅ System packages
- ✅ Shell aliases and functions
- ✅ Git configuration
- ✅ Application settings
- ✅ Mixin configurations
- ✅ Helper scripts

**Not synced (machine-local):**
- ❌ Secrets in `~/.zsh_secrets`
- ❌ AWS credentials in `~/.aws/credentials`
- ❌ SSH keys in `~/.ssh/`
- ❌ Application data
- ❌ User-specific files in `user-data/` (gitignored)

### Sync Strategy

**Daily workflow:**

```bash
# Start of day - pull latest
cd ~/nix-darwin && g pl && nix-rebuild

# Make changes throughout day
nixconf  # edit
nix-rebuild  # test

# End of day - push changes
g aa && g cm "Daily improvements" && g ps
```

**Best practices:**

1. **Pull before pushing** - Always `g pl` before making changes
2. **Test before committing** - Run `nix-rebuild` to verify
3. **Descriptive commits** - Clear messages help track changes
4. **Small commits** - Easier to debug if issues arise
5. **Push regularly** - Don't let changes pile up

---

## Common Patterns

### Pattern 1: Conditional Aliases

**Use case:** Different commands on different machines

```nix
# In work.nix
programs.zsh.shellAliases = {
  connect-db = "~/scripts/connect-to-work-db.sh";
};

# In personal.nix
programs.zsh.shellAliases = {
  connect-db = "~/scripts/connect-to-home-db.sh";
};
```

### Pattern 2: Shared Function, Different Values

**Use case:** Same functionality, different configuration

```nix
# In base.nix (shared function)
programs.zsh.initExtra = ''
  backup() {
    rsync -av ~/Documents/ "$BACKUP_DIR"
  }
'';

# In personal.nix
home.sessionVariables = {
  BACKUP_DIR = "/Volumes/PersonalBackup";
};

# In work.nix
home.sessionVariables = {
  BACKUP_DIR = "/Volumes/WorkBackup";
};
```

### Pattern 3: Conditional Packages

**Use case:** Install package only on certain machines

```nix
# In personal.nix
home.packages = with pkgs; [
  ollama  # AI models for personal projects
];

# In work.nix
home.packages = with pkgs; [
  postgresql_16  # Database client for work
];
```

### Pattern 4: Machine Type Detection in Scripts

**Use case:** Scripts that behave differently per machine

```bash
#!/usr/bin/env bash
# scripts/deploy.sh

if [ "$MACHINE_MODE" = "work" ]; then
  echo "Deploying to work environment..."
  aws s3 sync ./build s3://work-bucket
else
  echo "Deploying to personal environment..."
  aws s3 sync ./build s3://personal-bucket
fi
```

### Pattern 5: Development vs Production Mixins

**Use case:** Separate configs for dev vs prod setups

```nix
# In flake.nix - Development machine
darwinConfigurations."macbook-dev" = mkDarwinSystem {
  hostname = "macbook-dev";
  mixins = [ "base" "dev" "personal" ];  # Full dev tools
};

# In flake.nix - Production machine
darwinConfigurations."macbook-personal" = mkDarwinSystem {
  hostname = "macbook-personal";
  mixins = [ "base" "personal" ];  # No dev tools, lighter setup
};
```

---

## Troubleshooting

### Wrong Configuration Applied

**Problem:** Machine using wrong mixin (work settings on personal machine)

**Solution:**

```bash
# Check hostname
hostname
# Should match flake.nix entry

# If wrong, fix it:
sudo scutil --set HostName mbp-jimmy  # or correct hostname

# Rebuild
nix-rebuild

# Verify
echo $MACHINE_MODE
```

### Changes Not Syncing

**Problem:** Changes made on Machine A don't appear on Machine B

**Solution:**

```bash
# On Machine B
cd ~/nix-darwin

# Check git status
g s

# Pull changes
g pl

# Check if rebuild needed
nix-rebuild

# Restart shell
exec zsh
```

### Merge Conflicts

**Problem:** Git conflicts when pulling changes

**Solution:**

```bash
# View conflicts
g s

# Edit conflicting files
code path/to/conflicted/file

# Resolve conflicts manually
# Then:
g aa
g cm "Resolve merge conflict"
g ps
```

### Different Packages on Machines

**Problem:** Package available on one machine but not another

**Diagnostic:**

```bash
# Check which mixin has the package
rg "package-name" home/_mixins/

# Check machine's mixins
# Look in flake.nix for your hostname
```

**Solution:**

```bash
# Option 1: Add to shared (base.nix or dev.nix)
nixconf
# Edit appropriate mixin
nix-rebuild

# Option 2: Accept difference (intended for machine-specific)
```

### Build Fails on Second Machine

**Problem:** Build succeeds on Machine A but fails on Machine B

**Diagnostic:**

```bash
# Show detailed errors
darwin-rebuild switch --flake . --show-trace

# Check flake
nix flake check

# Compare Nix versions
nix --version
```

**Common causes:**

1. **Different Nix versions** - Update Nix on both machines
2. **Cache issues** - Clear and rebuild: `nix-collect-garbage -d`
3. **Platform differences** - Check `system` in flake.nix matches

---

## Best Practices

### 1. Consistent Naming

Use clear, consistent hostname patterns:

```bash
# Good
mbp-jimmy      # Clear: MacBook Pro, personal
mbp-work       # Clear: MacBook Pro, work
imac-studio    # Clear: iMac, personal studio

# Avoid
jimmys-mac     # Unclear which one
mac-2024       # Not descriptive
work-laptop    # Not specific enough
```

### 2. Document Machine Purpose

Add comments in `flake.nix`:

```nix
# Personal M1 MacBook Pro (2021) - Daily driver
darwinConfigurations."mbp-jimmy" = mkDarwinSystem {
  hostname = "mbp-jimmy";
  mixins = [ "base" "dev" "personal" ];
};

# Work M3 MacBook Pro (2024) - Corporate development
darwinConfigurations."mbp-work" = mkDarwinSystem {
  hostname = "mbp-work";
  mixins = [ "base" "dev" "work" ];
};
```

### 3. Test on All Machines

Before major changes:

```bash
# On Machine A
nixconf  # Make changes
nix-rebuild  # Test
g aa && g cm "Major update" && g ps

# On Machine B
g pl
nix-rebuild  # Verify works on second machine
```

### 4. Use Branches for Experiments

```bash
# Create experimental branch
g co -b experiment-new-shell

# Make changes
nixconf
nix-rebuild

# If works, merge
g co main
g merge experiment-new-shell
g ps

# If fails, discard
g co main
g br -D experiment-new-shell
```

### 5. Keep Secrets Separate

**Never commit secrets:**

```bash
# Use ~/.zsh_secrets for API keys
# Use sops-nix for encrypted secrets
# Use ~/.aws/credentials for AWS keys

# These are gitignored automatically
```

---

## Advanced: Adding a Third Machine Type

**Scenario:** Add a "server" machine type alongside personal/work

**Step 1: Create server mixin**

```bash
cd ~/nix-darwin
touch home/_mixins/server.nix
```

**Edit `server.nix`:**

```nix
{ config, pkgs, ... }:

{
  home.sessionVariables = {
    MACHINE_MODE = "server";
  };

  # Server-specific packages
  home.packages = with pkgs; [
    docker
    kubernetes
  ];

  # Server aliases
  programs.zsh.shellAliases = {
    logs = "tail -f /var/log/syslog";
  };
}
```

**Step 2: Add to flake.nix**

```nix
darwinConfigurations."mac-mini-server" = mkDarwinSystem {
  hostname = "mac-mini-server";
  username = "jimmy";
  mixins = [ "base" "server" ];  # No dev tools on server
};
```

**Step 3: Set up machine**

```bash
# On the Mac Mini
sudo scutil --set HostName mac-mini-server
sudo nix run nix-darwin -- switch --flake .#mac-mini-server
```

---

## Summary

**Multi-machine setup gives you:**

- ✅ **One repository** for all machines
- ✅ **Automatic configuration** based on hostname
- ✅ **Easy synchronization** via git
- ✅ **Flexible customization** via mixins
- ✅ **Type-safe configuration** via Nix

**Key takeaways:**

1. **Hostname determines configuration** - Set it correctly
2. **Mixins provide modularity** - base, dev, personal, work
3. **Git syncs changes** - Pull, rebuild, push workflow
4. **Test before committing** - Always run `nix-rebuild`
5. **Keep secrets separate** - Use appropriate secret management

---

## Next Steps

1. **[Installation Guide](installation.md)** - Set up your first machine
2. **[Usage Guide](usage.md)** - Daily workflows
3. **[Architecture Overview](../architecture/overview.md)** - Deep dive into system design

---

## Resources

- **[Mixin System Documentation](../architecture/overview.md#mixin-system)**
- **[Helper Functions (lib/)](../../lib/README.md)**
- **[Example Configurations](../../hosts/)**

---

**Version**: 2.0.0
**Last Updated**: 2025-11-07
