# Installation Guide

**Complete installation and setup guide for nix-darwin v2.0.0**

**Last Updated**: 2025-11-10 (v2.0.0 - Profile-based architecture)

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Complete Installation](#complete-installation)
3. [First Steps](#first-steps)
4. [Additional Machines](#additional-machines)
5. [Migration](#migration)

---

## Quick Start

**Get up and running in 20-30 minutes with the three-script workflow**

### Prerequisites

- macOS (Ventura 13.0+ or Sonoma 14.0+)
- Admin access
- Internet connection
- ~10GB free disk space

### Quick Installation (Three-Script Workflow)

```bash
# 1. Clone repository
git clone https://github.com/YOUR-USERNAME/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# 2. Bootstrap (Install Nix, nix-darwin, SOPS, age)
./scripts/bootstrap.sh

# 3. Configure (Interactive wizard - generates config files)
./scripts/configure.sh

# 4. Activate (Build and apply system)
./scripts/activate.sh

# 5. Restart terminal
exec zsh
```

### Verification

```bash
# Check installation
nix --version
echo $ACTIVE_PROFILE  # personal, work, or minimal

# Test git aliases
g s

# Expected prompt:
# personal | Python: 3.13.8
# ~/nix-darwin on feature/git-privacy-complete
# ➜
```

---

## Complete Installation

### Overview: Three-Script Workflow

v2.0.0 introduces a streamlined three-script installation process:

| Script | Purpose | Duration |
|--------|---------|----------|
| **bootstrap.sh** | Install prerequisites (Nix, nix-darwin, SOPS, age) | 5-10 min |
| **configure.sh** | Interactive configuration wizard, secret scanning | 10-15 min |
| **activate.sh** | Build and activate system with encryption | 15-30 min |

### Step 1: Clone Repository

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

### Step 2: Bootstrap (Install Prerequisites)

```bash
cd ~/nix-darwin
./scripts/bootstrap.sh
```

**What this installs:**

1. **Nix Package Manager**
   - Determinate Systems installer (Nix 2.31.2+)
   - Flakes enabled by default
   - Multi-user daemon setup

2. **nix-darwin**
   - System configuration manager for macOS
   - Integrates with Home Manager

3. **SOPS (Secrets OPerationS)**
   - Secret encryption tool
   - Age-based encryption

4. **age**
   - Modern encryption tool
   - Used for secret management

**Restart terminal after bootstrap:**

```bash
exec zsh
```

### Step 3: Configure (Interactive Wizard)

```bash
cd ~/nix-darwin
./scripts/configure.sh
```

**Configuration wizard will:**

1. **Collect User Information**
   - Username (auto-detected)
   - Full name
   - Email address

2. **Collect Machine Information**
   - Machine ID (unique identifier, e.g., mbp-personal-001)
   - Profile selection (personal, work, minimal)
   - Machine description

3. **Secret Scanning**
   - Scans for existing secrets (~/.db/, ~/.aws/credentials, .env files)
   - Creates secret templates based on selected profile
   - Generates SOPS age encryption keys

4. **Generate Configuration Files**
   - `config/user-config.nix` (gitignored - your personal info)
   - `config/machine-config.nix` (gitignored - machine identity)
   - Profile-specific secret templates

**Profile Options:**

| Profile | Description | Best For |
|---------|-------------|----------|
| **personal** | Personal machine setup | Home computers, personal projects |
| **work** | Work machine setup | Corporate environments, work projects |
| **minimal** | Bare-bones setup | Troubleshooting, minimal installs |

**Secret Templates Created:**

- **Personal profile**: `hosts/[machine-id]/secrets-personal.nix`
- **Work profile**: `hosts/[machine-id]/secrets-work.nix` (includes AWS SSO)
- Both encrypted with SOPS age encryption

### Step 4: Activate (Build and Apply System)

```bash
cd ~/nix-darwin
./scripts/activate.sh
```

**What this does:**

1. **Validates Configuration**
   - Checks config files exist
   - Validates FLAKE_ROOT environment variable
   - Detects placeholders in secret templates

2. **Encrypts Secrets**
   - Prompts you to fill secret placeholders
   - Encrypts secrets.yaml with SOPS age
   - Validates encryption

3. **Builds System**
   - Runs `darwin-rebuild switch --flake . --impure`
   - Installs all packages
   - Sets up Homebrew and casks
   - Generates configuration files (~/.zshrc, ~/.gitconfig, etc.)
   - Configures system settings

4. **Installs Git Hooks**
   - Pre-commit: Validates secret encryption
   - Pre-push: Prevents pushing unencrypted secrets

**Takes:** ~15-30 minutes on first build

**Watch for:**
- Package downloads (~5-10 GB)
- Homebrew installation
- System settings changes

### Step 5: Restart Terminal

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

# Check active profile
echo $ACTIVE_PROFILE  # personal, work, or minimal
echo $MACHINE_MODE    # home, work, or minimal

# Test git aliases
g s  # Should show git status

# Test modern tools
ll   # Better ls
bat README.md  # Syntax highlighted cat

# Check Python
python --version
```

### 2. Personalize Configuration

**Update Git info (if needed):**

```bash
nixconf  # Opens VS Code with repository

# Edit: home/_profiles/_template/programs/git.nix
# user = {
#   name = "Your Name";
#   email = "your@email.com";  # Profile-specific email set automatically
# };

nix-rebuild && exec zsh
```

**Add custom aliases:**

```bash
nixconf  # Opens VS Code

# For all profiles: home/_profiles/_template/shell/zsh.nix
# For personal only: home/_profiles/personal/aliases.nix
# For work only: home/_profiles/work/aliases.nix

# Add to shellAliases:
# myproject = "cd ~/Dev/my-main-project";

nix-rebuild && exec zsh
```

### 3. Manage Secrets

**View current secrets:**

```bash
secrets-status
```

**Edit secrets (interactive):**

```bash
edit-secrets  # Opens SOPS editor with auto-encryption

# Add your secrets:
# api_keys:
#   openai: "sk-..."
#   anthropic: "sk-ant-..."
```

**Secret files created by configure.sh:**
- `hosts/[machine-id]/secrets.yaml` (encrypted with SOPS)
- `hosts/[machine-id]/secrets-personal.nix` or `secrets-work.nix` (Nix import)

### 4. Create Dev Directory

```bash
mkdir -p ~/Dev/{algorithms,learning,ai-ml,courses,experiments,oss-contributions}

tree ~/Dev -L 1
```

### 5. Set Up SSH Keys

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

### 6. Configure VS Code

```bash
# Open VS Code
vs

# Install manual extensions:
# 1. Extensions → Search "Vitesse"
# 2. Install Vitesse Dark/Light themes

# Select theme:
# Cmd+K Cmd+T → Vitesse Dark
```

### 7. Configure AWS (Work Profile Only)

**If you selected work profile, AWS SSO multi-account support is available:**

```bash
# 1. Edit AWS account mapping (interactive editor)
edit-aws-map

# 2. Follow the interactive guide to map AWS accounts
# See: AWS Multi-Role Guide (available in work profile setup)

# 3. Login to AWS SSO
awslogin

# 4. Switch between accounts
awsuse dev    # Switches to development account
awsuse prod   # Switches to production account
```

**AWS SSO account mapping:**
- Template: `home/_profiles/work/accounts.json.template`
- Encrypted storage: `hosts/[machine-id]/secrets.yaml` (aws_accounts field)
- Deployed to: `~/.aws/accounts.json` (auto-generated from secrets)

See [AWS Multi-Role Guide](../reference/aws/AWS-MULTI-ROLE.md) for complete setup instructions.

### 8. Test Python Setup

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

### 9. Create Backup

```bash
cd ~/nix-darwin

# Commit customizations (config files are gitignored)
g aa
g cm "Initial setup for $(hostname)"
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

# 2. Run three-script workflow
./scripts/bootstrap.sh
exec zsh

./scripts/configure.sh
# Select different profile if needed (e.g., work vs personal)

./scripts/activate.sh
exec zsh
```

**configure.sh will:**
- Auto-detect you're on a new machine
- Create new machine-specific configuration
- Generate new machine ID (e.g., mbp-work-001)
- Create new secret templates for this machine

**Result:**
- New gitignored config files (config/user-config.nix, config/machine-config.nix)
- New gitignored host directory (hosts/[new-machine-id]/)
- Profile selected independently per machine

### Syncing Changes

**Make changes on one machine:**

```bash
# Personal Mac
cd ~/nix-darwin
nixconf  # Add new git alias to _template profile
nix-rebuild
g aa && g cm "Add new git alias" && g ps
```

**Update other machine:**

```bash
# Work Mac
cd ~/nix-darwin
g pl  # Pull changes
nix-rebuild
# New alias now available on work machine too!
```

### Profile-Specific Settings

**Profiles are self-contained and override template behavior:**

**Template** (`home/_profiles/_template/`):
- Shared programs (git, vscode, zsh, starship)
- Universal shell configs
- Base functionality all profiles inherit

**Personal** (`home/_profiles/personal/`):
- Personal navigation aliases (Dev/, learning/, algorithms/)
- Personal git email
- No database or AWS configurations

**Work** (`home/_profiles/work/`):
- Work database instances (6 pre-configured)
- AWS SSO multi-account support
- Work git email
- Work-specific aliases

**Minimal** (`home/_profiles/minimal/`):
- Bare-bones setup for troubleshooting
- Only essential tools (zsh, starship, fzf)

### Switching Profiles

**To change profile on current machine:**

```bash
# Edit machine config
code config/machine-config.nix

# Change profileName field:
# profileName = "work";  # or "personal" or "minimal"

# Rebuild
nix-rebuild && exec zsh

# Verify
echo $ACTIVE_PROFILE
```

**Future enhancement:** Profile switcher script (see BACKLOG.md)

---

## Migration

### From Pre-v2.0.0 nix-darwin

**v2.0.0 Breaking Changes:**

1. **Configuration files required**
   - `config/user-config.nix` (username, email, fullName)
   - `config/machine-config.nix` (machineId, profileName)

2. **Hostname-based detection replaced**
   - Old: Hostname determined behavior (macbook-pro-m1 → personal)
   - New: Profile selection in machine-config.nix

3. **Impure builds required**
   - All builds require `--impure` flag (auto-handled by `nix-rebuild` alias)
   - FLAKE_ROOT environment variable required

**Migration Steps:**

```bash
# 1. Backup current state
cd ~/nix-darwin
g aa && g cm "backup before v2.0.0 migration"

# 2. Pull v2.0.0
g pl origin main

# 3. Run configure.sh to generate config files
./scripts/configure.sh

# 4. Activate new configuration
./scripts/activate.sh

# 5. Verify
health-check
echo $ACTIVE_PROFILE
```

See CHANGELOG.md for complete v2.0.0 migration guide.

### From Homebrew-Only Setup

**1. Inventory packages:**

```bash
mkdir -p ~/migration-backup
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

**New format (profile-specific):**

```nix
# home/_profiles/personal/aliases.nix
{
  home.shellAliases = {
    ll = "ls -la";
    dev = "cd ~/Development";
    # Note: git aliases use 'g' prefix
    # gs -> use 'g s' instead
  };
}
```

**3. Extract functions:**

**Your old .zshrc:**

```bash
function mkcd() {
  mkdir -p "$1" && cd "$1"
}
```

**New format:**

```nix
# home/_profiles/_template/shell/zsh.nix
programs.zsh.initContent = ''
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

**New format:**

```nix
home.sessionVariables = {
  EDITOR = "vim";
};

home.sessionPath = [
  "$HOME/bin"
];
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

**2. Install nix-darwin v2.0.0** (follow steps above)

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

---

## Troubleshooting

### Build Errors

```bash
# Show detailed errors
nix-rebuild --show-trace

# Check flake
nix flake check

# Common issues:
# - Missing semicolon in Nix
# - Typo in package name
# - Invalid syntax
# - FLAKE_ROOT not set (use nix-rebuild alias)
```

### Configuration File Issues

```bash
# Check config files exist
ls -la config/

# Expected:
# config/user-config.nix (gitignored)
# config/machine-config.nix (gitignored)

# Regenerate if missing:
./scripts/configure.sh
```

### Profile Not Active

```bash
# Check active profile
echo $ACTIVE_PROFILE

# If wrong profile:
# 1. Edit config/machine-config.nix
# 2. Change profileName field
# 3. Rebuild: nix-rebuild && exec zsh
```

### Secret Encryption Errors

```bash
# Check age keys exist
ls ~/.config/sops/age/

# View secrets status
secrets-status

# Re-encrypt if needed
edit-secrets
```

### Placeholder Detection

```bash
# If activation fails with placeholder warnings:
# 1. Edit secret templates
code hosts/$(hostname)/secrets-personal.nix

# 2. Replace all <PLACEHOLDER> values
# 3. Run activation again
./scripts/activate.sh
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
- [ ] Profile selected (`echo $ACTIVE_PROFILE`)
- [ ] Config files generated (`ls config/`)
- [ ] nix-darwin built successfully
- [ ] Git config verified (`g config --list`)
- [ ] SSH keys generated and added to GitHub
- [ ] Python environment working (`python --version`)
- [ ] VS Code configured with themes
- [ ] AWS configured (work profile only)
- [ ] Secrets encrypted (`secrets-status`)
- [ ] Git hooks installed (automatic)
- [ ] First commit pushed

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

| Task | Time |
|------|------|
| Bootstrap (Nix, nix-darwin, SOPS, age) | 5-10 min |
| Configure (Interactive wizard) | 10-15 min |
| Activate (Initial build) | 15-30 min |
| Post-installation setup | 10-20 min |
| **Total** | **40-75 min** |

---

## Next Steps

1. **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Debug common issues
2. **[Secrets Management](SECRETS.md)** - Manage encrypted secrets
3. **[Backup & Recovery](backup-and-recovery.md)** - Protect your configuration
4. **[AWS Multi-Role Guide](../reference/aws/AWS-MULTI-ROLE.md)** - AWS SSO setup (work profile)

---

## Resources

- [Nix Installation](https://nixos.org/download.html)
- [Nix-Darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Determinate Systems](https://determinate.systems/posts/determinate-nix-installer)
- [SOPS Documentation](https://github.com/getsops/sops)
- [age Encryption](https://github.com/FiloSottile/age)

---

**Version**: v2.0.0
**Last Updated**: 2025-11-10
**Architecture**: Profile-based with three-script workflow
