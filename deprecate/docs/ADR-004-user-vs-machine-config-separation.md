# ADR-004: User vs Machine Config Separation

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

Nix-darwin configuration spans two distinct layers:

1. **System layer** (`modules/darwin/`, `modules/shared/`)
   - macOS system settings, preferences
   - System-wide packages (Homebrew, system tools)
   - Applies to the machine, not specific users

2. **User layer** (`home/_profiles/_template/`)
   - User-specific dotfiles, shell config
   - Development tools, personal packages
   - Home Manager configurations

### Initial Problem

Configuration was not clearly separated:
- Shell aliases mixed in system modules
- User packages in system configuration
- Machine-specific settings scattered across both layers
- Unclear where to add new configuration

### Requirements

1. **Clear separation**: System vs user config boundaries
2. **Machine-specific**: Support personal vs work differences
3. **User portability**: User config works across machines
4. **System stability**: System config independent of user changes
5. **Single rebuild**: One command updates both layers

## Decision

**Three-layer architecture with mixin system for machine differentiation.**

### Layer 1: System Configuration

**Location**: `modules/darwin/`, `modules/shared/`
**Purpose**: Machine-level settings
**Scope**: Applies to all users on the machine

```
modules/
├── darwin/
│   ├── system.nix          # macOS system preferences
│   ├── homebrew.nix        # GUI apps, fonts
│   └── security.nix        # Firewall, gatekeeper
└── shared/
    └── packages.nix        # System-wide CLI tools
```

**What goes here**:
- macOS system preferences (dock, finder, keyboard)
- System-wide packages (nix-installed tools)
- Homebrew casks (GUI applications)
- Security settings
- LaunchAgents, LaunchDaemons

### Layer 2: User Configuration

**Location**: `home/_profiles/_template/`
**Purpose**: User-specific settings
**Scope**: Applies to jimmy user across all machines

```
home/_profiles/_template/
├── shell/
│   └── zsh.nix            # Shell config, aliases
├── programs/
│   ├── git.nix            # Git config, aliases
│   ├── vscode.nix         # VS Code extensions
│   └── starship.nix       # Prompt customization
└── development/
    ├── python.nix         # Python setup
    └── node.nix           # Node.js setup
```

**What goes here**:
- Shell configuration (zsh, aliases, functions)
- Git configuration and aliases
- Editor configs (VS Code, vim)
- Development language setups
- User-specific packages

### Layer 3: Machine-Specific Mixins

**Location**: `home/_mixins/`
**Purpose**: Differentiate personal vs work machines
**Scope**: Applied per-machine based on hostname

```
home/_mixins/
├── base.nix               # Common to ALL machines
├── dev.nix                # Development tools
├── personal.nix           # Personal Mac only
└── work.nix               # Work Mac only
```

**Mixin selection logic**:
```nix
# home/_profiles/_template/default.nix
imports = [
  ./_mixins/base.nix
  ./_mixins/dev.nix
] ++ (myLib.importByMachine hostname {
  personal = [ ./_mixins/personal.nix ];
  work = [ ./_mixins/work.nix ];
});
```

## Consequences

### Positive

✅ **Clear boundaries**: Easy to know where config belongs
✅ **Separation of concerns**: System vs user vs machine
✅ **Machine portability**: User config works across machines
✅ **Conditional loading**: Only load relevant machine config
✅ **Better organization**: Logical grouping by scope
✅ **Easy maintenance**: Changes scoped to appropriate layer
✅ **Multi-user ready**: Can add more users easily

### Negative

⚠️ **Three layers to understand**: Learning curve for new users
⚠️ **Rebuild affects both**: System + user changes rebuild together
⚠️ **Mixin complexity**: Understanding import logic requires Nix knowledge

### Migration Impact

**Moved from system to user**:
- Shell aliases (`modules/darwin/` → `home/_profiles/_template/shell/`)
- Git configuration
- Development tool configs

**Moved from scattered to mixins**:
- AWS configuration (to `work.nix`)
- Work email (to `work.nix`)
- Personal packages (to `personal.nix`)

## Alternatives Considered

### Alternative 1: Single Flat Configuration

All configuration in one layer, no separation.

**Rejected because**:
- ❌ No clear organization
- ❌ Hard to maintain
- ❌ System and user concerns mixed
- ❌ Can't reuse user config across machines

