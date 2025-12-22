# MAINTENANCE.md - System Maintenance & Cleanup Guide

This guide details the tools and workflows for maintaining your Nix-Darwin system.

## 🧹 Cleanup System (Tiered)

The system uses a tiered cleanup approach to balance safety and thoroughness.

### 1. Alias Tiers

| Tier | Command | Alias | Description | Risk |
|------|---------|-------|-------------|------|
| **1** | `cleanup-safe` | - | Removes logs, temp files, and caches. No packages removed. | 🟢 Low |
| **2** | `cleanup-quick` | `clean` | Safe tier + Brew cleanup & minor cache clearing. | 🟢 Low |
| **3** | `cleanup-standard` | `cleanup` | **Default.** Quick tier + Docker prune + Nix garbage collection (7d). | 🟡 Medium |
| **4** | `cleanup-dev` | - | Target specific dev artifacts (Node modules, Python venvs). | 🟡 Medium |
| **5** | `cleanup-aggressive` | - | Deep clean. Nix store optimize, aggressive prune. **Requires Confirmation.** | 🔴 High |

### 2. Script-Based Tools

These scripts provide specific maintenance functions beyond general cleanup.

*   `cleanup-system`: Runs `scripts/maintenance/system-cleanup.sh`. An interactive script that guides you through cleaning Nix, Brew, macOS caches, and Docker. Good for occasional manual maintenance.
*   `repo-reset`: Runs `scripts/maintenance/repo-reset.sh`. **DANGER.** Resets the local configuration repository (removes generated configs in `config/` and `hosts/`). Use only when resetting the machine state.

---

## 🛠️ Maintenance Workflows

### Daily/Weekly
*   Run `clean` (cleanup-quick) to keep caches light.
*   Run `nix-rebuild` to apply updates and rotate generations.

### Monthly
*   Run `cleanup` (cleanup-standard) to reclaim disk space from old Nix generations and Docker images.
*   Run `nix-brew-audit` to see if any installed Homebrew packages can be migrated to Nix.

### Troubleshooting / Disk Space Recovery
*   Run `cleanup-aggressive` to reclaim maximum space.
*   Run `cleanup-system` for an interactive, guided cleanup process.

---

## 🔍 Audit Tools

*   `nix-brew-audit`: Scans your Homebrew leaves and checks Nixpkgs for matches. Helps migrate imperative installs to declarative config.
*   `nix-verify-backups`: Checks that your critical data (secrets, keys) is backed up.
