{ config, pkgs, lib, hostname, myLib, username, machineId, ... }:

let
  # Configuration flag for Oh-My-Zsh
  enableOhMyZsh = true;  # Set to false to disable Oh-My-Zsh plugins

  # Derive paths dynamically
  nixDarwinDir = "${config.home.homeDirectory}/nix-darwin";
  homeDir = config.home.homeDirectory;
  machineBackupsDir = "${nixDarwinDir}/workspace/${machineId}";
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
      extended = true;  # Save timestamp and duration
    };

    # Session variables - Available in all shell sessions
    sessionVariables = {
      # SOPS configuration for secrets management
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";

      # Ensure history is immediately written
      HISTFILE = "${config.home.homeDirectory}/.zsh_history";
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
      zshconf = "code ${nixDarwinDir}/nix-config/home/_profiles/_template/shell/zsh.nix";
      gitconf = "code ${nixDarwinDir}/nix-config/home/_profiles/_template/programs/git.nix";
      vscodeconf = "code ${nixDarwinDir}/nix-config/home/_profiles/_template/programs/vscode.nix";
      condaconf = "code ${homeDir}/.condarc";
      awsconf = "code ${homeDir}/.aws/config";
      awscred = "code ${homeDir}/.aws/credentials";
      jupyterconf = "code ${homeDir}/.jupyter/jupyter_notebook_config.py";
      zshrc = "code ${homeDir}/.zshrc";
      zshsec = "code ${homeDir}/.zsh_secrets";

      # Nix-Darwin system management
      # nix-rebuild runs with pre-flight checks by default
      # IMPORTANT: Must export FLAKE_ROOT for gitignored config imports
      # Automatically restarts shell on success to load new configuration
      nix-rebuild = "${nixDarwinDir}/scripts/maintenance/pre-flight-checks.sh && sudo FLAKE_ROOT=${nixDarwinDir} darwin-rebuild switch --flake ${nixDarwinDir}#${machineId} --impure && exec zsh";

      # Skip pre-flight checks for emergency rebuilds (use with caution)
      # IMPORTANT: Must export FLAKE_ROOT for gitignored config imports
      # Automatically restarts shell on success to load new configuration
      nix-rebuild-skip-checks = "sudo FLAKE_ROOT=${nixDarwinDir} darwin-rebuild switch --flake ${nixDarwinDir}#${machineId} --impure && exec zsh";

      # Debug mode with verbose output for troubleshooting
      # Shows detailed build logs, stack traces, and Home Manager activation details
      # Usage: nix-rebuild-debug (for full rebuild with debug info)
      # Automatically restarts shell on success to load new configuration
      nix-rebuild-debug = "sudo FLAKE_ROOT=${nixDarwinDir} darwin-rebuild switch --flake ${nixDarwinDir}#${machineId} --impure --show-trace --verbose --print-build-logs && exec zsh";

      # Check configuration without building (no shell restart needed)
      nix-check = "nix flake check ${nixDarwinDir}";

      # Run pre-flight checks manually (without rebuilding, no shell restart needed)
      nix-preflight = "${nixDarwinDir}/scripts/maintenance/pre-flight-checks.sh";

      # System health check - Validate nix-darwin system state (no shell restart needed)
      # Usage: nix-health-check (normal) | nix-health-check --verbose (detailed)
      nix-health-check = "${nixDarwinDir}/scripts/maintenance/health-check.sh";
      nix-health = "${nixDarwinDir}/scripts/maintenance/health-check.sh";  # Shorter alternate

      # Compare configurations between generations (no shell restart needed)
      # Usage: nix-config-diff (current vs previous) | nix-config-diff --generations N M
      nix-config-diff = "${nixDarwinDir}/scripts/maintenance/config-diff.sh";
      nix-config-diff-packages = "${nixDarwinDir}/scripts/maintenance/config-diff.sh --packages-only";
      nix-config-diff-verbose = "${nixDarwinDir}/scripts/maintenance/config-diff.sh --verbose";

      # Rollback to previous generation and restart shell
      nix-rollback = "sudo darwin-rebuild --rollback && exec zsh";

      # Force home-manager regeneration (workaround for cache bug)
      # See: claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md
      # Automatically restarts shell on success
      nix-rebuild-hm-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.${machineId}.config.home-manager.users.${username}.home.activationPackage) && $result/activate && sudo FLAKE_ROOT=${nixDarwinDir} darwin-rebuild switch --flake ${nixDarwinDir}#${machineId} --impure && exec zsh";
      nix-home-rebuild-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.${machineId}.config.home-manager.users.${username}.home.activationPackage) && $result/activate && exec zsh";

      # Scaffold new machine configuration from template
      nix-scaffold-machine = "${nixDarwinDir}/scripts/setup/scaffold-new-machine.sh";
      nix-new-machine = "${nixDarwinDir}/scripts/setup/scaffold-new-machine.sh";

      # Secret management (Secret Management v2.0)
      # Tier 3: domain-action pattern for namespace grouping (secrets-*)
      secrets-rescan = "${nixDarwinDir}/scripts/secrets/rescan-secrets.sh";
      secrets-edit = "${nixDarwinDir}/scripts/secrets/edit-secrets.sh";
      secrets-view = "${nixDarwinDir}/scripts/secrets/view-secrets.sh";
      secrets-backup = "${nixDarwinDir}/scripts/secrets/backup-secrets.sh";
      secrets-audit = "${nixDarwinDir}/scripts/secrets/audit-secrets.sh";

      # Maintenance & validation
      nix-verify-backups = "${nixDarwinDir}/scripts/maintenance/verify-backups.sh";

      # ============================================
      # WORKFLOW HELPERS
      # ============================================
      # Note: Personal app launchers (ff, cld, gpt, cursor, etc.) moved to personal.nix
      # to prevent them from appearing on work machine where Homebrew is disabled
      cc = "claude";  # Claude Code CLI (universal - works on both machines)
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
      se = "sops -e -i";  # SOPS edit secrets

      # ============================================
      # NAVIGATION
      # ============================================
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "~" = "cd ~";
      "-" = "cd -";

      # Quick directories (cd operations)
      dev = "cd ~/Dev";
      downloads = "cd ~/Downloads";
      desktop = "cd ~/Desktop";
      docs = "cd ~/Documents";
      apps = "cd ~/Applications";
      down = "cd ~/Downloads";
      desk = "cd ~/Desktop";

      # Finder operations (Tier 5: f + target)
      fdev = "open ~/Dev";
      fdown = "open ~/Downloads";
      fdesk = "open ~/Desktop";
      fdocs = "open ~/Documents";

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

      # Micromamba (Tier 4: abbreviated domain)
      # Note: m-act and m-deact use functions (not aliases) to show usage help
      m-create = "micromamba create";
      m-list = "micromamba env list";
      m-install = "micromamba install";
      m-remove = "micromamba remove";

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

    # Init content (combined: micromamba lazy-load, then main config)
    initContent = lib.mkMerge [
      # Micromamba LAZY initialization - only runs when first used
      # This saves ~100ms on shell startup
      (lib.mkOrder 550 ''
        # Lazy-load micromamba - only initialize when first invoked
        if command -v micromamba &> /dev/null; then
          export MAMBA_EXE="${"\${commands[micromamba]}"}"
          export MAMBA_ROOT_PREFIX="$HOME/micromamba"

          # Wrapper function that initializes micromamba on first use
          micromamba() {
            unfunction micromamba  # Remove this wrapper
            eval "$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
            micromamba "$@"  # Run the actual command
          }
        fi
      '')

      # Main shell configuration (runs after oh-my-zsh)
      ''
      # ============================================
      # ENVIRONMENT SETUP
      # ============================================
      # SOPS configuration (also set in sessionVariables, but ensure early availability)
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      # NOTE: History options are set declaratively in programs.zsh.history above
      # Do NOT duplicate setopt commands here - they conflict with Nix-managed options

      # ============================================
      # SOURCE SECRETS
      # ============================================
      [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

      # ============================================
      # LOAD CREDENTIALS (Environment Variables)
      # ============================================
      # Credentials are loaded from encrypted file for database connections
      # and other services requiring rotating passwords
      # SECURITY: Uses process substitution - credentials NEVER touch disk
      if [ -f "$HOME/.secrets/credentials.env.enc" ]; then
        if command -v sops &> /dev/null; then
          # Decrypt directly to memory using process substitution
          # This avoids writing cleartext credentials to disk
          set -a  # Auto-export all variables
          if source <(sops --decrypt "$HOME/.secrets/credentials.env.enc" 2>/dev/null); then
            echo "🔐 Loaded encrypted credentials"
          fi
          set +a
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
      # OPTIONAL OH-MY-ZSH CUSTOM PLUGINS
      # ============================================
      # NOTE: autosuggestions and syntax-highlighting are handled by Nix
      # (autosuggestion.enable = true, syntaxHighlighting.enable = true)
      # Only load plugins NOT managed by Nix here

      # Additional completions (if manually installed)
      if [ -d ~/.oh-my-zsh/custom/plugins/zsh-completions ]; then
        fpath+=(~/.oh-my-zsh/custom/plugins/zsh-completions/src)
      fi

      # You-should-use - reminds you to use aliases (if manually installed)
      if [ -f ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh
      fi

      # History substring search (if manually installed)
      if [ -f ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
        source ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
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
      # WELCOME MESSAGE (cached Python version)
      # ============================================
      if [ "$TERM_PROGRAM" != "vscode" ]; then
        # Cache Python version to avoid running python3 --version on every startup
        : ''${_PYTHON_VERSION:=$(python3 --version 2>&1 | awk '{print $2}')}
        echo "$MACHINE_MODE | Python: $_PYTHON_VERSION"
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
      # LOAD MODULAR FUNCTION FILES
      # ============================================
      # Functions extracted to separate files for maintainability
      # See: functions/README.md for documentation

      ${builtins.readFile ./functions/core.zsh}
      ${builtins.readFile ./functions/update.zsh}
      ${builtins.readFile ./functions/python.zsh}
      ${builtins.readFile ./functions/cleanup.zsh}
      ${builtins.readFile ./functions/credentials-mgmt.zsh}

      # ============================================
      # INLINE FUNCTIONS BELOW (duplicates of above, to be removed)
      # (Removed - functions now loaded from external files)

      # ============================================
      # HOT RELOAD FUNCTIONS
      # ============================================
      # Quick reload of secrets and environment without rebuild
      # Functions: reload-secrets, secrets-local {edit|show|rm}

      ${myLib.reload.mkAllHotReloadFunctions}

      # NOTE: Zoxide is initialized by Nix (programs.zoxide.enable = true in base.nix)
      # The 'z' command is automatically available - no manual init needed
      # Alias 'zz' for jumping back is kept for convenience
      alias zz="z -"
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
