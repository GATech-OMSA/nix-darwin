# Multi-User Setup Guide

This guide explains how to use this nix-darwin configuration with different usernames, enabling multiple users to adopt this configuration for their own systems.

## Overview

The configuration is now fully parameterized to support any username. The username is specified in `flake.nix` when defining each machine configuration and automatically propagates throughout the system.

## Key Features

- **Parameterized Username**: All user-specific paths and configurations use variables
- **Dynamic Home Paths**: Home directories automatically adapt to the username
- **Flexible Machine Definitions**: Easy to add new machines with different usernames
- **Backward Compatible**: Existing "jimmy" setup continues to work without changes

## For New Users: Getting Started

### Step 1: Clone the Repository

```bash
# Clone to your home directory
cd ~
git clone https://github.com/yourusername/nix-darwin.git
cd nix-darwin
```

### Step 2: Update flake.nix

Edit `flake.nix` to add your machine configuration:

```nix
# Example: Add a new personal machine for user "alice"
darwinConfigurations."alice-mbp" = mkDarwinSystem {
  hostname = "alice-mbp";
  system = "aarch64-darwin";
  username = "alice";  # ← Change this to your username
  mixins = [ "base" "dev" "personal" ];
};
```

### Step 3: Create User Home Directory

The configuration expects a home directory structure. Create it by copying the existing structure:

```bash
# Copy the home configuration template
cp -r home/jimmy home/alice  # Replace "alice" with your username

# The system will automatically use this directory based on username parameter
```

### Step 4: Update Machine Registry

Add your hostname to `hosts/machines.nix`:

```nix
knownMachines = {
  # ... existing machines ...
  "alice-mbp" = "personal";  # or "work" depending on machine type
};
```

### Step 5: Create Host Configuration

```bash
# Create host directory
mkdir -p hosts/alice-mbp

# Copy from template
cp hosts/mbp-jimmy/default.nix hosts/alice-mbp/default.nix

# Edit the networking section for your machine:
# - computerName: "Alice's MacBook Pro"
```

### Step 6: First Build

```bash
# Set your hostname (macOS)
sudo scutil --set HostName alice-mbp
sudo scutil --set LocalHostName alice-mbp
sudo scutil --set ComputerName "Alice's MacBook Pro"

# First-time installation
sudo nix run nix-darwin -- switch --flake .#alice-mbp
```

## For Existing Users: Adding a New Machine

If you already use this configuration and want to add a new machine (e.g., work laptop):

### Example: Adding a Work Machine

```nix
# In flake.nix
darwinConfigurations."jimmy-work" = mkDarwinSystem {
  hostname = "jimmy-work";
  system = "aarch64-darwin";
  username = "jimmy";  # Same username, different machine
  mixins = [ "base" "dev" "work" ];  # Note: "work" instead of "personal"
};
```

Then create `hosts/jimmy-work/default.nix` following the pattern in `hosts/mbp-work/`.

## How It Works

### Username Propagation

The username flows through the configuration like this:

```
flake.nix (username: "alice")
    ↓
mkDarwinSystem (specialArgs.username)
    ↓
hosts/alice-mbp/default.nix (users.users.${username})
    ↓
home/alice/default.nix (home.username, config.home.homeDirectory)
    ↓
shell/zsh.nix (nixDarwinDir, homeDir variables)
```

### Dynamic Path Resolution

All paths that previously used hardcoded usernames now use variables:

**Before (hardcoded):**
```nix
homeDirectory = "/Users/jimmy";
nixconf = "code ~/nix-darwin/home/jimmy/shell/zsh.nix";
```

**After (dynamic):**
```nix
homeDirectory = "/Users/${username}";
nixconf = "code ${nixDarwinDir}/home/${username}/shell/zsh.nix";
```

### Configuration Shortcuts

Shell aliases and functions automatically adapt to your username:

- `nixconf` → Opens `~/nix-darwin` (wherever your home is)
- `zshconf` → Opens `~/nix-darwin/home/<your-username>/shell/zsh.nix`
- `nix-rebuild` → Rebuilds with your username's home-manager config

