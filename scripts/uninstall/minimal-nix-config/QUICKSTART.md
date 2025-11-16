# Quick Start Guide

**Get up and running in 5 minutes**

## Prerequisites

- macOS
- Nix installed (with flakes enabled)
- nix-darwin installed

## Setup Steps

### 1. Bootstrap (if needed)

If nix-darwin is not installed:

```bash
./scripts/setup/bootstrap.sh
```

### 2. Configure

Set up your machine and user settings:

```bash
./scripts/setup/configure.sh
```

You'll be asked for:
- Username (defaults to $USER)
- Full name
- Email
- Machine ID (defaults to hostname)
- Machine type (personal or work)
- Description

This creates `config/user-config.nix` and `config/machine-config.nix` (gitignored).

### 3. Customize (Optional)

Edit modules to add packages or change settings:

```bash
# Add system packages
vim modules/shared/packages.nix

# Add GUI apps via Homebrew
vim modules/darwin/homebrew.nix

# Adjust macOS settings
vim modules/darwin/system.nix
vim modules/darwin/security.nix

# Change fonts
vim modules/darwin/fonts.nix
```

### 4. Activate

Apply your configuration:

```bash
./scripts/setup/activate.sh
# OR manually:
darwin-rebuild switch --flake .
```

### 5. Restart Shell

```bash
exec zsh
```

## Daily Workflow

### Adding a Package

1. Edit `modules/shared/packages.nix`:
   ```nix
   environment.systemPackages = with pkgs; [
     # ... existing packages ...
     your-new-package
   ];
   ```

2. Apply:
   ```bash
   darwin-rebuild switch --flake .
   ```

### Adding a GUI App

1. Edit `modules/darwin/homebrew.nix`:
   ```nix
   casks = [
     # ... existing apps ...
     "your-app"
   ];
   ```

2. Apply:
   ```bash
   darwin-rebuild switch --flake .
   ```

### Editing Dotfiles

**Important:** Dotfiles are now real files - edit them directly!

```bash
# Edit shell config
vim ~/.zshrc

# Edit git config
vim ~/.gitconfig

# No rebuild needed - just restart shell
exec zsh
```

## Maintenance

### Health Check

```bash
./scripts/maintenance/health-check.sh
```

Shows:
- Nix version
- nix-darwin status
- Config file status
- Homebrew status
- Disk usage

### Pre-Flight Checks

Runs automatically before activate, or run manually:

```bash
./scripts/maintenance/pre-flight-checks.sh
```

### Workspace Backup

```bash
./scripts/workspace/backup.sh
```

Stores machine-specific data in `workspace/${machineId}/` (gitignored).

### Workspace Restore

```bash
./scripts/workspace/restore.sh
```

## Troubleshooting

### Config not found error

```bash
./scripts/setup/configure.sh
```

### Flake errors

```bash
nix flake check .
```

### See what changed

```bash
darwin-rebuild --list-generations
```

### Rollback

```bash
darwin-rebuild --rollback
```

## File Structure

```
.
├── flake.nix              # Entry point
├── config/                # Machine configs (gitignored)
├── modules/               # Modular configuration
│   ├── darwin/            # macOS-specific
│   └── shared/            # Cross-platform
├── scripts/               # Automation
│   ├── setup/             # Initial setup
│   ├── maintenance/       # Health checks
│   └── workspace/         # Backups
└── workspace/             # Per-machine data (gitignored)
```

## Next Steps

- Customize your package list
- Add Homebrew apps
- Set up workspace backups
- Commit config to Git (optional)
- Read full README.md for details

## Getting Help

- Full documentation: `README.md`
- Check health: `./scripts/maintenance/health-check.sh`
- Pre-flight checks: `./scripts/maintenance/pre-flight-checks.sh`
