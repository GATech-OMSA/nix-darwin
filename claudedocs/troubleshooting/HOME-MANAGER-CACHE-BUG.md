# Home Manager Cache Bug & Workaround

**Date**: 2025-11-06
**Severity**: Critical
**Status**: Workaround Available

## Problem Description

When modifying Home Manager configuration (e.g., changing `oh-my-zsh.plugins` list), `darwin-rebuild switch` does **not** trigger home-manager to regenerate files, even though:
- ✅ The Nix expression evaluates correctly (`nix eval` shows correct values)
- ✅ Source configuration is correct
- ❌ Generated `.zshrc` in nix store still contains old values
- ❌ Symlink points to old cached nix store path

### What Doesn't Work

All of these **FAILED** to trigger regeneration:
- `darwin-rebuild switch --flake ~/nix-darwin`
- `darwin-rebuild switch --impure`
- `darwin-rebuild switch --rebuild`
- `nix-collect-garbage -d` + rebuild
- `nix flake update` + rebuild
- Deleting `~/.zshrc` symlink + rebuild
- Deleting `~/.local/state/home-manager/gcroots/current-home` + rebuild
- Adding `builtins.currentTime` to force hash change (with `--impure`)
- Deleting `/nix/var/nix/profiles/system-*` + rebuild

### Root Cause

Home Manager activation says: **"No change so reusing latest profile generation"**

Even though the derivation content changed, Home Manager compares at the **profile generation level**, not derivation content level. The cached derivation is reused because the profile generation comparison doesn't detect the change.

## The Workaround That Works

Build and activate home-manager directly, bypassing darwin-rebuild:

```bash
# 1. Build the home-manager activation package with --impure
cd ~/nix-darwin
result=$(nix build --impure --print-out-paths \
  .#darwinConfigurations.mbp-jimmy.config.home-manager.users.jimmy.home.activationPackage)

# 2. Manually activate it
$result/activate

# 3. Restart shell
exec zsh
```

### Why This Works

- Builds a **new** home-manager generation directly
- Bypasses the darwin-rebuild integration layer
- Forces regeneration of all home files
- `--impure` flag ensures no cached evaluation is used

## Verification

After running the workaround:

```bash
# 1. Check symlink points to NEW store path
ls -la ~/.zshrc
# Before: /nix/store/kp1cj71...-home-manager-files/.zshrc
# After:  /nix/store/sly02nyn...-home-manager-files/.zshrc (NEW!)

# 2. Verify file content changed
grep "^plugins=" ~/.zshrc
# Should show updated plugins list

# 3. Check nix eval matches actual file
nix eval --impure .#darwinConfigurations.mbp-jimmy.config.home-manager.users.jimmy.programs.zsh.oh-my-zsh.plugins --json
# Compare to ~/.zshrc content
```

## Convenient Aliases

Add these to `home/jimmy/shell/zsh.nix`:

```nix
shellAliases = {
  # Standard rebuild
  nix-rebuild = "sudo darwin-rebuild switch --flake ~/nix-darwin";

  # Force home-manager regeneration (workaround for cache bug)
  nix-rebuild-force = ''
    cd ~/nix-darwin && \
    result=$(nix build --impure --print-out-paths \
      .#darwinConfigurations.$(hostname).config.home-manager.users.jimmy.home.activationPackage) && \
    $result/activate && \
    sudo darwin-rebuild switch --flake ~/nix-darwin --impure
  '';

  # Just force home-manager without system rebuild
  home-rebuild-force = ''
    cd ~/nix-darwin && \
    result=$(nix build --impure --print-out-paths \
      .#darwinConfigurations.$(hostname).config.home-manager.users.jimmy.home.activationPackage) && \
    $result/activate
  '';
};
```

## When to Use Force Rebuild

Use `nix-rebuild-force` when:
- ✅ Modifying Home Manager configuration (zsh plugins, aliases, etc.)
- ✅ Changes to shell configuration not appearing after rebuild
- ✅ `.zshrc` or other home files not updating
- ✅ Symlinks pointing to old nix store paths

Use regular `nix-rebuild` for:
- ✅ System-level changes (packages, homebrew, system settings)
- ✅ First-time machine setup
- ✅ Updates (`update-all` already handles this correctly)

## Related Issues

- Home Manager doesn't auto-delete `.zshrc.zwc` compiled cache: [#1088](https://github.com/nix-community/home-manager/issues/1088)
- Derivation caching across darwin-rebuild: Upstream issue (to be filed)

## Future Solutions

Potential fixes being investigated:
1. Add `home.activation` script to touch a dummy file on each rebuild
2. Use `lib.mkForce` to override cached derivations
3. File upstream bug report with nix-darwin + home-manager integration
4. Investigate if `useGlobalPkgs = false` helps

## Example Case: Removing oh-my-zsh z plugin

**Scenario**: Removed `"z"` from `programs.zsh.oh-my-zsh.plugins` list

**Problem**: After `darwin-rebuild switch`, `.zshrc` still had `z` in plugins array

**Solution**:
```bash
# Used nix-rebuild-force workaround
home-rebuild-force

# Result: .zshrc regenerated with z removed
grep "^plugins=" ~/.zshrc
# plugins=(git docker ... fzf dirhistory sudo ...)  # z is GONE!
```

## Additional Notes

- The workaround uses `--impure` which breaks reproducibility temporarily
- This is safe for local development but should not be relied on for deployment
- Remove any `builtins.currentTime` hacks after successful rebuild
- The issue appears to be specific to nix-darwin + home-manager integration
- Standalone home-manager on NixOS may not have this issue

---

**Discovered**: 2025-11-06
**Workaround Status**: Tested and Working
**Upstream Report**: Pending
