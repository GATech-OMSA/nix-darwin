# CLI Tools Guide

Comprehensive reference for all CLI tools, shortcuts, and workflows in this nix-darwin setup.

---

## Table of Contents

1. [Modern CLI Replacements](#modern-cli-replacements)
2. [Navigation & Search](#navigation--search)
3. [Git Workflow](#git-workflow)
4. [File Management](#file-management)
5. [System Monitoring](#system-monitoring)
6. [Data Processing](#data-processing)
7. [Container & Kubernetes](#container--kubernetes)
8. [Database Tools](#database-tools)
9. [Development Tools](#development-tools)
10. [Terminal & Multiplexers](#terminal--multiplexers)
11. [AI & LLM Tools](#ai--llm-tools)
12. [Nix Management](#nix-management)
13. [Shell Shortcuts](#shell-shortcuts)

---

## Modern CLI Replacements

### ripgrep (rg) - Better grep

**Replaces:** `grep`

```bash
# Basic search
rg "pattern"

# Search specific file types
rg "function" --type ts
rg "TODO" --type py

# Case insensitive
rg -i "error"

# Show context lines
rg -C 3 "pattern"          # 3 lines before and after
rg -B 2 -A 5 "pattern"     # 2 before, 5 after

# Search hidden files
rg --hidden "pattern"

# Invert match (lines NOT matching)
rg -v "pattern"

# Count matches
rg -c "pattern"

# Just filenames
rg -l "pattern"

# Fixed string (no regex)
rg -F "exact.string"

# Multiline
rg -U "start.*\n.*end"
```

### fd - Better find

**Replaces:** `find`

```bash
# Find by name
fd "pattern"
fd ".py$"                  # Regex supported

# Find by extension
fd -e py                   # All .py files
fd -e ts -e tsx            # Multiple extensions

# Find by type
fd -t f "pattern"          # Files only
fd -t d "pattern"          # Directories only
fd -t l "pattern"          # Symlinks only

# Include hidden
fd -H "pattern"

# Execute command on results
fd -e py -x wc -l          # Count lines in each
fd -e ts -x prettier -w    # Format all

# Exclude patterns
fd -E node_modules -E .git "pattern"

# Max depth
fd -d 2 "pattern"
```

### bat - Better cat

**Replaces:** `cat`

```bash
# View file with syntax highlighting
bat file.py
bat file.json

# Show line numbers only
bat -n file.py

# Show non-printable characters
bat -A file.txt

# Plain output (no decorations)
bat -p file.py

# Specific language
bat -l python script

# Multiple files
bat file1.py file2.py

# Show changes from git
bat --diff file.py

# Pager mode (for long files)
bat --paging=always file.py
```

**Aliases configured:**
- `cat` → `bat`
- `catp` → `bat -p` (plain, no paging)

### eza - Better ls

**Replaces:** `ls`

```bash
# Basic listing with icons
eza --icons

# Long format
eza -l --icons

# Show all (including hidden)
eza -la --icons

# Tree view
eza --tree --level=2

# Sort by modified time
eza -l --sort=modified

# Show git status
eza -l --git

# Group directories first
eza --group-directories-first
```

**Aliases configured:**
- `ls` → `eza --icons --group-directories-first`
- `ll` → `eza -l --icons --group-directories-first`
- `la` → `eza -la --icons --group-directories-first`
- `lt` → `eza --tree --level=2 --icons`

### dust - Better du

**Replaces:** `du`

```bash
# Analyze current directory
dust

# Analyze specific path
dust /path/to/dir

# Limit depth
dust -d 2

# Show only N items
dust -n 10

# Reverse order (smallest first)
dust -r

# Show apparent size (not disk usage)
dust -s
```

### duf - Better df

**Replaces:** `df`

```bash
# Show all filesystems
duf

# Show only local filesystems
duf --only local

# Hide specific types
duf --hide special

# Sort by size
duf --sort size

# JSON output
duf --json
```

### sd - Better sed

**Replaces:** `sed`

```bash
# Simple replacement
sd 'old' 'new' file.txt

# In-place edit
sd -i 'old' 'new' file.txt

# Regex replacement
sd 'foo(\d+)' 'bar$1' file.txt

# Preview changes (no write)
sd 'old' 'new' file.txt

# Replace in multiple files
fd -e py | xargs sd 'old' 'new'
```

### procs - Better ps

**Replaces:** `ps`

```bash
# Show all processes
procs

# Search by name
procs nginx

# Tree view
procs --tree

# Watch mode
procs --watch

# Sort by CPU
procs --sortd cpu

# Sort by memory
procs --sortd mem
```

---

## Navigation & Search

### zoxide - Smarter cd

**Replaces:** `cd` (for frequently visited dirs)

```bash
# Jump to best match
z project           # Jumps to ~/Dev/my-project
z nix               # Jumps to ~/nix-darwin

# Interactive selection (with fzf)
zi

# Add directory manually
zoxide add /path/to/dir

# Remove directory
zoxide remove /path/to/dir

# List all entries
zoxide query -l

# Show score
zoxide query -ls
```

**How it works:** Learns from your `cd` usage and ranks directories by "frecency" (frequency + recency).

### fzf - Fuzzy Finder

```bash
# Find files
fzf

# Preview files while selecting
fzf --preview 'bat --color=always {}'

# Search command history
Ctrl+R

# Change directory
Alt+C

# Insert file path
Ctrl+T

# Pipe to fzf
cat file.txt | fzf
git branch | fzf

# Multi-select
fzf -m

# With specific command
vim $(fzf)
code $(fzf -m)
```

**Shell integration:**
- `Ctrl+R` - Search command history
- `Ctrl+T` - Insert file path
- `Alt+C` - Change directory

### atuin - Magical Shell History

**Replaces:** Built-in shell history / `Ctrl+R`

SQLite-backed shell history with sync, search by exit code, directory, and more.

```bash
# Search history (replaces Ctrl+R)
atuin search "git"

# Interactive search (default binding)
Ctrl+R                     # Opens atuin search UI

# Filter by exit code
atuin search --exit 0      # Only successful commands
atuin search --exit 1      # Only failed commands

# Filter by directory
atuin search --cwd .       # Commands run in current dir

# Filter by session
atuin search --session     # Current session only

# Show stats
atuin stats                # History statistics

# Import existing history
atuin import auto          # Auto-detect shell
atuin import zsh           # Import from zsh
```

**Search UI shortcuts:**
- `Ctrl+R` - Open search
- `Enter` - Execute selected command
- `Tab` - Insert to command line (edit before running)
- `Ctrl+D` - Delete from history
- `↑/↓` - Navigate results

**Configuration:** Managed via home-manager in `~/.config/atuin/config.toml`
- `search_mode = "fuzzy"` - Fuzzy matching enabled
- `filter_mode = "global"` - Search all history
- `auto_sync = false` - Cloud sync disabled (enable if needed)

### navi - Interactive Cheatsheet

Better than `tldr` for complex commands with interactive parameter filling.

```bash
# Launch interactive menu
navi

# Search for specific command
navi --query "docker"
navi --query "git rebase"

# Best match (non-interactive)
navi --best-match --query "compress tar"

# Add custom cheatsheets
navi repo add https://github.com/denisidoro/cheats

# List available cheatsheets
navi repo browse
```

**How it works:**
1. Shows categorized command cheatsheets
2. Select a command template
3. Fill in parameters interactively
4. Execute directly

**Tip:** Great for commands you rarely use (tar, find flags, openssl, etc.)

### glow - Terminal Markdown Viewer

```bash
# View markdown file
glow README.md

# Pager mode (for long files)
glow -p README.md

# Render from URL
glow https://raw.githubusercontent.com/.../README.md

# List markdown files
glow -l
```

**Use cases:**
- Read READMEs without leaving terminal
- Preview markdown before committing
- Browse documentation

### Starship - Prompt

Configured in `~/.config/starship.toml`. Shows:
- Current directory
- Git branch and status
- AWS profile
- Python version
- Command duration
- Exit code

---

## Git Workflow

### lazygit - Git TUI

```bash
# Launch in current repo
lazygit

# Launch in specific repo
lazygit -p /path/to/repo
```

**Key bindings in lazygit:**
- `Space` - Stage/unstage file
- `c` - Commit
- `p` - Push
- `P` - Pull
- `b` - Branches panel
- `s` - Stash
- `?` - Help

### delta - Git Diff Pager (Line-based)

Automatically used by git for diffs. Features:
- Syntax highlighting
- Line numbers
- Side-by-side view

```bash
# Compare files directly
delta file1.txt file2.txt

# Use with git
git diff                   # Uses delta automatically
git show HEAD              # Uses delta automatically
git log -p                 # Uses delta automatically
```

### difftastic (difft) - Structural Diff

**Use alongside delta** for syntax-aware diffs that understand code structure.

```bash
# Compare two files
difft old.py new.py

# Compare directories
difft old_dir/ new_dir/

# Use with git
GIT_EXTERNAL_DIFF=difft git diff
GIT_EXTERNAL_DIFF=difft git show HEAD

# Specific language
difft --language python file1 file2

# Ignore whitespace
difft --skip-unchanged file1 file2
```

**When to use which:**
- `delta` - Traditional line-by-line diffs, great for reviewing changes
- `difft` - When you need to understand structural changes (refactoring, moves)

### Git Aliases (Comprehensive)

**Status & Info:**
```bash
g s                        # git status
g st                       # git status -sb (short)
g stat                     # Full status
```

**Staging & Commits:**
```bash
g a <file>                 # git add
g aa                       # git add --all
g ap                       # git add --patch (interactive)
g cm "message"             # git commit -m
g cam "message"            # git commit -am (add + commit)
g amend                    # Amend last commit
g uncommit                 # Undo last commit, keep changes
g recommit                 # Amend without editing message
```

**Branches:**
```bash
g co <branch>              # Checkout branch
g b                        # List branches
g ba                       # List all branches (incl. remote)
g branches                 # Verbose branch list
g bclean                   # Delete merged branches
g gone                     # Delete branches with deleted remotes
```

**History & Logs:**
```bash
g l                        # Pretty log (oneline)
g lg                       # Log with graph
g last                     # Show last commit
g recent                   # Recent branches
g today                    # Today's commits
g week                     # This week's commits
```

**Diff:**
```bash
g d                        # git diff
g ds                       # git diff --staged
g changed                  # Files changed vs main
g unstaged                 # Unstaged changes
g staged                   # Staged changes
```

**Remote & Sync:**
```bash
g ps                       # git push
g pl                       # git pull
g sync                     # fetch --all --prune
g update                   # Pull with rebase
```

**Undo & Reset:**
```bash
g unstage <file>           # Unstage file
g discard <file>           # Discard changes
g undo                     # Undo last commit (soft)
g undo-commit              # Same as undo
```

**Search:**
```bash
g fb <pattern>             # Find branch by name
g ft <pattern>             # Find tag by name
g fc <code>                # Find commits with code
g fm <message>             # Find commits by message
```

**Stash:**
```bash
g save "message"           # Stash with message
g wip                      # Quick stash (work in progress)
g snapshot                 # Stash without removing
```

---

## File Management

### yazi - TUI File Manager

```bash
# Launch
yazi

# Launch in specific directory
yazi /path/to/dir
```

**Key bindings:**
- `h/j/k/l` - Navigate (vim-style)
- `Enter` - Open file/directory
- `Space` - Select file
- `d` - Delete
- `y` - Copy
- `p` - Paste
- `r` - Rename
- `/` - Search
- `q` - Quit
- `~` - Go home
- `Tab` - Toggle preview

### File Operations

```bash
# Copy to clipboard
copy < file.txt            # File content
echo "text" | copy         # Text

# Paste from clipboard
paste > file.txt
paste                      # To stdout

# Quick backup
backup file.txt            # Creates file.txt.bak

# Create directory and cd
mkcd new-directory
```

---

## System Monitoring

### btop - System Monitor

```bash
# Launch
btop
```

**Key bindings:**
- `m` - Toggle memory graph
- `n` - Toggle network
- `d` - Toggle disks
- `e` - Toggle tree view
- `f` - Filter processes
- `k` - Kill process
- `q` - Quit

### htop - Alternative Monitor

```bash
htop
```

### System Aliases

```bash
# Check port usage
port 3000                  # What's using port 3000

# Quick system info
fastfetch                  # System information
```

---

## Data Processing

### jq - JSON Processing

```bash
# Pretty print
cat file.json | jq .

# Get specific field
cat file.json | jq '.name'

# Array operations
cat file.json | jq '.[0]'           # First element
cat file.json | jq '.[] | .name'    # All names

# Filter
cat file.json | jq '.[] | select(.age > 30)'

# Transform
cat file.json | jq '{newKey: .oldKey}'
```

### yq - YAML Processing

```bash
# Read YAML
yq '.key' file.yaml

# Convert YAML to JSON
yq -o=json file.yaml

# Edit in place
yq -i '.key = "value"' file.yaml
```

### jless - JSON Viewer (Interactive)

```bash
# View JSON interactively
jless file.json
cat data.json | jless

# YAML mode
jless --yaml file.yaml
```

**Key bindings:**
- `j/k` - Navigate
- `h/l` - Collapse/expand
- `c` - Copy current value
- `/` - Search
- `q` - Quit

---

## Container & Kubernetes

### Docker Aliases

```bash
d                          # docker
dc                         # docker compose
dps                        # docker ps
dpsa                       # docker ps -a
dcu                        # docker compose up -d
dcd                        # docker compose down
dlogs <container>          # docker logs -f
dimg                       # docker images
drm <container>            # docker rm
drmi <image>               # docker rmi
dex <container>            # docker exec -it ... bash
drun <image>               # docker run -it --rm
dprune                     # docker system prune -a
```

### lazydocker - Docker TUI

```bash
lazydocker
```

### Kubernetes Aliases

```bash
k                          # kubectl
kg                         # kubectl get
kd                         # kubectl describe
kl                         # kubectl logs
k9                         # k9s (TUI)
```

### kubectx / kubens - Context Switching

Fast switching between K8s contexts and namespaces.

```bash
# List contexts
kubectx

# Switch context
kubectx my-cluster

# Switch to previous context
kubectx -

# Switch namespace
kubens my-namespace

# Switch to previous namespace
kubens -

# Interactive selection (with fzf)
kubectx                    # Fuzzy select context
kubens                     # Fuzzy select namespace
```

**Tip:** Much faster than `kubectl config use-context` and `kubectl config set-context --current --namespace`

### stern - Multi-Pod Log Tailing

Tail logs from multiple pods/containers simultaneously with colors.

```bash
# Tail all pods matching pattern
stern my-app

# Specific namespace
stern my-app -n production

# All pods in namespace
stern . -n my-namespace

# Include timestamps
stern my-app -t

# Since duration
stern my-app --since 1h
stern my-app --since 10m

# Container filter
stern my-app -c sidecar

# Exclude pattern
stern my-app -e "health"

# Output format
stern my-app -o json
stern my-app -o raw
```

**Key features:**
- Color-coded by pod name
- Auto-follows new pods
- Regex pattern matching
- Multi-container support

### k9s - Kubernetes TUI

```bash
# Launch
k9s

# Specific namespace
k9s -n my-namespace

# Specific context
k9s --context my-context
```

**Key bindings:**
- `:` - Command mode
- `/` - Filter
- `d` - Describe
- `l` - Logs
- `s` - Shell
- `Ctrl+d` - Delete
- `q` - Quit

---

## Database Tools

### usql - Universal SQL Client

One tool for all databases: PostgreSQL, MySQL, SQLite, MSSQL, Oracle, and more.

```bash
# Connect to PostgreSQL
usql postgres://user:pass@localhost/dbname
usql pg://localhost/mydb

# Connect to MySQL
usql mysql://user:pass@localhost/dbname
usql my://localhost/mydb

# Connect to SQLite
usql sqlite:///path/to/file.db
usql file:./local.db

# Connect to SQL Server
usql sqlserver://user:pass@localhost/dbname
usql ms://localhost/mydb

# Interactive mode
usql postgres://localhost/mydb
\dt                        # List tables
\d tablename               # Describe table
\i script.sql              # Execute SQL file
\q                         # Quit

# Execute query directly
usql -c "SELECT * FROM users" postgres://localhost/mydb

# Execute file
usql -f queries.sql postgres://localhost/mydb

# Copy data between databases
usql -c "COPY users TO STDOUT" pg://src | usql -c "COPY users FROM STDIN" pg://dst
```

**Supported databases:**
PostgreSQL, MySQL, SQLite, SQL Server, Oracle, CockroachDB, ClickHouse, MongoDB, Redis, and 40+ more.

**Key features:**
- Consistent syntax across all databases
- Tab completion for tables/columns
- History with up-arrow
- Pretty output formatting

---

## Development Tools

### Python (UV + Ruff)

```bash
# Create new project
uv-new myproject

# Create virtual environment
uv-venv
uv-venv 3.12              # Specific Python version

# Add dependencies
uv-add requests pandas

# Sync dependencies
uv-sync

# Run script
uv-run script.py

# Linting
lint                       # Check with ruff
lint-fix                   # Auto-fix issues
format                     # Format with ruff

# Activate venv manually
activate                   # source .venv/bin/activate
```

### Micromamba (Conda Alternative)

```bash
m-create myenv             # Create environment
m-list                     # List environments
m-install package          # Install package
m-remove myenv             # Remove environment
```

### Direnv (Auto Environment)

Place `.envrc` in project root:

```bash
# For UV projects
use uv                     # Auto-create/activate venv
use uv 3.12                # With specific Python

# For existing venv
use venv                   # Activates .venv or venv/

# Load .env file
dotenv                     # Loads .env automatically
```

### just - Task Runner

```bash
# Run default task
just

# List tasks
just --list

# Run specific task
just build
just test
just deploy

# With arguments
just deploy production
```

### hyperfine - Benchmarking

```bash
# Benchmark single command
hyperfine 'command'

# Compare commands
hyperfine 'cmd1' 'cmd2' 'cmd3'

# With warmup
hyperfine --warmup 3 'command'

# Export results
hyperfine --export-markdown results.md 'command'
```

### gitleaks - Secret Scanning

Detect and prevent secrets (API keys, passwords, tokens) in git repos.

```bash
# Scan current repo
gitleaks detect

# Scan specific path
gitleaks detect --source /path/to/repo

# Scan with verbose output
gitleaks detect -v

# Generate report
gitleaks detect --report-format json --report-path report.json

# Protect mode (use with pre-commit)
gitleaks protect

# Scan only staged changes
gitleaks protect --staged

# Baseline (ignore existing secrets)
gitleaks detect --baseline-path baseline.json
```

**Pre-commit integration:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

**Tip:** Run `gitleaks detect` before pushing to catch accidental secret commits.

### helix (hx) - Modal Editor

Fast, modern modal editor (alternative to vim/neovim). Zero config needed.

```bash
# Open file
hx file.py

# Open multiple files
hx file1.py file2.py

# Open at line number
hx file.py:42

# Open directory
hx .
```

**Key bindings (similar to Kakoune, not vim):**
- `h/j/k/l` - Move cursor
- `w/b` - Word forward/back
- `d` - Delete selection
- `y` - Yank (copy)
- `p` - Paste
- `u` - Undo
- `U` - Redo
- `Space` - Command palette (like VS Code)
- `g` - Goto menu
- `m` - Match menu (brackets, etc.)
- `:w` - Save
- `:q` - Quit
- `:wq` - Save and quit

**Selection-first model:** Unlike vim (verb-object), helix is selection-object-verb:
- vim: `d3w` (delete 3 words)
- helix: `3wd` (select 3 words, then delete)

**Built-in features:**
- LSP support (auto-configured)
- Tree-sitter syntax highlighting
- Multiple cursors
- File picker with preview

### mdbook - Documentation Generator

Fast static site generator for documentation (like Rust docs).

```bash
# Create new book
mdbook init my-docs

# Build
mdbook build

# Serve locally (with hot reload)
mdbook serve
mdbook serve -p 3000

# Clean build artifacts
mdbook clean

# Watch for changes
mdbook watch
```

**Project structure:**
```
my-docs/
├── book.toml          # Configuration
├── src/
│   ├── SUMMARY.md     # Table of contents
│   ├── chapter_1.md
│   └── chapter_2.md
└── book/              # Generated output
```

**SUMMARY.md format:**
```markdown
# Summary

- [Introduction](./intro.md)
- [Getting Started](./start.md)
  - [Installation](./start/install.md)
  - [Configuration](./start/config.md)
```

---

## Terminal & Multiplexers

### tmux - Terminal Multiplexer

```bash
# Start new session
tmux
tmux new -s name

# Attach to session
tmux attach
tmux attach -t name

# List sessions
tmux ls

# Kill session
tmux kill-session -t name
```

**Key bindings (prefix: Ctrl+b):**
- `c` - New window
- `n` - Next window
- `p` - Previous window
- `%` - Split vertical
- `"` - Split horizontal
- `d` - Detach
- `x` - Kill pane
- `z` - Zoom pane
- `[` - Scroll mode

### zellij - Modern Terminal Multiplexer

Alternative to tmux with better UX, discoverable keybindings, and floating panes.

```bash
# Start new session
zellij

# Start with session name
zellij -s myproject

# Attach to session
zellij attach
zellij attach myproject

# List sessions
zellij list-sessions
zellij ls

# Kill session
zellij kill-session myproject

# Run command in new pane
zellij run -- htop
```

**Key bindings (discoverable - shown at bottom):**
- `Ctrl+p` - Pane mode
  - `n` - New pane
  - `d` - Split down
  - `r` - Split right
  - `x` - Close pane
  - `f` - Toggle fullscreen
  - `w` - Toggle floating
  - `h/j/k/l` - Move focus
- `Ctrl+t` - Tab mode
  - `n` - New tab
  - `x` - Close tab
  - `r` - Rename tab
  - `1-9` - Go to tab
- `Ctrl+n` - Resize mode
- `Ctrl+s` - Scroll mode
- `Ctrl+o` - Session mode
  - `d` - Detach
  - `w` - Session manager
- `Ctrl+q` - Quit

**Why use zellij over tmux:**
- Discoverable keybindings (shown in status bar)
- Better default configuration
- Floating panes
- Native session manager
- Simpler split management

### Ghostty - Modern Terminal Emulator

Fast, native macOS terminal with GPU acceleration. Installed alongside iTerm2.

**Features:**
- Native macOS rendering (not Electron)
- GPU-accelerated
- Split panes built-in
- Ligature support
- Cross-platform (macOS, Linux)

**Configuration:** `~/.config/ghostty/config`
```
font-family = "JetBrains Mono"
font-size = 14
theme = dark:catppuccin-mocha,light:catppuccin-latte
```

**Key bindings:**
- `Cmd+D` - Split right
- `Cmd+Shift+D` - Split down
- `Cmd+[/]` - Navigate panes
- `Cmd+T` - New tab
- `Cmd+W` - Close pane/tab
- `Cmd+Shift+Enter` - Toggle fullscreen

### iTerm2 Shortcuts

- `Cmd+T` - New tab
- `Cmd+D` - Split vertical
- `Cmd+Shift+D` - Split horizontal
- `Cmd+[/]` - Switch panes
- `Cmd+Enter` - Fullscreen
- `Cmd+Shift+H` - Paste history
- `Cmd+;` - Autocomplete

---

## AI & LLM Tools

### Ollama (Local LLMs)

```bash
# Start server
ollama-start               # ollama serve

# List models
models                     # ollama list

# Run model
llama3                     # ollama run llama3
codellama                  # ollama run codellama

# Pull new model
ollama pull mistral
```

### Claude Code (This Tool)

Used for:
- Code generation and editing
- Codebase exploration
- Multi-file refactoring
- Git operations
- Documentation

---

## Nix Management

### Core Commands

```bash
# Rebuild system
nix-rebuild                # Smart rebuild with checks

# Build without switching
nix-build                  # darwin-rebuild build

# Rollback
nix-rollback               # Undo last generation

# Health check
nix-health                 # System validation

# Edit configuration
nixconf                    # cd to nix-darwin, open editor

# Compare generations
nix-config-diff            # Show changes between generations
```

### nh - Modern Nix Helper

`nh` provides better UX than darwin-rebuild with colored output, progress bars, and package diffs.

**Note:** `nix-rebuild` now uses `nh` under the hood automatically.

```bash
# Rebuild (uses nh with better output)
nix-rebuild                # Pre-flight checks + nh darwin switch
nix-rebuild --legacy       # Force use darwin-rebuild instead

# Direct nh commands (aliases)
nh-switch                  # nh darwin switch --impure
nh-build                   # nh darwin build --impure

# Cleanup (smarter than nix-collect-garbage)
nh-clean                   # Keep 5 generations, clean rest
nh-clean-aggressive        # Keep only 2 generations

# Search packages (prettier than nix search)
nh-search ripgrep          # Search nixpkgs

# Raw nh commands
nh darwin switch           # Rebuild and switch
nh darwin build            # Build without switching
nh clean all --keep 5      # Explicit cleanup
nh search <package>        # Package search
```

**Environment:** `NH_DARWIN_FLAKE` is auto-set, so `nh` commands work without arguments.

### Secrets Management

```bash
secrets-rescan             # Regenerate mappings
secrets-edit               # Edit encrypted secrets
secrets-view               # View decrypted secrets
secrets-backup             # Backup secrets
secrets-audit              # Audit secret usage
```

### Update Commands

```bash
update-nix                 # Update flake + rebuild
update-brew                # Update Homebrew
update-mamba               # Update Micromamba envs
update-vscode              # Update VS Code extensions
update-mas                 # Update Mac App Store apps
update-dev                 # Quick dev update (nix + mamba + vscode)
update-system              # System update (nix + brew)
update-all                 # Complete update (everything)
```

### Cleanup Commands

```bash
cleanup                    # Standard cleanup (safe + docker + nix gc)
clean                      # Quick cleanup (logs/temp only)
cleanup-system             # Interactive system cleanup
```

---

## Shell Shortcuts

### Configuration Editing

```bash
nixconf                    # cd ~/nix-darwin && code .
zshconf                    # code ~/.zshrc (read-only!)
gitconf                    # code ~/.config/git/config
vscodeconf                 # code ~/Library/.../settings.json
```

### Quick Actions

```bash
c                          # clear
reload                     # source ~/.zshrc
restart                    # exec zsh (full restart)
vs / vscode                # Open VS Code
f / finder                 # Open Finder
```

### Navigation Shortcuts

```bash
dev                        # cd ~/Dev
downloads / down           # cd ~/Downloads
desktop / desk             # cd ~/Desktop
docs                       # cd ~/Documents
apps                       # cd /Applications

# Open in Finder
fdev                       # open ~/Dev in Finder
fdown                      # open ~/Downloads in Finder
```

### Safety Aliases

These commands ask for confirmation:
```bash
cp                         # cp -i
mv                         # mv -i
rm                         # rm -i
```

---

## Quick Reference Card

### Most Used Commands

| Task | Command |
|------|---------|
| Search files | `fd pattern` |
| Search content | `rg pattern` |
| View file | `bat file` |
| View markdown | `glow file.md` |
| List files | `ll` or `la` |
| Jump to dir | `z dirname` |
| Fuzzy find | `fzf` or `Ctrl+R` |
| Shell history | `atuin` (via Ctrl+R) |
| Command cheatsheet | `navi` |
| Git status | `g s` |
| Git commit | `g cm "message"` |
| Git push | `g ps` |
| Git TUI | `lazygit` |
| Structural diff | `difft file1 file2` |
| Secret scanning | `gitleaks detect` |
| System monitor | `btop` |
| Docker TUI | `lazydocker` |
| K8s TUI | `k9s` |
| K8s context switch | `kubectx` |
| K8s logs | `stern pod-name` |
| Database client | `usql pg://...` |
| File manager | `yazi` |
| Multiplexer | `zellij` or `tmux` |
| Modal editor | `hx file` |
| Build docs | `mdbook serve` |
| Rebuild Nix | `nix-rebuild` |
| Update all | `update-all` |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+R` | Search history (atuin) |
| `Ctrl+T` | Insert file path (fzf) |
| `Alt+C` | Change directory (fzf) |
| `ESC ESC` | Prefix sudo |
| `Ctrl+L` | Clear screen |

---

## See Also

- [ADR-007: CLI Tool Selection](../architecture/decisions/ADR-007-cli-tool-selection.md) - Tool selection rationale
- [AWS-AND-SECRETS-WORKFLOW.md](../AWS-AND-SECRETS-WORKFLOW.md) - AWS and secrets guide
- [troubleshooting.md](../troubleshooting.md) - Common issues
