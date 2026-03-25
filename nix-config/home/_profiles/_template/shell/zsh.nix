{ config, pkgs, lib, hostname, myLib, username, machineId, ... }:

let
  # Derive paths dynamically
  nixDarwinDir = "${config.home.homeDirectory}/nix-darwin";
  homeDir = config.home.homeDirectory;

  # Lazy-loaded function files (sourced on first use, not at startup)
  # Saves ~50-80ms by deferring 933 lines of rarely-used function parsing
  lazyCleanup = pkgs.writeText "cleanup.zsh" (builtins.readFile ./functions/cleanup.zsh);
  lazyUpdate = pkgs.writeText "update.zsh" (builtins.readFile ./functions/update.zsh);
  lazyCredentials = pkgs.writeText "credentials-mgmt.zsh" (builtins.readFile ./functions/credentials-mgmt.zsh);

  # Static generation of shell init scripts to improve startup time
  # This moves ~15-30ms of processing from shell-start to build-time
  shellInitCache = pkgs.runCommand "shell-init-cache" {} ''
    # Fix for tools attempting to write to locked /homeless-shelter
    export HOME=$(mktemp -d)
    
    mkdir -p $out
    ${pkgs.starship}/bin/starship init zsh > $out/starship.zsh
    ${pkgs.zoxide}/bin/zoxide init zsh > $out/zoxide.zsh
    ${pkgs.atuin}/bin/atuin init zsh > $out/atuin.zsh
    ${pkgs.direnv}/bin/direnv hook zsh > $out/direnv.zsh
    ${pkgs.fzf}/bin/fzf --zsh > $out/fzf.zsh

    # Compile to .zwc for faster loading (using same zsh version)
    # This prevents parsing overhead at runtime
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/starship.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/zoxide.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/atuin.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/direnv.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/fzf.zsh"
  '';