## Customization by User

Each user can customize their configuration in `home/<username>/`:

```
home/alice/
├── default.nix           # Main user configuration
├── shell/
│   └── zsh.nix          # Shell aliases and functions
├── programs/
│   ├── git.nix          # Git configuration
│   ├── vscode.nix       # VS Code extensions
│   └── ...
└── development/
    ├── python.nix       # Python setup
    └── ...
```

## Common Patterns

### Same User, Multiple Machines

```nix
# Personal MacBook
darwinConfigurations."alice-personal" = mkDarwinSystem {
  hostname = "alice-personal";
  username = "alice";
  mixins = [ "base" "dev" "personal" ];
};

# Work MacBook
darwinConfigurations."alice-work" = mkDarwinSystem {
  hostname = "alice-work";
  username = "alice";
  mixins = [ "base" "dev" "work" ];
};
```

Both machines use the same `home/alice/` configuration but with different mixins for machine-specific settings.

### Different Users, Shared Repository

```nix
# Alice's machine
darwinConfigurations."alice-mbp" = mkDarwinSystem {
  hostname = "alice-mbp";
  username = "alice";
  mixins = [ "base" "dev" "personal" ];
};

# Bob's machine
darwinConfigurations."bob-mbp" = mkDarwinSystem {
  hostname = "bob-mbp";
  username = "bob";
  mixins = [ "base" "dev" "personal" ];
};
```

Repository structure:
```
home/
├── alice/  # Alice's user configurations
└── bob/    # Bob's user configurations
```

## Migration from Hardcoded Setup

If you're migrating from a hardcoded username setup:

1. **Verify username parameter**: Check `flake.nix` has username in machine definition
2. **Update home directory**: Ensure `home/${username}/` matches your username
3. **Rebuild**: Run `darwin-rebuild switch --flake ~/nix-darwin`
4. **Test aliases**: Verify `nixconf`, `zshconf`, etc. work correctly

## Troubleshooting

### "home/<username> directory not found"

**Problem**: The configuration looks for `home/${username}/default.nix` but it doesn't exist.

**Solution**:
```bash
# Copy from template
cp -r home/jimmy home/your-username
```

### "User not defined" errors

**Problem**: Host configuration doesn't define the user properly.

**Solution**: Ensure `hosts/<hostname>/default.nix` has:
```nix
users.users.${username} = {
  name = username;
  home = "/Users/${username}";
  shell = pkgs.zsh;
};
```

### Aliases not working

**Problem**: Shell shortcuts like `nixconf` point to wrong paths.

**Solution**: Restart shell after rebuild:
```bash
exec zsh
```

## Best Practices

1. **Use descriptive hostnames**: `alice-personal`, `bob-work`, not generic names
2. **Keep mixins consistent**: Use same mixin structure across users
3. **Document customizations**: Add comments for user-specific changes
4. **Test before committing**: Always test build on new machine first
5. **Separate user configs**: Each user gets their own `home/<username>/` directory

## Examples

### Example 1: Student Setup

```nix
darwinConfigurations."student-mbp" = mkDarwinSystem {
  hostname = "student-mbp";
  username = "student";
  mixins = [ "base" "dev" "personal" ];
};
```

### Example 2: Family Shared Repository

```nix
# Parent's work laptop
darwinConfigurations."parent-work" = mkDarwinSystem {
  hostname = "parent-work";
  username = "parent";
  mixins = [ "base" "dev" "work" ];
};

# Parent's personal laptop
darwinConfigurations."parent-home" = mkDarwinSystem {
  hostname = "parent-home";
  username = "parent";
  mixins = [ "base" "dev" "personal" ];
};

# Kid's laptop
darwinConfigurations."kid-mbp" = mkDarwinSystem {
  hostname = "kid-mbp";
  username = "kid";
  mixins = [ "base" "personal" ];  # No "dev" mixin
};
```

## See Also

- [Installation Guide](installation.md) - Initial setup steps
- [Architecture Overview](../architecture/overview.md) - System design
- [Usage Guide](usage.md) - Daily usage patterns
