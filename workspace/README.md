# Workspace Directory

Machine-specific data that persists across nix-darwin rebuilds. Each machine has its own subdirectory.

## Structure

```
workspace/
├── .gitignore              # Ignores all machine directories
├── README.md               # This file
└── <machineId>/           # Per-machine workspace (gitignored)
    ├── app-configs/       # Application configurations
    ├── user-content/      # User-generated content
    ├── backups/           # Created by backup script
    └── ...                # Created automatically by backup.sh
```

## Usage

### Backup
```bash
backup-workspace           # Backs up to workspace/<machineId>/
```

### Restore
```bash
restore-workspace          # Restores from workspace/<machineId>/
```

### Sync
```bash
sync-workspace             # Backup + Commit + Push
```

## What Gets Backed Up

- **App configs**: Claude, Continue.dev, Gemini, iTerm2
- **User content**: VS Code snippets, Jupyter notebooks, Karabiner
- **System data**: SSH known_hosts, Zoxide database

## Implementation

Scripts are centralized in `scripts/workspace/`:
- `backup.sh <machineId>` - Creates/updates workspace/<machineId>/
- `restore.sh <machineId>` - Restores from workspace/<machineId>/

Shell functions automatically pass the machineId from `config/machine-config.nix`.

## Git Tracking

- **Directory structure**: Tracked (this README, .gitignore)
- **Machine data**: Gitignored (workspace/*/), private and machine-specific
- **Scripts**: Tracked (scripts/workspace/*.sh), shared across machines

## Machine ID

The machineId comes from `config/machine-config.nix` and persists across hostname or username changes.

## Initial Setup

During `configure.sh`, the workspace directory is created with:

1. **Directory Creation**: `workspace/<machineId>/` is created
2. **Age Key Backup**: SOPS age key is backed up to `workspace/<machineId>/backups/age-key-YYYYMMDD-HHMMSS.txt`
3. **Application Data**: Run `backup-workspace` to populate with application configs and user content

The backup script automatically creates all subdirectories (app-configs/, user-content/, etc.) on first run.

## Age Key Security

**Critical**: Age keys are backed up to `workspace/<machineId>/backups/` during setup:
- Backup filename: `age-key-YYYYMMDD-HHMMSS.txt`
- Permissions: `600` (owner read/write only)
- Location is gitignored (private to this machine)
- **Save externally**: Copy entire workspace directory to external drive or cloud storage before machine replacement
