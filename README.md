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
├── flake.nix                 # Entry point
├── config/                   # Machine and user configuration (gitignored)
│   ├── machine-config.nix    # machineId + machineType
│   └── user-config.nix       # username + email
├── nix-config/               # All Nix configuration files
│   ├── hosts/                # Machine-specific configs + secrets
│   │   ├── _template/        # Template for new machines
│   │   └── macbook-pro-m1/   # Machine configs (secrets.yaml, etc.)
│   ├── home/                 # Home Manager configurations
│   │   ├── _profiles/        # Profile system (personal/work/minimal)
│   │   │   ├── _template/    # Shared programs and shell configs
│   │   │   ├── personal/     # Personal profile behavior
│   │   │   ├── work/         # Work profile behavior
│   │   │   └── minimal/      # Bare-bones troubleshooting
│   │   ├── _mixins/          # Reusable configuration mixins
│   │   └── _template/        # Base template configurations
│   ├── modules/              # System packages + settings (darwin/shared)
│   ├── lib/                  # 30+ helper functions
│   ├── overlays/             # Package customizations
│   └── pkgs/                 # Custom packages
├── scripts/                  # Utility scripts
│   ├── setup/                # Initial setup scripts
│   ├── secrets/              # Secret management scripts
│   ├── maintenance/          # System maintenance
│   └── workspace/            # Backup and restore
    ├── docs/                 # User-facing documentation
├── workspace/                # Per-machine workspace (gitignored)
└── secrets/                  # Local secrets storage (gitignored)
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

### Step 3: Run Configuration Script

The `configure.sh` script will guide you through setup and let you choose your machine ID:

```bash
# Run interactive configuration
./scripts/setup/configure.sh

# You'll be asked for:
# - Username, email, full name
# - Machine ID (can be anything: macbook-pro-m1, my-mac, dev-machine, etc.)
# - Profile type (personal/work/minimal)
# - Homebrew preference

# Machine ID is used for: flake targets, host directories, and secrets location
```

### Step 4: Set Up Secrets (Optional but Recommended)

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

### Step 5: Initial Build

The flake target uses your machine ID from config/machine-config.nix:

```bash
cd ~/nix-darwin

# First-time installation (takes 15-30 minutes)
# Replace <machine-id> with your chosen ID from configure.sh
sudo nix run nix-darwin -- switch --flake .#<machine-id>

# Examples:
# sudo nix run nix-darwin -- switch --flake .#macbook-pro-m1
# sudo nix run nix-darwin -- switch --flake .#mbp-work
# sudo nix run nix-darwin -- switch --flake .#my-awesome-mac
```

### Step 6: Install Oh-My-Zsh & Custom Plugins

```bash
# Install Oh-My-Zsh (Nix can't install this directly)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Custom zsh plugins are managed by nix-darwin
# No manual installation needed

# Restart terminal
exec zsh
```

### Step 7: Set Up Python Environment

```bash
# Micromamba is already installed, create your environment
# Option 1: Using the mkenv convenience function (recommended)
m-mkenv dev 3.13

# Option 2: Using micromamba directly
micromamba create -n dev python=3.12 -y

# Activate your environment
m-act dev  # or: micromamba activate dev
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

### Essential Shortcuts

**System & Configuration:**
```bash
nixconf              # Open nix-darwin in VS Code
nix-rebuild          # Rebuild system (with pre-flight checks)
nix-rollback         # Rollback to previous generation
nix-health           # System health check
reload               # Reload shell config
restart              # Restart shell (exec zsh)
c                    # Clear terminal
vs / vscode          # Open VS Code in current directory
```

**Secrets Management:**
```bash
secrets-status       # Check secrets setup & encryption status
secrets-edit         # Edit encrypted secrets (SOPS)
secrets-view         # View decrypted secrets
secrets-rescan       # Rescan for new secrets
secrets-backup       # Backup secrets
secrets-audit        # Audit secret locations
```

**Git Shortcuts:**
```bash
g                    # git
g s / gs             # git status -s
g aa                 # git add -A
g cm                 # git commit
g ps                 # git push
g pl                 # git pull
gsw                  # git switch
gswc                 # git switch -c (create branch)
```

**Navigation:**
```bash
dev                  # cd ~/Dev
downloads / down     # cd ~/Downloads
desktop / desk       # cd ~/Desktop
fdev                 # Open ~/Dev in Finder
fdown                # Open ~/Downloads in Finder
..                   # cd ..
...                  # cd ../..
```

**Modern CLI Tools:**
```bash
ls / ll / la         # eza with icons
cat                  # bat (syntax highlighting)
grep                 # ripgrep
find                 # fd (fast find)
```

**Python/Micromamba:**
```bash
py                   # python
m-act                # micromamba activate
m-create             # micromamba create
m-list               # micromamba env list
jl                   # jupyter lab
jn                   # jupyter notebook
```

See complete alias list: `workspace/macbook-pro-m1/my-aliases-complete.md`

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
nixconf              # Opens VS Code to nix-darwin directory

# 2. Rebuild
nix-rebuild          # Short alias for rebuild + restart

# 3. Changes take effect immediately!
# Alternative: darwin-rebuild switch --flake ~/nix-darwin
```

