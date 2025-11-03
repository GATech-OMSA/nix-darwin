{ config, pkgs, lib, hostname, ... }:

{
  # ENHANCED Zsh configuration - Complete declarative shell setup
  # Includes: Auto-activation, aliases, functions, and update system

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    # Oh My Zsh integration
    oh-my-zsh = {
      enable = true;
      theme = "af-magic";  # Your current theme
      plugins = [
        # Version Control
        "git"

        # Development Tools
        "docker"
        "docker-compose"
        "terraform"
        "kubectl"

        # Cloud & AWS
        "aws"

        # Python Development
        "python"
        "pip"
        "virtualenv"

        # Productivity & Navigation
        "fzf"
        "z"  # Directory jumping (note: you also have zoxide via Nix)
        "dirhistory"  # Navigate dirs with Alt+Left/Right
        "sudo"  # Press ESC twice to add sudo

        # File Operations
        "extract"  # Extract any archive with 'extract filename'
        "copypath"  # Copy current path to clipboard
        "copyfile"  # Copy file contents to clipboard

        # Utilities
        "colored-man-pages"
        "command-not-found"
        "web-search"  # Search from terminal (google, stackoverflow, etc)
        "jsontools"  # Pretty print JSON (pp_json, is_json, urlencode_json)
        "encode64"  # Base64 encode/decode
        "safe-paste"  # Prevents accidental execution when pasting

        # Note: zsh-autosuggestions and zsh-syntax-highlighting
        # are sourced manually below since they're installed in ~/.oh-my-zsh/custom
        # To add: zsh-completions, you-should-use, zsh-history-substring-search
      ];
    };

    # COMPLETE Shell aliases - merged from all sources
    shellAliases = {
      # ============================================
      # GENERAL & CONFIGURATION
      # ============================================
      c = "clear";
      C = "clear";
      code = "code .";
      vs = "code .";
      zshrc = "$EDITOR ~/nix-darwin/home/jimmy/shell/zsh.nix && darwin-rebuild switch --flake ~/nix-darwin";
      gitconf = "$EDITOR ~/nix-darwin/home/jimmy/programs/git.nix";
      condaconf = "$EDITOR ~/.condarc";
      awsconf = "$EDITOR ~/.aws/config";
      jupyterconf = "$EDITOR ~/.jupyter/jupyter_notebook_config.py";
      reload = "source ~/.zshrc && echo '✅ .zshrc reloaded'";
      restart = "exec zsh";


      # Safety aliases
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

      # ============================================
      # NAVIGATION
      # ============================================
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "~" = "cd ~";
      "-" = "cd -";

      # Quick directories
      dev = "cd ~/Dev";
      downloads = "cd ~/Downloads";
      apps = "cd ~/Applications";
      docs = "cd ~/Documents";
      algo = "cd ~/Dev/algorithms";
      desktop = "cd ~/Desktop";
      down = "cd ~/Downloads";
      desk = "cd ~/Desktop";

      # Personal-specific navigation
      learning = "cd ~/Dev/learning";
      aiml = "cd ~/Dev/ai-ml";
      courses = "cd ~/Dev/courses";
      experiments = "cd ~/Dev/experiments";
      oss = "cd ~/Dev/open-source";

      # ============================================
      # MODERN CLI TOOLS
      # ============================================
      ls = "eza --icons --group-directories-first";
      ll = "eza -al --icons --group-directories-first";
      la = "eza -a --icons --group-directories-first";
      lt = "eza --tree --level=2 --icons";
      cat = "bat --style=plain --paging=never";
      catp = "bat -p";
      grep = "rg";
      rgi = "rg -i";
      find = "fd";
      du = "dust";
      df = "duf";
      top = "btop";

      # ============================================
      # PYTHON - MULTI-TIER SETUP (UV + Micromamba)
      # ============================================
      # Create your own environments: micromamba create -n myenv python=3.12 -y
      # Activate: micromamba activate myenv
      py = "python";
      ipy = "ipython";
      jl = "jupyter lab";
      jn = "jupyter notebook";

      # UV commands
      "uv-new" = "uv init";
      "uv-venv" = "uv venv";
      "uv-add" = "uv add";
      "uv-sync" = "uv sync";
      "uv-run" = "uv run";
      activate = "source .venv/bin/activate";

      # Linting & Formatting
      lint = "ruff check .";
      format = "ruff format .";
      "lint-fix" = "ruff check --fix .";

      # Environment management
      "list-envs" = "micromamba env list";
      lsenv = "micromamba env list";
      condalist = "conda env list";
      mambalist = "micromamba env list";

      # ============================================
      # GIT - Universal prefix
      # ============================================
      # All git aliases are defined in git.nix (60+ aliases!)
      # Use 'g' as prefix: g s, g d, g co, g recent, g sync, etc.
      # Examples:
      #   g s          -> git status -s
      #   g st         -> git status (full)
      #   g aa         -> git add --all
      #   g cm "msg"   -> git commit -m "msg"
      #   g recent     -> show recent branches
      #   g today      -> today's commits
      #   g sync       -> fetch and pull
      g = "git";

      # ============================================
      # AWS HELPERS
      # ============================================
      # Quick profile switching (usage: awsp project-env)
      awsp = "export AWS_PROFILE=";
      # Show current profile
      awsprofile = "echo $AWS_PROFILE";
      # Check current identity (uses AWS_PROFILE if set)
      awswho = "aws sts get-caller-identity";

      # ============================================
      # TERRAFORM HELPERS
      # ============================================
      tf = "terraform";
      tfi = "terraform init";
      tfp = "terraform plan";
      tfa = "terraform apply";
      tfv = "terraform validate";
      tff = "terraform fmt";

      # ============================================
      # DOCKER HELPERS
      # ============================================
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dlogs = "docker logs -f";
      dimg = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";
      dex = "docker exec -it";  # Quick shell into container
      drun = "docker run -it --rm";  # Quick test container
      dprune = "docker system prune -af";  # Deep clean

      # ============================================
      # KUBERNETES HELPERS
      # ============================================
      k = "kubectl";
      kg = "kubectl get";
      kd = "kubectl describe";
      kl = "kubectl logs";
      k9 = "k9s";

      # ============================================
      # NETWORK UTILITIES
      # ============================================
      myip = "curl -s https://api.ipify.org && echo";
      localip = "ipconfig getifaddr en0";
      ports = "sudo lsof -iTCP -sTCP:LISTEN -n -P";

      # ============================================
      # USEFUL SHORTCUTS
      # ============================================
      h = "history";
      j = "jobs -l";
      path = "echo -e \${PATH//:/\\\\n}";
      now = "date +\"%Y-%m-%d %H:%M:%S\"";
      week = "date +%V";

      # ============================================
      # OLLAMA SHORTCUTS
      # ============================================
      "ollama-start" = "ollama serve";
      models = "ollama list";
      llama3 = "ollama run llama3";
      codellama = "ollama run codellama";

      # ============================================
      # NIX-DARWIN ALIASES
      # ============================================
      "nix-rebuild" = "sudo darwin-rebuild switch --flake ~/nix-darwin";
      "nix-switch" = "sudo darwin-rebuild switch --flake ~/nix-darwin";
      "nix-check" = "darwin-rebuild check --flake ~/nix-darwin";
      "nix-test" = "darwin-rebuild build --flake ~/nix-darwin";
      "nix-update" = "cd ~/nix-darwin && nix flake update && sudo darwin-rebuild switch --flake .";
      "nix-clean" = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix-store --optimize";
      "nix-generations" = "darwin-rebuild --list-generations";
      "nix-rollback" = "sudo darwin-rebuild rollback";
      "nix-list" = "nix-env -q";
      "nix-search" = "nix search nixpkgs";

      # ============================================
      # CLEANUP ALIASES
      # ============================================
      cleanup = "cleanup-all";
      clean = "cleanup-quick";
    };

    # Init content (combined: micromamba early, then main config)
    initContent = lib.mkMerge [
      # Micromamba init runs BEFORE completion (order 550)
      (lib.mkOrder 550 ''
        # Load micromamba early
        if command -v micromamba &> /dev/null; then
          export MAMBA_EXE="$(which micromamba)"
          export MAMBA_ROOT_PREFIX="$HOME/micromamba"
          eval "$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
        fi
      '')

      # Main shell configuration (runs after oh-my-zsh)
      ''
      # ============================================
      # SOURCE SECRETS
      # ============================================
      [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

      # ============================================
      # LOAD CUSTOM OH-MY-ZSH PLUGINS
      # ============================================
      # These plugins are installed manually in ~/.oh-my-zsh/custom/plugins
      # and need to be sourced separately from the Nix-managed oh-my-zsh

      # Autosuggestions - suggests commands as you type
      if [ -f ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
      fi

      # Syntax highlighting - highlights valid/invalid commands
      if [ -f ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      fi

      # Additional completions
      if [ -d ~/.oh-my-zsh/custom/plugins/zsh-completions ]; then
        fpath+=(~/.oh-my-zsh/custom/plugins/zsh-completions/src)
      fi

      # You-should-use - reminds you to use aliases
      if [ -f ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh
      fi

      # History substring search - search history with arrow keys
      if [ -f ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
        # Bind keys for history search
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
      fi

      # ============================================
      # TERRAFORM PLUGIN CACHE
      # ============================================
      mkdir -p "$TF_PLUGIN_CACHE_DIR"

      # ============================================
      # WELCOME MESSAGE
      # ============================================
      if [ "$TERM_PROGRAM" != "vscode" ]; then
        echo "$MACHINE_MODE | Python: $(python --version 2>&1 | awk '{print $2}')"
      fi

      # ============================================
      # CRITICAL: UV/VENV AUTO-ACTIVATION ON CD
      # ============================================
      # This is the feature you asked about!
      # Automatically activates Python virtual environments when you cd into a directory

      function auto_activate_venv() {
        # Deactivate any existing virtual environment
        if [ -n "$VIRTUAL_ENV" ]; then
          deactivate 2>/dev/null || true
        fi

        # Check for UV project (pyproject.toml + .venv)
        if [ -f "pyproject.toml" ] && [ -d ".venv" ]; then
          source .venv/bin/activate
          echo "🐍 Activated UV virtual environment: .venv"
          return
        fi

        # Check for any .venv directory
        if [ -d ".venv" ]; then
          source .venv/bin/activate
          echo "🐍 Activated virtual environment: .venv"
          return
        fi

        # Check for venv directory
        if [ -d "venv" ]; then
          source venv/bin/activate
          echo "🐍 Activated virtual environment: venv"
          return
        fi

        # Check for other common venv names
        if [ -d "env" ]; then
          source env/bin/activate
          echo "🐍 Activated virtual environment: env"
          return
        fi
      }

      # Hook into chpwd (runs after every cd)
      autoload -U add-zsh-hook
      add-zsh-hook chpwd auto_activate_venv

      # Also check on shell startup
      auto_activate_venv

      # ============================================
      # UTILITY FUNCTIONS
      # ============================================

      # Create directory and cd into it
      function mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Extract any archive
      function extract() {
        if [ -f $1 ]; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Quick backup
      function backup() {
        if [ -z "$1" ]; then
          echo "Usage: backup <file/directory>"
          return 1
        fi
        cp -r "$1" "$1.backup.$(date +%Y%m%d-%H%M%S)"
        echo "✅ Backed up $1"
      }

      # Search history
      function histgrep() {
        history | grep "$1"
      }

      # Kill process on port
      function kill-port() {
        if [ -z "$1" ]; then
          echo "Usage: kill-port <port>"
          return 1
        fi
        lsof -ti:$1 | xargs kill -9
        echo "✅ Killed process on port $1"
      }

      # Git clone and cd
      function gcl() {
        git clone "$1" && cd "$(basename "$1" .git)"
      }

      # ============================================
      # SYSTEM INFO FUNCTION
      # ============================================
      function sysinfo() {
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "macOS: $(sw_vers -productVersion)"
        echo "Machine: $MACHINE_MODE"
        echo "Architecture: $(uname -m)"
        if command -v nix &> /dev/null; then
          echo "Nix: $(nix --version | head -1)"
        fi
        if command -v python &> /dev/null; then
          echo "Python: $(python --version 2>&1)"
        fi
        if command -v node &> /dev/null; then
          echo "Node: $(node --version)"
        fi
        if command -v docker &> /dev/null; then
          echo "Docker: $(docker --version | awk '{print $3}' | tr -d ',')"
        fi
        if command -v terraform &> /dev/null; then
          echo "Terraform: $(terraform --version | head -1 | awk '{print $2}')"
        fi
        if command -v kubectl &> /dev/null; then
          echo "Kubectl: $(kubectl version --client --short 2>&1 | head -1)"
        fi
      }

      # ============================================
      # PYTHON ENVIRONMENT INFO
      # ============================================
      function pyenv-info() {
        echo "=== Python Environment Info ==="
        echo "Machine: $MACHINE_MODE"
        if [ -n "$VIRTUAL_ENV" ]; then
          echo "Virtual Env: $VIRTUAL_ENV"
        elif [ -n "$CONDA_DEFAULT_ENV" ]; then
          echo "Micromamba Env: $CONDA_DEFAULT_ENV"
        else
          echo "No virtual environment active"
        fi
        echo "Python: $(which python)"
        echo "Version: $(python --version 2>&1)"
        if command -v pip &> /dev/null; then
          echo "Pip: $(pip --version)"
        fi
        if command -v uv &> /dev/null; then
          echo "UV: $(uv --version)"
        fi
      }

      # ============================================
      # UV PYTHON HELPERS
      # ============================================
      function uv-new() {
        uv init $1
        cd $1
        uv venv
        source .venv/bin/activate
        echo "✅ UV project created and activated: $1"
      }

      function uv-venv() {
        uv venv
        source .venv/bin/activate
        echo "✅ UV virtual environment created and activated"
      }

      function activate() {
        if [ -f .venv/bin/activate ]; then
          source .venv/bin/activate
          echo "✅ Activated .venv"
        elif [ -f venv/bin/activate ]; then
          source venv/bin/activate
          echo "✅ Activated venv"
        else
          echo "❌ No virtual environment found in current directory"
        fi
      }

      # ============================================
      # INTERVIEW PREP & LEARNING HELPERS
      # ============================================

      # Quick algorithm problem setup
      function newalgo() {
        if [ -z "$1" ]; then
          echo "Usage: newalgo <problem-name>"
          return 1
        fi
        mkdir -p ~/Dev/learning/algorithms/$1
        cd ~/Dev/learning/algorithms/$1
        cat > solution.py <<'EOF'
"""
Problem: TODO
Link: TODO
Difficulty: TODO

Approach:
1. TODO

Time Complexity: O(?)
Space Complexity: O(?)
"""

def solution():
    pass

if __name__ == "__main__":
    # Test cases
    pass
EOF
        cat > test_solution.py <<'EOF'
import pytest
from solution import solution

def test_example():
    assert solution() == None  # TODO: Add test cases
EOF
        cat > README.md <<'EOF'
# Problem Name

## Problem Statement
TODO

## Approach
TODO

## Complexity
- Time: O(?)
- Space: O(?)

## Notes
TODO
EOF
        echo "✅ Algorithm problem setup created: $1"
        echo "   - solution.py"
        echo "   - test_solution.py"
        echo "   - README.md"
        code .
      }

      # System design practice template
      function design() {
        if [ -z "$1" ]; then
          echo "Usage: design <system-name>"
          return 1
        fi
        mkdir -p ~/Dev/learning/system-design/$1/diagrams
        cd ~/Dev/learning/system-design/$1
        cat > README.md <<'EOF'
# System Design: TODO

## Requirements

### Functional Requirements
- TODO

### Non-Functional Requirements
- TODO

## Scale Estimation
- Users: TODO
- QPS: TODO
- Storage: TODO

## High-Level Design
TODO

## Detailed Component Design
TODO

## Data Model
TODO

## API Design
TODO

## Deep Dive
TODO

## References
- TODO
EOF
        cat > architecture.md <<'EOF'
# Architecture

## Components
1. TODO

## Data Flow
1. TODO

## Technology Stack
- TODO
EOF
        cat > diagrams/architecture.mmd <<'EOF'
graph TB
    Client[Client]
    LB[Load Balancer]
    API[API Server]
    DB[(Database)]
    Cache[(Cache)]

    Client --> LB
    LB --> API
    API --> Cache
    API --> DB
EOF
        echo "✅ System design practice created: $1"
        echo "   - README.md (full design doc)"
        echo "   - architecture.md"
        echo "   - diagrams/architecture.mmd (Mermaid)"
        echo ""
        echo "💡 Generate diagram: mmdc -i diagrams/architecture.mmd -o diagrams/architecture.png"
        code .
      }

      # Quick RAG project setup
      function newrag() {
        if [ -z "$1" ]; then
          echo "Usage: newrag <project-name>"
          return 1
        fi
        mkdir -p ~/Dev/ai-ml/$1
        cd ~/Dev/ai-ml/$1
        uv init
        cat > pyproject.toml <<'EOF'
[project]
name = "TODO"
version = "0.1.0"
description = "RAG application"
dependencies = [
    "langchain",
    "chromadb",
    "sentence-transformers",
    "openai",
]

[tool.uv]
dev-dependencies = [
    "pytest",
    "ipython",
]
EOF
        mkdir -p src data notebooks
        cat > src/main.py <<'EOF'
"""
RAG Application Main Entry Point
"""

def main():
    print("RAG application starting...")
    # TODO: Implement RAG pipeline

if __name__ == "__main__":
    main()
EOF
        cat > README.md <<'EOF'
# RAG Project

## Setup
\`\`\`bash
uv sync
source .venv/bin/activate
\`\`\`

## Architecture
- Vector DB: ChromaDB
- Embeddings: sentence-transformers
- LLM: OpenAI/Ollama

## Usage
TODO
EOF
        uv venv
        source .venv/bin/activate
        echo "✅ RAG project created: $1"
        echo "   - UV environment configured"
        echo "   - Directory structure created"
        echo "   - Run: uv sync"
        code .
      }

      # Benchmark algorithm solution
      function bench-algo() {
        if [ ! -f solution.py ]; then
          echo "❌ solution.py not found in current directory"
          return 1
        fi
        echo "🔬 Benchmarking solution.py..."
        hyperfine --warmup 3 "python solution.py"
      }

      # Quick note-taking
      function note() {
        if [ -z "$1" ]; then
          echo "Usage: note <your note>"
          return 1
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $@" >> ~/Documents/daily-notes.md
        echo "✅ Note added to ~/Documents/daily-notes.md"
      }

      # ============================================
      # UPDATE FUNCTIONS (Modular)
      # ============================================

      function update-nix() {
        echo "❄️  Updating Nix Darwin..."
        local errors=0

        echo "  📦 Updating flake inputs..."
        cd ~/nix-darwin || return 1

        if nix flake update; then
          echo "  ✅ Flake inputs updated"
        else
          echo "  ❌ Flake update failed" >&2
          ((errors++))
        fi

        echo "  📦 Rebuilding darwin configuration..."
        if darwin-rebuild switch --flake .; then
          echo "  ✅ Darwin rebuild completed"
        else
          echo "  ❌ Darwin rebuild failed" >&2
          ((errors++))
        fi

        cd - > /dev/null

        if [ $errors -eq 0 ]; then
          echo "✅ Nix update completed successfully"
        else
          echo "⚠️  Nix update completed with $errors error(s)"
          return 1
        fi
      }

      function update-brew() {
        echo "🍺 Updating Homebrew..."
        local errors=0

        if command -v brew &> /dev/null; then
          echo "  📦 Updating Homebrew..."
          if brew update; then
            echo "  ✅ Homebrew updated"
          else
            echo "  ❌ Homebrew update failed" >&2
            ((errors++))
          fi

          echo "  📦 Upgrading packages..."
          if brew upgrade; then
            echo "  ✅ Packages upgraded"
          else
            echo "  ❌ Package upgrade failed" >&2
            ((errors++))
          fi

          echo "  📦 Upgrading casks..."
          if brew upgrade --cask; then
            echo "  ✅ Casks upgraded"
          else
            echo "  ❌ Cask upgrade failed" >&2
            ((errors++))
          fi

          echo "  🧹 Cleaning up..."
          if brew cleanup --prune=all; then
            echo "  ✅ Cleanup completed"
          else
            echo "  ❌ Cleanup failed" >&2
            ((errors++))
          fi

          echo "  🩺 Running diagnostics..."
          brew doctor
        else
          echo "  ⚠️  Homebrew not found"
          return 1
        fi

        if [ $errors -eq 0 ]; then
          echo "✅ Homebrew update completed successfully"
        else
          echo "⚠️  Homebrew update completed with $errors error(s)"
          return 1
        fi
      }

      # ============================================
      # MICROMAMBA CONVENIENCE FUNCTIONS
      # ============================================

      # Activate micromamba environment
      function act() {
        if [ -z "$1" ]; then
          echo "Usage: act <environment-name>"
          echo ""
          echo "Available environments:"
          micromamba env list
        else
          micromamba activate "$1"
        fi
      }

      # Deactivate micromamba environment
      function deact() {
        micromamba deactivate
      }

      # Create micromamba environment
      # Usage: mkenv <name> [python-version] [packages...]
      # Examples:
      #   mkenv myenv                    # Python 3.12 (default)
      #   mkenv myenv 3.13               # Python 3.13
      #   mkenv myenv 3.12 pandas numpy  # With packages
      function mkenv() {
        if [ -z "$1" ]; then
          echo "Usage: mkenv <name> [python-version] [packages...]"
          echo ""
          echo "Examples:"
          echo "  mkenv myenv                    # Python 3.12 (default)"
          echo "  mkenv myenv 3.13               # Python 3.13"
          echo "  mkenv myenv 3.12 pandas numpy  # With packages"
          return 1
        fi

        local name="$1"
        local python_version="3.12"
        local packages=""

        # Check if second argument is a Python version (starts with 3.)
        if [ -n "$2" ] && [[ "$2" =~ ^3\.[0-9]+$ ]]; then
          python_version="$2"
          shift 2
          packages="$@"
        else
          shift
          packages="$@"
        fi

        echo "Creating environment '$name' with Python $python_version..."
        if [ -n "$packages" ]; then
          echo "Installing packages: $packages"
          micromamba create -n "$name" python="$python_version" $packages -y
        else
          micromamba create -n "$name" python="$python_version" -y
        fi
      }

      # Remove micromamba environment
      function rmenv() {
        if [ -z "$1" ]; then
          echo "Usage: rmenv <environment-name>"
          echo ""
          echo "Available environments:"
          micromamba env list
        else
          echo "Removing environment '$1'..."
          micromamba env remove -n "$1" -y
        fi
      }

      # ============================================
      # UPDATE FUNCTIONS
      # ============================================

      function update-mamba() {
        echo "🐍 Updating Micromamba..."
        local errors=0

        if command -v micromamba &> /dev/null; then
          echo "  📦 Updating micromamba environments..."
          # Update all environments dynamically
          local env_list=$(micromamba env list | tail -n +3 | awk '{print $1}')
          if [ -n "$env_list" ]; then
            for env in $env_list; do
              if [ "$env" != "base" ]; then  # Skip the base installation
                echo "    • Updating $env..."
                if micromamba update -n "$env" --all -y 2>/dev/null; then
                  echo "    ✅ $env updated"
                else
                  echo "    ⚠️  $env skipped or failed" >&2
                fi
              fi
            done
          else
            echo "    ℹ️  No environments to update"
          fi
        else
          echo "  ⚠️  Micromamba not found"
          return 1
        fi

        if [ $errors -eq 0 ]; then
          echo "✅ Micromamba update completed successfully"
        else
          echo "⚠️  Micromamba update completed with $errors error(s)"
          return 1
        fi
      }

      function update-vscode() {
        echo "💻 Updating VS Code extensions..."

        if command -v code &> /dev/null; then
          code --list-extensions | while read extension; do
            code --install-extension "$extension" --force &> /dev/null
          done
          echo "✅ VS Code extensions updated"
        else
          echo "⚠️  VS Code not found"
          return 1
        fi
      }

      function update-mas() {
        echo "🍎 Updating Mac App Store apps..."

        if command -v mas &> /dev/null; then
          if mas upgrade; then
            echo "✅ Mac App Store apps updated"
          else
            echo "❌ Mac App Store update failed" >&2
            return 1
          fi
        else
          echo "⚠️  mas not found (install with: brew install mas)"
          return 1
        fi
      }

      function update-dev() {
        echo "⚡ Quick development update..."
        local start_time=$(date +%s)
        local errors=0

        update-nix || ((errors++))
        echo ""
        update-mamba || ((errors++))
        echo ""
        update-vscode || ((errors++))

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

        if [ $errors -eq 0 ]; then
          echo "✅ Development update completed!"
        else
          echo "⚠️  Completed with $errors error(s)"
          return 1
        fi
      }

      function update-system() {
        echo "💻 System update..."
        local start_time=$(date +%s)
        local errors=0

        update-nix || ((errors++))
        echo ""
        update-brew || ((errors++))

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

        if [ $errors -eq 0 ]; then
          echo "✅ System update completed!"
        else
          echo "⚠️  Completed with $errors error(s)"
          return 1
        fi
      }

      function update-all() {
        echo "🚀 Complete system update..."
        echo "================================================"

        local start_time=$(date +%s)
        local total_errors=0

        update-nix || ((total_errors++))
        echo ""
        update-brew || ((total_errors++))
        echo ""
        update-mamba || ((total_errors++))
        echo ""
        update-vscode || ((total_errors++))
        echo ""
        update-mas || ((total_errors++))
        echo ""

        echo "🍎 Checking for macOS updates..."
        softwareupdate --list
        echo ""

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo "================================================"
        echo "📊 Update Summary:"
        echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
        echo "❌ Errors: $total_errors"

        if [ $total_errors -eq 0 ]; then
          echo ""
          echo "✅ All updates completed successfully!"
          echo "💡 Consider restarting your terminal"
        else
          echo ""
          echo "⚠️  Completed with $total_errors error(s)"
          return 1
        fi
      }

      # ============================================
      # CLEANUP SYSTEM
      # ============================================

      function cleanup-all() {
        echo "🧹 Starting comprehensive system cleanup..."
        echo "================================================"
        echo ""

        local start_time=$(date +%s)
        local total_freed=0

        # 1. Empty Trash
        echo "🗑️  Emptying Trash..."
        if rm -rf ~/.Trash/* 2>/dev/null; then
          echo "   ✅ Trash emptied"
        else
          echo "   ⚠️  Trash was already empty or inaccessible"
        fi
        echo ""

        # 2. Clean system caches
        echo "🧽 Cleaning system caches..."
        if [ -d ~/Library/Caches ]; then
          local cache_size=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
          echo "   Current cache size: $cache_size"
          # Clean specific caches (be selective to avoid breaking apps)
          rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null
          rm -rf ~/Library/Caches/Homebrew/* 2>/dev/null
          rm -rf ~/Library/Caches/pip/* 2>/dev/null
          echo "   ✅ Safe caches cleaned"
        fi
        echo ""

        # 3. Clean temporary files
        echo "🔥 Cleaning temporary files..."
        rm -rf /tmp/* 2>/dev/null
        rm -rf ~/Downloads/*.tmp 2>/dev/null
        rm -rf ~/Downloads/*.download 2>/dev/null
        echo "   ✅ Temporary files cleaned"
        echo ""

        # 4. Clean Nix (generations and garbage collection)
        echo "❄️  Cleaning Nix..."
        echo "   Removing old generations (keeping last 3)..."
        nix-env --delete-generations +3 2>/dev/null || true
        sudo nix-env --delete-generations +3 2>/dev/null || true

        echo "   Running garbage collection..."
        local nix_before=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
        nix-collect-garbage -d
        sudo nix-collect-garbage -d
        nix-store --optimize
        local nix_after=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
        echo "   ✅ Nix cleaned (was: $nix_before, now: $nix_after)"
        echo ""

        # 5. Clean Homebrew
        if command -v brew &> /dev/null; then
          echo "🍺 Cleaning Homebrew..."
          brew cleanup --prune=all
          brew autoremove
          rm -rf $(brew --cache)/* 2>/dev/null
          echo "   ✅ Homebrew cleaned"
          echo ""
        fi

        # 6. Clean micromamba
        if command -v micromamba &> /dev/null; then
          echo "🐍 Cleaning micromamba..."
          micromamba clean --all --yes
          echo "   ✅ Micromamba cleaned"
          echo ""
        fi

        # 7. Clean Python caches
        echo "🐍 Cleaning Python caches..."
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find . -type f -name "*.pyc" -delete 2>/dev/null || true
        find . -type f -name "*.pyo" -delete 2>/dev/null || true
        rm -rf ~/.cache/pip/* 2>/dev/null
        rm -rf ~/.cache/uv/* 2>/dev/null
        echo "   ✅ Python caches cleaned"
        echo ""

        # 8. Clean VS Code caches
        echo "💻 Cleaning VS Code caches..."
        rm -rf ~/Library/Application\ Support/Code/Cache/* 2>/dev/null
        rm -rf ~/Library/Application\ Support/Code/CachedData/* 2>/dev/null
        rm -rf ~/Library/Application\ Support/Code/logs/* 2>/dev/null
        echo "   ✅ VS Code caches cleaned"
        echo ""

        # 9. Clean Docker (if installed)
        if command -v docker &> /dev/null; then
          echo "🐳 Cleaning Docker..."
          docker system prune -af --volumes 2>/dev/null || echo "   ⚠️  Docker not running"
          echo ""
        fi

        # 10. Clean npm/node caches
        if command -v npm &> /dev/null; then
          echo "📦 Cleaning npm cache..."
          npm cache clean --force 2>/dev/null
          echo "   ✅ npm cache cleaned"
          echo ""
        fi

        # 11. Clean system logs
        echo "📋 Cleaning system logs..."
        sudo rm -rf /var/log/*.log 2>/dev/null || true
        rm -rf ~/Library/Logs/* 2>/dev/null
        echo "   ✅ Logs cleaned"
        echo ""

        # 12. Clean Xcode derived data (if exists)
        if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
          echo "🔨 Cleaning Xcode derived data..."
          rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
          echo "   ✅ Xcode derived data cleaned"
          echo ""
        fi

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo "================================================"
        echo "📊 Cleanup Summary:"
        echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
        echo ""
        echo "💡 Tip: Check available disk space with 'df -h'"
        echo "💡 To see what's using disk space: 'ncdu ~' or 'dust ~'"
        echo ""
        echo "✅ Cleanup completed!"
      }

      # Quick cleanup (less aggressive, faster)
      function cleanup-quick() {
        echo "🧹 Quick cleanup..."
        rm -rf ~/.Trash/* 2>/dev/null
        nix-collect-garbage -d
        brew cleanup --prune=7 2>/dev/null || true
        micromamba clean --yes 2>/dev/null || true
        echo "✅ Quick cleanup done!"
      }

      # ============================================
      # CORE UTILITY FUNCTIONS
      # ============================================

      # Create directory and cd into it
      function mkcd() {
        if [ -z "$1" ]; then
          echo "Usage: mkcd <directory>"
          return 1
        fi
        mkdir -p "$1" && cd "$1"
      }

      # Kill process on specific port
      function kill-port() {
        if [ -z "$1" ]; then
          echo "Usage: kill-port <port-number>"
          echo "Example: kill-port 8000"
          return 1
        fi
        local port=$1
        local pid=$(lsof -ti:$port)
        if [ -z "$pid" ]; then
          echo "No process found on port $port"
          return 1
        fi
        echo "Killing process $pid on port $port..."
        kill -9 $pid
        echo "✅ Process killed"
      }

      # Clone repo and cd into it
      function gcl() {
        if [ -z "$1" ]; then
          echo "Usage: gcl <repo-url> [directory-name]"
          echo "Examples:"
          echo "  gcl https://github.com/user/repo.git"
          echo "  gcl https://github.com/user/repo.git my-custom-dir"
          return 1
        fi

        local repo_url="$1"
        local dir_name="''${2:-$(basename "$repo_url" .git)}"

        git clone "$repo_url" ''${2:+"$2"} && cd "$dir_name"
      }

      # Display system information
      function sysinfo() {
        echo "================================================"
        echo "🖥️  System Information"
        echo "================================================"
        echo "Machine Mode: $MACHINE_MODE"
        echo "Hostname: $(hostname)"
        echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
        echo "Architecture: $(uname -m)"
        echo ""
        echo "🐍 Python Environment:"
        echo "System Python: $(python --version 2>&1)"
        echo "UV: $(uv --version 2>&1 || echo 'not installed')"
        echo "Micromamba: $(micromamba --version 2>&1 | head -n1 || echo 'not installed')"
        if [ -n "$VIRTUAL_ENV" ]; then
          echo "Active venv: $VIRTUAL_ENV"
        fi
        echo ""
        echo "☁️  AWS:"
        echo "Profile: ''${AWS_PROFILE:-<not set>}"
        echo ""
        echo "📦 Package Managers:"
        echo "Nix: $(nix --version 2>&1)"
        echo "Homebrew: $(brew --version 2>&1 | head -n1 || echo 'not installed')"
        echo ""
        echo "💾 Disk Space:"
        df -h / | tail -n1 | awk '{print "Available: "$4" / "$2" (Used: "$5")"}'
        echo "================================================"
      }

      # Display Python environment setup
      function pyenv-info() {
        echo "================================================"
        echo "🐍 Python Environment Setup"
        echo "================================================"
        echo ""
        echo "📦 System Python (Nix):"
        which python
        python --version
        echo ""
        echo "⚡ UV (Fast Python package installer):"
        which uv || echo "  Not found"
        uv --version 2>&1 || echo "  Not installed"
        echo ""
        echo "🐍 Micromamba (Conda-compatible):"
        which micromamba || echo "  Not found"
        micromamba --version 2>&1 | head -n1 || echo "  Not installed"
        echo ""
        if [ -n "$VIRTUAL_ENV" ]; then
          echo "✅ Active Virtual Environment:"
          echo "  Path: $VIRTUAL_ENV"
          echo "  Python: $(python --version 2>&1)"
        else
          echo "ℹ️  No virtual environment active"
        fi
        echo ""
        echo "📚 Python Strategy:"
        echo "  Tier 1: Micromamba environments (create with: micromamba create -n myenv python=3.12)"
        echo "  Tier 2: Project environments (UV .venv for project-specific deps)"
        echo "  Tier 3: System Python (Nix-managed 3.13)"
        echo "================================================"
      }

      # ============================================
      # SYSTEM MAINTENANCE HELPERS
      # ============================================

      # Clean old Nix generations and report space saved
      function nix-cleanup() {
        echo "🧹 Nix System Cleanup"
        echo "================================================"
        echo ""

        # Get current disk usage
        local before=$(df -k / | tail -n1 | awk '{print $3}')

        echo "📊 Current generations:"
        nix-env --list-generations --profile /nix/var/nix/profiles/system
        echo ""

        echo "🗑️  Removing old generations (keeping last 5)..."
        sudo nix-env --delete-generations +5 --profile /nix/var/nix/profiles/system

        echo "🗑️  Removing old home-manager generations (keeping last 5)..."
        nix-env --delete-generations +5 --profile ~/.local/state/nix/profiles/home-manager

        echo ""
        echo "🧹 Running garbage collection..."
        nix-collect-garbage -d

        echo ""
        echo "🔧 Optimizing Nix store..."
        nix-store --optimize

        # Get new disk usage
        local after=$(df -k / | tail -n1 | awk '{print $3}')
        local saved=$((before - after))
        local saved_mb=$((saved / 1024))

        echo ""
        echo "================================================"
        echo "✅ Cleanup complete!"
        if [ $saved_mb -gt 0 ]; then
          echo "💾 Space saved: ~$saved_mb MB"
        fi
        echo "================================================"
      }

      # System health check
      function nix-health() {
        echo "🏥 System Health Check"
        echo "================================================"
        echo ""

        local issues=0

        # Check Nix
        echo "📦 Checking Nix installation..."
        if command -v nix &> /dev/null; then
          echo "  ✅ Nix: $(nix --version)"
        else
          echo "  ❌ Nix not found"
          ((issues++))
        fi
        echo ""

        # Check Python
        echo "🐍 Checking Python setup..."
        if command -v python &> /dev/null; then
          echo "  ✅ Python: $(python --version 2>&1)"
        else
          echo "  ❌ Python not found"
          ((issues++))
        fi

        if command -v uv &> /dev/null; then
          echo "  ✅ UV: $(uv --version 2>&1)"
        else
          echo "  ⚠️  UV not found"
        fi

        if command -v micromamba &> /dev/null; then
          echo "  ✅ Micromamba: $(micromamba --version 2>&1 | head -n1)"
        else
          echo "  ⚠️  Micromamba not found"
        fi
        echo ""

        # Check Git
        echo "🔧 Checking Git configuration..."
        if command -v git &> /dev/null; then
          echo "  ✅ Git: $(git --version)"
          local git_email=$(git config user.email 2>&1)
          if [ -n "$git_email" ]; then
            echo "  ✅ Git email: $git_email"
          else
            echo "  ⚠️  Git email not configured"
          fi
        else
          echo "  ❌ Git not found"
          ((issues++))
        fi
        echo ""

        # Check AWS
        echo "☁️  Checking AWS setup..."
        if command -v aws &> /dev/null; then
          echo "  ✅ AWS CLI: $(aws --version 2>&1 | head -n1)"
          if [ -n "$AWS_PROFILE" ]; then
            echo "  ✅ AWS Profile: $AWS_PROFILE"
          else
            echo "  ℹ️  No AWS profile set"
          fi
        else
          echo "  ❌ AWS CLI not found"
          ((issues++))
        fi
        echo ""

        # Check Docker
        echo "🐳 Checking Docker..."
        if command -v docker &> /dev/null; then
          if docker info &> /dev/null; then
            echo "  ✅ Docker: $(docker --version)"
          else
            echo "  ⚠️  Docker installed but not running"
          fi
        else
          echo "  ℹ️  Docker not installed"
        fi
        echo ""

        # Check disk space
        echo "💾 Checking disk space..."
        local disk_usage=$(df -h / | tail -n1 | awk '{print $5}' | sed 's/%//')
        if [ $disk_usage -lt 80 ]; then
          echo "  ✅ Disk usage: $disk_usage% (healthy)"
        elif [ $disk_usage -lt 90 ]; then
          echo "  ⚠️  Disk usage: $disk_usage% (consider cleanup)"
        else
          echo "  ❌ Disk usage: $disk_usage% (cleanup recommended!)"
          ((issues++))
        fi
        echo ""

        # Check key aliases
        echo "🔑 Checking key aliases..."
        if alias nix-rebuild &> /dev/null; then
          echo "  ✅ nix-rebuild alias configured"
        else
          echo "  ⚠️  nix-rebuild alias not found"
        fi

        if alias g &> /dev/null; then
          echo "  ✅ git alias (g) configured"
        else
          echo "  ⚠️  git alias (g) not found"
        fi
        echo ""

        echo "================================================"
        if [ $issues -eq 0 ]; then
          echo "✅ System health: GOOD"
          echo "No critical issues found!"
        else
          echo "⚠️  System health: ISSUES DETECTED"
          echo "Found $issues critical issue(s)"
          echo "Run 'nix-rebuild' to fix configuration issues"
        fi
        echo "================================================"
      }

      # ============================================
      # WORK-SPECIFIC FUNCTIONS (only on work Mac)
      # ============================================
      if [ "$MACHINE_MODE" = "work" ]; then
        # AWS SSO Login - accepts profile name
        # Usage: awslogin <profile-name>
        # Example: awslogin project1-dev
        function awslogin() {
          local profile="''${1:-$AWS_PROFILE}"
          if [ -z "$profile" ]; then
            echo "❌ Error: No profile specified"
            echo "Usage: awslogin <profile-name>"
            echo "Example: awslogin project1-dev"
            echo ""
            echo "Available profiles:"
            aws configure list-profiles | grep -v "^default$" | sed 's/^/  - /'
            return 1
          fi
          echo "🔐 Logging into AWS SSO with profile: $profile"
          aws sso login --profile "$profile"
          if [ $? -eq 0 ]; then
            echo "✅ AWS SSO login successful"
            export AWS_PROFILE="$profile"
            echo "📌 AWS_PROFILE set to: $profile"
          else
            echo "❌ AWS SSO login failed"
          fi
        }

        # Logout from AWS SSO (clears all cached credentials)
        function awslogout() {
          rm -rf ~/.aws/sso/cache/*
          unset AWS_PROFILE
          echo "✅ AWS SSO logged out (all sessions cleared)"
        }

        # Refresh SSO session for current or specified profile
        function awsrefresh() {
          local profile="''${1:-$AWS_PROFILE}"
          if [ -z "$profile" ]; then
            echo "❌ Error: No profile specified and AWS_PROFILE not set"
            echo "Usage: awsrefresh <profile-name>"
            return 1
          fi
          echo "🔄 Refreshing AWS SSO session for: $profile"
          aws sso login --profile "$profile"
        }

        # Check caller identity for current or specified profile
        function awscheck() {
          local profile="''${1:-$AWS_PROFILE}"
          if [ -z "$profile" ]; then
            echo "❌ Error: No profile specified and AWS_PROFILE not set"
            echo "Usage: awscheck <profile-name>"
            return 1
          fi
          echo "🔍 Checking identity for profile: $profile"
          aws sts get-caller-identity --profile "$profile"
        }

        # List all AWS profiles
        function awslist() {
          echo "📋 Available AWS profiles:"
          aws configure list-profiles | grep -v "^default$" | sed 's/^/  - /'
          echo ""
          echo "Current profile: ''${AWS_PROFILE:-<not set>}"
        }

        # Switch to a profile (sets AWS_PROFILE and shows confirmation)
        function awsuse() {
          if [ -z "$1" ]; then
            echo "❌ Error: No profile specified"
            echo "Usage: awsuse <profile-name>"
            echo ""
            awslist
            return 1
          fi
          export AWS_PROFILE="$1"
          echo "✅ Switched to profile: $1"
          echo "🔍 Checking identity..."
          awswho
        }

        # SSM Session Manager - uses current profile or specified profile
        function ssm() {
          if [ -z "$1" ]; then
            echo "Usage: ssm <instance-id> [profile-name]"
            echo "Example: ssm i-1234567890abcdef0"
            echo "Example: ssm i-1234567890abcdef0 project1-dev"
            return 1
          fi
          local instance_id="$1"
          local profile="''${2:-$AWS_PROFILE}"
          if [ -z "$profile" ]; then
            echo "❌ Error: No profile specified and AWS_PROFILE not set"
            echo "Usage: ssm <instance-id> [profile-name]"
            return 1
          fi
          echo "🔌 Starting SSM session to $instance_id using profile: $profile"
          aws ssm start-session --target "$instance_id" --profile "$profile"
        }

        # Work shortcuts
        alias vpn="open -a 'Cisco AnyConnect'"
        alias cdwork="cd ~/Work"
        alias cdrepo="cd ~/Work/repositories"
        alias tfdev="terraform workspace select dev"
        alias tfprod="terraform workspace select prod"
      fi

      # ============================================
      # BACKUP & SECRETS MANAGEMENT
      # ============================================

      # Backup non-secret user data
      function backup-user-data() {
        if [ ! -f ~/nix-darwin/user-data/backup.sh ]; then
          echo "❌ Error: backup script not found"
          echo "Expected: ~/nix-darwin/user-data/backup.sh"
          return 1
        fi
        echo "📦 Running user data backup..."
        ~/nix-darwin/user-data/backup.sh
      }

      # Restore user data from backup
      function restore-user-data() {
        if [ ! -f ~/nix-darwin/user-data/restore.sh ]; then
          echo "❌ Error: restore script not found"
          echo "Expected: ~/nix-darwin/user-data/restore.sh"
          return 1
        fi
        echo "📦 Restoring user data from backup..."
        ~/nix-darwin/user-data/restore.sh
      }

      # Edit encrypted secrets with sops
      function edit-secrets() {
        local hostname=$(hostname -s)
        local secrets_file="$HOME/nix-darwin/hosts/$hostname/secrets.yaml"

        if [ ! -f "$secrets_file" ]; then
          echo "❌ Error: secrets file not found"
          echo "Expected: $secrets_file"
          echo ""
          echo "💡 To create encrypted secrets:"
          echo "  1. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt"
          echo "  2. Update .sops.yaml with your public key"
          echo "  3. Run: sops $secrets_file"
          echo ""
          echo "See: ~/nix-darwin/secrets/SETUP.md"
          return 1
        fi

        if ! command -v sops &> /dev/null; then
          echo "❌ Error: sops not found"
          echo "Install with: nix-env -iA nixpkgs.sops"
          return 1
        fi

        echo "🔐 Opening encrypted secrets with sops..."
        echo "File: $secrets_file"
        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops "$secrets_file"
      }

      # Check secrets configuration status
      function secrets-status() {
        echo "🔐 Secrets Management Status"
        echo "================================================"
        echo ""

        # Check age key
        echo "🔑 Age Key:"
        if [ -f ~/.config/sops/age/keys.txt ]; then
          echo "  ✅ Age key exists: ~/.config/sops/age/keys.txt"
          local public_key=$(grep "public key:" ~/.config/sops/age/keys.txt | awk '{print $NF}')
          echo "  📌 Public key: $public_key"
        else
          echo "  ❌ Age key not found"
          echo "     Generate with: age-keygen -o ~/.config/sops/age/keys.txt"
        fi
        echo ""

        # Check sops configuration
        echo "⚙️  Sops Configuration:"
        if [ -f ~/nix-darwin/secrets/.sops.yaml ]; then
          echo "  ✅ .sops.yaml exists"
        else
          echo "  ❌ .sops.yaml not found"
        fi
        echo ""

        # Check secrets file
        local hostname=$(hostname -s)
        local secrets_file="$HOME/nix-darwin/hosts/$hostname/secrets.yaml"
        echo "📄 Secrets File:"
        if [ -f "$secrets_file" ]; then
          echo "  ✅ Secrets file exists: $secrets_file"
          if file "$secrets_file" | grep -q "ASCII text"; then
            echo "  ⚠️  WARNING: Secrets file is NOT encrypted!"
            echo "     Encrypt with: sops -e -i $secrets_file"
          else
            echo "  ✅ Secrets file is encrypted"
          fi
        else
          echo "  ❌ Secrets file not found: $secrets_file"
          echo "     Create with: sops $secrets_file"
        fi
        echo ""

        # Check sops installation
        echo "🔧 Tools:"
        if command -v sops &> /dev/null; then
          echo "  ✅ sops: $(sops --version 2>&1 | head -n1)"
        else
          echo "  ❌ sops not installed"
          echo "     Install with: nix-env -iA nixpkgs.sops"
        fi

        if command -v age &> /dev/null; then
          echo "  ✅ age: $(age --version 2>&1)"
        else
          echo "  ❌ age not installed (included in nix-darwin)"
        fi
        echo ""

        # Check active secrets
        echo "🔓 Active Secrets (managed by sops-nix):"
        if [ -f ~/.zsh_secrets ]; then
          echo "  ✅ ~/.zsh_secrets (environment variables)"
        else
          echo "  ❌ ~/.zsh_secrets not found"
        fi

        if [ -f ~/.ssh/id_ed25519 ]; then
          echo "  ✅ ~/.ssh/id_ed25519 (SSH private key)"
        else
          echo "  ❌ ~/.ssh/id_ed25519 not found"
        fi

        if [ -f ~/.aws/credentials ]; then
          echo "  ✅ ~/.aws/credentials (AWS credentials)"
        else
          echo "  ❌ ~/.aws/credentials not found"
        fi

        if [ -f ~/.docker/config.json ]; then
          echo "  ✅ ~/.docker/config.json (Docker config)"
        else
          echo "  ❌ ~/.docker/config.json not found"
        fi
        echo ""

        echo "================================================"
        echo "💡 Useful commands:"
        echo "  edit-secrets         - Edit encrypted secrets"
        echo "  backup-user-data     - Backup non-secret data"
        echo "  restore-user-data    - Restore from backup"
        echo "  nix-rebuild          - Apply secrets after changes"
        echo ""
        echo "📚 Documentation:"
        echo "  ~/nix-darwin/secrets/SETUP.md"
        echo "  ~/nix-darwin/user-data/README.md"
        echo "================================================"
      }

      # ============================================
      # ZOXIDE INITIALIZATION
      # ============================================
      if command -v zoxide &> /dev/null; then
        eval "$(zoxide init zsh)"
        alias zz="z -"
      fi
      ''
    ];

    # Login shell init
    loginExtra = ''
      # Performance profiling (uncomment to use)
      # zmodload zsh/zprof
    '';

    # Logout shell
    logoutExtra = ''
      # Performance profiling (uncomment to use)
      # zprof
    '';
  };
}
