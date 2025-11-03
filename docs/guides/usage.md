# Usage Guide

**Daily workflows, configuration, and system maintenance**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Daily Workflows](#daily-workflows)
2. [Adding Packages](#adding-packages)
3. [Adding Aliases](#adding-aliases)
4. [Customizing Shell](#customizing-shell)
5. [Configuration Management](#configuration-management)
6. [Updates & Maintenance](#updates--maintenance)

---

## Daily Workflows

### Morning Routine

```bash
# Update everything
update-all

# Navigate to project
dev
cd my-main-project

# Check git status
g s

# Pull latest
g pl

# Check recent branches
g recent
```

### Git Workflow

**Starting new work:**
```bash
cd ~/Dev/my-project
g s
g co -b feature/new-feature  # Create branch
# ... make changes ...
g aa
g cm "Add feature"
g ps
```

**Review before push:**
```bash
g review  # See what you're pushing
g today   # Today's commits
g ps      # Push
```

**Branch management:**
```bash
g recent      # Recent branches
g bclean      # Delete merged branches
g sync        # Sync with upstream
```

### Python Development

**New project:**
```bash
dev
uv-new my-api
cd my-api
# 🐍 Activated UV virtual environment: .venv

uv-add fastapi uvicorn
vs
```

**Existing project:**
```bash
cd ~/Dev/my-project
# Auto-activates venv
uv-add requests
python main.py
test  # Run pytest
lint  # Run ruff
```

### Code Editing

**VS Code shortcuts:**
```bash
vs                # Open current directory
code README.md    # Open specific file

# Inside VS Code:
# Cmd+P - Quick open file
# Cmd+Shift+P - Command palette
# Cmd+J - Toggle terminal
```

### End of Day

```bash
cd ~/Dev/my-project
g d        # Review changes
g aa
g cm "Implement feature X"
g ps
g today   # Review today's work
g bclean  # Clean merged branches
```

---

## Adding Packages

### CLI Package via Nix

**1. Search for package:**
```bash
nix search nixpkgs ripgrep
```

**2. Edit packages.nix:**
```bash
nixconf
# Navigate to modules/shared/packages.nix
```

```nix
environment.systemPackages = with pkgs; [
  # Existing packages...
  ripgrep      # Add your package
];
```

**3. Rebuild:**
```bash
nix-rebuild
```

**4. Verify:**
```bash
which ripgrep
ripgrep --version
```

**5. Commit:**
```bash
g aa && g cm "Add ripgrep package" && g ps
```

### GUI App via Homebrew

**1. Find cask:**
```bash
brew search visual-studio-code
```

**2. Edit homebrew.nix:**
```bash
nixconf
# Navigate to modules/darwin/homebrew.nix
```

```nix
homebrew.casks = [
  # Existing casks...
  "visual-studio-code"
];
```

**3. Rebuild:**
```bash
nix-rebuild
```

### Quick Install (Then Track)

```bash
# Install immediately
brew install --cask brave-browser

# Test it

# Add to config to track
nixconf
# Add "brave-browser" to homebrew.nix

nix-rebuild
g aa && g cm "Track brave-browser" && g ps
```

### Remove Package

```bash
nixconf
# Comment out or remove package
nix-rebuild

# Clean up (optional)
nix-collect-garbage -d
```

---

## Adding Aliases

### Simple Shell Alias

**1. Edit zsh.nix:**
```bash
zshconf
```

**2. Add alias:**
```nix
home.shellAliases = {
  weather = "curl wttr.in";
  myip = "curl ifconfig.me";
};
```

**3. Rebuild and restart:**
```bash
nix-rebuild
exec zsh
```

**4. Test:**
```bash
weather
```

**5. Commit:**
```bash
g aa && g cm "Add weather alias" && g ps
```

### Git Alias

**1. Edit git.nix:**
```bash
gitconf
```

**2. Add alias:**
```nix
programs.git.aliases = {
  quickcommit = "commit -am";
  pushforce = "push --force-with-lease";
};
```

**3. Rebuild:**
```bash
nix-rebuild
```

**4. Test (use with `g` prefix):**
```bash
g quickcommit "Quick change"
```

### Custom Function

**1. Edit zsh.nix:**
```bash
zshconf
```

**2. Add function in initExtra:**
```nix
programs.zsh.initExtra = ''
  mkcd() {
    mkdir -p "$1" && cd "$1"
  }

  backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
  }
'';
```

**3. Rebuild and restart:**
```bash
nix-rebuild
exec zsh
```

**4. Test:**
```bash
mkcd ~/Dev/new-project
```

### Machine-Specific Alias

**Personal only** (`home/_mixins/personal.nix`):
```nix
home.shellAliases = {
  blog = "cd ~/Dev/my-blog";
};
```

**Work only** (`home/_mixins/work.nix`):
```nix
home.shellAliases = {
  monorepo = "cd ~/Dev/work-monorepo";
  vpn = "sudo openconnect vpn.company.com";
};
```

---

## Customizing Shell

### Customize Prompt (Starship)

**Edit `home/_mixins/base.nix`:**

```nix
programs.starship.settings = {
  character = {
    success_symbol = "[→](bold green)";
    error_symbol = "[→](bold red)";
  };

  directory = {
    style = "bold cyan";
    truncation_length = 3;
  };

  # Disable module
  nodejs.disabled = true;
};
```

```bash
nix-rebuild
exec zsh
```

### Environment Variables

**Edit `home/jimmy/shell/zsh.nix`:**

```nix
home.sessionVariables = {
  EDITOR = "code --wait";
  MY_VAR = "value";
};

home.sessionPath = [
  "$HOME/bin"
  "$HOME/.local/bin"
];
```

### Zsh Options

```nix
programs.zsh.initExtra = ''
  # Auto cd when typing directory name
  setopt AUTO_CD

  # Don't record duplicates in history
  setopt HIST_IGNORE_DUPS

  # Share history between terminals
  setopt SHARE_HISTORY

  # Correct typos
  setopt CORRECT
'';
```

### Key Bindings

```nix
programs.zsh.initExtra = ''
  # Ctrl+Left/Right for word navigation
  bindkey '^[[1;5D' backward-word
  bindkey '^[[1;5C' forward-word

  # Home/End keys
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
'';
```

### fzf Customization

```nix
home.sessionVariables = {
  FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";
};

programs.zsh.initExtra = ''
  # Use ripgrep for fzf
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
'';
```

---

## Configuration Management

### Quick Config Access

```bash
nixconf        # Open nix-darwin folder
gitconf        # Edit git.nix
zshconf        # Edit zsh.nix
vscodeconf     # Edit vscode.nix
awsconf        # Edit AWS config
```

### Key Files to Edit

| Want to... | Edit file |
|------------|-----------|
| Add system package | `modules/shared/packages.nix` |
| Add GUI app | `modules/darwin/homebrew.nix` |
| Add shell alias | `home/jimmy/shell/zsh.nix` |
| Add git alias | `home/jimmy/programs/git.nix` |
| Configure VS Code | `home/jimmy/programs/vscode.nix` |
| Change Python setup | `home/jimmy/development/python.nix` |
| Add personal setting | `home/_mixins/personal.nix` |
| Add work setting | `home/_mixins/work.nix` |

### Standard Workflow

```bash
# 1. Edit config
nixconf

# 2. Rebuild
nix-rebuild

# 3. Restart shell (if needed)
exec zsh

# 4. Test

# 5. Commit
g aa
g cm "Description"
g ps
```

### Validation

```bash
# Check flake syntax
nix flake check

# Dry run
darwin-rebuild build --flake . --dry-run
```

### Git Configuration

**Shared** (`home/jimmy/programs/git.nix`):
```nix
programs.git = {
  userName = "Your Name";
  userEmail = "your@email.com";
};
```

**Machine-specific** (`home/_mixins/personal.nix` or `work.nix`):
```nix
programs.git = {
  userEmail = "work@company.com";  # Override for work
};
```

### VS Code Settings

**Edit `home/jimmy/programs/vscode.nix`:**

```nix
programs.vscode.userSettings = {
  "editor.fontSize" = 14;
  "editor.tabSize" = 2;
  "workbench.colorTheme" = "Vitesse Dark";
};
```

---

## Updates & Maintenance

### Quick Updates

```bash
# Daily: Update Nix only (fast)
update-nix

# Weekly: Update everything
update-all
```

### What update-all Does

1. Updates Nix flake inputs
2. Rebuilds system with new packages
3. Updates Homebrew packages and casks
4. Updates Micromamba packages
5. Updates VS Code extensions

**Time:** ~5-15 minutes

### Selective Updates

**Nix only:**
```bash
update-nix
# Or manually:
cd ~/nix-darwin
nix flake update
darwin-rebuild switch --flake .
```

**Homebrew only:**
```bash
update-brew
# Or manually:
brew update
brew upgrade
brew upgrade --cask
```

**Python packages:**
```bash
# UV projects (per-project)
cd ~/Dev/my-project
uv lock --upgrade
uv sync

# Micromamba (base environment)
base
micromamba update --all -y
```

### After Updates

```bash
# Restart shell
exec zsh

# Verify changes
nix-env -q
python --version
g s

# Clean up (optional)
nix-clean
```

### Update Frequency

| Component | Frequency | Command |
|-----------|-----------|---------|
| **Nix packages** | Daily or Weekly | `update-nix` |
| **All systems** | Weekly | `update-all` |
| **Homebrew** | Weekly | `update-brew` |
| **Python (project)** | As needed | `uv lock --upgrade` |

### Rollback

```bash
# Rollback to previous generation
nix-rollback

# Restart shell
exec zsh

# View generations
darwin-rebuild --list-generations

# Switch to specific generation
sudo darwin-rebuild switch --switch-generation 10
```

### Cleanup

**Tier-Based Cleanup System:**

```bash
# Daily/weekly maintenance
cleanup-quick        # or: clean

# Regular maintenance (recommended)
cleanup              # Standard cleanup (default)

# For active developers
cleanup-dev          # Clean dev artifacts

# Maximum cleanup (with confirmations)
cleanup-aggressive   # or: cleanup-all

# Always preview first with dry-run
cleanup-aggressive --dry-run
```

**Tool-Specific Cleanup:**

```bash
# Clean specific tools
cleanup-nix --keep=3      # Nix generations
cleanup-docker --volumes  # Docker (including volumes)
cleanup-python            # Python/UV caches
cleanup-git               # Git repositories
cleanup-terraform         # Terraform directories
```

**See full documentation:** [Shell Reference - Cleanup Functions](../reference/shell.md#cleanup-functions)

---

## Best Practices

### 1. Commit Before Major Changes

```bash
g aa
g cm "Working config $(date)"
g ps
# Then experiment
```

### 2. Test in Stages

```bash
# Change 1 thing
nix-rebuild
# Test
# Commit

# Change next thing
# Repeat
```

### 3. Use Comments

```nix
home.shellAliases = {
  # Added 2024-01-15: Quick weather check
  weather = "curl wttr.in";
};
```

### 4. Keep Secrets Out

**NEVER commit:**
- AWS credentials
- API keys
- Passwords

Use `~/.zsh_secrets` instead.

### 5. Group Related Config

```nix
environment.systemPackages = with pkgs; [
  # Git tools
  git
  gh
  git-lfs

  # Python tools
  python311
  uv

  # Modern CLI
  bat
  eza
  ripgrep
];
```

### 6. Machine-Specific in Mixins

```nix
# ✅ Good: Work alias in work.nix
# home/_mixins/work.nix
home.shellAliases = {
  vpn = "sudo openconnect vpn.company.com";
};

# ❌ Bad: Work alias in shared zsh.nix
```

---

## Common Workflows

### Start New Feature

```bash
cd ~/Dev/my-project
g pl
g cob feature/new-feature
vs
# ... work on feature ...
g aa && g cm "Implement new feature" && g ps
```

### Fix Bug

```bash
cd ~/Dev/my-project
g co main
g pl
g cob hotfix/bug-123
# ... fix bug ...
test
g aa && g cm "Fix bug #123" && g ps
```

### Add Dependency

```bash
cd ~/Dev/python-project
uv-add requests
# ... use in code ...
g aa && g cm "Add requests dependency" && g ps
```

### Deploy Changes

```bash
cd ~/Dev/my-app
test
lint
g aa && g cm "Release v1.2.0" && g tag v1.2.0 && g ps --tags
```

---

## Troubleshooting

### Changes Not Applied

```bash
nix-rebuild
exec zsh
```

### Command Not Found

```bash
# Rebuild and restart
nix-rebuild
exec zsh

# Check if package installed
which command
```

### Build Errors

```bash
# Show detailed errors
darwin-rebuild switch --flake . --show-trace

# Check flake
nix flake check

# Rollback if needed
nix-rollback
```

---

## Quick Reference

### System Commands

```bash
nix-rebuild      # Rebuild after changes
nix-rollback     # Undo last rebuild
nix-clean        # Clean old generations
update-all       # Update everything
update-nix       # Update Nix only
```

### Git Commands

```bash
g s              # Status
g aa             # Add all
g cm "msg"       # Commit
g ps             # Push
g pl             # Pull
g recent         # Recent branches
g today          # Today's commits
```

### Config Shortcuts

```bash
nixconf          # Open nix-darwin
gitconf          # Edit git.nix
zshconf          # Edit zsh.nix
vscodeconf       # Edit vscode.nix
```

### Python Commands

```bash
uv-new name      # New UV project
uv-add pkg       # Add dependency
test             # Run tests
lint             # Lint code
format           # Format code
base             # Activate base env
```

---

## Next Steps

- **[Backup & Recovery](backup-and-recovery.md)** - Protect your system
- **[Secrets Management](secrets.md)** - Handle sensitive data
- **[Learning Guide](learning.md)** - Master modern CLI tools
- **[Troubleshooting](troubleshooting.md)** - Fix common issues

---
