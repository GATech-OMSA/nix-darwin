{ config, pkgs, lib, hostname, myLib, username, ... }:

let
  # Configuration flag for Oh-My-Zsh
  enableOhMyZsh = true;  # Set to false to disable Oh-My-Zsh plugins

  # Derive paths dynamically
  nixDarwinDir = "${config.home.homeDirectory}/nix-darwin";
  homeDir = config.home.homeDirectory;
in
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

    # Oh My Zsh integration - Controlled by enableOhMyZsh flag
    # Theme is empty to allow Starship prompt to take over
    oh-my-zsh = {
      enable = enableOhMyZsh;
      theme = "";  # Empty theme = use Starship prompt
      plugins = lib.optionals enableOhMyZsh [
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
        # NOTE: Directory jumping is provided by zoxide (configured in base.nix)
        # Removed oh-my-zsh "z" plugin to avoid conflict with zoxide (2025-11-06)
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
    shellAliases = myLib.aws.mkAwsAliasesFromJson // {
      # ============================================
      # SYSTEM & CONFIGURATION
      # ============================================
      c = "clear";
      reload = "source ~/.zshrc && echo '✅ .zshrc reloaded'";
      restart = "exec zsh";

      # Quick open shortcuts
      vs = "code .";          # Open VS Code in current directory
      vscode = "code .";      # Alias for vs (full name)
      f = "open .";           # Open Finder in current directory
      finder = "open .";      # Alias for f (full name)

      # Configuration shortcuts
      nixconf = "code ${nixDarwinDir}";
      zshconf = "code ${nixDarwinDir}/home/${username}/shell/zsh.nix";
      gitconf = "code ${nixDarwinDir}/home/${username}/programs/git.nix";
      vscodeconf = "code ${nixDarwinDir}/home/${username}/programs/vscode.nix";
      condaconf = "code ${homeDir}/.condarc";
      awsconf = "code ${homeDir}/.aws/config";
      jupyterconf = "code ${homeDir}/.jupyter/jupyter_notebook_config.py";
      zshrc = "code ${homeDir}/.zshrc";

      # Nix-Darwin system management
      # nix-rebuild runs with pre-flight checks by default
      nix-rebuild = "${nixDarwinDir}/scripts/pre-flight-checks.sh && sudo darwin-rebuild switch --flake ${nixDarwinDir}";

      # Skip pre-flight checks for emergency rebuilds (use with caution)
      nix-rebuild-skip-checks = "sudo darwin-rebuild switch --flake ${nixDarwinDir}";

      # Debug mode with verbose output for troubleshooting
      # Shows detailed build logs, stack traces, and Home Manager activation details
      # Usage: nix-rebuild-debug (for full rebuild with debug info)
      nix-rebuild-debug = "sudo darwin-rebuild switch --flake ${nixDarwinDir} --show-trace --verbose --print-build-logs";

      # Check configuration without building
      nix-check = "nix flake check ${nixDarwinDir}";

      # Run pre-flight checks manually (without rebuilding)
      nix-preflight = "${nixDarwinDir}/scripts/pre-flight-checks.sh";

      # System health check - Validate nix-darwin system state
      # Usage: health-check (normal) | health-check --verbose (detailed)
      health-check = "${nixDarwinDir}/scripts/health-check.sh";
      system-health = "${nixDarwinDir}/scripts/health-check.sh";

      nix-rollback = "sudo darwin-rebuild --rollback";

      # Force home-manager regeneration (workaround for cache bug)
      # See: claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md
      nix-rebuild-hm-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.$(hostname).config.home-manager.users.${username}.home.activationPackage) && $result/activate && sudo darwin-rebuild switch --flake ${nixDarwinDir} --impure";
      home-rebuild-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.$(hostname).config.home-manager.users.${username}.home.activationPackage) && $result/activate";

      # Scaffold new machine configuration from template
      scaffold-machine = "${nixDarwinDir}/scripts/scaffold-new-machine.sh";
      new-machine = "${nixDarwinDir}/scripts/scaffold-new-machine.sh";

      # ============================================
      # APP LAUNCHERS
      # ============================================
      # Browsers
      ff = "open -a Firefox";
      orion = "open -a Orion";

      # AI/LLM
      claude = "open -a Claude";
      gpt = "open -a ChatGPT";
      pplx = "open -a Perplexity";
      obs = "open -a Obsidian";
      jan = "open -a Jan";

      # Development
      cursor = "open -a Cursor";
      cur = "open -a Cursor";
      cc = "claude";  # Claude Code CLI in terminal

      # Productivity
      pdf = "open -a 'PDF Expert'";
      shot = "open -a Shottr";
      alfred = "open -a Alfred";

      # Communication
      zoom = "open -a Zoom";
      wa = "open -a WhatsApp";
      whatsapp = "open -a WhatsApp";

      # Other
      tv = "open -a TradingView";
      vpn = "open -a ProtonVPN";

      # ============================================
      # WORKFLOW HELPERS
      # ============================================
      show = "open -R";        # Reveal in Finder
      ql = "qlmanage -p";      # Quick Look preview
      copy = "pbcopy";         # Pipe to clipboard
      paste = "pbpaste";       # Paste from clipboard
      port = "lsof -i :";      # Check what's on port

      # Safety aliases
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

      # ============================================
      # NIX DEVELOPMENT
      # ============================================
      ns = "nix-shell";
      nd = "nix develop";
      nb = "nix build";
      nf = "nix flake";
      se = "sops -e -i";  # SOPS edit secrets

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
      desktop = "cd ~/Desktop";
      docs = "cd ~/Documents";
      apps = "cd ~/Applications";
      down = "cd ~/Downloads";
      desk = "cd ~/Desktop";

      # Personal projects
      learning = "cd ~/Dev/learning";
      aiml = "cd ~/Dev/ai-ml";
      algo = "cd ~/Dev/algorithms";
      courses = "cd ~/Dev/courses";
      experiments = "cd ~/Dev/experiments";
      oss = "cd ~/Dev/open-source";

      # ============================================
      # MODERN CLI TOOLS (eza, bat, ripgrep, etc.)
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
      # GIT - Modern shortcuts (complement g-prefix)
      # ============================================
      # Main git interface (all aliases in git.nix with 'g' prefix)
      g = "git";

      # Modern git shortcuts
      gsw = "git switch";
      gswc = "git switch -c";
      gres = "git restore";
      grest = "git restore --staged";

      # ============================================
      # PYTHON - MULTI-TIER (UV + Micromamba)
      # ============================================
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
      # AWS
      # ============================================
      awsp = "export AWS_PROFILE=";
      awsprofile = "echo $AWS_PROFILE";
      awswho = "aws sts get-caller-identity";

      # ============================================
      # DOCKER & KUBERNETES
      # ============================================
      # Docker
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
      dex = "docker exec -it";
      drun = "docker run -it --rm";
      dprune = "docker system prune -af";

      # Kubernetes
      k = "kubectl";
      kg = "kubectl get";
      kd = "kubectl describe";
      kl = "kubectl logs";
      k9 = "k9s";

      # ============================================
      # TERRAFORM
      # ============================================
      tf = "terraform";
      tfi = "terraform init";
      tfp = "terraform plan";
      tfa = "terraform apply";
      tfv = "terraform validate";
      tff = "terraform fmt";

      # ============================================
      # FILE OPERATIONS
      # ============================================
      # NOTE: extract is provided by oh-my-zsh extract plugin (line 57)
      # Don't define alias here as it conflicts with the plugin function

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
      # CLEANUP ALIASES
      # ============================================
      # Note: cleanup function is defined below and defaults to cleanup-standard
      # cleanup-all is an alias for cleanup-aggressive
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
      # LOAD CREDENTIALS (Environment Variables)
      # ============================================
      # Credentials are loaded from encrypted file for database connections
      # and other services requiring rotating passwords
      if [ -f "$HOME/.secrets/credentials.env.enc" ]; then
        # Decrypt credentials file (SOPS automatically decrypts)
        if command -v sops &> /dev/null; then
          # Decrypt to temporary file
          SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --decrypt "$HOME/.secrets/credentials.env.enc" > "$HOME/.secrets/credentials.env" 2>/dev/null

          if [ -f "$HOME/.secrets/credentials.env" ]; then
            # Set permissions
            chmod 600 "$HOME/.secrets/credentials.env"

            # Load variables
            set -a  # Auto-export all variables
            source "$HOME/.secrets/credentials.env"
            set +a

            # Count loaded variables
            local cred_count=$(grep -c '^export' "$HOME/.secrets/credentials.env" 2>/dev/null || echo "0")
            if [ "$cred_count" -gt 0 ]; then
              echo "🔐 Loaded $cred_count credentials"
            fi

            # Clean up decrypted file for security
            rm "$HOME/.secrets/credentials.env" 2>/dev/null
          fi
        fi
      elif [ -f "$HOME/.secrets/credentials.env" ]; then
        # If unencrypted file exists (shouldn't happen in prod), warn and load
        echo "⚠️  Warning: Unencrypted credentials file found"
        set -a
        source "$HOME/.secrets/credentials.env"
        set +a
      fi

      # ============================================
      # AWS HELPER FUNCTIONS
      # ============================================
      # Work machine: AWS functions loaded from work.nix
      # Personal machine: Uses simple AWS config from aws.nix

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
      # OPTION+ARROW WORD NAVIGATION
      # ============================================
      # Fix for Option+Left/Right to navigate by word
      bindkey "^[b" backward-word      # Option+Left
      bindkey "^[f" forward-word       # Option+Right
      bindkey "^[[1;3C" forward-word   # Option+Right (alternative)
      bindkey "^[[1;3D" backward-word  # Option+Left (alternative)

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

      # NOTE: extract function is provided by oh-my-zsh extract plugin (line 57)
      # The plugin provides the same functionality, so custom function is not needed

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

      # Create new project and open in VS Code
      function newproj() {
        if [ -z "$1" ]; then
          echo "Usage: newproj <project-name>"
          return 1
        fi
        mkdir -p ~/Dev/"$1" && cd ~/Dev/"$1" && code .
        echo "✅ Created and opened project: ~/Dev/$1"
      }

      # Alias for kill-port (no hyphen)
      function killport() {
        kill-port "$@"
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
      # WARNING & CONFIRMATION HELPERS
      # ============================================
      # Reusable warning and confirmation functions for risky operations
      # Generated by lib/warnings.nix

      # Display warning message
      # Usage: warn "MESSAGE" [LEVEL]
      function warn() {
        local message="$1"
        local level="''${2:-WARNING}"

        case "$level" in
          INFO)
            echo "ℹ️  INFO: $message"
            ;;
          WARNING)
            echo "⚠️  WARNING: $message"
            ;;
          CRITICAL)
            echo "🚨 CRITICAL: $message"
            ;;
          *)
            echo "⚠️  $message"
            ;;
        esac
      }

      # Confirm action with user
      # Usage: confirm "Question?" && command
      function confirm() {
        local question="$1"
        read -q "REPLY?$question (y/N) "
        echo ""
        [[ "$REPLY" =~ ^[Yy]$ ]]
      }

      # Wrap risky command with confirmation
      # Usage: risky "WARNING" "This is dangerous" command args...
      function risky() {
        local level="$1"
        local message="$2"
        shift 2

        warn "$message" "$level"
        if confirm "Proceed?"; then
          "$@"
        else
          echo "❌ Operation cancelled"
          return 1
        fi
      }

      # Critical operation requiring explicit confirmation
      # Usage: critical "DELETE" "This will delete everything" command args...
      function critical() {
        local confirm_text="$1"
        local message="$2"
        shift 2

        echo ""
        echo "🚨 CRITICAL OPERATION"
        echo "⚠️  $message"
        echo ""
        read -r "confirmation?Type '$confirm_text' to confirm: "

        if [[ "$confirmation" == "$confirm_text" ]]; then
          "$@"
        else
          echo "❌ Operation cancelled (incorrect confirmation)"
          return 1
        fi
      }

      # ============================================
      # SAFE NIX REBUILD WRAPPER
      # ============================================
      # Enhanced nix-rebuild with explicit confirmation
      # The standard nix-rebuild alias runs pre-flight checks automatically
      # Use this function when you want an additional confirmation step

      function nix-rebuild-confirm() {
        warn "System Rebuild" "WARNING"
        echo "  • This will rebuild your entire system configuration"
        echo "  • Changes will be applied immediately"
        echo "  • Previous generation will be available for rollback (nix-rollback)"
        echo ""

        if confirm "Proceed with rebuild?"; then
          echo ""
          echo "🔄 Running pre-flight checks..."
          if ${nixDarwinDir}/scripts/pre-flight-checks.sh; then
            echo ""
            echo "🏗️  Building darwin configuration..."
            sudo darwin-rebuild switch --flake ${nixDarwinDir}
          else
            echo ""
            echo "❌ Pre-flight checks failed"
            echo "💡 Fix the issues above and try again"
            return 1
          fi
        else
          echo "❌ Rebuild cancelled"
          return 1
        fi
      }

      # ============================================
      # USER DATA BACKUP & RESTORE
      # ============================================

      # Backup user data (runs backup.sh)
      function backup-user-data() {
        if [ ! -f ${nixDarwinDir}/user-data/backup.sh ]; then
          echo "❌ Error: backup script not found"
          echo "Expected: ${nixDarwinDir}/user-data/backup.sh"
          return 1
        fi
        echo "📦 Running user data backup..."
        ${nixDarwinDir}/user-data/backup.sh
      }

      # Restore user data from backup (runs restore.sh)
      function restore-user-data() {
        if [ ! -f ${nixDarwinDir}/user-data/restore.sh ]; then
          echo "❌ Error: restore script not found"
          echo "Expected: ${nixDarwinDir}/user-data/restore.sh"
          return 1
        fi
        echo "📦 Restoring user data from backup..."
        ${nixDarwinDir}/user-data/restore.sh
      }

      # Sync user data: Backup + Commit + Push
      function sync-user-data() {
        echo "🔄 Syncing user data..."
        echo ""

        # Run backup
        if ! backup-user-data; then
          echo "❌ Backup failed"
          return 1
        fi

        echo ""
        echo "📝 Committing changes..."

        # Check if in git repo
        if [ ! -d ${nixDarwinDir}/.git ]; then
          echo "❌ Error: Not in a git repository"
          return 1
        fi

        # Save current directory
        local prev_dir=$(pwd)

        # Change to nix-darwin directory
        cd ${nixDarwinDir}

        # Check if there are changes in user-data
        if ! git diff --quiet user-data/ || ! git diff --cached --quiet user-data/; then
          # Stage all user-data changes
          git add user-data/

          # Create commit with timestamp
          local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
          git commit -m "Sync user-data: $timestamp"

          echo "✅ Changes committed"
          echo ""
          echo "📤 Pushing to remote..."

          # Push to remote
          if git push; then
            echo "✅ Sync complete!"
          else
            echo "❌ Push failed"
            cd "$prev_dir"
            return 1
          fi
        else
          echo "✅ No changes to sync"
        fi

        # Return to previous directory
        cd "$prev_dir"
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
        cd ${nixDarwinDir} || return 1

        if nix flake update; then
          echo "  ✅ Flake inputs updated"
        else
          echo "  ❌ Flake update failed" >&2
          ((errors++))
        fi

        echo "  📦 Rebuilding darwin configuration..."
        if darwin-rebuild switch --flake ${nixDarwinDir}; then
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

          echo "  📦 Upgrading all casks (including auto-update apps)..."
          if brew cu -afy; then
            echo "  ✅ All casks upgraded"
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
      # USER DATA SYNC
      # ============================================

      # Sync user-data from home directory to nix-darwin repository
      # Backs up VS Code settings, Karabiner config, and other user preferences
      function sync-user-data() {
        echo "📦 Syncing user data to nix-darwin repository..."
        local errors=0
        local nix_darwin="${nixDarwinDir}"
        local user_data="$nix_darwin/user-data/user-content"

        # Check if nix-darwin exists
        if [ ! -d "$nix_darwin" ]; then
          echo "❌ Error: ${nixDarwinDir} directory not found"
          return 1
        fi

        # Sync VS Code settings
        if [ -d "$HOME/Library/Application Support/Code/User" ]; then
          echo "  📝 Syncing VS Code settings..."
          mkdir -p "$user_data/vscode"

          # Copy settings.json
          if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
            cp "$HOME/Library/Application Support/Code/User/settings.json" \
               "$user_data/vscode/settings.json"
            echo "  ✅ VS Code settings synced"
          fi

          # Copy keybindings.json
          if [ -f "$HOME/Library/Application Support/Code/User/keybindings.json" ]; then
            cp "$HOME/Library/Application Support/Code/User/keybindings.json" \
               "$user_data/vscode/keybindings.json"
            echo "  ✅ VS Code keybindings synced"
          fi
        else
          echo "  ⚠️  VS Code User directory not found"
        fi

        # Sync Karabiner config
        if [ -d "$HOME/.config/karabiner" ]; then
          echo "  ⌨️  Syncing Karabiner configuration..."
          mkdir -p "$user_data/karabiner"

          # Copy main config
          if [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
            cp "$HOME/.config/karabiner/karabiner.json" \
               "$user_data/karabiner/karabiner.json"
            echo "  ✅ Karabiner config synced"
          fi

          # Copy complex modifications
          if [ -d "$HOME/.config/karabiner/assets/complex_modifications" ]; then
            mkdir -p "$user_data/karabiner/assets/complex_modifications"
            cp -r "$HOME/.config/karabiner/assets/complex_modifications/"* \
               "$user_data/karabiner/assets/complex_modifications/" 2>/dev/null || true
            echo "  ✅ Karabiner complex modifications synced"
          fi
        else
          echo "  ⚠️  Karabiner config directory not found (may not be installed yet)"
        fi

        if [ $errors -eq 0 ]; then
          echo "✅ User data sync completed successfully"
          echo "  💡 Don't forget to commit changes: cd ${nixDarwinDir} && git add user-data && git commit"
        else
          echo "⚠️  User data sync completed with $errors error(s)"
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
      # ============================================
      # CLEANUP SYSTEM - Comprehensive Tier-Based Cleanup
      # ============================================
      #
      # Features:
      # - 5 cleanup tiers: safe → quick → standard → dev → aggressive
      # - Dry-run mode: --dry-run flag
      # - Skip confirmations: --yes flag
      # - Before/after disk reporting
      # - Cleanup history logging to ~/.cleanup-history
      # - Tool-specific cleanup functions
      #
      # Usage:
      #   cleanup-safe                    # Conservative cleanup
      #   cleanup-quick                   # Fast daily cleanup
      #   cleanup                         # Standard (default)
      #   cleanup-dev                     # Development-focused
      #   cleanup-aggressive              # Maximum cleanup (with prompts)
      #   cleanup-aggressive --dry-run    # Preview without executing
      #   cleanup-aggressive --yes        # Skip all confirmations
      #
      # Tool-specific:
      #   cleanup-nix                     # Nix only
      #   cleanup-docker                  # Docker only
      #   cleanup-python                  # Python/UV only
      #   cleanup-git                     # Git repositories
      #   cleanup-aws                     # AWS caches
      #   cleanup-terraform               # Terraform
      #   cleanup-macos                   # macOS-specific
      #
      # ============================================

      # Helper: Get disk space
      __cleanup_get_disk_space() {
        df -h / | tail -n1 | awk '{print $3}'
      }

      # Helper: Log to cleanup history
      __cleanup_log() {
        local tier="$1"
        local message="$2"
        local log_file="$HOME/.cleanup-history"

        mkdir -p "$(dirname "$log_file")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$tier] $message" >> "$log_file"

        # Rotate log (keep last 500 lines)
        if [[ -f "$log_file" && $(wc -l < "$log_file") -gt 1000 ]]; then
          tail -500 "$log_file" > "$log_file.tmp"
          mv "$log_file.tmp" "$log_file"
        fi
      }

      # Helper: Confirm risky operation
      __cleanup_confirm() {
        local operation="$1"
        local description="$2"
        local risk="$3"  # low, medium, high
        local yes_flag="$4"

        # Skip if --yes flag
        [[ "$yes_flag" == "true" ]] && return 0

        # Show warning based on risk level
        case "$risk" in
          high)
            echo -e "\033[31m⚠️  HIGH RISK OPERATION\033[0m"
            ;;
          medium)
            echo -e "\033[33m⚠️  Medium Risk Operation\033[0m"
            ;;
        esac

        [[ -n "$description" ]] && echo -e "\033[1m$description\033[0m"
        echo ""

        read -p "Continue with $operation? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && {
          echo -e "\033[33mSkipped: $operation\033[0m"
          return 1
        }
        return 0
      }

      # ============================================
      # TIER 1: CLEANUP-SAFE (Conservative, no confirmations)
      # ============================================
      function cleanup-safe() {
        local dry_run=false
        local yes_flag=true  # Safe tier doesn't need confirmations

        # Parse flags
        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --help|-h)
              echo "Usage: cleanup-safe [OPTIONS]"
              echo ""
              echo "Conservative cleanup (safe, no confirmations needed)"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations without executing"
              echo "  --help, -h   Show this help message"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m🛡️  SAFE CLEANUP - Conservative System Cleanup\033[0m"
        echo -e "\033[36m============================================================\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  DRY RUN MODE - No changes will be made\033[0m"
        echo ""

        local start_time=$(date +%s)
        local disk_before=$(__cleanup_get_disk_space)

        __cleanup_log "safe" "Starting safe cleanup (dry_run=$dry_run)"

        # 1. Empty Trash
        echo -e "\033[35m🗑️  Trash & Temporary Files\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would empty Trash\033[0m"
          echo -e "\033[36m  [DRY RUN] Would clean temp files (/tmp, ~/Downloads/*.tmp)\033[0m"
        else
          rm -rf ~/.Trash/* 2>/dev/null && echo "  ✅ Trash emptied" || echo "  ℹ️  Trash already empty"
          rm -rf /tmp/* 2>/dev/null && echo "  ✅ Temp files cleaned"
          rm -rf ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null && echo "  ✅ Download temp files cleaned"
        fi
        echo ""

        # 2. Nix GC (keep last 5 generations)
        echo -e "\033[35m❄️  Nix Cleanup (Conservative)\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would keep last 5 generations and run GC\033[0m"
        else
          echo "  Removing old generations (keeping last 5)..."
          nix-env --delete-generations +5 2>/dev/null || true
          sudo nix-env --delete-generations +5 2>/dev/null || true
          echo "  Running garbage collection..."
          nix-collect-garbage -d &>/dev/null && echo "  ✅ Nix GC completed"
        fi
        echo ""

        # 3. Homebrew (30 days)
        if command -v brew &> /dev/null; then
          echo -e "\033[35m🍺 Homebrew Cleanup (30 days)\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would cleanup Homebrew (prune 30 days)\033[0m"
          else
            brew cleanup --prune=30 &>/dev/null && echo "  ✅ Homebrew cleaned (30 days)"
          fi
          echo ""
        fi

        # Final report
        local disk_after=$(__cleanup_get_disk_space)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "\033[1m\033[32m✅ Safe Cleanup Complete!\033[0m"
        echo -e "\033[32m============================================================\033[0m"
        echo -e "\033[36mℹ️  Disk: $disk_before → $disk_after\033[0m"
        echo -e "\033[36mℹ️  Duration: $((duration / 60))m $((duration % 60))s\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  This was a DRY RUN - no changes were made\033[0m"
        echo ""

        __cleanup_log "safe" "Completed in $((duration))s (disk: $disk_before → $disk_after)"
      }

      # ============================================
      # TIER 2: CLEANUP-QUICK (Fast daily/weekly cleanup)
      # ============================================
      function cleanup-quick() {
        local dry_run=false
        local yes_flag=true

        # Parse flags
        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --help|-h)
              echo "Usage: cleanup-quick [OPTIONS]"
              echo ""
              echo "Fast daily/weekly cleanup"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations without executing"
              echo "  --help, -h   Show this help message"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m⚡ QUICK CLEANUP - Fast System Cleanup\033[0m"
        echo -e "\033[36m============================================================\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  DRY RUN MODE - No changes will be made\033[0m"
        echo ""

        local start_time=$(date +%s)
        local disk_before=$(__cleanup_get_disk_space)

        __cleanup_log "quick" "Starting quick cleanup (dry_run=$dry_run)"

        # Run safe tier operations
        echo -e "\033[35m🛡️  Running Safe Tier Operations...\033[0m"
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would run: cleanup-safe operations\033[0m"
        else
          # Empty Trash & temp files
          rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
          nix-env --delete-generations +5 2>/dev/null || true
          sudo nix-env --delete-generations +5 2>/dev/null || true
          nix-collect-garbage -d &>/dev/null
          command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null
          echo "  ✅ Safe operations completed"
        fi
        echo ""

        # Micromamba
        if command -v micromamba &> /dev/null; then
          echo -e "\033[35m🐍 Micromamba Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would run: micromamba clean --yes\033[0m"
          else
            micromamba clean --yes &>/dev/null && echo "  ✅ Micromamba cleaned"
          fi
          echo ""
        fi

        # Docker images (keep volumes)
        if command -v docker &> /dev/null && docker info &>/dev/null; then
          echo -e "\033[35m🐳 Docker Image Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would run: docker image prune -af\033[0m"
          else
            docker image prune -af &>/dev/null && echo "  ✅ Docker images cleaned"
          fi
          echo ""
        fi

        # Python caches
        echo -e "\033[35m🐍 Python Cache Cleanup\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would clean Python caches\033[0m"
        else
          rm -rf ~/.cache/pip/* ~/.cache/uv/* 2>/dev/null
          echo "  ✅ Python caches cleaned"
        fi
        echo ""

        # npm cache
        if command -v npm &> /dev/null; then
          echo -e "\033[35m📦 npm Cache Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would run: npm cache clean --force\033[0m"
          else
            npm cache clean --force &>/dev/null && echo "  ✅ npm cache cleaned"
          fi
          echo ""
        fi

        # Final report
        local disk_after=$(__cleanup_get_disk_space)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "\033[1m\033[32m✅ Quick Cleanup Complete!\033[0m"
        echo -e "\033[32m============================================================\033[0m"
        echo -e "\033[36mℹ️  Disk: $disk_before → $disk_after\033[0m"
        echo -e "\033[36mℹ️  Duration: $((duration / 60))m $((duration % 60))s\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  This was a DRY RUN - no changes were made\033[0m"
        echo ""

        __cleanup_log "quick" "Completed in $((duration))s (disk: $disk_before → $disk_after)"
      }

      # ============================================
      # TIER 3: CLEANUP-STANDARD (Default cleanup - alias: cleanup)
      # ============================================
      function cleanup-standard() {
        local dry_run=false
        local yes_flag=false

        # Parse flags
        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --yes|-y) yes_flag=true ;;
            --help|-h)
              echo "Usage: cleanup-standard [OPTIONS]"
              echo ""
              echo "Standard cleanup (recommended for regular maintenance)"
              echo "Alias: cleanup"
              echo ""
              echo "Includes:"
              echo "  - Everything in cleanup-quick"
              echo "  - UV cache cleanup"
              echo "  - Git repository cleanup"
              echo "  - AWS cache cleanup"
              echo "  - VS Code caches"
              echo "  - System logs (safe)"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations without executing"
              echo "  --yes, -y    Skip confirmation prompts"
              echo "  --help, -h   Show this help message"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m🚀 STANDARD CLEANUP - Regular Maintenance\033[0m"
        echo -e "\033[36m============================================================\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  DRY RUN MODE - No changes will be made\033[0m"
        echo ""

        local start_time=$(date +%s)
        local disk_before=$(__cleanup_get_disk_space)

        __cleanup_log "standard" "Starting standard cleanup (dry_run=$dry_run)"

        # Run quick tier operations inline for performance
        echo -e "\033[35m⚡ Quick Tier Operations\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would run quick cleanup operations\033[0m"
        else
          rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
          nix-env --delete-generations +5 2>/dev/null || true
          sudo nix-env --delete-generations +5 2>/dev/null || true
          nix-collect-garbage -d &>/dev/null
          command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null
          command -v micromamba &>/dev/null && micromamba clean --yes &>/dev/null
          command -v docker &>/dev/null && docker info &>/dev/null && docker image prune -af &>/dev/null
          rm -rf ~/.cache/pip/* ~/.cache/uv/* 2>/dev/null
          command -v npm &>/dev/null && npm cache clean --force &>/dev/null
          echo "  ✅ Quick tier completed"
        fi
        echo ""

        # UV cache (comprehensive)
        echo -e "\033[35m⚡ UV Cache Cleanup\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would clean UV cache (~/.cache/uv)\033[0m"
        else
          rm -rf ~/.cache/uv/* 2>/dev/null && echo "  ✅ UV cache cleaned"
        fi
        echo ""

        # Git cleanup
        echo -e "\033[35m📂 Git Repository Cleanup\033[0m"
        echo "=================================================="
        if [[ -d "$HOME/Dev" ]]; then
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would clean Git repos in ~/Dev\033[0m"
          else
            find "$HOME/Dev" -name ".git" -type d -exec sh -c 'cd "$(dirname "{}")" && git gc --quiet 2>/dev/null' \; 2>/dev/null
            echo "  ✅ Git repositories optimized"
          fi
        fi
        echo ""

        # AWS cache
        if [[ -d "$HOME/.aws/cli/cache" ]]; then
          echo -e "\033[35m☁️  AWS Cache Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would clean AWS CLI cache\033[0m"
          else
            rm -rf "$HOME/.aws/cli/cache"/* 2>/dev/null && echo "  ✅ AWS cache cleaned"
          fi
          echo ""
        fi

        # VS Code caches
        echo -e "\033[35m💻 VS Code Cache Cleanup\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would clean VS Code caches\033[0m"
        else
          rm -rf ~/Library/Application\ Support/Code/Cache/* 2>/dev/null
          rm -rf ~/Library/Application\ Support/Code/CachedData/* 2>/dev/null
          rm -rf ~/Library/Application\ Support/Code/logs/* 2>/dev/null
          echo "  ✅ VS Code caches cleaned"
        fi
        echo ""

        # System logs (safe)
        echo -e "\033[35m📋 System Log Cleanup (Safe)\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would clean safe system logs\033[0m"
        else
          rm -rf ~/Library/Logs/* 2>/dev/null && echo "  ✅ User logs cleaned"
        fi
        echo ""

        # Final report
        local disk_after=$(__cleanup_get_disk_space)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "\033[1m\033[32m✅ Standard Cleanup Complete!\033[0m"
        echo -e "\033[32m============================================================\033[0m"
        echo -e "\033[36mℹ️  Disk: $disk_before → $disk_after\033[0m"
        echo -e "\033[36mℹ️  Duration: $((duration / 60))m $((duration % 60))s\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  This was a DRY RUN - no changes were made\033[0m"
        echo ""

        __cleanup_log "standard" "Completed in $((duration))s (disk: $disk_before → $disk_after)"
      }

      # Alias for backward compatibility and convenience
      function cleanup() {
        cleanup-standard "$@"
      }

      # ============================================
      # TIER 4: CLEANUP-DEV (Development-focused cleanup)
      # ============================================
      function cleanup-dev() {
        local dry_run=false
        local yes_flag=false

        # Parse flags
        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --yes|-y) yes_flag=true ;;
            --help|-h)
              echo "Usage: cleanup-dev [OPTIONS]"
              echo ""
              echo "Development-focused cleanup"
              echo ""
              echo "Includes:"
              echo "  - Everything in cleanup-standard"
              echo "  - Terraform .terraform directories"
              echo "  - Jupyter checkpoints"
              echo "  - Python __pycache__ across projects"
              echo "  - Docker build cache"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations without executing"
              echo "  --yes, -y    Skip confirmation prompts"
              echo "  --help, -h   Show this help message"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m🔧 DEV CLEANUP - Development-Focused Cleanup\033[0m"
        echo -e "\033[36m============================================================\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  DRY RUN MODE - No changes will be made\033[0m"
        echo ""

        local start_time=$(date +%s)
        local disk_before=$(__cleanup_get_disk_space)

        __cleanup_log "dev" "Starting dev cleanup (dry_run=$dry_run)"

        # Run standard tier inline
        echo -e "\033[35m🚀 Standard Tier Operations\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would run standard cleanup operations\033[0m"
        else
          # Quick operations
          rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
          nix-env --delete-generations +5 2>/dev/null || true
          sudo nix-env --delete-generations +5 2>/dev/null || true
          nix-collect-garbage -d &>/dev/null
          command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null
          command -v micromamba &>/dev/null && micromamba clean --yes &>/dev/null
          rm -rf ~/.cache/pip/* ~/.cache/uv/* 2>/dev/null
          command -v npm &>/dev/null && npm cache clean --force &>/dev/null
          rm -rf ~/Library/Application\ Support/Code/Cache/* ~/Library/Application\ Support/Code/CachedData/* 2>/dev/null
          [[ -d "$HOME/.aws/cli/cache" ]] && rm -rf "$HOME/.aws/cli/cache"/* 2>/dev/null
          echo "  ✅ Standard tier completed"
        fi
        echo ""

        # Terraform cleanup
        if [[ -d "$HOME/Dev" ]]; then
          echo -e "\033[35m🏗️  Terraform Cleanup\033[0m"
          echo "=================================================="
          local terraform_count=$(find "$HOME/Dev" -name ".terraform" -type d 2>/dev/null | wc -l | tr -d ' ')
          if [[ $terraform_count -gt 0 ]]; then
            if [[ "$dry_run" == "true" ]]; then
              echo -e "\033[36m  [DRY RUN] Would remove $terraform_count .terraform directories\033[0m"
            else
              find "$HOME/Dev" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
              echo "  ✅ Removed $terraform_count .terraform directories"
            fi
          else
            echo "  ℹ️  No .terraform directories found"
          fi
          echo ""
        fi

        # Jupyter checkpoints
        if [[ -d "$HOME/Dev" ]]; then
          echo -e "\033[35m📓 Jupyter Checkpoint Cleanup\033[0m"
          echo "=================================================="
          local jupyter_count=$(find "$HOME/Dev" -name ".ipynb_checkpoints" -type d 2>/dev/null | wc -l | tr -d ' ')
          if [[ $jupyter_count -gt 0 ]]; then
            if [[ "$dry_run" == "true" ]]; then
              echo -e "\033[36m  [DRY RUN] Would remove $jupyter_count Jupyter checkpoint directories\033[0m"
            else
              find "$HOME/Dev" -name ".ipynb_checkpoints" -type d -exec rm -rf {} + 2>/dev/null
              echo "  ✅ Removed $jupyter_count checkpoint directories"
            fi
          else
            echo "  ℹ️  No Jupyter checkpoints found"
          fi
          echo ""
        fi

        # Python __pycache__ across all projects
        if [[ -d "$HOME/Dev" ]]; then
          echo -e "\033[35m🐍 Python __pycache__ Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            local pycache_count=$(find "$HOME/Dev" -name "__pycache__" -type d 2>/dev/null | wc -l | tr -d ' ')
            echo -e "\033[36m  [DRY RUN] Would remove $pycache_count __pycache__ directories\033[0m"
          else
            local before_count=$(find "$HOME/Dev" -name "__pycache__" -type d 2>/dev/null | wc -l | tr -d ' ')
            find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
            find "$HOME/Dev" -name "*.pyc" -type f -delete 2>/dev/null
            find "$HOME/Dev" -name "*.pyo" -type f -delete 2>/dev/null
            echo "  ✅ Removed $before_count __pycache__ directories"
          fi
          echo ""
        fi

        # Docker build cache
        if command -v docker &> /dev/null && docker info &>/dev/null; then
          echo -e "\033[35m🐳 Docker Build Cache\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would run: docker builder prune -af\033[0m"
          else
            docker builder prune -af &>/dev/null && echo "  ✅ Docker build cache cleared"
          fi
          echo ""
        fi

        # Final report
        local disk_after=$(__cleanup_get_disk_space)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "\033[1m\033[32m✅ Dev Cleanup Complete!\033[0m"
        echo -e "\033[32m============================================================\033[0m"
        echo -e "\033[36mℹ️  Disk: $disk_before → $disk_after\033[0m"
        echo -e "\033[36mℹ️  Duration: $((duration / 60))m $((duration % 60))s\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  This was a DRY RUN - no changes were made\033[0m"
        echo ""

        __cleanup_log "dev" "Completed in $((duration))s (disk: $disk_before → $disk_after)"
      }

      # ============================================
      # TIER 5: CLEANUP-AGGRESSIVE (Maximum cleanup with confirmations)
      # ============================================
      function cleanup-aggressive() {
        local dry_run=false
        local yes_flag=false

        # Parse flags
        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --yes|-y) yes_flag=true ;;
            --help|-h)
              echo "Usage: cleanup-aggressive [OPTIONS]"
              echo ""
              echo "Maximum cleanup (WITH CONFIRMATIONS for risky operations)"
              echo "Alias: cleanup-all (backward compat)"
              echo ""
              echo "Includes:"
              echo "  - Everything in cleanup-dev"
              echo "  - All tool caches (Ollama models, LLM caches)"
              echo "  - All development artifacts (node_modules, .venv, build dirs)"
              echo "  - macOS: Time Machine snapshots, iOS backups"
              echo "  - Old downloads (30+ days)"
              echo "  - All Docker volumes"
              echo "  - Nix: keep only last 2 generations"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations without executing"
              echo "  --yes, -y    Skip ALL confirmation prompts (use with caution!)"
              echo "  --help, -h   Show this help message"
              echo ""
              echo "⚠️  WARNING: This is a destructive operation"
              echo "    Review with --dry-run first!"
              return 0
              ;;
            *)
              echo "❌ Unknown option: $arg"
              echo "Run 'cleanup-aggressive --help' for usage"
              return 1
              ;;
          esac
        done

        # Show critical warning unless --yes flag is used
        if [[ "$yes_flag" != "true" ]]; then
          echo ""
          echo "🚨 AGGRESSIVE CLEANUP"
          echo "⚠️  DESTRUCTIVE OPERATION - Will permanently delete:"
          echo "  • Nix store garbage and old generations"
          echo "  • All tool caches (Ollama models, LLM caches)"
          echo "  • Development artifacts (node_modules, .venv, builds)"
          echo "  • Time Machine snapshots and iOS backups"
          echo "  • Old downloads (30+ days)"
          echo "  • All Docker volumes"
          echo ""
          echo "💡 TIP: Run with --dry-run first to preview changes"
          echo ""
          read -r "confirmation?Type 'DELETE' to confirm: "

          if [[ "$confirmation" != "DELETE" ]]; then
            echo "❌ Operation cancelled (incorrect confirmation)"
            return 1
          fi
        fi

        echo ""
        echo -e "\033[1m\033[31m🔥 AGGRESSIVE CLEANUP - Maximum System Cleanup\033[0m"
        echo -e "\033[31m============================================================\033[0m"
        echo -e "\033[33m⚠️  WARNING: This performs extensive cleanup operations\033[0m"
        echo -e "\033[33m⚠️  Some operations may require re-downloading data later\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  DRY RUN MODE - No changes will be made\033[0m"
        echo ""

        local start_time=$(date +%s)
        local disk_before=$(__cleanup_get_disk_space)

        __cleanup_log "aggressive" "Starting aggressive cleanup (dry_run=$dry_run, yes_flag=$yes_flag)"

        # Run dev tier inline
        echo -e "\033[35m🔧 Dev Tier Operations\033[0m"
        echo "=================================================="
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m  [DRY RUN] Would run dev cleanup operations\033[0m"
        else
          # All quick + standard + dev operations
          rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
          nix-env --delete-generations +5 2>/dev/null || true
          sudo nix-env --delete-generations +5 2>/dev/null || true
          command -v brew &>/dev/null && brew cleanup --prune=all &>/dev/null
          command -v micromamba &>/dev/null && micromamba clean --all --yes &>/dev/null
          rm -rf ~/.cache/* 2>/dev/null
          command -v npm &>/dev/null && npm cache clean --force &>/dev/null
          [[ -d "$HOME/Dev" ]] && {
            find "$HOME/Dev" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
            find "$HOME/Dev" -name ".ipynb_checkpoints" -type d -exec rm -rf {} + 2>/dev/null
            find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
          }
          echo "  ✅ Dev tier completed"
        fi
        echo ""

        # Ollama models (HIGH RISK)
        if [[ -d "$HOME/.ollama/models" ]] && __cleanup_confirm "Ollama models cleanup" "This will remove all Ollama models (requires re-download)" "high" "$yes_flag"; then
          echo -e "\033[35m🤖 Ollama Models Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would remove all Ollama models\033[0m"
          else
            rm -rf "$HOME/.ollama/models"/* 2>/dev/null && echo "  ✅ Ollama models removed"
          fi
          echo ""
        fi

        # HuggingFace cache (HIGH RISK)
        if [[ -d "$HOME/.cache/huggingface" ]] && __cleanup_confirm "HuggingFace cache cleanup" "This will remove all cached models (requires re-download)" "high" "$yes_flag"; then
          echo -e "\033[35m🤗 HuggingFace Cache Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would remove HuggingFace cache\033[0m"
          else
            rm -rf "$HOME/.cache/huggingface"/* 2>/dev/null && echo "  ✅ HuggingFace cache cleared"
          fi
          echo ""
        fi

        # Old downloads (MEDIUM RISK)
        if __cleanup_confirm "old downloads cleanup" "Remove files in ~/Downloads older than 30 days" "medium" "$yes_flag"; then
          echo -e "\033[35m📥 Old Downloads Cleanup (30+ days)\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            local old_count=$(find "$HOME/Downloads" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
            echo -e "\033[36m  [DRY RUN] Would remove $old_count files\033[0m"
          else
            local removed_count=$(find "$HOME/Downloads" -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
            find "$HOME/Downloads" -type f -mtime +30 -delete 2>/dev/null
            echo "  ✅ Removed $removed_count old files"
          fi
          echo ""
        fi

        # Docker volumes (HIGH RISK)
        if command -v docker &>/dev/null && docker info &>/dev/null && __cleanup_confirm "Docker volumes cleanup" "This will remove ALL Docker volumes (data loss possible)" "high" "$yes_flag"; then
          echo -e "\033[35m🐳 Docker Complete Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would run: docker system prune -af --volumes\033[0m"
          else
            docker system prune -af --volumes &>/dev/null && echo "  ✅ Docker completely cleaned"
          fi
          echo ""
        fi

        # Time Machine snapshots (HIGH RISK)
        if __cleanup_confirm "Time Machine snapshots" "Remove local Time Machine snapshots" "high" "$yes_flag"; then
          echo -e "\033[35m⏰ Time Machine Snapshots\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would remove Time Machine local snapshots\033[0m"
          else
            tmutil listlocalsnapshots / 2>/dev/null | grep "com.apple" | while read snapshot; do
              sudo tmutil deletelocalsnapshots $(echo "$snapshot" | cut -d'.' -f4) 2>/dev/null
            done
            echo "  ✅ Time Machine snapshots removed"
          fi
          echo ""
        fi

        # Aggressive Nix cleanup (keep only 2 generations)
        if __cleanup_confirm "aggressive Nix cleanup" "Keep only last 2 generations (more aggressive)" "medium" "$yes_flag"; then
          echo -e "\033[35m❄️  Aggressive Nix Cleanup\033[0m"
          echo "=================================================="
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m  [DRY RUN] Would keep only last 2 generations\033[0m"
          else
            nix-env --delete-generations +2 2>/dev/null || true
            sudo nix-env --delete-generations +2 2>/dev/null || true
            nix-collect-garbage -d &>/dev/null
            sudo nix-collect-garbage -d &>/dev/null
            nix-store --optimize &>/dev/null
            echo "  ✅ Aggressive Nix cleanup completed"
          fi
          echo ""
        fi

        # Final report
        local disk_after=$(__cleanup_get_disk_space)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        echo ""
        echo -e "\033[1m\033[32m✅ Aggressive Cleanup Complete!\033[0m"
        echo -e "\033[32m============================================================\033[0m"
        echo -e "\033[36mℹ️  Disk: $disk_before → $disk_after\033[0m"
        echo -e "\033[36mℹ️  Duration: $((duration / 60))m $((duration % 60))s\033[0m"
        [[ "$dry_run" == "true" ]] && echo -e "\033[33mℹ️  This was a DRY RUN - no changes were made\033[0m"
        echo ""

        __cleanup_log "aggressive" "Completed in $((duration))s (disk: $disk_before → $disk_after)"
      }

      # Alias for backward compatibility
      function cleanup-all() {
        cleanup-aggressive "$@"
      }

      # ============================================
      # CORE UTILITY FUNCTIONS
      # ============================================
      # NOTE: Duplicate function definitions removed (lines 1981-2052)
      # These functions are already defined earlier in the file:
      #   - mkcd() at line 495
      #   - kill-port() at line 518
      #   - gcl() at line 528
      #   - sysinfo() at line 550

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
        echo "📦 Available Micromamba Environments:"
        # Check base environment
        if [ -d "$HOME/micromamba" ]; then
          if [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" = "base" ]; then
            echo "  * base"
          else
            echo "    base"
          fi
        fi
        # Check named environments
        if [ -d "$HOME/micromamba/envs" ]; then
          for env in "$HOME/micromamba/envs"/*; do
            if [ -d "$env" ]; then
              local env_name=$(basename "$env")
              if [ -n "$CONDA_DEFAULT_ENV" ] && [ "$CONDA_DEFAULT_ENV" = "$env_name" ]; then
                echo "  * $env_name"
              else
                echo "    $env_name"
              fi
            fi
          done
        fi
        echo ""
        if [ -n "$VIRTUAL_ENV" ]; then
          echo "✅ Active UV/Venv Virtual Environment:"
          echo "  Path: $VIRTUAL_ENV"
          echo "  Python: $(python --version 2>&1)"
        elif [ -z "$CONDA_DEFAULT_ENV" ]; then
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
      # ============================================
      # TOOL-SPECIFIC CLEANUP FUNCTIONS
      # ============================================

      # Nix-specific cleanup
      function cleanup-nix() {
        local dry_run=false
        local keep=5

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --keep=*) keep="''${arg#*=}" ;;
            --help|-h)
              echo "Usage: cleanup-nix [OPTIONS]"
              echo ""
              echo "Nix-specific cleanup with generation management"
              echo ""
              echo "Options:"
              echo "  --dry-run       Preview operations"
              echo "  --keep=N        Keep last N generations (default: 5)"
              echo "  --help, -h      Show this help"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m❄️  NIX CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        local disk_before=$(__cleanup_get_disk_space)

        echo -e "\033[35m📊 Current Generations\033[0m"
        nix-env --list-generations --profile /nix/var/nix/profiles/system
        echo ""

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would remove generations older than last $keep\033[0m"
          echo -e "\033[36m[DRY RUN] Would run garbage collection\033[0m"
          echo -e "\033[36m[DRY RUN] Would optimize Nix store\033[0m"
        else
          echo "Removing old generations (keeping last $keep)..."
          sudo nix-env --delete-generations +$keep --profile /nix/var/nix/profiles/system 2>/dev/null || true
          nix-env --delete-generations +$keep --profile ~/.local/state/nix/profiles/home-manager 2>/dev/null || true
          echo "  ✅ Generations cleaned"
          echo ""

          echo "Running garbage collection..."
          nix-collect-garbage -d &>/dev/null
          sudo nix-collect-garbage -d &>/dev/null
          echo "  ✅ Garbage collection completed"
          echo ""

          echo "Optimizing Nix store..."
          nix-store --optimize &>/dev/null
          echo "  ✅ Store optimized"
        fi

        local disk_after=$(__cleanup_get_disk_space)
        echo ""
        echo -e "\033[32m✅ Nix cleanup complete! (Disk: $disk_before → $disk_after)\033[0m"
        echo ""
      }

      # Docker-specific cleanup
      function cleanup-docker() {
        local dry_run=false
        local volumes=false

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --volumes) volumes=true ;;
            --help|-h)
              echo "Usage: cleanup-docker [OPTIONS]"
              echo ""
              echo "Docker-specific cleanup"
              echo ""
              echo "Options:"
              echo "  --dry-run       Preview operations"
              echo "  --volumes       Also remove volumes (DESTRUCTIVE)"
              echo "  --help, -h      Show this help"
              return 0
              ;;
          esac
        done

        if ! command -v docker &>/dev/null; then
          echo "Docker not installed"
          return 1
        fi

        if ! docker info &>/dev/null; then
          echo "Docker not running"
          return 1
        fi

        echo ""
        echo -e "\033[1m\033[36m🐳 DOCKER CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        local disk_before=$(__cleanup_get_disk_space)

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would prune images, containers, networks\033[0m"
          [[ "$volumes" == "true" ]] && echo -e "\033[36m[DRY RUN] Would also remove volumes\033[0m"
        else
          if [[ "$volumes" == "true" ]]; then
            docker system prune -af --volumes && echo "  ✅ Docker completely cleaned (including volumes)"
          else
            docker system prune -af && echo "  ✅ Docker cleaned (volumes preserved)"
          fi
        fi

        local disk_after=$(__cleanup_get_disk_space)
        echo ""
        echo -e "\033[32m✅ Docker cleanup complete! (Disk: $disk_before → $disk_after)\033[0m"
        echo ""
      }

      # Python/UV-specific cleanup
      function cleanup-python() {
        local dry_run=false

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --help|-h)
              echo "Usage: cleanup-python [OPTIONS]"
              echo ""
              echo "Python/UV-specific cleanup"
              echo ""
              echo "Cleans:"
              echo "  - UV cache"
              echo "  - pip cache"
              echo "  - __pycache__ directories"
              echo "  - .pyc/.pyo files"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations"
              echo "  --help, -h   Show this help"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m🐍 PYTHON CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would clean UV cache\033[0m"
          echo -e "\033[36m[DRY RUN] Would clean pip cache\033[0m"
          [[ -d "$HOME/Dev" ]] && {
            local pycache_count=$(find "$HOME/Dev" -name "__pycache__" 2>/dev/null | wc -l | tr -d ' ')
            echo -e "\033[36m[DRY RUN] Would remove $pycache_count __pycache__ directories\033[0m"
          }
        else
          rm -rf ~/.cache/uv/* ~/.cache/pip/* 2>/dev/null && echo "  ✅ UV and pip caches cleaned"

          if [[ -d "$HOME/Dev" ]]; then
            local count=$(find "$HOME/Dev" -name "__pycache__" 2>/dev/null | wc -l | tr -d ' ')
            find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
            find "$HOME/Dev" -name "*.pyc" -type f -delete 2>/dev/null
            find "$HOME/Dev" -name "*.pyo" -type f -delete 2>/dev/null
            echo "  ✅ Removed $count __pycache__ directories"
          fi
        fi
        echo ""
      }

      # Git repository cleanup
      function cleanup-git() {
        local dry_run=false
        local base_dir="$HOME/Dev"

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --dir=*) base_dir="''${arg#*=}" ;;
            --help|-h)
              echo "Usage: cleanup-git [OPTIONS]"
              echo ""
              echo "Git repository cleanup (optimize and gc)"
              echo ""
              echo "Options:"
              echo "  --dry-run     Preview operations"
              echo "  --dir=PATH    Target directory (default: ~/Dev)"
              echo "  --help, -h    Show this help"
              return 0
              ;;
          esac
        done

        if [[ ! -d "$base_dir" ]]; then
          echo "Directory not found: $base_dir"
          return 1
        fi

        echo ""
        echo -e "\033[1m\033[36m📂 GIT CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        local repo_count=$(find "$base_dir" -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')

        if [[ $repo_count -eq 0 ]]; then
          echo "  ℹ️  No Git repositories found in $base_dir"
          return 0
        fi

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would optimize $repo_count Git repositories\033[0m"
        else
          echo "Optimizing $repo_count repositories..."
          find "$base_dir" -name ".git" -type d -exec sh -c 'cd "$(dirname "{}")" && git gc --quiet 2>/dev/null' \; 2>/dev/null
          echo "  ✅ Git repositories optimized"
        fi
        echo ""
      }

      # AWS cache cleanup
      function cleanup-aws() {
        local dry_run=false

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --help|-h)
              echo "Usage: cleanup-aws [OPTIONS]"
              echo ""
              echo "AWS CLI cache cleanup"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations"
              echo "  --help, -h   Show this help"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m☁️  AWS CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        if [[ ! -d "$HOME/.aws/cli/cache" ]]; then
          echo "  ℹ️  No AWS CLI cache found"
          return 0
        fi

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would clean AWS CLI cache\033[0m"
        else
          rm -rf "$HOME/.aws/cli/cache"/* 2>/dev/null && echo "  ✅ AWS CLI cache cleaned"
        fi
        echo ""
      }

      # Terraform cleanup
      function cleanup-terraform() {
        local dry_run=false
        local base_dir="$HOME/Dev"

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --dir=*) base_dir="''${arg#*=}" ;;
            --help|-h)
              echo "Usage: cleanup-terraform [OPTIONS]"
              echo ""
              echo "Terraform .terraform directory cleanup"
              echo ""
              echo "Options:"
              echo "  --dry-run     Preview operations"
              echo "  --dir=PATH    Target directory (default: ~/Dev)"
              echo "  --help, -h    Show this help"
              return 0
              ;;
          esac
        done

        if [[ ! -d "$base_dir" ]]; then
          echo "Directory not found: $base_dir"
          return 1
        fi

        echo ""
        echo -e "\033[1m\033[36m🏗️  TERRAFORM CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        local tf_count=$(find "$base_dir" -name ".terraform" -type d 2>/dev/null | wc -l | tr -d ' ')

        if [[ $tf_count -eq 0 ]]; then
          echo "  ℹ️  No .terraform directories found"
          return 0
        fi

        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would remove $tf_count .terraform directories\033[0m"
        else
          find "$base_dir" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
          echo "  ✅ Removed $tf_count .terraform directories"
        fi
        echo ""
      }

      # macOS-specific cleanup
      function cleanup-macos() {
        local dry_run=false
        local yes_flag=false

        for arg in "$@"; do
          case $arg in
            --dry-run) dry_run=true ;;
            --yes|-y) yes_flag=true ;;
            --help|-h)
              echo "Usage: cleanup-macos [OPTIONS]"
              echo ""
              echo "macOS-specific cleanup (Time Machine snapshots, system caches)"
              echo ""
              echo "Options:"
              echo "  --dry-run    Preview operations"
              echo "  --yes, -y    Skip confirmations"
              echo "  --help, -h   Show this help"
              return 0
              ;;
          esac
        done

        echo ""
        echo -e "\033[1m\033[36m🍎 MACOS CLEANUP\033[0m"
        echo -e "\033[36m========================================\033[0m"
        echo ""

        # Time Machine snapshots (HIGH RISK)
        if __cleanup_confirm "Time Machine snapshots" "Remove local Time Machine snapshots" "high" "$yes_flag"; then
          if [[ "$dry_run" == "true" ]]; then
            echo -e "\033[36m[DRY RUN] Would remove Time Machine snapshots\033[0m"
          else
            tmutil listlocalsnapshots / 2>/dev/null | grep "com.apple" | while read snapshot; do
              sudo tmutil deletelocalsnapshots $(echo "$snapshot" | cut -d'.' -f4) 2>/dev/null
            done
            echo "  ✅ Time Machine snapshots removed"
          fi
        fi

        # System caches (safe)
        echo ""
        echo "Cleaning safe system caches..."
        if [[ "$dry_run" == "true" ]]; then
          echo -e "\033[36m[DRY RUN] Would clean Safari, Homebrew, user caches\033[0m"
        else
          rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null
          rm -rf ~/Library/Caches/Homebrew/* 2>/dev/null
          rm -rf ~/Library/Logs/* 2>/dev/null
          echo "  ✅ System caches cleaned"
        fi
        echo ""
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

        # Check git hooks
        echo "🪝 Checking git hooks..."
        if [ -f ~/nix-darwin/.git/hooks/pre-commit ] && [ -f ~/nix-darwin/.git/hooks/pre-push ]; then
          echo "  ✅ Git hooks installed (pre-commit, pre-push)"
        else
          echo "  ⚠️  Git hooks not installed"
          echo "     Run: secrets-status for details"
          echo "     Hooks will be installed automatically on next rebuild"
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
        # AWS profile completion function
        function _aws_profiles() {
          local profiles
          profiles=($(grep '^\[profile' ~/.aws/config 2>/dev/null | sed 's/\[profile \(.*\)\]/\1/'))
          _describe 'aws profiles' profiles
        }

        # Enable completion for AWS functions
        compdef _aws_profiles awsuse
        compdef _aws_profiles awslogin
        compdef _aws_profiles awsrefresh

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

          # Save last-used profile for session persistence
          mkdir -p ~/.aws
          echo "$1" > ~/.aws/.last_profile

          echo "✅ Switched to profile: $1"
          echo "🔍 Checking identity..."
          awswho
        }

        # Auto-restore last AWS profile on shell startup (work Mac only)
        if [ -f ~/.aws/.last_profile ]; then
          export AWS_PROFILE=$(cat ~/.aws/.last_profile)
          echo "🔄 Restored AWS profile: $AWS_PROFILE"
        fi

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

      # Sync user data: Backup + Commit + Push
      function sync-user-data() {
        echo "🔄 Syncing user data..."
        echo ""

        # Run backup
        if ! backup-user-data; then
          echo "❌ Backup failed"
          return 1
        fi

        echo ""
        echo "📝 Committing changes..."

        # Check if in git repo
        if [ ! -d ~/nix-darwin/.git ]; then
          echo "❌ Error: Not in a git repository"
          return 1
        fi

        # Change to nix-darwin directory
        cd ~/nix-darwin

        # Check if there are changes in user-data
        if ! git diff --quiet user-data/ || ! git diff --cached --quiet user-data/; then
          # Stage all user-data changes
          git add user-data/

          # Create commit with timestamp
          local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
          git commit -m "Sync user-data: $timestamp"

          echo "✅ Changes committed"
          echo ""
          echo "📤 Pushing to remote..."

          # Push to remote
          if git push; then
            echo "✅ Sync complete!"
          else
            echo "❌ Push failed"
            return 1
          fi
        else
          echo "✅ No changes to sync"
        fi

        # Return to previous directory
        cd - > /dev/null
      }

      # Edit encrypted secrets with sops (system-level secrets)
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
        }

        if ! command -v sops &> /dev/null; then
          echo "❌ Error: sops not found"
          echo "Install with: brew install sops"
          return 1
        }

        # Show informational warning
        warn "Editing Encrypted Secrets" "INFO"
        echo "  • File will be decrypted temporarily"
        echo "  • Changes will be re-encrypted on save"
        echo "  • Make sure SOPS keys are configured correctly"
        echo ""

        echo "🔐 Opening secrets file: $secrets_file"
        echo ""
        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops "$secrets_file"
      }

      # Edit encrypted credentials (database passwords, rotating credentials)
      function edit-credentials() {
        local credentials_dir="$HOME/.secrets"
        local credentials_file="$credentials_dir/credentials.env"
        local encrypted_file="$credentials_dir/credentials.env.enc"

        # Create directory if it doesn't exist
        if [ ! -d "$credentials_dir" ]; then
          echo "📁 Creating credentials directory: $credentials_dir"
          mkdir -p "$credentials_dir"
          chmod 700 "$credentials_dir"
        fi

        # Check if sops is available
        if ! command -v sops &> /dev/null; then
          echo "❌ Error: sops not found"
          echo "Install with: nix-env -iA nixpkgs.sops"
          return 1
        fi

        # Check if age key exists
        if [ ! -f ~/.config/sops/age/keys.txt ]; then
          echo "❌ Error: Age key not found"
          echo "Generate with: age-keygen -o ~/.config/sops/age/keys.txt"
          return 1
        fi

        # Create template if encrypted file doesn't exist
        if [ ! -f "$encrypted_file" ]; then
          echo "📝 Creating credentials template..."
          cat > "$credentials_file" << 'TEMPLATE'
# Enterprise Credential Management
# This file contains rotating credentials for databases and services
#
# Variable Naming Pattern: <PROJECT>_<ENV>_<TYPE>
# Example: TI_PROD_USERNAME, TI_PROD_PASSWORD, TI_PROD_HOST
#
# After editing:
#   1. Save and exit
#   2. Run: exec zsh (to reload credentials)
#   3. Test connection: dbconnect-<instance> <env>
#
# WARNING: This file will be encrypted with SOPS on save

# ==================================================
# LAN CREDENTIALS (Reusable)
# ==================================================
export LAN_USERNAME="your-lan-id"
export LAN_PASSWORD="your-lan-password"

# ==================================================
# TRIRIGA (TI) - Oracle Database
# ==================================================
# Development
export TI_DEV_USERNAME="ti_dev"
export TI_DEV_PASSWORD="dev-password"
export TI_DEV_HOST="dev-oracle.company.com"
export TI_DEV_PORT="1521"
export TI_DEV_SERVICE="TIDEV"

# QA
export TI_QA_USERNAME="ti_qa"
export TI_QA_PASSWORD="qa-password"
export TI_QA_HOST="qa-oracle.company.com"
export TI_QA_PORT="1521"
export TI_QA_SERVICE="TIQA"

# Production
export TI_PROD_USERNAME="ti_prod"
export TI_PROD_PASSWORD="prod-password"
export TI_PROD_HOST="prod-oracle.company.com"
export TI_PROD_PORT="1521"
export TI_PROD_SERVICE="TIPROD"

# ==================================================
# HR DATABASE - SQL Server
# ==================================================
export HRDB_PROD_USERNAME="hr_app"
export HRDB_PROD_PASSWORD="hrdb-prod-password"
export HRDB_PROD_HOST="hrdb.company.com"
export HRDB_PROD_PORT="1433"
export HRDB_PROD_DATABASE="HRPROD"

# ==================================================
# PAYROLL - PostgreSQL (Uses LAN Credentials)
# ==================================================
export PAYROLL_PROD_USERNAME="$LAN_USERNAME"
export PAYROLL_PROD_PASSWORD="$LAN_PASSWORD"
export PAYROLL_PROD_HOST="payroll.company.com"
export PAYROLL_PROD_PORT="5432"
export PAYROLL_PROD_DATABASE="payroll"

# ==================================================
# ADD YOUR PROJECTS BELOW
# ==================================================
# Copy and modify templates above for each new database instance
TEMPLATE

          echo "✅ Template created at: $credentials_file"
          echo ""
          echo "🔐 Encrypting template..."
          SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops --encrypt "$credentials_file" > "$encrypted_file"
          rm "$credentials_file"
          echo "✅ Encrypted file created: $encrypted_file"
          echo ""
        fi

        # Decrypt, edit, and re-encrypt
        echo "🔐 Opening credentials with sops..."
        echo "File: $encrypted_file"
        echo ""
        echo "💡 After editing:"
        echo "  1. Save and exit"
        echo "  2. Run: exec zsh (reload credentials)"
        echo "  3. Test: dbconnect-<instance> <env>"
        echo ""

        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops "$encrypted_file"

        # Ensure decrypted file is cleaned up
        if [ -f "$credentials_file" ]; then
          echo "⚠️  Cleaning up decrypted file..."
          rm "$credentials_file"
        fi

        # Update shell to use new credentials
        echo ""
        echo "💡 To use updated credentials, run: exec zsh"
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

        # Check git hooks
        echo "🪝 Git Hooks:"
        if [ -f ~/nix-darwin/.git/hooks/pre-commit ] && [ -f ~/nix-darwin/.git/hooks/pre-push ]; then
          echo "  ✅ Git hooks installed (pre-commit, pre-push)"
          echo "     Hooks automatically validate secrets encryption"
        else
          echo "  ⚠️  Git hooks not installed"
          echo "     These hooks prevent committing unencrypted secrets"
          echo "     Install with: ~/nix-darwin/scripts/install-hooks.sh"
          echo "     Or they will be installed automatically on next rebuild"
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

      # Validate all secrets are properly encrypted
      function secrets-check() {
        if [ -x ~/nix-darwin/scripts/check-secrets-encrypted.sh ]; then
          ~/nix-darwin/scripts/check-secrets-encrypted.sh
        else
          echo "❌ Error: Validation script not found"
          echo "Expected: ~/nix-darwin/scripts/check-secrets-encrypted.sh"
          return 1
        fi
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

  # Starship prompt configuration - Override any conflicting settings
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Note: starship.toml is provided by base.nix mixin
}