# User Data Backup & Restore

This directory contains **non-secret user data** that cannot be managed declaratively by Nix. These configs are backed up to git and synced across machines.

## Overview

**Two-Tier Backup Strategy:**
1. **Secrets** (managed by sops-nix) - Encrypted in git, auto-restored
2. **User Data** (this directory) - Version controlled in git, synced with `sync-user-data`

## What's Backed Up Here

### App Configs
- **Claude Code** - `~/.claude.json`
- **Continue.dev** - `~/.continue/config.json`, `~/.continue/config.ts`
- **Gemini** - `~/.gemini/settings.json`
- **iTerm2** - Preferences plist
- **Cursor** - `~/.cursor/argv.json`, `~/.cursor/cli-config.json`
- **Docker** - `~/.docker/config.json` (user preferences, NOT daemon settings)

### User Content
- **VS Code** - settings.json, argv.json, snippets, spell dictionary
- **Jupyter** - Custom configs (jupyter_lab_config.py, jupyter_notebook_config.py)
- **IPython** - Custom config (ipython_config.py)
- **Claude** - todos (projects excluded - too large)

### Other
- **SSH** - known_hosts (not secret, but useful)
- **Zoxide** - Directory navigation database

## Usage

### Daily Workflow

**After making changes to VS Code settings or other configs:**

```bash
sync-user-data  # Backup + commit + push (one command)
```

This automatically:
1. Backs up all configs to `user-data/`
2. Commits changes to git
3. Pushes to remote repository

### Manual Backup

```bash
backup-user-data  # Run backup.sh manually
```

This creates/updates:
```
user-data/
├── app-configs/
│   ├── claude.json
│   ├── continue/
│   ├── gemini/
│   ├── iterm2/
│   ├── cursor/
│   └── docker/
├── user-content/
│   ├── vscode/
│   │   ├── settings.json
│   │   ├── argv.json
│   │   ├── snippets/
│   │   └── spell-dictionary.txt
│   ├── jupyter/
│   └── ipython/
└── ssh_known_hosts
```

### Restore (New Machine)

1. **Clone nix-darwin repo:**
   ```bash
   git clone <your-nix-darwin-repo> ~/nix-darwin
   cd ~/nix-darwin
   ```

2. **User data is already included** in the git repo (no need to copy from external drive)

3. **Run restore:**
   ```bash
   restore-user-data
   ```

4. **Build nix-darwin:**
   ```bash
   # First-time setup (see docs/guides/installation.md)
   sudo nix run nix-darwin -- switch --flake .#mbp-jimmy
   ```

   This automatically restores encrypted secrets via sops-nix!

## Helper Functions

After rebuilding with zsh.nix, use these shortcuts:

```bash
backup-user-data    # Backup configs to user-data/
restore-user-data   # Restore configs from user-data/
sync-user-data      # Backup + commit + push (recommended)
```

**Typical workflow:**
```bash
# Edit VS Code settings in UI (Cmd+,)
sync-user-data      # One command to backup and sync to git
```

## What's NOT Here

These are managed elsewhere:

| Data | Where | How |
|------|-------|-----|
| **API Keys, SSH keys** | `hosts/*/secrets.yaml` | sops-nix (encrypted in git) |
| **AWS credentials** | `hosts/*/secrets.yaml` | sops-nix (encrypted in git) |
| **Git config** | `home/jimmy/programs/git.nix` | Declarative Nix config |
| **Zsh config** | `home/jimmy/shell/zsh.nix` | Declarative Nix config |
| **VS Code extensions** | `home/jimmy/programs/vscode.nix` | Declarative Nix config |
| **Packages** | `modules/shared/packages.nix` | Declarative Nix config |
| **Homebrew apps** | `modules/darwin/homebrew.nix` | Declarative Nix config |

## Version Control

**All user-data is now version controlled in git** for easy sync across machines.

The `.gitignore` in this directory excludes very large or machine-specific files:
- VS Code projects cache
- Temporary files
- Machine-specific metadata

**Committed to git:**
- Scripts: `backup.sh`, `restore.sh`
- Documentation: `README.md`, `.gitignore`
- **All backed up configs**: VS Code settings, app configs, user content
- Synced automatically via `sync-user-data` command

## Complete New Machine Setup

Full workflow for setting up a new Mac from scratch:

1. **Install Nix** (see `docs/guides/installation.md`)
2. **Generate age key** (see `secrets/SETUP.md`)
3. **Clone nix-darwin repo** (includes user-data in git)
4. **Run initial build** (decrypts secrets automatically)
5. **Run restore-user-data** (restores configs to system)
6. **Restart shell** and enjoy!

See `docs/guides/installation.md` for detailed walkthrough.

## Maintenance

**When to sync:**
- After changing VS Code settings
- After customizing Claude/Continue.dev configs
- After creating new VS Code snippets
- After modifying any backed up config

**Workflow:**
```bash
sync-user-data  # One command: backup + commit + push
```

**Additional backup recommendations:**
- Git repository serves as primary backup (synced to remote)
- Optional: External Time Machine backup for complete system restore
- Optional: Cloud backup of entire nix-darwin repo (no secrets to worry about - encrypted via sops)

## See Also

- [Secrets Guide](../docs/guides/secrets.md) - For sops-nix encrypted secrets
- [Installation Guide](../docs/guides/installation.md) - Complete setup walkthrough
- [Backup & Recovery Guide](../docs/guides/backup-and-recovery.md) - Complete backup strategy
- [Architecture Overview](../docs/architecture/overview.md) - How everything fits together
