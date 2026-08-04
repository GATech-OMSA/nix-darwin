# dispatch.zsh
# Umbrella dispatcher functions (update/clean/secrets/status/fix) that route
# to existing functions and scripts — a thin command-UX layer, no new logic.
# Extracted from zsh.nix for maintainability

# ============================================
# DISPATCH HELPERS
# ============================================

# Run a script under $HOME/nix-darwin/scripts/, erroring clearly if missing.
__dispatch_run_script() {
  local script="$HOME/nix-darwin/scripts/$1"
  shift
  if [[ ! -f "$script" ]]; then
    echo "✗ Script not found: $script" >&2
    return 1
  fi
  bash "$script" "$@"
}

# ============================================
# UPDATE
# ============================================
function update() {
  case "${1:-}" in
    "")
      update-all
      ;;
    help|--help|-h)
      cat <<'EOF'
Usage: update [subcommand]
  (no args)   Run update-all (Nix + Homebrew + VS Code + Mac App Store)
  nix         Update Nix Darwin only
  brew        Update Homebrew only
  vscode      Update VS Code extensions only
  mas         Update Mac App Store apps only
  dev         Quick development update (Nix + VS Code)
  system      System update (Nix + Homebrew)
EOF
      ;;
    nix) shift; update-nix "$@" ;;
    brew) shift; update-brew "$@" ;;
    vscode) shift; update-vscode "$@" ;;
    mas) shift; update-mas "$@" ;;
    dev) shift; update-dev "$@" ;;
    system) shift; update-system "$@" ;;
    *)
      echo "Unknown update subcommand: $1" >&2
      update help
      return 1
      ;;
  esac
}

# ============================================
# CLEAN
# ============================================
function clean() {
  case "${1:-}" in
    "")
      cleanup-standard
      ;;
    help|--help|-h)
      cat <<'EOF'
Usage: clean [subcommand]
  (no args)   Run cleanup-standard (recommended for regular maintenance)
  quick       Fast daily/weekly cleanup
  safe        Conservative cleanup (no confirmations)
  dev         Development-focused cleanup (Terraform, Jupyter, __pycache__)
  aggressive  Maximum cleanup (destructive, requires confirmation)
  nix         Nix generations + garbage collection only
  docker      Docker system prune only
  python      Python/uv caches only
  deep        Full interactive system-cleanup script
EOF
      ;;
    quick) shift; cleanup-quick "$@" ;;
    safe) shift; cleanup-safe "$@" ;;
    dev) shift; cleanup-dev "$@" ;;
    aggressive) shift; cleanup-aggressive "$@" ;;
    nix) shift; cleanup-nix "$@" ;;
    docker) shift; cleanup-docker "$@" ;;
    python) shift; cleanup-python "$@" ;;
    deep) shift; bash "$HOME/nix-darwin/scripts/maintenance/system-cleanup.sh" "$@" ;;
    *)
      echo "Unknown clean subcommand: $1" >&2
      clean help
      return 1
      ;;
  esac
}

# Back-compat: `cleanup` used to be the default-tier alias — now routes
# through the `clean` dispatcher instead of shadowing it.
function cleanup() { clean "$@" }

# ============================================
# SECRETS
# ============================================
function secrets() {
  case "${1:-}" in
    "")
      __dispatch_run_script secrets/status-secrets.sh
      ;;
    help|--help|-h)
      cat <<'EOF'
Usage: secrets [subcommand]
  (no args)   Show secrets status
  edit        Edit encrypted secrets.yaml
  view        View decrypted secrets
  deploy      Decrypt + deploy secrets
  rescan      Discover unmanaged secrets (read-only)
  audit       Audit secret permissions/coverage
  backup      Backup secrets
EOF
      ;;
    edit) shift; __dispatch_run_script secrets/edit-secrets.sh "$@" ;;
    view) shift; __dispatch_run_script secrets/view-secrets.sh "$@" ;;
    deploy) shift; __dispatch_run_script secrets/deploy-secrets.sh "$@" ;;
    rescan) shift; __dispatch_run_script secrets/rescan-secrets.sh "$@" ;;
    audit) shift; __dispatch_run_script secrets/audit-secrets.sh "$@" ;;
    backup) shift; __dispatch_run_script secrets/backup-secrets.sh "$@" ;;
    *)
      echo "Unknown secrets subcommand: $1" >&2
      secrets help
      return 1
      ;;
  esac
}

# ============================================
# STATUS
# ============================================
function status() {
  case "${1:-}" in
    "")
      __dispatch_run_script maintenance/health-check.sh
      ;;
    help|--help|-h)
      cat <<'EOF'
Usage: status [subcommand]
  (no args)   Run system health check
  secrets     Show secrets status
  git         Show nix-darwin repo git status
EOF
      ;;
    secrets) shift; secrets "$@" ;;
    git) shift; git -C "$HOME/nix-darwin" status --short --branch "$@" ;;
    *)
      echo "Unknown status subcommand: $1" >&2
      status help
      return 1
      ;;
  esac
}

# ============================================
# FIX
# ============================================
# No-arg default intentionally does nothing destructive — rollback/rebuild
# are too dangerous to run without an explicit subcommand.
function fix() {
  case "${1:-}" in
    "")
      cat <<'EOF'
fix: pick a subcommand — nothing runs without one.
  rollback       Roll back to the previous generation
  rebuild        Rebuild + switch (standard pre-flight checks)
  rebuild-force  Rebuild + switch, skipping pre-flight checks
EOF
      return 1
      ;;
    help|--help|-h)
      cat <<'EOF'
Usage: fix <subcommand>
  rollback       Roll back to the previous generation
  rebuild        Rebuild + switch (standard pre-flight checks)
  rebuild-force  Rebuild + switch, skipping pre-flight checks
EOF
      ;;
    rollback) shift; bash "$HOME/nix-darwin/scripts/maintenance/rebuild.sh" --rollback "$@" ;;
    rebuild) shift; bash "$HOME/nix-darwin/scripts/maintenance/rebuild.sh" "$@" ;;
    rebuild-force) shift; bash "$HOME/nix-darwin/scripts/maintenance/rebuild.sh" --skip-checks "$@" ;;
    *)
      echo "Unknown fix subcommand: $1" >&2
      fix help
      return 1
      ;;
  esac
}
