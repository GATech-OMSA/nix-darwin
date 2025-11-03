# Nix Darwin Configuration

---

## What This Is

This is a **complete system configuration** for macOS that:

- ✅ Manages system packages declaratively (no manual installs)
- ✅ Configures all applications (Git, VS Code, Shell, etc.)
- ✅ Handles secrets securely (encrypted, version-controlled)
- ✅ Works across multiple machines (personal + work)
- ✅ Provides one-command system reproduction
- ✅ Enables instant rollbacks if something breaks

**One command rebuilds your entire system**: `darwin-rebuild switch --flake .`

---

## Features

### System Management

- **Nix Darwin**: Declarative macOS configuration
- **Home Manager**: User-level application configs
- **sops-nix**: Encrypted secrets management
- **Modular architecture**: Reusable across machines

### Modern Tools

- **Shell**: Zsh + Oh-My-Zsh + Starship prompt
- **CLI Tools**: bat, eza, ripgrep, fd, zoxide, fzf, delta
- **Development**: Python (UV + micromamba), Node.js, Docker
- **Cloud**: AWS CLI, kubectl, k9s, Terraform
- **nix-direnv**: 20x faster project loading

### Configurations Included

- ✅ Git (all your aliases and settings)
- ✅ VS Code (settings + extensions)
- ✅ Zsh (modular, not a 508-line string!)
- ✅ macOS system defaults
- ✅ Fonts (Nerd Fonts with icons)
- ✅ Homebrew (GUI apps only)

---

## Structure

```
nix-darwin/
├── flake.nix                  # Entry point
├── hosts/                     # Machine-specific configs
│   ├── mbp-jimmy/            # Personal MacBook
│   └── mbp-work/             # Work MacBook
├── modules/
│   ├── darwin/               # macOS system settings
│   └── shared/               # Packages for all machines
├── home/
│   ├── jimmy/                # Your user configs
│   │   ├── shell/           # Zsh configuration
│   │   ├── programs/        # Git, VS Code, etc.
│   │   └── development/     # Python, Node.js
│   └── _mixins/             # Reusable configs (base, dev, personal, work)
├── lib/                      # 30+ helper functions (machine type, generators, etc.)
├── overlays/                 # Package overrides
├── pkgs/                     # Custom packages
└── secrets/                  # Encrypted secrets (sops-nix)
```

**Infrastructure:**

