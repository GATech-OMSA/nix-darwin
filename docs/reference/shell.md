# Shell Reference

**Complete shell configuration: Zsh, Git, and Starship prompt**

[← Back to Index](../index.md)

---

## Table of Contents

- [Overview](#overview)
- [Zsh Configuration](#zsh-configuration)
  - [Modern CLI Aliases](#modern-cli-aliases)
  - [Quick Open Shortcuts](#quick-open-shortcuts)
  - [App Launchers](#app-launchers)
  - [Workflow Helpers](#workflow-helpers)
  - [Navigation Aliases](#navigation-aliases)
  - [Python & UV Aliases](#python--uv-aliases)
  - [Docker Aliases](#docker-aliases)
  - [Kubernetes Aliases](#kubernetes-aliases)
  - [AWS Aliases](#aws-aliases)
  - [Terraform Aliases](#terraform-aliases)
  - [Nix Darwin Aliases](#nix-darwin-aliases)
  - [Ollama Aliases](#ollama-aliases)
  - [Network Utilities](#network-utilities)
  - [General Shortcuts](#general-shortcuts)
- [Shell Functions](#shell-functions)
  - [File & Directory](#file--directory)
  - [Search & Info](#search--info)
  - [Interview Prep & Learning](#interview-prep--learning)
  - [Update Functions](#update-functions)
  - [Cleanup Functions](#cleanup-functions)
  - [Work-Specific Functions](#work-specific-functions)
- [Python Auto-Activation](#python-auto-activation)
- [Oh-My-Zsh Plugins](#oh-my-zsh-plugins)
- [Git Configuration](#git-configuration)
  - [Basic Operations](#basic-operations)
  - [Commit Shortcuts](#commit-shortcuts)
  - [Branch Management](#branch-management)
  - [Stash Operations](#stash-operations)
  - [Log & History](#log--history)
  - [Diff & Review](#diff--review)
  - [Find Commands](#find-commands)
  - [Team Insights](#team-insights)
  - [Sync & Update](#sync--update)
  - [Cleanup & Reset](#cleanup--reset)
  - [Common Workflows](#common-workflows)
  - [Delta Configuration](#delta-configuration)
- [Starship Prompt](#starship-prompt)
  - [Prompt Layout](#prompt-layout)
  - [Configuration](#starship-configuration)
  - [iTerm2 Keyboard Shortcuts](#iterm2-keyboard-shortcuts)
  - [Customization](#customization)
  - [Troubleshooting](#troubleshooting)
- [Configuration Files](#configuration-files)

---

## Overview

This reference covers the complete shell environment:

- **Zsh** - Shell with 100+ aliases and custom functions
- **Git** - 60+ git aliases with `g` prefix pattern
- **Starship** - Fast, customizable prompt (Catppuccin theme)
- **Oh-My-Zsh** - 19 built-in + 5 custom plugins

---

## Zsh Configuration

### Modern CLI Aliases

Modern replacements for traditional Unix tools:

| Alias  | Command                                     | Tool    | Description                 |
| ------ | ------------------------------------------- | ------- | --------------------------- |
| `ls`   | `eza --icons --group-directories-first`     | eza     | Better ls with icons        |
| `ll`   | `eza -al --icons --group-directories-first` | eza     | Long listing with all files |
| `la`   | `eza -a --icons`                            | eza     | Show hidden files           |
| `lt`   | `eza --tree --level=2`                      | eza     | Tree view (2 levels)        |
| `cat`  | `bat --style=plain`                         | bat     | Syntax highlighting         |
| `grep` | `rg`                                        | ripgrep | Faster grep                 |
| `find` | `fd`                                        | fd      | Faster find                 |
| `du`   | `dust`                                      | dust    | Disk usage analyzer         |
| `df`   | `duf`                                       | duf     | Disk free with colors       |
| `top`  | `btop`                                      | btop    | Better system monitor       |

**Examples:**

```bash
ll              # Long listing of current directory
lt              # Tree view of current directory
cat config.json # Pretty-printed JSON with syntax highlighting
grep "error"    # Fast search with ripgrep
find ".md"      # Find all markdown files
```

### Quick Open Shortcuts

Quickly open applications and directories:

| Alias    | Command    | Description                    |
| -------- | ---------- | ------------------------------ |
| `vs`     | `code .`   | Open VS Code in current dir    |
| `vscode` | `code .`   | Alias for vs (full name)       |
| `f`      | `open .`   | Open Finder in current dir     |
| `finder` | `open .`   | Alias for f (full name)        |

**Examples:**

```bash
vs              # Opens current directory in VS Code
cd ~/Dev/project && vs  # Navigate and open
f               # Opens current directory in Finder
```

### App Launchers

Open GUI applications from terminal (all lowercase):

**Browsers:**

| Alias   | Command              | App     |
| ------- | -------------------- | ------- |
| `ff`    | `open -a Firefox`    | Firefox |
| `orion` | `open -a Orion`      | Orion   |

**AI/LLM:**

| Alias    | Command                 | App        |
| -------- | ----------------------- | ---------- |
| `claude` | `open -a Claude`        | Claude     |
| `gpt`    | `open -a ChatGPT`       | ChatGPT    |
| `pplx`   | `open -a Perplexity`    | Perplexity |
| `obs`    | `open -a Obsidian`      | Obsidian   |
| `jan`    | `open -a Jan`           | Jan        |

**Development:**

| Alias    | Command              | App    |
| -------- | -------------------- | ------ |
| `cursor` | `open -a Cursor`     | Cursor |
| `cur`    | `open -a Cursor`     | Short  |

**Productivity:**

| Alias    | Command                     | App         |
| -------- | --------------------------- | ----------- |
| `pdf`    | `open -a 'PDF Expert'`      | PDF Expert  |
| `shot`   | `open -a Shottr`            | Shottr      |
| `alfred` | `open -a Alfred`            | Alfred      |

**Communication:**

| Alias      | Command                | App      |
| ---------- | ---------------------- | -------- |
| `zoom`     | `open -a Zoom`         | Zoom     |
| `wa`       | `open -a WhatsApp`     | WhatsApp |
| `whatsapp` | `open -a WhatsApp`     | Full name|

**Other:**

| Alias  | Command                  | App         |
| ------ | ------------------------ | ----------- |
| `tv`   | `open -a TradingView`    | TradingView |
| `vpn`  | `open -a ProtonVPN`      | ProtonVPN   |

**Examples:**

```bash
gpt              # Open ChatGPT
claude           # Open Claude
obs              # Open Obsidian for notes
cursor           # Open Cursor IDE
ff               # Open Firefox
```

### Workflow Helpers

Productivity shortcuts for common operations:

| Alias   | Command        | Description                    |
| ------- | -------------- | ------------------------------ |
| `show`  | `open -R`      | Reveal file in Finder          |
| `ql`    | `qlmanage -p`  | Quick Look preview             |
| `copy`  | `pbcopy`       | Pipe to clipboard              |
| `paste` | `pbpaste`      | Paste from clipboard           |
| `port`  | `lsof -i :`    | Check what's running on port   |

**Examples:**

```bash
show file.txt       # Reveal file in Finder
ql image.png        # Quick Look preview
cat file.txt | copy # Copy file contents to clipboard
paste               # Paste clipboard contents
port 3000           # Check what's on port 3000
```

### Navigation Aliases

Quick directory jumping:

| Alias  | Command       | Description              |
| ------ | ------------- | ------------------------ |
| `..`   | `cd ..`       | Up one directory         |
| `...`  | `cd ../..`    | Up two directories       |
| `....` | `cd ../../..` | Up three directories     |
| `~`    | `cd ~`        | Go to home directory     |
| `-`    | `cd -`        | Go to previous directory |
| `c`    | `clear`       | Clear terminal           |

**Quick Directories:**

| Alias         | Path                         | Description               |
| ------------- | ---------------------------- | ------------------------- |
| `dev`         | `cd ~/Dev`                   | Development directory     |
| `downloads`   | `cd ~/Downloads`             | Downloads folder          |
| `down`        | `cd ~/Downloads`             | Short form                |
| `apps`        | `cd ~/Applications`          | Applications              |
| `docs`        | `cd ~/Documents`             | Documents                 |
| `algo`        | `cd ~/Dev/algorithms`        | Algorithm practice        |
| `desktop`     | `cd ~/Desktop`               | Desktop                   |
| `desk`        | `cd ~/Desktop`               | Short form                |
| `learning`    | `cd ~/Dev/learning`          | Learning projects         |
| `aiml`        | `cd ~/Dev/ai-ml`             | AI/ML projects            |
| `courses`     | `cd ~/Dev/courses`           | Course materials          |
| `experiments` | `cd ~/Dev/experiments`       | Experimental code         |
| `oss`         | `cd ~/Dev/oss-contributions` | Open source contributions |

**Examples:**

```bash
dev              # Jump to ~/Dev
...              # Go up two levels
-                # Go back to previous directory
```

### Python & UV Aliases

Python development shortcuts:

**Micromamba Environment Management:**

| Function/Alias              | Command                          | Description                                  |
| --------------------------- | -------------------------------- | -------------------------------------------- |
| `act <env>`                 | `micromamba activate <env>`      | Activate environment                         |
| `deact`                     | `micromamba deactivate`          | Deactivate environment                       |
| `mkenv <name> [ver] [pkgs]` | `micromamba create ...`          | Create environment (defaults to Python 3.12) |
| `rmenv <env>`               | `micromamba env remove -n <env>` | Remove environment                           |
| `list-envs`                 | `micromamba env list`            | List all environments                        |
| `lsenv`                     | `micromamba env list`            | List all environments (short)                |

**Virtual Environment:**

| Alias      | Command                     | Description         |
| ---------- | --------------------------- | ------------------- |
| `activate` | `source .venv/bin/activate` | Activate local venv |

**Python Tools:**

| Alias | Command            | Description            |
| ----- | ------------------ | ---------------------- |
| `py`  | `python`           | Python interpreter     |
| `ipy` | `ipython`          | IPython REPL           |
| `jl`  | `jupyter lab`      | Start Jupyter Lab      |
| `jn`  | `jupyter notebook` | Start Jupyter Notebook |

**UV (Fast Python Package Manager):**

| Alias     | Command   | Description                         |
| --------- | --------- | ----------------------------------- |
| `uv-new`  | Function  | Create UV project + venv + activate |
| `uv-venv` | Function  | Create and activate venv            |
| `uv-add`  | `uv add`  | Add dependency                      |
| `uv-sync` | `uv sync` | Sync dependencies                   |
| `uv-run`  | `uv run`  | Run with UV                         |

**Code Quality:**

| Alias      | Command              | Description  |
| ---------- | -------------------- | ------------ |
| `lint`     | `ruff check .`       | Lint code    |
| `format`   | `ruff format .`      | Format code  |
| `lint-fix` | `ruff check --fix .` | Lint and fix |

**Environment Management:**

| Alias       | Command               | Description     |
| ----------- | --------------------- | --------------- |
| `list-envs` | `micromamba env list` | List conda envs |

**Examples:**

```bash
uv-new myproject    # Create new UV project
base                # Activate base Python environment
cd myproject        # Auto-activates .venv if present!
lint                # Check code with ruff
format              # Format code with ruff
```

### Docker Aliases

Docker and Docker Compose shortcuts:

| Alias    | Command                   | Description               |
| -------- | ------------------------- | ------------------------- |
| `d`      | `docker`                  | Docker command            |
| `dc`     | `docker compose`          | Docker Compose            |
| `dps`    | `docker ps`               | List running containers   |
| `dpsa`   | `docker ps -a`            | List all containers       |
| `dcu`    | `docker compose up -d`    | Start services (detached) |
| `dcd`    | `docker compose down`     | Stop services             |
| `dlogs`  | `docker compose logs -f`  | Follow logs               |
| `dimg`   | `docker images`           | List images               |
| `drm`    | `docker rm`               | Remove container          |
| `drmi`   | `docker rmi`              | Remove image              |
| `dex`    | `docker exec -it`         | Execute in container      |
| `drun`   | `docker run -it --rm`     | Run and remove            |
| `dprune` | `docker system prune -af` | Clean everything          |

**Examples:**

```bash
dcu                 # Start all services
dlogs api           # Follow API logs
dex api bash        # Shell into API container
dprune              # Clean up unused containers/images
```

### Kubernetes Aliases

kubectl and k9s shortcuts:

| Alias | Command            | Description         |
| ----- | ------------------ | ------------------- |
| `k`   | `kubectl`          | kubectl command     |
| `kg`  | `kubectl get`      | Get resources       |
| `kd`  | `kubectl describe` | Describe resources  |
| `kl`  | `kubectl logs`     | View logs           |
| `k9`  | `k9s`              | Terminal UI for K8s |

**Examples:**

```bash
kg pods             # List all pods
kd pod my-pod       # Describe a pod
kl my-pod -f        # Follow pod logs
k9                  # Launch K9s UI
```

### AWS Aliases

AWS CLI shortcuts:

| Alias        | Command                       | Description          |
| ------------ | ----------------------------- | -------------------- |
| `awsp`       | `export AWS_PROFILE=`         | Set AWS profile      |
| `awsprofile` | `echo $AWS_PROFILE`           | Show current profile |
| `awswho`     | `aws sts get-caller-identity` | Who am I?            |

**Work-Specific (only on work Mac):**

| Alias     | Command                        | Description    |
| --------- | ------------------------------ | -------------- |
| `awsdev`  | `export AWS_PROFILE=work-dev`  | Switch to dev  |
| `awsprod` | `export AWS_PROFILE=work-prod` | Switch to prod |

**Examples:**

```bash
awswho              # Check current AWS identity
awsp personal       # Switch to personal profile
awsdev              # (Work) Switch to dev environment
```

### Terraform Aliases

Terraform shortcuts:

| Alias | Command              | Description       |
| ----- | -------------------- | ----------------- |
| `tf`  | `terraform`          | Terraform command |
| `tfi` | `terraform init`     | Initialize        |
| `tfp` | `terraform plan`     | Plan changes      |
| `tfa` | `terraform apply`    | Apply changes     |
| `tfv` | `terraform validate` | Validate config   |
| `tff` | `terraform fmt`      | Format files      |

**Work-Specific:**

| Alias    | Command                           | Description              |
| -------- | --------------------------------- | ------------------------ |
| `tfdev`  | `terraform workspace select dev`  | Switch to dev workspace  |
| `tfprod` | `terraform workspace select prod` | Switch to prod workspace |

**Examples:**

```bash
tfi && tfp          # Init and plan
tfa                 # Apply changes
tff                 # Format terraform files
```

### Nix Darwin Aliases

| Alias          | Command                                      | Description           |
| -------------- | -------------------------------------------- | --------------------- |
| `nix-rebuild`  | `darwin-rebuild switch --flake ~/nix-darwin` | Rebuild system        |
| `nix-update`   | `cd ~/nix-darwin && nix flake update`        | Update flake          |
| `nix-clean`    | Garbage collect + optimize                   | Clean old generations |
| `nix-rollback` | `darwin-rebuild rollback`                    | Rollback to previous  |

### Ollama Aliases

Local LLM management:

| Alias          | Command                | Description           |
| -------------- | ---------------------- | --------------------- |
| `ollama-start` | `ollama serve`         | Start Ollama server   |
| `models`       | `ollama list`          | List installed models |
| `llama3`       | `ollama run llama3`    | Chat with Llama 3     |
| `codellama`    | `ollama run codellama` | Chat with Code Llama  |

**Examples:**

```bash
ollama-start        # Start Ollama in background
models              # See what's installed
llama3              # Start chatting
```

### Network Utilities

Network information shortcuts:

| Alias     | Command                                 | Description     |
| --------- | --------------------------------------- | --------------- |
| `myip`    | `curl -s https://api.ipify.org && echo` | Public IP       |
| `localip` | `ipconfig getifaddr en0`                | Local IP        |
| `ports`   | `sudo lsof -iTCP -sTCP:LISTEN -n -P`    | Listening ports |

**Examples:**

```bash
myip                # Show public IP
localip             # Show local network IP
ports               # What's listening?
```

### General Shortcuts

Miscellaneous useful aliases:

| Alias     | Command                                        | Description                 |
| --------- | ---------------------------------------------- | --------------------------- |
| `vs`      | `code .`                                       | Open VS Code in current dir |
| `zshrc`   | `code ~/.zshrc && source ~/.zshrc`             | Edit and reload zshrc       |
| `gitconf` | `code ~/.gitconfig`                            | Edit git config             |
| `reload`  | `source ~/.zshrc && echo '✅ .zshrc reloaded'` | Reload shell                |
| `cp`      | `cp -i`                                        | Copy with confirmation      |
| `mv`      | `mv -i`                                        | Move with confirmation      |
| `rm`      | `rm -i`                                        | Remove with confirmation    |
| `cleanup` | `cleanup-standard`                             | Standard cleanup (default)  |
| `clean`   | `cleanup-quick`                                | Quick cleanup               |

---

## Shell Functions

### File & Directory

```bash
mkcd dirname        # Create directory and cd into it
extract file.zip    # Extract any archive type
backup file.txt     # Create timestamped backup
newproj myapp       # Create ~/Dev/myapp and open in VS Code
```

### Search & Info

```bash
histgrep searchterm # Search command history
sysinfo            # Complete system information
pyenv-info         # Python environment details
port 3000          # Check what's running on port 3000
killport 3000      # Kill process running on port 3000
kill-port 3000     # Alternative (with hyphen)
```

### Network

```bash
kill-port 3000     # Kill process on port 3000
```

### Git

```bash
gcl repo-url       # Git clone and cd into it
# Auto-detect directory name from URL
gcl https://github.com/user/repo.git
# → Clones to "repo/" and cd into it

# Specify custom directory name
gcl https://github.com/user/repo.git my-custom-name
# → Clones to "my-custom-name/" and cd into it
```

### Interview Prep & Learning

**Algorithm Practice:**

```bash
newalgo two-sum
# Creates:
#   ~/Dev/algorithms/two-sum/
#   ├── solution.py       # Template with test cases
#   ├── tests.py          # Pytest setup
#   └── README.md         # Problem description
```

**System Design:**

```bash
design url-shortener
# Creates:
#   ~/Dev/learning/system-design/url-shortener/
#   ├── README.md         # Design template
#   └── diagrams/         # For Mermaid diagrams
```

**RAG Projects:**

```bash
newrag my-chatbot
# Creates UV-based RAG project with:
#   - pyproject.toml
#   - src/ structure
#   - .venv activated
```

**Benchmarking:**

```bash
bench-algo          # Benchmark solution.py with hyperfine
```

**Quick Notes:**

```bash
note "Meeting notes here"   # Appends to ~/daily-notes.md
```

### Update Functions

Modular update system for different components:

**Individual Updates:**

```bash
update-nix          # Update Nix Darwin only
update-brew         # Update Homebrew packages
update-mamba        # Update micromamba environments
update-vscode       # Update VS Code extensions
update-mas          # Update Mac App Store apps
```

**Combined Updates:**

```bash
update-dev          # Quick: Nix + Mamba + VS Code
update-system       # System: Nix + Homebrew
update-all          # Everything: All of the above + macOS check
```

**Example output:**

```
🚀 Starting comprehensive update...
📦 Updating Nix flake...
✅ Nix update completed
📦 Updating Homebrew...
✅ Homebrew update completed
...
📊 Update Summary:
⏱️  Duration: 12 minutes 34 seconds
❌ Errors: 0
✅ Update complete!
```

### Cleanup Functions

**Tier-Based Cleanup System** with 5 levels + 7 tool-specific functions:

#### Cleanup Tiers

**1. Safe (Conservative, No Confirmations):**
```bash
cleanup-safe [--dry-run]
# Safest cleanup - no confirmations needed
# - Empty trash & temp files
# - Nix GC (keep last 5 generations)
# - Homebrew cleanup (30 days)
```

**2. Quick (Daily/Weekly):**
```bash
cleanup-quick [--dry-run]
# or use alias: clean
# Fast cleanup for regular use
# - Everything in safe
# - Micromamba clean
# - Docker images (keep volumes)
# - Python caches (pip, UV)
# - npm cache
```

**3. Standard (Default):**
```bash
cleanup [--dry-run] [--yes]
# or: cleanup-standard
# Recommended for regular maintenance
# - Everything in quick
# - UV cache cleanup
# - Git repository cleanup
# - AWS cache cleanup
# - VS Code caches
# - System logs (safe)
```

**4. Dev (Development-Focused):**
```bash
cleanup-dev [--dry-run] [--yes]
# For active developers
# - Everything in standard
# - Terraform .terraform directories
# - Jupyter checkpoints
# - Python __pycache__ across projects
# - Docker build cache
```

**5. Aggressive (Maximum Cleanup):**
```bash
cleanup-aggressive [--dry-run] [--yes]
# or use backward-compatible alias: cleanup-all
# Maximum cleanup WITH CONFIRMATIONS
# - Everything in dev
# - All tool caches (Ollama models, HuggingFace)
# - All development artifacts
# - macOS: Time Machine snapshots
# - Old downloads (30+ days)
# - All Docker volumes
# - Nix: keep only last 2 generations
```

#### Tool-Specific Cleanup

**Nix:**
```bash
cleanup-nix [--dry-run] [--keep=N]
# Nix-specific with generation management
# Default: keep last 5 generations
```

**Docker:**
```bash
cleanup-docker [--dry-run] [--volumes]
# Docker-specific cleanup
# --volumes: Also remove volumes (DESTRUCTIVE)
```

**Python/UV:**
```bash
cleanup-python [--dry-run]
# Clean UV cache, pip cache, __pycache__
```

**Git:**
```bash
cleanup-git [--dry-run] [--dir=PATH]
# Optimize Git repositories in directory
# Default: ~/Dev
```

**AWS:**
```bash
cleanup-aws [--dry-run]
# Clean AWS CLI cache
```

**Terraform:**
```bash
cleanup-terraform [--dry-run] [--dir=PATH]
# Remove .terraform directories
# Default: ~/Dev
```

**macOS:**
```bash
cleanup-macos [--dry-run] [--yes]
# macOS-specific: Time Machine snapshots, system caches
```

#### Common Flags

- `--dry-run` - Preview operations without executing
- `--yes` or `-y` - Skip all confirmation prompts
- `--help` or `-h` - Show help message

#### Cleanup History

All cleanup operations are logged to `~/.cleanup-history`:

```bash
cat ~/.cleanup-history
# [2025-11-03 14:32:15] [safe] Starting safe cleanup (dry_run=false)
# [2025-11-03 14:32:31] [safe] Completed in 16s (disk: 125GB → 125GB)
```

#### Recommended Usage

- **Daily:** `cleanup-quick` or `clean`
- **Weekly:** `cleanup` (standard)
- **Monthly:** `cleanup-dev` (if you develop)
- **Quarterly:** `cleanup-aggressive --dry-run` (review first), then run without `--dry-run`

### User Data Functions

Manage application configs and user content that can't be managed declaratively:

```bash
backup-user-data   # Backup configs to user-data/
restore-user-data  # Restore configs from user-data/
sync-user-data     # Backup + git commit + push (one command)
```

**What gets backed up:**
- VS Code settings, argv.json, spell dictionary, snippets
- iTerm2 preferences
- Claude, Continue.dev, Gemini configs
- Cursor configs
- Jupyter and IPython configs
- SSH known_hosts, Zoxide database
- Claude todos

**Example workflow:**
```bash
# Change VS Code settings in UI
sync-user-data     # Automatically: backup → commit → push
```

See: [user-data/README.md](../../user-data/README.md)

### Work-Specific Functions

**Only available when `MACHINE_MODE="work"`**

**AWS SSO:**

```bash
awslogin           # AWS SSO login for work-domain
awslogout          # Clear SSO cache
awsrefresh         # Refresh credentials
awscheck           # Check session status
```

**SSM Access:**

```bash
ssm i-1234567890   # Start SSM session to EC2 instance
```

**Quick Navigation:**

```bash
vpn                # Open VPN
cdwork             # cd ~/work
cdrepo             # cd ~/work/repos
```

---

## Python Auto-Activation

**Automatic virtual environment activation on `cd`!**

When you `cd` into a directory with `.venv`, `venv`, or `env`, it automatically activates.

**Example:**

```bash
cd ~/Dev/myproject
# 🐍 Activated venv: /Users/jimmy/Dev/myproject/.venv

# Deactivates when you leave
cd ..
# 🔴 Deactivated venv
```

**Supported Directories:**

| Directory | Priority | Description                |
| --------- | -------- | -------------------------- |
| `.venv`   | 1st      | Modern standard (UV, venv) |
| `venv`    | 2nd      | Traditional venv           |
| `env`     | 3rd      | Alternative name           |

---

## Oh-My-Zsh Plugins

**Built-in plugins enabled (19):**

- git, docker, docker-compose, terraform, aws, kubectl
- python, pip, virtualenv
- fzf, z, dirhistory, sudo
- extract, copypath, copyfile
- colored-man-pages, command-not-found, web-search
- jsontools, encode64, safe-paste

**Custom plugins (5):**

- zsh-autosuggestions - Command suggestions as you type
- zsh-syntax-highlighting - Green/red command highlighting
- zsh-completions - 100+ additional completions
- you-should-use - Reminds you to use aliases
- zsh-history-substring-search - Up/Down arrow history search

**Plugin Features:**

```bash
# Press ESC twice → adds sudo to current command
ls /root
# Press ESC ESC → becomes: sudo ls /root

# Alt+Left/Right → navigate directory history

# copypath → copies current directory path to clipboard

# pp_json file.json → pretty print JSON

# Type part of command, press Up → searches history
```

---

## Git Configuration

All git aliases use the `g` prefix pattern for consistency. Example: `g s` (not `gs`).

### Basic Operations

**Status & Add:**

| Alias       | Command         | Description       |
| ----------- | --------------- | ----------------- |
| `g s`       | `status`        | Short status      |
| `g st`      | `status`        | Status            |
| `g a`       | `add`           | Add files         |
| `g aa`      | `add --all`     | Add all files     |
| `g ap`      | `add --patch`   | Add interactively |
| `g unstage` | `reset HEAD --` | Unstage files     |

**From zsh.nix:**

| Alias | Command         | Description |
| ----- | --------------- | ----------- |
| `gs`  | `git status`    | Status      |
| `ga`  | `git add`       | Add files   |
| `gaa` | `git add --all` | Add all     |

**Checkout & Switch:**

| Alias   | Command            | Description            |
| ------- | ------------------ | ---------------------- |
| `g co`  | `checkout`         | Checkout branch/commit |
| `g cod` | `checkout develop` | Checkout develop       |
| `gco`   | `git checkout`     | Checkout               |

**Examples:**

```bash
gs                  # Check status
ga file1.js file2.js # Add specific files
gaa                 # Add everything
g ap                # Interactive add
g unstage file.js   # Unstage files
g co main           # Switch to main
g co -b feature-xyz # Create and switch to new branch
```

### Commit Shortcuts

**Standard Commits:**

| Alias        | Command                    | Description                    |
| ------------ | -------------------------- | ------------------------------ |
| `g ci`       | `commit`                   | Commit                         |
| `g cm`       | `commit -m`                | Commit with message            |
| `g cam`      | `commit -a -m`             | Commit all with message        |
| `g amend`    | `commit --amend --no-edit` | Amend without changing message |
| `g recommit` | `commit --amend --no-edit` | Same as amend                  |
| `gc`         | `git commit`               | Commit                         |
| `gcm`        | `git commit -m`            | Commit with message            |
| `gca`        | `git commit --amend`       | Amend last commit              |

**Quick Save Points:**

| Alias        | Command                       | Description         |
| ------------ | ----------------------------- | ------------------- |
| `g save`     | Add all + commit as SAVEPOINT | Quick savepoint     |
| `g wipe`     | Add all + commit + reset hard | Wipe to last commit |
| `g snapshot` | Stash save + stash apply      | Quick snapshot      |

**Examples:**

```bash
gcm "Add user authentication"  # Commit with message
g cam "Fix bug in login"       # Commit all changes
g amend                        # Amend last commit (keep message)
gca                            # Amend and change message
g save                         # Quick save work in progress
g wipe                         # Discard all changes
```

### Branch Management

**List & Info:**

| Alias        | Command                       | Description                 |
| ------------ | ----------------------------- | --------------------------- |
| `g b`        | `branch`                      | List branches               |
| `g ba`       | `branch -a`                   | List all (including remote) |
| `g branches` | `branch -a -vv`               | Verbose branch list         |
| `g recent`   | Show recently worked branches | Recently worked branches    |
| `gb`         | `git branch`                  | List branches               |

**Cleanup:**

| Alias      | Command                              | Description            |
| ---------- | ------------------------------------ | ---------------------- |
| `g bclean` | Delete merged branches               | Delete merged branches |
| `g bdone`  | Checkout main + pull + clean         | Finish branch workflow |
| `g gone`   | Delete branches where remote is gone | Delete gone remotes    |

**Branch Status:**

| Alias        | Command                        | Description         |
| ------------ | ------------------------------ | ------------------- |
| `g stat`     | `diff --stat`                  | Short branch status |
| `g ahead`    | Show commits ahead of upstream | Commits ahead       |
| `g behind`   | Show commits behind upstream   | Commits behind      |
| `g diverged` | Show branch divergence         | Branch divergence   |

**Examples:**

```bash
g b                 # List local branches
g ba                # List all branches
g branches          # Detailed branch info
g recent            # What did I work on recently?
g bclean            # Clean up merged branches
g bdone             # Checkout main, pull, clean up
g gone              # Delete branches with deleted remotes
```

### Stash Operations

| Alias       | Command         | Description                |
| ----------- | --------------- | -------------------------- |
| `g pop`     | `stash pop`     | Apply and remove top stash |
| `g stp`     | `stash pop`     | Same as pop                |
| `g stashes` | `stash list`    | List all stashes           |
| `gst`       | `git stash`     | Stash changes              |
| `gstp`      | `git stash pop` | Pop stash                  |

**Examples:**

```bash
gst                # Stash current changes
g stashes          # List all stashes
g pop              # Apply and remove latest stash
g snapshot         # Stash but keep in working tree
```

### Log & History

**Basic Log:**

| Alias    | Command                    | Description               |
| -------- | -------------------------- | ------------------------- |
| `g l`    | `log --oneline`            | One line per commit       |
| `g last` | `log -1 HEAD`              | Last commit               |
| `g lg`   | Pretty log with graph      | Pretty log with graph     |
| `g lo`   | `log --oneline --decorate` | One line with decorations |
| `g ls`   | Log with author            | Compact with author       |
| `g ll`   | Log with file stats        | With file stats           |
| `gl`     | `git log --oneline -10`    | Last 10 commits           |
| `glog`   | Pretty git log with graph  | Visual history            |

**Time-Based Logs:**

| Alias         | Command                  | Description         |
| ------------- | ------------------------ | ------------------- |
| `g today`     | Show today's commits     | Today's commits     |
| `g yesterday` | Show yesterday's commits | Yesterday's commits |
| `g week`      | Show this week's commits | This week's commits |

**Examples:**

```bash
gl                 # Quick view of last 10 commits
glog               # Beautiful graph view
g lg               # Same as glog
g last             # Details of last commit
g ll               # Log with file change stats
g today            # What did I commit today?
g yesterday        # What did I do yesterday?
g week             # This week's work
```

### Diff & Review

**Basic Diff:**

| Alias  | Command             | Description           |
| ------ | ------------------- | --------------------- |
| `g d`  | `diff`              | Diff unstaged changes |
| `g ds` | `diff --staged`     | Diff staged changes   |
| `gd`   | `git diff`          | Diff unstaged         |
| `gds`  | `git diff --staged` | Diff staged           |

**Advanced Diff:**

| Alias           | Command                                          | Description             |
| --------------- | ------------------------------------------------ | ----------------------- |
| `g changed`     | `diff --name-only`                               | List changed files      |
| `g unstaged`    | `diff --name-only`                               | Unstaged files          |
| `g staged`      | `diff --cached --name-only`                      | Staged files            |
| `g untracked`   | `ls-files --others --exclude-standard`           | Untracked files         |
| `g ignored`     | `ls-files --others --ignored --exclude-standard` | Ignored files           |
| `g files`       | Files changed in branch                          | Files changed in branch |
| `g filehistory` | `log --follow -p --`                             | File history with diffs |

**Review:**

| Alias      | Command                    | Description    |
| ---------- | -------------------------- | -------------- |
| `g review` | Review changes vs upstream | Review changes |

**Examples:**

```bash
gd                 # What changed (not staged)?
gds                # What will be committed?
g d file.js        # Diff specific file
g changed          # List all modified files
g staged           # What's staged?
g untracked        # What's not tracked?
g filehistory src/app.js  # Complete file history
```

### Find Commands

Powerful search utilities:

| Alias  | Command                         | Description     |
| ------ | ------------------------------- | --------------- |
| `g fb` | Find branches containing commit | Find branches   |
| `g ft` | Find tags containing commit     | Find tags       |
| `g fc` | Find commits by code (pickaxe)  | Find by code    |
| `g fm` | Find commits by message         | Find by message |

**Examples:**

```bash
g fb abc123        # Which branches have this commit?
g ft v1.2.0        # Which tags contain this commit?
g fc "password"    # Find commits that changed "password"
g fm "bug fix"     # Find commits with "bug fix" in message
```

### Team Insights

**Contributors:**

| Alias            | Command                           | Description         |
| ---------------- | --------------------------------- | ------------------- |
| `g contributors` | List contributors by commit count | All contributors    |
| `g who`          | Top 20 contributors this month    | Recent contributors |

**Activity:**

| Alias        | Command              | Description   |
| ------------ | -------------------- | ------------- |
| `g activity` | Recent team activity | Team activity |

**Examples:**

```bash
g contributors     # All time contributors
g who              # Who's been active this month?
g activity         # What's the team been up to?
```

### Sync & Update

**Pull & Push:**

| Alias  | Command           | Description      |
| ------ | ----------------- | ---------------- |
| `g pl` | `pull`            | Pull from remote |
| `g pr` | `pull --rebase`   | Pull with rebase |
| `g ps` | `push`            | Push to remote   |
| `gp`   | `git push`        | Push             |
| `gpo`  | `git push origin` | Push to origin   |
| `gpl`  | `git pull origin` | Pull from origin |

**Sync Helpers:**

| Alias       | Command                  | Description          |
| ----------- | ------------------------ | -------------------- |
| `g sync`    | Pull + push              | Full sync            |
| `g update`  | Fast-forward only update | Safe update          |
| `g catchup` | See what's new upstream  | See upstream changes |

**Examples:**

```bash
gpl main           # Pull from origin/main
gp                 # Push current branch
g pr               # Pull with rebase
g sync             # Sync current branch
g update           # Safe update (ff-only)
g catchup          # What's new on remote?
```

### Cleanup & Reset

**Reset Operations:**

| Alias           | Command                   | Description                    |
| --------------- | ------------------------- | ------------------------------ |
| `g rh`          | `reset HEAD`              | Reset to HEAD                  |
| `g undo`        | `reset HEAD~1 --mixed`    | Undo last commit, keep changes |
| `g uncommit`    | `reset --soft HEAD~1`     | Undo commit, keep staged       |
| `g undo-commit` | `reset --soft HEAD~1`     | Same as uncommit               |
| `gundo`         | `git reset --soft HEAD~1` | Undo last commit               |

**Clean:**

| Alias   | Command     | Description            |
| ------- | ----------- | ---------------------- |
| `g cdf` | `clean -df` | Remove untracked files |

**Examples:**

```bash
gundo              # Undo last commit, keep changes staged
g undo             # Undo last commit, unstage changes
g rh               # Reset staging area
g cdf              # Clean untracked files
```

### Common Workflows

**Feature Branch Workflow:**

```bash
# Start new feature
g co -b feature/new-feature

# Make changes
# ... edit files ...

# Check status
gs

# Add and commit
gaa
gcm "Add new feature"

# Push to remote
gp

# Later: update from main
g co main
gpl main
g co feature/new-feature
git rebase main

# Finish feature
g co main
git merge feature/new-feature
gp
g bclean
```

**Quick Fix Workflow:**

```bash
# Save current work
gst

# Make quick fix on main
g co main
# ... fix bug ...
gaa
gcm "Fix critical bug"
gp

# Return to feature work
g co feature/my-feature
gstp
```

**Review Before Push:**

```bash
# Check what you're about to push
gd                 # Unstaged changes
gds                # Staged changes
gl                 # Recent commits
glog               # Visual history

# Push when ready
gp
```

### Delta Configuration

Delta is configured for beautiful diffs with syntax highlighting:

```bash
gd file.js         # Shows diff with syntax highlighting
glog               # Pretty log with delta integration
```

**Configuration (automatic in .gitconfig):**

```ini
[core]
    pager = delta

[delta]
    navigate = true
    light = false
    side-by-side = true
    line-numbers = true
```

**Features:**

- Syntax highlighting - Language-aware
- Side-by-side - Compare old and new
- Line numbers - Easy reference
- Word-level diffs - Highlights exact changes

---

## Starship Prompt

**Fast, customizable shell prompt (Catppuccin Powerline theme)**

### Prompt Layout

```
 jimmy  ~/nix-darwin   main [!]  🐍 3.13.8  20:15  5.2s
❯
```

**Components:**

- - macOS icon
- `jimmy` - Username
- `~/nix-darwin` - Current directory (with icon)
- `main [!]` - Git branch + status
- 🐍 `3.13.8` - Python version (context-aware)
- `20:15` - Current time
- `5.2s` - Command duration (if > 500ms)
- `❯` - Prompt character (green = success, red = error)

### Starship Configuration

**Current Theme:** Catppuccin Powerline

**Switching Presets:**

```bash
# View available presets
starship preset -h

# Common presets:
# - catppuccin-powerline (current)
# - gruvbox-rainbow
# - tokyo-night
# - nerd-font-symbols
# - pure-preset
# - pastel-powerline
```

**Apply New Preset (The Nix Way):**

Update `home/_mixins/base.nix`:

```nix
home.file.".config/starship.toml".source =
  pkgs.runCommand "starship-PRESET-NAME" {} ''
    ${pkgs.starship}/bin/starship preset PRESET-NAME -o $out
  '';
```

Then rebuild:

```bash
nix-rebuild
exec zsh
```

**Testing Configuration:**

```bash
# Test starship is working
starship --version

# Check which config is loaded
echo $STARSHIP_CONFIG

# View current config
cat ~/.config/starship.toml

# Debug module timing (if prompt is slow)
starship timings
```

### iTerm2 Keyboard Shortcuts

**Essential Shortcuts:**

**Tabs & Windows:**
| Shortcut | Action |
|----------|--------|
| `⌘` + `T` | New tab |
| `⌘` + `W` | Close tab/window |
| `⌘` + `Number` | Jump to tab N |
| `⌘` + `Left/Right` | Previous/Next tab |
| `⌘` + `` ` `` | Cycle windows |

**Split Panes:**
| Shortcut | Action |
|----------|--------|
| `⌘` + `D` | Split vertically |
| `⌘` + `Shift` + `D` | Split horizontally |
| `⌘` + `Option` + `Arrow` | Navigate split panes |
| `⌘` + `Shift` + `Enter` | Maximize current pane |
| `Ctrl` + `⌘` + `Arrow` | Resize pane |

**Shell Navigation:**
| Shortcut | Action |
|----------|--------|
| `Ctrl` + `A` | Go to line start |
| `Ctrl` + `E` | Go to line end |
| `⌥` + `Left/Right` | Move by word |
| `Ctrl` + `U` | Delete to line start |
| `Ctrl` + `K` | Delete to line end |
| `Ctrl` + `W` | Delete previous word |

**Command History:**
| Shortcut | Action |
|----------|--------|
| `Ctrl` + `R` | Search history (fuzzy with fzf) |
| `Up/Down` | Previous/Next command |
| `Ctrl` + `G` | Cancel search |

**Utilities:**
| Shortcut | Action |
|----------|--------|
| `⌘` + `/` | Find cursor |
| `⌘` + `K` | Clear screen |
| `⌘` + `F` | Find in terminal |
| `⌘` + `Alt` + `I` | Broadcast to all panes |

### Customization

**Use Custom TOML Instead:**

Replace the preset with custom TOML:

```nix
home.file.".config/starship.toml".text = ''
  "$schema" = 'https://starship.rs/config-schema.json'

  format = """
  $username\
  $directory\
  $git_branch\
  $git_status\
  $python\
  $nodejs\
  $character"""

  [character]
  success_symbol = "[➜](bold green)"
  error_symbol = "[➜](bold red)"

  [directory]
  truncation_length = 3
  style = "bold cyan"

  [git_branch]
  symbol = " "
  style = "bold purple"
'';
```

**Using Nix Settings (Alternative to Presets):**

Configure directly in Nix:

```nix
programs.starship = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    add_newline = true;

    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
    };

    directory = {
      truncation_length = 3;
      truncation_symbol = "…/";
      style = "bold cyan";
    };

    git_branch = {
      symbol = " ";
      style = "bold purple";
    };

    python = {
      symbol = "🐍 ";
      pyenv_version_name = true;
    };
  };
};
```

### Troubleshooting

**Icons Not Showing:**

1. Verify Nerd Font is installed:

   ```bash
   fc-list | grep -i "meslo"
   ```

2. Set iTerm2 font:

   - `⌘` + `,` → Profiles → Text → Font
   - Select "MesloLGM Nerd Font Mono"
   - Size: 13-14

3. Verify terminal supports Unicode:
   ```bash
   echo ""  # Should show a nice icon
   ```

**Prompt Not Updating:**

```bash
# 1. Rebuild Nix config
nix-rebuild

# 2. Restart shell
exec zsh

# 3. Or reload starship manually
eval "$(starship init zsh)"
```

**Slow Prompt:**

```bash
# 1. Identify slow module
starship timings

# 2. Disable heavy modules
[git_status]
disabled = true

[python]
scan_timeout = 10
```

---

## Configuration Files

### Zsh Configuration

**File:** `home/jimmy/shell/zsh.nix`

Contains:

- All shell aliases (lines 36-274)
- Custom functions (lines 341-1183)
- Plugin configuration (lines 28-37)
- Environment variables

### Git Configuration

**File:** `home/jimmy/programs/git.nix`

Contains:

- Git user settings
- All git aliases in `programs.git.settings.alias` section
- Delta configuration
- Git settings (core, diff, merge, etc.)

### Starship Configuration

**File:** `home/_mixins/base.nix` (lines 37-47)

Contains:

- Starship enablement
- Preset configuration
- TOML generation

**Generated Config:** `~/.config/starship.toml` (managed by Nix)

### Modify Configuration

**Zsh aliases/functions:**

1. Edit `home/jimmy/shell/zsh.nix`
2. Rebuild: `nix-rebuild`
3. Restart: `exec zsh`

**Git aliases:**

1. Edit `home/jimmy/programs/git.nix`
2. Add/modify in `alias = { ... }` section
3. Rebuild: `nix-rebuild`

**Starship theme:**

1. Edit `home/_mixins/base.nix`
2. Change preset name or use custom TOML
3. Rebuild: `nix-rebuild`
4. Restart: `exec zsh`

---

## Links

**Shell & Git:**

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Git Official Docs](https://git-scm.com/doc)

**Starship:**

- [Starship Homepage](https://starship.rs/)
- [Configuration Reference](https://starship.rs/config/)
- [Presets Gallery](https://starship.rs/presets/)
- [Advanced Config](https://starship.rs/advanced-config/)

**Themes & Fonts:**

- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Catppuccin for iTerm2](https://github.com/catppuccin/iterm)

**Related Documentation:**

- [Modern CLI Tools](modern-cli.md) - eza, bat, ripgrep, fd, etc.
- [Python Reference](python.md) - Python auto-activation
- [Configuration Guide](../guides/configuration.md) - How to customize
- [Home Manager Reference](home-manager.md) - Understanding Nix configuration
