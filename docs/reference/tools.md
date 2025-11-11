# Development Tools Reference

**VS Code, Modern CLI Tools, AI/ML Tools, and macOS System**

[← Back to Index](../index.md)

---

## Table of Contents

- [VS Code](#vs-code)
  - [Opening VS Code](#opening-vs-code)
  - [Installed Extensions](#installed-extensions)
  - [Key Settings](#key-settings)
  - [Language-Specific Settings](#language-specific-settings)
  - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Python Development Workflow](#python-development-workflow)
  - [Jupyter Notebooks](#jupyter-notebooks)
  - [Tips & Best Practices](#vscode-tips--best-practices)
  - [Troubleshooting](#vscode-troubleshooting)
- [Modern CLI Tools](#modern-cli-tools)
  - [File Listing - eza](#file-listing---eza)
  - [File Viewing - bat](#file-viewing---bat)
  - [File Searching - fd & ripgrep](#file-searching---fd--ripgrep)
  - [Disk Usage - dust & duf](#disk-usage---dust--duf)
  - [System Monitor - btop](#system-monitor---btop)
  - [Directory Jumping - zoxide](#directory-jumping---zoxide)
  - [Fuzzy Finder - fzf](#fuzzy-finder---fzf)
  - [Delta - Git Diff](#delta---git-diff)
  - [Hyperfine - Benchmarking](#hyperfine---benchmarking)
  - [Other Modern Tools](#other-modern-tools)
  - [Why Use Modern Tools?](#why-use-modern-tools)
- [AI/ML Tools](#aiml-tools)
  - [Ollama](#ollama)
  - [Installed Models](#installed-models)
  - [Usage](#usage)
  - [RAG Project Template](#rag-project-template)
  - [Common Workflows](#aiml-common-workflows)
  - [Performance Tips](#performance-tips)
  - [Troubleshooting](#aiml-troubleshooting)
- [macOS System](#macos-system)
  - [System Settings](#system-settings)
  - [Keyboard Shortcuts](#macos-keyboard-shortcuts)
  - [Dock Settings](#dock-settings)
  - [Finder Settings](#finder-settings)
  - [Installed Applications](#installed-applications)
  - [Tips & Tricks](#macos-tips--tricks)
- [Configuration](#configuration)

---

## VS Code

**Editor configuration, extensions, and shortcuts**

### Opening VS Code

| Command | Description |
|---------|-------------|
| `vs` | Open VS Code in current directory |
| `code .` | Open VS Code (full command) |
| `code file.txt` | Open specific file |
| `vscodeconf` | Edit vscode.nix (extensions/keybindings only) |

**Examples:**
```bash
# Open current directory
vs

# Open specific project
cd ~/Dev/my-project
vs

# Open file
code README.md

# Edit extensions/keybindings (Nix)
vscodeconf

# Change settings
# Edit in VS Code UI → Cmd+, (Settings)
# Then save to git:
sync-user-data
```

**Settings Management:**
- **Extensions & Keybindings**: Managed in `vscode.nix` (declarative)
- **Settings**: Managed in VS Code UI (user-data/)
- Use `sync-user-data` to backup and sync settings changes to git

---

### Installed Extensions

**Themes & Icons:**
- **Material Icon Theme** - File icons
- **Vitesse Dark** (manual install) - Color theme

**Git & GitHub:**
- **GitLens** - Enhanced git capabilities
- **GitHub Copilot** - AI code completion
- **GitHub Copilot Chat** - AI assistant

**Python Development:**
- **Python** - Full Python support
- **Pylance** - Fast language server
- **Python Debugger** - Debugging support
- **Ruff** - Fast linting and formatting
- **Jupyter** - Notebook support
  - Jupyter Cell Tags
  - Jupyter Slideshow

**Code Quality:**
- **Prettier** - Code formatter (JS/TS/JSON/MD)
- **Error Lens** - Inline error display
- **Code Spell Checker** - Spell checking

**Documentation:**
- **Markdown All in One** - Markdown tools
- **Markdown Mermaid** - Diagram support

**Other:**
- **Even Better TOML** - TOML support

**Manual Installs (Not in Nix):**

Install these via VS Code UI:
- **Vitesse Theme** (`antfu.theme-vitesse`)
- **LeetCode** (`LeetCode.vscode-leetcode`) - Interview prep
- **Better Comments** (`aaron-bond.better-comments`) - Enhanced comments
- **Draw.io** (`hediet.vscode-drawio`) - System design diagrams

---

### Key Settings

**Editor:**

| Setting | Value | Description |
|---------|-------|-------------|
| Font | MesloLGM Nerd Font | Nerd font with icons |
| Font Size | 14 | Comfortable reading |
| Tab Size | 4 | Standard indentation |
| Format on Save | true | Auto-format on save |
| Minimap | Auto-hide on mouseover | Clean view |
| Line Numbers | Interval | Every 10 lines |
| Sticky Scroll | Enabled | Context while scrolling |

**Terminal:**

| Setting | Value |
|---------|-------|
| Font | MesloLGM Nerd Font |
| Font Size | 13 |
| Font Weight | 300 (light) |
| Cursor Style | Line, blinking |
| Tabs | Enabled |

**Files:**

| Setting | Value | Description |
|---------|-------|-------------|
| Auto Save | After delay | Saves automatically |
| Default Path | ~/Dev | File dialog starts here |
| Trim Whitespace | true | Clean files |
| Insert Final Newline | true | POSIX compliant |

**Workbench:**

| Setting | Value |
|---------|-------|
| Color Theme | Vitesse Dark |
| Icon Theme | Material Icon Theme |
| Sidebar | Right side |
| Activity Bar | Top |
| Startup Editor | New untitled file |

**Git:**

| Setting | Value | Description |
|---------|-------|-------------|
| Auto Fetch | true | Keep in sync |
| Smart Commit | true | Commit all if nothing staged |
| Confirm Sync | false | No confirmation |

**Privacy:**

| Setting | Value |
|---------|-------|
| Telemetry | Off |
| Experiments | Disabled |
| Natural Language Search | Disabled |
| Updates | None (Nix manages) |

---

### Language-Specific Settings

**Python:**

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.analysis.typeCheckingMode": "basic",
  "editor.defaultFormatter": "charliermarsh.ruff",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit",
    "source.fixAll": "explicit"
  }
}
```

**Features:**
- Auto-detects `.venv` in project
- Uses Ruff for formatting (fast!)
- Organizes imports on save
- Type checking with Pylance

**JavaScript / TypeScript:**

```json
{
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "vscode.typescript-language-features"
  }
}
```

**JSON / Markdown:**

```json
{
  "[json]": {
    "editor.defaultFormatter": "vscode.json-language-features"
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

---

### Keyboard Shortcuts

**Essential macOS Shortcuts:**

| Shortcut | Action |
|----------|--------|
| `Cmd+P` | Quick file open |
| `Cmd+Shift+P` | Command palette |
| `Cmd+B` | Toggle sidebar |
| `Cmd+J` | Toggle terminal |
| `Cmd+\`` | Toggle integrated terminal |
| `Cmd+K Cmd+S` | Keyboard shortcuts |

**Editor:**

| Shortcut | Action |
|----------|--------|
| `Cmd+/` | Toggle comment |
| `Opt+Shift+F` | Format document |
| `Cmd+D` | Add selection to next find match |
| `Cmd+Shift+L` | Select all occurrences |
| `Opt+Up/Down` | Move line up/down |
| `Opt+Shift+Up/Down` | Copy line up/down |
| `Cmd+Shift+K` | Delete line |

**Multi-Cursor:**

| Shortcut | Action |
|----------|--------|
| `Opt+Click` | Add cursor |
| `Cmd+Opt+Up/Down` | Add cursor above/below |
| `Cmd+Shift+L` | Add cursors to all matches |

**Navigation:**

| Shortcut | Action |
|----------|--------|
| `Cmd+Click` | Go to definition |
| `Cmd+T` | Go to symbol in workspace |
| `Cmd+Shift+O` | Go to symbol in file |
| `Ctrl+-` | Go back |
| `Ctrl+Shift+-` | Go forward |

**Git (with GitLens):**

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+G` | Source control view |
| `Ctrl+Shift+G G` | Open source control |

**Search:**

| Shortcut | Action |
|----------|--------|
| `Cmd+F` | Find in file |
| `Cmd+H` | Replace in file |
| `Cmd+Shift+F` | Find in files |
| `Cmd+Shift+H` | Replace in files |

**Terminal:**

| Shortcut | Action |
|----------|--------|
| `Ctrl+\`` | New terminal |
| `Cmd+K` | Clear terminal |

---

### Python Development Workflow

**Project Setup:**

```bash
# Create UV project
uv-new my-project
cd my-project

# VS Code auto-detects .venv
vs

# Start coding - formatting on save with Ruff
```

**Features:**

- ✅ Auto-detects `.venv` virtual environment
- ✅ Ruff formats on save (fast!)
- ✅ Organizes imports automatically
- ✅ Type checking with Pylance
- ✅ Copilot suggestions
- ✅ Jupyter notebook support

**Debugging:**

1. Set breakpoint (click gutter or `F9`)
2. Press `F5` to start debugging
3. Use debug console for evaluation

---

### Jupyter Notebooks

**Features:**
- Open `.ipynb` files directly
- Run cells with `Shift+Enter`
- Cell toolbar on left
- Line numbers enabled
- Output limit: 50 lines

**Usage:**
```bash
# Create notebook
touch analysis.ipynb
code analysis.ipynb

# Or start Jupyter Lab
jl
```

---

### VS Code Tips & Best Practices

**1. Use Command Palette:**

Press `Cmd+Shift+P` for any action:
- Format document
- Change color theme
- Install extensions
- Configure settings

**2. Multi-Cursor Editing:**

- `Opt+Click` to add cursors
- `Cmd+D` to select next occurrence
- Edit multiple lines simultaneously

**3. Quick File Navigation:**

- `Cmd+P` → Type filename → Enter
- Faster than sidebar navigation

**4. Integrated Terminal:**

- `Cmd+J` to toggle
- Multiple terminals with tabs
- Split terminals with `Cmd+\`

**5. Format on Save:**

Already enabled! Just save and code auto-formats.

**6. GitLens Features:**

- Line blame inline
- File history
- Compare branches
- Visual file history

---

### VS Code Troubleshooting

**Extension Not Working:**

```bash
# Rebuild to ensure extensions installed
nix-rebuild

# Restart VS Code
# Cmd+Q, then reopen
```

**Settings Not Applied:**

```bash
# Check vscode.nix syntax
vscodeconf

# Rebuild
nix-rebuild

# Restart VS Code completely
```

**Python Environment Not Detected:**

```bash
# Ensure .venv exists
ls -la .venv

# Reload window
Cmd+Shift+P → "Reload Window"

# Or manually select interpreter
Cmd+Shift+P → "Python: Select Interpreter"
```

**Copilot Not Suggesting:**

```bash
# Check Copilot status
Cmd+Shift+P → "GitHub Copilot: Check Status"

# Sign in if needed
Cmd+Shift+P → "GitHub Copilot: Sign In"
```

---

## Modern CLI Tools

**Modern replacements for traditional Unix utilities**

### Overview

| Old Tool | New Tool | Why Better |
|----------|----------|------------|
| `ls` | `eza` | Icons, colors, git integration |
| `cat` | `bat` | Syntax highlighting, line numbers |
| `grep` | `ripgrep` (rg) | Faster, respects .gitignore |
| `find` | `fd` | Simpler syntax, faster |
| `du` | `dust` | Visual, sorted by size |
| `df` | `duf` | Colorful, clean output |
| `top/htop` | `btop` | Beautiful, interactive |
| `cd` | `zoxide` (z) | Smart directory jumping |
| `diff` | `delta` | Syntax-highlighted diffs |

---

### File Listing - eza

**eza** - Modern replacement for `ls` with colors, icons, and git integration.

**Aliases:**

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --icons --group-directories-first` | Basic listing with icons |
| `ll` | `eza -al --icons --group-directories-first` | Long listing, all files |
| `la` | `eza -a --icons` | Show hidden files |
| `lt` | `eza --tree --level=2` | Tree view (2 levels deep) |

**Examples:**

```bash
# Basic listing
ls
# 📁 dir1   📁 dir2   📄 file1.txt   📄 file2.md

# Long listing
ll
# drwxr-xr-x  5 jimmy  staff   160 Jan 15 10:30 📁 dir1
# -rw-r--r--  1 jimmy  staff  1.2K Jan 15 10:25 📄 file1.txt

# Show hidden files
la
# 📁 .git   📄 .gitignore   📁 dir1   📄 file1.txt

# Tree view
lt
# .
# ├── 📁 dir1
# │   ├── 📄 file1.txt
# │   └── 📄 file2.txt
# └── 📁 dir2
#     └── 📄 config.json

# Deeper tree
eza --tree --level=3

# Sort by size
eza -al --sort=size

# Sort by modified time
eza -al --sort=modified

# Show git status
eza -al --git
# -M modified.txt
# N  new-file.txt
# I  ignored.txt
```

**Features:**
- **Icons** - Visual file type indicators
- **Colors** - Different colors for files, directories, symlinks
- **Git integration** - Shows git status inline
- **Directories first** - Groups directories at top
- **Extended attributes** - Shows macOS metadata
- **Tree view** - Hierarchical directory display

---

### File Viewing - bat

**bat** - Cat clone with syntax highlighting and line numbers.

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `cat` | `bat --style=plain` | View file with syntax highlighting |

**Examples:**

```bash
# View file (with syntax highlighting)
cat config.json
# {
#   "name": "my-app",
#   "version": "1.0.0"
# }

# View with line numbers
bat config.json

# View multiple files
bat file1.txt file2.txt

# Show non-printable characters
bat --show-all file.txt

# Specific language
bat --language=json data.txt

# View with paging
bat large-file.log

# No paging (print all)
bat --paging=never file.txt

# Plain style (no decorations)
bat --style=plain file.txt
```

**Themes:**

```bash
# List available themes
bat --list-themes

# Use specific theme
bat --theme="Monokai Extended" file.txt

# Set default theme in config
# ~/.config/bat/config
--theme="Monokai Extended"
```

**Features:**
- **Syntax highlighting** - Supports 100+ languages
- **Line numbers** - Easy reference
- **Git integration** - Shows git modifications
- **Automatic paging** - For long files
- **Non-printable characters** - Visible with --show-all

---

### File Searching - fd & ripgrep

**fd - Find Files:**

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `find` | `fd` | Find files |

**Examples:**

```bash
# Find by name
find config
# config.json
# configs/config.yaml

# Find by extension
fd -e md
# README.md
# docs/guide.md

# Find in specific directory
fd test ~/Dev

# Find directories only
fd -t d src

# Find files only
fd -t f .ts src/

# Include hidden files
fd -H config

# Ignore .gitignore
fd -I node_modules

# Execute command on results
fd -e jpg -x convert {} {.}.png

# Full path search
fd --full-path /home/.*config

# Case-insensitive
fd -i readme
```

**ripgrep - Search File Contents:**

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `grep` | `rg` | Search file contents |

**Examples:**

```bash
# Search for pattern
grep "function"
# src/main.ts:15:function hello() {
# src/util.ts:42:function helper() {

# Search in specific files
grep "TODO" -g "*.ts"

# Case-insensitive
grep -i error

# Show context (3 lines before/after)
grep -C 3 "import"

# Search hidden files
grep --hidden "secret"

# Show files without match
grep --files-without-match "test"

# Count matches
grep -c "function"

# Replace text (preview)
rg "old" -r "new"

# Limit to file types
grep "error" -t py
grep "function" -t js -t ts

# Multiline search
grep -U "pattern.*across.*lines"
```

**Features Comparison:**

| Feature | fd | ripgrep |
|---------|----|----|
| **Speed** | Faster than find | Faster than grep |
| **.gitignore** | Respects | Respects |
| **Syntax** | Simple | Regex |
| **Purpose** | Find files | Search content |

---

### Disk Usage - dust & duf

**dust - Disk Usage:**

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `du` | `dust` | Disk usage analyzer |

**Examples:**

```bash
# Analyze current directory
du

# Output:
#   5.0G  ┌── node_modules          │████████████████████████ │ 89%
#   500M  ├── .git                  │██                       │  9%
#   100M  ├── dist                  │█                        │  2%
#   5.6G  ├── my-project            │█████████████████████████│100%

# Limit depth
dust -d 1

# Show specific directory
dust ~/Dev

# Reverse order (smallest first)
dust -r

# Number of lines
dust -n 20

# Show apparent size
dust -s
```

**duf - Disk Free:**

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `df` | `duf` | Disk free with colors |

**Examples:**

```bash
# Show all mounted filesystems
df

# Output:
# ╭──────────────┬────────┬────────┬────────┬───────────────┬──────┬────────────╮
# │ MOUNTED ON   │   SIZE │   USED │  AVAIL │         USE%  │ TYPE │ FILESYSTEM │
# ├──────────────┼────────┼────────┼────────┼───────────────┼──────┼────────────┤
# │ /            │ 465.6G │ 280.1G │ 185.5G │ [##########..] 60.1% │ apfs       │
# │ /System      │ 465.6G │ 280.1G │ 185.5G │ [##########..] 60.1% │ apfs       │
# ╰──────────────┴────────┴────────┴────────┴───────────────┴──────┴────────────╯

# Show only local filesystems
duf --only local

# Exclude specific filesystems
duf --hide-fs tmpfs

# Sort by usage
duf --sort usage

# JSON output
duf --json
```

---

### System Monitor - btop

**btop** - Beautiful resource monitor.

**Alias:**

| Alias | Command | Description |
|-------|---------|-------------|
| `top` | `btop` | System monitor |

**Usage:**

```bash
# Launch btop
top

# or
btop
```

**Key Bindings:**

| Key | Action |
|-----|--------|
| `q` | Quit |
| `m` | Toggle memory view |
| `p` | Toggle process view |
| `n` | Toggle network view |
| `d` | Toggle disk view |
| `+` / `-` | Zoom in/out |
| `f` | Filter processes |
| `k` | Kill process |
| `t` | Tree view |
| `/` | Search |

**Features:**
- **CPU usage** - Per core
- **Memory** - RAM and swap
- **Disk I/O** - Read/write stats
- **Network** - Upload/download
- **Processes** - Sortable, filterable
- **Beautiful UI** - Colors and graphs
- **Mouse support** - Click to interact

---

### Directory Jumping - zoxide

**zoxide** - Smarter cd command that learns your habits.

**Aliases:**

| Alias | Command | Description |
|-------|---------|-------------|
| `z` | `zoxide` | Jump to directory |
| `zz` | `z -` | Jump to previous directory |

**Examples:**

```bash
# First, visit directories normally
cd ~/Dev/my-project
cd ~/Documents/work
cd ~/Dev/another-project

# Now jump to them from anywhere!
z project
# Jumps to ~/Dev/my-project (most frecent match)

# Multiple matches - shows interactive selector
z dev
# 1. ~/Dev
# 2. ~/Dev/my-project
# 3. ~/Dev/another-project

# Jump to previous directory
zz

# Add directory manually
zoxide add ~/custom/path

# Query database
zoxide query dev
# ~/Dev

# Remove directory
zoxide remove ~/old/path
```

**Features:**
- **Learns your habits** - Tracks directory frecency (frequency + recency)
- **Partial matching** - `z doc` → `~/Documents`
- **Multiple matches** - Interactive selection
- **Fast** - Written in Rust
- **Smart ranking** - Prioritizes recent + frequent

---

### Fuzzy Finder - fzf

**fzf** - Command-line fuzzy finder.

**Key Bindings:**

| Key | Action |
|-----|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Search files |
| `Alt+C` | Search directories and cd |

**Examples:**

```bash
# Search command history
# Press Ctrl+R
# Type: git
# Shows all git commands from history
# Select with Enter

# Find file
# Press Ctrl+T
# Type: config
# Shows matching files
# Select with Enter, inserts path

# Change directory
# Press Alt+C
# Type: dev
# Shows matching directories
# Select with Enter, cd's into it

# Use in scripts
selected=$(ls | fzf)
echo "You selected: $selected"

# Multi-select
fzf -m

# Preview
fzf --preview 'bat --color=always {}'

# Search and open in editor
vim $(fzf)
```

**Features:**
- **Fast** - Searches as you type
- **Fuzzy matching** - Handles typos
- **Preview** - See file contents
- **Multi-select** - Select multiple items
- **Customizable** - Many options

---

### Delta - Git Diff

**delta** - Syntax-highlighting pager for git diff.

**Configuration:**

Automatically configured in `.gitconfig`:

```ini
[core]
    pager = delta

[delta]
    navigate = true
    light = false
    side-by-side = true
    line-numbers = true
```

**Usage:**

```bash
# View diff (automatically uses delta)
git diff

# Shows beautiful syntax-highlighted diff with:
# - Syntax highlighting
# - Line numbers
# - Side-by-side view
# - +/- indicators

# View commit diff
git show abc123

# View staged changes
git diff --staged
```

**Features:**
- **Syntax highlighting** - Language-aware
- **Side-by-side** - Compare old and new
- **Line numbers** - Easy reference
- **Customizable themes** - Match your style
- **Word-level diffs** - Highlights exact changes

---

### Hyperfine - Benchmarking

**hyperfine** - Command-line benchmarking tool.

**Usage:**

```bash
# Basic benchmark
hyperfine 'sleep 0.3'
# Benchmark 1: sleep 0.3
#   Time (mean ± σ):     301.2 ms ±   1.2 ms    [User: 1.1 ms, System: 1.9 ms]
#   Range (min … max):   299.3 ms … 303.9 ms    10 runs

# Compare commands
hyperfine 'grep pattern file.txt' 'rg pattern file.txt'

# Warmup runs
hyperfine --warmup 3 'python script.py'

# Export results
hyperfine --export-json results.json 'command'

# Parameterized runs
hyperfine --prepare 'make clean' --parameter-scan num 1 10 'make -j {num}'

# Used in algorithm benchmarking
bench-algo
# Benchmarks solution.py with hyperfine
```

---

### Other Modern Tools

**jq - JSON Processor:**

```bash
# Pretty-print JSON
cat data.json | jq '.'

# Extract field
cat data.json | jq '.name'

# Filter array
cat data.json | jq '.items[] | select(.price > 100)'

# Transform
cat data.json | jq '{name: .name, total: .price * .quantity}'
```

**ncdu - Disk Usage Analyzer:**

```bash
# Analyze directory
ncdu ~

# Interactive navigation
# - Navigate with arrows
# - Press 'd' to delete
# - Press '?' for help
```

**tldr - Simplified Man Pages:**

```bash
# Get quick examples
tldr tar
tldr git
tldr docker

# Much simpler than man pages!
```

---

### Why Use Modern Tools?

**Performance:**

- **ripgrep** - 5-10x faster than grep
- **fd** - 3-8x faster than find
- **eza** - Faster than ls -la
- **zoxide** - Instant directory jumping

**Features:**

- **Syntax highlighting** - bat, delta
- **Git integration** - eza, delta
- **Smart defaults** - Respects .gitignore
- **Better UX** - Colors, icons, progress

**Ease of Use:**

- **Simpler syntax** - fd vs find
- **Better output** - duf vs df
- **Interactive** - fzf, btop
- **Helpful** - tldr vs man

---

## AI/ML Tools

**Ollama and local LLM setup**

### Ollama

**Ollama** - Run large language models locally on your Mac.

**Aliases:**

| Alias | Command | Description |
|-------|---------|-------------|
| `ollama-start` | `ollama serve` | Start Ollama server |
| `models` | `ollama list` | List installed models |
| `llama3` | `ollama run llama3` | Chat with Llama 3 |
| `codellama` | `ollama run codellama` | Chat with Code Llama |

**Quick Start:**

```bash
# Start Ollama server
ollama-start
# Server starts on http://localhost:11434

# In another terminal, list models
models

# Chat with Llama 3
llama3

# Chat with Code Llama
codellama
```

---

### Installed Models

Check installed models:

```bash
models
# NAME              ID              SIZE    MODIFIED
# llama3:latest     abc123...       4.7 GB  2 days ago
# codellama:latest  def456...       3.8 GB  1 week ago
```

**Install New Models:**

```bash
# Install a model
ollama pull mistral

# Install specific version
ollama pull llama3:70b

# Remove a model
ollama rm mistral
```

**Popular Models:**

| Model | Size | Best For |
|-------|------|----------|
| `llama3` | 4.7GB | General chat |
| `llama3:70b` | 40GB | Best quality (needs powerful Mac) |
| `codellama` | 3.8GB | Code generation |
| `mistral` | 4.1GB | Fast, good quality |
| `phi` | 1.6GB | Small, fast |
| `gemma` | 2.6GB | Google's model |

---

### Usage

**Interactive Chat:**

```bash
# Start chatting
llama3
>>> Hello! How can I help you today?

# Ask questions
>>> Explain Python decorators

# Exit chat
>>> /bye
```

**Programmatic Usage:**

```python
import ollama

# Generate response
response = ollama.generate(
    model='llama3',
    prompt='Write a Python function to reverse a string'
)
print(response['response'])

# Chat interface
messages = [
    {'role': 'user', 'content': 'Why is the sky blue?'}
]
response = ollama.chat(model='llama3', messages=messages)
print(response['message']['content'])
```

**API Usage:**

```bash
# REST API (Ollama server must be running)
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Why is the sky blue?"
}'
```

---

### RAG Project Template

Quick setup for RAG (Retrieval Augmented Generation) projects:

```bash
newrag my-chatbot
# Creates:
#   ~/Dev/ai-ml/my-chatbot/
#   ├── pyproject.toml      # UV config with dependencies
#   ├── .venv/              # Virtual environment
#   ├── src/main.py         # RAG pipeline skeleton
#   ├── data/               # For your documents
#   ├── notebooks/          # For experiments
#   └── README.md
```

**Included Dependencies:**
- `langchain` - LLM framework
- `chromadb` - Vector database
- `sentence-transformers` - Embeddings
- `openai` - OpenAI API (optional)
- `pytest`, `ipython` - Development tools

**Example RAG Pipeline:**

```python
# src/main.py (template)
from langchain.vectorstores import Chroma
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import Ollama

# Initialize embeddings
embeddings = HuggingFaceEmbeddings()

# Initialize vector store
vectorstore = Chroma(
    persist_directory="./chroma_db",
    embedding_function=embeddings
)

# Initialize Ollama
llm = Ollama(model="llama3")

# Add documents
# vectorstore.add_documents(documents)

# Query
# results = vectorstore.similarity_search(query)
# answer = llm(context + question)
```

---

### AI/ML Common Workflows

**Local Development with Ollama:**

```bash
# 1. Start Ollama server
ollama-start

# 2. Create RAG project
newrag document-qa
cd ~/Dev/ai-ml/document-qa

# 3. Install dependencies
uv sync

# 4. Activate environment (automatic!)
# 🐍 Activated UV virtual environment: .venv

# 5. Start coding
vs
```

**Model Comparison:**

```bash
# Test same prompt with different models
echo "Write a Python function to fibonacci" | ollama run llama3
echo "Write a Python function to fibonacci" | ollama run codellama
echo "Write a Python function to fibonacci" | ollama run mistral
```

**Jupyter Notebook Workflow:**

```bash
# In RAG project directory
jl

# Create new notebook
# Use Ollama in notebook:
import ollama
response = ollama.generate(model='llama3', prompt='Hello!')
print(response['response'])
```

---

### Performance Tips

**1. Use Smaller Models for Development:**

```bash
# Development: Use phi (fast, small)
ollama pull phi
ollama run phi

# Production: Use llama3 or better
ollama run llama3:70b
```

**2. Model Loading:**

Models load on first use. Subsequent calls are faster.

```bash
# Pre-load a model
ollama run llama3 "hello"
# Now it's loaded in memory
```

**3. GPU Acceleration:**

Ollama automatically uses Metal (GPU) on Apple Silicon Macs.

**4. Memory Management:**

```bash
# Check running models
ollama ps

# Stop all models (frees memory)
ollama stop llama3
```

---

### AI/ML Troubleshooting

**Ollama Not Starting:**

```bash
# Check if already running
ps aux | grep ollama

# Kill existing process
pkill ollama

# Restart
ollama-start
```

**Model Download Failed:**

```bash
# Retry download
ollama pull llama3

# Check disk space
df -h

# Check network
curl -I https://ollama.ai
```

**Out of Memory:**

```bash
# Use smaller model
ollama run phi

# Or stop other models
ollama ps
ollama stop llama3
```

**Slow Response:**

```bash
# Check if model is loaded
ollama ps

# Use GPU (automatic on Apple Silicon)
# Ensure you're on M1/M2/M3 Mac

# Use smaller model for faster responses
ollama run phi
```

---

## macOS System

**System settings and keyboard shortcuts**

### System Settings

**Keyboard:**

| Setting | Value | Description |
|---------|-------|-------------|
| Key Repeat | 2 (fast) | How fast keys repeat |
| Initial Key Repeat | 15 | Delay before repeat starts |
| Press and Hold | Disabled | No special characters on hold |

**Result:** Very responsive typing experience

**Trackpad:**

| Setting | Value |
|---------|-------|
| Tap to Click | Enabled |
| Natural Scrolling | Enabled (macOS default) |

**Dock:**

| Setting | Value |
|---------|-------|
| Auto Hide | Enabled |
| Show Delay | 0.2s |
| Hide Delay | 0.2s |
| Tile Size | 36 |

**Finder:**

| Setting | Value |
|---------|-------|
| Show Extensions | Yes |
| Show Path Bar | Yes |
| Show Hidden Files | Yes (via Cmd+Shift+.) |
| Default View | List View |

---

### macOS Keyboard Shortcuts

**System-Wide:**

| Shortcut | Action |
|----------|--------|
| `Cmd+Space` | Spotlight / Alfred |
| `Cmd+Tab` | Switch applications |
| `Cmd+~` | Switch windows in app |
| `Cmd+Q` | Quit application |
| `Cmd+W` | Close window |
| `Cmd+,` | Preferences |

**Finder:**

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+.` | Show/hide hidden files |
| `Cmd+Shift+G` | Go to folder |
| `Cmd+Shift+H` | Go to home |
| `Cmd+Shift+D` | Go to desktop |
| `Cmd+Shift+A` | Go to Applications |
| `Cmd+Up` | Go to parent folder |
| `Space` | Quick Look |

**Screenshots:**

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+3` | Full screen capture |
| `Cmd+Shift+4` | Selection capture |
| `Cmd+Shift+4` then `Space` | Window capture |
| `Cmd+Shift+5` | Screenshot menu (Monterey+) |

**Window Management (Rectangle):**

Rectangle is installed for window management:

| Shortcut | Action |
|----------|--------|
| `Ctrl+Opt+Left` | Left half |
| `Ctrl+Opt+Right` | Right half |
| `Ctrl+Opt+Up` | Top half |
| `Ctrl+Opt+Down` | Bottom half |
| `Ctrl+Opt+F` | Fullscreen |
| `Ctrl+Opt+C` | Center |

---

### Dock Settings

**Current Configuration:**
```nix
system.defaults.dock = {
  autohide = true;
  autohide-delay = 0.2;
  autohide-time-modifier = 0.2;
  tilesize = 36;
  show-recents = false;
  mru-spaces = false;  # Don't rearrange spaces
};
```

**Tips:**
- **Auto-hide:** Dock slides away when not in use
- **No recents:** Clean dock without recent apps
- **Fixed spaces:** Spaces stay in order

---

### Finder Settings

**Current Configuration:**
```nix
system.defaults.finder = {
  AppleShowAllExtensions = true;
  ShowPathbar = true;
  FXPreferredViewStyle = "Nlsv";  # List view
  FXEnableExtensionChangeWarning = false;
};
```

---

### Installed Applications

**Via Homebrew Cask:**

**Productivity:**
- Alfred - Spotlight replacement
- Rectangle - Window management
- Keka - Archive utility
- KeyClu - Keyboard shortcut helper

**Development:**
- iTerm2 - Terminal
- VS Code - Editor
- Docker - Containers
- Claude Code - AI assistant

**Browsers:**
- Firefox
- Orion

**Communication:**
- WhatsApp
- Zoom

**AI Tools:**
- ChatGPT
- Claude
- Ollama
- Jan

**See full list:** `modules/darwin/homebrew.nix`

---

### macOS Tips & Tricks

**1. Show Hidden Files in Finder:**

```bash
# Keyboard shortcut
Cmd+Shift+.

# Or permanently via setting (already enabled in Nix)
```

**2. Fast Key Repeat:**

Already configured! Enjoy super fast typing.

**3. Disable Mission Control Shortcuts:**

Already disabled to avoid conflicts with terminal shortcuts.

**4. Quick File Path:**

In Finder:
- Right-click file
- Hold `Opt` key
- "Copy as Pathname" appears

**5. Dock Management:**

```bash
# Add spacer to Dock
defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'
killall Dock
```

---

## Configuration

### VS Code Configuration

**Hybrid Approach:**

**Extensions (Nix):** `home/jimmy/programs/vscode.nix`
```nix
programs.vscode = {
  enable = true;
  profiles.default = {
    extensions = [ /* VS Code extensions */ ];
    keybindings = [];  // Optional custom keybindings
  };
};
```

**Settings (User-Data):** Managed in VS Code UI
- Settings location: `~/Library/Application Support/Code/User/settings.json`
- Backed up to: `user-data/user-content/vscode/settings.json`
- Edit in VS Code UI (Cmd+,), then run `sync-user-data` to save

**Edit Configuration:**

```bash
# Edit vscode.nix
vscodeconf

# Rebuild to apply changes
nix-rebuild

# Restart VS Code
```

**Add Extension:**

1. Find extension ID (e.g., `esbenp.prettier-vscode`)
2. Check if available in nixpkgs: [search.nixos.org](https://search.nixos.org/)
3. Add to `extensions` array in vscode.nix
4. Rebuild: `nix-rebuild`

### Modern CLI Tools Configuration

**Nix Configuration:**

**File:** `modules/shared/packages.nix`

```nix
environment.systemPackages = with pkgs; [
  # Modern CLI tools
  bat
  eza
  ripgrep
  fd
  dust
  duf
  btop
  zoxide
  fzf
  delta
  hyperfine
  jq
  ncdu
];
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix`

**Modern CLI aliases** (lines 36-46):
```bash
# Modern CLI replacements
ls = "eza --icons --group-directories-first";
ll = "eza -al --icons --group-directories-first";
la = "eza -a --icons";
lt = "eza --tree --level=2";
cat = "bat --style=plain";
grep = "rg";
find = "fd";
du = "dust";
df = "duf";
top = "btop";
```

**Zoxide initialization** (lines 1180-1183):
```bash
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  alias zz="z -"
fi
```

### AI/ML Tools Configuration

**Ollama Installation:**

**Installed via:** Homebrew (`modules/darwin/homebrew.nix`)

```nix
casks = [
  "ollama"
];
```

**Shell Aliases:**

**File:** `home/jimmy/shell/zsh.nix` (lines 243-246)

```bash
"ollama-start" = "ollama serve";
models = "ollama list";
llama3 = "ollama run llama3";
codellama = "ollama run codellama";
```

### macOS System Configuration

**System Settings File:**

**File:** `modules/darwin/system.nix`

All macOS settings are defined here:
```nix
system.defaults = {
  dock = { /* ... */ };
  finder = { /* ... */ };
  NSGlobalDomain = { /* ... */ };
  # ... more settings
};
```

**Modify Settings:**

1. **Edit system.nix:**
   ```bash
   code ~/nix-darwin/modules/darwin/system.nix
   ```

2. **Change settings:**
   ```nix
   system.defaults.dock = {
     tilesize = 48;  # Larger dock icons
     autohide = false;  # Always show dock
   };
   ```

3. **Rebuild:**
   ```bash
   nix-rebuild
   ```

4. **Logout/login** for some settings to take effect

---

## Links

**VS Code:**
- [VS Code Documentation](https://code.visualstudio.com/docs)
- [VS Code Keyboard Shortcuts (PDF)](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-macos.pdf)
- [GitHub Copilot Docs](https://docs.github.com/en/copilot)

**Modern CLI Tools:**
- [eza](https://github.com/eza-community/eza)
- [bat](https://github.com/sharkdp/bat)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [dust](https://github.com/bootandy/dust)
- [duf](https://github.com/muesli/duf)
- [btop](https://github.com/aristocratos/btop)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [delta](https://github.com/dandavison/delta)
- [hyperfine](https://github.com/sharkdp/hyperfine)

**AI/ML Tools:**
- [Ollama Documentation](https://ollama.ai/docs)
- [Ollama Models Library](https://ollama.ai/library)
- [LangChain Documentation](https://python.langchain.com/)
- [ChromaDB Documentation](https://docs.trychroma.com/)

**macOS:**
- [Nix Darwin Options](https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.dock.autohide)
- [macOS Keyboard Shortcuts](https://support.apple.com/en-us/HT201236)

**Related Documentation:**
- [Shell Reference](shell.md) - Zsh, Git, and Starship
- [Languages Reference](languages.md) - Python and Node.js development
- [Infrastructure Reference](infrastructure.md) - AWS, Docker, Kubernetes, Terraform
- [Python Reference](languages.md#python) - Python development setup
- [Git Reference](shell.md#git) - Git workflows
- [Nix Darwin Reference](system.md) - System configuration
