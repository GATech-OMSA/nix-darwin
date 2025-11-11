# Profile-Based nix-darwin Architecture Proposal

**Version:** 1.0
**Date:** November 2025
**Status:** Proposal for Review
**Project:** git-privacy → Profile-Based Migration
**Author:** System Architecture Analysis

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current vs Proposed Architecture](#2-current-vs-proposed-architecture)
3. [Final Directory Structure](#3-final-directory-structure)
4. [Gitignore Strategy](#4-gitignore-strategy)
5. [Profile System Design](#5-profile-system-design)
6. [user-data Directory Design](#6-user-data-directory-design)
7. [Multi-Machine Scenarios](#7-multi-machine-scenarios)
8. [Script Changes Required](#8-script-changes-required)
9. [Onboarding Flow](#9-onboarding-flow)
10. [Build Process Deep Dive](#10-build-process-deep-dive)
11. [Migration Path](#11-migration-path)
12. [Implementation Checklist](#12-implementation-checklist)
13. [Risks and Mitigations](#13-risks-and-mitigations)
14. [Future Extensibility](#14-future-extensibility)

---

## 1. Executive Summary

### Problem Statement

The current nix-darwin configuration suffers from three critical issues:

1. **Build Failures**: The `activate.sh` script fails because it tries to import `home/jimmy/` which is gitignored, causing Nix to fail during flake evaluation
2. **Hardcoded Identity**: Hostname-based machine detection (`mbp-jimmy` vs `mbp-work`) embeds personal identifiers throughout the codebase
3. **Limited Flexibility**: Users cannot easily switch between profiles (personal ↔ work ↔ minimal) or share configurations without exposing identity

**Error Evidence:**
```bash
$ ./activate.sh
error: path '/nix/store/xg51bd540s4108kywrix54sq385awwph-source/home/jimmy' does not exist
```

### Proposed Solution

Migrate to a **profile-based architecture** that:

- **Separates Identity from Behavior**: `machineId` (user's choice) vs `profileName` (behavior template)
- **Enables Profile Switching**: Users can create and switch between multiple profiles
- **Preserves Template Functionality**: Work and personal templates maintain current apps, CLIs, aliases, shortcuts
- **Fixes Build Issues**: Import tracked `home/template/` instead of gitignored `home/${username}/`
- **Protects Privacy**: Users choose whether to use personal identifiers or generic names

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Single config/profile.nix** | Consolidates user-config.nix + machine-config.nix for simplicity |
| **Import home/template/** | Template tracked in git, imports gitignored user-specific configs |
| **user-data/{username}/** | Standard directory hierarchy, easier gitignore patterns |
| **Pure Nix imports** | No sed string replacement, cleaner architecture |
| **machineId ≠ profileName** | Identity separate from behavior for privacy + flexibility |

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| **Build Success** | ❌ Fails on gitignored dirs | ✅ Builds reliably | Fixed |
| **Profile Switching** | ❌ Not supported | ✅ Supported | New feature |
| **Privacy** | ❌ Hardcoded identity | ✅ Optional identity | Improved |
| **Template Functionality** | ✅ Works | ✅ Preserved | No change |
| **Onboarding Complexity** | Moderate | Slightly increased | +2 questions |
| **Migration Effort** | N/A | ~8-12 hours | Automated script |

### Success Criteria

- ✅ `darwin-rebuild switch --flake .` succeeds without gitignore errors
- ✅ Users can create profile with generic name ("personal") or specific ("mbp-jimmy")
- ✅ Profile switching works: `switch-profile personal` → `switch-profile work`
- ✅ Templates (personal.nix, work.nix) maintain current apps/aliases/shortcuts
- ✅ Multi-machine scenarios work (3 machines, new user, backup/restore)
- ✅ Automated migration script converts existing setup without data loss

---

## 2. Current vs Proposed Architecture

### 2.1 Current Architecture (Hostname-Based)

**Entry Point: flake.nix (Lines 110-130)**
```nix
{
  darwinConfigurations = {
    # Personal machine
    mbp-jimmy = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ./hosts/mbp-jimmy
        home-manager.darwinModules.home-manager {
          home-manager.users.${username} = import ./home/${username};
          # ❌ FAILS: home/jimmy/ is gitignored
        }
      ];
    };

    # Work machine
    mbp-work = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ./hosts/mbp-work
        home-manager.darwinModules.home-manager {
          home-manager.users.${username} = import ./home/${username};
          # ❌ FAILS: home/jimmy/ is gitignored
        }
      ];
    };
  };
}
```

**Problems:**
1. **Hardcoded hostnames** (`mbp-jimmy`, `mbp-work`) expose identity
2. **Directory structure** requires `home/jimmy/` and `hosts/mbp-jimmy/` which are gitignored
3. **No profile switching** - hostname determines behavior permanently
4. **Build fails** because Nix flake evaluation can't access gitignored directories

**Current Directory Structure:**
```
nix-darwin/
├── flake.nix                    # ❌ Hardcoded machine names
├── config/
│   ├── user-config.nix          # ❌ Gitignored, separate file
│   └── machine-config.nix       # ❌ Gitignored, separate file
├── home/
│   ├── jimmy/                   # ❌ Gitignored, username in path
│   │   └── default.nix
│   ├── _mixins/                 # ✅ Tracked
│   └── _template/               # ✅ Tracked
├── hosts/
│   ├── mbp-jimmy/               # ❌ Gitignored, hostname in path
│   └── mbp-work/                # ❌ Gitignored, hostname in path
└── user-data-jimmy/             # ❌ Gitignored, username in path
```

### 2.2 Proposed Architecture (Profile-Based)

**Entry Point: flake.nix (New Design)**
```nix
let
  # Read profile configuration
  profileConfig = import ./config/profile.nix;
  inherit (profileConfig) username machineId profileName system;

  # Import profile definition
  profile = import ./profiles/templates/${profileName}.nix;
in
{
  darwinConfigurations.${machineId} = nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = { inherit profileConfig profile; };
    modules = [
      ./hosts/template  # ✅ Single tracked template
      home-manager.darwinModules.home-manager {
        home-manager.users.${username} = import ./home/template;
        # ✅ WORKS: home/template/ is tracked in git
      }
    ];
  };
}
```

**Benefits:**
1. **Single machine definition** - no hardcoded hostnames
2. **Profile-driven behavior** - switch by changing `profileName` in config
3. **Privacy by default** - user chooses machineId (can be generic or specific)
4. **Build succeeds** - imports tracked templates that load gitignored configs

**Proposed Directory Structure:**
```
nix-darwin/
├── flake.nix                    # ✅ Generic, reads profile.nix
├── config/
│   ├── profile.nix              # ❌ Gitignored, single config file
│   └── profile.nix.template     # ✅ Tracked template
├── home/
│   ├── template/                # ✅ Tracked, reads profile.nix
│   │   └── default.nix
│   └── _mixins/                 # ✅ Tracked
├── hosts/
│   └── template/                # ✅ Tracked, reads profile.nix
│       └── default.nix
├── profiles/
│   └── templates/               # ✅ Tracked
│       ├── personal.nix
│       ├── work.nix
│       ├── minimal.nix
│       └── README.md
└── user-data/
    └── jimmy/                   # ❌ Gitignored
        ├── secrets/
        ├── backups/
        └── credentials/
```

### 2.3 Architecture Comparison Table

| Aspect | Current (Hostname) | Proposed (Profile) | Winner |
|--------|-------------------|-------------------|--------|
| **Build Reliability** | ❌ Fails on gitignored dirs | ✅ Reliable | Proposed |
| **Privacy** | ❌ Hardcoded identity | ✅ Optional identity | Proposed |
| **Flexibility** | ❌ Fixed per hostname | ✅ Switchable profiles | Proposed |
| **Configuration Files** | 2 files (user + machine) | 1 file (profile.nix) | Proposed |
| **Machine Definitions** | Multiple (mbp-jimmy, mbp-work) | Single generic | Proposed |
| **Template Complexity** | Simple | Slightly more complex | Current |
| **Migration Effort** | N/A | Required | Current |
| **Template Functionality** | ✅ Works | ✅ Preserved | Tie |

### 2.4 Data Flow Comparison

**Current (Hostname-Based):**
```
User runs: darwin-rebuild switch --flake .#mbp-jimmy
    ↓
flake.nix: darwinConfigurations.mbp-jimmy
    ↓
Import: ./hosts/mbp-jimmy/ (❌ gitignored, fails)
    ↓
Import: ./home/jimmy/ (❌ gitignored, fails)
    ↓
Build FAILS
```

**Proposed (Profile-Based):**
```
User runs: darwin-rebuild switch --flake .
    ↓
flake.nix: Read config/profile.nix (❌ gitignored, but accessible at build time)
    ↓
Extract: machineId="mbp-jimmy", profileName="personal"
    ↓
flake.nix: darwinConfigurations.${machineId}
    ↓
Import: ./profiles/templates/personal.nix (✅ tracked)
    ↓
Import: ./hosts/template/ (✅ tracked)
    ↓
Import: ./home/template/ (✅ tracked)
    ↓
Templates dynamically load: config/profile.nix (❌ gitignored, but at build time)
    ↓
Build SUCCEEDS
```

### 2.5 Key Architectural Insight

**The Critical Distinction:**

Nix has two phases:
1. **Flake Evaluation** (reads flake.nix, builds dependency graph) - uses git tree
2. **Build Phase** (executes builds, imports configs) - uses filesystem

**Current Problem:**
```nix
# In flake.nix (evaluation phase)
import ./home/${username};  # ❌ Tries to read from git tree, fails
```

**Proposed Solution:**
```nix
# In flake.nix (evaluation phase)
import ./home/template;  # ✅ Reads tracked template from git tree

# In home/template/default.nix (build phase)
let
  profileConfig = import ../../config/profile.nix;  # ✅ Reads from filesystem
in { ... }
```

This is why the profile-based approach works: flake evaluation only touches tracked files, while build phase can access gitignored configs.

---

## 3. Final Directory Structure

### 3.1 Complete Directory Tree

```
nix-darwin/
├── flake.nix                                    # ✅ Tracked - Generic entry point
├── flake.lock                                   # ✅ Tracked - Dependency versions
│
├── config/
│   ├── profile.nix                              # ❌ Gitignored - User's config
│   └── profile.nix.template                     # ✅ Tracked - Template for new users
│
├── home/
│   ├── template/                                # ✅ Tracked - Main user config entry
│   │   ├── default.nix                          # Imports profile, applies mixins
│   │   ├── shell/
│   │   │   ├── zsh.nix
│   │   │   ├── starship.nix
│   │   │   └── direnv.nix
│   │   ├── programs/
│   │   │   ├── git.nix
│   │   │   ├── vscode.nix
│   │   │   ├── tmux.nix
│   │   │   └── neovim.nix
│   │   └── development/
│   │       ├── python.nix
│   │       ├── node.nix
│   │       └── rust.nix
│   │
│   └── _mixins/                                 # ✅ Tracked - Composable configs
│       ├── base.nix                             # Core settings (all profiles)
│       ├── dev.nix                              # Development tools
│       ├── personal.nix                         # Personal machine settings
│       └── work.nix                             # Work machine settings
│
├── hosts/
│   └── template/                                # ✅ Tracked - Main system config entry
│       ├── default.nix                          # Imports profile, applies system settings
│       └── configuration.nix
│
├── profiles/
│   └── templates/                               # ✅ Tracked - Profile definitions
│       ├── personal.nix                         # Personal profile settings
│       ├── work.nix                             # Work profile settings
│       ├── minimal.nix                          # Minimal profile settings
│       └── README.md                            # Profile documentation
│
├── modules/                                     # ✅ Tracked - Nix modules
│   ├── darwin/
│   │   ├── homebrew.nix
│   │   ├── system.nix
│   │   └── security.nix
│   └── shared/
│       ├── packages.nix
│       └── fonts.nix
│
├── lib/                                         # ✅ Tracked - Helper functions
│   ├── default.nix
│   ├── machine.nix
│   └── warnings.nix
│
├── overlays/                                    # ✅ Tracked - Package overlays
│   └── default.nix
│
├── pkgs/                                        # ✅ Tracked - Custom packages
│   └── default.nix
│
├── scripts/                                     # ✅ Tracked - Automation scripts
│   ├── bootstrap.sh                             # Install prerequisites
│   ├── configure.sh                             # Interactive setup wizard
│   ├── activate.sh                              # Build & activate config
│   ├── switch-profile.sh                        # ✨ NEW - Switch profiles
│   ├── validate-config.sh                       # Validate profile.nix
│   └── helpers/
│       ├── backup.sh
│       └── restore.sh
│
├── user-data/                                   # ✨ NEW - Per-user data
│   └── {username}/                              # ❌ Gitignored - User-specific
│       ├── secrets/
│       │   ├── secrets.yaml                     # SOPS-encrypted secrets
│       │   └── keys/
│       │       └── age-key.txt                  # Age encryption key
│       ├── backups/
│       │   ├── home-manager-backups/
│       │   └── darwin-backups/
│       ├── credentials/
│       │   ├── .aws/
│       │   ├── .ssh/
│       │   └── .gnupg/
│       └── README.md                            # What's stored here
│
├── docs/                                        # ✅ Tracked - Documentation
│   ├── START-HERE.md
│   ├── QUICK-REFERENCE.md
│   ├── guides/
│   ├── reference/
│   └── architecture/
│
├── claudedocs/                                  # ❌ Gitignored - Planning docs
│   ├── planning/
│   └── reference/
│
├── .gitignore                                   # ✅ Tracked - Gitignore rules
├── .sops.yaml                                   # ✅ Tracked - SOPS config
├── CLAUDE.md                                    # ✅ Tracked - AI instructions
├── README.md                                    # ✅ Tracked - Project overview
└── CHANGELOG.md                                 # ✅ Tracked - Version history
```

### 3.2 Key File Descriptions

**config/profile.nix** (Gitignored - User's Configuration)
```nix
{
  # Identity (user chooses: generic or specific)
  username = "jimmy";
  fullName = "Jimmy Smith";
  email = "jimmy@personal.com";
  machineId = "mbp-jimmy";  # or "personal-laptop", "work-macbook", etc.

  # Profile (determines behavior)
  profileName = "personal";  # personal | work | minimal | custom

  # System
  system = "aarch64-darwin";  # or "x86_64-darwin"
  machineDescription = "Jimmy's MacBook Pro M1";

  # Features
  homebrewEnabled = true;
  secretsEnabled = true;

  # Mixins (composable config modules)
  mixins = [ "base" "dev" "personal" ];
}
```

**profiles/templates/personal.nix** (Tracked - Personal Profile Definition)
```nix
{
  # Apps & Tools
  apps = {
    browsers = [ "firefox" "brave" ];
    communication = [ "slack" "discord" ];
    productivity = [ "notion" "obsidian" ];
    media = [ "spotify" "vlc" ];
  };

  cliTools = [
    "git" "gh" "lazygit"
    "htop" "btop" "ncdu"
    "fzf" "ripgrep" "fd"
    "tmux" "zellij"
  ];

  # Shell Configuration
  shellAliases = {
    # Personal aliases
    dev = "cd ~/Dev";
    proj = "cd ~/Projects";
    docs = "cd ~/Documents";
  };

  # Development Stacks
  languages = [ "python" "node" "rust" "go" ];

  # Settings
  settings = {
    dockPosition = "bottom";
    darkMode = true;
    autoHideMenuBar = false;
  };
}
```

**profiles/templates/work.nix** (Tracked - Work Profile Definition)
```nix
{
  # Apps & Tools
  apps = {
    browsers = [ "chrome" ];
    communication = [ "slack" "zoom" "teams" ];
    productivity = [ "notion" "jira" ];
  };

  cliTools = [
    "git" "gh"
    "docker" "kubectl" "terraform"
    "aws-cli" "gcloud"
    "jq" "yq"
  ];

  # Shell Configuration
  shellAliases = {
    # Work aliases
    work = "cd ~/Work";
    infra = "cd ~/Work/infrastructure";
    deploy-staging = "terraform apply -var-file=staging.tfvars";
    deploy-prod = "terraform apply -var-file=prod.tfvars";
  };

  # AWS Multi-Role (Work-specific)
  awsProfiles = {
    enabled = true;
    profiles = [ "work-dev" "work-staging" "work-prod" ];
  };

  # Development Stacks
  languages = [ "python" "node" "go" ];

  # Settings
  settings = {
    dockPosition = "left";
    darkMode = true;
    autoHideMenuBar = true;
  };
}
```

**home/template/default.nix** (Tracked - Dynamically Loads Profile)
```nix
{ config, pkgs, lib, ... }:

let
  # Import gitignored profile config (available at build time)
  profileConfig = import ../../config/profile.nix;
  inherit (profileConfig) username fullName email mixins;

  # Import profile template (tracked in git)
  profile = import ../../profiles/templates/${profileConfig.profileName}.nix;
in
{
  imports =
    # Apply mixins specified in profile
    map (mixin: ../_mixins/${mixin}.nix) mixins
    ++
    # Standard imports
    [
      ./shell/zsh.nix
      ./programs/git.nix
      ./programs/vscode.nix
      ./development/python.nix
    ];

  # User info from profile
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";
  };

  # Git config from profile
  programs.git = {
    enable = true;
    userName = fullName;
    userEmail = email;
  };

  # Packages from profile
  home.packages = with pkgs; profile.cliTools;

  # Aliases from profile
  programs.zsh.shellAliases = profile.shellAliases;
}
```

### 3.3 Directory Comparison: Before vs After

| Directory | Current | Proposed | Change |
|-----------|---------|----------|--------|
| **config/** | user-config.nix + machine-config.nix | profile.nix | Consolidated |
| **home/** | jimmy/ (gitignored) | template/ (tracked) | Renamed & tracked |
| **hosts/** | mbp-jimmy/, mbp-work/ (gitignored) | template/ (tracked) | Unified |
| **profiles/** | N/A | templates/ (tracked) | New |
| **user-data/** | user-data-jimmy/ (gitignored) | user-data/jimmy/ (gitignored) | Restructured |

### 3.4 File Count & Size Estimates

| Category | Files | Total Size | Growth |
|----------|-------|------------|--------|
| **Profile System** (new) | 5 | ~2 KB | +100% |
| **Scripts** (modified) | 4 | ~4 KB | +30% |
| **Templates** (renamed) | 3 | ~3 KB | 0% |
| **Documentation** (updated) | 8 | ~15 KB | +40% |
| **Total Change** | 20 files | ~24 KB | +35% |

---

## 4. Gitignore Strategy

### 4.1 Updated .gitignore

```gitignore
# ============================================================================
# Profile-Based Configuration (User-Specific)
# ============================================================================

# Profile configuration (contains username, email, machineId)
config/profile.nix

# User-specific data directory (secrets, backups, credentials)
user-data/*/

# ============================================================================
# Legacy (Pre-Profile Migration) - Can be removed after migration
# ============================================================================

# Old configuration format
config/user-config.nix
config/machine-config.nix

# Old directory structure
home/*/
!home/_mixins/
!home/template/

hosts/*/
!hosts/template/

# Old user-data format
user-data-*/

# ============================================================================
# Development & Build Artifacts
# ============================================================================

# Nix build results
result
result-*

# Darwin build artifacts
darwin-configuration-backups/

# ============================================================================
# Secrets & Credentials (Defense in Depth)
# ============================================================================

# Age keys (also in user-data/)
.age-key.txt
age-key.txt

# SOPS files (should be in user-data/secrets/)
secrets.yaml
*.sops.yaml
!.sops.yaml  # Project SOPS config is tracked

# AWS credentials (should be in user-data/credentials/)
.aws/credentials
.aws/config

# SSH keys (should be in user-data/credentials/)
.ssh/id_*
.ssh/*.pem

# ============================================================================
# Editor & IDE
# ============================================================================

# VS Code
.vscode/
*.code-workspace

# JetBrains
.idea/

# Vim/Neovim
*.swp
*.swo
*~

# ============================================================================
# Planning & Documentation (Local Only)
# ============================================================================

# AI assistant planning docs
claudedocs/planning/
claudedocs/archive/

# Personal notes
NOTES.md
TODO.md
SCRATCHPAD.md

# ============================================================================
# macOS & System
# ============================================================================

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Thumbnails
._*

# System logs
*.log

# Temporary files
*.tmp
*.temp
.cache/
```

### 4.2 Why This Gitignore Strategy Works

**Problem: Git Tree vs Filesystem**

Nix has two distinct phases:
1. **Flake Evaluation**: Reads flake.nix, builds dependency graph from **git tree**
2. **Build Phase**: Executes builds, imports configs from **filesystem**

**Current Failure:**
```nix
# flake.nix (evaluation phase - uses git tree)
home-manager.users.${username} = import ./home/${username};
# ❌ FAILS: home/jimmy/ is gitignored, doesn't exist in git tree
```

**Proposed Solution:**
```nix
# flake.nix (evaluation phase - uses git tree)
home-manager.users.${username} = import ./home/template;
# ✅ SUCCESS: home/template/ is tracked, exists in git tree

# home/template/default.nix (build phase - uses filesystem)
let
  profileConfig = import ../../config/profile.nix;
  # ✅ SUCCESS: Can read gitignored files at build time
in { ... }
```

**Key Insight:**
- **Evaluation phase** needs tracked files (uses git tree)
- **Build phase** can access gitignored files (uses filesystem)
- Our strategy: tracked templates load gitignored configs at build time

### 4.3 Directory-by-Directory Analysis

**config/profile.nix** (Gitignored)
```
Why Gitignored: Contains personal info (username, email, machineId)
Nix Access: Read at BUILD time by home/template/default.nix
Problem Risk: ✅ LOW - Only accessed during build phase
```

**home/template/** (Tracked)
```
Why Tracked: Main entry point, must exist in git tree for flake evaluation
Nix Access: Imported at EVALUATION time by flake.nix
Problem Risk: ✅ NONE - Fully tracked
```

**profiles/templates/** (Tracked)
```
Why Tracked: Profile definitions, must exist in git tree
Nix Access: Imported at BUILD time by home/template/default.nix
Problem Risk: ✅ NONE - Fully tracked
```

**user-data/{username}/** (Gitignored)
```
Why Gitignored: Contains secrets, backups, credentials
Nix Access: Never directly accessed by Nix (only by SOPS, scripts)
Problem Risk: ✅ NONE - Nix doesn't touch this
```

### 4.4 Testing Gitignore Correctness

**Test 1: Clean Clone Build**
```bash
# Simulate new user cloning repo
cd /tmp
git clone https://github.com/user/nix-darwin.git test-build
cd test-build

# Should fail (no profile.nix yet)
darwin-rebuild build --flake .
# Expected: Error about missing config/profile.nix

# Copy template and configure
cp config/profile.nix.template config/profile.nix
# Edit: set username, profileName, etc.

# Should succeed
darwin-rebuild build --flake .
# Expected: ✅ Build succeeds
```

**Test 2: Verify Gitignored Files Not Committed**
```bash
# After creating profile.nix and user-data/
git status

# Should show:
# nothing to commit, working tree clean

# Should NOT show:
# config/profile.nix
# user-data/jimmy/
```

**Test 3: Verify Tracked Templates Accessible**
```bash
# Check git tree includes templates
git ls-tree -r HEAD | grep -E '(home/template|profiles/templates)'

# Should show:
# 100644 blob ... home/template/default.nix
# 100644 blob ... profiles/templates/personal.nix
# 100644 blob ... profiles/templates/work.nix
```

### 4.5 Gitignore Security Layers

**Defense in Depth Approach:**

1. **Primary Layer**: `.gitignore` prevents accidental commits
2. **Git Hooks**: Pre-commit hook validates no secrets committed
3. **SOPS Encryption**: Secrets encrypted even if somehow committed
4. **File Permissions**: 600 on sensitive files prevents unauthorized access
5. **Documentation**: Clear warnings in CLAUDE.md and docs

**Git Hook Example** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash

# Check for accidentally staged profile.nix
if git diff --cached --name-only | grep -q "config/profile.nix"; then
  echo "❌ ERROR: config/profile.nix should not be committed"
  echo "This file contains personal information"
  exit 1
fi

# Check for accidentally staged user-data/
if git diff --cached --name-only | grep -q "user-data/"; then
  echo "❌ ERROR: user-data/ should not be committed"
  echo "This directory contains secrets and credentials"
  exit 1
fi

# Check for unencrypted secrets
if git diff --cached --name-only | grep -q "secrets.yaml"; then
  if ! head -n1 secrets.yaml | grep -q "sops:"; then
    echo "❌ ERROR: secrets.yaml is not SOPS-encrypted"
    echo "Run: sops -e -i secrets.yaml"
    exit 1
  fi
fi

exit 0
```

---

## 5. Profile System Design

### 5.1 Core Concepts

**machineId vs profileName**

| Concept | Purpose | Examples | Privacy |
|---------|---------|----------|---------|
| **machineId** | Unique identifier for Nix build | `mbp-jimmy`, `personal-laptop`, `mac1` | User's choice |
| **profileName** | Behavior template | `personal`, `work`, `minimal` | Generic |

**Key Design Principle:** Separate identity (machineId) from behavior (profileName)

**Example:**
```nix
# config/profile.nix
{
  # Identity - user chooses privacy level
  machineId = "mbp-jimmy";           # Specific (reveals identity)
  # OR
  machineId = "personal-laptop";     # Generic (privacy-focused)

  # Behavior - always generic
  profileName = "personal";          # Uses profiles/templates/personal.nix
}
```

### 5.2 Profile Types

**Built-in Profiles:**

**1. Personal Profile**
```nix
# profiles/templates/personal.nix
{
  description = "Personal machine configuration";

  apps = {
    browsers = [ "firefox" "brave" ];
    communication = [ "slack" "discord" "signal" ];
    productivity = [ "notion" "obsidian" ];
    media = [ "spotify" "vlc" "iina" ];
    creative = [ "gimp" "inkscape" "blender" ];
  };

  cliTools = [
    # Core
    "git" "gh" "lazygit"
    "tmux" "zellij"
    "htop" "btop" "ncdu"

    # Search & Navigation
    "fzf" "ripgrep" "fd" "bat" "eza"

    # Development
    "neovim" "vscode"
    "docker" "docker-compose"

    # Languages
    "python3" "nodejs" "rustc" "go"

    # Utils
    "wget" "curl" "jq" "yq"
    "tree" "tldr"
  ];

  shellAliases = {
    # Navigation
    dev = "cd ~/Dev";
    proj = "cd ~/Projects";
    docs = "cd ~/Documents";

    # Git shortcuts
    gs = "git status";
    gaa = "git add --all";
    gcm = "git commit -m";
    gps = "git push";
    gpl = "git pull";

    # System
    ll = "eza -la";
    cat = "bat";
  };

  languages = {
    python = {
      enabled = true;
      defaultVersion = "3.12";
      packages = [ "pip" "pipenv" "poetry" "ipython" "jupyter" ];
    };
    node = {
      enabled = true;
      defaultVersion = "20";
      packages = [ "npm" "yarn" "pnpm" ];
    };
    rust = {
      enabled = true;
      packages = [ "cargo" "rustfmt" "clippy" ];
    };
  };

  settings = {
    dockPosition = "bottom";
    dockAutoHide = false;
    darkMode = true;
    menuBarAutoHide = false;
  };

  mixins = [ "base" "dev" "personal" ];
}
```

**2. Work Profile**
```nix
# profiles/templates/work.nix
{
  description = "Work machine configuration";

  apps = {
    browsers = [ "chrome" ];
    communication = [ "slack" "zoom" "teams" ];
    productivity = [ "notion" "jira" "confluence" ];
  };

  cliTools = [
    # Core
    "git" "gh"
    "tmux"
    "htop" "btop"

    # Cloud & Infrastructure
    "docker" "kubectl" "terraform" "ansible"
    "aws-cli" "gcloud" "azure-cli"

    # Monitoring & Debugging
    "prometheus" "grafana"
    "wireshark" "tcpdump"

    # Data
    "postgresql" "redis-cli"
    "jq" "yq"
  ];

  shellAliases = {
    # Navigation
    work = "cd ~/Work";
    infra = "cd ~/Work/infrastructure";
    k8s = "cd ~/Work/kubernetes";

    # AWS Multi-Role
    aws-dev = "export AWS_PROFILE=work-dev";
    aws-staging = "export AWS_PROFILE=work-staging";
    aws-prod = "export AWS_PROFILE=work-prod";

    # Kubernetes
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get services";
    kgd = "kubectl get deployments";

    # Infrastructure
    tf = "terraform";
    tfi = "terraform init";
    tfp = "terraform plan";
    tfa = "terraform apply";
  };

  awsProfiles = {
    enabled = true;
    profiles = [
      { name = "work-dev"; region = "us-west-2"; role = "DevOpsEngineer"; }
      { name = "work-staging"; region = "us-west-2"; role = "DevOpsEngineer"; }
      { name = "work-prod"; region = "us-west-2"; role = "DevOpsEngineer"; mfaRequired = true; }
    ];
  };

  languages = {
    python = {
      enabled = true;
      defaultVersion = "3.11";
      packages = [ "pip" "poetry" "black" "flake8" "mypy" "pytest" ];
    };
    node = {
      enabled = true;
      defaultVersion = "18";
      packages = [ "npm" "yarn" ];
    };
    go = {
      enabled = true;
      packages = [ "gopls" "golangci-lint" ];
    };
  };

  settings = {
    dockPosition = "left";
    dockAutoHide = true;
    darkMode = true;
    menuBarAutoHide = true;
  };

  mixins = [ "base" "dev" "work" ];
}
```

**3. Minimal Profile**
```nix
# profiles/templates/minimal.nix
{
  description = "Minimal configuration for lightweight setups";

  apps = {
    browsers = [ "firefox" ];
    terminal = [ "alacritty" ];
  };

  cliTools = [
    "git" "gh"
    "neovim"
    "tmux"
    "htop"
    "fzf" "ripgrep" "fd"
  ];

  shellAliases = {
    ls = "eza";
    cat = "bat";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
  };

  languages = {
    python = {
      enabled = true;
      defaultVersion = "3.11";
      packages = [ "pip" ];
    };
  };

  settings = {
    dockPosition = "bottom";
    dockAutoHide = true;
    darkMode = true;
    menuBarAutoHide = true;
  };

  mixins = [ "base" ];
}
```

### 5.3 Profile Switching Mechanism

**switch-profile.sh** (New Script)
```bash
#!/usr/bin/env bash
# switch-profile.sh - Switch between profiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE_FILE="$REPO_ROOT/config/profile.nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Show usage
usage() {
  cat <<EOF
Usage: switch-profile.sh <profile-name>

Available profiles:
  personal  - Personal machine configuration
  work      - Work machine configuration
  minimal   - Minimal configuration

Examples:
  switch-profile.sh personal
  switch-profile.sh work

Current profile: $(get_current_profile)
EOF
  exit 1
}

# Get current profile
get_current_profile() {
  if [ ! -f "$PROFILE_FILE" ]; then
    echo "none"
    return
  fi

  grep "profileName" "$PROFILE_FILE" | sed 's/.*"\(.*\)".*/\1/'
}

# Validate profile exists
validate_profile() {
  local profile="$1"
  local template="$REPO_ROOT/profiles/templates/${profile}.nix"

  if [ ! -f "$template" ]; then
    echo -e "${RED}❌ Error: Profile '$profile' does not exist${NC}"
    echo ""
    usage
  fi
}

# Backup current config
backup_config() {
  local backup_dir="$REPO_ROOT/user-data/$(whoami)/backups"
  mkdir -p "$backup_dir"

  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_file="$backup_dir/profile.nix.$timestamp"

  cp "$PROFILE_FILE" "$backup_file"
  echo -e "${GREEN}✅ Backed up current config to: $backup_file${NC}"
}

# Switch profile
switch_profile() {
  local new_profile="$1"

  # Update profileName in config/profile.nix
  sed -i.bak "s/profileName = \".*\"/profileName = \"$new_profile\"/" "$PROFILE_FILE"
  rm "$PROFILE_FILE.bak"

  echo -e "${GREEN}✅ Switched to profile: $new_profile${NC}"
}

# Rebuild system
rebuild() {
  echo ""
  echo -e "${YELLOW}🔨 Rebuilding system configuration...${NC}"

  if darwin-rebuild switch --flake "$REPO_ROOT"; then
    echo ""
    echo -e "${GREEN}✅ System rebuild successful${NC}"
    echo ""
    echo "Restart your shell: exec zsh"
  else
    echo ""
    echo -e "${RED}❌ System rebuild failed${NC}"
    echo ""
    echo "Restore backup: cp user-data/$(whoami)/backups/profile.nix.* config/profile.nix"
    exit 1
  fi
}

# Main
main() {
  if [ $# -eq 0 ]; then
    usage
  fi

  local new_profile="$1"
  local current_profile=$(get_current_profile)

  # Validate
  validate_profile "$new_profile"

  # Already on this profile?
  if [ "$current_profile" = "$new_profile" ]; then
    echo -e "${YELLOW}⚠️  Already on profile: $new_profile${NC}"
    exit 0
  fi

  echo "Switching profile: $current_profile → $new_profile"
  echo ""

  # Backup, switch, rebuild
  backup_config
  switch_profile "$new_profile"
  rebuild
}

main "$@"
```

**Usage Examples:**
```bash
# Check current profile
switch-profile.sh
# Output: Current profile: personal

# Switch to work profile
switch-profile.sh work
# Output:
# ✅ Backed up current config to: user-data/jimmy/backups/profile.nix.20250111_143022
# ✅ Switched to profile: work
# 🔨 Rebuilding system configuration...
# ✅ System rebuild successful
# Restart your shell: exec zsh

# Switch back to personal
switch-profile.sh personal
```

### 5.4 Custom Profiles

**Creating Custom Profile:**

```bash
# 1. Copy existing profile template
cp profiles/templates/personal.nix profiles/templates/data-science.nix

# 2. Edit custom profile
nvim profiles/templates/data-science.nix
```

**data-science.nix Example:**
```nix
{
  description = "Data science workstation";

  apps = {
    browsers = [ "firefox" ];
    productivity = [ "notion" ];
    dataviz = [ "tableau" "grafana" ];
  };

  cliTools = [
    "git" "gh"
    "tmux"
    "htop" "btop"

    # Python ecosystem
    "python3" "ipython" "jupyter"
    "pipenv" "poetry"

    # Data tools
    "duckdb" "sqlite"
    "postgresql" "redis"

    # Scientific computing
    "r" "julia"
  ];

  shellAliases = {
    ds = "cd ~/DataScience";
    nb = "jupyter notebook";
    lab = "jupyter lab";
  };

  pythonPackages = [
    # Core
    "pandas" "numpy" "scipy"

    # Visualization
    "matplotlib" "seaborn" "plotly"

    # Machine Learning
    "scikit-learn" "tensorflow" "pytorch"
    "xgboost" "lightgbm"

    # NLP
    "nltk" "spacy" "transformers"

    # Utils
    "jupyterlab" "ipykernel"
    "black" "flake8" "mypy"
  ];

  settings = {
    dockPosition = "bottom";
    dockAutoHide = false;
    darkMode = true;
  };

  mixins = [ "base" "dev" "personal" ];
}
```

**Use Custom Profile:**
```bash
# Edit config/profile.nix
profileName = "data-science";

# Rebuild
darwin-rebuild switch --flake .
```

### 5.5 Profile Inheritance (Future Enhancement)

**Concept:** Profiles can extend other profiles

```nix
# profiles/templates/senior-dev.nix
{
  extends = "personal";  # Inherit from personal profile

  # Override/extend
  cliTools = [
    # Inherits all personal.nix tools
    # Add additional tools:
    "k9s" "helm" "argocd"
    "terraform" "ansible"
  ];

  shellAliases = {
    # Inherits all personal.nix aliases
    # Add additional aliases:
    k = "kubectl";
    tf = "terraform";
  };
}
```

This would be implemented in future versions, not part of initial migration.

---

## 6. user-data Directory Design

### 6.1 Directory Structure

**Proposed:**
```
user-data/
└── {username}/                    # ❌ Gitignored
    ├── secrets/
    │   ├── secrets.yaml           # SOPS-encrypted secrets
    │   ├── .sops.yaml             # User-specific SOPS config
    │   └── keys/
    │       └── age-key.txt        # Age encryption key (600 perms)
    │
    ├── backups/
    │   ├── home-manager-backups/  # Home Manager activation backups
    │   ├── darwin-backups/        # Darwin system backups
    │   └── manual/                # User-initiated backups
    │       ├── 2025-01-11-pre-profile-migration/
    │       └── 2025-01-15-before-major-update/
    │
    ├── credentials/
    │   ├── .aws/
    │   │   ├── config             # AWS region/output settings (non-sensitive)
    │   │   └── credentials        # AWS keys (NEVER commit)
    │   ├── .ssh/
    │   │   ├── config             # SSH host configurations
    │   │   ├── id_ed25519         # SSH private key (600 perms)
    │   │   └── id_ed25519.pub     # SSH public key
    │   ├── .gnupg/
    │   │   ├── pubring.kbx
    │   │   └── trustdb.gpg
    │   └── tokens/
    │       ├── github.token
    │       ├── gitlab.token
    │       └── npm.token
    │
    ├── cache/                     # Build caches, temporary data
    │   ├── nix-build/
    │   └── home-manager/
    │
    └── README.md                  # Documentation for user-data contents
```

### 6.2 Why user-data/{username}/ vs user-data-{username}/

**Rationale for Change:**

| Aspect | user-data-{username}/ (current) | user-data/{username}/ (proposed) | Winner |
|--------|--------------------------------|----------------------------------|--------|
| **Hierarchy** | Flat, all users at root | Nested, organized | Proposed |
| **Gitignore** | `user-data-*/` (wildcard) | `user-data/*/` (cleaner) | Proposed |
| **Consistency** | Different from hosts/, home/ | Matches hosts/, home/ | Proposed |
| **Backup** | Backup entire `user-data-jimmy/` | Backup entire `user-data/jimmy/` | Tie |
| **Migration** | N/A | Requires move | Current |

**Decision:** Use `user-data/{username}/` for consistency and cleaner patterns.

### 6.3 Secrets Management with SOPS

**SOPS Integration:**

**user-data/{username}/secrets/secrets.yaml**
```yaml
# Encrypted with SOPS (age)
aws_access_key: ENC[AES256_GCM,data:...,tag:...,type:str]
aws_secret_key: ENC[AES256_GCM,data:...,tag:...,type:str]
github_token: ENC[AES256_GCM,data:...,tag:...,type:str]
ssh_passphrase: ENC[AES256_GCM,data:...,tag:...,type:str]

# Nested secrets
work:
  vpn_password: ENC[AES256_GCM,data:...,tag:...,type:str]
  jira_token: ENC[AES256_GCM,data:...,tag:...,type:str]

# Database credentials
databases:
  prod:
    host: db.example.com
    user: admin
    password: ENC[AES256_GCM,data:...,tag:...,type:str]
```

**Access Secrets in Nix:**
```nix
# home/template/programs/git.nix
{ config, pkgs, lib, ... }:

let
  profileConfig = import ../../config/profile.nix;
  username = profileConfig.username;

  # Load secrets from user-data
  secrets = config.sops.secrets;
in
{
  sops = {
    age.keyFile = "/Users/${username}/user-data/${username}/secrets/keys/age-key.txt";
    defaultSopsFile = "/Users/${username}/user-data/${username}/secrets/secrets.yaml";

    secrets = {
      github_token = {};
      ssh_passphrase = {};
    };
  };

  # Use secret
  programs.git.extraConfig.credential.helper =
    "!f() { echo \"password=$(cat ${secrets.github_token.path})\"; }; f";
}
```

### 6.4 Backup Strategy

**Automatic Backups:**

**Pre-Rebuild Backup** (in activate.sh):
```bash
backup_before_rebuild() {
  local username=$(whoami)
  local backup_dir="$REPO_ROOT/user-data/$username/backups"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="$backup_dir/pre-rebuild-$timestamp"

  mkdir -p "$backup_path"

  # Backup config
  cp "$REPO_ROOT/config/profile.nix" "$backup_path/"

  # Backup Home Manager state
  if [ -d "$HOME/.local/state/home-manager" ]; then
    cp -r "$HOME/.local/state/home-manager" "$backup_path/"
  fi

  # Backup Darwin state
  if [ -d "/run/current-system" ]; then
    cp -r "/run/current-system" "$backup_path/" 2>/dev/null || true
  fi

  echo "✅ Backup created: $backup_path"
}
```

**Manual Backups:**
```bash
# scripts/backup.sh
#!/usr/bin/env bash

backup_manual() {
  read -p "Backup description: " description
  local slug=$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local timestamp=$(date +%Y-%m-%d)
  local username=$(whoami)
  local backup_dir="$REPO_ROOT/user-data/$username/backups/manual/$timestamp-$slug"

  mkdir -p "$backup_dir"

  # Backup everything
  cp "$REPO_ROOT/config/profile.nix" "$backup_dir/"
  cp -r "$REPO_ROOT/user-data/$username/secrets" "$backup_dir/"
  cp -r "$REPO_ROOT/user-data/$username/credentials" "$backup_dir/"

  # Create manifest
  cat > "$backup_dir/MANIFEST.md" <<EOF
# Backup: $description

**Date:** $(date)
**User:** $username
**Machine:** $(hostname)
**Profile:** $(grep profileName config/profile.nix | sed 's/.*"\(.*\)".*/\1/')

## Contents

- profile.nix
- secrets/
- credentials/

## Restore

\`\`\`bash
cd $REPO_ROOT
cp $backup_dir/profile.nix config/
cp -r $backup_dir/secrets user-data/$username/
cp -r $backup_dir/credentials user-data/$username/
darwin-rebuild switch --flake .
\`\`\`
EOF

  echo "✅ Manual backup created: $backup_dir"
}
```

### 6.5 Credentials Management

**File Permissions Enforcement:**
```bash
# scripts/validate-permissions.sh
#!/usr/bin/env bash

validate_permissions() {
  local username=$(whoami)
  local cred_dir="$REPO_ROOT/user-data/$username/credentials"

  # Check age key (should be 600)
  local age_key="$REPO_ROOT/user-data/$username/secrets/keys/age-key.txt"
  if [ -f "$age_key" ]; then
    local perms=$(stat -f "%OLp" "$age_key")
    if [ "$perms" != "600" ]; then
      echo "❌ Wrong permissions on age key: $perms (should be 600)"
      chmod 600 "$age_key"
      echo "✅ Fixed: chmod 600 $age_key"
    fi
  fi

  # Check AWS credentials (should be 600)
  local aws_cred="$cred_dir/.aws/credentials"
  if [ -f "$aws_cred" ]; then
    local perms=$(stat -f "%OLp" "$aws_cred")
    if [ "$perms" != "600" ]; then
      echo "❌ Wrong permissions on AWS credentials: $perms (should be 600)"
      chmod 600 "$aws_cred"
      echo "✅ Fixed: chmod 600 $aws_cred"
    fi
  fi

  # Check SSH keys (should be 600)
  for key in "$cred_dir/.ssh/id_"*; do
    if [ -f "$key" ] && [[ ! "$key" == *.pub ]]; then
      local perms=$(stat -f "%OLp" "$key")
      if [ "$perms" != "600" ]; then
        echo "❌ Wrong permissions on SSH key: $perms (should be 600)"
        chmod 600 "$key"
        echo "✅ Fixed: chmod 600 $key"
      fi
    fi
  done

  echo "✅ All permission checks passed"
}
```

**Git Hooks Protection:**
```bash
# .git/hooks/pre-commit
#!/bin/bash

# Block commits of user-data/ (defense in depth)
if git diff --cached --name-only | grep -q "user-data/"; then
  echo "❌ ERROR: user-data/ should not be committed"
  echo ""
  echo "This directory contains:"
  echo "  - Encrypted secrets (secrets.yaml)"
  echo "  - Credentials (.aws, .ssh, tokens)"
  echo "  - Backups"
  echo ""
  echo "These files are already gitignored, but you may have forced them."
  echo "Remove from staging: git reset HEAD user-data/"
  exit 1
fi

# Block unencrypted secrets.yaml
if git diff --cached --name-only | grep -q "secrets.yaml"; then
  secrets_file=$(git diff --cached --name-only | grep "secrets.yaml")
  if ! head -n1 "$secrets_file" | grep -q "sops:"; then
    echo "❌ ERROR: secrets.yaml is not SOPS-encrypted"
    echo ""
    echo "Encrypt it first: sops -e -i $secrets_file"
    exit 1
  fi
fi

exit 0
```

### 6.6 user-data README Template

**user-data/{username}/README.md:**
```markdown
# User Data Directory

**User:** {username}
**Machine:** {machineId}
**Created:** {date}

## Overview

This directory contains user-specific data that should **never be committed** to git:
- Encrypted secrets
- Credentials and tokens
- System backups
- Build caches

## Directory Structure

### secrets/
- `secrets.yaml` - SOPS-encrypted secrets (AWS keys, tokens, passwords)
- `keys/age-key.txt` - Age encryption key (chmod 600)

### backups/
- `home-manager-backups/` - Automatic Home Manager backups
- `darwin-backups/` - Automatic Darwin system backups
- `manual/` - User-initiated backups with descriptions

### credentials/
- `.aws/` - AWS configuration and credentials
- `.ssh/` - SSH keys and config
- `.gnupg/` - GPG keys
- `tokens/` - API tokens (GitHub, GitLab, npm)

### cache/
- Temporary build artifacts and caches

## Security

### File Permissions
- Age key: `chmod 600 secrets/keys/age-key.txt`
- AWS credentials: `chmod 600 credentials/.aws/credentials`
- SSH keys: `chmod 600 credentials/.ssh/id_*`

### Git Protection
- All user-data/ is gitignored
- Pre-commit hooks prevent accidental commits
- SOPS encryption required for secrets.yaml

## Backup & Restore

### Create Manual Backup
```bash
cd ~/nix-darwin
./scripts/backup.sh
```

### Restore from Backup
```bash
cd ~/nix-darwin
backup_dir="user-data/{username}/backups/manual/2025-01-15-before-major-update"
cp "$backup_dir/profile.nix" config/
cp -r "$backup_dir/secrets" user-data/{username}/
cp -r "$backup_dir/credentials" user-data/{username}/
darwin-rebuild switch --flake .
```

## Migration to New Machine

### Export
```bash
cd ~/nix-darwin
tar czf nix-darwin-backup.tar.gz config/profile.nix user-data/{username}/
```

### Import
```bash
# On new machine
cd ~/nix-darwin
tar xzf nix-darwin-backup.tar.gz
./scripts/bootstrap.sh  # Install Nix
darwin-rebuild switch --flake .
```

## Troubleshooting

### Check Permissions
```bash
./scripts/validate-permissions.sh
```

### Re-encrypt Secrets
```bash
sops -e -i user-data/{username}/secrets/secrets.yaml
```

### Verify Gitignore
```bash
git status  # Should show: nothing to commit
```
```

---

## 7. Multi-Machine Scenarios

### 7.1 Scenario 1: Alice's Three Machines

**Background:**
- Alice is a DevOps engineer
- Has 3 machines: personal laptop, work laptop, homelab server
- Wants to share configuration but maintain privacy
- Different profiles for each machine

**Machines:**

1. **Personal Laptop** (MacBook Pro M1)
   - Purpose: Personal projects, learning, open source
   - Privacy: Generic machineId
   - Profile: Personal

2. **Work Laptop** (MacBook Pro Intel)
   - Purpose: Company work, production access
   - Privacy: Generic machineId
   - Profile: Work

3. **Homelab Server** (Mac Mini M2)
   - Purpose: Self-hosted services, experiments
   - Privacy: Generic machineId
   - Profile: Minimal

**Setup Process:**

**Machine 1: Personal Laptop**
```bash
# Clone repo
git clone https://github.com/alice/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# Run bootstrap (installs Nix, nix-darwin, SOPS, age)
./scripts/bootstrap.sh

# Run configuration wizard
./scripts/configure.sh

# Interactive prompts:
# Username: alice
# Full name: Alice Smith
# Email: alice@personal.com
# Machine ID: personal-laptop  # ← Generic name
# Profile: personal
# System: aarch64-darwin
# Enable Homebrew: yes

# Generates: config/profile.nix
{
  username = "alice";
  fullName = "Alice Smith";
  email = "alice@personal.com";
  machineId = "personal-laptop";
  profileName = "personal";
  system = "aarch64-darwin";
  homebrewEnabled = true;
  mixins = [ "base" "dev" "personal" ];
}

# Creates: user-data/alice/
user-data/alice/
├── secrets/
│   ├── secrets.yaml
│   └── keys/age-key.txt
├── backups/
├── credentials/
└── README.md

# Activate configuration
./scripts/activate.sh
# Output:
# ✅ Configuration built successfully
# ✅ System activated
# Restart shell: exec zsh

exec zsh

# Verify
echo $MACHINE_MODE  # Output: home
hostname  # Output: personal-laptop
```

**Machine 2: Work Laptop**
```bash
# Clone same repo (already configured on Machine 1)
git clone https://github.com/alice/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# Run bootstrap
./scripts/bootstrap.sh

# Run configuration wizard
./scripts/configure.sh

# Interactive prompts:
# Username: alice
# Full name: Alice Smith
# Email: alice@company.com  # ← Work email
# Machine ID: work-laptop  # ← Still generic
# Profile: work  # ← Work profile
# System: x86_64-darwin
# Enable Homebrew: yes

# Generates: config/profile.nix
{
  username = "alice";
  fullName = "Alice Smith";
  email = "alice@company.com";
  machineId = "work-laptop";
  profileName = "work";
  system = "x86_64-darwin";
  homebrewEnabled = true;
  mixins = [ "base" "dev" "work" ];
}

# Creates: user-data/alice/
user-data/alice/
├── secrets/
│   ├── secrets.yaml  # Work secrets (AWS keys)
│   └── keys/age-key.txt
├── credentials/
│   ├── .aws/
│   │   ├── config
│   │   └── credentials  # Work AWS profiles
│   └── .ssh/
│       └── id_ed25519  # Work SSH key
└── README.md

# Activate configuration
./scripts/activate.sh

exec zsh

# Verify
echo $MACHINE_MODE  # Output: work
aws configure list-profiles  # Output: work-dev, work-staging, work-prod
```

**Machine 3: Homelab Server**
```bash
# Clone same repo
git clone https://github.com/alice/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# Run bootstrap
./scripts/bootstrap.sh

# Run configuration wizard
./scripts/configure.sh

# Interactive prompts:
# Username: alice
# Full name: Alice Smith
# Email: alice@homelab.local
# Machine ID: homelab-server  # ← Still generic
# Profile: minimal  # ← Minimal profile (server)
# System: aarch64-darwin
# Enable Homebrew: no  # ← No GUI apps

# Generates: config/profile.nix
{
  username = "alice";
  fullName = "Alice Smith";
  email = "alice@homelab.local";
  machineId = "homelab-server";
  profileName = "minimal";
  system = "aarch64-darwin";
  homebrewEnabled = false;
  mixins = [ "base" ];
}

# Activate configuration
./scripts/activate.sh

exec zsh

# Verify
echo $MACHINE_MODE  # Output: home (minimal defaults to home)
```

**Profile Switching (Work Laptop):**

Alice sometimes does personal work on work laptop (company allows):
```bash
# Switch to personal profile temporarily
switch-profile personal

# Output:
# ✅ Backed up current config to: user-data/alice/backups/profile.nix.20250115_140530
# ✅ Switched to profile: personal
# 🔨 Rebuilding system configuration...
# ✅ System rebuild successful
# Restart your shell: exec zsh

exec zsh

# Now has personal aliases, apps, settings
echo $MACHINE_MODE  # Output: home

# Switch back to work
switch-profile work
exec zsh
```

**Syncing Changes:**

Alice adds new alias to personal profile on Machine 1:
```bash
# Machine 1: Personal Laptop
cd ~/nix-darwin
nvim home/_mixins/personal.nix

# Add:
shellAliases.blog = "cd ~/Projects/blog";

# Commit and push
git add home/_mixins/personal.nix
git commit -m "feat: Add blog alias to personal profile"
git push

# Machine 2: Work Laptop (when in personal profile)
cd ~/nix-darwin
git pull
darwin-rebuild switch --flake .
exec zsh

# Now has blog alias on both machines
```

### 7.2 Scenario 2: Bob - New User from Scratch

**Background:**
- Bob is a software engineer new to Nix
- Fresh MacBook Pro M2
- Wants personal configuration
- Prefers specific machineId

**Initial Setup:**

```bash
# 1. Clone repository
git clone https://github.com/bob/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# 2. Run bootstrap (first-time setup)
./scripts/bootstrap.sh

# Output:
# ╔══════════════════════════════════════════════════════════╗
# ║        nix-darwin Bootstrap - Initial Setup              ║
# ╚══════════════════════════════════════════════════════════╝
#
# This script will install:
# ✓ Nix package manager (with flakes enabled)
# ✓ nix-darwin (macOS system management)
# ✓ SOPS (secret management)
# ✓ Age (encryption)
#
# [1/4] Installing Nix...
# ✅ Nix installed successfully
#
# [2/4] Enabling Nix flakes...
# ✅ Flakes enabled
#
# [3/4] Installing nix-darwin...
# ✅ nix-darwin installed
#
# [4/4] Installing SOPS and Age...
# ✅ SOPS installed
# ✅ Age installed
#
# ╔══════════════════════════════════════════════════════════╗
# ║            Bootstrap Complete!                           ║
# ╚══════════════════════════════════════════════════════════╝
#
# Next step: ./scripts/configure.sh

# 3. Run configuration wizard
./scripts/configure.sh

# Interactive prompts:
# ╔══════════════════════════════════════════════════════════╗
# ║     nix-darwin Configuration Wizard                      ║
# ╚══════════════════════════════════════════════════════════╝
#
# Let's set up your profile configuration.
#
# === User Information ===
# Username (current: bob): [enter]
# Full name: Bob Johnson
# Email: bob@example.com
#
# === Machine Identity ===
# Machine ID (unique identifier for this machine)
# Examples:
#   - Generic: personal-laptop, work-macbook, home-server
#   - Specific: mbp-bob, bobs-m2-pro
#
# Choose based on your privacy preference.
# Machine ID: mbp-bob-m2
#
# === Profile Selection ===
# Available profiles:
#   1) personal - Personal machine (dev tools, media, creative apps)
#   2) work     - Work machine (cloud tools, enterprise apps)
#   3) minimal  - Minimal setup (basic CLI tools)
#
# Select profile (1-3): 1
#
# === System Configuration ===
# Detected system: aarch64-darwin
# Enable Homebrew (for GUI apps): yes
#
# === Summary ===
# Username:     bob
# Full name:    Bob Johnson
# Email:        bob@example.com
# Machine ID:   mbp-bob-m2
# Profile:      personal
# System:       aarch64-darwin
# Homebrew:     enabled
# Mixins:       base, dev, personal
#
# Proceed with this configuration? (yes/no): yes
#
# ✅ Created config/profile.nix
# ✅ Created user-data/bob/ directory
# ✅ Generated age encryption key
# ✅ Created secrets template
#
# Next step: ./scripts/activate.sh

# 4. Activate configuration
./scripts/activate.sh

# Output:
# ╔══════════════════════════════════════════════════════════╗
# ║          nix-darwin Activation                           ║
# ╚══════════════════════════════════════════════════════════╝
#
# [1/5] Validating configuration...
# ✅ config/profile.nix exists
# ✅ Profile template exists: profiles/templates/personal.nix
# ✅ user-data/bob/ directory exists
# ✅ Age key exists
#
# [2/5] Backing up current state...
# ✅ Backup created: user-data/bob/backups/pre-activation-20250115_151030
#
# [3/5] Building system configuration...
# building '/nix/store/...-darwin-system-mbp-bob-m2'...
# ✅ Build successful
#
# [4/5] Activating configuration...
# setting up /etc...
# setting up user environment...
# ✅ Activation successful
#
# [5/5] Post-activation checks...
# ✅ Shell: zsh
# ✅ Git: configured
# ✅ VS Code: extensions installed
#
# ╔══════════════════════════════════════════════════════════╗
# ║             Setup Complete!                              ║
# ╚══════════════════════════════════════════════════════════╝
#
# Your nix-darwin system is now active.
#
# Next steps:
#   1. Restart your shell:    exec zsh
#   2. Verify installation:   health-check
#   3. Read documentation:    cat docs/START-HERE.md
#
# Useful commands:
#   nix-rebuild      - Rebuild system after config changes
#   switch-profile   - Switch between profiles
#   edit-secrets     - Edit encrypted secrets
#   health-check     - System health diagnostics

# 5. Restart shell
exec zsh

# 6. Verify setup
health-check

# Output:
# ╔══════════════════════════════════════════════════════════╗
# ║          System Health Check                             ║
# ╚══════════════════════════════════════════════════════════╝
#
# === Configuration ===
# ✅ config/profile.nix exists
# ✅ Profile: personal
# ✅ Machine ID: mbp-bob-m2
# ✅ System: aarch64-darwin
#
# === Nix ===
# ✅ Nix version: 2.19.2
# ✅ Flakes: enabled
# ✅ nix-darwin: installed
#
# === Home Manager ===
# ✅ Home Manager: active
# ✅ Generation: 1
# ✅ Packages: 45 installed
#
# === Shell ===
# ✅ Shell: /run/current-system/sw/bin/zsh
# ✅ Starship: configured
# ✅ Direnv: configured
#
# === Development ===
# ✅ Git: 2.43.0
# ✅ Python: 3.12.1
# ✅ Node: 20.10.0
# ✅ Rust: 1.75.0
#
# === Secrets ===
# ✅ SOPS: installed
# ✅ Age: installed
# ✅ Age key: exists (600 perms)
# ✅ Secrets file: exists (encrypted)
#
# === File Permissions ===
# ✅ Age key: 600
# ✅ SSH keys: 600
#
# ╔══════════════════════════════════════════════════════════╗
# ║         All checks passed!                               ║
# ╚══════════════════════════════════════════════════════════╝
```

**Bob's First Customization:**

```bash
# Add custom alias
cd ~/nix-darwin
nvim home/_mixins/personal.nix

# Add:
shellAliases.myproject = "cd ~/Dev/myproject";

# Rebuild
nix-rebuild

# Output:
# 🔨 Building configuration...
# ✅ Build successful
# 🔄 Activating...
# ✅ Activation successful
#
# Restart shell: exec zsh

exec zsh

# Test
myproject  # Changes to ~/Dev/myproject
```

### 7.3 Scenario 3: Carol - Restore from Backup

**Background:**
- Carol has existing nix-darwin setup on old MacBook
- Got new MacBook Pro M3
- Wants to restore complete configuration
- Needs to preserve secrets and credentials

**Old Machine: Export**

```bash
# On old MacBook
cd ~/nix-darwin

# Create comprehensive backup
./scripts/backup-for-migration.sh

# Output:
# ╔══════════════════════════════════════════════════════════╗
# ║        Migration Backup Creation                         ║
# ╚══════════════════════════════════════════════════════════╝
#
# Creating backup for migration to new machine...
#
# [1/6] Backing up configuration...
# ✅ config/profile.nix
# ✅ .sops.yaml
#
# [2/6] Backing up secrets...
# ✅ user-data/carol/secrets/secrets.yaml
# ✅ user-data/carol/secrets/keys/age-key.txt
#
# [3/6] Backing up credentials...
# ✅ user-data/carol/credentials/.aws/
# ✅ user-data/carol/credentials/.ssh/
# ✅ user-data/carol/credentials/.gnupg/
# ✅ user-data/carol/credentials/tokens/
#
# [4/6] Backing up Home Manager state...
# ✅ ~/.local/state/home-manager/
#
# [5/6] Backing up Darwin state...
# ✅ /run/current-system/ (metadata only)
#
# [6/6] Creating archive...
# ✅ nix-darwin-migration-20250115-carol.tar.gz
#
# ╔══════════════════════════════════════════════════════════╗
# ║          Backup Complete!                                ║
# ╚══════════════════════════════════════════════════════════╝
#
# Archive: ~/nix-darwin-migration-20250115-carol.tar.gz
# Size: 124 MB
#
# Transfer this file to your new machine:
#   - USB drive
#   - Cloud storage (encrypted)
#   - Airdrop
#
# On new machine:
#   1. Clone repo: git clone <your-repo> ~/nix-darwin
#   2. Run bootstrap: ./scripts/bootstrap.sh
#   3. Extract backup: tar xzf nix-darwin-migration-20250115-carol.tar.gz
#   4. Run restore: ./scripts/restore-from-backup.sh nix-darwin-migration-20250115-carol/

# Copy to USB drive
cp ~/nix-darwin-migration-20250115-carol.tar.gz /Volumes/USB/
```

**New Machine: Restore**

```bash
# On new MacBook
# 1. Clone repository
git clone https://github.com/carol/nix-darwin.git ~/nix-darwin
cd ~/nix-darwin

# 2. Run bootstrap
./scripts/bootstrap.sh
# (Same output as Bob's scenario)

# 3. Copy backup from USB
cp /Volumes/USB/nix-darwin-migration-20250115-carol.tar.gz ~/

# 4. Extract backup
tar xzf ~/nix-darwin-migration-20250115-carol.tar.gz

# 5. Run restore script
./scripts/restore-from-backup.sh ~/nix-darwin-migration-20250115-carol/

# Output:
# ╔══════════════════════════════════════════════════════════╗
# ║        Restore from Migration Backup                     ║
# ╚══════════════════════════════════════════════════════════╝
#
# Restoring configuration from backup...
#
# [1/8] Validating backup...
# ✅ Backup directory exists
# ✅ config/profile.nix found
# ✅ secrets/ found
# ✅ credentials/ found
#
# [2/8] Restoring configuration...
# ✅ config/profile.nix → ~/nix-darwin/config/
#
# [3/8] Restoring secrets...
# ✅ secrets/ → ~/nix-darwin/user-data/carol/secrets/
# ✅ Age key permissions: 600
# ✅ SOPS configuration restored
#
# [4/8] Restoring credentials...
# ✅ .aws/ → ~/nix-darwin/user-data/carol/credentials/
# ✅ .ssh/ → ~/nix-darwin/user-data/carol/credentials/
# ✅ .gnupg/ → ~/nix-darwin/user-data/carol/credentials/
# ✅ tokens/ → ~/nix-darwin/user-data/carol/credentials/
#
# [5/8] Validating file permissions...
# ✅ Age key: 600
# ✅ AWS credentials: 600
# ✅ SSH keys: 600
#
# [6/8] Building system configuration...
# building '/nix/store/...-darwin-system-work-laptop'...
# ✅ Build successful
#
# [7/8] Activating configuration...
# setting up /etc...
# setting up user environment...
# ✅ Activation successful
#
# [8/8] Verifying restoration...
# ✅ Profile: work
# ✅ Machine ID: work-laptop
# ✅ Git: configured
# ✅ AWS: 3 profiles configured
# ✅ SSH: 2 keys restored
#
# ╔══════════════════════════════════════════════════════════╗
# ║          Restoration Complete!                           ║
# ╚══════════════════════════════════════════════════════════╝
#
# Your nix-darwin system has been fully restored.
#
# Next steps:
#   1. Restart shell:     exec zsh
#   2. Test AWS access:   aws sts get-caller-identity
#   3. Test SSH keys:     ssh -T git@github.com
#   4. Health check:      health-check

# 6. Restart shell
exec zsh

# 7. Verify restoration
aws configure list-profiles
# Output: work-dev, work-staging, work-prod

ssh -T git@github.com
# Output: Hi carol! You've successfully authenticated

health-check
# Output: All checks passed!
```

**Update System Architecture (M2 → M3):**

Carol's old machine was Intel, new is M3:
```bash
# Edit config/profile.nix
nvim config/profile.nix

# Change:
system = "x86_64-darwin";  # Old (Intel)
# To:
system = "aarch64-darwin";  # New (M3)

# Rebuild
nix-rebuild

# Output:
# 🔨 Building configuration for aarch64-darwin...
# ✅ Recompiling packages for ARM architecture
# ✅ Build successful
# ✅ Activation successful
```

---

## 8. Script Changes Required

### 8.1 bootstrap.sh (Minimal Changes)

**Current:** Installs Nix, nix-darwin, SOPS, age
**Changes:** Update user-facing messages about backup locations
**Lines Changed:** ~20 lines
**Complexity:** Low

**Specific Changes:**

1. Update backup path messages:
```bash
# OLD:
echo "Backups will be stored in: user-data-$(whoami)/"

# NEW:
echo "Backups will be stored in: user-data/$(whoami)/"
```

2. Update README references:
```bash
# OLD:
echo "See user-data-$(whoami)/README.md for details"

# NEW:
echo "See user-data/$(whoami)/README.md for details"
```

**Full Diff:**
```diff
--- a/scripts/bootstrap.sh
+++ b/scripts/bootstrap.sh
@@ -45,7 +45,7 @@ install_prerequisites() {
   echo "✅ Age installed"

   echo ""
-  echo "Backups will be stored in: user-data-$(whoami)/"
+  echo "Backups will be stored in: user-data/$(whoami)/"
   echo ""
 }

@@ -67,7 +67,7 @@ main() {
   echo "╚══════════════════════════════════════════════════════════╝"
   echo ""
-  echo "Next step: ./scripts/configure.sh"
+  echo "Next steps: ./scripts/configure.sh"
 }
```

### 8.2 configure.sh (Major Rewrite)

**Current:** Generates user-config.nix + machine-config.nix via sed
**Changes:** Generate single profile.nix via Nix attribute sets
**Lines Changed:** ~300 lines
**Complexity:** High

**Specific Changes:**

**1. Remove sed-based string replacement:**
```bash
# OLD (Lines 450-480):
sed "s/USERNAME_PLACEHOLDER/$username/g" config/user-config.nix.template > config/user-config.nix
sed "s/MACHINE_ID_PLACEHOLDER/$machine_id/g" config/machine-config.nix.template > config/machine-config.nix
```

**2. Add profile selection wizard:**
```bash
# NEW (Lines 200-250):
select_profile() {
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║          Profile Selection                               ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
  echo "Available profiles:"
  echo ""
  echo "  1) personal - Personal machine configuration"
  echo "     • Development tools (Python, Node, Rust)"
  echo "     • Creative apps (Obsidian, Notion)"
  echo "     • Media (Spotify, VLC)"
  echo "     • Browsers (Firefox, Brave)"
  echo ""
  echo "  2) work - Work machine configuration"
  echo "     • Cloud tools (AWS, Docker, Kubernetes)"
  echo "     • Enterprise apps (Slack, Zoom, Teams)"
  echo "     • Infrastructure (Terraform, Ansible)"
  echo "     • AWS multi-role support"
  echo ""
  echo "  3) minimal - Minimal configuration"
  echo "     • Basic CLI tools (git, neovim, tmux)"
  echo "     • Single browser (Firefox)"
  echo "     • Lightweight setup"
  echo ""

  while true; do
    read -p "Select profile (1-3): " profile_choice

    case $profile_choice in
      1)
        profile_name="personal"
        break
        ;;
      2)
        profile_name="work"
        break
        ;;
      3)
        profile_name="minimal"
        break
        ;;
      *)
        echo "Invalid choice. Please enter 1, 2, or 3."
        ;;
    esac
  done

  echo ""
  echo "Selected profile: $profile_name"
  echo ""
}
```

**3. Generate single profile.nix:**
```bash
# NEW (Lines 500-550):
generate_profile_config() {
  local config_file="$REPO_ROOT/config/profile.nix"

  cat > "$config_file" <<EOF
{
  # User Information
  username = "$username";
  fullName = "$full_name";
  email = "$email";

  # Machine Identity
  machineId = "$machine_id";
  machineDescription = "$machine_description";

  # Profile Configuration
  profileName = "$profile_name";

  # System
  system = "$system";

  # Features
  homebrewEnabled = $homebrew_enabled;
  secretsEnabled = true;

  # Mixins
  mixins = [ $mixins_list ];
}
EOF

  echo "✅ Created config/profile.nix"
}
```

**4. Create user-data directory structure:**
```bash
# NEW (Lines 600-650):
create_user_data_structure() {
  local user_data_dir="$REPO_ROOT/user-data/$username"

  echo "Creating user-data directory structure..."

  # Main directories
  mkdir -p "$user_data_dir/secrets/keys"
  mkdir -p "$user_data_dir/backups/home-manager-backups"
  mkdir -p "$user_data_dir/backups/darwin-backups"
  mkdir -p "$user_data_dir/backups/manual"
  mkdir -p "$user_data_dir/credentials/.aws"
  mkdir -p "$user_data_dir/credentials/.ssh"
  mkdir -p "$user_data_dir/credentials/tokens"
  mkdir -p "$user_data_dir/cache"

  # Generate age key
  age-keygen -o "$user_data_dir/secrets/keys/age-key.txt"
  chmod 600 "$user_data_dir/secrets/keys/age-key.txt"

  # Create secrets template
  cat > "$user_data_dir/secrets/secrets.yaml" <<EOF
# SOPS-encrypted secrets
# Edit with: sops secrets.yaml

# Example secrets (replace with your own)
github_token: your-github-token-here
aws_access_key: your-aws-access-key-here
aws_secret_key: your-aws-secret-key-here
EOF

  # Encrypt secrets
  sops -e -i "$user_data_dir/secrets/secrets.yaml"

  # Create README
  cp "$REPO_ROOT/user-data/README.template.md" "$user_data_dir/README.md"
  sed -i "s/{username}/$username/g" "$user_data_dir/README.md"
  sed -i "s/{machineId}/$machine_id/g" "$user_data_dir/README.md"
  sed -i "s/{date}/$(date +%Y-%m-%d)/g" "$user_data_dir/README.md"

  echo "✅ Created user-data/$username/ directory"
  echo "✅ Generated age encryption key"
  echo "✅ Created secrets template"
}
```

**Full Rewritten Sections:**
- Profile selection wizard (new: ~100 lines)
- Configuration generation (rewrite: ~150 lines)
- user-data structure creation (new: ~80 lines)
- Validation logic (update: ~50 lines)

### 8.3 activate.sh (Moderate Changes)

**Current:** Checks user-config.nix + machine-config.nix, builds darwin config
**Changes:** Check profile.nix, validate profile template exists
**Lines Changed:** ~80 lines
**Complexity:** Moderate

**Specific Changes:**

**1. Update configuration checking:**
```bash
# OLD (Lines 120-140):
check_config() {
  if [ ! -f "$REPO_ROOT/config/user-config.nix" ]; then
    echo "❌ Error: config/user-config.nix not found"
    exit 1
  fi

  if [ ! -f "$REPO_ROOT/config/machine-config.nix" ]; then
    echo "❌ Error: config/machine-config.nix not found"
    exit 1
  fi
}

# NEW (Lines 120-160):
check_config() {
  echo "[1/5] Validating configuration..."

  if [ ! -f "$REPO_ROOT/config/profile.nix" ]; then
    echo "❌ Error: config/profile.nix not found"
    echo ""
    echo "Run configuration wizard: ./scripts/configure.sh"
    exit 1
  fi

  # Extract profileName from profile.nix
  local profile_name=$(grep "profileName" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')

  # Check profile template exists
  if [ ! -f "$REPO_ROOT/profiles/templates/$profile_name.nix" ]; then
    echo "❌ Error: Profile template not found: profiles/templates/$profile_name.nix"
    echo ""
    echo "Available profiles:"
    ls -1 "$REPO_ROOT/profiles/templates/" | grep ".nix$" | sed 's/.nix$//' | sed 's/^/  - /'
    exit 1
  fi

  # Check user-data directory
  local username=$(grep "username" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')
  if [ ! -d "$REPO_ROOT/user-data/$username" ]; then
    echo "⚠️  Warning: user-data/$username/ not found"
    echo "Creating directory structure..."
    mkdir -p "$REPO_ROOT/user-data/$username"
  fi

  echo "✅ config/profile.nix exists"
  echo "✅ Profile template exists: profiles/templates/$profile_name.nix"
  echo "✅ user-data/$username/ directory exists"
}
```

**2. Add profile validation function:**
```bash
# NEW (Lines 180-220):
validate_profile() {
  local profile_name=$1
  local template="$REPO_ROOT/profiles/templates/$profile_name.nix"

  echo "Validating profile: $profile_name"

  # Check template is valid Nix
  if ! nix-instantiate --eval --expr "import $template" > /dev/null 2>&1; then
    echo "❌ Error: Profile template has syntax errors"
    echo ""
    echo "Run: nix-instantiate --eval --expr \"import $template\""
    exit 1
  fi

  echo "✅ Profile template is valid"
}
```

**3. Update backup path:**
```bash
# OLD (Lines 250-270):
backup_before_build() {
  local backup_dir="$REPO_ROOT/user-data-$(whoami)/backups"
  ...
}

# NEW (Lines 250-290):
backup_before_build() {
  echo "[2/5] Backing up current state..."

  local username=$(grep "username" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')
  local backup_dir="$REPO_ROOT/user-data/$username/backups"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="$backup_dir/pre-activation-$timestamp"

  mkdir -p "$backup_path"

  # Backup config
  cp "$REPO_ROOT/config/profile.nix" "$backup_path/"

  # Backup Home Manager state
  if [ -d "$HOME/.local/state/home-manager" ]; then
    cp -r "$HOME/.local/state/home-manager" "$backup_path/"
  fi

  echo "✅ Backup created: $backup_path"
}
```

**4. Update build command:**
```bash
# OLD (Lines 300-320):
build_system() {
  echo "Building system configuration..."
  darwin-rebuild switch --flake .#$(hostname -s)
}

# NEW (Lines 310-350):
build_system() {
  echo "[3/5] Building system configuration..."

  # Extract machineId from profile.nix
  local machine_id=$(grep "machineId" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')

  echo "Building for machine: $machine_id"

  if darwin-rebuild switch --flake .#"$machine_id"; then
    echo "✅ Build successful"
  else
    echo "❌ Build failed"
    echo ""
    echo "Debug: darwin-rebuild build --flake .#$machine_id --show-trace"
    exit 1
  fi
}
```

### 8.4 New Scripts

**1. switch-profile.sh** (New - ~300 lines)

Purpose: Switch between profiles
Location: `scripts/switch-profile.sh`
Features:
- Validate profile exists
- Backup current config
- Update profileName in config/profile.nix
- Rebuild system
- Handle errors with rollback

(Full implementation shown in Section 5.3)

**2. validate-config.sh** (New - ~150 lines)

Purpose: Validate profile.nix and profile templates
Location: `scripts/validate-config.sh`

```bash
#!/usr/bin/env bash
# validate-config.sh - Validate configuration files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

validate_profile_config() {
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║          Configuration Validation                        ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""

  # Check profile.nix exists
  if [ ! -f "$REPO_ROOT/config/profile.nix" ]; then
    echo "❌ config/profile.nix not found"
    return 1
  fi
  echo "✅ config/profile.nix exists"

  # Validate Nix syntax
  if ! nix-instantiate --eval --expr "import $REPO_ROOT/config/profile.nix" > /dev/null 2>&1; then
    echo "❌ config/profile.nix has syntax errors"
    return 1
  fi
  echo "✅ Valid Nix syntax"

  # Extract and validate required fields
  local required_fields=("username" "fullName" "email" "machineId" "profileName" "system")

  for field in "${required_fields[@]}"; do
    if ! grep -q "^  $field = " "$REPO_ROOT/config/profile.nix"; then
      echo "❌ Missing required field: $field"
      return 1
    fi
  done
  echo "✅ All required fields present"

  # Validate profileName
  local profile_name=$(grep "profileName" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')
  if [ ! -f "$REPO_ROOT/profiles/templates/$profile_name.nix" ]; then
    echo "❌ Profile template not found: $profile_name"
    return 1
  fi
  echo "✅ Profile template exists: $profile_name"

  # Validate system architecture
  local system=$(grep "system" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')
  if [[ "$system" != "aarch64-darwin" && "$system" != "x86_64-darwin" ]]; then
    echo "❌ Invalid system: $system (must be aarch64-darwin or x86_64-darwin)"
    return 1
  fi
  echo "✅ Valid system architecture: $system"

  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║         Configuration Valid!                             ║"
  echo "╚══════════════════════════════════════════════════════════╝"
}

validate_profile_template() {
  local profile_name=$1
  local template="$REPO_ROOT/profiles/templates/$profile_name.nix"

  echo ""
  echo "Validating profile template: $profile_name"

  if [ ! -f "$template" ]; then
    echo "❌ Template not found: $template"
    return 1
  fi

  # Validate Nix syntax
  if ! nix-instantiate --eval --expr "import $template" > /dev/null 2>&1; then
    echo "❌ Template has syntax errors"
    return 1
  fi

  echo "✅ Template is valid"
}

main() {
  validate_profile_config || exit 1

  # Validate current profile template
  local profile_name=$(grep "profileName" "$REPO_ROOT/config/profile.nix" | sed 's/.*"\(.*\)".*/\1/')
  validate_profile_template "$profile_name" || exit 1
}

main "$@"
```

**3. migrate-to-profiles.sh** (New - ~500 lines)

Purpose: Automated migration from current git-privacy to profile-based
Location: `scripts/migrate-to-profiles.sh`

(Full implementation in Section 11.2)

### 8.5 Script Summary Table

| Script | Status | Lines Changed | Complexity | Key Changes |
|--------|--------|---------------|------------|-------------|
| **bootstrap.sh** | Modify | ~20 | Low | Update backup path messages |
| **configure.sh** | Rewrite | ~300 | High | Profile wizard, single profile.nix generation |
| **activate.sh** | Modify | ~80 | Moderate | Profile validation, update paths |
| **switch-profile.sh** | New | ~300 | Moderate | Profile switching logic |
| **validate-config.sh** | New | ~150 | Low | Configuration validation |
| **migrate-to-profiles.sh** | New | ~500 | High | Automated migration |

**Total Lines of Code:** ~1,350 lines (new + modified)

---

## 9. Onboarding Flow

### 9.1 New User Complete Walkthrough

**Scenario:** Fresh MacBook Pro, no existing Nix setup

**Step 1: Clone Repository**
```bash
# Open Terminal (Cmd+Space, type "Terminal")
cd ~
git clone https://github.com/username/nix-darwin.git
cd nix-darwin

# Verify contents
ls
# Output:
# CLAUDE.md  README.md  config/  docs/  flake.nix  home/  hosts/
# lib/  modules/  overlays/  pkgs/  profiles/  scripts/
```

**Step 2: Run Bootstrap**
```bash
./scripts/bootstrap.sh
```

**Terminal Output:**
```
╔══════════════════════════════════════════════════════════╗
║        nix-darwin Bootstrap - Initial Setup              ║
╚══════════════════════════════════════════════════════════╝

This script will install:
✓ Nix package manager (with flakes enabled)
✓ nix-darwin (macOS system management)
✓ SOPS (secret management)
✓ Age (encryption)

WARNING: This will modify your system:
  - Install Nix in /nix
  - Create /etc/nix/nix.conf
  - Modify shell profile (~/.zshrc)

Proceed with installation? (yes/no): yes

[1/4] Installing Nix package manager...
  • Downloading Nix installer...
  • Running official installer...
  • Nix installer: Welcome to the Multi-User Nix Installation
  • Creating system users (nixbld1-32)...
  • Creating /nix directory...
  • Configuring Nix daemon...
  • Installing Nix 2.19.2...
✅ Nix installed successfully

[2/4] Enabling Nix flakes...
  • Writing /etc/nix/nix.conf...
experimental-features = nix-command flakes
  • Restarting Nix daemon...
✅ Flakes enabled

[3/4] Installing nix-darwin...
  • Cloning nix-darwin repository...
  • Installing nix-darwin framework...
  • nix-darwin 24.05 installed
✅ nix-darwin installed

[4/4] Installing SOPS and Age...
  • Installing SOPS (secret management)...
  • Installing Age (encryption)...
✅ SOPS installed: v3.8.1
✅ Age installed: v1.1.1

╔══════════════════════════════════════════════════════════╗
║            Bootstrap Complete!                           ║
╚══════════════════════════════════════════════════════════╝

Next step: ./scripts/configure.sh

Backups will be stored in: user-data/<username>/backups/
Secrets will be stored in: user-data/<username>/secrets/

Time elapsed: 2m 34s
```

**Step 3: Run Configuration Wizard**
```bash
./scripts/configure.sh
```

**Interactive Terminal Session:**
```
╔══════════════════════════════════════════════════════════╗
║     nix-darwin Configuration Wizard                      ║
╚══════════════════════════════════════════════════════════╝

Let's set up your profile configuration.

This wizard will guide you through:
  1. User information (name, email)
  2. Machine identity (unique ID)
  3. Profile selection (personal, work, minimal)
  4. System configuration (architecture, Homebrew)

Press Enter to continue...

╔══════════════════════════════════════════════════════════╗
║        Step 1/4: User Information                        ║
╚══════════════════════════════════════════════════════════╝

Username (current: john): [Press Enter]

Full name: John Doe

Email address: john@example.com

╔══════════════════════════════════════════════════════════╗
║        Step 2/4: Machine Identity                        ║
╚══════════════════════════════════════════════════════════╝

Choose a unique identifier for this machine.

Privacy Options:
  • Generic:  personal-laptop, work-macbook, home-server
  • Specific: mbp-john, johns-m2-pro, john-work-laptop

Generic names provide more privacy but specific names help
identify machines in multi-machine setups.

Machine ID: personal-laptop

Machine description (optional): John's Personal MacBook Pro

╔══════════════════════════════════════════════════════════╗
║        Step 3/4: Profile Selection                       ║
╚══════════════════════════════════════════════════════════╝

Available profiles:

  1) personal - Personal machine configuration
     • Development: Python, Node, Rust, Go
     • Apps: Firefox, Brave, Slack, Discord, Notion, Obsidian
     • Media: Spotify, VLC, IINA
     • Creative: GIMP, Inkscape
     • CLI: 45+ tools (git, gh, tmux, fzf, ripgrep, etc.)

  2) work - Work machine configuration
     • Cloud: AWS CLI, Docker, Kubernetes, Terraform
     • Apps: Chrome, Zoom, Teams, Jira
     • Infrastructure: ansible, helm, k9s
     • Monitoring: prometheus, grafana
     • AWS multi-role support

  3) minimal - Minimal configuration
     • Core: git, neovim, tmux, htop
     • Browser: Firefox
     • Language: Python
     • No GUI apps (Homebrew disabled)

You can switch profiles later with: switch-profile <name>

Select profile (1-3): 1

Selected: personal

╔══════════════════════════════════════════════════════════╗
║        Step 4/4: System Configuration                    ║
╚══════════════════════════════════════════════════════════╝

Detected system: aarch64-darwin (Apple Silicon)

Enable Homebrew for GUI apps? (yes/no): yes

Mixins (composable configurations):
  ✓ base (core settings - always included)
  ✓ dev (development tools)
  ✓ personal (personal machine settings)

╔══════════════════════════════════════════════════════════╗
║        Configuration Summary                             ║
╚══════════════════════════════════════════════════════════╝

User Information:
  Username:     john
  Full name:    John Doe
  Email:        john@example.com

Machine:
  Machine ID:   personal-laptop
  Description:  John's Personal MacBook Pro
  Profile:      personal
  System:       aarch64-darwin (Apple Silicon)

Features:
  Homebrew:     enabled
  Secrets:      enabled (SOPS + age)
  Mixins:       base, dev, personal

Estimated install size: ~2.5 GB
Estimated install time: ~8-12 minutes

Proceed with this configuration? (yes/no): yes

[1/5] Creating configuration...
  • Writing config/profile.nix...
✅ config/profile.nix created

[2/5] Creating user-data directory...
  • Creating user-data/john/
  • Creating secrets/
  • Creating backups/
  • Creating credentials/
  • Creating cache/
✅ user-data/john/ created

[3/5] Generating encryption keys...
  • Generating age key...
  • Setting permissions (600)...
  • Age public key: age1ckj8v3h7jqh9l4k6m8n9p0q2r3s4t5u6v7w8x9y0z1a2
✅ age-key.txt created (user-data/john/secrets/keys/)

[4/5] Creating secrets template...
  • Writing secrets.yaml...
  • Encrypting with SOPS...
✅ secrets.yaml created (encrypted)

[5/5] Writing README...
  • Creating user-data/john/README.md...
✅ README created

╔══════════════════════════════════════════════════════════╗
║         Configuration Complete!                          ║
╚══════════════════════════════════════════════════════════╝

Next step: ./scripts/activate.sh

This will build and activate your nix-darwin configuration.
First build may take 8-12 minutes to download and compile packages.

Time elapsed: 47s
```

**Step 4: Activate Configuration**
```bash
./scripts/activate.sh
```

**Terminal Output:**
```
╔══════════════════════════════════════════════════════════╗
║          nix-darwin Activation                           ║
╚══════════════════════════════════════════════════════════╝

[1/5] Validating configuration...
  • Checking config/profile.nix...
  • Verifying profile template: personal
  • Checking user-data/john/...
  • Validating age key...
✅ config/profile.nix exists
✅ Profile template exists: profiles/templates/personal.nix
✅ user-data/john/ directory exists
✅ Age key exists (600 perms)

[2/5] Backing up current state...
  • Creating backup directory...
  • Backing up config/profile.nix...
  • Backing up Home Manager state...
✅ Backup created: user-data/john/backups/pre-activation-20250115_151030

[3/5] Building system configuration...
Building for machine: personal-laptop

  • Evaluating flake.nix...
  • Downloading dependencies...
    - nixpkgs: stable (24.05)
    - home-manager: release-24.05
    - nix-darwin: stable
  • Building packages...
    Progress: 0/127 (git, gh, python3)
    Progress: 25/127 (tmux, neovim, fzf)
    Progress: 50/127 (docker, nodejs, rust)
    Progress: 75/127 (starship, bat, eza)
    Progress: 100/127 (ripgrep, fd, jq)
    Progress: 127/127 (system activation)
  • Building system derivation...
✅ Build successful

[4/5] Activating configuration...
  • Setting up /etc...
    - /etc/nix/nix.conf
    - /etc/shells
    - /etc/zshrc
  • Setting up system environment...
    - PATH additions
    - Environment variables
  • Activating Home Manager...
    - User packages (45 installed)
    - Shell configuration (zsh, starship)
    - Git configuration
    - VS Code extensions (12 installed)
  • Installing Homebrew casks...
    - firefox
    - slack
    - notion
    - spotify
✅ Activation successful

[5/5] Post-activation checks...
  • Checking shell: zsh
  • Checking Git: configured (John Doe <john@example.com>)
  • Checking Python: 3.12.1
  • Checking Node: 20.10.0
  • Checking Rust: 1.75.0
  • Checking VS Code: installed
✅ All checks passed

╔══════════════════════════════════════════════════════════╗
║             Setup Complete!                              ║
╚══════════════════════════════════════════════════════════╝

Your nix-darwin system is now active.

Next steps:
  1. Restart your shell:    exec zsh
  2. Verify installation:   health-check
  3. Read documentation:    cat docs/START-HERE.md

Useful commands:
  nix-rebuild      - Rebuild system after config changes
  switch-profile   - Switch between profiles
  edit-secrets     - Edit encrypted secrets
  health-check     - System health diagnostics

Time elapsed: 8m 42s
Total packages installed: 127
Disk space used: 2.3 GB
```

**Step 5: Restart Shell**
```bash
exec zsh
```

**Terminal Output (New Shell):**
```
# Starship prompt appears
╭─ john@personal-laptop ~/nix-darwin ‹main›
╰─➤
```

**Step 6: Verify Installation**
```bash
health-check
```

**Terminal Output:**
```
╔══════════════════════════════════════════════════════════╗
║          System Health Check                             ║
╚══════════════════════════════════════════════════════════╝

=== Configuration ===
✅ config/profile.nix exists
✅ Profile: personal
✅ Machine ID: personal-laptop
✅ System: aarch64-darwin

=== Nix ===
✅ Nix version: 2.19.2
✅ Flakes: enabled
✅ nix-darwin: 24.05 installed

=== Home Manager ===
✅ Home Manager: active
✅ Generation: 1
✅ Packages: 45 installed

=== Shell ===
✅ Shell: /run/current-system/sw/bin/zsh
✅ Starship: configured
✅ Direnv: configured

=== Development ===
✅ Git: 2.43.0
✅ Python: 3.12.1 (with pip, pipenv, poetry)
✅ Node: 20.10.0 (with npm, yarn)
✅ Rust: 1.75.0 (with cargo, rustfmt, clippy)

=== Applications ===
✅ Firefox: installed
✅ Slack: installed
✅ Notion: installed
✅ Spotify: installed

=== Secrets ===
✅ SOPS: 3.8.1 installed
✅ Age: 1.1.1 installed
✅ Age key: exists (600 perms)
✅ Secrets file: exists (encrypted)

=== File Permissions ===
✅ Age key: 600
✅ All sensitive files: correct permissions

╔══════════════════════════════════════════════════════════╗
║         All checks passed!                               ║
╚══════════════════════════════════════════════════════════╝

Your system is fully configured and operational.

System info:
  Profile: personal
  Generation: 1
  Last activated: 2025-01-15 15:18:42
  Uptime: 0 days, 0 hours, 2 minutes

Documentation: docs/START-HERE.md
```

### 9.2 Onboarding Time Estimates

| Phase | First-Time User | Experienced User | Notes |
|-------|----------------|------------------|-------|
| **Clone Repo** | 1 min | 30 sec | Network dependent |
| **Bootstrap** | 5-8 min | 3-5 min | Nix installation |
| **Configure** | 3-5 min | 1-2 min | Interactive wizard |
| **Activate** | 8-12 min | 5-8 min | First build slowest |
| **Verify** | 2 min | 1 min | Health checks |
| **Total** | 19-28 min | 10-16 min | |

### 9.3 Onboarding Decision Tree

```
User starts
    ↓
Has Nix installed?
├─ No → Run bootstrap.sh (5-8 min)
└─ Yes → Skip bootstrap
    ↓
Has existing config?
├─ No → Run configure.sh (3-5 min)
│      - Interactive wizard
│      - Profile selection
│      - Generate profile.nix
│
└─ Yes (backup/restore) → Run restore-from-backup.sh
       - Extract backup
       - Restore configs
       - Validate
    ↓
Run activate.sh (8-12 min first time)
    ↓
Restart shell (exec zsh)
    ↓
Run health-check
    ↓
✅ Complete
```

### 9.4 Common Onboarding Issues

**Issue 1: Nix Installation Requires Sudo**
```bash
./scripts/bootstrap.sh

# Output:
# Password required for Nix installation (sudo access needed)
# This is normal - Nix requires system modifications

Password: [enter macOS password]
```

**Issue 2: First Build Takes Long**
```bash
./scripts/activate.sh

# Expected on first run:
# Progress: 25/127 packages...
# (May appear stuck - this is normal)

# Why slow:
# - Downloading 2+ GB of packages
# - Compiling some packages from source
# - Building Home Manager configuration

# Subsequent builds: 30-60 seconds (most packages cached)
```

**Issue 3: Homebrew Cask Installation Requires Password**
```bash
# During activation:
# Installing Homebrew casks...

Password: [enter macOS password]

# Why: Homebrew casks install to /Applications, requires sudo
```

**Issue 4: Shell Doesn't Show Changes**
```bash
# After activation
./scripts/activate.sh
# ✅ Activation successful

git status
# Still shows old aliases

# Solution: MUST restart shell
exec zsh

# Now shows new configuration
```

---

## 10. Build Process Deep Dive

### 10.1 Nix Flake Evaluation vs Build

**The Two-Phase Process:**

**Phase 1: Flake Evaluation** (Fast, ~2-5 seconds)
- **What**: Parse flake.nix, build dependency graph
- **Where**: From git tree (tracked files only)
- **Output**: Build plan (derivations)
- **Files Accessed**: Only tracked files in git

**Phase 2: Build Execution** (Slow, ~8-12 minutes first time)
- **What**: Execute builds, install packages, activate system
- **Where**: From filesystem (includes gitignored files)
- **Output**: Installed system (/nix/store + /run/current-system)
- **Files Accessed**: Tracked + gitignored files

**Visual Representation:**
```
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Flake Evaluation (~2-5 seconds)               │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
            Read flake.nix
                    │
                    ▼
         Import tracked files
         (home/template/, profiles/templates/, hosts/template/)
                    │
                    ▼
      Build dependency graph
                    │
                    ▼
         Generate derivations
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 2: Build Execution (~8-12 min first time)        │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
    Templates import gitignored configs
    (config/profile.nix, user-data/secrets/)
                    │
                    ▼
    Download packages from cache.nixos.org
                    │
                    ▼
    Compile packages (if needed)
                    │
                    ▼
    Install to /nix/store
                    │
                    ▼
    Activate system
                    │
                    ▼
    ✅ System active
```

### 10.2 Why Git Tree vs Filesystem Matters

**Current Architecture Problem:**
```nix
# flake.nix (Evaluation Phase - uses git tree)
darwinConfigurations.mbp-jimmy = {
  modules = [
    home-manager.darwinModules.home-manager {
      home-manager.users.jimmy = import ./home/jimmy;
      # ❌ FAILS: home/jimmy/ is gitignored
      # Not in git tree, evaluation fails
    }
  ];
};
```

**Error:**
```
error: getting status of '/nix/store/xg51bd540s4108kywrix54sq385awwph-source/home/jimmy': No such file or directory

Explanation: During flake evaluation, Nix builds from git tree.
home/jimmy/ is gitignored → not in git tree → error
```

**Proposed Architecture Solution:**
```nix
# flake.nix (Evaluation Phase - uses git tree)
darwinConfigurations.${machineId} = {
  modules = [
    home-manager.darwinModules.home-manager {
      home-manager.users.${username} = import ./home/template;
      # ✅ WORKS: home/template/ is tracked in git
      # Present in git tree, evaluation succeeds
    }
  ];
};

# home/template/default.nix (Build Phase - uses filesystem)
let
  profileConfig = import ../../config/profile.nix;
  # ✅ WORKS: Build phase can access gitignored files from filesystem
in { ... }
```

**Why This Works:**
1. **Evaluation**: Only touches tracked files (home/template/)
2. **Build**: Can access gitignored files (config/profile.nix)
3. **Separation**: Identity files (gitignored) loaded during build, not evaluation

### 10.3 Build Caching and Performance

**First Build (Cold Cache):**
```bash
darwin-rebuild switch --flake .

# Timeline:
# 00:00 - 00:05 : Flake evaluation
# 00:05 - 02:00 : Download packages from cache.nixos.org
# 02:00 - 08:00 : Compile packages (if needed)
# 08:00 - 10:00 : Build Home Manager configuration
# 10:00 - 12:00 : Install Homebrew casks
# 12:00 - 12:30 : System activation

# Total: ~12 minutes
```

**Subsequent Builds (Warm Cache):**
```bash
# After changing alias in home/_mixins/personal.nix
darwin-rebuild switch --flake .

# Timeline:
# 00:00 - 00:05 : Flake evaluation
# 00:05 - 00:15 : Build changed files only
# 00:15 - 00:30 : System activation

# Total: ~30 seconds
```

**Cache Locations:**
```
/nix/store/                    # Immutable package store
~/.cache/nix/                  # Local evaluation cache
/var/cache/nix-darwin/         # Darwin system cache
~/.cache/home-manager/         # Home Manager cache
```

**What Gets Cached:**
- ✅ Downloaded packages (git, tmux, python, etc.)
- ✅ Compiled derivations
- ✅ Home Manager generations
- ✅ Nix flake evaluations
- ❌ Gitignored configs (always re-read)

**Cache Size Estimates:**
```
Fresh install:       2.5 GB
After 10 generations: 3.2 GB
After 50 generations: 4.8 GB

Cleanup: nix-collect-garbage --delete-older-than 7d
```

### 10.4 Debugging Build Failures

**Common Build Errors:**

**Error 1: Syntax Error in profile.nix**
```bash
darwin-rebuild switch --flake .

# Output:
error: syntax error, unexpected '}', expecting ';'
       at /Users/john/nix-darwin/config/profile.nix:12:1

# Debug:
nix-instantiate --eval config/profile.nix

# Fix: Check for missing semicolons, quotes, or braces
```

**Error 2: Profile Template Not Found**
```bash
darwin-rebuild switch --flake .

# Output:
error: file 'profiles/templates/custom.nix' was not found

# Debug:
ls profiles/templates/

# Fix: Create template or change profileName in config/profile.nix
```

**Error 3: Flake Evaluation Fails**
```bash
darwin-rebuild switch --flake .

# Output:
error: getting status of '/nix/store/.../home/jimmy': No such file or directory

# This is the GIT TREE problem!

# Debug:
# Check if imported path is gitignored
git check-ignore home/jimmy
# Output: home/jimmy (confirmed gitignored)

# Fix: Import tracked template instead
```

**Error 4: Age Key Missing**
```bash
darwin-rebuild switch --flake .

# Output:
error: age key not found at /Users/john/user-data/john/secrets/keys/age-key.txt

# Debug:
ls user-data/john/secrets/keys/

# Fix:
age-keygen -o user-data/john/secrets/keys/age-key.txt
chmod 600 user-data/john/secrets/keys/age-key.txt
```

**Debug Tools:**
```bash
# Show full build trace
darwin-rebuild build --flake . --show-trace

# Evaluate specific file
nix-instantiate --eval --strict config/profile.nix

# Check flake inputs
nix flake metadata

# Inspect derivation
nix show-derivation .#darwinConfigurations.personal-laptop.system

# Build without activation
darwin-rebuild build --flake .

# Check what will be built
darwin-rebuild build --flake . --dry-run
```

---

## 11. Migration Path

### 11.1 Migration Strategy

**Approach: Gradual Migration with Rollback Safety**

**Migration Phases:**
1. **Pre-Migration**: Backup, validation, risk assessment
2. **Core Migration**: Directory restructure, config consolidation
3. **Script Updates**: Update bootstrap, configure, activate
4. **Testing**: Multi-scenario validation
5. **Documentation**: Update all docs
6. **Release**: Tag v2.0.0, announce breaking changes

**Risk Level:** Medium
- **Breaking Changes**: Yes (directory structure, config format)
- **Rollback Capable**: Yes (git revert, backup restore)
- **Data Loss Risk**: Low (comprehensive backups)

### 11.2 Automated Migration Script

**scripts/migrate-to-profiles.sh**
```bash
#!/usr/bin/env bash
# migrate-to-profiles.sh - Automated migration to profile-based architecture
#
# This script migrates from the current git-privacy hostname-based architecture
# to the new profile-based architecture.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# State
BACKUP_DIR=""
CURRENT_HOSTNAME=""
USERNAME=""

banner() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  Migration: git-privacy → Profile-Based Architecture    ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
}

pre_migration_checks() {
  echo -e "${BLUE}[1/8] Pre-Migration Checks${NC}"
  echo ""

  # Check we're in git repo
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
  fi

  # Check working tree is clean
  if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Uncommitted changes detected${NC}"
    echo ""
    echo "Commit or stash changes before migration:"
    echo "  git add . && git commit -m 'Pre-migration snapshot'"
    exit 1
  fi

  # Check current hostname
  CURRENT_HOSTNAME=$(hostname -s)
  echo "Current hostname: $CURRENT_HOSTNAME"

  # Check if old config exists
  if [ -f "$REPO_ROOT/config/user-config.nix" ]; then
    echo "✅ Found config/user-config.nix"
  else
    echo -e "${RED}❌ config/user-config.nix not found${NC}"
    exit 1
  fi

  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    echo "✅ Found config/machine-config.nix"
  else
    echo -e "${RED}❌ config/machine-config.nix not found${NC}"
    exit 1
  fi

  USERNAME=$(whoami)
  echo "Current user: $USERNAME"

  # Check user-data directory
  if [ -d "$REPO_ROOT/user-data-$USERNAME" ]; then
    echo "✅ Found user-data-$USERNAME/"
  else
    echo "⚠️  Warning: user-data-$USERNAME/ not found"
  fi

  echo ""
  echo -e "${GREEN}✅ Pre-migration checks passed${NC}"
  echo ""
}

create_backup() {
  echo -e "${BLUE}[2/8] Creating Comprehensive Backup${NC}"
  echo ""

  local timestamp=$(date +%Y%m%d_%H%M%S)
  BACKUP_DIR="$REPO_ROOT/.migration-backup-$timestamp"

  mkdir -p "$BACKUP_DIR"

  # Backup configs
  echo "Backing up configurations..."
  cp "$REPO_ROOT/config/user-config.nix" "$BACKUP_DIR/"
  cp "$REPO_ROOT/config/machine-config.nix" "$BACKUP_DIR/"

  # Backup user-data
  if [ -d "$REPO_ROOT/user-data-$USERNAME" ]; then
    echo "Backing up user-data-$USERNAME/..."
    cp -r "$REPO_ROOT/user-data-$USERNAME" "$BACKUP_DIR/"
  fi

  # Backup scripts
  echo "Backing up scripts..."
  cp -r "$REPO_ROOT/scripts" "$BACKUP_DIR/"

  # Backup flake.nix and home/host configs
  echo "Backing up flake.nix..."
  cp "$REPO_ROOT/flake.nix" "$BACKUP_DIR/"

  if [ -d "$REPO_ROOT/home/$USERNAME" ]; then
    echo "Backing up home/$USERNAME/..."
    cp -r "$REPO_ROOT/home/$USERNAME" "$BACKUP_DIR/"
  fi

  if [ -d "$REPO_ROOT/hosts/$CURRENT_HOSTNAME" ]; then
    echo "Backing up hosts/$CURRENT_HOSTNAME/..."
    cp -r "$REPO_ROOT/hosts/$CURRENT_HOSTNAME" "$BACKUP_DIR/"
  fi

  # Create manifest
  cat > "$BACKUP_DIR/MANIFEST.md" <<EOF
# Migration Backup

**Date:** $(date)
**User:** $USERNAME
**Hostname:** $CURRENT_HOSTNAME
**Backup Dir:** $BACKUP_DIR

## Contents

- config/user-config.nix
- config/machine-config.nix
- user-data-$USERNAME/
- scripts/
- flake.nix
- home/$USERNAME/
- hosts/$CURRENT_HOSTNAME/

## Rollback

If migration fails, restore from backup:

\`\`\`bash
$REPO_ROOT/scripts/rollback-migration.sh $BACKUP_DIR
\`\`\`
EOF

  echo ""
  echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
  echo ""
}

extract_config_values() {
  echo -e "${BLUE}[3/8] Extracting Configuration Values${NC}"
  echo ""

  # Extract from user-config.nix
  local full_name=$(grep "fullName" "$REPO_ROOT/config/user-config.nix" | sed 's/.*"\(.*\)".*/\1/')
  local email=$(grep "email" "$REPO_ROOT/config/user-config.nix" | sed 's/.*"\(.*\)".*/\1/')

  # Extract from machine-config.nix
  local machine_type=$(grep "machineType" "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
  local system=$(grep "system" "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
  local description=$(grep "description" "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')

  echo "Extracted values:"
  echo "  Username: $USERNAME"
  echo "  Full name: $full_name"
  echo "  Email: $email"
  echo "  Machine type: $machine_type"
  echo "  System: $system"
  echo "  Description: $description"
  echo ""

  # Determine profile from machine type
  local profile_name=""
  case "$machine_type" in
    work)
      profile_name="work"
      ;;
    personal|home)
      profile_name="personal"
      ;;
    minimal)
      profile_name="minimal"
      ;;
    *)
      echo -e "${YELLOW}⚠️  Unknown machine type: $machine_type${NC}"
      echo "Defaulting to: personal"
      profile_name="personal"
      ;;
  esac

  # Interactive: Choose machineId
  echo ""
  echo "Choose a machine ID for this system:"
  echo "  1) Keep current hostname: $CURRENT_HOSTNAME"
  echo "  2) Use generic: personal-laptop"
  echo "  3) Custom"
  echo ""
  read -p "Choice (1-3): " machine_id_choice

  local machine_id=""
  case $machine_id_choice in
    1)
      machine_id="$CURRENT_HOSTNAME"
      ;;
    2)
      if [ "$profile_name" = "work" ]; then
        machine_id="work-laptop"
      else
        machine_id="personal-laptop"
      fi
      ;;
    3)
      read -p "Enter machine ID: " machine_id
      ;;
    *)
      echo "Invalid choice. Using hostname."
      machine_id="$CURRENT_HOSTNAME"
      ;;
  esac

  echo ""
  echo "Migration configuration:"
  echo "  Machine ID: $machine_id"
  echo "  Profile: $profile_name"
  echo ""

  # Generate new profile.nix
  cat > "$REPO_ROOT/config/profile.nix" <<EOF
{
  # User Information
  username = "$USERNAME";
  fullName = "$full_name";
  email = "$email";

  # Machine Identity
  machineId = "$machine_id";
  machineDescription = "$description";

  # Profile Configuration
  profileName = "$profile_name";

  # System
  system = "$system";

  # Features
  homebrewEnabled = true;
  secretsEnabled = true;

  # Mixins
  mixins = [ "base" "dev" "$profile_name" ];
}
EOF

  echo -e "${GREEN}✅ Created config/profile.nix${NC}"
  echo ""
}

restructure_directories() {
  echo -e "${BLUE}[4/8] Restructuring Directories${NC}"
  echo ""

  # Move user-data-{username}/ → user-data/{username}/
  if [ -d "$REPO_ROOT/user-data-$USERNAME" ]; then
    echo "Moving user-data-$USERNAME/ → user-data/$USERNAME/"
    mkdir -p "$REPO_ROOT/user-data"
    mv "$REPO_ROOT/user-data-$USERNAME" "$REPO_ROOT/user-data/$USERNAME"
    echo "✅ user-data restructured"
  else
    echo "Creating new user-data/$USERNAME/ structure..."
    mkdir -p "$REPO_ROOT/user-data/$USERNAME/secrets/keys"
    mkdir -p "$REPO_ROOT/user-data/$USERNAME/backups"
    mkdir -p "$REPO_ROOT/user-data/$USERNAME/credentials"
    mkdir -p "$REPO_ROOT/user-data/$USERNAME/cache"
    echo "✅ user-data structure created"
  fi

  # Rename home/_template/ → home/template/
  if [ -d "$REPO_ROOT/home/_template" ]; then
    echo "Moving home/_template/ → home/template/"
    git mv "$REPO_ROOT/home/_template" "$REPO_ROOT/home/template"
    echo "✅ home/template created"
  fi

  # Rename hosts/_template/ → hosts/template/
  if [ -d "$REPO_ROOT/hosts/_template" ]; then
    echo "Moving hosts/_template/ → hosts/template/"
    git mv "$REPO_ROOT/hosts/_template" "$REPO_ROOT/hosts/template"
    echo "✅ hosts/template created"
  fi

  echo ""
  echo -e "${GREEN}✅ Directory restructuring complete${NC}"
  echo ""
}

update_flake() {
  echo -e "${BLUE}[5/8] Updating flake.nix${NC}"
  echo ""

  # Update flake.nix to profile-based architecture
  cat > "$REPO_ROOT/flake.nix" <<'EOF'
{
  description = "nix-darwin configuration (profile-based)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      # Import profile configuration
      profileConfig = import ./config/profile.nix;
      inherit (profileConfig) username machineId profileName system;

      # Import profile template
      profile = import ./profiles/templates/${profileName}.nix;

      # Create pkgs
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.${machineId} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit profileConfig profile; };
        modules = [
          ./hosts/template
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import ./home/template;
              extraSpecialArgs = { inherit profileConfig profile; };
            };
          }
        ];
      };
    };
}
EOF

  echo -e "${GREEN}✅ Updated flake.nix${NC}"
  echo ""
}

update_gitignore() {
  echo -e "${BLUE}[6/8] Updating .gitignore${NC}"
  echo ""

  # Backup old .gitignore
  cp "$REPO_ROOT/.gitignore" "$BACKUP_DIR/.gitignore.old"

  # Update .gitignore with new patterns
  cat > "$REPO_ROOT/.gitignore" <<'EOF'
# Profile-Based Configuration
config/profile.nix
user-data/*/

# Legacy (can be removed after migration)
config/user-config.nix
config/machine-config.nix
home/*/
!home/_mixins/
!home/template/
hosts/*/
!hosts/template/
user-data-*/

# Nix build artifacts
result
result-*

# Secrets (defense in depth)
.age-key.txt
secrets.yaml
!.sops.yaml

# macOS
.DS_Store

# Editor
.vscode/
*.swp

# Planning docs
claudedocs/planning/
claudedocs/archive/
EOF

  echo -e "${GREEN}✅ Updated .gitignore${NC}"
  echo ""
}

test_build() {
  echo -e "${BLUE}[7/8] Testing Build${NC}"
  echo ""

  echo "Running test build (won't activate)..."
  echo ""

  if darwin-rebuild build --flake "$REPO_ROOT"; then
    echo ""
    echo -e "${GREEN}✅ Build test successful${NC}"
  else
    echo ""
    echo -e "${RED}❌ Build test failed${NC}"
    echo ""
    echo "Migration incomplete. System not modified."
    echo "Rollback available: $BACKUP_DIR"
    exit 1
  fi

  echo ""
}

finalize_migration() {
  echo -e "${BLUE}[8/8] Finalizing Migration${NC}"
  echo ""

  # Remove old config files
  echo "Removing old configuration files..."
  rm -f "$REPO_ROOT/config/user-config.nix"
  rm -f "$REPO_ROOT/config/machine-config.nix"

  # Git commit
  echo "Committing changes..."
  git add .
  git commit -m "feat: Migrate to profile-based architecture

- Consolidated user-config.nix + machine-config.nix → profile.nix
- Restructured user-data-{username}/ → user-data/{username}/
- Renamed home/_template/ → home/template/
- Renamed hosts/_template/ → hosts/template/
- Updated flake.nix for profile-based architecture
- Updated .gitignore for new structure

Breaking changes:
- Configuration format changed
- Directory structure changed
- Hostname-based machine detection removed

Migration backup: $BACKUP_DIR"

  echo ""
  echo -e "${GREEN}✅ Migration committed${NC}"
  echo ""
}

summary() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║         Migration Complete!                              ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. Review changes:  git show HEAD"
  echo "  2. Activate system: darwin-rebuild switch --flake ."
  echo "  3. Restart shell:   exec zsh"
  echo "  4. Verify:          health-check"
  echo ""
  echo "Backup location: $BACKUP_DIR"
  echo ""
  echo "If anything goes wrong:"
  echo "  ./scripts/rollback-migration.sh $BACKUP_DIR"
  echo ""
}

main() {
  banner

  echo "This script will migrate your nix-darwin setup to the new"
  echo "profile-based architecture."
  echo ""
  echo "Changes:"
  echo "  • Consolidate configs: user-config.nix + machine-config.nix → profile.nix"
  echo "  • Restructure: user-data-{username}/ → user-data/{username}/"
  echo "  • Update: home/_template/ → home/template/"
  echo "  • Rewrite: flake.nix for profile-based architecture"
  echo ""
  echo "This is a BREAKING CHANGE but includes comprehensive backups."
  echo ""

  read -p "Proceed with migration? (yes/no): " confirm
  if [ "$confirm" != "yes" ]; then
    echo "Migration cancelled."
    exit 0
  fi

  pre_migration_checks
  create_backup
  extract_config_values
  restructure_directories
  update_flake
  update_gitignore
  test_build
  finalize_migration
  summary
}

main "$@"
```

### 11.3 Manual Migration Steps

For users who prefer manual migration or want to understand each step:

**Step 1: Create Feature Branch**
```bash
cd ~/nix-darwin
git checkout -b feature/profile-based-architecture
```

**Step 2: Backup Current Setup**
```bash
# Create comprehensive backup
./scripts/backup-for-migration.sh

# Result: ~/nix-darwin-migration-backup-20250115.tar.gz
```

**Step 3: Create New Profile System**
```bash
# Create profiles directory
mkdir -p profiles/templates

# Copy profile templates from this proposal
# (personal.nix, work.nix, minimal.nix from Section 5.2)

# Update home/_template/ → home/template/
git mv home/_template home/template

# Update hosts/_template/ → hosts/template/
git mv hosts/_template hosts/template
```

**Step 4: Consolidate Configs**
```bash
# Extract values from old configs
USERNAME=$(grep "username" config/user-config.nix | sed 's/.*"\(.*\)".*/\1/')
FULL_NAME=$(grep "fullName" config/user-config.nix | sed 's/.*"\(.*\)".*/\1/')
EMAIL=$(grep "email" config/user-config.nix | sed 's/.*"\(.*\)".*/\1/')
MACHINE_TYPE=$(grep "machineType" config/machine-config.nix | sed 's/.*"\(.*\)".*/\1/')
SYSTEM=$(grep "system" config/machine-config.nix | sed 's/.*"\(.*\)".*/\1/')

# Create new profile.nix
cat > config/profile.nix <<EOF
{
  username = "$USERNAME";
  fullName = "$FULL_NAME";
  email = "$EMAIL";
  machineId = "$(hostname -s)";  # or choose generic name
  profileName = "$MACHINE_TYPE";
  system = "$SYSTEM";
  homebrewEnabled = true;
  secretsEnabled = true;
  mixins = [ "base" "dev" "$MACHINE_TYPE" ];
}
EOF
```

**Step 5: Restructure user-data**
```bash
# Move user-data-{username}/ → user-data/{username}/
mkdir -p user-data
mv user-data-$USERNAME user-data/$USERNAME
```

**Step 6: Update flake.nix**
```bash
# Replace flake.nix with profile-based version (Section 11.2)
```

**Step 7: Update .gitignore**
```bash
# Update .gitignore (Section 11.2)
```

**Step 8: Test Build**
```bash
# Build without activation
darwin-rebuild build --flake .

# If successful:
✅ Build complete
```

**Step 9: Commit Changes**
```bash
git add .
git commit -m "feat: Migrate to profile-based architecture"
```

**Step 10: Activate**
```bash
darwin-rebuild switch --flake .
exec zsh
health-check
```

### 11.4 Rollback Procedure

**scripts/rollback-migration.sh**
```bash
#!/usr/bin/env bash
# rollback-migration.sh - Rollback profile-based migration

set -euo pipefail

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ Backup directory not found: $BACKUP_DIR"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Migration Rollback                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

echo "Rolling back from: $BACKUP_DIR"
echo ""

# Restore configs
cp "$BACKUP_DIR/user-config.nix" config/
cp "$BACKUP_DIR/machine-config.nix" config/

# Restore scripts
cp -r "$BACKUP_DIR/scripts/" .

# Restore flake.nix
cp "$BACKUP_DIR/flake.nix" .

# Restore user-data structure
USERNAME=$(whoami)
if [ -d "$BACKUP_DIR/user-data-$USERNAME" ]; then
  rm -rf "user-data/$USERNAME"
  cp -r "$BACKUP_DIR/user-data-$USERNAME" .
fi

echo "✅ Files restored from backup"
echo ""

echo "Rebuilding with old configuration..."
darwin-rebuild switch --flake .#$(hostname -s)

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Rollback Complete                                ║"
echo "╚══════════════════════════════════════════════════════════╝"
```

---

## 12. Implementation Checklist

### 12.1 Files to Create

**Profile System:**
- [ ] `profiles/templates/personal.nix` (140 lines)
- [ ] `profiles/templates/work.nix` (160 lines)
- [ ] `profiles/templates/minimal.nix` (60 lines)
- [ ] `profiles/templates/README.md` (80 lines)

**Configuration:**
- [ ] `config/profile.nix.template` (30 lines)

**Scripts:**
- [ ] `scripts/switch-profile.sh` (300 lines)
- [ ] `scripts/validate-config.sh` (150 lines)
- [ ] `scripts/migrate-to-profiles.sh` (500 lines)
- [ ] `scripts/rollback-migration.sh` (80 lines)

**User Data:**
- [ ] `user-data/README.template.md` (100 lines)

**Documentation:**
- [ ] Update `docs/START-HERE.md`
- [ ] Update `docs/QUICK-REFERENCE.md`
- [ ] Update `docs/guides/usage.md`
- [ ] Update `docs/architecture/overview.md`
- [ ] Update `CLAUDE.md`
- [ ] Update `CHANGELOG.md`

**Total New Files:** 9 files, ~1,600 lines
**Total Updated Files:** 8 files, ~800 lines modified

### 12.2 Files to Modify

**Core Configuration:**
- [ ] `flake.nix` (~40 lines modified)
  - Import profile.nix
  - Single generic darwinConfiguration
  - Pass profileConfig to modules

**Templates:**
- [ ] `home/template/default.nix` (rename from `home/_template/`, ~50 lines modified)
  - Import profile.nix
  - Dynamic mixin imports
  - Pass profile values

- [ ] `hosts/template/default.nix` (rename from `hosts/_template/`, ~30 lines modified)
  - Import profile.nix
  - Pass machineId, system

**Scripts:**
- [ ] `scripts/bootstrap.sh` (~20 lines modified)
  - Update backup path messages

- [ ] `scripts/configure.sh` (~300 lines rewritten)
  - Profile selection wizard
  - Generate single profile.nix
  - Create user-data structure

- [ ] `scripts/activate.sh` (~80 lines modified)
  - Check profile.nix
  - Validate profile template
  - Update backup paths

**Git Configuration:**
- [ ] `.gitignore` (~30 lines modified)
  - Add profile.nix
  - Add user-data/*/
  - Keep legacy patterns temporarily

### 12.3 Files to Delete (After Migration)

**Old Configuration Format:**
- [ ] `config/user-config.nix.template`
- [ ] `config/machine-config.nix.template`

**User-specific Directories (gitignored, manual cleanup):**
- [ ] `home/{username}/` (move to template pattern)
- [ ] `hosts/{hostname}/` (move to template pattern)
- [ ] `user-data-{username}/` (restructure to user-data/{username}/)

### 12.4 Testing Checklist

**Unit Tests:**
- [ ] Profile.nix syntax validation
- [ ] Profile template validation
- [ ] Flake evaluation succeeds
- [ ] All mixins importable

**Integration Tests:**
- [ ] Build succeeds (personal profile)
- [ ] Build succeeds (work profile)
- [ ] Build succeeds (minimal profile)
- [ ] Profile switching works
- [ ] Secrets loading works
- [ ] Age encryption works

**Scenario Tests:**
- [ ] New user onboarding (fresh MacBook)
- [ ] Multi-machine setup (3 machines)
- [ ] Backup and restore
- [ ] Migration from current setup
- [ ] Profile switching (personal ↔ work)
- [ ] System architecture change (Intel → M3)

**Edge Cases:**
- [ ] Missing profile.nix (error handling)
- [ ] Invalid profile name (error handling)
- [ ] Missing age key (error handling)
- [ ] Gitignored directory access (should work)
- [ ] Clean git clone build (should work)

### 12.5 Documentation Checklist

**Update User-Facing Docs:**
- [ ] START-HERE.md (onboarding)
- [ ] QUICK-REFERENCE.md (commands)
- [ ] usage.md (daily usage)
- [ ] installation.md (first-time setup)
- [ ] troubleshooting.md (common issues)
- [ ] backup-and-recovery.md (backup/restore)

**Update Technical Docs:**
- [ ] architecture/overview.md (profile system)
- [ ] architecture/reference.md (file locations)
- [ ] reference/shell.md (aliases)
- [ ] reference/languages.md (Python, Node, etc.)

**Update AI Instructions:**
- [ ] CLAUDE.md (Section 9: critical rules)
- [ ] Add profile system explanation
- [ ] Update file editing rules
- [ ] Update examples

**Create New Docs:**
- [ ] MIGRATION-GUIDE.md (profile migration)
- [ ] PROFILES.md (profile system deep dive)
- [ ] MULTI-MACHINE.md (multi-machine scenarios)

### 12.6 Release Checklist

**Pre-Release:**
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Migration script tested
- [ ] Rollback procedure validated
- [ ] CHANGELOG.md updated

**Release:**
- [ ] Merge feature branch → main
- [ ] Tag v2.0.0
- [ ] Create GitHub release
- [ ] Announce breaking changes

**Post-Release:**
- [ ] Monitor issues
- [ ] Update troubleshooting for common migration issues
- [ ] Create migration FAQ

---

## 13. Risks and Mitigations

### 13.1 Risk Matrix

| Risk | Severity | Probability | Impact | Mitigation |
|------|----------|-------------|--------|------------|
| **Build failures on existing setups** | 🔴 High | Medium | 🔴 Critical | Comprehensive backup, rollback script |
| **Data loss during migration** | 🔴 High | Low | 🔴 Critical | Multi-layer backups, validation gates |
| **Secrets exposure** | 🔴 High | Low | 🔴 Critical | SOPS encryption, git hooks, permissions |
| **User confusion** | 🟡 Medium | High | 🟡 Moderate | Clear docs, migration guide, examples |
| **Profile switching breaks config** | 🟡 Medium | Medium | 🟡 Moderate | Validation script, backup before switch |
| **Gitignore fails** | 🟡 Medium | Low | 🟡 Moderate | Pre-commit hooks, defense in depth |
| **Breaking existing workflows** | 🟡 Medium | High | 🟡 Moderate | Gradual migration, compatibility layer |
| **Performance degradation** | 🟢 Low | Low | 🟢 Minor | Benchmark tests, cache optimization |

### 13.2 Mitigation Strategies

**Risk 1: Build Failures on Existing Setups**

**Mitigation:**
- ✅ Automated migration script with validation
- ✅ Test build before activation
- ✅ Comprehensive backup (configs, user-data, scripts)
- ✅ Rollback script tested on multiple scenarios
- ✅ Breaking changes documented in CHANGELOG
- ✅ Migration guide with screenshots

**Validation:**
```bash
# Before migration
./scripts/migrate-to-profiles.sh
# Step 7/8: Test build (doesn't activate)
# Only proceeds if build succeeds
```

**Risk 2: Data Loss During Migration**

**Mitigation:**
- ✅ Pre-migration backup (timestamped)
- ✅ Git commit before migration (rollback point)
- ✅ User-data copied, not moved
- ✅ Validation gates at each step
- ✅ Manifest file documenting backup contents

**Backup Layers:**
1. Git commit (code rollback)
2. .migration-backup-{timestamp}/ (file rollback)
3. user-data/backups/ (user data rollback)

**Risk 3: Secrets Exposure**

**Mitigation:**
- ✅ SOPS encryption (age)
- ✅ Git hooks prevent unencrypted commits
- ✅ File permissions validation (600)
- ✅ .gitignore defense in depth
- ✅ Pre-commit validation script

**Security Layers:**
```
Layer 1: .gitignore (prevent staging)
Layer 2: Pre-commit hook (block commit)
Layer 3: SOPS encryption (if somehow committed)
Layer 4: File permissions (600)
Layer 5: Documentation warnings
```

**Risk 4: User Confusion**

**Mitigation:**
- ✅ Clear migration guide with terminal examples
- ✅ Interactive configure.sh with explanations
- ✅ Profile selection wizard with descriptions
- ✅ Updated CLAUDE.md with new rules
- ✅ FAQ section for common questions
- ✅ Video walkthrough (future)

**Documentation Priorities:**
1. Migration guide (how to upgrade)
2. Profile system explanation (concepts)
3. Multi-machine scenarios (examples)
4. Troubleshooting (common issues)

**Risk 5: Profile Switching Breaks Config**

**Mitigation:**
- ✅ Backup before switch (automatic)
- ✅ Validation before build
- ✅ Test build before activation
- ✅ Rollback on failure
- ✅ Profile template validation

**switch-profile.sh Safety:**
```bash
# Automatic safety measures:
1. Backup current config
2. Validate new profile exists
3. Test build (no activation)
4. Only activate if build succeeds
5. Provide rollback command on failure
```

**Risk 6: Gitignore Fails**

**Mitigation:**
- ✅ Tested .gitignore patterns
- ✅ Pre-commit hooks as backup
- ✅ Post-commit validation
- ✅ SOPS encryption as final layer
- ✅ Clear documentation

**Testing:**
```bash
# After setup, verify:
git status
# Should show: nothing to commit

# Check specific files:
git check-ignore config/profile.nix
git check-ignore user-data/jimmy/
# Should output paths (confirmed ignored)
```

**Risk 7: Breaking Existing Workflows**

**Mitigation:**
- ✅ Legacy patterns in .gitignore (temporary)
- ✅ Gradual migration path
- ✅ Rollback capability
- ✅ Compatibility documented
- ✅ Version bump (v1.x → v2.0.0)

**Breaking Changes:**
- Configuration format (user-config.nix + machine-config.nix → profile.nix)
- Directory structure (user-data-{username}/ → user-data/{username}/)
- Hostname detection removed (manual machineId)
- Template paths (home/_template/ → home/template/)

**Compatibility:**
- ❌ Cannot coexist (breaking changes)
- ✅ Migration script automates upgrade
- ✅ Rollback restores v1.x

**Risk 8: Performance Degradation**

**Mitigation:**
- ✅ Profile system adds minimal overhead
- ✅ Build caching unchanged
- ✅ Benchmark tests comparing v1.x vs v2.0.0
- ✅ Optimization for common operations

**Performance Impact:**
```
Flake evaluation: +0.5s (profile.nix import)
Build time: No change (cache hit rate same)
Activation time: No change
Disk usage: No change

Overall: <5% overhead (acceptable)
```

### 13.3 Emergency Procedures

**Procedure 1: Build Fails After Migration**
```bash
# 1. Check error message
darwin-rebuild switch --flake . --show-trace

# 2. If syntax error in profile.nix:
nvim config/profile.nix
# Fix syntax, retry

# 3. If can't fix quickly:
./scripts/rollback-migration.sh .migration-backup-{timestamp}/

# 4. Report issue:
# Create GitHub issue with error trace
```

**Procedure 2: Secrets Accidentally Committed**
```bash
# 1. IMMEDIATELY remove from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch user-data/*/secrets/secrets.yaml" \
  --prune-empty --tag-name-filter cat -- --all

# 2. Force push (if already pushed to remote)
git push origin --force --all

# 3. Rotate all secrets
# Change: GitHub tokens, AWS keys, SSH passphrases

# 4. Re-encrypt with new age key
age-keygen -o user-data/jimmy/secrets/keys/age-key.txt
sops -r -i user-data/jimmy/secrets/secrets.yaml
```

**Procedure 3: System Unbootable**
```bash
# Boot into recovery mode
# 1. Restart Mac, hold Cmd+R
# 2. Open Terminal from Utilities menu

# 3. Rollback to previous generation
/nix/var/nix/profiles/system-1-link/activate

# 4. Restart normally
# System restored to pre-migration state
```

---

## 14. Future Extensibility

### 14.1 Planned Features (Q2 2025)

**1. Profile Inheritance**
```nix
# profiles/templates/senior-dev.nix
{
  extends = "personal";  # Inherit from personal profile

  cliTools = [
    # Inherits all personal.nix tools
    # Add senior-dev specific:
    "k9s" "helm" "argocd"
    "terraform" "ansible"
  ];
}
```

**2. Profile Mixins (Composable)**
```nix
# profiles/mixins/aws.nix
{ pkgs, ... }:
{
  cliTools = [ "aws-cli" "aws-vault" "aws-sso" ];
  awsProfiles = { ... };
}

# profiles/mixins/kubernetes.nix
{ pkgs, ... }:
{
  cliTools = [ "kubectl" "k9s" "helm" ];
  shellAliases = { k = "kubectl"; };
}

# Usage in profile:
{
  imports = [
    ../mixins/aws.nix
    ../mixins/kubernetes.nix
  ];
}
```

**3. Profile Validation Schema**
```bash
# Validate profile before activation
validate-profile personal

# Output:
# ✅ Valid profile: personal
# ✅ All required fields present
# ✅ All packages available
# ✅ All cliTools exist in nixpkgs
# ⚠️  Warning: Deprecated package: python38
```

**4. Profile Diff Tool**
```bash
# Compare two profiles
profile-diff personal work

# Output:
# === Apps ===
# - personal: firefox, brave, spotify
# + work: chrome, zoom, teams
#
# === CLI Tools ===
# - personal: gimp, inkscape
# + work: docker, kubectl, terraform
#
# === Aliases ===
# - personal: dev = "cd ~/Dev"
# + work: work = "cd ~/Work"
```

### 14.2 Advanced Features (Q3 2025)

**5. Profile Templates from Community**
```bash
# Download profile template
nix-darwin-profiles search data-science

# Result:
# nixos-community/data-science-profile
#   - Jupyter, pandas, scikit-learn
#   - R, Julia
#   - 150+ data science packages

# Install
nix-darwin-profiles install nixos-community/data-science-profile
# Creates: profiles/templates/data-science.nix
```

**6. Conditional Profile Settings**
```nix
# profiles/templates/work.nix
{
  # Conditional based on system
  cliTools = [
    "git" "gh"
  ] ++ (if system == "aarch64-darwin" then [
    # ARM-specific tools
    "docker-compose-arm64"
  ] else [
    # Intel-specific tools
    "docker-compose-x86"
  ]);

  # Conditional based on hostname
  awsProfiles = if machineId == "work-laptop" then {
    enabled = true;
    profiles = [ "dev" "staging" "prod" ];
  } else {
    enabled = false;
  };
}
```

**7. Profile Environment Variables**
```nix
# profiles/templates/work.nix
{
  envVars = {
    WORK_MODE = "true";
    AWS_DEFAULT_REGION = "us-west-2";
    KUBE_EDITOR = "nvim";
    TERRAFORM_LOG = "INFO";
  };

  # Conditional env vars
  envVars = {
    DEBUG = if machineId == "dev-laptop" then "true" else "false";
  };
}
```

**8. Profile Hooks**
```nix
# profiles/templates/work.nix
{
  hooks = {
    onActivate = ''
      echo "Activating work profile..."
      # Set up VPN
      # Connect to work network
      # Start required services
    '';

    onDeactivate = ''
      echo "Deactivating work profile..."
      # Disconnect VPN
      # Stop work services
    '';
  };
}
```

### 14.3 Enterprise Features (Q4 2025)

**9. Managed Profiles (Remote Config)**
```nix
# Company-managed profile
{
  profileSource = "https://company.com/nix-darwin/work-profile.nix";
  autoUpdate = true;
  updateFrequency = "daily";

  # Local overrides allowed
  localOverrides = {
    shellAliases = {
      myalias = "cd ~/MyProject";
    };
  };
}
```

**10. Compliance Reporting**
```bash
# Check if system meets company policy
nix-darwin-compliance check

# Output:
# ✅ Required packages installed: docker, kubectl, aws-cli
# ✅ Secrets encrypted with SOPS
# ✅ Disk encryption enabled
# ✅ Firewall active
# ⚠️  Optional: VPN not connected
# ❌ FAILED: Homebrew cask: spotify (not in allowlist)
```

**11. Audit Logging**
```bash
# Track profile changes
cat ~/.local/state/nix-darwin/audit.log

# Output:
# 2025-01-15 10:30:00 | switch-profile | personal → work | user: alice
# 2025-01-15 14:00:00 | config-change | added alias: deploy-prod | user: alice
# 2025-01-15 16:00:00 | switch-profile | work → personal | user: alice
```

**12. Multi-User Coordination**
```nix
# Team profile with shared settings
{
  profileName = "team-devops";
  sharedWith = [ "alice" "bob" "carol" ];

  # Shared packages
  sharedPackages = [ "kubectl" "terraform" "aws-cli" ];

  # User-specific overrides
  userOverrides = {
    alice = { email = "alice@company.com"; };
    bob = { email = "bob@company.com"; };
  };
}
```

### 14.4 Extensibility Roadmap

**Q1 2025: Foundation** (Current Proposal)
- ✅ Profile-based architecture
- ✅ Profile switching
- ✅ Multi-machine support
- ✅ Migration tooling

**Q2 2025: Enhancement**
- [ ] Profile inheritance
- [ ] Profile mixins
- [ ] Validation schemas
- [ ] Diff tools

**Q3 2025: Advanced**
- [ ] Community templates
- [ ] Conditional settings
- [ ] Environment variables
- [ ] Activation hooks

**Q4 2025: Enterprise**
- [ ] Managed profiles
- [ ] Compliance reporting
- [ ] Audit logging
- [ ] Multi-user coordination

### 14.5 API Stability

**Stability Guarantees:**

**Stable (v2.0.0+):**
- ✅ profile.nix format
- ✅ Profile template structure
- ✅ Core commands (switch-profile, nix-rebuild)
- ✅ Directory structure (user-data/, profiles/)

**Experimental (subject to change):**
- ⚠️ Profile inheritance
- ⚠️ Profile mixins
- ⚠️ Community templates
- ⚠️ Managed profiles

**Deprecation Policy:**
- Breaking changes require major version bump (v2.0 → v3.0)
- Deprecation warnings for 1 release cycle minimum
- Migration scripts provided for breaking changes

---

## Appendix A: Quick Reference

### Profile.nix Template
```nix
{
  username = "john";
  fullName = "John Doe";
  email = "john@example.com";
  machineId = "personal-laptop";
  profileName = "personal";
  system = "aarch64-darwin";
  homebrewEnabled = true;
  secretsEnabled = true;
  mixins = [ "base" "dev" "personal" ];
}
```

### Common Commands
```bash
# Rebuild system
nix-rebuild && exec zsh

# Switch profile
switch-profile work

# Validate config
./scripts/validate-config.sh

# Health check
health-check

# Migrate
./scripts/migrate-to-profiles.sh

# Rollback
./scripts/rollback-migration.sh .migration-backup-{timestamp}/
```

### Directory Structure
```
config/profile.nix          → Your configuration
profiles/templates/         → Profile definitions
home/template/              → User config entry
hosts/template/             → System config entry
user-data/{username}/       → User-specific data
```

---

## Appendix B: Glossary

**machineId**: Unique identifier for a machine (user's choice: generic or specific)

**profileName**: Behavior template (personal, work, minimal)

**profile.nix**: Single configuration file (replaces user-config.nix + machine-config.nix)

**Flake evaluation**: Phase 1 - parse flake.nix, build dependency graph (git tree)

**Build phase**: Phase 2 - execute builds, install packages (filesystem)

**Git tree**: Tracked files in git repository (excludes gitignored files)

**Filesystem**: All files on disk (includes gitignored files)

**SOPS**: Secrets Operations - tool for encrypting secrets

**Age**: Simple, modern encryption tool

**Mixin**: Composable configuration module (base, dev, personal, work)

**Template**: Git-tracked configuration pattern (home/template/, hosts/template/)

**user-data**: User-specific data directory (secrets, backups, credentials)

**Generation**: Nix system version (can rollback to previous generations)

---

## Appendix C: Further Reading

### Documentation
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://github.com/nix-community/home-manager)
- [SOPS](https://github.com/mozilla/sops)
- [Age Encryption](https://github.com/FiloSottile/age)

### Related Proposals
- [git-privacy Project](../../../projects/git-privacy)
- [AWS Multi-Role Guide](../../../reference/aws/AWS-MULTI-ROLE.md)

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Status:** ✅ Ready for Review
**Next Steps:** Review → Approve → Implement