- **lib/** - 30+ reusable functions: `selectByMachine`, `mkNavigationAliases`, `mkPackageGroups`, etc. ([details](lib/README.md))
- **overlays/** - Package customizations and version pinning ([details](overlays/README.md))
- **pkgs/** - Custom package definitions ([details](pkgs/README.md))

---

## Installation

### Prerequisites

1. **macOS**: Tahoe (26.0) or later
2. **Admin access**: Required for installation
3. **Backup**: Always backup before major changes!

### Step 1: Install Nix

```bash
# Install using Determinate Systems installer (recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restart terminal
exec zsh

# Verify installation
nix --version
```

### Step 2: Clone This Configuration

```bash
cd ~
# If you have this in a git repo:
git clone YOUR_REPO_URL nix-darwin
# Or if using the files directly:
mv /path/to/nix-darwin-new ~/nix-darwin

cd ~/nix-darwin
```

### Step 3: Set Hostname

**CRITICAL**: Hostname must match your configuration name!

```bash
# For personal Mac:
sudo scutil --set HostName mbp-jimmy

# For work Mac:
sudo scutil --set HostName mbp-work

# Verify:
hostname -s  # Should show mbp-jimmy or mbp-work
```

### Step 4: Customize for Your System

```bash
# Edit if your username is different
nano hosts/mbp-jimmy/default.nix
# Change "jimmy" to your actual username if needed
```

### Step 5: Set Up Secrets (Optional but Recommended)

```bash
# Generate age key for secrets
mkdir -p ~/Library/Application\ Support/sops/age
age-keygen -o ~/Library/Application\ Support/sops/age/keys.txt

# Get your public key
grep 'public key:' ~/Library/Application\ Support/sops/age/keys.txt

# Update .sops.yaml with your public key
nano secrets/.sops.yaml
# Replace the placeholder age key with your public key

# Add your secrets
nano secrets/secrets.yaml
# Add your API keys

# Encrypt secrets
sops -e -i secrets/secrets.yaml

# Now it's safe to commit!

# Note: Git hooks will be automatically installed on first rebuild
# to prevent committing unencrypted secrets
```

See `secrets/README.md` for detailed instructions.

### Step 6: Initial Build

```bash
cd ~/nix-darwin

# First-time installation (takes 15-30 minutes)
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy

# Or for work Mac:
sudo nix run nix-darwin -- switch --flake .#mbp-work
```

### Step 7: Install Oh-My-Zsh & Custom Plugins

```bash
# Install Oh-My-Zsh (Nix can't install this directly)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install custom zsh plugins (required for full shell experience)
./scripts/install-zsh-plugins.sh

# Restart terminal
exec zsh
```

### Step 8: Set Up Python Environment

```bash
# Micromamba is already installed, create your environment
# Option 1: Using the mkenv convenience function (recommended)
mkenv dev 3.12

# Option 2: Using micromamba directly
micromamba create -n dev python=3.12 -y

# Activate your environment
act dev  # or: micromamba activate dev
python --version  # Should show 3.12.x
```

---

## ✅ Verification

After installation, verify everything works:

```bash
# Restart terminal
exec zsh

# Should see welcome message:
# 👋 Welcome back, jimmy!
# 📅 [Date and time]
# 🏠 PERSONAL | Python: 3.12.x

# Test packages
which git eza bat zoxide
git --version
eza --version

# Test modern CLI
ls        # Should show icons
ll        # Long format with icons
z         # Zoxide help

# Test system info
sysinfo

# Test Git
git config --list | head -10

# Test update functions
update-dev   # Quick update

# Check secrets and git hooks status
secrets-status   # Shows git hooks installation status
```

---

## Daily Usage

### Updating Your System

```bash
# Quick development update (Nix + Python + VS Code)
update-dev

# System update (Nix + Homebrew)
update-system

# Complete update (everything)
update-all

# Just Nix packages
update-nix

# Just Homebrew
update-brew
```

### Making Changes

```bash
# 1. Edit configuration files
nano ~/nix-darwin/home/jimmy/shell/zsh.nix

# 2. Rebuild
darwin-rebuild switch --flake ~/nix-darwin

# 3. Changes take effect immediately!
```

### Rolling Back

```bash
# List generations
darwin-rebuild --list-generations

# Rollback to previous
darwin-rebuild rollback

# Or specific generation
darwin-rebuild --switch-generation 42
```

### Adding Packages

```bash
# 1. Edit packages file
nano ~/nix-darwin/modules/shared/packages.nix

# 2. Add package to environment.systemPackages
# Example: rustc

# 3. Rebuild
darwin-rebuild switch --flake ~/nix-darwin

# 4. Package is now installed!
which rustc
```

### Managing Secrets

```bash
# Edit secrets (auto-decrypts/encrypts)
sops ~/nix-darwin/secrets/secrets.yaml

# Add new secret
# Save and quit
# Rebuild to make available
darwin-rebuild switch --flake ~/nix-darwin
```

---

## Customization

### Add More Aliases

Edit `home/jimmy/shell/zsh.nix`:

```nix
shellAliases = {
  # ... existing aliases
  myalias = "your command here";
};
```

### Change VS Code Theme

Edit `home/jimmy/programs/vscode.nix`:

```nix
userSettings = {
  "workbench.colorTheme" = "Your Theme Name";
};
```

### Add GUI Apps

Edit `modules/darwin/homebrew.nix`:

```nix
casks = [
  # ... existing casks
  "your-app-name";
];
```

---

## Multi-Machine Setup

### Adding a New Machine

1. Create host config:

```bash
mkdir -p hosts/new-machine
nano hosts/new-machine/default.nix
```

2. Add to `flake.nix`:

```nix
darwinConfigurations."new-machine" = mkDarwinSystem {
  hostname = "new-machine";
  system = "aarch64-darwin";
  username = "jimmy";
  mixins = [ "base" "dev" "personal" ];  # Or "work"
};
```

3. On the new machine:

```bash
sudo scutil --set HostName new-machine
darwin-rebuild switch --flake .#new-machine
```

### Personal vs Work

The configuration automatically adjusts based on hostname:

- `mbp-jimmy`: Uses `personal` mixin
- `mbp-work`: Uses `work` mixin

Work Mac differences:

- ✅ Git email: work email vs GitHub no-reply
- ✅ AWS SSO functions instead of IAM
- ✅ Machine mode: 🏢 WORK vs 🏠 PERSONAL
- ✅ Homebrew can be disabled (toggle in host config)

---

## Troubleshooting

### "Command not found" after install

```bash
exec zsh  # Reload shell
```

### Hostname doesn't match

```bash
hostname -s  # Check current
sudo scutil --set HostName mbp-jimmy  # Fix it
```

### Build fails

```bash
# Show detailed error trace
darwin-rebuild switch --flake . --show-trace

# If all else fails, rollback
darwin-rebuild rollback
```

### Oh-My-Zsh not loading

```bash
# Check if installed
ls -la ~/.oh-my-zsh

# If not, install:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### VS Code extensions not installing

Some extensions require manual hash updates. If an extension fails:

1. Comment it out temporarily in `vscode.nix`
2. Rebuild
3. Install extension manually in VS Code
4. Or find the correct hash and update

### Secrets not working

```bash
# Check age key exists
ls -la ~/Library/Application\ Support/sops/age/keys.txt

# Verify .sops.yaml has your public key
cat ~/nix-darwin/secrets/.sops.yaml

# Rebuild
darwin-rebuild switch --flake ~/nix-darwin
```

---

## Learning Resources

- **Nix Package Search**: https://search.nixos.org/
- **Nix Darwin Manual**: https://daiderd.com/nix-darwin/
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml
- **SOPS Documentation**: https://github.com/getsops/sops

---

## Understanding the Setup

### Why Nix?

- **Reproducible**: Same config = same system, always
- **Declarative**: Describe what you want, not how
- **Rollback**: Instant undo if something breaks
- **Version control**: Your entire system in git

### Why Home Manager?

- **User-level configs**: Git, VS Code, Shell, etc.
- **100+ modules**: Pre-built configs for popular apps
- **Cross-platform**: Works on macOS and Linux

### Why sops-nix?

- **Encrypted secrets**: Safe to commit to git
- **Automatic deployment**: Secrets available on rebuild
- **Cloud integration**: AWS KMS, GCP KMS support

---

## Migration from ConfigHub

Your old configs have been migrated:

| ConfigHub                 | New Location                       |
| ------------------------- | ---------------------------------- |
| `.gitconfig`              | `home/jimmy/programs/git.nix`      |
| `.zshrc`                  | `home/jimmy/shell/zsh.nix`         |
| `code-user-settings.json` | `home/jimmy/programs/vscode.nix`   |
| `~/.zsh_secrets`          | `secrets/secrets.yaml` (encrypted) |
| `Brewfile`                | `modules/darwin/homebrew.nix`      |

**ConfigHub is no longer needed** - everything is in Nix!

---

## What You've Achieved

After setup, you have:

- ✅ **Fully declarative system**: One config, reproducible everywhere
- ✅ **Version controlled**: Every change tracked in git
- ✅ **Secure secrets**: Encrypted, but usable
- ✅ **Fast development**: nix-direnv, modern tools
- ✅ **Easy updates**: One command updates everything
- ✅ **Instant rollback**: Safety net for all changes
- ✅ **Multi-machine**: Same config on personal + work Macs
- ✅ **Modern best practices**: Following 2024-2025 standards

**Welcome to the future of system configuration!**

---

## Comprehensive Documentation

This repository includes **17 well-organized documentation files** covering every aspect:

### Start Here

1. **[START-HERE.md](docs/START-HERE.md)** 📍 - Main entry point (read this first!)
2. **[QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** ⚡ - One-page cheat sheet (print and keep visible)
3. **[Documentation Hub](docs/index.md)** - Complete documentation index

### Documentation Sections

**Guides (6 files)** - Practical, task-oriented documentation:

- **[Installation Guide](docs/guides/installation.md)** - Complete setup
- **[Usage Guide](docs/guides/usage.md)** - Daily usage, adding packages/aliases
- **[Backup & Recovery](docs/guides/backup-and-recovery.md)** - Safety and disaster recovery
- **[Secrets Management](docs/guides/secrets.md)** - Managing encrypted secrets
- **[Learning Modern CLI](docs/guides/learning.md)** - Modern tools and multi-machine setup
- **[Troubleshooting](docs/guides/troubleshooting.md)** - Common issues and solutions

**Reference (5 files)** - Exhaustive documentation:

- **[System Reference](docs/reference/system.md)** - Nix-Darwin, Home Manager
- **[Shell Reference](docs/reference/shell.md)** - Zsh, Git, Starship
- **[Languages Reference](docs/reference/languages.md)** - Python, Node.js
- **[Infrastructure Reference](docs/reference/infrastructure.md)** - AWS, Docker, Kubernetes, Terraform
- **[Tools Reference](docs/reference/tools.md)** - VS Code, AI/ML, Modern CLI, macOS

**Architecture (2 files)** - System design:

- **[Architecture Overview](docs/architecture/overview.md)** - How it all works
- **[Architecture Reference](docs/architecture/reference.md)** - File structure + best practices

**Appendix (1 file)** - All-in-one reference:

- **[FAQ & Reference](docs/appendix/faq.md)** - FAQ, Glossary, Resources, Changelog

---
