# Learning Guide

**Modern CLI tools and multi-machine setup mastery**

[← Back to Index](../index.md)

---

## Table of Contents

1. [Part 1: Modern CLI Tools Learning Path](#part-1-modern-cli-tools-learning-path)
2. [Part 2: Multi-Machine Setup](#part-2-multi-machine-setup)

---

## Part 1: Modern CLI Tools Learning Path

### Week-by-Week Learning Plan

This configuration includes many modern CLI replacements. Learn them gradually!

### Week 1: Navigation & File Viewing

**Learn:** `eza` (better ls), `bat` (better cat), `z` (jump to directories)

**Day 1-2: eza (ls replacement)**

```bash
# Basic usage
ll              # List with details
la              # List all (including hidden)
lt              # Tree view
eza --help      # See all options

# Practice
ll ~/Dev
la ~/.config
lt -L 2         # Tree 2 levels deep
```

**Day 3-4: bat (cat replacement)**

```bash
# Syntax highlighted cat
bat README.md
bat -n file.py      # With line numbers
bat -A file.txt     # Show all characters

# Practice
bat ~/.zshrc
bat --language python script.py
```

**Day 5-7: z (autojump)**

```bash
# After visiting directories, jump to them
cd ~/Dev/my-project
cd ~/Documents
cd ~

# Now jump
z my-proj       # Jumps to ~/Dev/my-project
z Doc           # Jumps to ~/Documents

# Practice: Visit your common directories
# Then use z to jump around
```

### Week 2: Search & Find

**Learn:** `ripgrep` (better grep), `fd` (better find), `fzf` (fuzzy finder)

**Day 1-3: ripgrep (grep replacement)**

```bash
# Fast code search
rg "TODO"                 # Find in current directory
rg -i "function"          # Case insensitive
rg "error" --type py      # Only Python files
rg "api_key" -g '*.yaml'  # Specific file pattern

# Practice
cd ~/Dev/my-project
rg "function"
rg "import" --type py
```

**Day 4-5: fd (find replacement)**

```bash
# Fast file finding
fd README               # Find files named README
fd -e py                # Find all .py files
fd -H config            # Include hidden files
fd -t d project         # Find directories

# Practice
fd .nix ~/nix-darwin
fd -e md docs/
```

**Day 6-7: fzf (fuzzy finder)**

```bash
# Interactive fuzzy search
Ctrl+R          # Search command history
Ctrl+T          # Find files
Alt+C           # Change directory

# In commands
code $(fzf)     # Open file in VS Code
cd $(fd -t d | fzf)  # Change to directory

# Practice
# Press Ctrl+R and type partial command
# Press Ctrl+T and type partial filename
```

### Week 3: System Monitoring

**Learn:** `btop` (better top), `duf` (better df), `dust` (better du)

**Day 1-3: btop (top replacement)**

```bash
btop            # Interactive process viewer

# Inside btop:
# - Arrow keys: Navigate
# - F2: Options
# - q: Quit

# Practice
btop
# Watch CPU, memory, processes
```

**Day 4-5: duf (df replacement)**

```bash
# Disk usage with colors
duf             # Show all filesystems

# Practice
duf
# Observe your disk space visually
```

**Day 6-7: dust (du replacement)**

```bash
# Directory sizes
dust            # Current directory sizes
dust ~          # Home directory
dust -d 2 ~/Dev # Max depth 2

# Practice
dust ~/Dev
dust ~/.config
```

### Week 4: Git Workflow

**Learn:** Git with `g` prefix, interactive commands

**Day 1-2: Basic Git with g**

```bash
g s             # Status (was: git status)
g d             # Diff
g aa            # Add all
g cm "msg"      # Commit
g ps            # Push

# Practice
cd ~/nix-darwin
g s
g d
```

**Day 3-4: Branch Management**

```bash
g recent        # Recent branches
g co main       # Checkout
g cob feat      # Create and checkout branch
g bclean        # Delete merged branches

# Practice
g recent
g cob test-branch
g s
g co main
g bclean
```

**Day 5-7: History & Review**

```bash
g l             # Pretty log
g today         # Today's commits
g review        # What you're about to push
g sync          # Sync with upstream

# Practice
g l
g today
g review
```

### Advanced Tools (Month 2+)

**When comfortable with basics:**

- **jq** - JSON processing
- **yq** - YAML processing
- **delta** - Better git diffs
- **procs** - Better ps
- **sd** - Better sed

---

## Part 2: Multi-Machine Setup

### Understanding Machine Configurations

This nix-darwin setup supports multiple machines from one repository.

### Architecture

```
Personal Mac (mbp-jimmy) ──┐
                            ├── Same Git Repo
Work Mac (mbp-work) ────────┘

Each uses different mixins:
- personal.nix
- work.nix
```

### Hostname-Based Configuration

**Hostname determines everything:**

```bash
hostname
# mbp-jimmy → personal.nix → MACHINE_MODE="home"
# mbp-work → work.nix → MACHINE_MODE="work"
```

### Setting Up Multiple Machines

**On Personal Mac:**

```bash
# 1. Set hostname
sudo scutil --set HostName mbp-jimmy

# 2. Clone repo
git clone <repo> ~/nix-darwin

# 3. Build for personal
cd ~/nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy

# 4. Subsequent rebuilds
nix-rebuild  # Auto-detects hostname
```

**On Work Mac:**

```bash
# 1. Set hostname
sudo scutil --set HostName mbp-work

# 2. Clone same repo
git clone <repo> ~/nix-darwin

# 3. Build for work
cd ~/nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-work

# 4. Subsequent rebuilds
nix-rebuild  # Auto-detects hostname
```

### Machine-Specific Configuration

**Personal Mac Only** (`home/_mixins/personal.nix`):

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };

  home.shellAliases = {
    blog = "cd ~/Dev/my-blog";
  };
}
```

**Work Mac Only** (`home/_mixins/work.nix`):

```nix
{
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "work-domain";
  };

  home.shellAliases = {
    vpn = "sudo openconnect vpn.company.com";
    monorepo = "cd ~/Dev/work-monorepo";
  };
}
```

### Syncing Changes Between Machines

**Workflow:**

```bash
# On Personal Mac
cd ~/nix-darwin
gitconf  # Add new git alias
nix-rebuild
g aa && g cm "Add new git alias" && g ps