in
{
  # ENHANCED Zsh configuration - Complete declarative shell setup
  # Includes: Auto-activation, aliases, functions, and update system

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = false; # Replaced by fast-syntax-highlighting (see initContent)

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

      # nh (Nix Helper) configuration - enables zero-arg nh commands
      # Note: NH_DARWIN_FLAKE is the flake path, NH_DARWIN_HOSTNAME is our custom var for -H
      NH_DARWIN_FLAKE = nixDarwinDir;
      NH_DARWIN_HOSTNAME = machineId;
    };

    # COMPLETE Shell aliases - merged from all sources
    shellAliases = {
      # ============================================
      # SYSTEM & CONFIGURATION
      # ============================================
      c = "clear";
      reload = "source ~/.zshrc && printf '\\033[90m zshrc reloaded\\033[0m\\n'";
      restart = "exec zsh";

      # Quick open shortcuts
      vs = "code .";          # Open VS Code in current directory
      f = "open .";           # Open Finder in current directory

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
      # Usage: nix-rebuild [options]
      # See: scripts/maintenance/rebuild.sh
      nix-rebuild = "${nixDarwinDir}/scripts/maintenance/rebuild.sh";
      nix-rebuild-skip-checks = "${nixDarwinDir}/scripts/maintenance/rebuild.sh --skip-checks";
      nix-rebuild-debug = "${nixDarwinDir}/scripts/maintenance/rebuild.sh --debug";

      # Check configuration without building (no shell restart needed)
      nix-check = "nix flake check ${nixDarwinDir}";

      # Run pre-flight checks manually (without rebuilding, no shell restart needed)
      nix-preflight = "${nixDarwinDir}/scripts/maintenance/pre-flight-checks.sh";

      # System health check - Validate nix-darwin system state (no shell restart needed)
      # Usage: nix-health (normal) | nix-health --verbose (detailed)
      nix-health = "${nixDarwinDir}/scripts/maintenance/health-check.sh";

      # Compare configurations between generations (no shell restart needed)
      # Usage: nix-config-diff (current vs previous) | nix-config-diff --generations N M
      nix-config-diff = "${nixDarwinDir}/scripts/maintenance/config-diff.sh";
      nix-config-diff-packages = "${nixDarwinDir}/scripts/maintenance/config-diff.sh --packages-only";
      nix-config-diff-verbose = "${nixDarwinDir}/scripts/maintenance/config-diff.sh --verbose";

      # Rollback to previous generation and restart shell
      nix-rollback = "${nixDarwinDir}/scripts/maintenance/rebuild.sh --rollback";

      # nh (Nix Helper) convenience aliases
      # Uses subshell to cd to flake directory (nh works best from within flake dir)
      nh-switch = "(cd ${nixDarwinDir} && nh darwin switch -H ${machineId} . --impure)";
      nh-build = "(cd ${nixDarwinDir} && nh darwin build -H ${machineId} . --impure)";
      nh-clean = "nh clean all --keep 5";          # Smart cleanup, keep 5 generations
      nh-clean-aggressive = "nh clean all --keep 2";  # Aggressive cleanup
      nh-search = "nh search";                     # Search nixpkgs

      # Force home-manager regeneration (workaround for cache bug)
      # See: claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md
      # Automatically restarts shell on success
      nix-rebuild-hm-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.${machineId}.config.home-manager.users.${username}.home.activationPackage) && $result/activate && sudo FLAKE_ROOT=${nixDarwinDir} darwin-rebuild switch --flake ${nixDarwinDir}#${machineId} --impure && exec zsh";
      nix-home-rebuild-force = "cd ${nixDarwinDir} && result=$(nix build --impure --print-out-paths .#darwinConfigurations.${machineId}.config.home-manager.users.${username}.home.activationPackage) && $result/activate && exec zsh";

      # Scaffold new machine configuration from template
      nix-scaffold-machine = "${nixDarwinDir}/scripts/setup/scaffold-new-machine.sh";

      # Secret management (Secret Management v2.0)
      # Tier 3: domain-action pattern for namespace grouping (secrets-*)
      secrets-rescan = "${nixDarwinDir}/scripts/secrets/rescan-secrets.sh";
      secrets-edit = "${nixDarwinDir}/scripts/secrets/edit-secrets.sh";
      secrets-view = "${nixDarwinDir}/scripts/secrets/view-secrets.sh";
      secrets-backup = "${nixDarwinDir}/scripts/secrets/backup-secrets.sh";
      secrets-audit = "${nixDarwinDir}/scripts/secrets/audit-secrets.sh";
      # secrets-status provided by lazy-loaded credentials-mgmt.zsh (richer output)
      secrets-deploy = "${nixDarwinDir}/scripts/secrets/deploy-secrets.sh";

      # Maintenance & validation
      nix-verify-backups = "${nixDarwinDir}/scripts/maintenance/verify-backups.sh";
      nix-brew-audit = "${nixDarwinDir}/scripts/maintenance/brew-nix-audit.sh";

      # ============================================
      # WORKFLOW HELPERS
      # ============================================
      # Note: Personal app launchers (ff, cld, gpt, cursor, etc.) moved to personal.nix
      # to prevent them from appearing on work machine where Homebrew is disabled
      cc = "claude";  # Claude Code CLI (universal - works on both machines)
      ccr = "claude --resume";  # Resume last conversation
      ccc = "claude --continue";  # Continue last conversation
      cca = "claude --add-dir";  # Add directory to context
      "cc!" = "claude --dangerously-skip-permissions";  # Auto-approve (use with caution)
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
      down = "cd ~/Downloads";
      desk = "cd ~/Desktop";
      docs = "cd ~/Documents";
      apps = "cd ~/Applications";

      # Finder operations (Tier 5: f + target)
      fdev = "open ~/Dev";
      fdown = "open ~/Downloads";
      fdesk = "open ~/Desktop";
      fdocs = "open ~/Documents";

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
      # awswho defined as function in aws-helpers.nix (richer output than simple alias)

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
      # CLEANUP & MAINTENANCE
      # ============================================
      # Main cleanup command (Standard Tier)
      cleanup = "cleanup-standard";
      clean = "cleanup-quick";
      
      # Specific cleanup tasks (Zsh functions)
      # cleanup-safe       : Logs/temp files only
      # cleanup-quick      : Safe + brew cleanup
      # cleanup-standard   : Quick + Docker prune + Nix GC
      # cleanup-aggressive : Deep clean (requires confirmation)
      
      # Script-based maintenance
      system-cleanup = "${nixDarwinDir}/scripts/maintenance/system-cleanup.sh";
    };


    # Init content (combined: micromamba lazy-load, then main config)
    initContent = lib.mkMerge [
      # PERFORMANCE OPTIMIZATIONS (The <0.5s Goal)
      # Hybrid Approach: Static generation of init scripts
      # Moves ~20ms of processing from shell-start to build-time
      (lib.mkOrder 40 ''
        # DARK/LIGHT MODE DETECTION FOR STARSHIP
        # Detection waterfall:
        #   1. COLORFGBG env var (iTerm2 — instant)
        #   2. macOS appearance (Ghostty/Warp/Terminal — follows system)
        _nix_starship=$(readlink -f "$HOME/.config/starship.toml" 2>/dev/null)
        if [[ "$_nix_starship" == /nix/store/* ]]; then
          _writable_starship="$HOME/.cache/starship/starship.toml"
          mkdir -p "$(dirname "$_writable_starship")"

          # Detect dark/light mode
          _palette=""
          if [[ -n "$COLORFGBG" ]]; then
            # iTerm2 sets COLORFGBG="fg;bg" — bg < 8 means dark
            _bg="''${COLORFGBG##*;}"
            if (( _bg < 8 )); then
              _palette="catppuccin_mocha"
            else
              _palette="catppuccin_latte"
            fi
            unset _bg
          fi
          # Fallback: macOS system appearance (covers Ghostty, Warp, Terminal.app)
          if [[ -z "$_palette" ]]; then
            if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
              _palette="catppuccin_mocha"
            else
              _palette="catppuccin_latte"
            fi
          fi

          # Only rewrite if nix config changed or palette differs
          if [[ ! -f "$_writable_starship" ]] || \
             ! diff -q "$_nix_starship" "$_writable_starship" &>/dev/null || \
             ! grep -q "palette = '$_palette'" "$_writable_starship" 2>/dev/null; then
            sed "s/^palette = .*/palette = '$_palette'/" "$_nix_starship" > "$_writable_starship"
          fi
          export STARSHIP_CONFIG="$_writable_starship"
          unset _writable_starship _palette
        fi
        unset _nix_starship
      '')

      (lib.mkOrder 50 ''
        # STATICALLY GENERATED INTEGRATIONS
        # Replaces "eval $(tool init zsh)" to save runtime overhead.
        # Generated at build time via pkgs.runCommand.

        source ${shellInitCache}/starship.zsh
        source ${shellInitCache}/zoxide.zsh
        source ${shellInitCache}/atuin.zsh
        source ${shellInitCache}/direnv.zsh
      '')

      (lib.mkOrder 100 ''
        # 1. FASTER COMPLETION INIT (Bypass compaudit on secure Nix paths)
        # We prefer speed (compinit -C) over checking every file on every startup.
        # On a Nix system, paths are immutable, so this is very safe.
        autoload -Uz compinit
        ZCOMPDUMP="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
        mkdir -p "$(dirname "$ZCOMPDUMP")"
        
        # Always use -u (skip permission checks) and -C (skip file validation) if dump exists
        if [[ -s "$ZCOMPDUMP" ]]; then
          compinit -u -C -d "$ZCOMPDUMP"
        else
          compinit -u -d "$ZCOMPDUMP"
          # Compile only on fresh generation
          if [[ ! -s "$ZCOMPDUMP.zwc" || "$ZCOMPDUMP" -nt "$ZCOMPDUMP.zwc" ]]; then
            zcompile "$ZCOMPDUMP"
          fi
        fi

        # Helper to refresh completions manually (run after adding new packages)
        alias refresh-completions="rm -f $ZCOMPDUMP*; compinit -u -d $ZCOMPDUMP; zcompile $ZCOMPDUMP; echo 'Completions refreshed'"

        # 2. REPLACEMENTS FOR OMZ PLUGINS
        # sudo (double ESC)
        sudo-command-line() {
            [[ -z $BUFFER ]] && zle up-history
            if [[ $BUFFER == sudo\ * ]]; then
                LBUFFER="''${LBUFFER#sudo }"
            else
                LBUFFER="sudo $LBUFFER"
            fi
        }
        zle -N sudo-command-line
        bindkey "\e\e" sudo-command-line

        # extract
        extract() {
          if [ -f $1 ] ; then
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
              *)           echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }

        # 3. LAZY LOADERS (Heavy completions — generated by myLib.mkLazyCompletion)
        ${myLib.mkLazyCompletion {
          name = "aws";
          binary = "${pkgs.awscli2}/bin/aws";
          completionCommand = "${pkgs.awscli2}/bin/aws_completer";
        }}
        ${myLib.mkLazyCompletion {
          name = "kubectl";
          binary = "${pkgs.kubectl}/bin/kubectl";
          completionCommand = "${pkgs.kubectl}/bin/kubectl completion zsh";
        }}
        ${myLib.mkLazyCompletion {
          name = "docker";
          binary = "${pkgs.docker}/bin/docker";
          completionCommand = "${pkgs.docker}/bin/docker completion zsh";
        }}
      '')

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
      # FZF INTEGRATION (pre-generated at build-time)
      # ============================================
      # Only load in interactive shells with zle (avoids warnings in subshells)
      if [[ $options[zle] = on ]]; then
        source ${shellInitCache}/fzf.zsh 2>/dev/null
      fi

      # ============================================
      # SOURCE SECRETS
      # ============================================
      [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

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
      [[ -n "$TF_PLUGIN_CACHE_DIR" ]] && mkdir -p "$TF_PLUGIN_CACHE_DIR"

      # ============================================
      # WELCOME MESSAGE
      # ============================================
      if [ "$TERM_PROGRAM" != "vscode" ]; then
        _nix_ver=$(nix --version 2>/dev/null | awk '{print $NF}')
        _os_ver=$(sw_vers -productVersion 2>/dev/null)
        printf '\033[90m %s · macOS %s · nix %s\033[0m\n' "$MACHINE_MODE" "$_os_ver" "$_nix_ver"
        unset _nix_ver _os_ver
      fi

      # ============================================
      # LOAD MODULAR FUNCTION FILES
      # ============================================
      # Functions extracted to separate files for maintainability
      # See: functions/README.md for documentation

      ${builtins.readFile ./functions/core.zsh}
      ${builtins.readFile ./functions/python.zsh}
      ${builtins.readFile ./functions/aws-completion.zsh}

      # Lazy-load: cleanup functions (377 lines, used occasionally)
      __lazy_load_cleanup() {
        unfunction cleanup-safe cleanup-quick cleanup-standard cleanup-dev \
          cleanup-aggressive cleanup-all cleanup-nix cleanup-docker cleanup-python \
          __lazy_load_cleanup 2>/dev/null
        source ${lazyCleanup}
      }
      cleanup-safe() { __lazy_load_cleanup; cleanup-safe "$@"; }
      cleanup-quick() { __lazy_load_cleanup; cleanup-quick "$@"; }
      cleanup-standard() { __lazy_load_cleanup; cleanup-standard "$@"; }
      # cleanup() stub omitted — alias `cleanup = "cleanup-standard"` handles it
      cleanup-dev() { __lazy_load_cleanup; cleanup-dev "$@"; }
      cleanup-aggressive() { __lazy_load_cleanup; cleanup-aggressive "$@"; }
      cleanup-all() { __lazy_load_cleanup; cleanup-all "$@"; }
      cleanup-nix() { __lazy_load_cleanup; cleanup-nix "$@"; }
      cleanup-docker() { __lazy_load_cleanup; cleanup-docker "$@"; }
      cleanup-python() { __lazy_load_cleanup; cleanup-python "$@"; }

      # Lazy-load: update functions (315 lines, used weekly)
      __lazy_load_update() {
        unfunction update-nix update-brew update-mamba update-vscode update-mas \
          update-dev update-system update-all __lazy_load_update 2>/dev/null
        source ${lazyUpdate}
      }
      update-nix() { __lazy_load_update; update-nix "$@"; }
      update-brew() { __lazy_load_update; update-brew "$@"; }
      update-mamba() { __lazy_load_update; update-mamba "$@"; }
      update-vscode() { __lazy_load_update; update-vscode "$@"; }
      update-mas() { __lazy_load_update; update-mas "$@"; }
      update-dev() { __lazy_load_update; update-dev "$@"; }
      update-system() { __lazy_load_update; update-system "$@"; }
      update-all() { __lazy_load_update; update-all "$@"; }

      # Lazy-load: credentials management (241 lines, used occasionally)
      __lazy_load_credentials() {
        unfunction edit-secrets edit-credentials secrets-status secrets-check \
          backup-workspace restore-workspace sync-workspace nix-rebuild-confirm \
          __lazy_load_credentials 2>/dev/null
        source ${lazyCredentials}
      }
      edit-secrets() { __lazy_load_credentials; edit-secrets "$@"; }
      edit-credentials() { __lazy_load_credentials; edit-credentials "$@"; }
      secrets-status() { __lazy_load_credentials; secrets-status "$@"; }
      secrets-check() { __lazy_load_credentials; secrets-check "$@"; }
      backup-workspace() { __lazy_load_credentials; backup-workspace "$@"; }
      restore-workspace() { __lazy_load_credentials; restore-workspace "$@"; }
      sync-workspace() { __lazy_load_credentials; sync-workspace "$@"; }
      nix-rebuild-confirm() { __lazy_load_credentials; nix-rebuild-confirm "$@"; }
      # nix-health() stub omitted — alias `nix-health` points to health-check.sh script

      # ============================================
      # HOT RELOAD FUNCTIONS
      # ============================================
      # Quick reload of secrets and environment without rebuild
      # Functions: secrets-reload, secrets-local {edit|show|rm}

      ${myLib.reload.mkAllHotReloadFunctions}

      alias zz="z -"
      ''
      
      (lib.mkOrder 900 ''
        # FAST SYNTAX HIGHLIGHTING
        # Replaces standard zsh-syntax-highlighting (saves ~700ms)
        # Sourced at the end to ensure it wraps all widgets correctly
        source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
      '')

      (lib.mkOrder 950 ''
        # BACKGROUND COMPILATION (runs after prompt, non-blocking)
        # Compiles zcompdump and function files to .zwc bytecode for faster loading
        {
          if [[ -s "$ZCOMPDUMP" && (! -s "$ZCOMPDUMP.zwc" || "$ZCOMPDUMP" -nt "$ZCOMPDUMP.zwc") ]]; then
            zcompile "$ZCOMPDUMP"
          fi
        } &!
      '')
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
    # Disable standard integration as we statically source it in initExtra
    enableZshIntegration = lib.mkForce false;
  };

  # Disable other standard integrations managed by static cache
  programs.zoxide.enableZshIntegration = lib.mkForce false;
  programs.atuin.enableZshIntegration = lib.mkForce false;
  programs.direnv.enableZshIntegration = lib.mkForce false;
}
