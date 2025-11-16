# Nix-Darwin Rollback Scripts

**⚠️ WARNING: These scripts are designed to help you migrate OUT of nix-darwin declarative configuration management.**

## What These Scripts Do

These scripts help you gracefully exit the nix-darwin config system while preserving your working environment.

### What Gets Kept:
- ✅ Nix package manager (fully functional)
- ✅ All apps installed via Nix (optional cleanup available)
- ✅ Homebrew and all its apps
- ✅ System state and settings

### What Gets Converted:
- 🔄 Generated configs → Real static files
- 🔄 Symlinked dotfiles → Actual files you own
- 🔄 SOPS secrets → Plain config files (decrypted)
- 🔄 Nix-managed shell → Traditional shell setup

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `rollback-to-dotfiles.sh` | **Main orchestrator** - Run this |
| `backup-current-state.sh` | Backs up current working state |
| `materialize-configs.sh` | Converts generated configs to real files |
| `list-nix-packages.sh` | Shows what's managed by Nix |
| `minimal-nix-config/` | **Full modular nix-darwin** (no Home Manager) |

### About minimal-nix-config

This is **NOT a bare-bones config** - it's a fully modular nix-darwin setup that keeps:
- ✅ Module structure (fonts, homebrew, security, packages, nix)
- ✅ All scripts (bootstrap, configure, activate, health checks)
- ✅ Machine/user config system
- ✅ Workspace backups
- ❌ Home Manager (dotfile generation)

See `minimal-nix-config/README.md` for full details.

## Usage

```bash
# 1. Review what will happen (dry run)
./scripts/uninstall/rollback-to-dotfiles.sh --dry-run

# 2. Actually perform the rollback
./scripts/uninstall/rollback-to-dotfiles.sh

# 3. Optional: Clean up Nix packages
./scripts/uninstall/rollback-to-dotfiles.sh --cleanup-packages
```

## What Happens Step by Step

1. **Backup Phase**
   - Snapshot current working configs
   - Save Nix generation list
   - Create restore point

2. **Configure Minimal Nix Location**
   - Ask where to keep minimal nix config
   - Default: `~/.nix-darwin-minimal`
   - This path will be used in updated configs

3. **Package Inventory**
   - Show what's managed by Nix
   - Show what's managed by Homebrew
   - Categorize packages

4. **Materialization Phase**
   - Read current configs from Nix store
   - Create TWO versions of `.zshrc`:
     - `.zshrc.original` - Exact copy (unchanged paths)
     - `.zshrc` - Modified to use minimal nix config
   - Update paths: `/Users/jimmy/nix-darwin` → Your chosen minimal path
   - Decrypt secrets → Write to actual config files
   - Materialize other configs as-is

5. **Installation Phase**
   - Install modified `.zshrc` to `~/.zshrc`
   - Copy original to `~/.zshrc.original` (reference)
   - Install other configs
   - Remove Nix symlinks

6. **Minimal Config Setup**
   - Copy minimal config template to chosen location
   - Optional: Switch to minimal config immediately
   - This removes Home Manager (stops dotfile management)

7. **Cleanup Phase (Optional)**
   - Show list of Nix-managed packages
   - Let user choose what to uninstall
   - Remove selected packages

## After Rollback

You'll have:
- Traditional dotfiles in your `$HOME`
- Two versions of `.zshrc` (see below)
- Nix still available for package management
- Homebrew apps unchanged
- All your settings preserved

You can then:
- Edit `~/.zshrc` directly (no more rebuilds)
- Manage dotfiles with Git manually
- Use Nix just for installing packages via minimal config
- Keep or remove nix-darwin entirely

## Understanding the Dual .zshrc System

After rollback, you'll have **two versions** of your shell config:

### `~/.zshrc` (Active Version)
- **This is your active shell config** - used when you open a terminal
- Paths have been updated to point to your minimal nix config
- Example: `nix-rebuild` now points to `~/.nix-darwin-minimal` instead of `/Users/jimmy/nix-darwin`
- All Nix functions (`nixconf`, `nix-rebuild`, etc.) work with minimal config
- **Edit this file** if you want to customize your shell

### `~/.zshrc.original` (Reference Version)
- Exact copy from your nix-darwin managed config
- Paths unchanged (still point to `/Users/jimmy/nix-darwin`)
- **For reference only** - not used by your shell
- Useful if you need to see original paths or settings
- Safe to delete once you've confirmed everything works

### Why Two Versions?

Your nix-darwin config had many Nix-specific functions:
```bash
nix-rebuild    # Rebuilds your system
nixconf        # Opens config in editor
nix-rollback   # Rolls back to previous generation
# ... and many more
```

These all referenced `/Users/jimmy/nix-darwin`. After rollback:
- `.zshrc` has these paths updated to your minimal config location
- `.zshrc.original` keeps the original paths as reference
- You can compare them if something doesn't work

### Example Diff

**Original** (`.zshrc.original`):
```bash
nix-rebuild = "/Users/jimmy/nix-darwin/scripts/... && darwin-rebuild switch --flake /Users/jimmy/nix-darwin#..."
nixconf = "code /Users/jimmy/nix-darwin"
```

**Modified** (`.zshrc`):
```bash
nix-rebuild = "~/.nix-darwin-minimal/scripts/... && darwin-rebuild switch --flake ~/.nix-darwin-minimal#..."
nixconf = "code ~/.nix-darwin-minimal"
```

### What to Do

1. **Test your shell** - Run commands like `nix-rebuild`, `nixconf`, etc.
2. **If something doesn't work** - Compare `.zshrc` vs `.zshrc.original`
3. **Once satisfied** - Delete `.zshrc.original` or keep as backup
4. **To use different location** - Edit `.zshrc` and update the paths

## Safety Features

- Creates backups before any changes
- Dry-run mode to preview changes
- Rollback capability (within 24 hours)
- Preserves all working state

## Restore from Backup

If something goes wrong:

```bash
./scripts/uninstall/restore-from-backup.sh
```

This will restore the nix-darwin managed state.
