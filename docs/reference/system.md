# System Reference

**Nix Darwin, Home Manager, and Helper Functions**

[← Back to Index](../index.md)

---

## Table of Contents

- [Nix Darwin](#nix-darwin)
  - [Core Commands](#core-commands)
  - [First-Time Installation](#first-time-installation)
  - [Aliases](#nix-darwin-aliases)
  - [Update Workflow](#update-workflow)
  - [Generations](#generations)
  - [Cleanup](#cleanup)
  - [Troubleshooting](#troubleshooting-nix-darwin)
  - [Configuration Files](#configuration-files)
  - [Common Workflows](#common-workflows-nix-darwin)
  - [State Versions](#state-versions)
  - [Environment Variables](#environment-variables-nix-darwin)
- [Home Manager](#home-manager)
  - [Overview](#home-manager-overview)
  - [Structure](#home-manager-structure)
  - [What Home Manager Manages](#what-home-manager-manages)
  - [Common Tasks](#common-tasks-home-manager)
  - [Home Manager vs System](#home-manager-vs-system)
  - [Configuration Files](#home-manager-configuration-files)
  - [Mixins](#mixins)
  - [Activation](#activation)
  - [Troubleshooting](#troubleshooting-home-manager)
- [Helper Functions](#helper-functions)
  - [System Information](#system-information)
  - [Python Environment](#python-environment)
  - [Backup & Restore](#backup--restore)
  - [Secrets Management](#secrets-management)
  - [System Maintenance](#system-maintenance)
  - [Update Functions](#update-functions)
  - [Cleanup Functions](#cleanup-functions)

---

## Nix Darwin

**System management commands and workflows**

### Core Commands

#### Rebuilding

```bash
# Standard rebuild (from ~/nix-darwin)
darwin-rebuild switch --flake .

# Or use the alias (from anywhere)
nix-rebuild
nix-switch  # Same as above

# Build without switching (test first)
nix-check
darwin-rebuild build --flake .

# Test build (dry-run)
nix-test
darwin-rebuild build --flake . --dry-run
```

### First-Time Installation

```bash
# Set hostname first!
sudo scutil --set HostName mbp-jimmy  # or mbp-work

# Initial installation
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy

# For work Mac
sudo nix run nix-darwin -- switch --flake .#mbp-work
```

### Nix Darwin Aliases

| Alias             | Command                                                                         | Description             |
| ----------------- | ------------------------------------------------------------------------------- | ----------------------- |
| `nix-rebuild`     | `darwin-rebuild switch --flake ~/nix-darwin`                                    | Rebuild and switch      |
| `nix-switch`      | `darwin-rebuild switch --flake ~/nix-darwin`                                    | Same as above           |
| `nix-check`       | `darwin-rebuild build --flake ~/nix-darwin`                                     | Build without switching |
| `nix-test`        | `darwin-rebuild build --flake ~/nix-darwin --dry-run`                           | Test build              |
| `nix-update`      | `cd ~/nix-darwin && nix flake update`                                           | Update flake inputs     |
| `nix-clean`       | `nix-collect-garbage -d && sudo nix-collect-garbage -d && nix-store --optimize` | Cleanup old generations |
| `nix-generations` | `darwin-rebuild --list-generations`                                             | List all generations    |
| `nix-rollback`    | `darwin-rebuild rollback`                                                       | Rollback to previous    |
| `nix-list`        | `nix-env -q`                                                                    | List installed packages |
| `nix-search`      | `nix search nixpkgs`                                                            | Search for packages     |

### Update Workflow

#### Quick Update (Nix Only)

```bash
# Using the update function
update-nix

# Or manually
cd ~/nix-darwin
nix flake update
darwin-rebuild switch --flake .
```

#### Complete System Update

```bash
# Updates: Nix + Homebrew + Micromamba + VS Code + Mac App Store
update-all
```

See [Update Guide](../guides/usage.md#updates) for details.

### Generations

#### List Generations

```bash
nix-generations
# Or
darwin-rebuild --list-generations
```

#### Rollback

```bash
# Rollback to previous generation
nix-rollback
darwin-rebuild rollback

# Rollback to specific generation
darwin-rebuild --switch-generation 42
```

#### Delete Old Generations

```bash
# Delete all old generations and garbage collect
nix-clean

# Delete generations older than 30 days
nix-collect-garbage --delete-older-than 30d
sudo nix-collect-garbage --delete-older-than 30d
```

### Cleanup

#### Standard Cleanup

```bash
nix-clean  # Garbage collect + optimize store
```

#### Comprehensive System Cleanup

```bash
cleanup-all  # Trash + Nix + Homebrew + Docker + Python caches + logs
```

### Troubleshooting Nix Darwin

#### Build Errors

```bash
# Show detailed error trace
darwin-rebuild switch --flake . --show-trace

# Check flake structure
nix flake show

# Validate flake
nix flake check
```

#### See What Changed

```bash
# Before rebuilding
darwin-rebuild build --flake . --show-trace 2>&1 | grep "will be changed"
```

#### Nix Store Issues

```bash
# Verify store integrity
nix-store --verify --check-contents

# Repair store
nix-store --repair --verify --check-contents
```

### Configuration Files

| File               | Purpose                            |
| ------------------ | ---------------------------------- |
| `flake.nix`        | Main entry point, defines machines |
| `hosts/mbp-jimmy/` | Personal Mac configuration         |
| `hosts/mbp-work/`  | Work Mac configuration             |
| `modules/darwin/`  | macOS system settings              |
| `modules/shared/`  | Shared packages across machines    |
| `home/jimmy/`      | User-level configurations          |

See [File Structure](../architecture/reference.md) for details.

### Common Workflows Nix Darwin

#### Add a Package

1. Edit `modules/shared/packages.nix`
2. Add package to `environment.systemPackages`
3. Rebuild: `nix-rebuild`

See [Adding Packages](../guides/usage.md#adding-packages).

#### Modify Shell Configuration

1. Edit `home/jimmy/shell/zsh.nix`
2. Add aliases or functions
3. Rebuild: `nix-rebuild`
4. Restart terminal: `exec zsh`

#### Change System Settings

1. Edit `modules/darwin/system.nix`
2. Modify `system.defaults.*` settings
3. Rebuild: `nix-rebuild`

### State Versions

**DO NOT CHANGE THESE AFTER INITIAL INSTALLATION**

- System state version: `system.stateVersion = 5` (in host configs)
- Home Manager state version: `home.stateVersion = "24.05"` (in home/jimmy/default.nix)

### Environment Variables Nix Darwin

| Variable       | Value                       | Set By                          |
| -------------- | --------------------------- | ------------------------------- |
| `MACHINE_MODE` | `home` or `work`            | Mixin (personal.nix / work.nix) |
| `AWS_PROFILE`  | `personal` or `example-corp` | Mixin                           |
| `EDITOR`       | `code`                      | zsh.nix                         |
| `PAGER`        | `less`                      | zsh.nix                         |

---

## Home Manager

**User-level configuration management**

### Home Manager Overview

**Home Manager** manages user-level configurations:

- Dotfiles (.zshrc, .gitconfig, etc.)
- Application settings (VS Code, etc.)
- User packages
- Shell configuration

**Key Concept:** Everything in `home/` directory is managed by Home Manager.

### Home Manager Structure

```
home/
├── jimmy/
│   ├── default.nix          # Main home config
│   ├── programs/            # Application configs
│   │   ├── git.nix
│   │   ├── vscode.nix
│   │   └── starship.nix
│   ├── shell/               # Shell configs
│   │   └── zsh.nix
│   └── development/         # Dev tools
│       └── python.nix
└── _mixins/                 # Shared configs
    ├── personal.nix
    └── work.nix
```

### What Home Manager Manages

#### Dotfiles

Home Manager generates:

- `~/.zshrc` - Shell configuration
- `~/.config/git/config` - Git configuration
- `~/.config/starship.toml` - Prompt configuration
- `~/.condarc` - Conda configuration
- And many more...

#### Application Settings

- VS Code settings + extensions
- Git configuration
- Shell aliases and functions
- Starship prompt theme

#### State

**State Version:** `24.05`

**Never change after installation!**

### Common Tasks Home Manager

#### Edit User Configuration

```bash
# Edit main home config
code ~/nix-darwin/home/jimmy/default.nix

# Edit specific programs
code ~/nix-darwin/home/jimmy/programs/git.nix
code ~/nix-darwin/home/jimmy/programs/vscode.nix

# Edit shell
code ~/nix-darwin/home/jimmy/shell/zsh.nix

# Rebuild
nix-rebuild
```

#### Add Home Manager Package

```nix
# In home/jimmy/default.nix
home.packages = with pkgs; [
  # Existing packages
  # Add new package here
  neofetch
];
```

#### Modify Program

```nix
# In home/jimmy/programs/git.nix
programs.git = {
  enable = true;
  settings = {
    user.name = "Your Name";
    user.email = "your@email.com";
  };
};
```

### Home Manager vs System

| Feature      | Home Manager    | System (Nix Darwin)       |
| ------------ | --------------- | ------------------------- |
| **Scope**    | User-level      | System-wide               |
| **Location** | `home/`         | `modules/`                |
| **Examples** | .zshrc, VS Code | System settings, Homebrew |
| **Runs as**  | User            | Root                      |

### Home Manager Configuration Files

#### Main Config

**File:** `home/jimmy/default.nix`

```nix
{ config, pkgs, ... }: {
  imports = [
    ./programs/git.nix
    ./programs/vscode.nix
    ./shell/zsh.nix
    ./development/python.nix
    # Mixin (personal or work)
    ./_mixins/personal.nix
  ];

  home = {
    username = "jimmy";
    homeDirectory = "/Users/jimmy";
    stateVersion = "24.05";
  };

  home.packages = with pkgs; [
    # User packages
  ];
}
```

### Mixins

**Location:** `home/_mixins/`

Mixins provide machine-specific configuration:

**personal.nix:**

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };
}
```

**work.nix:**

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "example-corp";
  };
}
```

See [Mixin Architecture](../architecture/overview.md#mixin-system) for details.

### Activation

Home Manager activates on every rebuild:

```bash
nix-rebuild
# ...
# Activating home-manager configuration for jimmy
# Starting Home Manager activation
# ...
```

**What happens:**

1. Generates all dotfiles
2. Links files to home directory
3. Runs activation scripts
4. Applies user settings

### Troubleshooting Home Manager

#### File Conflicts

```bash
# Error: File exists and is not a symlink
# Solution: Remove or backup the file
mv ~/.zshrc ~/.zshrc.backup
nix-rebuild
```

#### State Version Mismatch

Don't change `stateVersion`! If you see warnings about it, keep the original value.

#### Settings Not Applied

```bash
# Rebuild
nix-rebuild

# Restart shell
exec zsh

# Or logout/login for some settings
```

---

## Helper Functions

**Comprehensive shell functions for system management**

### System Information

#### sysinfo

Display comprehensive system information:

```bash
sysinfo
# Output:
# ================================================
# System Information
# ================================================
# Machine Mode: home
# Hostname: mbp-jimmy
# OS: macOS 14.0
# Architecture: arm64
# Python: 3.13.8
# UV: 0.1.0
# AWS Profile: personal
# Disk Space: Available: 185.5G / 465.6G (Used: 60%)
# ================================================
```

**Features:**

- System details (hostname, OS, architecture)
- Python environment info
- AWS profile status
- Package manager versions
- Disk space usage

### Python Environment

#### pyenv-info

Display Python environment setup:

```bash
pyenv-info
# Output:
# ================================================
# Python Environment Setup
# ================================================
# System Python (Nix):
#   /nix/store/.../bin/python
#   Python 3.13.8
# UV (Fast Python package installer):
#   /nix/store/.../bin/uv
#   uv 0.1.0
# Micromamba (Conda-compatible):
#   /opt/homebrew/bin/micromamba
#   micromamba 1.5.0
# Active Virtual Environment:
#   Path: /Users/jimmy/Dev/myproject/.venv
#   Python: Python 3.13.8
# Python Strategy:
#   Tier 1: Micromamba environments (create with: mkenv myenv python=3.12)
#   Tier 2: Project environments (UV .venv for project-specific deps)
#   Tier 3: System Python (Nix-managed 3.13)
# ================================================
```

**Features:**

- Shows system Python location and version
- UV and Micromamba status
- Active virtual environment info
- Python strategy overview

### Backup & Restore

#### backup-user-data

Backup non-secret user data:

```bash
backup-user-data
# Runs: ~/nix-darwin/user-data/backup.sh
# Backs up:
#   - Shell history
#   - Custom configurations
#   - Application data
#   - Bookmarks
#   - (Not secrets - those are managed separately)
```

**What it backs up:**

- `~/.zsh_history` - Command history
- Browser bookmarks
- Application preferences
- Custom scripts and configs

**Does NOT backup:**

- Encrypted secrets (managed via sops)
- Large files
- Temporary data

#### restore-user-data

Restore user data from backup:

```bash
restore-user-data
# Runs: ~/nix-darwin/user-data/restore.sh
# Restores all backed up user data
```

**Use cases:**

- New machine setup
- Disaster recovery
- Testing configurations

### Secrets Management

#### edit-secrets

Edit encrypted secrets with sops:

```bash
edit-secrets
# Opens encrypted secrets file for current hostname
# File: ~/nix-darwin/hosts/mbp-jimmy/secrets.yaml
# Uses: ~/.config/sops/age/keys.txt for decryption
```

**What you can store:**

- API keys
- AWS credentials
- SSH keys
- Personal access tokens
- Environment variables

**Workflow:**

1. Run `edit-secrets`
2. Modify secrets in YAML format
3. Save and close (automatically re-encrypts)
4. Run `nix-rebuild` to apply

#### secrets-status

Check secrets configuration status:

```bash
secrets-status
# Output:
# ================================================
# Secrets Management Status
# ================================================
# Age Key:
#   ✅ Age key exists: ~/.config/sops/age/keys.txt
#   Public key: age1abc123...
# Sops Configuration:
#   ✅ .sops.yaml exists
# Secrets File:
#   ✅ Secrets file exists: hosts/mbp-jimmy/secrets.yaml
#   ✅ Secrets file is encrypted
# Tools:
#   ✅ sops: 3.8.0
#   ✅ age: 1.1.1
# Active Secrets:
#   ✅ ~/.zsh_secrets (environment variables)
#   ✅ ~/.ssh/id_ed25519 (SSH private key)
#   ✅ ~/.aws/credentials (AWS credentials)
# ================================================
# Useful commands:
#   edit-secrets         - Edit encrypted secrets
#   backup-user-data     - Backup non-secret data
#   restore-user-data    - Restore from backup
#   nix-rebuild          - Apply secrets after changes
# ================================================
```

**Features:**

- Age key status
- Sops configuration check
- Secrets file encryption status
- Active secrets status
- Tool installation check

### System Maintenance

#### nix-cleanup

Clean old Nix generations with detailed reporting:

```bash
nix-cleanup
# Output:
# ================================================
# Nix System Cleanup
# ================================================
# Current generations:
#   42   2025-01-15 10:30:00   (current)
#   41   2025-01-14 15:20:00
#   40   2025-01-13 09:15:00
# Removing old generations (keeping last 5)...
# Running garbage collection...
# Optimizing Nix store...
# ================================================
# Cleanup complete!
# Space saved: ~2.5 GB
# ================================================
```

**What it does:**

1. Lists current generations
2. Removes old generations (keeps last 5)
3. Runs garbage collection
4. Optimizes Nix store
5. Reports space saved

#### nix-health

Comprehensive system health check:

```bash
nix-health
# Output:
# ================================================
# System Health Check
# ================================================
# Checking Nix installation...
#   ✅ Nix: nix 2.18.0
# Checking Python setup...
#   ✅ Python: Python 3.13.8
#   ✅ UV: uv 0.1.0
#   ✅ Micromamba: micromamba 1.5.0
# Checking Git configuration...
#   ✅ Git: git version 2.42.0
#   ✅ Git email: jimmy-jain@users.noreply.github.com
# Checking AWS setup...
#   ✅ AWS CLI: aws-cli/2.13.0
#   ✅ AWS Profile: personal
# Checking Docker...
#   ✅ Docker: Docker version 24.0.5
# Checking disk space...
#   ✅ Disk usage: 60% (healthy)
# Checking key aliases...
#   ✅ nix-rebuild alias configured
#   ✅ git alias (g) configured
# ================================================
# System health: GOOD
# No critical issues found!
# ================================================
```

**Checks:**

- Nix installation
- Python environment (system, UV, Micromamba)
- Git configuration
- AWS CLI and profile
- Docker status
- Disk space usage
- Key aliases

### Update Functions

Modular update system for different components.

#### update-nix

Update Nix Darwin only:

```bash
update-nix
# Updates flake inputs
# Rebuilds darwin configuration
# Reports success/errors
```

#### update-brew

Update Homebrew packages:

```bash
update-brew
# Updates Homebrew
# Upgrades packages
# Upgrades casks
# Cleans up
# Runs diagnostics
```

#### update-mamba

Update Micromamba environments:

```bash
update-mamba
# Automatically updates ALL micromamba environments
# Skips only the base installation directory
```

#### update-vscode

Update VS Code extensions:

```bash
update-vscode
# Updates all installed extensions
```

#### update-mas

Update Mac App Store apps:

```bash
update-mas
# Updates all MAS apps
```

#### update-dev

Quick development update:

```bash
update-dev
# Updates: Nix + Micromamba + VS Code
# Duration: ~5-10 minutes
```

#### update-system

System update:

```bash
update-system
# Updates: Nix + Homebrew
# Duration: ~10-15 minutes
```

#### update-all

Complete system update:

```bash
update-all
# Updates everything:
#   - Nix Darwin
#   - Homebrew
#   - Micromamba
#   - VS Code
#   - Mac App Store
#   - Checks for macOS updates
# Output:
# ================================================
# Complete system update...
# ================================================
# (Shows progress for each component)
# ================================================
# Update Summary:
# Duration: 12 minutes 34 seconds
# Errors: 0
# ✅ All updates completed successfully!
# ================================================
```

### Cleanup Functions

#### cleanup-quick

Fast cleanup of common areas:

```bash
cleanup-quick
# Empties trash
# Nix garbage collection
# Homebrew cleanup (7 days)
# Micromamba cache
```

#### cleanup-all

Comprehensive system cleanup:

```bash
cleanup-all
# Output:
# ================================================
# Starting comprehensive system cleanup...
# ================================================
# Emptying Trash...
# Cleaning system caches...
# Cleaning temporary files...
# Cleaning Nix... (was: 50G, now: 35G)
# Cleaning Homebrew...
# Cleaning Micromamba...
# Cleaning Python caches...
# Cleaning VS Code caches...
# Cleaning Docker...
# Cleaning npm cache...
# Cleaning system logs...
# ================================================
# Cleanup Summary:
# Duration: 5 minutes 23 seconds
# Tip: Check disk space with 'df -h'
# ✅ Cleanup completed!
# ================================================
```

**What it cleans:**

1. Trash
2. System caches
3. Temporary files
4. Nix (old generations)
5. Homebrew cache
6. Micromamba cache
7. Python caches (`__pycache__`, `.pyc`, pip cache)
8. VS Code caches
9. Docker (containers, images, volumes)
10. npm cache
11. System logs
12. Xcode derived data (if exists)

---

## Links

- [Nix Package Search](https://search.nixos.org/)
- [Nix Darwin Manual](https://daiderd.com/nix-darwin/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)

**Related Documentation:**

- [Configuration Guide](../guides/usage.md) - How to customize
- [Update Guide](../guides/usage.md#updates) - Update workflow
- [Troubleshooting Guide](../guides/troubleshooting.md) - Fix common issues
- [Architecture Overview](../architecture/overview.md) - System design
