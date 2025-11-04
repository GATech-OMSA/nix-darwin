# Quick Reference - Nix Darwin

**Print this and stick on your monitor!**

---

## Daily Commands

```bash
# System Management
nix-rebuild                      # Rebuild system
nix-rollback                     # Undo last rebuild
exec zsh                         # Restart shell
nix-health                       # Check system health

# Configuration
nixconf                          # Edit nix config
gitconf                          # Edit git config
zshconf                          # Edit zsh config
vscodeconf                       # Edit VS Code config
awsconf                          # Edit AWS config

# Quick Opens
vs                               # Open VS Code here
f                                # Open Finder here
```

---

## App Launchers

```bash
# AI/LLM
claude                           # Open Claude
gpt                              # Open ChatGPT
pplx                             # Open Perplexity
obs                              # Open Obsidian

# Development
cursor                           # Open Cursor
cur                              # Open Cursor (short)

# Browsers
ff                               # Open Firefox
orion                            # Open Orion

# Communication
zoom                             # Open Zoom
wa                               # Open WhatsApp

# Other
tv                               # Open TradingView
vpn                              # Open ProtonVPN
pdf                              # Open PDF Expert
shot                             # Open Shottr
alfred                           # Open Alfred
```

---

## Workflow Helpers

```bash
show file.txt                    # Reveal in Finder
ql image.png                     # Quick Look preview
cat file.txt | copy              # Copy to clipboard
paste                            # Paste from clipboard
port 3000                        # Check what's on port
killport 3000                    # Kill process on port
newproj myapp                    # Create project + open VS Code
```

---

## File Operations (Modern CLI)

```bash
# Listing
ll                               # List files (eza with icons)
la                               # List all including hidden
lt                               # Tree view
ls                               # Basic list with icons

# Viewing
bat file.txt                     # View with syntax highlighting
cat file.txt                     # Same as bat (aliased)

# Searching
rg "pattern"                     # Search in files (ripgrep)
rg "pattern" -t py               # Search only Python files
rg -i "pattern"                  # Case insensitive

# Finding
fd filename                      # Find files
fd -e js                         # Find JavaScript files
fd -t d dirname                  # Find directories only
```

---

## Navigation

```bash
# Smart Navigation
z project                        # Jump to frecent directory
z -                              # Jump back
zi                               # Interactive directory select

# Fuzzy Finding
Ctrl+R                           # Search command history (fzf)
Ctrl+T                           # Find files (fzf)
Alt+C                            # Find and cd to directory (fzf)
```

---

## Git (with `g` prefix)

```bash
# Status & Info
g s                              # Status (short)
g l                              # Log (oneline)
g d                              # Diff (with delta)

# Common Operations
g a file                         # Add file
g aa                             # Add all
g c "msg"                        # Commit with message
g cm "msg"                       # Commit with message (alias)
g p                              # Push
g pl                             # Pull
g f                              # Fetch

# Branching
g co branch                      # Checkout branch
g cob name                       # Create & checkout branch
g b                              # List branches
g recent                         # Recent branches

# Undo/Cleanup
g undo                           # Undo last commit (keep changes)
g unstage                        # Unstage files
g cleanup                        # Delete merged branches
```

---

## Python

```bash
# Environment Info
pyenv-info                       # Show Python setup
python --version                 # System Python version

# UV (Project Management)
uv-new project-name              # Create new project with venv
uv-add package                   # Add dependency

# Micromamba (Data Science)
micromamba activate env          # Activate environment
micromamba create -n name        # Create environment
micromamba list                  # List packages
```

---

## AWS

```bash
# Personal Mac (IAM)
aws <command>                    # Uses personal profile

# Work Mac (SSO)
awslogin                         # Login to AWS SSO
awswho                           # Check current session
awslist                          # List all profiles
awsuse profile-name              # Switch profile
awscheck                         # Check all profile status
```

---

## Docker

```bash
# Docker Compose
dcu                              # docker compose up
dcd                              # docker compose down
dcr                              # docker compose restart
dcl                              # docker compose logs
dcb                              # docker compose build

# Docker
dps                              # docker ps
di                               # docker images
dprune                           # Prune system
```

---

## Kubernetes

```bash
# kubectl (k alias)
k get pods                       # List pods
k get svc                        # List services
k logs pod-name                  # View logs
k exec -it pod sh                # Shell into pod

# k9s
k9s                              # Interactive K8s UI
```

---

## System Utilities