# On Work Mac
cd ~/nix-darwin
g pl  # Pull changes
nix-rebuild
# New alias now available on work Mac!
```

**Best Practices:**

1. **Pull before editing:**

   ```bash
   cd ~/nix-darwin
   g pl  # Always pull first
   ```

2. **Commit frequently:**

   ```bash
   g aa
   g cm "Add custom alias"
   g ps
   ```

3. **Keep machine-specific in mixins:**
   - Shared → `home/jimmy/`
   - Personal → `home/_mixins/personal.nix`
   - Work → `home/_mixins/work.nix`

### Verification

**Check current machine:**

```bash
hostname          # mbp-jimmy or mbp-work
echo $MACHINE_MODE  # home or work
echo $AWS_PROFILE   # personal or work-domain
g config user.email  # Check git email
```

**Test machine-specific settings:**

```bash
# On personal Mac
echo $MACHINE_MODE  # home
blog                # personal alias works

# On work Mac
echo $MACHINE_MODE  # work
vpn                 # work alias works
```

### Common Pitfalls

**1. Wrong hostname:**

```bash
# Check hostname
hostname

# If wrong, set correct one
sudo scutil --set HostName mbp-jimmy
```

**2. Forgot to pull:**

```bash
# Before editing, always:
cd ~/nix-darwin
g pl
```

**3. Machine-specific in shared config:**

```nix
# Wrong: vpn alias in shared zsh.nix
# Right: vpn alias in work.nix
```

### Secrets Per Machine

**Personal secrets:**

```bash
sops hosts/mbp-jimmy/secrets.yaml
# Personal API keys, personal AWS
```

**Work secrets:**

```bash
sops hosts/mbp-work/secrets.yaml
# Work API keys, work AWS
```

---

## Practice Exercises

### Exercise 1: Learn eza

```bash
# Week 1, Day 1
ll ~/Dev
la ~/.config
lt ~/nix-darwin -L 2

# Create cheat sheet
cat > ~/cheat-eza.txt <<EOF
ll - list with details
la - list all
lt - tree view
EOF
```

### Exercise 2: Search with ripgrep

```bash
# Week 2, Day 1
cd ~/Dev/my-project
rg "TODO"
rg "function" --type py
rg "import" -g '*.py'

# Practice patterns
rg --help
```

### Exercise 3: Master fzf

```bash
# Week 2, Day 6
# Press Ctrl+R - search history for "git"
# Press Ctrl+T - find README files
# Press Alt+C - jump to Dev directory
```

### Exercise 4: Set Up Second Machine

```bash
# On new machine
sudo scutil --set HostName mbp-work
git clone <repo> ~/nix-darwin
cd ~/nix-darwin
sudo nix run nix-darwin -- switch --flake .#mbp-work
```

---

## Cheat Sheets

### Modern CLI Tools

```bash
# Navigation
ll                  # eza: list details
z project           # Jump to directory

# Viewing
bat README.md       # Syntax highlighted

# Search
rg "pattern"        # Search code
fd filename         # Find files
Ctrl+R              # fzf history search

# System
btop                # Process monitor
duf                 # Disk usage
dust                # Directory sizes

# Git
g s                 # Status
g recent            # Recent branches
g today             # Today's commits
```

### Multi-Machine

```bash
hostname            # Check machine
echo $MACHINE_MODE  # home or work

# Sync machines
g pl                # Pull on machine 2
nix-rebuild         # Apply changes

# Edit machine-specific
code home/_mixins/personal.nix  # Personal
code home/_mixins/work.nix      # Work
```

---

## Next Steps

- **[Usage Guide](usage.md)** - Daily workflows
- **[Troubleshooting](troubleshooting.md)** - Fix issues
- **[Reference Docs](../index.md#reference)** - Tool details

---
