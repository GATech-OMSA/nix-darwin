# User vs Machine Configuration Separation

**Date**: 2025-01-06
**Status**: Documented & Implemented

---

## Overview

This document defines the clear separation between **user preferences** (same across all machines) and **machine-specific settings** (work vs personal), with implementation of conditional package installation based on machine type.

---

## Table of Contents

1. [Conceptual Separation](#conceptual-separation)
2. [Current Mixin Structure](#current-mixin-structure)
3. [User Preferences (Cross-Machine)](#user-preferences-cross-machine)
4. [Machine Type Settings](#machine-type-settings)
5. [Conditional Package Installation](#conditional-package-installation)
6. [Package Groups by Machine](#package-groups-by-machine)
7. [Implementation Details](#implementation-details)
8. [Examples](#examples)
9. [Best Practices](#best-practices)

---

## Conceptual Separation

### User Preferences
**Definition**: Settings that represent the user's personal choices and preferences, consistent across all machines regardless of context (work/personal).

**Characteristics**:
- Reflects user's workflow preferences
- Same on every machine the user works on
- Independent of employment or machine ownership
- Examples: Editor choice, shell theme, keybindings, personal aliases

### Machine Type Settings
**Definition**: Settings specific to the machine's context and purpose (work vs personal).

**Characteristics**:
- Depends on machine ownership/purpose
- Different between work and personal machines
- Often dictated by organizational policies
- Examples: AWS profiles, git email, work-specific packages, VPN configs

---

## Current Mixin Structure

```
home/_mixins/
├── base.nix         # User preferences + universal tools
├── dev.nix          # Development setup (currently uniform)
├── personal.nix     # Personal machine settings
└── work.nix         # Work machine settings
```

### Analysis of Current Structure

**✅ Already Well-Separated:**

The current structure already demonstrates good separation:

1. **base.nix** - User preferences that apply everywhere
   - Starship prompt configuration (user's preferred theme)
   - Tool preferences (fzf, bat, eza, zoxide, direnv)
   - Shell integrations

2. **dev.nix** - Development tools (currently uniform)
   - Git, GitHub CLI
   - Build tools (make)
   - Documentation tools (tldr)
   - Git delta configuration

3. **personal.nix** - Personal machine context
   - MACHINE_MODE = "home"
   - AWS_PROFILE = "personal"
   - Personal project shortcuts
   - Personal-only packages (neofetch)

4. **work.nix** - Work machine context
   - MACHINE_MODE = "work"
   - AWS multi-role system
   - Work project shortcuts
   - Work-specific packages (ODBC drivers, database tools)
   - Corporate configurations (CA bundle)

---

## User Preferences (Cross-Machine)

### Category 1: Editor & Tools
**Where**: `base.nix`, `home/jimmy/programs/vscode.nix`

**Examples**:
```nix
# Editor choice
programs.vscode.enable = true;

# Preferred tools
programs.bat.enable = true;
programs.eza.enable = true;
programs.fzf.enable = true;
```

**Rationale**: User's preferred tools are the same regardless of machine context.

### Category 2: Shell Theme & Prompt
**Where**: `base.nix`, `home/_mixins/starship.toml`

**Examples**:
```nix
# Starship prompt - user's preferred appearance
programs.starship = {
  enable = true;
  enableZshIntegration = true;
};
home.file.".config/starship.toml".source = ./starship.toml;
```

**Rationale**: Visual preferences are personal, not machine-dependent.

### Category 3: Keybindings & Shortcuts
**Where**: `home/jimmy/programs/vscode.nix`, `home/jimmy/shell/zsh.nix`

**Examples**:
```nix
# VS Code keybindings (same on all machines)
programs.vscode.keybindings = [ ... ];

# Shell aliases for system operations
programs.zsh.shellAliases = {
  ll = "eza -lh --git";
  la = "eza -lah --git";
  tree = "eza --tree";
};
```

**Rationale**: Muscle memory and workflow preferences are consistent.

### Category 4: Git Workflow Preferences
**Where**: `home/jimmy/programs/git.nix`

**Examples**:
```nix
# Git aliases (workflow preferences)
programs.git.aliases = {
  st = "status -s";
  co = "checkout";
  br = "branch";
  # ... 60+ more
};

# Git delta configuration (diff presentation preference)
programs.delta = {
  enable = true;
  options = {
    navigate = true;
    line-numbers = true;
    syntax-theme = "Nord";
  };
};
```

**Rationale**: How you work with git is a personal preference.

---

## Machine Type Settings

### Category 1: Identity & Authentication
**Where**: `home/_mixins/personal.nix`, `home/_mixins/work.nix`

**Examples**:
```nix
# Personal Machine
home.sessionVariables = {
  MACHINE_MODE = "home";
  AWS_PROFILE = "personal";
};

# Work Machine
home.sessionVariables = {
  MACHINE_MODE = "work";
  # AWS_PROFILE - Managed by awsuse command
};
programs.git.userEmail = "first.last@company.com";
```

**Rationale**: Identity depends on machine ownership/context.

### Category 2: Project Navigation
**Where**: `home/_mixins/personal.nix`, `home/_mixins/work.nix`

**Examples**:
```nix
# Personal Machine
programs.zsh.shellAliases = {
  learning = "cd ~/Dev/learning";
  courses = "cd ~/Dev/courses";
};

# Work Machine
programs.zsh.shellAliases = {
  fscst = "cd ~/Dev/scst";
  fti = "cd ~/Dev/tririga";
};
```

**Rationale**: Project locations differ by machine purpose.

### Category 3: Environment-Specific Functions
**Where**: `home/_mixins/work.nix`

**Examples**:
```nix
# Work-only functions
programs.zsh.initContent = ''
  # AWS SSO system for work accounts
  ${myLib.aws.mkAwsAccountHelper}

  # Database connectors for work databases
  ${myLib.database.mkDatabaseInstances [ ... ]}

  # Token helpers for work credentials
  ${myLib.database.mkTokenHelpers [ ... ]}
'';
```

**Rationale**: Work-specific infrastructure requires work-specific tooling.

### Category 4: Compliance & Corporate Settings
**Where**: `home/_mixins/work.nix`

**Examples**:
```nix
# Corporate CA bundle
programs.aws.caBundle = "~/.config/certs/cacert.pem";

# ODBC configuration for corporate databases
home.sessionVariables = {
  ODBCSYSINI = "/usr/local/etc";
  ODBCINI = "/usr/local/etc/odbc.ini";
};
```

**Rationale**: Corporate requirements are machine-specific.

---

## Conditional Package Installation

### Problem Statement

Currently, both machines get the same packages from `modules/shared/packages.nix` and `home/_mixins/dev.nix`. This means:

- **Personal machine** gets work-specific database tools it may not need
- **Work machine** gets packages that may be lighter on personal
- **No flexibility** in package installation based on machine purpose

### Solution: Machine-Based Package Groups

Use the existing `myLib.mkConditionalPackages` and `myLib.mkPackageGroups` helpers to create conditional package installation.

### Package Categories

1. **Essential** - Required on ALL machines
2. **Development** - Programming tools and languages
3. **Infrastructure** - Cloud, containers, IaC tools
4. **Database** - Database clients and tools
5. **Work-Specific** - Corporate/compliance tools
6. **Personal-Specific** - Personal productivity/learning tools

---

## Package Groups by Machine

### System-Level Packages (modules/shared/packages.nix)

#### Essential (All Machines)
```nix
essential = [
  # Version Control
  git git-lfs gh

  # Editors
  vim neovim

  # Shell
  zsh

  # Modern CLI Tools
  ripgrep fd delta dust duf btop procs sd

  # JSON/YAML/TOML Tools
  jq yq-go dasel

  # Network Tools
  wget curl httpie

  # System Utilities
  htop tree watch tldr neofetch

  # File Utilities
  rsync unzip p7zip duti

  # Text Processing
  gnused gawk pandoc

  # Performance & Benchmarking
  hyperfine entr

  # Code Quality
  pre-commit nodePackages.markdown-link-check

  # macOS Specific
  mkalias tmux

  # Secrets Management
  age sops
];
```

#### Development (Work + Personal - Full Stack)
```nix
development-full = [
  # Programming Languages
  go php

  # Build Tools
  gnumake

  # Containers & Orchestration
  docker-compose kubectl k9s kubernetes-helm

  # Cloud
  awscli2

  # Infrastructure as Code (commented by default)
  # terraform terraform-docs tflint tfsec

  # Interview Prep & System Design
  mermaid-cli graphviz plantuml

  # AI/ML Development
  ollama

  # Note-taking
  nb
];
```

#### Work-Specific Packages (Work Machine Only)
```nix
work-specific = [
  # Database Drivers & Clients
  unixODBC        # ODBC driver manager
  freetds         # ODBC for SQL Server
  postgresql_16   # PostgreSQL client + libpq

  # Database CLI Tools
  pgcli           # PostgreSQL CLI with auto-completion
  # mycli         # MySQL/MariaDB CLI (if needed)
];
```

#### Personal-Specific Packages (Personal Machine Only)
```nix
personal-specific = [
  # Personal tools
  neofetch        # Already installed, but explicit

  # Learning & Experimentation
  # (None currently, but space for future tools)
];
```

### User-Level Packages (home/_mixins/)

#### Development Tools (dev.nix - Currently Uniform)
```nix
home.packages = with pkgs; [
  # Version control (redundant with system, but explicit)
  git gh

  # Build tools
  gnumake

  # Documentation
  tldr
];

# Git delta configuration (user preference)
programs.delta = { ... };
```

#### Conditional in Future:
```nix
# Work machines get full development stack
home.packages = myLib.mkConditionalPackages {
  condition = myLib.isWork hostname;
  packages = with pkgs; [
    # Additional work-specific dev tools
  ];
};
```

---

## Implementation Details

### Step 1: Define Package Groups

**File**: `modules/shared/packages.nix`

```nix
{ config, pkgs, lib, myLib, hostname, ... }:

let
  # Essential packages for ALL machines
  essentialPackages = with pkgs; [
    git git-lfs gh
    vim neovim zsh
    ripgrep fd delta dust duf btop procs sd
    jq yq-go dasel
    wget curl httpie
    htop tree watch tldr neofetch
    rsync unzip p7zip duti
    gnused gawk pandoc
    hyperfine entr
    pre-commit nodePackages.markdown-link-check
    mkalias tmux age sops
  ];

  # Development packages (different by machine)
  developmentPackages = with pkgs; [
    go php
    gnumake
    docker-compose kubectl k9s kubernetes-helm
    awscli2
    mermaid-cli graphviz plantuml
    ollama
    nb
  ];

  # Work-specific packages
  workPackages = with pkgs; [
    # Currently in work.nix, could move here if desired
  ];

  # Personal-specific packages
  personalPackages = with pkgs; [
    # Future personal tools
  ];

in {
  environment.systemPackages = essentialPackages
    ++ developmentPackages
    ++ (myLib.mkConditionalPackages {
      condition = myLib.isWork hostname;
      packages = workPackages;
    })
    ++ (myLib.mkConditionalPackages {
      condition = myLib.isPersonal hostname;
      packages = personalPackages;
    });
}
```

### Step 2: Conditional in dev.nix

**File**: `home/_mixins/dev.nix`

```nix
{ config, pkgs, lib, myLib, hostname, ... }:

{
  # Base development tools for all machines
  home.packages = with pkgs; [
    git gh
    gnumake
    tldr
  ];

  # Work machines get additional dev packages
  home.packages = lib.mkMerge [
    # Base packages above

    (myLib.mkConditionalPackages {
      condition = myLib.isWork hostname;
      packages = with pkgs; [
        # Additional work-specific dev tools (if any)
      ];
    })
  ];

  # Git delta (user preference - same everywhere)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Nord";
    };
  };
}
```

### Step 3: Keep Machine-Specific in Mixins

**File**: `home/_mixins/work.nix`

```nix
{ config, pkgs, lib, myLib, ... }:

{
  # Work-specific packages (database tools, corporate compliance)
  home.packages = with pkgs; [
    unixODBC
    freetds
    postgresql_16
    pgcli
  ];

  # Machine context settings
  home.sessionVariables = {
    MACHINE_MODE = "work";
    ODBCSYSINI = "/usr/local/etc";
    ODBCINI = "/usr/local/etc/odbc.ini";
  };

  # ... rest of work-specific config
}
```

---

## Examples

### Example 1: Essential Package (All Machines)

**Package**: `ripgrep`

**Location**: `modules/shared/packages.nix` - `essentialPackages`

**Rationale**: Modern search tool needed on all machines

### Example 2: Development Package (Work Heavy, Personal Light)

**Package**: `kubectl`, `k9s`, `kubernetes-helm`

**Current**: Installed on all machines
**Future**: Could be work-only if personal machine doesn't need Kubernetes

**Implementation**:
```nix
# Option A: Keep in developmentPackages (all machines)
developmentPackages = [ kubectl k9s kubernetes-helm ];

# Option B: Move to work-only
workPackages = [ kubectl k9s kubernetes-helm ];
```

### Example 3: Work-Only Package

**Package**: `unixODBC`, `freetds`, `postgresql_16`

**Current**: In `home/_mixins/work.nix`
**Rationale**: Corporate database access, not needed on personal

**Already correctly separated** ✅

### Example 4: Personal-Only Package

**Package**: `neofetch`

**Current**: In system packages + `personal.nix`
**Future**: Could be personal-only if work doesn't need it

**Implementation**:
```nix
personalPackages = [ neofetch ];
```

---

## Best Practices

### 1. User Preferences Go in Base or User Configs

```nix
# ✅ Good - User preference in base.nix
programs.starship.enable = true;

# ✅ Good - User preference in home/jimmy/programs/
programs.vscode.keybindings = [ ... ];

# ❌ Bad - Don't duplicate preferences
# personal.nix: programs.starship.enable = true;
# work.nix: programs.starship.enable = true;
```

### 2. Machine Settings Go in Machine Mixins

```nix
# ✅ Good - Machine identity in work.nix
home.sessionVariables.MACHINE_MODE = "work";

# ✅ Good - Work-specific config in work.nix
programs.aws.caBundle = "~/.config/certs/cacert.pem";

# ❌ Bad - Don't put machine settings in base
# base.nix: AWS_PROFILE = "personal"; # Wrong!
```

### 3. Use Conditional Installation for Optional Packages

```nix
# ✅ Good - Conditional based on machine type
home.packages = myLib.mkConditionalPackages {
  condition = myLib.isWork hostname;
  packages = [ pkgs.kubectl pkgs.terraform ];
};

# ❌ Bad - Installing work tools on personal
# personal.nix: home.packages = [ pkgs.kubectl ]; # Why?
```

### 4. Document Package Rationale

```nix
# Essential packages for ALL machines
essentialPackages = [
  git           # Version control - required everywhere
  ripgrep       # Fast search - universal utility
  jq            # JSON processing - common need
];

# Work-specific packages
workPackages = [
  unixODBC      # Corporate database connectivity
  terraform     # Infrastructure as Code for work projects
];
```

### 5. Maintain Separation Boundaries

**User Layer** (Preferences):
- Editor choice
- Shell theme
- Keybindings
- Workflow aliases (ll, la, tree)
- Tool configurations

**Machine Layer** (Context):
- AWS profiles
- Git email
- Project navigation
- Corporate compliance
- Environment-specific functions

### 6. When in Doubt, Ask:

**Question**: "Would I want this the same way on a different employer's machine?"

- **Yes** → User preference (base.nix or home/jimmy/)
- **No** → Machine setting (work.nix or personal.nix)

**Question**: "Does this depend on machine ownership or purpose?"

- **Yes** → Machine setting
- **No** → User preference

---

## Current Status

### ✅ Already Well-Separated

The current configuration demonstrates excellent separation:

1. **User preferences** → base.nix (Starship, tool configs)
2. **Development tools** → dev.nix (language tools, git)
3. **Personal context** → personal.nix (MACHINE_MODE="home", personal aliases)
4. **Work context** → work.nix (MACHINE_MODE="work", AWS multi-role, databases)

### 🆕 Enhancement: Conditional Package Installation

**Implementation**:
1. Define package groups by category (essential, development, work, personal)
2. Use `myLib.mkConditionalPackages` for machine-based installation
3. Work machines get full development + database stack
4. Personal machines get lighter setup (can be customized)

### 📊 Package Distribution

**Current** (Both machines get the same):
- System packages: ~67 packages
- User packages: ~15 packages from home manager

**Future** (With conditionals):
- System packages: ~60 essential + conditional development/work/personal
- User packages: Conditional based on machine type
- Work machine: Full stack (all packages)
- Personal machine: Can be lighter (optional packages excluded)

---

## Validation

### Check Package Differences

```bash
# Count system packages for each machine
nix eval .#darwinConfigurations.mbp-jimmy.config.environment.systemPackages --json | jq 'length'
nix eval .#darwinConfigurations.mbp-work.config.environment.systemPackages --json | jq 'length'

# Should show different counts after conditionals are implemented

# Full rebuild test
darwin-rebuild switch --flake ~/nix-darwin
```

### Verify Separation

```bash
# Check that user preferences are the same
diff <(nix eval .#darwinConfigurations.mbp-jimmy.config.home-manager.users.jimmy.programs.starship --json) \
     <(nix eval .#darwinConfigurations.mbp-work.config.home-manager.users.jimmy.programs.starship --json)
# Should be identical

# Check that machine settings differ
diff <(nix eval .#darwinConfigurations.mbp-jimmy.config.home-manager.users.jimmy.home.sessionVariables --json) \
     <(nix eval .#darwinConfigurations.mbp-work.config.home-manager.users.jimmy.home.sessionVariables --json)
# Should show differences (MACHINE_MODE, AWS_PROFILE, etc.)
```

---

## Future Enhancements

### 1. Package Profiles

Create named package profiles for different development needs:

```nix
packageProfiles = {
  minimal = essentialPackages;
  developer = essentialPackages ++ developmentPackages;
  full-stack = essentialPackages ++ developmentPackages ++ dataTools;
  work = essentialPackages ++ developmentPackages ++ workPackages;
};
```

### 2. Per-Project Development Environments

Use `flake.nix` and `direnv` for project-specific package sets:

```nix
# ~/Dev/myproject/flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: {
    devShells.default = nixpkgs.mkShell {
      packages = [ pkgs.python312 pkgs.poetry ];
    };
  };
}
```

### 3. Machine Type Detection Refinement

Extend machine detection beyond work/personal:

```nix
machineTypes = {
  personal-desktop = { ... };
  personal-laptop = { ... };
  work-desktop = { ... };
  work-laptop = { ... };
  testing = { ... };
};
```

---

## References

- **Architecture Overview**: `docs/architecture/overview.md`
- **Lib Helpers**: `lib/default.nix` - `mkConditionalPackages`, `mkPackageGroups`
- **Machine Detection**: `lib/machine-detection.nix`
- **System Packages**: `modules/shared/packages.nix`
- **User Mixins**: `home/_mixins/*.nix`

---

**Status**: Documented ✅
**Implementation**: Ready for conditional package installation
**Backward Compatibility**: Maintained - current setup still works