```bash
# Information
sysinfo                          # System information
disk-usage                       # Show disk usage (dust)
duf                              # Disk usage by filesystem

# Process Management
btop                             # Better top
kill-port 3000                   # Kill process on port

# Cleanup (Tier-Based System)
cleanup-safe                     # Safest cleanup (no confirmations)
cleanup-quick                    # Quick daily cleanup (alias: clean)
cleanup                          # Standard cleanup (default)
cleanup-dev                      # Development-focused cleanup
cleanup-aggressive               # Maximum cleanup (alias: cleanup-all)

# Tool-Specific Cleanup
cleanup-nix [--keep=5]           # Nix-specific cleanup
cleanup-docker [--volumes]       # Docker cleanup
cleanup-python                   # Python/UV cache cleanup
cleanup-git [--dir=~/Dev]        # Git repository optimization
cleanup-aws                      # AWS cache cleanup
cleanup-terraform                # Terraform .terraform cleanup
cleanup-macos                    # macOS-specific cleanup

# Common Flags
--dry-run                        # Preview without executing
--yes / -y                       # Skip confirmations
--help / -h                      # Show help
```

---

## Backup & Secrets

```bash
# Backup
backup-user-data                 # Backup non-secret configs
restore-user-data                # Restore configs

# Secrets
edit-secrets                     # Edit encrypted secrets
secrets-status                   # Check secrets setup
```

---

## Updates

```bash
# Quick Updates
update-dev                       # Update dev tools (UV, VS Code)
update-nix                       # Update Nix packages
update-brew                      # Update Homebrew

# Complete Update
update-all                       # Update everything
```

---

## Emergency Procedures

```bash
# Build Failed
nix-rollback                     # Rollback immediately
darwin-rebuild --list-generations # See available generations

# System Issues
nix-health                       # Run health check
exec zsh                         # Restart shell

# Recovery
darwin-rebuild rollback          # Full rollback
darwin-rebuild --switch-generation N # Rollback to specific gen
```

---

## Keyboard Shortcuts (iTerm2)

```bash
# Tabs
⌘+T                              # New tab
⌘+W                              # Close tab
⌘+1-9                            # Jump to tab

# Splits
⌘+D                              # Split vertical
⌘+Shift+D                        # Split horizontal
⌘+Opt+Arrow                      # Navigate splits

# Utilities
⌘+K                              # Clear screen
⌘+F                              # Find
⌘+/                              # Find cursor
```

---

## Shell Shortcuts

```bash
# Navigation
Ctrl+A                           # Start of line
Ctrl+E                           # End of line
Ctrl+U                           # Delete to start
Ctrl+K                           # Delete to end
Ctrl+W                           # Delete word

# History
Ctrl+R                           # Search history (fzf)
!!                               # Repeat last command
!$                               # Last argument
```

---

## Custom Keybindings (Hyper Key)

**Hyper Key = Caps Lock (hold) = Cmd+Opt+Ctrl+Shift**
**Tap Caps Lock = Escape**

### Window Management
```bash
# Snap to Halves
Hyper + Left                     # Snap left half
Hyper + Right                    # Snap right half
Hyper + Up                       # Snap top half
Hyper + Down                     # Snap bottom half

# Snap to Quarters
Hyper + 1                        # Top-left
Hyper + 2                        # Top-right
Hyper + 3                        # Bottom-left
Hyper + 4                        # Bottom-right

# Window Control
Hyper + F                        # Maximize
Hyper + C                        # Center window
```

### App Launching
```bash
Hyper + T                        # iTerm2
Hyper + B                        # Browser (Safari)
Hyper + V                        # VS Code
Hyper + M                        # Mail
Hyper + N                        # Notes
Hyper + S                        # Messages
Hyper + O                        # Obsidian
```

### Developer Shortcuts
```bash
Hyper + R                        # Reload/Refresh
Hyper + D                        # Developer Tools
Hyper + K                        # Force Quit dialog
Hyper + P                        # Command Palette
```

**Tip:** Practice 3-5 shortcuts per week. See [user-data/user-content/karabiner/README.md](../user-data/user-content/karabiner/README.md) for complete guide.

---

## Learning Resources

- **Complete docs:** [docs/index.md](index.md)
- **Start here:** [START-HERE.md](START-HERE.md)
- **Troubleshooting:** [guides/troubleshooting.md](guides/troubleshooting.md)
- **CLI learning:** [guides/learning.md](guides/learning.md)

---

**Remember:** All commands work immediately after `nix-rebuild`. If not found, run `exec zsh`!
