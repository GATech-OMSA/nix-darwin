# Learning Guide

**Master your nix-darwin environment: From shell shortcuts to advanced workflows**

**Last Updated**: 2025-11-10 (v2.0.0)

---

## Who This Guide Is For

✅ **You've completed installation** - System is running and configured
✅ **You want to learn** advanced features and productivity shortcuts
✅ **You're ready to** master modern CLI tools and workflows

❌ **Haven't installed yet?** Start with [Installation Guide](../INSTALLATION.md)

---

## Table of Contents

1. [Shell Shortcuts Mastery](#1-shell-shortcuts-mastery)
2. [Git Workflow Patterns](#2-git-workflow-patterns)
3. [Zoxide - Smart Directory Jumping](#3-zoxide---smart-directory-jumping)
4. [AWS Multi-Role System (Work Profile)](#4-aws-multi-role-system-work-profile)
5. [Modern CLI Tools](#5-modern-cli-tools)
6. [SOPS Secrets Management](#6-sops-secrets-management)
7. [Profile System (v2.0.0)](#7-profile-system-v200)
8. [Advanced Topics](#8-advanced-topics)

---

## 1. Shell Shortcuts Mastery

### Progressive Learning Path

**Week 1: Basic Navigation** → **Week 2: Modern Tools** → **Week 3: Advanced Workflows**

### Level 1: Basic Shortcuts (Day 1-3)

**Navigation:**

```bash
# Directory shortcuts (instant jumping)
dev             # → cd ~/Dev
docs            # → cd ~/Documents
down            # → cd ~/Downloads

# Quick traversal
..              # Up one directory
...             # Up two directories
-               # Go to previous directory

# Practice workflow
dev             # Jump to Dev
cd my-project   # Enter project
-               # Back to Dev
..              # Up to home
```

**File listing (eza - modern ls):**

```bash
# Modern ls with eza
ll              # Detailed list with icons
la              # Show hidden files
lt              # Tree view (2 levels)
ls              # Color-coded directories-first

# Compare old vs new
/bin/ls -la     # Traditional (boring)
ll              # Modern (beautiful icons, colors)
```

**File viewing (bat - modern cat):**

```bash
# Syntax highlighting
bat README.md           # Markdown rendering
bat script.py           # Python highlighting
bat config.json         # JSON formatting

# Options
bat -n file.py          # Line numbers
bat -A file.txt         # Show all characters (tabs, spaces)
bat --language python   # Force language

# Practice
bat ~/.zshrc            # Your shell config
```

**Practice exercises:**

```bash
# Exercise 1: Navigate your project structure
dev
ll                      # List projects
cd my-main-project
lt                      # See tree structure
-                       # Back to Dev

# Exercise 2: View different file types
bat package.json        # JSON highlighting
bat README.md           # Markdown rendering
bat script.py           # Python syntax colors
```

### Level 2: Productivity Shortcuts (Day 4-7)

**Quick actions:**

```bash
# Open in applications
vs              # Open current dir in VS Code
f               # Open in Finder
show file.txt   # Reveal file in Finder
ql image.png    # Quick Look preview

# Clipboard
cat file.txt | copy     # Copy contents to clipboard
paste                   # Paste from clipboard
paste > output.txt      # Paste to file

# Application launchers (all lowercase)
gpt             # Open ChatGPT
claude          # Open Claude
obs             # Open Obsidian for notes
cursor          # Open Cursor IDE
ff              # Open Firefox
```

**Workflow combinations:**

```bash
# Edit + commit workflow
cd ~/Dev/my-project
vs                      # Open in VS Code
# ... make changes ...
g aa && g cm "Fix" && g ps

# Quick documentation lookup
cd my-project
bat README.md           # Quick read
vs                      # Edit if needed

# File investigation
show ~/.zshrc           # Reveal in Finder
bat ~/.zshrc            # Read content
code ~/.zshrc           # Edit (alias for vs)
```

**Practice exercises:**

```bash
# Exercise 1: Complete edit-commit cycle
dev
cd learning-project
echo "# Test" > README.md
vs                      # Open, edit file
g aa && g cm "Add README"

# Exercise 2: Multi-app workflow
obs                     # Open notes
gpt                     # Research topic
copy                    # Copy findings
obs                     # Paste into notes
```

### Level 3: Advanced Functions (Week 2+)

**Directory creation:**

```bash
# Create and enter
mkcd ~/Dev/new-project  # mkdir + cd in one

# New project scaffold
newproj my-api          # Creates ~/Dev/my-api + opens VS Code
```

**File operations:**

```bash
# Backup with timestamp
backup important.txt    # Creates important.txt.backup-20250107-143022

# Extract any archive
extract archive.zip     # Auto-detects format
extract tarball.tar.gz  # Works with all formats
```

**Search and history:**

```bash
# Search command history
histgrep docker         # Find all docker commands you've run

# System information
sysinfo                 # Complete system details
```

**Network utilities:**

```bash
# Find what's using a port
port 3000               # Check port 3000

# Kill process on port
killport 3000           # Stop whatever's on port 3000

# Check your IP
myip                    # Public IP
localip                 # Local network IP
```

**Practice exercises:**

```bash
# Exercise 1: Debug port conflict
port 3000               # See what's running
killport 3000           # Stop it
# ... start your app ...

# Exercise 2: Quick backup before risky change
backup important-config.yaml
# ... make changes ...
# If broken: cp important-config.yaml.backup-* important-config.yaml

# Exercise 3: System troubleshooting
sysinfo                 # Check system state
ports                   # All listening ports
```

---

## 2. Git Workflow Patterns

### Understanding the `g` Prefix System

**Why `g` prefix?**

- ✅ Access to 60+ git aliases
- ✅ Single source of truth in `home/_profiles/_template/programs/git.nix`
- ✅ Consistent pattern: `g <command>`
- ✅ No conflicts with shell commands

**Basic pattern:**

```bash
# All git commands via g prefix
g s                     # Status
g aa                    # Add all
g cm "msg"              # Commit
g recent                # Recent branches
g today                 # Today's commits
g review                # What you're about to push
# ... 50+ more
```

### Common Workflows

**Daily workflow:**

```bash
# Morning: Start work
cd ~/Dev/my-project
g s                     # Check status
g pl                    # Pull latest
g recent                # What was I working on?

# During: Make changes
# ... edit files ...
g d                     # Review changes
g aa                    # Stage all
g cm "Implement feature X"
g ps                    # Push

# Evening: Review day
g today                 # What did I do today?
g week                  # This week's work
```

**Feature branch workflow:**

```bash
# Start feature
g co -b feature/new-auth
# or
g cob feature/new-auth  # Create and checkout

# Work on feature
# ... edit files ...
g aa
g cm "Add auth middleware"
g ps

# Review before merge
g review                # See all changes vs main
g l                     # Commit history
g d main                # Diff vs main

# Merge and cleanup
g co main
g pl
git merge feature/new-auth
g ps
g bclean                # Delete merged branches
```

**Quick fix workflow:**

```bash
# Save current work
g save                  # Quick savepoint

# or use stash
gst                     # Stash changes

# Make hotfix
g co main
g pl
g cob hotfix/critical-bug
# ... fix bug ...
g aa && g cm "Fix critical bug"
g ps

# Return to work
g co feature/my-feature
gstp                    # Pop stash
```

**Review and cleanup:**

```bash
# Before pushing
g d                     # Unstaged changes
g ds                    # Staged changes (what will commit)
g l                     # Recent commits
g review                # Everything you're about to push

# Branch management
g recent                # Recent branches (with dates)
g bclean                # Delete merged branches
g gone                  # Delete branches with deleted remotes

# History
g today                 # Today's commits
g yesterday             # Yesterday's work
g week                  # This week's commits
```

### Advanced Git Patterns

**Finding things:**

```bash
# Find in code history
g fc "password"         # Find commits that changed "password"
g fm "bug fix"          # Find commits with "bug fix" in message

# Find in branches
g fb abc123             # Which branches have this commit?
g ft v1.2.0             # Which tags contain this commit?

# Team insights
g who                   # Top 20 contributors this month
g contributors          # All-time contributors
g activity              # Recent team activity
```

**Undoing mistakes:**

```bash
# Undo last commit (keep changes)
g undo                  # Changes unstaged
gundo                   # Changes staged

# Amend last commit (don't change message)
g amend                 # Quick amend

# Dangerous: wipe to last commit
g wipe                  # Discard all changes

# Safe: create snapshot before risky operation
g snapshot              # Stash but keep in working tree
```

**Practice exercises:**

```bash
# Exercise 1: Complete feature workflow
cd ~/Dev/learning
g cob feature/practice
echo "test" > test.txt
g aa && g cm "Add test"
g review                # Check changes
g co main
g bclean

# Exercise 2: Search your history
g today                 # What did you do?
g fm "Add"              # Find "Add" commits
g fc "import"           # Find code with "import"

# Exercise 3: Team review
g who                   # Who's active?
g activity              # What's happening?
```

---

## 3. Zoxide - Smart Directory Jumping

**The smartest way to navigate your filesystem.**

### What is Zoxide?

Zoxide is a **smarter cd command** that learns your habits and lets you jump to directories by typing partial names.

### How It Works

```bash
# Traditional cd (the old way)
cd ~/Dev/my-long-project-name
cd ~/Documents/work/projects/current
cd ~/Downloads

# Zoxide (the smart way)
z proj          # Jumps to ~/Dev/my-long-project-name
z curr          # Jumps to ~/Documents/work/projects/current
z down          # Jumps to ~/Downloads
```

**It learns from your history** - The more you visit a directory, the higher it ranks.

### Basic Usage

**First-time setup (build history):**

```bash
# Visit directories normally with cd
cd ~/Dev/my-project
cd ~/Documents/notes
cd ~/Dev/another-project
cd ~/Downloads
cd ~

# Now zoxide has learned these paths!
```

**Jump to directories:**

```bash
# Fuzzy matching - partial names work
z proj          # Matches my-project or another-project
z notes         # Jumps to ~/Documents/notes
z down          # Jumps to ~/Downloads

# Multiple matches? It picks the most frequently visited
```

### Advanced Features

**Interactive selection:**

```bash
zi proj         # Opens fuzzy finder if multiple matches
# Use arrow keys to select the right one
```

**Query without jumping:**

```bash
zoxide query proj       # Shows where "z proj" would go
zoxide query --list     # List all tracked directories
```

**Manual directory addition:**

```bash
zoxide add ~/some/new/path      # Add without visiting
```

**Remove from database:**

```bash
zoxide remove ~/old/path        # Stop tracking a directory
```

### Powerful Workflows

**Project switching:**

```bash
# Old way (painful)
cd ~/Dev/work-project
# ... work ...
cd ~/Dev/personal-blog
# ... work ...
cd ~/Dev/experiments

# New way (effortless)
z work          # Jump to work-project
# ... work ...
z blog          # Jump to personal-blog
# ... work ...
z exp           # Jump to experiments
```

**Combined with other tools:**

```bash
# Jump and open in VS Code
z myproj && vs

# Jump and list files
z docs && ll

# Jump and search
z proj && rg "TODO"

# Jump and git status
z myapp && g s
```

**Deep directory navigation:**

```bash
# Traditional (4-5 commands)
cd ~/Dev
ls
cd my-project
cd src
cd components

# Zoxide (1 command)
z comp          # If you've been there before, goes straight to components/
```

### Tips & Tricks

**1. Use short, memorable substrings:**

```bash
# Directory: ~/Dev/awesome-react-application
z react         # Short and memorable
z awesome       # Also works
z app          # Might match multiple, use zi for selection
```

**2. Train zoxide for your workflow:**

```bash
# Visit your most-used directories a few times
cd ~/Dev/main-project && cd ~
cd ~/Dev/main-project && cd ~
cd ~/Dev/main-project && cd ~

# Now "z main" will reliably go there
```

**3. Combine with aliases:**

```bash
# Create workflow aliases
alias zwork='z work-project && vs'
alias zblog='z blog && g s'

# Now
zwork           # Jump to work project and open VS Code
zblog           # Jump to blog and check git status
```

**4. Use with git workflows:**

```bash
# Jump to repo and check status
z myrepo && g s

# Jump to repo, pull, and rebuild
z nixdarwin && g pl && nix-rebuild
```

**5. Check rankings:**

```bash
zoxide query --list             # See all directories with scores
zoxide query --list --score     # Include frequency scores
```

### Integration with nix-darwin

Zoxide is **pre-configured and enabled** in your nix-darwin setup:

```nix
# home/_profiles/_template/shell/zsh.nix
programs.zoxide = {
  enable = true;
  enableZshIntegration = true;
};
```

**Available commands:**
- `z <partial>` - Jump to directory
- `zi <partial>` - Interactive selection
- `zoxide query` - Query database
- `zoxide add` - Add directory manually
- `zoxide remove` - Remove from database

### Practice Exercises

**Exercise 1: Build your zoxide database**

```bash
# Visit your common directories
cd ~/Dev/project1
cd ~/Dev/project2
cd ~/Documents/notes
cd ~/Downloads
cd ~/Desktop
cd ~

# Now try jumping
z proj1
z proj2
z notes
z down
```

**Exercise 2: Fuzzy matching**

```bash
# Create test directories
mkcd ~/Dev/test-fuzzy-matching-one
cd ~
mkcd ~/Dev/test-fuzzy-matching-two
cd ~

# Now try
z fuzzy         # Which one does it pick?
zi fuzzy        # Interactive selection
```

**Exercise 3: Daily workflow integration**

```bash
# Morning routine
z myproject     # Jump to project
g s             # Check git status
g pl            # Pull latest
vs              # Open in VS Code

# Switching contexts
z another       # Jump to different project
g s && g pl     # Quick status and pull
vs              # Open

# End of day
z myproject     # Back to main project
g today         # Review work
```

### Troubleshooting

**Zoxide doesn't find my directory:**

```bash
# Check if it's in the database
zoxide query --list | rg "dirname"

# If not, visit it with cd first
cd /path/to/directory
cd ~

# Now try
z dirname
```

**Multiple matches, wrong one selected:**

```bash
# Use interactive mode
zi dirname      # Select the right one with arrow keys

# Or be more specific
z full-directory-name
```

**Clear zoxide database:**

```bash
# Remove all entries
rm ~/.local/share/zoxide/db.zo

# Rebuild by visiting directories again
```

---

## 4. AWS Multi-Role System (Work Profile)

**Available only on work profile machines.**

### Quick Reference

**Basic commands:**

```bash
awswho                  # Who am I?
awsprofile              # Current profile
awsp personal           # Switch profile (personal machines)
```

**Work profile enhanced commands:**

```bash
# Multi-role profile switching
awsuse ti dev           # Switch to ti-dev (support role)
awsuse ti dev developer # Switch to ti-dev-developer role

# Quick aliases (generated from work profile config)
tidev                   # → awsuse ti dev
tidev-developer         # → awsuse ti dev developer
tiprod                  # → awsuse ti prod

# Discovery
awslist                 # List all available profiles
awswhere                # Show current context

# Session management
awslogin                # AWS SSO login
awscheck                # Check session status
awsrefresh              # Refresh credentials
awslogout               # Clear SSO cache
```

### Understanding Multi-Role Architecture

**Typical project structure:**

```
Project: TI (Transmission Intelligence)
├── Environment: dev
│   ├── ti-dev (support role - read-only)
│   ├── ti-dev-developer (write access)
│   └── ti-dev-admin (full admin)
└── Environment: prod
    ├── ti-prod (support role - read-only)
    └── ti-prod-admin (emergency only)
```

**Role hierarchy:**

```bash
# Support (read-only)
awsuse ti dev           # List resources, view configs
aws s3 ls               # ✅ Works
aws s3 cp file s3://... # ❌ Denied

# Developer (write access)
awsuse ti dev developer # Create/update resources
aws s3 cp file s3://... # ✅ Works
aws lambda update-...   # ✅ Works

# Admin (full access)
awsuse ti dev admin     # IAM, security, everything
aws iam create-role ... # ✅ Works (use carefully!)
```

### Common Workflows

**Daily work start:**

```bash
# 1. Check current state
awswhere                # Where am I?

# 2. Switch to project/environment
tidev                   # TI development environment

# 3. Verify access
awscheck                # Session valid?
awswho                  # Confirm identity

# 4. Work
aws s3 ls s3://my-bucket/
aws lambda list-functions
```

**Role switching during work:**

```bash
# Start with read-only (safe)
tidev                   # Support role

# Check something
aws s3 ls s3://data-bucket/

# Need to upload? Switch roles
tidev-developer         # Developer role
aws s3 cp data.csv s3://data-bucket/

# Back to read-only
tidev                   # Support role (defensive)
```

**Complete documentation:** AWS Multi-Role Guide (available in work profile setup)

---

## 5. Modern CLI Tools

### Progressive Learning Plan

**Week 1-2: Core Tools** → **Week 3-4: Advanced Tools** → **Month 2+: Power User**

### Week 1: Navigation & Viewing

**eza (better ls):**

```bash
# Basic usage
ll              # Detailed list
la              # All files (including hidden)
lt              # Tree view

# Advanced
eza --tree --level=3                    # Deeper tree
eza -l --sort=modified                  # Sort by date
eza --icons --group-directories-first   # Full options

# Practice
cd ~/Dev
ll              # See your projects
lt -L 3         # Tree view
```

**bat (better cat):**

```bash
# Syntax highlighting
bat script.py           # Python highlighting
bat config.json         # JSON formatting
bat README.md           # Markdown rendering

# Options
bat -n file.py          # Line numbers
bat -A file.txt         # Show all characters (tabs, spaces)
bat --language python   # Force language

# Practice
bat ~/.zshrc            # Your shell config
bat /etc/hosts          # System file
```

**zoxide (better cd) - See full section above (#3)**

```bash
# Jump to frequently visited directories
z proj                  # Fuzzy match
zi proj                 # Interactive selection
zoxide query --list     # See all tracked dirs
```

### Week 2: Search & Find

**ripgrep (better grep):**

```bash
# Fast code search
rg "TODO"                   # Find in current directory
rg -i "function"            # Case insensitive
rg "error" --type py        # Only Python files
rg "api_key" -g '*.yaml'    # Specific file pattern

# Advanced
rg "import" -A 3            # Show 3 lines after match
rg "class.*User" --type py  # Regex search
rg "secret" --hidden        # Include hidden files

# Practice
cd ~/Dev/my-project
rg "function"               # Find all functions
rg "TODO" --type py         # Python TODOs
rg "import.*requests"       # Regex match
```

**fd (better find):**

```bash
# Fast file finding
fd README                   # Find README files
fd -e py                    # All .py files
fd -H config                # Include hidden
fd -t d project             # Find directories

# Advanced
fd -e md -x bat {}          # Find and view markdown files
fd -E node_modules          # Exclude directory
fd . ~/Dev -t f -e py       # All Python in Dev

# Practice
fd .nix ~/nix-darwin
fd -e md docs/
fd -t d -H .config
```

**fzf (fuzzy finder):**

```bash
# Interactive search
Ctrl+R          # Search command history
Ctrl+T          # Find files
Alt+C           # Change directory

# In commands
code $(fzf)                         # Open file in VS Code
cd $(fd -t d | fzf)                 # Fuzzy cd to directory
git checkout $(git branch | fzf)    # Fuzzy branch switch

# Practice
# Press Ctrl+R and type: git
# Press Ctrl+T and type: readme
# Press Alt+C and navigate
```

### Week 3: System Monitoring

**btop (better top):**

```bash
btop            # Launch interactive monitor

# Inside btop:
# - Arrow keys: Navigate
# - F2: Options
# - m: Memory view
# - p: Process view
# - q: Quit

# Practice
btop
# Watch CPU, memory, processes
# Find resource-heavy processes
```

**duf (better df):**

```bash
# Disk usage
duf             # All filesystems with colors

# See what's using space
duf --only local
duf --only /

# Practice
duf             # Check your disk
```

**dust (better du):**

```bash
# Directory sizes
dust            # Current directory
dust ~          # Home directory
dust -d 2 ~/Dev # Max depth 2

# Find large directories
dust -r ~/Dev   # Reverse sort (largest first)

# Practice
dust ~/Dev      # What's using space in Dev?
dust -d 3 ~/    # Scan home (3 levels)
```

### Advanced Tools (Month 2+)

**jq (JSON processor):**

```bash
# Parse JSON
curl -s api.github.com/users/octocat | jq '.'
echo '{"name":"John","age":30}' | jq '.name'

# Advanced
jq '.items[] | .name' data.json
jq -r '.[] | [.name, .age] | @csv' data.json

# Practice
echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' | jq '.users[].name'
```

**yq (YAML processor):**

```bash
# Parse YAML
yq '.services' docker-compose.yml
yq '.version' config.yaml

# Advanced
yq -i '.version = "2.0"' config.yaml  # In-place edit

# Practice
yq '.home.sessionVariables' ~/nix-darwin/home/_profiles/_template/default.nix
```

**delta (better git diffs):**

```bash
# Already configured!
g d                     # See beautiful diffs
g l                     # Pretty log

# Side-by-side view enabled
# Syntax highlighting automatic
# Line numbers included
```

**procs (better ps):**

```bash
# Better process viewer
procs                   # All processes
procs firefox           # Find Firefox processes
procs --tree            # Process tree
procs --watch           # Live updating

# Practice
procs
procs python
```

**sd (better sed):**

```bash
# Simple replacements
sd 'old' 'new' file.txt
sd -i 'foo' 'bar' *.py  # In-place, multiple files

# Regex
sd '\d+' '0' file.txt   # Replace numbers

# Practice
echo "hello world" | sd 'world' 'universe'
```

---

## 6. SOPS Secrets Management

### Understanding SOPS

**What is SOPS?**

- Encrypts files with age encryption
- Stores encrypted secrets in git safely
- Auto-decrypts on system rebuild
- Binary format (obviously encrypted)

**What gets encrypted:**

```
hosts/*/secrets.yaml              # Machine-specific encrypted secrets
hosts/*/secrets-personal.nix      # Personal profile secret templates
hosts/*/secrets-work.nix          # Work profile secret templates (work machines)
```

**What's in secrets:**

```yaml
zsh_secrets: |
  export OPENAI_API_KEY="sk-..."
  export GITHUB_TOKEN="ghp_..."

ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
```

### Common Workflows

**Add new API key:**

```bash
# 1. Edit encrypted secrets
edit-secrets

# 2. Add to zsh_secrets section
zsh_secrets: |
  export OPENAI_API_KEY="sk-..."
  export NEW_API_KEY="key-..."   # Add this

# 3. Save (auto-encrypts)

# 4. Rebuild to activate
nix-rebuild

# 5. Verify
echo $NEW_API_KEY

# 6. Commit safely
g aa && g cm "Add new API key"
g ps
```

**Rotate compromised key:**

```bash
# 1. Generate new key from provider (GitHub, AWS, etc.)

# 2. Edit secrets
edit-secrets

# 3. Replace old key with new
GITHUB_TOKEN="ghp_NEW_TOKEN"    # Replace value

# 4. Rebuild immediately
nix-rebuild

# 5. Test new key
gh auth status

# 6. Commit
g aa && g cm "Rotate GitHub token"

# 7. Revoke old key in provider UI
```

**Add new secret type:**

```bash
# 1. Edit profile secret template (hosts/*/secrets-personal.nix)
# Add new secret definition

# 2. Add to secrets file
edit-secrets
# Add:
my_secret: "secret-value"

# 3. Rebuild
nix-rebuild

# 4. Verify installed
ls -la ~/.my_secret
cat ~/.my_secret
```

### Security Best Practices

**Always encrypted in git:**

```bash
# Check encryption before commit
cat hosts/*/secrets.yaml
# Should see binary data, NOT plaintext

# Verify
file hosts/*/secrets.yaml
# Output: hosts/*/secrets.yaml: data

# Git hooks validate automatically
g aa                    # Hook checks encryption
g cm "Update secrets"   # Safe to commit
```

**Backup age key:**

```bash
# CRITICAL: Backup immediately after creation
cat ~/.config/sops/age/keys.txt | copy
# Paste into 1Password/Bitwarden

# Or copy to encrypted USB
cp ~/.config/sops/age/keys.txt /Volumes/SecureBackup/
```

**Check status:**

```bash
secrets-status          # Check everything
secrets-check           # Validate encryption
```

**Complete guide:** [Secrets Management Guide](../SECRETS.md)

---

## 7. Profile System (v2.0.0)

### Understanding Profiles

nix-darwin v2.0.0 uses a **profile-based architecture** for flexible configuration.

**Three profiles available:**

| Profile | ACTIVE_PROFILE | MACHINE_MODE | Use Case |
|---------|----------------|--------------|----------|
| personal | `personal` | `home` | Personal machines |
| work | `work` | `work` | Work machines |
| minimal | `minimal` | `minimal` | Troubleshooting |

### Check Current Profile

```bash
# Check active profile
echo $ACTIVE_PROFILE     # personal, work, or minimal
echo $MACHINE_MODE       # home, work, or minimal

# Should see in prompt
# personal | ~/Dev/project  (Starship prompt shows profile)
```

### Switch Profiles

```bash
# Switch to work profile
scripts/switch-profile.sh work

# Switch to personal profile
scripts/switch-profile.sh personal

# Switch to minimal (troubleshooting)
scripts/switch-profile.sh minimal
```

### Profile-Specific Behavior

**Personal Profile:**
- Personal aliases and shortcuts
- Personal Git email
- No work databases or AWS profiles
- Gaming and personal tools

**Work Profile:**
- Work aliases (tidev, vpn, etc.)
- Work Git email
- AWS multi-role system enabled
- Database connectors (Oracle, PostgreSQL)
- Work-specific development tools

**Minimal Profile:**
- Bare-bones configuration
- For troubleshooting and debugging
- Minimal packages only

### Profile Configuration

Profiles are defined in `home/_profiles/`:

```
home/_profiles/
├── _template/       # Shared base configs (Git, VS Code, shell)
├── personal/        # Personal profile (extends template)
├── work/            # Work profile (extends template + AWS + DB)
└── minimal/         # Minimal profile (troubleshooting)
```

**Complete documentation:** [ADR-006: Profile-Based Architecture](../architecture/decisions/ADR-006-profile-based-architecture.md)

---

## 8. Advanced Topics

### Multi-Machine Configuration

**Understanding profile-based configs:**

```bash
# Check your machine
echo $ACTIVE_PROFILE    # personal, work, or minimal
echo $MACHINE_MODE      # home, work, or minimal
```

**Profile-specific configuration:**

Profiles are in `home/_profiles/{personal,work,minimal}/`.

**Syncing changes between machines:**

```bash
# On Personal Mac
cd ~/nix-darwin
# Edit shared config
nixconf                 # Add git alias
nix-rebuild
g aa && g cm "Add new alias" && g ps

# On Work Mac
cd ~/nix-darwin
g pl                    # Pull changes
nix-rebuild             # New alias now available!
```

### Debugging Nix Builds

**Show detailed errors:**

```bash
darwin-rebuild switch --flake . --show-trace --impure
```

**Test build without switching:**

```bash
darwin-rebuild build --flake . --impure
```

**Check flake:**

```bash
nix flake check
nix flake show
```

**Evaluate specific option:**

```bash
nix eval .#darwinConfigurations.default.system
```

### Performance Optimization

**Cleanup old generations:**

```bash
# Manual
nix-collect-garbage -d
nix-store --optimize

# Automated (cleanup tiers)
cleanup                 # Standard cleanup
cleanup-aggressive      # Maximum cleanup
```

**Optimize builds:**

```nix
# modules/darwin/nix.nix
nix.settings = {
  max-jobs = 8;              # Parallel builds
  cores = 4;                 # Cores per job
  auto-optimise-store = true;
};
```

---

## Practice Workflow

### 30-Day Mastery Plan

**Days 1-7: Shell Shortcuts**

- Day 1-2: Navigation (dev, docs, .., z)
- Day 3-4: File operations (ll, bat, show, vs)
- Day 5-6: Applications (gpt, claude, obs)
- Day 7: Practice combinations

**Days 8-14: Git Workflows**

- Day 8-9: Basic (g s, g aa, g cm, g ps)
- Day 10-11: Branches (g recent, g bclean, g cob)
- Day 12-13: History (g today, g week, g review)
- Day 14: Complete feature workflow

**Days 15-21: Modern CLI Tools**

- Day 15-16: Search (rg, fd, fzf)
- Day 17-18: Monitoring (btop, duf, dust)
- Day 19-20: Advanced tools (jq, yq, delta)
- Day 21: Build custom workflow

**Days 22-30: Advanced Topics**

- Day 22-24: SOPS secrets management
- Day 25-26: Profile system understanding
- Day 27-28: Custom packages and overlays
- Day 29-30: Performance optimization

### Daily Practice

**Morning (5 minutes):**

```bash
# Check system state
echo $ACTIVE_PROFILE    # Verify profile
update-nix              # If Monday
g recent                # Recent work
z myproject             # Jump to project
g s                     # Status
```

**During work (ongoing):**

```bash
# Use shortcuts constantly
z proj              # Instead of cd ~/Dev/project
vs                  # Instead of "code ."
g aa && g cm "..." && g ps  # Instead of full git commands
rg "pattern"        # Instead of grep
ll                  # Instead of ls -la
```

**Evening (5 minutes):**

```bash
# Review day
g today                 # What did I do?
g bclean                # Clean branches
cleanup-quick           # System cleanup
```

---

## Quick Reference

### Essential Shortcuts

```bash
# Navigation
dev, docs, down         # Quick jump
z proj                  # Zoxide smart jump
.., ..., -              # Traverse

# File operations
ll, la, lt              # List
bat, cat                # View
vs, f                   # Open

# Git (with g prefix)
g s, g aa, g cm         # Basic
g recent, g today       # Review
g review, g sync        # Advanced

# Search
rg "pattern"            # Code search
fd filename             # File find
Ctrl+R                  # History

# System
btop                    # Monitor
duf                     # Disk usage
cleanup                 # Clean up

# Profile (v2.0.0)
echo $ACTIVE_PROFILE    # Check profile
scripts/switch-profile.sh work  # Switch profile
```

### Configuration

```bash
nixconf                 # Open config
nix-rebuild             # Apply changes
exec zsh                # Restart shell
g aa && g cm && g ps    # Commit
```

---

## Next Steps

### Continue Learning

- **[Installation Guide](../INSTALLATION.md)** - Setup procedures
- **[Troubleshooting Guide](../TROUBLESHOOTING.md)** - Fix common issues
- **[Secrets Management](../SECRETS.md)** - SOPS workflows
- **[Backup & Recovery](../backup-and-recovery.md)** - System backup
- **AWS Multi-Role Guide** - Work profile AWS system (see work profile setup)

### Architecture Documentation

- **[ADR-006: Profile-Based Architecture](../architecture/decisions/ADR-006-profile-based-architecture.md)** - v2.0.0 design
- **[ADR-005: Validation and Testing](../architecture/decisions/ADR-005-validation-and-testing-systems.md)** - Quality systems
- **[ADR-003: Git Hooks](../architecture/decisions/ADR-003-git-hooks-enforcement.md)** - Security validation

---

**Ready to master your environment!** 🚀
