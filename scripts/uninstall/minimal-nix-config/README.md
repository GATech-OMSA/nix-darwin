# Minimal Nix-Darwin Config

**Dotfile-Free Package Management with Full Modularity**

This is a modular nix-darwin configuration that:
- ✅ Manages system packages via Nix
- ✅ Keeps Homebrew working
- ✅ Maintains module structure (fonts, security, packages, etc.)
- ✅ Includes all maintenance scripts
- ✅ Supports workspace backups
- ✅ Uses machine/user config system
- ❌ Does NOT generate or manage dotfiles (no Home Manager)

## Philosophy

This config keeps everything you love about declarative system management:
- Modular organization
- Script automation
- Machine-specific configs
- Workspace backups

But your dotfiles are now **real files you own and edit directly**.

## Structure

```
minimal-nix-config/
├── flake.nix                    # Entry point
├── config/                      # Machine & user configs (gitignored)
│   ├── user-config.nix
│   └── machine-config.nix
├── modules/                     # Modular Darwin configuration
│   ├── darwin/
│   │   ├── fonts.nix           # Font management
│   │   ├── homebrew.nix        # Homebrew casks & formulae
│   │   ├── security.nix        # Security settings
│   │   └── system.nix          # macOS system settings
│   └── shared/
│       ├── packages.nix        # Nix packages
│       └── nix.nix             # Nix daemon settings
├── scripts/                     # All your favorite scripts
│   ├── setup/
│   │   ├── bootstrap.sh        # Initial setup
│   │   ├── configure.sh        # Generate configs
│   │   └── activate.sh         # Apply configuration
│   ├── maintenance/
│   │   ├── health-check.sh     # System health
│   │   ├── nix-check.sh        # Nix flake check
│   │   └── pre-flight-checks.sh
│   └── workspace/
│       ├── backup.sh           # Workspace backups
│       └── restore.sh          # Workspace restore
└── workspace/                   # Per-machine data (gitignored)
```

## Initial Setup

1. **Copy this directory** to your chosen location (e.g., `~/.nix-darwin-minimal`)

2. **Run configure script** to set up machine/user configs:
   ```bash
   cd ~/.nix-darwin-minimal
   ./scripts/setup/configure.sh
   ```

3. **Edit your configs** (optional):
   ```bash
   # Add/remove packages
   vim modules/shared/packages.nix

   # Configure Homebrew apps
   vim modules/darwin/homebrew.nix

   # Adjust system settings
   vim modules/darwin/system.nix
   ```

4. **Apply configuration**:
   ```bash
   ./scripts/setup/activate.sh
   # OR manually:
   darwin-rebuild switch --flake .
   ```

## Daily Usage

### Managing Packages

```bash
# Add a package
vim modules/shared/packages.nix  # Add to list
darwin-rebuild switch --flake .  # Apply

# Add Homebrew app
vim modules/darwin/homebrew.nix  # Add to casks
darwin-rebuild switch --flake .  # Apply
```

### Managing Dotfiles

**This is now MANUAL** - your dotfiles are real files:

```bash
# Edit shell config directly
vim ~/.zshrc

# Edit git config directly
vim ~/.gitconfig

# No rebuild needed!
exec zsh  # Just restart shell
```

### Scripts

All scripts work the same:

```bash
# Health check
./scripts/maintenance/health-check.sh

# Pre-flight checks
./scripts/maintenance/pre-flight-checks.sh

# Workspace backup
./scripts/workspace/backup.sh

# Workspace restore
./scripts/workspace/restore.sh
```

### Aliases

Your `.zshrc` aliases should point here:

```bash
# These should now reference this directory
alias nixconf="code ~/.nix-darwin-minimal"
alias nix-rebuild="~/.nix-darwin-minimal/scripts/maintenance/pre-flight-checks.sh && darwin-rebuild switch --flake ~/.nix-darwin-minimal"
```

(The rollback script updates these automatically)

## What's Different from Full nix-darwin?

| Feature | Full nix-darwin | Minimal Config |
|---------|----------------|----------------|
| **Packages** | ✅ Managed | ✅ Managed |
| **Homebrew** | ✅ Managed | ✅ Managed |
| **System Settings** | ✅ Managed | ✅ Managed |
| **Fonts** | ✅ Managed | ✅ Managed |
| **Security** | ✅ Managed | ✅ Managed |
| **Dotfiles** | ✅ Generated | ❌ Manual (real files) |
| **Shell Config** | ✅ Generated | ❌ Manual (edit ~/.zshrc) |
| **Git Config** | ✅ Generated | ❌ Manual (edit ~/.gitconfig) |
| **Secrets** | ✅ SOPS encrypted | ❌ Plain files |
| **Scripts** | ✅ Available | ✅ Available |
| **Modules** | ✅ Modular | ✅ Modular |
| **Workspace** | ✅ Backup/restore | ✅ Backup/restore |

## Adding Packages

Edit `modules/shared/packages.nix`:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  git
  curl
  wget

  # Modern CLI tools
  eza
  bat
  ripgrep

  # Your tools
  awscli2
  jq
  # ...
];
```

Then rebuild:
```bash
darwin-rebuild switch --flake .
```

## Machine-Specific Configuration

The config system still works:

**`config/machine-config.nix`:**
```nix
{
  machineId = "macbook-pro-m1";
  machineType = "personal";  # or "work"
  description = "My MacBook Pro M1";
}
```

**`config/user-config.nix`:**
```nix
{
  username = "jimmy";
  fullName = "Jimmy";
  email = "jimmy@example.com";
}
```

Use in modules:
```nix
{ machineConfig, userConfig, ... }:

{
  # Access machine info
  networking.hostName = machineConfig.machineId;

  # Access user info
  users.users.${userConfig.username} = {
    home = "/Users/${userConfig.username}";
  };
}
```

## Workspace Backups

Still works the same way:

```bash
# Backup workspace
./scripts/workspace/backup.sh

# Restore workspace
./scripts/workspace/restore.sh
```

Workspace is stored in `workspace/${machineId}/` (gitignored)

## Switching Back to Full nix-darwin

If you want declarative dotfile management again:

1. Restore from backup:
   ```bash
   ~/.nix-darwin-backup-TIMESTAMP/RESTORE.sh
   ```

2. Or point back to full config:
   ```bash
   cd /Users/jimmy/nix-darwin
   darwin-rebuild switch --flake .
   ```

## Benefits of This Approach

- ✅ **Flexibility** - Edit dotfiles without rebuilds
- ✅ **Simplicity** - No Home Manager complexity
- ✅ **Portability** - Dotfiles are standard files
- ✅ **Speed** - No dotfile generation on rebuild
- ✅ **Structure** - Keep modular organization
- ✅ **Automation** - Keep all scripts and tools
- ✅ **Git** - Manage dotfiles separately if you want
- ✅ **Learning** - Easier to understand and debug

## Migrating Config from Full nix-darwin

Most modules can be copied directly:

```bash
# Copy package list
cp /Users/jimmy/nix-darwin/nix-config/modules/shared/packages.nix \
   modules/shared/packages.nix

# Copy Homebrew setup
cp /Users/jimmy/nix-darwin/nix-config/modules/darwin/homebrew.nix \
   modules/darwin/homebrew.nix

# Adjust paths as needed
```

Just remove any Home Manager references.
