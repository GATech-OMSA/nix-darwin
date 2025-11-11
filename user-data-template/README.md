# User Data Template

This is a template directory for user-specific data. During setup, this directory will be copied to `user-data-${username}/`.

## Structure

```
user-data-${username}/
├── app-configs/          # Application configs (Claude, Continue, Cursor, etc.)
├── user-content/         # User-specific content
│   ├── claude/          # Claude Code user content
│   ├── jupyter/         # Jupyter notebooks
│   ├── karabiner/       # Karabiner keyboard config
│   ├── vscode/          # VS Code settings
│   └── vscode-snippets/ # VS Code snippets
├── backup.sh            # Backup script (auto-detects username)
├── restore.sh           # Restore script (auto-detects username)
├── ssh_known_hosts      # SSH known hosts
└── zoxide_database      # Zoxide navigation database
```

## Setup

The `setup.sh` script will:
1. Copy this template to `user-data-${username}/`
2. Update scripts to use the correct username
3. Configure Nix to reference the user-specific directory

## Backup & Restore

The `backup.sh` and `restore.sh` scripts automatically detect the username from the directory name pattern (`user-data-${username}`).

## Git Tracking

- Template directory: **Tracked** in git
- User-specific directories (`user-data-*/`): **Gitignored**

## Notes

- Each user on the same machine will have their own `user-data-${username}/` directory
- The template ensures consistent structure across users
- User-specific settings and credentials stay in gitignored directories