### Rolling Back

```bash
# Quick rollback
nix-rollback         # Rollback to previous generation + restart

# List generations
darwin-rebuild --list-generations

# Or specific generation
darwin-rebuild --switch-generation 42
```

### Adding Packages

```bash
# 1. Edit packages file
nano ~/nix-darwin/nix-config/modules/shared/packages.nix

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

Edit `nix-config/home/_profiles/_template/shell/zsh.nix`:

```nix
shellAliases = {
  # ... existing aliases
  myalias = "your command here";
};
```

### Change VS Code Theme

Edit `nix-config/home/_profiles/_template/programs/vscode.nix`:

```nix
userSettings = {
  "workbench.colorTheme" = "Your Theme Name";
};
```

### Add GUI Apps

Edit `nix-config/modules/darwin/homebrew.nix`:

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
mkdir -p nix-config/hosts/new-machine
nano nix-config/hosts/new-machine/default.nix
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

The configuration automatically adjusts based on **profile type** set in `config/machine-config.nix`:

- `profileName = "personal"`: Personal machine behavior
- `profileName = "work"`: Work machine behavior
- `profileName = "minimal"`: Minimal/troubleshooting setup

**Note**: Profile is determined by `config/machine-config.nix`, NOT by hostname or machine ID!

Work profile differences:

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

### Wrong profile active

```bash
# Check current profile
echo $ACTIVE_PROFILE

# Change profile: edit config/machine-config.nix
nano config/machine-config.nix
# Change: profileName = "personal";  # or "work" or "minimal"

# Then rebuild
nix-rebuild && exec zsh
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

| ConfigHub                 | New Location                                                |
| ------------------------- | ----------------------------------------------------------- |
| `.gitconfig`              | `nix-config/home/_profiles/_template/programs/git.nix`      |
| `.zshrc`                  | `nix-config/home/_profiles/_template/shell/zsh.nix`         |
| `code-user-settings.json` | `nix-config/home/_profiles/_template/programs/vscode.nix`   |
| `~/.zsh_secrets`          | `nix-config/hosts/*/secrets.yaml` (encrypted)               |
| `Brewfile`                | `nix-config/modules/darwin/homebrew.nix`                    |

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

## Documentation

**Focused learning with comprehensive reference**

### Quick Start

1. **[Installation Guide](docs/installation.md)** - Complete setup instructions
2. **[Learning Guide](docs/learning/README.md)** - Progressive Nix learning path
3. **[Documentation Hub](docs/README.md)** - All available documentation

### Comprehensive Reference

For detailed documentation, see **[docs/](docs/)**:

- **Essential Guides** - Installation, secrets, troubleshooting, backup & recovery
- **Learning** - Nix and nix-darwin learning resources (1,480 lines!)
- **Work** - AWS multi-account configuration (work profile)
- **Modern Tools** - CLI tools reference

> **Note:** Technical documentation (ADRs, component READMEs, etc.) archived to `.deprecate/` during Nov 2025 cleanup. Contact maintainer if you need access to archived docs.

---
