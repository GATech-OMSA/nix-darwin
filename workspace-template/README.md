# Workspace Template

This is a template directory for machine-specific workspace data. During setup, this directory will be copied to `workspace/${machineId}/`.

## What is Workspace?

Your **workspace** contains machine-specific data that persists across nix-darwin rebuilds:
- Application configurations and settings
- User-generated content (notebooks, snippets, custom configs)
- Machine state (SSH known hosts, navigation history)
- Backup and restore scripts

This data is **gitignored** for privacy and machine-specific to your hardware.

## Structure

```
workspace/${machineId}/
├── app-configs/          # Application configs (Claude, Continue, Cursor, etc.)
├── user-content/         # User-specific content
│   ├── claude/          # Claude Code user content
│   ├── jupyter/         # Jupyter notebooks
│   ├── karabiner/       # Karabiner keyboard config
│   ├── vscode/          # VS Code settings
│   └── vscode-snippets/ # VS Code snippets
├── backup.sh            # Backup script for this machine
├── restore.sh           # Restore script for this machine
├── ssh_known_hosts      # SSH known hosts
└── zoxide_database      # Zoxide navigation database
```

## Setup

The `configure.sh` script will:
1. Copy this template to `workspace/${machineId}/`
2. Configure shell functions to reference the machine-specific directory
3. Machine ID comes from `config/machine-config.nix`

## Backup & Restore

Shell functions for managing workspace data:
- `backup-workspace()` - Save current workspace state
- `restore-workspace()` - Restore workspace from backup
- `sync-workspace()` - Sync workspace data

These use the `machineId` from your Nix configuration to locate the correct workspace directory.

## Migration

If you have an old `user-data-${username}/` directory, the migration happens automatically during `configure.sh`.

## Git Tracking

- Template directory (`workspace-template/`): **Tracked** in git
- Machine-specific directories (`workspace/*/`): **Gitignored**

## Notes

- Each machine has its own `workspace/${machineId}/` directory
- Machine ID is stable even if hostname or username changes
- Supports machine replacement tracking (e.g., macbook-pro-m1-2021 → macbook-pro-m1-2024)
- Workspace is machine-specific, not user-specific
