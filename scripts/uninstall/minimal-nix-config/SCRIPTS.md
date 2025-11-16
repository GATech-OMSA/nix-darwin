# Scripts Reference

Complete guide to all scripts in minimal-nix-config

## 📁 Directory Overview

```
scripts/
├── setup/              # Initial setup & configuration
├── maintenance/        # System maintenance & health
├── validation/         # Config & security validation
├── app-catalog/        # App discovery & installation
└── workspace/          # Per-machine data management
```

---

## 🚀 Setup Scripts

### `bootstrap.sh`
**Initial nix-darwin installation on a new machine**

```bash
./scripts/setup/bootstrap.sh
```

- Checks if Nix is installed
- Installs nix-darwin if needed
- Guides through initial setup

**When to use:** First-time setup on a brand new machine

---

### `configure.sh`
**Interactive configuration generator**

```bash
./scripts/setup/configure.sh
```

Prompts for:
- Username
- Full name
- Email
- Machine ID
- Machine type (personal/work)
- Description

Creates:
- `config/user-config.nix` (gitignored)
- `config/machine-config.nix` (gitignored)

**When to use:** Initial setup, or to reconfigure machine/user settings

---

### `activate.sh`
**Apply nix-darwin configuration**

```bash
./scripts/setup/activate.sh
```

- Runs pre-flight checks
- Applies configuration via `darwin-rebuild`
- Shows activation summary

**When to use:** After editing modules to apply changes

**Equivalent to:**
```bash
darwin-rebuild switch --flake .
```

---

### `scaffold-new-machine.sh`
**New machine setup wizard**

```bash
./scripts/setup/scaffold-new-machine.sh
```

Interactive wizard that:
1. Checks prerequisites
2. Runs configuration
3. Helps customize modules
4. Applies configuration
5. Provides next steps

**When to use:** Setting up minimal-nix-config on a new machine (guided experience)

---

## 🔧 Maintenance Scripts

### `health-check.sh`
**System health diagnostics**

```bash
./scripts/maintenance/health-check.sh
```

Checks:
- Nix installation & version
- nix-darwin status
- Config file validity
- Homebrew status
- Disk space usage
- Generation count

**When to use:** Regular checkups, troubleshooting

---

### `pre-flight-checks.sh`
**Pre-rebuild validation**

```bash
./scripts/maintenance/pre-flight-checks.sh
```

Validates:
- Nix is installed
- darwin-rebuild available
- Config files exist
- Flake is valid
- Disk space sufficient

**When to use:** Before rebuilds (runs automatically in activate.sh)

---

### `cleanup.sh`
**Nix garbage collection & cleanup**

```bash
./scripts/maintenance/cleanup.sh
```

Options:
1. Delete old generations (keep last 5)
2. Delete old generations (keep last 10)
3. Delete generations older than 30 days
4. Garbage collect only
5. Full cleanup (delete + GC + optimize)

**When to use:** Weekly/monthly maintenance, when disk space is low

---

### `config-diff.sh`
**Show configuration changes**

```bash
./scripts/maintenance/config-diff.sh
```

Shows:
- Git status
- Changes in tracked files
- Untracked files
- Recent commits
- Module-specific diffs

**When to use:** Before committing, to review changes

**Requires:** Git repository initialized

---

## ✅ Validation Scripts

### `audit-permissions.sh`
**File permission security audit**

```bash
./scripts/validation/audit-permissions.sh
```

Checks:
- Config file permissions (should be 600/644)
- Workspace permissions (recommends 700)
- Suggests fixes for issues

**When to use:** Security audits, after manual file operations

---

### `validate-machine-config.sh`
**Config file validation**

```bash
./scripts/validation/validate-machine-config.sh
```

Validates:
- `user-config.nix` (username, fullName, email)
- `machine-config.nix` (machineId, machineType, description)
- machineType is 'personal' or 'work'

**When to use:** After manual config edits, troubleshooting

---

## 📦 App Catalog Scripts

