# GEMINI.md - AI Assistant Instructions for nix-darwin

---

## Overview

This is a **nix-darwin** configuration repository providing declarative macOS system configuration using Nix + Home Manager. It manages system packages, application configurations, secrets, and supports multiple machines (personal + work).

**One command rebuilds the entire system:** `darwin-rebuild switch --flake .`

---

## Quick Reference Links

When user asks about:

**Getting Started:**
- **New user / getting started** → [START-HERE.md](docs/START-HERE.md)
- **Quick commands** → [QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)
- **Installation** → [Installation Guide](docs/guides/installation.md)

**Daily Usage:**
- **Adding packages** → [Usage Guide - Adding Packages](docs/guides/usage.md#adding-packages)
- **Adding aliases** → [Usage Guide - Adding Aliases](docs/guides/usage.md#adding-aliases)
- **Git aliases** → [Shell Reference - Git](docs/reference/shell.md#git)
- **Shell aliases** → [Shell Reference - Zsh](docs/reference/shell.md#zsh)
- **Python setup** → [Languages Reference - Python](docs/reference/languages.md#python)
- **Secrets** → [Secrets Guide](docs/guides/secrets.md)
- **System health** → [System Health Check Guide](docs/guides/system-health.md)
- **Backup/rollback** → [Backup & Recovery Guide](docs/guides/backup-and-recovery.md)

**Troubleshooting & Reference:**
- **Troubleshooting** → [Troubleshooting Guide](docs/guides/troubleshooting.md)
- **FAQ** → [FAQ & Reference](docs/appendix/faq.md)
- **Architecture** → [Architecture Overview](docs/architecture/overview.md)

---

## Common Commands

### Building & Switching

```bash
# Rebuild system
nix-rebuild

# Test build without switching
darwin-rebuild build --flake ~/nix-darwin
```

### Updates

```bash
update-all     # Update everything
update-nix     # Just Nix packages
update-brew    # Just Homebrew
```

### Rollback

```bash
# Rollback to previous generation
nix-rollback
```

---

## Key Files to Edit

| Want to...                 | Edit file                                      |
| -------------------------- | ---------------------------------------------- |
| Add system package         | `modules/shared/packages.nix`                  |
| Add GUI app                | `modules/darwin/homebrew.nix`                  |
| Add shell alias            | `home/jimmy/shell/zsh.nix`                     |
| Add git alias              | `home/jimmy/programs/git.nix`                  |
| Add VS Code extensions     | `home/jimmy/programs/vscode.nix`               |
| Change Python setup        | `home/jimmy/development/python.nix`            |
| Add personal setting       | `home/_mixins/personal.nix`                    |
| Add work setting           | `home/_mixins/work.nix`                        |

---

## AI Assistant Instructions

### 1. Use Lib Functions for Common Patterns

**Available via `myLib` parameter in modules.**

- **Machine-specific values**: Use `myLib.selectByMachine hostname { personal = X; work = Y; }`
- **Conditional imports**: Use `myLib.importIfPersonal hostname path`
- **Navigation aliases**: Use `myLib.mkNavigationAliases "$HOME/Dev" { ... }`
- **Package groups**: Use `myLib.mkPackageGroups { ... } pkgs`

**Don't manually write:**

- `if hostname == "mbp-work" then... else...` → Use `myLib.selectByMachine`

### 2. Always Rebuild After Config Changes

Configuration changes require a rebuild to take effect: `nix-rebuild`

### 3. Don't Edit Generated Files

**Never edit these directly** (they are managed by Nix):

- `~/.zshrc`
- `~/.config/git/config`
- `~/.config/starship.toml`

**Edit the source files instead.**

### 4. Refer to Documentation

**Instead of explaining inline, link to the comprehensive documentation in the `docs/` directory.**

### 5. Test Before Committing

1. Read current config
2. Make edit
3. Rebuild: `nix-rebuild`
4. Test the change
5. Commit: `g aa && g cm "..."`

### 6. Git Commit Messages

**NEVER include AI assistant references in commit messages.** Write clean, professional commit messages.

### 7. Hostname Matters

System behavior depends on the hostname (`mbp-jimmy` vs. `mbp-work`).

### 8. State Versions

**Never change `system.stateVersion` or `home.stateVersion`.**

### 9. Machine-Specific Config

Use mixins for machine-specific settings:

- **Shared** → `base.nix` or `dev.nix`
- **Personal only** → `personal.nix`
- **Work only** → `work.nix`

### 10. Security

*   Secrets are managed with `sops-nix` and encrypted in `hosts/*/secrets.yaml`.
*   Use the `edit-secrets` alias to edit secrets.
*   Git hooks are in place to prevent committing unencrypted secrets.
