# Architecture Overview

**Complete system architecture, mixin system, and comparison with alternatives**

[← Back to Index](../index.md)

---

## Table of Contents

1. [System Architecture](#system-architecture)
   - [High-Level Architecture](#high-level-architecture)
   - [Core Components](#core-components)
   - [Configuration Flow](#configuration-flow)
   - [System vs User Config](#system-vs-user-config)
   - [Flake System](#flake-system)
   - [Configuration Layers](#configuration-layers)
   - [Design Principles](#design-principles)
2. [Mixin System](#mixin-system)
   - [What Are Mixins](#what-are-mixins)
   - [Mixin Structure](#mixin-structure)
   - [How Mixins Work](#how-mixins-work)
   - [Available Mixins](#available-mixins)
   - [Adding New Mixins](#adding-new-mixins)
   - [Mixin Best Practices](#mixin-best-practices)
3. [Comparison with Other Systems](#comparison-with-other-systems)
   - [Quick Comparison](#quick-comparison)
   - [vs Manual Configuration](#vs-manual-configuration)
   - [vs Homebrew Only](#vs-homebrew-only)
   - [vs Ansible](#vs-ansible)
   - [vs Chezmoi](#vs-chezmoi)
   - [vs GNU Stow](#vs-gnu-stow)
   - [vs NixOS](#vs-nixos)
   - [Why Choose Nix-Darwin](#why-choose-nix-darwin)

---

# System Architecture

## Overview

This nix-darwin configuration uses a modular architecture that separates system-level settings, user-level configuration, and machine-specific settings for maximum flexibility and maintainability.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                    flake.nix                        │
│            (Entry point, orchestrator)               │
└──────────────┬──────────────────────┬───────────────┘
               │                      │
       ┌───────▼─────────┐    ┌──────▼──────────┐
       │  System Layer   │    │   User Layer    │
       │  (Nix-Darwin)   │    │ (Home Manager)  │
       └───────┬─────────┘    └──────┬──────────┘
               │                      │
     ┌─────────▼─────────┐  ┌────────▼──────────┐
     │  Host Configs     │  │   User Config     │
     │  (per machine)    │  │   (home/jimmy)    │
     └───────────────────┘  └────────┬──────────┘
                                     │
                         ┌───────────▼───────────┐
                         │   Mixins (personal   │
                         │   or work)           │
                         └──────────────────────┘
```

---

## Core Components

### 1. Nix Flakes

**File:** `flake.nix`

- **Purpose:** Entry point and dependency management
- **Defines:** Available system configurations (mbp-jimmy, mbp-work)
- **Manages:** Nixpkgs, nix-darwin, and home-manager versions
- **Locks:** Dependency versions in `flake.lock`

### 2. Nix-Darwin

**Directory:** `modules/`

- **Purpose:** System-level configuration
- **Manages:**
  - macOS system settings
  - System-wide packages
  - Homebrew integration
  - System defaults

### 3. Home Manager

**Directory:** `home/`

- **Purpose:** User-level configuration
- **Manages:**
  - Dotfiles (.zshrc, .gitconfig, etc.)
  - Application settings
  - User-specific packages
  - Shell configuration

### 4. Mixins

**Directory:** `home/_mixins/`

- **Purpose:** Machine-specific configuration
- **Manages:**
  - Personal vs work settings
  - Environment variables
  - Machine-specific aliases
  - AWS profiles

---

## Configuration Flow

### Build Process

```
1. Run: nix-rebuild
   ↓
2. Reads: flake.nix
   ↓
3. Determines hostname (mbp-jimmy or mbp-work)
   ↓
4. Loads host-specific config (hosts/mbp-*/default.nix)
   ↓
5. Builds system layer (Nix-Darwin)
   ├── Loads modules/shared/packages.nix
   ├── Loads modules/darwin/system.nix
   └── Loads modules/darwin/casks.nix
   ↓
6. Builds user layer (Home Manager)
   ├── Loads home/jimmy/default.nix
   ├── Loads home/jimmy/programs/*.nix
   ├── Loads home/jimmy/shell/zsh.nix
   └── Loads home/_mixins/{personal,work}.nix
   ↓
7. Generates configuration files
   ├── Creates ~/.zshrc
   ├── Creates ~/.config/git/config
   ├── Creates ~/.config/starship.toml
   └── Links to /nix/store/...
   ↓
8. Activates new generation
```

### Rebuild Command Flow

```bash
nix-rebuild
  ↓
cd ~/nix-darwin
  ↓
darwin-rebuild switch --flake .
  ↓
Evaluates flake.nix
  ↓
Builds configuration
  ↓
Activates new generation
  ↓
Returns to original directory
```

---

## System vs User Config

### System Layer (Nix-Darwin)

**Location:** `modules/`

**Scope:** System-wide settings

**Examples:**

- Installing system packages (`modules/shared/packages.nix`)
- macOS system defaults (`modules/darwin/system.nix`)
- Homebrew casks (`modules/darwin/casks.nix`)
- Networking settings (`hosts/*/default.nix`)

**Requires:** `sudo` for activation

**Applied:** After `darwin-rebuild switch`

### User Layer (Home Manager)

**Location:** `home/`

**Scope:** User-specific settings

**Examples:**

- Git configuration (`home/jimmy/programs/git.nix`)
- Shell aliases (`home/jimmy/shell/zsh.nix`)
- VS Code settings (`home/jimmy/programs/vscode.nix`)
- Python setup (`home/jimmy/development/python.nix`)

**Requires:** Regular user permissions

**Applied:** As part of `darwin-rebuild switch`

### User Preferences vs Machine Settings

**Important Distinction:**

Within the user layer, there's a critical separation between:

1. **User Preferences** (cross-machine) - Your personal workflow choices
   - Editor, shell theme, keybindings
   - Tool configurations (Starship, fzf, bat)
   - Git aliases and workflow preferences
   - Same on all machines you use

2. **Machine Settings** (context-specific) - Machine type and purpose
   - AWS profiles, git email
   - Work vs personal project shortcuts
   - Corporate compliance configurations
   - Different between work and personal machines

**See**: [User vs Machine Config Separation](../../claudedocs/USER-VS-MACHINE-CONFIG-SEPARATION.md) for detailed guide

### Interaction

```
System Layer (root)
    ↓ provides
[System Packages] → [Available to all users]
    ↓ uses
User Layer (jimmy)
    ↓ configures
[User Preferences] → [Same everywhere]
    ↓ applies
[Machine Settings] → [Work vs Personal]
```

---

## Flake System

### Why Flakes?

- **Reproducible:** Lock file pins all dependencies
- **Composable:** Easy to import other flakes
- **Discoverable:** Standard structure across projects
- **Self-contained:** All inputs declared explicitly

### Flake Structure

**File:** `flake.nix`

```nix
{
  description = "Jimmy's Nix Darwin configuration";

  # Inputs: External dependencies
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  # Outputs: What this flake provides
  outputs = { self, nixpkgs, nix-darwin, home-manager }: {
    # System configurations
    darwinConfigurations = {
      mbp-jimmy = { ... };   # Personal Mac
      mbp-work = { ... };    # Work Mac
    };
  };
}
```

### Lock File

**File:** `flake.lock`

- **Purpose:** Pin exact versions of all dependencies
- **Generated:** Automatically by Nix
- **Updated:** `nix flake update`
- **Committed:** Yes, should be in git

**Benefits:**

- Reproducible builds
- Explicit version control
- Easy rollback via git

---

## Configuration Layers

### Layer 1: Flake (Root)

**Purpose:** Dependency management and system selection

**Files:**

- `flake.nix`
- `flake.lock`

**Updates:** `nix flake update`

### Layer 2: Host (System)

**Purpose:** Per-machine system settings

**Files:**

- `hosts/mbp-jimmy/default.nix`
- `hosts/mbp-work/default.nix`

**Contains:**

- Hostname
- Computer name
- Host-specific system settings

### Layer 3: System (Nix-Darwin)

**Purpose:** System-wide configuration

**Files:**

- `modules/shared/packages.nix`
- `modules/darwin/system.nix`
- `modules/darwin/casks.nix`

**Contains:**

- System packages
- macOS defaults
- Homebrew configuration

### Layer 4: User (Home Manager)

**Purpose:** User-specific configuration

**Files:**

- `home/jimmy/default.nix`
- `home/jimmy/programs/*.nix`
- `home/jimmy/shell/zsh.nix`
- `home/jimmy/development/python.nix`

**Contains:**

- Dotfiles
- Application settings
- Shell configuration
- Development tools

### Layer 5: Mixin (Machine-Specific)

**Purpose:** Differentiate between machines

**Files:**

- `home/_mixins/base.nix`
- `home/_mixins/personal.nix`
- `home/_mixins/work.nix`

**Contains:**

- Environment variables (MACHINE_MODE, AWS_PROFILE)
- Machine-specific aliases
- Per-machine tool configuration

---

## Design Principles

### 1. Declarative

Everything is declared in configuration files. No imperative commands needed after initial setup.

### 2. Reproducible

Same configuration produces same result. Lock file ensures exact dependency versions.

### 3. Modular

Configuration split into logical modules. Easy to add, remove, or modify components.

### 4. Composable

Mixins and imports allow reusing configuration across machines.

### 5. Version Controlled

All configuration in git. Easy to track changes and rollback.

### 6. Atomic

Changes applied atomically. New generation activated only if build succeeds.

### 7. Rollback-able

Can always rollback to previous generation if something breaks.

---

# Mixin System

## What Are Mixins

### Definition

**Mixins** are modular configuration fragments that can be selectively included based on the target machine.

### Problem They Solve

**Without mixins:**

- Need separate repositories for personal and work Macs
- Duplicate shared configuration
- Hard to keep configurations in sync

**With mixins:**

- Single repository for all machines
- Shared configuration reused automatically
- Machine-specific settings separated cleanly
- Easy to maintain and sync

### Analogy

Think of mixins like ingredients in recipes:

- **base.nix** = Common ingredients (flour, salt) used in all recipes
- **dev.nix** = Cooking tools (oven, mixer) for all recipes
- **personal.nix** = Sweet ingredients (sugar, vanilla) for desserts
- **work.nix** = Savory ingredients (herbs, spices) for meals

You combine different mixins to create different "recipes" (configurations).

---

## Mixin Structure

### Location

```
home/_mixins/
├── base.nix         # Common to ALL machines
├── dev.nix          # Development setup
├── personal.nix     # Personal Mac settings
└── work.nix         # Work Mac settings
```

### Loading Mechanism

**File:** `flake.nix`

```nix
darwinConfigurations = {
  # Personal Mac
  mbp-jimmy = mkDarwinSystem {
    hostname = "mbp-jimmy";
    username = "jimmy";
    mixins = [ "base" "dev" "personal" ];  # ← Loads these mixins
  };

  # Work Mac
  mbp-work = mkDarwinSystem {
    hostname = "mbp-work";
    username = "jimmy";
    mixins = [ "base" "dev" "work" ];  # ← Loads these mixins
  };
};
```

### Selection Process

1. **System detects hostname** (mbp-jimmy or mbp-work)
2. **Flake reads mixin list** for that hostname
3. **Loads corresponding mixin files** from `home/_mixins/`
4. **Merges configurations** (later mixins can override earlier ones)
5. **Generates final config** specific to that machine

---

## How Mixins Work

### Composition

Mixins are **composed** together during build:

```
base.nix settings
    +
dev.nix settings
    +
personal.nix settings (or work.nix)
    =
Final configuration for your machine
```

### Override Behavior

Later mixins can override earlier ones:

```nix
# base.nix
home.sessionVariables = {
  EDITOR = "vim";
};

# personal.nix (loaded after base.nix)
home.sessionVariables = {
  EDITOR = "code --wait";  # ← Overrides vim
};
```

Result: `EDITOR = "code --wait"`

### Merge Behavior

For lists and attribute sets, values are merged:

```nix
# base.nix
home.packages = [ pkgs.git pkgs.curl ];

# dev.nix
home.packages = [ pkgs.python3 ];

# personal.nix
home.packages = [ pkgs.neofetch ];
```

Result: All packages installed (git, curl, python3, neofetch)

---

## Available Mixins

### base.nix

**Purpose:** Configuration common to ALL machines

**Contains:**

- Starship prompt configuration
- Common tool setup (fzf, dircolors)
- Shell environment basics
- Universal settings

**When loaded:** Always (on every machine)

**Example contents:**

```nix
{
  # Starship prompt (same on all machines)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      # ... more starship config
    };
  };

  # Common packages for all machines
  home.packages = with pkgs; [
    # Already in system packages, but for reference
  ];
}
```

**Edit when:**

- Changing prompt appearance
- Adding tools needed on ALL machines
- Modifying shared shell behavior

### dev.nix

**Purpose:** Development tools and configuration

**Contains:**

- Programming language setups
- Development tool configuration
- Language-specific packages
- Development aliases

**When loaded:** On both personal and work Macs (all dev machines)

**Example contents:**

```nix
{
  # Import development programs
  imports = [
    ../jimmy/development/python.nix
    ../jimmy/development/node.nix
    ../jimmy/development/ai-ml.nix
  ];

  # Development-specific settings
  home.sessionVariables = {
    # Dev-related env vars
  };
}
```

**Edit when:**

- Adding new programming language
- Configuring dev tools
- Setting up new development environment

### personal.nix

**Purpose:** Personal Mac specific settings

**Contains:**

- MACHINE_MODE = "home"
- Personal AWS profile
- Personal project shortcuts
- Personal-only tools
- Personal email for git (optional)

**When loaded:** Only on mbp-jimmy (personal Mac)

**Example contents:**

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
    AWS_REGION = "us-east-1";
  };

  home.shellAliases = {
    # Personal project shortcuts
    blog = "cd ~/Dev/my-blog";
    sideproject = "cd ~/Dev/side-project";
    personal-site = "cd ~/Dev/personal-website";
  };

  # Personal-specific git email (optional)
  programs.git = {
    userEmail = "jimmy@personal.com";
  };

  # Personal-only packages
  home.packages = with pkgs; [
    # Tools only for personal use
    obs-studio  # Streaming
  ];
}
```

**Edit when:**

- Adding personal project shortcuts
- Changing personal AWS profile
- Installing personal-only tools

### work.nix

**Purpose:** Work Mac specific settings

**Contains:**

- MACHINE_MODE = "work"
- Work AWS profile
- Work project shortcuts
- Work-specific tools
- Company VPN shortcuts
- Work email for git

**When loaded:** Only on mbp-work (work Mac)

**Example contents:**

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "example-corp";
    AWS_REGION = "us-east-1";
  };

  home.shellAliases = {
    # Work project shortcuts
    monorepo = "cd ~/Dev/work-monorepo";
    infra = "cd ~/Dev/infrastructure";

    # VPN shortcut
    vpn = "sudo openconnect vpn.company.com";
  };

  # Work-specific git email
  programs.git = {
    userEmail = "jimmy.smith@company.com";
  };

  # Work-only packages
  home.packages = with pkgs; [
    kubectl      # Kubernetes
    terraform    # Infrastructure
    awscli2      # AWS CLI
  ];

  # Work-specific functions
  programs.zsh.initExtra = ''
    # AWS SSO login function
    awslogin() {
      aws sso login --profile example-corp
    }

    # Check AWS identity
    awswho() {
      aws sts get-caller-identity
    }
  '';
}
```

**Edit when:**

- Adding work project shortcuts
- Changing work AWS profile
- Installing work-only tools
- Adding company-specific configurations

---

## Adding New Mixins

### Creating a New Mixin

**Example:** Create a gaming mixin for personal Mac

1. **Create mixin file:**

```bash
touch ~/nix-darwin/home/_mixins/gaming.nix
```

2. **Add configuration:**

```nix
# home/_mixins/gaming.nix
{
  home.packages = with pkgs; [
    # Gaming tools
    steam
    discord
  ];

  home.shellAliases = {
    games = "cd ~/Games";
  };
}
```

3. **Add to personal Mac in flake.nix:**

```nix
darwinConfigurations."mbp-jimmy" = mkDarwinSystem {
  hostname = "mbp-jimmy";
  username = "jimmy";
  mixins = [ "base" "dev" "personal" "gaming" ];  # ← Add gaming
};
```

4. **Rebuild:**

```bash
nix-rebuild
```

### Mixin Naming

**Conventions:**

- Lowercase names
- Descriptive (base, dev, personal, work)
- Category-based (if creating new ones: media, security, etc.)

### Mixin Guidelines

**Do create mixins for:**

- Machine categories (personal, work)
- Feature sets (gaming, media, security)
- Environment types (home, office, travel)

**Don't create mixins for:**

- Single settings (use existing mixin instead)
- One-time configurations
- User-specific settings (those go in home/jimmy/)

---

## Mixin Best Practices

### 1. Keep Mixins Focused

Each mixin should have a clear purpose:

**Good:**

```nix
# personal.nix - Only personal Mac settings
{
  home.sessionVariables.MACHINE_MODE = "home";
  home.shellAliases.blog = "cd ~/Dev/blog";
}
```

**Bad:**

```nix
# personal.nix - Mixed concerns
{
  home.sessionVariables.MACHINE_MODE = "home";
  programs.starship.enable = true;  # ← Should be in base.nix
  home.packages = [ pkgs.python3 ];  # ← Should be in dev.nix
}
```

### 2. Use Inheritance Hierarchy

```
base.nix          # Most general
  ↓
dev.nix           # Development machines
  ↓
personal.nix      # Specific machine type
  or
work.nix
```

### 3. Document Mixin Purpose

Add comments at the top of each mixin:

```nix
# home/_mixins/personal.nix
#
# Personal MacBook Pro configuration
#
# Contains:
# - Personal AWS profile
# - Personal project shortcuts
# - Personal-only tools
# - Home environment variables
#
{ config, pkgs, ... }: {
  # ... configuration
}
```

### 4. Avoid Duplication

If multiple mixins need the same setting, move it to base.nix:

**Before:**

```nix
# personal.nix
programs.fzf.enable = true;

# work.nix
programs.fzf.enable = true;
```

**After:**

```nix
# base.nix (used by both)
programs.fzf.enable = true;
```

### 5. Use Conditional Logic Sparingly

Prefer separate mixins over complex conditionals:

**Avoid:**

```nix
# base.nix (BAD)
home.packages = if (config.networking.hostName == "mbp-work") then
  [ pkgs.kubectl ]
else
  [ pkgs.obs-studio ];
```

**Prefer:**

```nix
# work.nix
home.packages = [ pkgs.kubectl ];

# personal.nix
home.packages = [ pkgs.obs-studio ];
```

### 6. Keep Secrets Out

**Never** put secrets in mixins:

```nix
# work.nix (WRONG!)
home.sessionVariables = {
  API_KEY = "secret123";  # ← NEVER DO THIS!
};
```

**Correct:**

Secrets go in `~/.zsh_secrets` (not in git).

---

# Comparison with Other Systems

## Quick Comparison

| Feature                | Nix-Darwin | Homebrew | Ansible | Chezmoi | Manual |
| ---------------------- | ---------- | -------- | ------- | ------- | ------ |
| **Declarative**        | ✅         | ❌       | ✅      | ❌      | ❌     |
| **Reproducible**       | ✅         | ⚠️       | ⚠️      | ⚠️      | ❌     |
| **Atomic Rollback**    | ✅         | ❌       | ❌      | ❌      | ❌     |
| **Multi-Machine**      | ✅         | ❌       | ✅      | ✅      | ❌     |
| **Package Management** | ✅         | ✅       | ⚠️      | ❌      | ❌     |
| **Dotfile Management** | ✅         | ❌       | ⚠️      | ✅      | ❌     |
| **System Settings**    | ✅         | ❌       | ✅      | ❌      | ⚠️     |
| **Learning Curve**     | High       | Low      | Medium  | Low     | N/A    |
| **Setup Time**         | Medium     | Low      | High    | Low     | N/A    |

---

## vs Manual Configuration

### Manual Configuration

**Approach:**

- Edit dotfiles directly (`~/.zshrc`, `~/.gitconfig`)
- Install packages with `brew install`
- Change system settings via System Preferences
- Document (maybe) in a README

**Pros:**

- Simple and intuitive
- No learning curve
- Quick to make changes

**Cons:**

- Not reproducible
- Hard to sync across machines
- No version control (unless you track it)
- Can't rollback changes
- Manual setup on new machines

### Nix-Darwin

**Approach:**

- Declare configuration in `.nix` files
- Version control everything
- Rebuild to apply changes
- Automatic dotfile generation

**Pros:**

- Fully reproducible
- Version controlled by default
- Atomic rollbacks
- Easy multi-machine setup
- Declarative and documented

**Cons:**

- Steeper learning curve
- Requires understanding Nix
- Initial setup takes longer

---

## vs Homebrew Only

### Homebrew Only

**Approach:**

- Use Homebrew for package management
- Use `brew bundle` with Brewfile
- Manual dotfile management
- Manual system preferences

**Pros:**

- Familiar to macOS users
- Large package repository
- Good for GUI apps
- Easy to use

**Cons:**

- Not truly declarative (no rollback)
- Doesn't manage dotfiles
- Doesn't manage system settings
- Brewfile isn't a complete system state

### Best of Both Worlds

**This configuration uses both:**

```nix
# Nix for CLI tools (reproducible, version-locked)
environment.systemPackages = with pkgs; [
  ripgrep
  bat
  eza
];

# Homebrew for GUI apps (better macOS integration)
homebrew.casks = [
  "visual-studio-code"
  "docker"
  "claude-code"
];
```

---

## vs Ansible

### Ansible

**Approach:**

- Infrastructure as Code tool
- YAML-based playbooks
- Idempotent (mostly)
- Agent-less

**Pros:**

- Industry standard
- Great for servers
- Powerful templating
- Large community

**Cons:**

- Not truly declarative (imperative steps)
- No rollback mechanism
- Slower to run
- Overkill for single-user setups

### Nix-Darwin

**Pros:**

- True declarative configuration
- Instant rollbacks
- Fast execution (cached builds)
- Purpose-built for system management

**Cons:**

- Nix language learning curve
- Less familiar syntax
- Smaller community (compared to Ansible)

---

## vs Chezmoi

### Chezmoi

**Approach:**

- Dotfile manager
- Template-based
- Multi-machine support
- Version controlled

**Pros:**

- Excellent for dotfiles
- Templates for machine differences
- Easy to use
- Good documentation

**Cons:**

- Only manages dotfiles
- No package management
- No system settings
- No rollback

### When to Use Each

**Use Chezmoi if:**

- Only need dotfile management
- Want simple templating
- Don't need package management

**Use Nix-Darwin if:**

- Want complete system management
- Need reproducibility
- Want rollback capability

---

## vs GNU Stow

### GNU Stow

**Approach:**

- Symlink manager
- Simple and minimal
- Organize dotfiles in folders
- Use symlinks to home directory

**Pros:**

- Very simple
- No dependencies
- Easy to understand
- Lightweight

**Cons:**

- Only symlinks, no generation
- No package management
- No system settings
- Manual syncing

---

## vs NixOS

### NixOS

**Approach:**

- Full Linux distribution
- Everything managed by Nix
- Declarative system
- Atomic upgrades and rollbacks

**Pros:**

- Complete system control
- Everything reproducible
- Largest Nix community
- Most mature

**Cons:**

- Linux only (not macOS)
- Requires full OS replacement
- Steeper learning curve
- Less macOS app support

### Relationship

**Nix-Darwin is NixOS for macOS:**

- Same declarative approach
- Same Nix language
- Same Home Manager
- Similar configuration patterns

**Differences:**

- NixOS controls the entire OS
- Nix-Darwin works alongside macOS
- NixOS has more packages
- Nix-Darwin needs Homebrew for some things

---

## Why Choose Nix-Darwin

### Best For

1. **Developers who:**

   - Want reproducible environments
   - Work on multiple machines
   - Value declarative configuration
   - Don't mind learning Nix

2. **Teams who:**

   - Want standardized dev environments
   - Need to onboard developers quickly
   - Value documentation-as-code

3. **Power users who:**
   - Customize heavily
   - Want to track all changes
   - Need rollback capability

### Not Best For

1. **Users who:**

   - Want simplicity over power
   - Don't need multi-machine sync
   - Aren't comfortable with code
   - Just need basic dotfile management

2. **Scenarios where:**
   - Quick setup is critical
   - Learning time isn't available
   - Only need package management

---

## Decision Matrix

### Choose Nix-Darwin If

- ✅ You want complete reproducibility
- ✅ You need multi-machine management
- ✅ You value atomic rollbacks
- ✅ You're comfortable learning new tools
- ✅ You want declarative configuration
- ✅ You need version-controlled system state

### Choose Homebrew If

- ✅ You want simplicity
- ✅ You only need package management
- ✅ You don't need dotfile management
- ✅ You want quick setup
- ✅ You're already familiar with it

### Choose Chezmoi If

- ✅ You only need dotfile management
- ✅ You want simple templating
- ✅ You don't need package management
- ✅ You prefer Go over Nix

### Choose Manual If

- ✅ You have simple needs
- ✅ You only use one machine
- ✅ You don't need reproducibility
- ✅ You want maximum simplicity

---

## Conclusion

### Nix-Darwin Strengths

1. **Reproducibility:** Exact same environment every time
2. **Rollback:** Instant undo if something breaks
3. **Declarative:** Configuration is documentation
4. **Version Control:** All changes tracked in git
5. **Multi-Machine:** Easy sync across machines

### Nix-Darwin Weaknesses

1. **Learning Curve:** Nix language takes time
2. **Complexity:** More moving parts
3. **Setup Time:** Initial setup takes longer
4. **Community Size:** Smaller than Homebrew

### Bottom Line

**Nix-Darwin is worth it if:**

- You value reproducibility over simplicity
- You manage multiple machines
- You're comfortable with declarative tools
- You want a professional, maintainable setup

**Stick with alternatives if:**

- You need quick-and-easy solutions
- You only use one machine
- You don't need advanced features
- Learning Nix isn't worth the time

---

## Next Steps

- **[File Structure](reference.md)** - Detailed file organization
- **[Getting Started](../guides/installation.md)** - Install nix-darwin
- **[Migration Guide](../guides/installation.md)** - Move from other systems

---

**Understanding the architecture helps you customize effectively!**