### `install-apps.sh`
**Interactive app installer**

```bash
./scripts/app-catalog/install-apps.sh
```

Features:
- Browse apps by category
  - Development (VS Code, iTerm2, Docker)
  - Browsers (Chrome, Firefox, Brave)
  - Productivity (Notion, Slack, Zoom)
  - Utilities (Rectangle, Raycast)
  - Media (Spotify, VLC)
  - Security (1Password, ProtonVPN)
- Search Homebrew casks
- Add custom apps
- Auto-adds to `homebrew.nix`
- Optional immediate rebuild

**When to use:** Discovering and installing GUI apps easily

---

## 💾 Workspace Scripts

### `backup.sh`
**Workspace backup for this machine**

```bash
./scripts/workspace/backup.sh
```

- Creates `workspace/${machineId}/`
- Saves backup timestamp
- Template for adding custom backup logic

**Customize:** Edit script to backup machine-specific files

**When to use:** Regular backups of machine-specific data

---

### `restore.sh`
**Workspace restore for this machine**

```bash
./scripts/workspace/restore.sh
```

- Reads from `workspace/${machineId}/`
- Shows last backup date
- Template for adding custom restore logic

**Customize:** Edit script to restore machine-specific files

**When to use:** After reinstall, moving to new machine

---

## 🔄 Common Workflows

### Daily Development
```bash
# Edit packages
vim modules/shared/packages.nix

# Apply
./scripts/setup/activate.sh

# Check health
./scripts/maintenance/health-check.sh
```

### Adding GUI Apps
```bash
# Interactive browser
./scripts/app-catalog/install-apps.sh

# OR manually
vim modules/darwin/homebrew.nix
./scripts/setup/activate.sh
```

### Maintenance (Weekly)
```bash
# Health check
./scripts/maintenance/health-check.sh

# Cleanup old generations
./scripts/maintenance/cleanup.sh

# Backup workspace
./scripts/workspace/backup.sh
```

### New Machine Setup
```bash
# Option 1: Wizard (recommended)
./scripts/setup/scaffold-new-machine.sh

# Option 2: Manual
./scripts/setup/bootstrap.sh
./scripts/setup/configure.sh
./scripts/setup/activate.sh
```

### Before Committing
```bash
# See what changed
./scripts/maintenance/config-diff.sh

# Validate configs
./scripts/validation/validate-machine-config.sh
./scripts/validation/audit-permissions.sh

# Commit
git add <files>
git commit -m "Description"
```

---

## 🎯 Script Dependencies

**All scripts are location-independent:**
- Use `$SCRIPT_DIR` and `$CONFIG_ROOT`
- Work regardless of installation path
- Safe to move the entire directory

**No external dependencies except:**
- `cleanup.sh` → Requires nix/darwin-rebuild
- `config-diff.sh` → Requires git
- `install-apps.sh` → Requires Homebrew
- `bootstrap.sh` → Requires Nix (installs nix-darwin)

---

## 💡 Tips

1. **Add aliases** in your `.zshrc`:
   ```bash
   alias health="~/.nix-darwin-minimal/scripts/maintenance/health-check.sh"
   alias nix-cleanup="~/.nix-darwin-minimal/scripts/maintenance/cleanup.sh"
   alias install-app="~/.nix-darwin-minimal/scripts/app-catalog/install-apps.sh"
   ```

2. **Make scripts executable** (already done):
   ```bash
   chmod +x scripts/**/*.sh
   ```

3. **Customize workspace scripts** for your needs:
   - Edit `backup.sh` to include your important files
   - Edit `restore.sh` to restore them

4. **Use pre-flight checks** before rebuilds:
   ```bash
   ./scripts/maintenance/pre-flight-checks.sh && darwin-rebuild switch --flake .
   ```

---

## 📚 See Also

- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - 5-minute setup guide
- [.gitignore](.gitignore) - What's gitignored

---

*All scripts use `set -euo pipefail` for safety and reliability*
