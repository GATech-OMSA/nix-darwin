{ config, pkgs, lib, hostname, myLib, username, machineId, ... }:

let
  # Derive paths dynamically
  nixDarwinDir = "${config.home.homeDirectory}/nix-darwin";
  homeDir = config.home.homeDirectory;

  # Lazy-loaded function files (sourced on first use, not at startup).
  # Defers ~1300 lines of rarely-used function parsing (#012 moved core/python/
  # aws-completion out of initContent into this pattern; cleanup/update/
  # credentials-mgmt were already lazy).
  lazyCleanup = pkgs.writeText "cleanup.zsh" (builtins.readFile ./functions/cleanup.zsh);
  lazyUpdate = pkgs.writeText "update.zsh" (builtins.readFile ./functions/update.zsh);
  lazyCredentials = pkgs.writeText "credentials-mgmt.zsh" (builtins.readFile ./functions/credentials-mgmt.zsh);
  lazyCore = pkgs.writeText "core.zsh" (builtins.readFile ./functions/core.zsh);
  lazyPython = pkgs.writeText "python.zsh" (builtins.readFile ./functions/python.zsh);
  lazyAwsCompletion = pkgs.writeText "aws-completion.zsh" (builtins.readFile ./functions/aws-completion.zsh);
  lazyDispatch = pkgs.writeText "dispatch.zsh" (builtins.readFile ./functions/dispatch.zsh);

  # Static generation of shell init scripts to improve startup time
  # This moves ~15-30ms of processing from shell-start to build-time.
  #
  # SIGCHLD-race patches (macOS 15+):
  # zsh's getoutput → waitforpid path can lose SIGCHLD when a $()
  # subshell exits before the parent enters sigsuspend, wedging the shell
  # in __sigsuspend forever. We patch generated init scripts to replace
  # racy command-substitutions with foreground redirect (waitjobs path).
  shellInitCache = pkgs.runCommand "shell-init-cache" {} ''
    # Fix for tools attempting to write to locked /homeless-shelter
    export HOME=$(mktemp -d)

    mkdir -p $out
    ${pkgs.starship}/bin/starship init zsh > $out/starship.zsh
    ${pkgs.zoxide}/bin/zoxide init zsh > $out/zoxide.zsh
    ${pkgs.atuin}/bin/atuin init zsh > $out/atuin.zsh
    ${pkgs.direnv}/bin/direnv hook zsh > $out/direnv.zsh
    ${pkgs.fzf}/bin/fzf --zsh > $out/fzf.zsh

    # Patch atuin.zsh: replace `$(atuin uuid)` (racy command-substitution)
    # with a file-redirect pattern that uses zsh's waitjobs path instead of
    # the racy waitforpid path. Pinned to absolute atuin binary so PATH
    # changes during init can't break it.
    ${pkgs.gnused}/bin/sed -i \
      "s|export ATUIN_SESSION=\$(atuin uuid)|${pkgs.atuin}/bin/atuin uuid > \"\''${TMPDIR:-/tmp}/.atuin-session.\$\$\" 2>/dev/null \&\& export ATUIN_SESSION=\"\$(<\''${TMPDIR:-/tmp}/.atuin-session.\$\$)\" \&\& /bin/rm -f \"\''${TMPDIR:-/tmp}/.atuin-session.\$\$\"|" \
      $out/atuin.zsh

    # Verify patch applied (build fails if upstream renames the line)
    if ${pkgs.gnugrep}/bin/grep -qF 'export ATUIN_SESSION=$(atuin uuid)' $out/atuin.zsh; then
      echo "ERROR: atuin.zsh sed patch did not match — upstream changed the line" >&2
      exit 1
    fi

    # Verify the preexec hook is registered as _atuin_preexec — the SIGCHLD-safe
    # override defined in initContent replaces that exact function. If atuin
    # renames the symbol, the override becomes a dead function and the racy
    # `$(atuin history start …)` silently fires every command. Build fails so
    # the override gets updated. (F12b)
    if ! ${pkgs.gnugrep}/bin/grep -qF 'add-zsh-hook preexec _atuin_preexec' $out/atuin.zsh; then
      echo "ERROR: atuin.zsh no longer registers '_atuin_preexec' as the preexec hook — the SIGCHLD-safe override in zsh.nix is dead; update it to the new symbol" >&2
      exit 1
    fi

    # Patch starship.zsh: replace top-level `PROMPT2="$(starship prompt --continuation)"`
    # — the $() runs at every shell source (i.e. every `exec zsh`) and triggers
    # the SIGCHLD waitforpid race. Pre-compute the continuation prompt at build
    # time and embed the result as a literal string, eliminating the runtime fork.
    starship_cont=$(${pkgs.starship}/bin/starship prompt --continuation 2>/dev/null || printf '❯ ')
    # Escape any sed-special chars in the captured string
    escaped_cont=$(printf '%s' "$starship_cont" | ${pkgs.gnused}/bin/sed -e 's/[\&|]/\\&/g')
    ${pkgs.gnused}/bin/sed -i \
      "s|^PROMPT2=\"\$(.*starship.* prompt --continuation)\"|PROMPT2=\"$escaped_cont\"|" \
      $out/starship.zsh

    # Verify patch applied
    if ${pkgs.gnugrep}/bin/grep -qE '^PROMPT2="\$\(.*starship.*--continuation' $out/starship.zsh; then
      echo "ERROR: starship.zsh PROMPT2 sed patch did not match — upstream changed the line" >&2
      exit 1
    fi

    # Patch fzf.zsh: replace top-level `binding=$(bindkey '^I')` — runs at
    # source time inside a `{}` block and triggers the SIGCHLD race. Convert
    # to file-redirect pattern (waitjobs path) instead of $() (waitforpid path).
    ${pkgs.gnused}/bin/sed -i \
      "s|binding=\$(bindkey '\\^I')|bindkey '^I' > \"\''${TMPDIR:-/tmp}/.fzf-binding.\$\$\" 2>/dev/null \&\& binding=\"\$(<\''${TMPDIR:-/tmp}/.fzf-binding.\$\$)\" \&\& /bin/rm -f \"\''${TMPDIR:-/tmp}/.fzf-binding.\$\$\"|" \
      $out/fzf.zsh

    # Verify patch applied
    if ${pkgs.gnugrep}/bin/grep -qF "binding=\$(bindkey '^I')" $out/fzf.zsh; then
      echo "ERROR: fzf.zsh binding sed patch did not match — upstream changed the line" >&2
      exit 1
    fi

    # Compile to .zwc for faster loading (using same zsh version)
    # This prevents parsing overhead at runtime
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/starship.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/zoxide.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/atuin.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/direnv.zsh"
    ${pkgs.zsh}/bin/zsh -c "zcompile $out/fzf.zsh"
  '';

  # Copy a zsh plugin out of the store, apply one sed substitution to a single
  # file, and fail the build if the original pattern is no longer present (so an
  # upstream rename can never silently ship the racy `$()` form). Used for the
  # two standalone plugin patches below; the three inline patches in
  # shellInitCache stay inline because they're entangled with zcompile and
  # build-time-precomputed values.
  mkForkRacePatch = { name, src, file, sedExpr, verify }:
    pkgs.runCommand name {} ''
      cp -r ${src} $out
      chmod -R +w $out
      ${pkgs.gnused}/bin/sed -i ${lib.escapeShellArg sedExpr} "$out/${file}"

      # Verify patch applied (build fails if upstream changes the pattern).
      if ${pkgs.gnugrep}/bin/grep -qF ${lib.escapeShellArg verify} "$out/${file}"; then
        echo "ERROR: ${name} sed patch did not match — upstream changed the line" >&2
        exit 1
      fi
    '';

  # Build-time patched fast-syntax-highlighting: replaces top-level
  # `if [[ $(uname -a) = (#i)*darwin* ]]` (racy $() at source-time) with
  # `$OSTYPE = darwin*` (a parameter test, no fork). Eliminates one of
  # the largest remaining SIGCHLD-race sites at shell init.
  fixedFsh = mkForkRacePatch {
    name = "fsh-patched";
    src = pkgs.zsh-fast-syntax-highlighting;
    file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
    sedExpr = ''s|if \[\[ \$(uname -a) = (#i)\*darwin\* \]\]|if [[ $OSTYPE = darwin* ]]|'';
    verify = ''if [[ $(uname -a) = (#i)*darwin* ]]'';
  };

  # Build-time patched zsh-autosuggestions: replace `$(builtin zle -la)`
  # in _zsh_autosuggest_bind_widgets with `${(kF)widgets}` — the latter
  # reads from the `widgets` associative array (provided by zsh/parameter,
  # already loaded) without forking. The `$()` form forks a subshell to
  # capture builtin output and waits via the racy waitforpid path, which
  # on macOS 15+ wedges the shell at the first prompt.
  fixedAutosuggestions = mkForkRacePatch {
    name = "zsh-autosuggestions-patched";
    src = pkgs.zsh-autosuggestions;
    file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    sedExpr = ''s|\$(builtin zle -la)|''${(kF)widgets}|'';
    verify = ''$(builtin zle -la)'';
  };
in
{
  # ENHANCED Zsh configuration - Complete declarative shell setup
  # Includes: Auto-activation, aliases, functions, and update system

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    # Disable HM's autosuggestion — it sources the unpatched upstream copy
    # whose precmd hook contains a racy `$(builtin zle -la)`. We source
    # the build-time patched `fixedAutosuggestions` derivation manually
    # below (see initContent at mkOrder 875).
    autosuggestion.enable = false;
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

      # Disable zsh-autosuggestions' per-precmd widget rebinding.
      # By default, `_zsh_autosuggest_start` re-runs `_zsh_autosuggest_bind_widgets`
      # on every prompt — that function evaluates `$(builtin zle -la)`, which
      # forks a subshell and waits via the racy waitforpid path. On macOS 15+
      # that race wedges the shell at the prompt. With MANUAL_REBIND, the
      # rebind happens once at first precmd then the hook removes itself.
      ZSH_AUTOSUGGEST_MANUAL_REBIND = "1";
    };

    # COMPLETE Shell aliases - merged from all sources
    shellAliases = {
      # ============================================
      # SYSTEM & CONFIGURATION
      # ============================================
      c = "clear";

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
      # zshrc — managed in ~/.zshrc.local (no rebuild needed)
      zshsec = "code ${homeDir}/.zsh_secrets";

      # Nix-Darwin system management
      # Usage: nix-rebuild [options]
      # See: scripts/maintenance/rebuild.sh
      nix-rebuild = "${nixDarwinDir}/scripts/maintenance/rebuild.sh";
      nix-rebuild-skip-checks = "${nixDarwinDir}/scripts/maintenance/rebuild.sh --skip-checks";
      nix-rebuild-debug = "${nixDarwinDir}/scripts/maintenance/rebuild.sh --debug";
      # Open the most recent rebuild log in $PAGER (rotated to last 20).
      nix-rebuild-log = "${nixDarwinDir}/scripts/maintenance/nix-rebuild-log.sh";

      # Check configuration without building (no shell restart needed)
      nix-check = "nix flake check ${nixDarwinDir}";

      # ── Security scanning ──────────────────────────────────────────────
      # secnow ("x"): CVE scan of what's INSTALLED now (live system closure).
      #   secnow --explain  → show which top-level package pulls each CVE in.
      # secnext ("y"): scan what WOULD be installed before switching (builds the
      #   candidate, shows the delta, prompts on findings).
      #   secnext --fast    → eval-only pre-download peek (build-closure superset).
      #   secnext --no-cache → force a fresh scan, ignoring the verdict cache.
      # The same secnext gate runs automatically before nix-rebuild / update-nix
      # (bypass: nix-rebuild-skip-checks, or SKIP_SECURITY_PREFLIGHT=1). Clean and
      # explicitly-accepted findings verdicts are cached ~7d keyed by candidate
      # closure, so a rebuild of an unchanged closure skips the ~50–80s vulnix
      # scan (SEC_PREFLIGHT_CACHE_TTL_DAYS overrides the TTL).
      secnow = "security-scan";  # packaged tool (bundles vulnix); see nix-config/pkgs/security-scan
      secnext = "${nixDarwinDir}/scripts/maintenance/security-preflight.sh";

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
      nh-switch = "(cd ${nixDarwinDir} && nh darwin switch -H ${machineId} .)";
      nh-build = "(cd ${nixDarwinDir} && nh darwin build -H ${machineId} .)";
      nh-clean = "nh clean all --keep 5";          # Smart cleanup, keep 5 generations
      nh-clean-aggressive = "nh clean all --keep 2";  # Aggressive cleanup
      nh-search = "nh search";                     # Search nixpkgs

      # Force home-manager regeneration (workaround for cache bug)
      # See: claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md
      # Logic extracted to a script (repo convention); restarts shell on success.
      nix-rebuild-hm-force = "${nixDarwinDir}/scripts/maintenance/rebuild-hm-force.sh --with-system";
      nix-home-rebuild-force = "${nixDarwinDir}/scripts/maintenance/rebuild-hm-force.sh";

      # Scaffold new machine configuration from template
      nix-scaffold-machine = "${nixDarwinDir}/scripts/setup/scaffold-new-machine.sh";

      # Secret management (Secret Management v2.0)
      # Tier 3: domain-action pattern for namespace grouping (secrets-*)
      secrets-rescan = "${nixDarwinDir}/scripts/secrets/rescan-secrets.sh";
      secrets-edit = "${nixDarwinDir}/scripts/secrets/edit-secrets.sh";
      secrets-view = "${nixDarwinDir}/scripts/secrets/view-secrets.sh";
      secrets-backup = "${nixDarwinDir}/scripts/secrets/backup-secrets.sh";
      secrets-audit = "${nixDarwinDir}/scripts/secrets/audit-secrets.sh";
      secrets-status = "${nixDarwinDir}/scripts/secrets/status-secrets.sh";
      secrets-deploy = "${nixDarwinDir}/scripts/secrets/deploy-secrets.sh";

      # Maintenance & validation
      nix-verify-backups = "${nixDarwinDir}/scripts/maintenance/verify-backups.sh";
      nix-brew-audit = "${nixDarwinDir}/scripts/maintenance/brew-nix-audit.sh";

      # ============================================
      # WORKFLOW HELPERS
      # ============================================
      # Note: Personal app launchers (ff, cld, gpt, cursor, etc.) moved to personal.nix
      # to prevent them from appearing on work machine where Homebrew is disabled
      # Claude Code aliases moved to ~/.zshrc.local (no rebuild needed for changes)
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

      # grep/find intentionally NOT aliased to rg/fd — those take different
      # syntax (not just different output), so overriding them silently breaks
      # `grep -rn` / `find . -name`. Use rg/fd by name; `rgi` is the short rg.
      rgi = "rg -i";

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
      # PYTHON (UV)
      # ============================================
      py = "python";
      ipy = "ipython";
      jl = "jupyter lab";
      jn = "jupyter notebook";

      # UV commands
      # uv-new/uv-venv/activate removed — richer same-named functions in
      # python.zsh (cd into project dirs, chain venv+activate, check both
      # .venv/venv) were shadowed by these aliases. Removing un-shadows them.
      "uv-add" = "uv add";
      "uv-sync" = "uv sync";
      "uv-run" = "uv run";

      # Linting & Formatting (py- namespaced: these are Python/ruff-only, so a
      # bare `lint` shouldn't run ruff inside a JS/Go repo)
      "py-lint" = "ruff check .";
      "py-format" = "ruff format .";
      "py-lint-fix" = "ruff check --fix .";

      # ============================================
      # AWS
      # ============================================
      # awsp / awswho defined as functions in aws-helpers.nix
      # (awsp as an alias was broken: `awsp foo` set an empty profile and ran `foo`).

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
      # `clean`/`cleanup` are umbrella dispatcher functions (dispatch.zsh),
      # not aliases — an alias here would shadow the function of the same
      # name. See dispatch.zsh for subcommands (quick/safe/dev/aggressive/...).
      #
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
      # ZPROF GATING — opt-in startup profiling
      # Run `ZPROF=1 zsh -i -c exit` to print a flat profile of init.
      # No overhead when unset (zsh/zprof module not loaded).
      (lib.mkOrder 1 ''
        if [[ -n "''${ZPROF:-}" ]]; then
          zmodload zsh/zprof
        fi
      '')

      # PERFORMANCE OPTIMIZATIONS (The <0.5s Goal)
      # Hybrid Approach: Static generation of init scripts
      # Moves ~20ms of processing from shell-start to build-time
      (lib.mkOrder 40 ''
        # DARK/LIGHT MODE DETECTION FOR STARSHIP
        #
        # IMPORTANT: This block must NOT contain any $(...) command substitutions
        # at top level. On macOS 15+, $() in zshrc can race with SIGCHLD and hang
        # forever — child exits before zsh enters sigsuspend, signal lost, shell
        # blocked indefinitely. The user reproduced this with `$(defaults read)`
        # and `$(atuin uuid)` triggering identical hangs at different lines.
        #
        # Strategy: cache the palette decision in a file, refresh once per hour
        # via a SEPARATE non-blocking process. Shell init only reads the file
        # (no fork). On cache miss, default to mocha (dark) — user can correct
        # by running the refresh once, or it'll fix itself on next refresh.
        if [[ -L "$HOME/.config/starship.toml" ]]; then
          _palette_cache="$HOME/.cache/starship/.palette"
          _writable_starship="$HOME/.cache/starship/starship.toml"
          # Read palette from cache (pure builtin, no fork)
          if [[ -r "$_palette_cache" ]]; then
            read -r _palette < "$_palette_cache"
          else
            # Best-effort default; refresh runs below to fix it
            _palette="catppuccin_mocha"
          fi
          # Read cache palette into config if cache file exists with a value.
          if [[ -n "''${_palette:-}" ]] && [[ -f "$_writable_starship" ]]; then
            export STARSHIP_CONFIG="$_writable_starship"
          fi
          # Background refresh — disowned, fires once per hour at most.
          # No `wait` ever, so SIGCHLD race can't bite zsh init.
          _now=$EPOCHSECONDS
          _last=0
          [[ -r "$_palette_cache.mtime" ]] && read -r _last < "$_palette_cache.mtime"
          if (( _now - _last > 3600 )); then
            ( "${nixDarwinDir}/scripts/maintenance/refresh-starship-palette.sh" >/dev/null 2>&1 & ) &!
          fi
          unset _palette_cache _writable_starship _palette _now _last
        fi
      '')

      (lib.mkOrder 50 ''
        # STATICALLY GENERATED INTEGRATIONS
        # Replaces "eval $(tool init zsh)" to save runtime overhead.
        # Generated at build time via pkgs.runCommand.

        # Pre-populate ATUIN_SESSION + ATUIN_SHLVL so atuin.zsh skips the
        # `export ATUIN_SESSION=$(atuin uuid)` fork on every shell start.
        #
        # Why: that $() can race with SIGCHLD on macOS — child exits, sigsuspend
        # waits forever for a signal that already arrived, hanging shell init
        # before the welcome message ever prints. Reproduced after
        # `exec zsh` (= `respin`) where SHLVL changes (parent=1 → child=2)
        # and atuin.zsh's `ATUIN_SHLVL != $SHLVL` branch fires the fork.
        # Pure-builtin substitute below uses no fork at all.
        zmodload zsh/datetime 2>/dev/null
        if [[ -z "''${ATUIN_SESSION:-}" ]]; then
          export ATUIN_SESSION="''${EPOCHREALTIME//.}-$$"
        fi
        export ATUIN_SHLVL=$SHLVL

        source ${shellInitCache}/starship.zsh
        source ${shellInitCache}/zoxide.zsh
        source ${shellInitCache}/atuin.zsh
        source ${shellInitCache}/direnv.zsh

        # SIGCHLD-SAFE ATUIN PREEXEC OVERRIDE
        #
        # Upstream atuin.zsh does:
        #   id=$(atuin history start -- "$1" 2>/dev/null)
        # which uses zsh's racy command-substitution wait path for every
        # submitted command. Keep the same behavior, but capture through a
        # per-pid file and read it with the builtin `read`.
        typeset -g __ATUIN_BIN="${pkgs.atuin}/bin/atuin"
        typeset -g __ATUIN_HISTORY_START_FILE="''${TMPDIR:-/tmp}/.atuin-history-start.$$"

        _atuin_preexec() {
          local _cmd="$1"
          if "$__ATUIN_BIN" history start -- "$_cmd" > "$__ATUIN_HISTORY_START_FILE" 2>/dev/null; then
            if [[ -s "$__ATUIN_HISTORY_START_FILE" ]]; then
              read -r ATUIN_HISTORY_ID < "$__ATUIN_HISTORY_START_FILE"
            else
              ATUIN_HISTORY_ID=""
            fi
          else
            ATUIN_HISTORY_ID=""
          fi
          export ATUIN_HISTORY_ID
          __atuin_preexec_time=''${EPOCHREALTIME-}
        }

        _atuin_cleanup_history_start() {
          [[ -f "$__ATUIN_HISTORY_START_FILE" ]] && /bin/rm -f "$__ATUIN_HISTORY_START_FILE"
        }
        autoload -Uz add-zsh-hook 2>/dev/null && \
          add-zsh-hook zshexit _atuin_cleanup_history_start

        # SIGCHLD-SAFE STARSHIP PROMPT
        #
        # The default starship init does:
        #   setopt promptsubst
        #   PROMPT='$(starship prompt ...)'
        #   RPROMPT='$(starship prompt --right ...)'
        # That $() runs on EVERY prompt redraw — typing chars, mode changes,
        # widget redraws, autosuggest refreshes. Each invocation goes through
        # zsh's getoutput → waitforpid → signal_suspend, which races SIGCHLD on
        # macOS 15+: child exits before parent enters sigsuspend, signal lost,
        # shell hangs forever in __sigsuspend.
        #
        # Fix: render the prompts in precmd via foreground redirect (safe
        # waitjobs path), stash in parameters, reference those in PROMPT.
        # `$(<file)` reads the file without forking, so prompt-subst stays
        # fork-free on every redraw. Vi-mode rerender hooks into
        # zle-keymap-select.
        typeset -g __STARSHIP_BIN="${pkgs.starship}/bin/starship"
        typeset -g __STARSHIP_LEFT_FILE="$HOME/.cache/starship/.left.$$"
        typeset -g __STARSHIP_RIGHT_FILE="$HOME/.cache/starship/.right.$$"
        typeset -g STARSHIP_LEFT="" STARSHIP_RIGHT=""
        # Set once the first precmd render has run — gates the chpwd hook below
        # so a `cd` during shell init can't fork starship inside the SIGCHLD
        # window before the first prompt.
        typeset -g __STARSHIP_READY=
        # Gate mkdir to avoid fork on every shell init — `/bin/mkdir`
        # forks an external command and waits via waitjobs, which on
        # macOS 15+ races with SIGCHLD. Once the dir exists, the test
        # short-circuits and no fork happens.
        [[ -d "$HOME/.cache/starship" ]] || /bin/mkdir -p "$HOME/.cache/starship"

        __starship_render() {
          "$__STARSHIP_BIN" prompt \
            --terminal-width="$COLUMNS" \
            --keymap="''${KEYMAP:-}" \
            --status="''${STARSHIP_CMD_STATUS:-}" \
            --pipestatus="''${STARSHIP_PIPE_STATUS[*]:-}" \
            --cmd-duration="''${STARSHIP_DURATION:-}" \
            --jobs="''${STARSHIP_JOBS_COUNT:-0}" \
            > "$__STARSHIP_LEFT_FILE" 2>/dev/null
          STARSHIP_LEFT="$(<$__STARSHIP_LEFT_FILE)"
          "$__STARSHIP_BIN" prompt --right \
            --terminal-width="$COLUMNS" \
            --keymap="''${KEYMAP:-}" \
            --status="''${STARSHIP_CMD_STATUS:-}" \
            --pipestatus="''${STARSHIP_PIPE_STATUS[*]:-}" \
            --cmd-duration="''${STARSHIP_DURATION:-}" \
            --jobs="''${STARSHIP_JOBS_COUNT:-0}" \
            > "$__STARSHIP_RIGHT_FILE" 2>/dev/null
          STARSHIP_RIGHT="$(<$__STARSHIP_RIGHT_FILE)"
          __STARSHIP_READY=1
        }

        # NOTE: do NOT call __starship_render at init time. The two
        # foreground starship invocations (`starship prompt > file`)
        # use zsh's waitjobs path which on macOS 15+ ALSO races with
        # SIGCHLD and can wedge `exec zsh`. The precmd hook below
        # fires before the first prompt displays, so STARSHIP_LEFT
        # and STARSHIP_RIGHT will be populated in time.
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd __starship_render

        # Replace PROMPT/RPROMPT — pure parameter expansion, no fork.
        # Use $VAR (not ''${VAR}) to dodge Nix indented-string escape pitfalls.
        PROMPT='$STARSHIP_LEFT'
        RPROMPT='$STARSHIP_RIGHT'

        # Re-render and redraw when vi keymap changes (insert <-> normal).
        __starship_keymap_select() {
          __starship_render
          zle reset-prompt
        }
        zle -N zle-keymap-select __starship_keymap_select

        # Re-render on directory change made from inside a ZLE widget.
        #
        # Widgets that cd then redraw via `zle reset-prompt` — fzf-cd-widget
        # (Alt-C), zoxide's `zi` — never fire precmd, so the frozen
        # STARSHIP_LEFT/RIGHT would still show the OLD directory until the next
        # real command. Refresh them here so the widget's own reset-prompt (and
        # ours) draws the current dir. Typed `cd` is already covered by precmd,
        # so this only acts inside a widget ($WIDGET set) — no double render on
        # ordinary cd. Gated on __STARSHIP_READY to stay clear of the init
        # SIGCHLD window.
        __starship_chpwd() {
          [[ -n "$__STARSHIP_READY" && -n "''${WIDGET:-}" ]] || return
          __starship_render
          zle reset-prompt 2>/dev/null
        }
        add-zsh-hook chpwd __starship_chpwd

        # Clean up render files on shell exit.
        __starship_cleanup() {
          /bin/rm -f "$__STARSHIP_LEFT_FILE" "$__STARSHIP_RIGHT_FILE" 2>/dev/null
        }
        add-zsh-hook zshexit __starship_cleanup

        # SIGCHLD-SAFE _direnv_hook OVERRIDE
        #
        # The default direnv hook is:
        #   eval "$(direnv export zsh)"
        # That $() goes through zsh's getoutput → waitforpid → signal_suspend
        # path. On macOS 15+ that path races with SIGCHLD: a fast child exits
        # before the parent enters sigsuspend, the signal is lost, the shell
        # blocks forever in __sigsuspend.
        #
        # This override redirects to a tmp file and sources it. Foreground
        # commands with `>` redirect use waitjobs (the job-control path), not
        # waitforpid, so the race doesn't apply.
        #
        # Same per-pid temp file is reused across hook calls (cd events fire
        # this many times) — no $(mktemp) fork, no allocation thrash.
        typeset -g __DIRENV_BIN="${pkgs.direnv}/bin/direnv"
        typeset -g __DIRENV_EXPORT_FILE="$HOME/.cache/direnv/.export.$$.zsh"
        # Gate mkdir to avoid SIGCHLD-race fork on every shell init.
        [[ -d "$HOME/.cache/direnv" ]] || /bin/mkdir -p "$HOME/.cache/direnv"

        # First-precmd skip: when a shell starts, the parent's direnv state
        # is already correct (env vars inherited). The first call would
        # fork direnv just to confirm "nothing changed" — but that fork
        # uses zsh's waitjobs path which races with SIGCHLD on macOS 15+
        # and can wedge the shell at the first prompt. Skip the first call;
        # subsequent calls (after cd or new prompts) work normally.
        typeset -g __DIRENV_HOOK_PRIMED=
        _direnv_hook() {
          if [[ -z "$__DIRENV_HOOK_PRIMED" ]]; then
            __DIRENV_HOOK_PRIMED=1
            return 0
          fi
          trap -- "" SIGINT
          if "$__DIRENV_BIN" export zsh > "$__DIRENV_EXPORT_FILE" 2>/dev/null; then
            [[ -s "$__DIRENV_EXPORT_FILE" ]] && source "$__DIRENV_EXPORT_FILE"
          fi
          trap - SIGINT
        }

        # Clean up the per-pid export file on shell exit.
        _direnv_cleanup_export() {
          [[ -f "$__DIRENV_EXPORT_FILE" ]] && /bin/rm -f "$__DIRENV_EXPORT_FILE"
        }
        autoload -Uz add-zsh-hook 2>/dev/null && \
          add-zsh-hook zshexit _direnv_cleanup_export
      '')

      (lib.mkOrder 100 ''
        # 1. FASTER COMPLETION INIT (Bypass compaudit on secure Nix paths)
        # We prefer speed (compinit -C) over checking every file on every startup.
        # On a Nix system, paths are immutable, so this is very safe.
        # Home Manager appends profile completion paths later in .zshrc, but
        # compinit snapshots fpath when it runs. Seed those paths first so Tab
        # completion sees Nix package completions.
        typeset -U path cdpath fpath manpath
        for profile in ''${(z)NIX_PROFILES}; do
          fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done

        autoload -Uz compinit
        ZCOMPDUMP="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
        # Use zsh head modifier (no fork) instead of dirname — see SIGCHLD
        # race notes near the dark/light block above. Gate with -d to avoid
        # the mkdir external-fork on every shell init (idempotent stat).
        [[ -d "''${ZCOMPDUMP:h}" ]] || mkdir -p "''${ZCOMPDUMP:h}"
        
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
      # Local testing overrides (gitignored) — sourced after main secrets so
      # they win. Lets `respin` pick up secrets-local changes without a
      # dedicated secrets-reload command.
      [ -f ~/.zsh_secrets.local ] && source ~/.zsh_secrets.local

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
      [[ -d "$TF_PLUGIN_CACHE_DIR" ]] || mkdir -p "$TF_PLUGIN_CACHE_DIR"

      # ============================================
      # WELCOME MESSAGE (cached — avoids subprocess calls per shell)
      # ============================================
      # IMPORTANT: zero $(...) at top level — see SIGCHLD race notes near the
      # dark/light block. mtime check uses zstat builtin (no fork). Refresh on
      # cache miss runs in a backgrounded subshell with no wait.
      if [ "$TERM_PROGRAM" != "vscode" ]; then
        _wf="$HOME/.cache/nix-darwin/welcome.$MACHINE_MODE"
        _wf_mtime=0
        zmodload -F zsh/stat b:zstat 2>/dev/null && \
          zstat -A _wf_stat +mtime "$_wf" 2>/dev/null && \
          _wf_mtime=$_wf_stat[1]
        # Refresh if missing or older than 24h.
        if [[ ! -s "$_wf" ]] || (( EPOCHSECONDS - _wf_mtime > 86400 )); then
          # Disowned background refresh — no wait, no SIGCHLD risk.
          ( "${nixDarwinDir}/scripts/maintenance/refresh-welcome.sh" "$_wf" "$MACHINE_MODE" >/dev/null 2>&1 & ) &!
        fi
        # Print the (possibly stale) cache; refresh applies on next shell start.
        # Use zsh's `$(<file)` special form (no fork) + `print -r --` (builtin)
        # instead of `/bin/cat` — the cat fork triggers waitjobs which on
        # macOS 15+ can race with SIGCHLD and wedge `exec zsh`.
        [[ -s "$_wf" ]] && print -r -- "$(<$_wf)"
        unset _wf _wf_mtime _wf_stat
      fi

      # ============================================
      # LOAD MODULAR FUNCTION FILES
      # ============================================
      # Functions extracted to separate files for maintainability. ALL are
      # lazy-loaded: a thin wrapper sources the file on first call, so the body
      # parses only when used. This defers ~1040 lines of rarely-used function
      # parsing off the interactive-init path (parse savings are modest, a few
      # ms; the main value is consistency + deferring source-time work like the
      # aws-completion compdef). See: functions/README.md for documentation.

      # Lazy-load: core utility functions (203 lines, used occasionally).
      # `als` is an alias to find-alias (matches core.zsh's own alias) so it
      # routes through the lazy find-alias wrapper without a separate stub.
      __lazy_load_core() {
        unfunction mkcd find-alias zsh-profile path-add backup histgrep \
          kill-port gcl newproj killport sysinfo warn confirm risky critical \
          note __lazy_load_core 2>/dev/null
        source ${lazyCore}
      }
      function mkcd() { __lazy_load_core; mkcd "$@"; }
      function find-alias() { __lazy_load_core; find-alias "$@"; }
      function zsh-profile() { __lazy_load_core; zsh-profile "$@"; }
      function path-add() { __lazy_load_core; path-add "$@"; }
      function backup() { __lazy_load_core; backup "$@"; }
      function histgrep() { __lazy_load_core; histgrep "$@"; }
      function kill-port() { __lazy_load_core; kill-port "$@"; }
      function gcl() { __lazy_load_core; gcl "$@"; }
      function newproj() { __lazy_load_core; newproj "$@"; }
      function killport() { __lazy_load_core; killport "$@"; }
      function sysinfo() { __lazy_load_core; sysinfo "$@"; }
      function warn() { __lazy_load_core; warn "$@"; }
      function confirm() { __lazy_load_core; confirm "$@"; }
      function risky() { __lazy_load_core; risky "$@"; }
      function critical() { __lazy_load_core; critical "$@"; }
      function note() { __lazy_load_core; note "$@"; }
      alias als="find-alias"

      # Lazy-load: Python/uv helpers (67 lines, used occasionally).
      __lazy_load_python() {
        unfunction uv-new uv-venv activate pyenv-info __lazy_load_python 2>/dev/null
        source ${lazyPython}
      }
      function uv-new() { __lazy_load_python; uv-new "$@"; }
      function uv-venv() { __lazy_load_python; uv-venv "$@"; }
      function activate() { __lazy_load_python; activate "$@"; }
      function pyenv-info() { __lazy_load_python; pyenv-info "$@"; }

      # Lazy-load: AWS tab-completion body (88 lines) — only needed on first
      # tab of awsuse/awslogin. compdef runs inline (it must, to register at
      # init); the completion function is stubbed to source its body on first
      # invocation, so _aws_helper_completion parses only when completion fires.
      _aws_helper_completion() {
        unfunction _aws_helper_completion 2>/dev/null
        source ${lazyAwsCompletion}
        _aws_helper_completion "$@"
      }
      compdef _aws_helper_completion awsuse awslogin

      # Lazy-load: cleanup functions (377 lines, used occasionally)
      __lazy_load_cleanup() {
        unfunction cleanup-safe cleanup-quick cleanup-standard cleanup-dev \
          cleanup-aggressive cleanup-all cleanup-nix cleanup-docker cleanup-python \
          __lazy_load_cleanup 2>/dev/null
        source ${lazyCleanup}
      }
      function cleanup-safe() { __lazy_load_cleanup; cleanup-safe "$@"; }
      function cleanup-quick() { __lazy_load_cleanup; cleanup-quick "$@"; }
      function cleanup-standard() { __lazy_load_cleanup; cleanup-standard "$@"; }
      # cleanup() stub omitted — alias `cleanup = "cleanup-standard"` handles it
      function cleanup-dev() { __lazy_load_cleanup; cleanup-dev "$@"; }
      function cleanup-aggressive() { __lazy_load_cleanup; cleanup-aggressive "$@"; }
      function cleanup-all() { __lazy_load_cleanup; cleanup-all "$@"; }
      function cleanup-nix() { __lazy_load_cleanup; cleanup-nix "$@"; }
      function cleanup-docker() { __lazy_load_cleanup; cleanup-docker "$@"; }
      function cleanup-python() { __lazy_load_cleanup; cleanup-python "$@"; }

      # Lazy-load: update functions (315 lines, used weekly)
      __lazy_load_update() {
        unfunction update-nix update-brew update-mamba update-vscode update-mas \
          update-dev update-system update-all __lazy_load_update 2>/dev/null
        source ${lazyUpdate}
      }
      function update-nix() { __lazy_load_update; update-nix "$@"; }
      function update-brew() { __lazy_load_update; update-brew "$@"; }
      function update-mamba() { __lazy_load_update; update-mamba "$@"; }
      function update-vscode() { __lazy_load_update; update-vscode "$@"; }
      function update-mas() { __lazy_load_update; update-mas "$@"; }
      function update-dev() { __lazy_load_update; update-dev "$@"; }
      function update-system() { __lazy_load_update; update-system "$@"; }
      function update-all() { __lazy_load_update; update-all "$@"; }

      # Lazy-load: umbrella dispatchers (update/clean/secrets/status/fix +
      # back-compat cleanup). Routing layer only — the bodies call the
      # already-lazy functions/scripts above, so this defers just the
      # dispatch.zsh parse cost, not the work it routes to.
      __lazy_load_dispatch() {
        unfunction update clean cleanup secrets status fix __lazy_load_dispatch 2>/dev/null
        source ${lazyDispatch}
      }
      function update() { __lazy_load_dispatch; update "$@"; }
      function clean() { __lazy_load_dispatch; clean "$@"; }
      function cleanup() { __lazy_load_dispatch; cleanup "$@"; }
      function secrets() { __lazy_load_dispatch; secrets "$@"; }
      function status() { __lazy_load_dispatch; status "$@"; }
      function fix() { __lazy_load_dispatch; fix "$@"; }

      # Lazy-load: workspace backup/restore — the only functions this module defines.
      # (edit-secrets/secrets-status/etc. were stubbed here previously but never defined
      # in credentials-mgmt.zsh — they died with the old warning system. secrets-status
      # is now a shell alias to scripts/secrets/status-secrets.sh; see aliases above.
      # sync-workspace was removed — the script it called doesn't exist.)
      __lazy_load_credentials() {
        unfunction backup-workspace restore-workspace \
          __lazy_load_credentials 2>/dev/null
        source ${lazyCredentials}
      }
      function backup-workspace() { __lazy_load_credentials; backup-workspace "$@"; }
      function restore-workspace() { __lazy_load_credentials; restore-workspace "$@"; }
      # nix-health() stub omitted — alias `nix-health` points to health-check.sh script

      # ============================================
      # HOT RELOAD FUNCTIONS
      # ============================================
      # Quick reload of secrets and environment without rebuild
      # Functions: respin, secrets-local, zsh-local

      # Full shell process restart. Picks up everything in one shot: zshenv,
      # zshrc, ~/.zsh_secrets, ~/.zsh_secrets.local, and ~/.zshrc.local — all
      # sourced automatically as part of normal init (see SOURCE SECRETS above).
      # Replaces the old separate reload / restart / secrets-reload aliases.
      function respin() {
        printf '\033[90m respinning: zshenv → zshrc → secrets (+ .local) → zshrc.local\033[0m\n'
        exec zsh
      }

      ${myLib.reload.mkAllHotReloadFunctions}

      alias zz="z -"
      ''
      
      (lib.mkOrder 875 ''
        # ZSH-AUTOSUGGESTIONS (build-time patched)
        # HM's `programs.zsh.autosuggestion.enable` sources the upstream
        # copy whose precmd hook (`_zsh_autosuggest_bind_widgets`) evaluates
        # `$(builtin zle -la)` — that $() forks and waits via the racy
        # waitforpid path on macOS 15+. Our patched copy replaces it with
        # `''${(k)widgets}` (parameter expansion, no fork).
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        source ${fixedAutosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      '')

      (lib.mkOrder 1500 ''
        # FAST SYNTAX HIGHLIGHTING
        # Replaces standard zsh-syntax-highlighting (saves ~700ms)
        # Sourced at order 1500 — strictly after the default-1000 blocks (fzf,
        # bindkey overrides, function definitions) so FSH wraps every widget
        # those blocks bind. Order 900 placed it BEFORE default blocks, which
        # left fzf and option+arrow bindings without highlighting wrappers.
        # Uses build-time patched copy (fixedFsh) to remove racy
        # `$(uname -a)` command-substitution at source time — the
        # upstream version triggers zsh's SIGCHLD waitforpid race on
        # macOS 15+ and wedges the shell during `exec zsh`.
        source ${fixedFsh}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
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

      # Debug instrumentation for precmd / preexec / chpwd hooks. Opt-in via
      # either:
      #   - ZSH_DEBUG_PRECMD=1 in the env  (one-shot)
      #   - touch ~/.cache/zsh-debug-precmd  (persistent across all new shells)
      #
      # Each hook is wrapped with a timestamped logger that appends ENTER/EXIT
      # lines to a per-pid log file. If the shell hangs, the last ENTER line
      # without a matching EXIT names the offending hook.
      #
      # Why this exists: the SIGCHLD race in zsh's waitforpid bites any $() in
      # the hot path. We've eliminated all top-level $() in init blocks, but
      # third-party precmd hooks (direnv, starship, atuin, autosuggestions) can
      # still fork at prompt time. This instrumentation tells us which one.
      #
      # Cost when enabled: ~5ms per shell start (writes to tmpfs).
      # Cost when disabled: zero (single env-var test).
      (lib.mkOrder 9000 ''
        if [[ -n "''${ZSH_DEBUG_PRECMD:-}" ]] || [[ -f "$HOME/.cache/zsh-debug-precmd" ]]; then
          zmodload zsh/datetime 2>/dev/null
          export _ZSH_DEBUG_LOG="''${TMPDIR:-/tmp}/zsh-precmd-debug.$$.log"
          : > "$_ZSH_DEBUG_LOG"
          print -- "=== zsh debug pid=$$ tty=$TTY started $EPOCHREALTIME ===" >> "$_ZSH_DEBUG_LOG"
          print -- "precmd_functions:  $precmd_functions" >> "$_ZSH_DEBUG_LOG"
          print -- "preexec_functions: $preexec_functions" >> "$_ZSH_DEBUG_LOG"
          print -- "chpwd_functions:   $chpwd_functions" >> "$_ZSH_DEBUG_LOG"
          print -- "log: $_ZSH_DEBUG_LOG" >&2

          __zsh_wrap_hooks() {
            local label=$1; shift
            local hook
            for hook in "$@"; do
              # Skip wrappers, missing functions, already-wrapped names.
              [[ "$hook" == __dbg_orig_* ]] && continue
              (( ''${+functions[$hook]} )) || continue
              if (( ''${+functions[__dbg_orig_$hook]} )); then
                unfunction "__dbg_orig_$hook"
              fi
              functions -c "$hook" "__dbg_orig_$hook"
              eval "
                $hook() {
                  print -- \"[\$EPOCHREALTIME] ENTER ''${label}::$hook\" >> \"\$_ZSH_DEBUG_LOG\"
                  __dbg_orig_$hook \"\$@\"
                  local _rc=\$?
                  print -- \"[\$EPOCHREALTIME] EXIT  ''${label}::$hook rc=\$_rc\" >> \"\$_ZSH_DEBUG_LOG\"
                  return \$_rc
                }
              "
            done
          }

          __zsh_wrap_hooks precmd  "''${precmd_functions[@]}"
          __zsh_wrap_hooks preexec "''${preexec_functions[@]}"
          __zsh_wrap_hooks chpwd   "''${chpwd_functions[@]}"
          unfunction __zsh_wrap_hooks

          print -- "[debug] hooks instrumented; tail -f $_ZSH_DEBUG_LOG to watch" >&2
        fi
      '')

      # Source local overrides (not Nix-managed, no rebuild needed)
      # __ensure_zshrc_local creates the file with default aliases on first shell start
      (lib.mkOrder 9999 ''
        __ensure_zshrc_local
        [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

        # Print zprof report at end of init (opt-in via env var, see top of file).
        if [[ -n "''${ZPROF:-}" ]]; then
          zprof
        fi
      '')
    ];
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

  # Patch the HM-emitted history block to remove a SIGCHLD-racy
  # `mkdir -p "$(dirname "$HISTFILE")"` at zshrc top-level. The $()
  # forks `dirname`, which on macOS 15+ can race with zsh's waitforpid
  # path and wedge the shell during `exec zsh`. We replace it with a
  # zsh `:h` head-modifier (parameter expansion, no fork).
  #
  # Reads `config.programs.zsh.initContent` (the merged string) and
  # overrides `home.file.".zshrc".text` with mkForce — no circularity
  # since the source is initContent, not the file's own text.
  home.file.".zshrc".text = lib.mkForce (
    builtins.replaceStrings
      [ ''mkdir -p "$(dirname "$HISTFILE")"'' ]
      [ ''[[ -d "''${HISTFILE:h}" ]] || /bin/mkdir -p "''${HISTFILE:h}"'' ]
      config.programs.zsh.initContent
  );
}