### Alternative 2: Separate Nix-Darwin and Home Manager

Install nix-darwin and home-manager separately, two rebuilds.

**Rejected because**:
- ❌ More complex workflow (two rebuild commands)
- ❌ Synchronization issues between layers
- ❌ Harder to maintain consistency
- ❌ User confusion about which to rebuild

### Alternative 3: Environment Variables for Machine Type

Use `MACHINE_MODE=work` instead of mixins.

**Rejected because**:
- ❌ Not pure (Nix can't read environment easily)
- ❌ Manual setup required
- ❌ Can be unset or changed
- ❌ See [ADR-001](ADR-001-machine-detection-strategy.md)

### Alternative 4: Git Branches for Machines

Separate git branches for personal/work.

**Rejected because**:
- ❌ Merge conflicts
- ❌ Hard to share improvements
- ❌ Confusing version control
- ❌ See [ADR-001](ADR-001-machine-detection-strategy.md)

### Alternative 5: No Machine Differentiation

Manual config changes per machine, no automation.

**Rejected because**:
- ❌ Error-prone manual changes
- ❌ Harder to maintain consistency
- ❌ Can't track machine-specific config
- ❌ Loses benefit of declarative config

## Implementation Notes

### Adding System Configuration

```nix
# modules/darwin/system.nix
{
  system.defaults.dock.autohide = true;
}
```

### Adding User Configuration

```nix
# home/_profiles/_template/shell/zsh.nix
{
  programs.zsh.shellAliases = {
    ll = "ls -lah";
  };
}
```

### Adding Machine-Specific Configuration

```nix
# home/_mixins/work.nix
{
  programs.git.userEmail = "first.last@work.com";

  home.sessionVariables = {
    MACHINE_MODE = "work";
  };
}
```

### Decision Tree

**Where should I add this configuration?**

```
Does it affect macOS system settings?
├─ YES → modules/darwin/
│         Examples: dock, finder, keyboard settings
│
└─ NO → Is it the same on ALL machines?
         ├─ YES → home/_profiles/_template/
         │         Examples: shell aliases, git config
         │
         └─ NO → Is it machine-specific?
                  ├─ YES → home/_mixins/personal.nix or work.nix
                  │         Examples: work email, AWS profiles
                  │
                  └─ COMMON → home/_mixins/base.nix
                              Examples: starship, common env vars
```

## User Experience

### Adding a Package

**System package** (available to all users):
```nix
# modules/shared/packages.nix
environment.systemPackages = with pkgs; [ jq ];
```

**User package** (jimmy only):
```nix
# home/_profiles/_template/default.nix
home.packages = with pkgs; [ ripgrep ];
```

**Work-only package**:
```nix
# home/_mixins/work.nix
home.packages = with pkgs; [ awscli2 ];
```

### Configuration Changes

All layers rebuild together:
```bash
nix-rebuild  # Rebuilds system + user + mixins
```

No need to track which layer changed.

## File Organization Standards

### System Layer Standards

- **One file per concern**: `homebrew.nix`, `security.nix`, `system.nix`
- **No user-specific config**: Only machine-level settings
- **Clear naming**: File name matches purpose

### User Layer Standards

- **Organize by program**: `git.nix`, `vscode.nix`, `zsh.nix`
- **Group by category**: `shell/`, `programs/`, `development/`
- **No machine-specific logic**: Use mixins instead

### Mixin Layer Standards

- **base.nix**: Truly common to all machines
- **dev.nix**: Development tools (can be toggled)
- **personal.nix**: Personal Mac only
- **work.nix**: Work Mac only

## Multi-User Extension

Design supports multiple users:

```nix
# Future: home/alice/default.nix
{
  imports = [
    ./_mixins/base.nix
  ];
}

# flake.nix
homeConfigurations = {
  "jimmy@macbook-pro-m1" = home-manager.lib.homeManagerConfiguration { ... };
  "alice@macbook-pro-m1" = home-manager.lib.homeManagerConfiguration { ... };
};
```

## References

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Manual](https://github.com/LnL7/nix-darwin)
- [Architecture Overview](../overview.md)
- [ADR-001: Machine Detection Strategy](ADR-001-machine-detection-strategy.md)

## Revision History

- **2024-11-07**: Initial decision - Three-layer architecture with mixins
