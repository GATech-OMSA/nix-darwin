# Installation Guide

**Complete installation and setup guide for nix-darwin**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Complete Installation](#complete-installation)
3. [First Steps](#first-steps)
4. [Additional Machines](#additional-machines)
5. [Migration](#migration)
6. [Multi-User Setup](#multi-user-setup)

---

## Quick Start

**Get up and running in 15-30 minutes**

### Prerequisites

- macOS (Ventura 13.0+ or Sonoma 14.0+)
- Admin access
- Internet connection
- ~10GB free disk space

### Quick Installation

```bash
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Set hostname
sudo scutil --set HostName mbp-jimmy  # or mbp-work

# 3. Clone repository
git clone https://github.com/YOUR-USERNAME/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# 4. Install nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy

# 5. Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 6. Install Zsh plugins
./scripts/install-zsh-plugins.sh

# 7. Restart terminal
exec zsh

# Note: Git hooks for secrets validation are installed automatically
```

### Verification

```bash
# Check installation
nix --version
hostname
echo $MACHINE_MODE

# Test git aliases
g s

# Expected prompt:
# home | Python: 3.13.8
# ~/nix-darwin on master
# ➜
```

---

## Complete Installation

### Step 1: Install Nix

**Install Nix package manager:**

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restart terminal
```

**What this installs:**

- Nix package manager
- Nix daemon
- Multi-user setup
- Flakes enabled by default

**Verify:**

```bash
nix --version
# nix (Nix) 2.31.2 or newer
```

**Alternative - Official Installer:**

```bash
sh <(curl -L https://nixos.org/nix/install)

# Enable flakes manually:
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Step 2: Set Hostname

Your hostname determines which configuration is used:

```bash
# For personal Mac
sudo scutil --set HostName mbp-jimmy
sudo scutil --set LocalHostName mbp-jimmy
sudo scutil --set ComputerName "Jimmy's MacBook Pro"

# For work Mac
sudo scutil --set HostName mbp-work
sudo scutil --set LocalHostName mbp-work
sudo scutil --set ComputerName "Jimmy's Work MacBook"

# Verify
hostname
```

**Important:** Hostname determines:

- Which machine-specific config is loaded (personal.nix or work.nix)
- MACHINE_MODE environment variable (home or work)
- AWS profile settings
- Git email configuration

### Step 3: Clone Repository

```bash
# Clone to home directory
cd ~
git clone https://github.com/YOUR-USERNAME/nix-darwin.git
cd nix-darwin

# Or with SSH (recommended):
git clone git@github.com:YOUR-USERNAME/nix-darwin.git
cd nix-darwin
```

**If forking:**

```bash
# Fork on GitHub first, then:
git clone https://github.com/YOUR-USERNAME/nix-darwin.git
cd nix-darwin
```

### Step 4: Install Nix-Darwin

**For personal Mac (mbp-jimmy):**

```bash
cd ~/nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy
```

**For work Mac (mbp-work):**

```bash
cd ~/nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-work
```

**What this does:**

- Installs nix-darwin system manager
- Installs Home Manager
- Installs all packages from packages.nix
- Sets up Homebrew and casks
- Generates configuration files (~/.zshrc, ~/.gitconfig, etc.)
- Configures system settings

**Takes:** ~15-30 minutes on first build

**Watch for:**

- Package downloads (~5-10 GB)
- Homebrew installation
- System settings changes

### Step 5: Install Oh-My-Zsh

Oh-My-Zsh cannot be installed via Nix and must be installed manually:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# When prompted:
# - Say YES to make zsh default shell
# - Say NO to changing .zshrc (managed by Nix)
```

### Step 6: Install Custom Zsh Plugins

```bash
cd ~/nix-darwin
./scripts/install-zsh-plugins.sh
```

**Installs:**

- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- you-should-use
- zsh-history-substring-search

### Step 7: Restart Terminal

```bash
# Completely quit and restart terminal app (Cmd+Q)
# Or run:
exec zsh
```

---

## First Steps

### 1. Verify Installation

```bash
# Check Nix
nix --version

# Check Darwin
darwin-rebuild --version

# Check machine mode
echo $MACHINE_MODE  # home or work

# Test git aliases
g s  # Should show git status

# Test modern tools
ll   # Better ls
bat README.md  # Syntax highlighted

# Check Python
python --version
```

### 2. Personalize Configuration

**Update Git info:**

```bash
gitconf  # Opens git.nix in VS Code

# Update if needed:
# user = {
#   name = "Your Name";
#   email = "your@email.com";
# };

nix-rebuild
```

**Add custom aliases:**

```bash
zshconf  # Opens zsh.nix in VS Code

# Add to shellAliases:
# myproject = "cd ~/Dev/my-main-project";

nix-rebuild
exec zsh
```

### 3. Create Dev Directory

```bash
mkdir -p ~/Dev/{algorithms,learning,ai-ml,courses,experiments,oss-contributions}

tree ~/Dev -L 1
```

### 4. Set Up SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your@email.com"

# Add to ssh-agent
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub | pbcopy

# Add to GitHub: Settings → SSH Keys → New SSH Key
# Paste key (Cmd+V)

# Test
ssh -T git@github.com
```

### 5. Configure VS Code

```bash
# Open VS Code
vs

# Install manual extensions:
# 1. Extensions → Search "Vitesse"
# 2. Install Vitesse Dark/Light themes

# Select theme:
# Cmd+K Cmd+T → Vitesse Dark
```

### 6. Configure iTerm2 (if using)

1. Open iTerm2
2. Preferences (Cmd+,) → Profiles → Text
3. Font: MesloLGM Nerd Font, 13pt
4. Profiles → Colors: Import theme if desired
5. Profiles → Terminal: xterm-256color

### 7. Set Up Secrets File

```bash
# Create secrets file
touch ~/.zsh_secrets
chmod 600 ~/.zsh_secrets

# Edit it
code ~/.zsh_secrets
```

**Add your secrets:**

```bash
# API Keys
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."

# Other secrets
export SECRET_KEY="..."
```

**Reload shell:**

```bash
exec zsh
```

### 8. Verify Git Hooks Installation

**Git hooks are automatically installed** on every rebuild to prevent committing unencrypted secrets:

```bash
# Check if hooks are installed
secrets-status

# Expected output:
# 🪝 Git Hooks:
#   ✅ Git hooks installed (pre-commit, pre-push)
#      Hooks automatically validate secrets encryption
```

**What these hooks do:**

- **pre-commit**: Blocks commits containing unencrypted secrets files
- **pre-push**: Blocks pushes containing unencrypted secrets files

**Automatic Installation:**

- Hooks are installed automatically during `nix-rebuild`

**Manual Installation (if needed):**

```bash
# Only needed if you want to install manually
~/nix-darwin/scripts/install-hooks.sh
```

### 9. Configure AWS (if needed)

**Personal Mac:**

```bash
mkdir -p ~/.aws
awsconf  # Edit config

# Add personal profile(s)
```

**Work Mac:**

```bash
mkdir -p ~/.aws
awsconf  # Edit config

# Add work profiles with SSO
# Login via SSO
awslogin
```

### 10. Test Python Setup

```bash
# Create first UV project
uv-new hello-world
cd ~/Dev/hello-world

# Virtual environment auto-activates
# 🐍 Activated UV virtual environment: .venv

# Add dependencies
uv-add requests

# Start coding
vs
```

### 11. Create Backup

```bash
cd ~/nix-darwin

# Commit customizations
g aa
g cm "Initial customization for $(hostname)"
g ps

# Document changes
cat > CUSTOMIZATIONS.md <<EOF
# My Customizations

## Changes Made
- Updated git user info
- Added custom aliases
- Configured AWS
- Set up SSH keys

## Date
$(date)
EOF

g aa
g cm "Document customizations"
g ps
```

---

## Additional Machines

### Setting Up a Second Machine

**Same repository, different machine:**

```bash
# 1. On new machine, clone repository
cd ~
git clone https://github.com/YOUR-USERNAME/nix-darwin.git
cd nix-darwin

# 2. Set correct hostname
sudo scutil --set HostName mbp-work  # or mbp-jimmy

# 3. Build for this machine
sudo nix run nix-darwin -- switch --flake .#mbp-work

# 4. Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 5. Install Zsh plugins
./scripts/install-zsh-plugins.sh

# 6. Restart terminal
exec zsh
```

### Syncing Changes

**Make changes on one machine:**

```bash
# Personal Mac
cd ~/nix-darwin
gitconf  # Add new git alias
nix-rebuild
g aa && g cm "Add new git alias" && g ps
```

**Update other machine:**

```bash
# Work Mac
cd ~/nix-darwin
g pl  # Pull changes
nix-rebuild
# New alias now available!
```

### Machine-Specific Settings

Use mixins for machine-specific configuration:

**Personal** (`home/_mixins/personal.nix`):

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };
}
```

**Work** (`home/_mixins/work.nix`):

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "example-corp";
  };

  home.shellAliases = {
    vpn = "sudo openconnect vpn.company.com";
  };
}
```

---

## Migration

### From Homebrew-Only Setup

**1. Inventory packages:**

```bash
brew list > ~/migration-backup/brew-packages.txt
brew list --cask > ~/migration-backup/brew-casks.txt
```

**2. Find Nix equivalents:**

```bash
# Search for package
nix search nixpkgs ripgrep
nix search nixpkgs fzf
```

**3. Add to packages.nix:**

```nix
environment.systemPackages = with pkgs; [
  ripgrep    # was: brew install ripgrep
  fzf        # was: brew install fzf
  jq         # was: brew install jq
];
```

**4. Keep GUI apps as Homebrew casks:**

```nix
# modules/darwin/homebrew.nix
homebrew.casks = [
  "google-chrome"
  "visual-studio-code"
  "docker"
];
```

### From Manual Dotfiles

**1. Extract aliases:**

```bash
# View current aliases
cat ~/.zshrc | grep "alias" > ~/migration-backup/my-aliases.txt
```

**2. Convert to Nix format:**

**Your old .zshrc:**

```bash
alias ll="ls -la"
alias dev="cd ~/Development"
alias gs="git status"
```

**New format in zsh.nix:**

```nix
home.shellAliases = {
  ll = "ls -la";
  dev = "cd ~/Development";
  # Note: git aliases use 'g' prefix
  # gs -> use 'g s' instead
};
```

**3. Extract functions:**

**Your old .zshrc:**

```bash
function mkcd() {
  mkdir -p "$1" && cd "$1"
}
```

**New format in zsh.nix:**

```nix
programs.zsh.initExtra = ''
  mkcd() {
    mkdir -p "$1" && cd "$1"
  }
'';
```

**4. Extract environment variables:**

**Your old .zshrc:**

```bash
export EDITOR="vim"
export PATH="$HOME/bin:$PATH"
```

**New format in zsh.nix:**

```nix
home.sessionVariables = {
  EDITOR = "vim";
};

home.sessionPath = [
  "$HOME/bin"
];
```

### From Linux/NixOS

**Key differences:**

| NixOS                   | Nix-Darwin            |
| ----------------------- | --------------------- |
| `configuration.nix`     | `flake.nix` + modules |
| `nixos-rebuild`         | `darwin-rebuild`      |
| System-level everything | Mix of Nix + Homebrew |
| `systemd`               | `launchd`             |

**Adapt services:**

```bash
# NixOS services don't work on macOS
# Use Homebrew services instead:
brew install postgresql@15
brew services start postgresql@15
```

**Home Manager works the same:**

```nix
# Same syntax on both!
programs.git = {
  enable = true;
  userName = "Jimmy";
};
```

### Migration Workflow

**1. Backup everything:**

```bash
mkdir -p ~/migration-backup

# Dotfiles
cp ~/.zshrc ~/migration-backup/
cp ~/.gitconfig ~/migration-backup/
cp -r ~/.config ~/migration-backup/config-backup

# Export configs
git config --list > ~/migration-backup/git-config.txt
alias > ~/migration-backup/aliases.txt
env > ~/migration-backup/env-vars.txt

# Homebrew
brew list > ~/migration-backup/brew-packages.txt
brew list --cask > ~/migration-backup/brew-casks.txt
```

**2. Install nix-darwin** (follow steps above)

**3. Gradually migrate:**

- Start with system packages
- Then shell aliases
- Then git config
- Then application configs
- Finally environment variables

**4. Keep old setup accessible:**

```bash
# Keep old dotfiles as .old
mv ~/.zshrc ~/.zshrc.old
mv ~/.gitconfig ~/.gitconfig.old
```

**5. Test thoroughly:**

- Test daily workflow
- Test all custom scripts
- Test all tools used regularly
- Verify secrets/credentials still work

**6. Document changes:**

```bash
cat > ~/nix-darwin/CUSTOMIZATIONS.md <<EOF
# Migration Notes

## Migrated from old .zshrc
- Added alias: xyz
- Added function: abc

## Date: $(date)
EOF
```

---

## Troubleshooting

### Build Errors

```bash
# Show detailed errors
darwin-rebuild switch --flake . --show-trace

# Check flake
nix flake check

# Common issues:
# - Missing semicolon in Nix
# - Typo in package name
# - Invalid syntax
```

### File Conflicts

```bash
# Error: File exists and is not a symlink
# Backup and retry:
mv ~/.zshrc ~/.zshrc.backup
nix-rebuild
```

### Oh-My-Zsh Errors

```bash
# If oh-my-zsh not found:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# If plugins not working:
./scripts/install-zsh-plugins.sh
```

### Slow First Build

First build downloads everything (~5-10 GB):

- Be patient
- Good internet connection helps
- Subsequent rebuilds are fast (~30 seconds)

### Command Not Found After Install

```bash
# Restart shell
exec zsh

# Or reload PATH
source ~/.zshrc
```

---

## Post-Installation Checklist

- [ ] Nix installed and working (`nix --version`)
- [ ] Hostname set correctly (`hostname`)
- [ ] nix-darwin built successfully
- [ ] Oh-My-Zsh installed
- [ ] Zsh plugins installed
- [ ] Git config verified (`g config --list`)
- [ ] SSH keys generated and added to GitHub
- [ ] Python environment working (`python --version`)
- [ ] VS Code configured with themes
- [ ] AWS configured (if needed)
- [ ] Secrets file created (`~/.zsh_secrets`)
- [ ] First commit pushed

---

## Clean Slate (If Needed)

If you need to start over:

```bash
# Remove Nix-Darwin
sudo /nix/nix-installer uninstall

# Remove Nix completely
sudo rm -rf /nix

# Remove configs
rm -rf ~/.zshrc ~/.gitconfig ~/.config/nix

# Start from Step 1
```

---

## System Requirements

### Disk Space

- **Nix store:** ~5-8 GB
- **Build cache:** ~2-3 GB
- **Total recommended:** 10+ GB free

### Performance

- **Apple Silicon:** Excellent performance
- **Intel Mac:** Good performance
- **RAM:** 8GB minimum, 16GB recommended

---

## Time Estimates

| Task              | Time          |
| ----------------- | ------------- |
| Install Nix       | 2-5 min       |
| Set hostname      | 1 min         |
| Clone repo        | 1 min         |
| Initial build     | 15-30 min     |
| Install Oh-My-Zsh | 2 min         |
| Install plugins   | 1 min         |
| Post-installation | 10-20 min     |
| **Total**         | **30-60 min** |

---

## Multi-User Setup

This configuration supports multiple users and usernames out of the box. If you want to:

- **Use a different username** (not "jimmy")
- **Share this config** with family members or team
- **Manage multiple machines** with different users

See the **[Multi-User Setup Guide](multi-user-setup.md)** for detailed instructions.

**Quick Overview:**

1. Edit `flake.nix` to add your machine with your username:
   ```nix
   darwinConfigurations."your-hostname" = mkDarwinSystem {
     hostname = "your-hostname";
     username = "your-username";  # ← Your username here
     mixins = [ "base" "dev" "personal" ];
   };
   ```

2. Copy home directory: `cp -r home/jimmy home/your-username`

3. Create host config: `mkdir hosts/your-hostname`

4. Run installation: `sudo nix run nix-darwin -- switch --flake .#your-hostname`

All paths, aliases, and configurations automatically adapt to your username.

---

## Next Steps

1. **[Usage Guide](usage.md)** - Learn daily workflows
2. **[Secrets Management](secrets.md)** - Set up encrypted secrets
3. **[Learning Guide](learning.md)** - Learn modern CLI tools
4. **[Multi-User Setup](multi-user-setup.md)** - Configure for different users

---

## Resources

- [Nix Installation](https://nixos.org/download.html)
- [Nix-Darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Determinate Systems](https://determinate.systems/posts/determinate-nix-installer)

---
