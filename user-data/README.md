# User Data Backup & Restore

This directory contains **non-secret user data** that cannot be managed declaratively by Nix. These are typically large application configs, user-generated content, and preferences that are too personal or too large to commit to git.

## Overview

**Two-Tier Backup Strategy:**
1. **Secrets** (managed by sops-nix) - Encrypted in git, auto-restored
2. **User Data** (this directory) - Git-ignored, manually backed up/restored

## What's Backed Up Here

### App Configs
- **Claude Code** - `~/.claude.json`
- **Continue.dev** - `~/.continue/config.json`, `~/.continue/config.ts`
- **Gemini** - `~/.gemini/settings.json`
- **iTerm2** - Preferences plist

### User Content
- **VS Code** - Custom snippets
- **Jupyter** - Custom configs (jupyter_lab_config.py, jupyter_notebook_config.py)
- **IPython** - Custom config (ipython_config.py)

### Other
- **SSH** - known_hosts (not secret, but useful)

## Usage

### Backup (Old Machine)

```bash
cd ~/nix-darwin/user-data
./backup.sh
```

This creates:
```
user-data/
├── app-configs/
│   ├── claude.json
│   ├── continue/
│   ├── gemini/
│   └── iterm2/
├── user-content/
│   ├── vscode-snippets/
│   ├── jupyter/
│   └── ipython/
└── ssh_known_hosts
```

**Then copy to external storage:**
```bash
# To external drive
cp -r ~/nix-darwin/user-data /Volumes/ExternalDrive/nix-darwin-userdata-backup

# Or to cloud (after ensuring no secrets)
# zip -r userdata-backup.zip user-data/
```

### Restore (New Machine)

1. **Clone nix-darwin repo:**
   ```bash
   git clone <your-nix-darwin-repo> ~/nix-darwin
   ```

2. **Copy user-data/ from backup:**
   ```bash
   # From external drive
   cp -r /Volumes/ExternalDrive/nix-darwin-userdata-backup/* ~/nix-darwin/user-data/

   # Or extract from zip
   # unzip userdata-backup.zip -d ~/nix-darwin/
   ```

3. **Run restore:**
   ```bash
   cd ~/nix-darwin/user-data
   ./restore.sh
   ```

4. **Build nix-darwin:**
   ```bash
   cd ~/nix-darwin
   # First-time setup (see docs/getting-started/installation.md)
   sudo nix run nix-darwin -- switch --flake .#mbp-jimmy
   ```

   This automatically restores encrypted secrets via sops-nix!

## Helper Functions

After rebuilding with zsh.nix, use these shortcuts:

```bash
backup-user-data    # Run backup.sh
restore-user-data   # Run restore.sh
```

## What's NOT Here

These are managed elsewhere:

| Data | Where | How |
|------|-------|-----|
| **API Keys, SSH keys** | `hosts/*/secrets.yaml` | sops-nix (encrypted in git) |
| **AWS credentials** | `hosts/*/secrets.yaml` | sops-nix (encrypted in git) |
| **Git config** | `home/jimmy/programs/git.nix` | Declarative Nix config |
| **Zsh config** | `home/jimmy/shell/zsh.nix` | Declarative Nix config |
| **VS Code settings** | `home/jimmy/programs/vscode.nix` | Declarative Nix config |
| **Packages** | `modules/shared/packages.nix` | Declarative Nix config |
| **Homebrew apps** | `modules/darwin/homebrew.nix` | Declarative Nix config |

## Git Ignore

The `.gitignore` in this directory prevents backing up user data to git:
- Too large (VS Code snippets, etc.)
- Too personal (iTerm2 preferences with colors, etc.)
- Changes frequently

**Only these files are committed:**
- `.gitignore`
- `README.md` (this file)
- `backup.sh`
- `restore.sh`

## Complete New Machine Setup

Full workflow for setting up a new Mac from scratch:

1. **Install Nix** (see `docs/getting-started/installation.md`)
2. **Generate age key** (see `secrets/SETUP.md`)
3. **Clone nix-darwin repo** with your configs
4. **Copy user-data/ backup** to `~/nix-darwin/user-data/`
5. **Run initial build** (this decrypts secrets automatically)
6. **Run restore script** to restore non-secret user data
7. **Restart shell** and enjoy!

See `docs/guides/new-machine-setup.md` for detailed walkthrough.

## Maintenance

**When to backup:**
- Before major system upgrade
- After customizing Claude/Continue.dev configs
- After creating new VS Code snippets
- Monthly (if actively customizing)

**Storage recommendations:**
- **External Drive**: Time Machine backup or separate encrypted drive
- **Cloud**: Encrypt before uploading (contains preferences but not secrets)
- **NAS**: Keep alongside Time Machine backups

## See Also

- [Secrets Management Guide](../docs/guides/secrets-management.md) - For sops-nix encrypted secrets
- [New Machine Setup](../docs/guides/new-machine-setup.md) - Complete setup walkthrough
- [Architecture Overview](../docs/architecture/overview.md) - How everything fits together
