# Root Cause Analysis: Home Manager Activation Failure

**Date**: November 5, 2025
**System**: mbp-work (M3 MacBook, macOS)
**Status**: ✅ RESOLVED

## Problem Statement

After cloning nix-darwin configuration and running `darwin-rebuild switch`, the system appeared to work but:
- Starship was not using custom `starship.toml` configuration
- Zsh had no custom aliases or functions
- Home Manager-managed dotfiles were not linked to home directory

## Root Cause

When running `sudo darwin-rebuild switch`, the system activation script creates `~/.local/state` directory as the root user. This prevents Home Manager (running as the regular user) from creating the necessary gcroots directory structure for managing symlinks.

**Technical Details**:
- Home Manager needs to create: `~/.local/state/home-manager/gcroots/`
- The directory was owned by `root:wheel` instead of `jimmy:staff`
- Home Manager activation silently failed when attempting to run `nix-store --realise`
- No error messages were visible in normal output

**Discovery Method**: Used `bash -x` to trace the Home Manager activation script, which revealed:
```
mkdir: /Users/jimmy/.local/state/home-manager/gcroots: Permission denied
```

## Solution

### Immediate Fix
```bash
sudo chown -R jimmy:staff ~/.local/state
```

### Permanent Fix
Added system activation script to automatically fix permissions before Home Manager runs:

**File**: `modules/darwin/default.nix`
```nix
system.activationScripts.preActivation = {
  enable = true;
  text = ''
    echo "Fixing permissions for Home Manager..."
    for user_dir in /Users/*; do
      if [ -d "$user_dir" ]; then
        username=$(basename "$user_dir")
        if [ -d "$user_dir/.local/state" ]; then
          chown -R "$username:staff" "$user_dir/.local/state" 2>/dev/null || true
          echo "Fixed permissions for $username"
        fi
      fi
    done
  '';
};
```

This script:
1. Runs during system activation (before Home Manager)
2. Iterates through all user directories
3. Fixes ownership of `.local/state` if it exists
4. Handles multiple users automatically

## Verification

After applying the fix:
- ✅ Starship prompt displays with custom configuration
- ✅ All custom aliases and functions work (`restart`, `ll`, `la`, etc.)
- ✅ Dotfiles properly symlinked from `/nix/store/`
- ✅ Home Manager activation hooks execute successfully
- ✅ Automatic backup of conflicting files (`.hm-backup` extension)

## Impact on New Machines

This fix makes the configuration portable:
- Works automatically on fresh installations
- No manual permission fixes needed
- Safe for multiple user accounts
- Compatible with Determinate Nix installer

## Related Changes

1. **Determinate Nix Compatibility**: Set `nix.enable = false` in darwin configuration
2. **Starship Configuration**: Disabled Oh-My-Zsh theme to allow Starship
3. **Home Manager Integration**: Added `backupFileExtension = "hm-backup"` for safety
4. **Git Hook Fix**: Fixed pre-commit hook to properly validate SOPS encryption

### Git Hook Issue

The original pre-commit hook used `file` command to check if secrets were "binary", but SOPS-encrypted YAML files are ASCII text (base64-encoded values in YAML). This caused false positives.

**Fixed**: `.git/hooks/pre-commit` now calls `scripts/check-secrets-encrypted.sh` which properly validates:
- Presence of `sops:` metadata section
- Presence of `ENC[AES256_GCM,...]` encrypted values

## Lessons Learned

1. Always check file ownership when `sudo` commands create user directories
2. Home Manager activation failures can be silent - use debug tracing when needed
3. System activation scripts can prevent common permission issues
4. Determinate Nix requires different configuration than standard Nix

## Documentation

- Created: `docs/INSTALLATION-FIX.md` with detailed troubleshooting steps
- Updated: System configuration with permanent fix
- Next: Update main README.md with clearer installation instructions
