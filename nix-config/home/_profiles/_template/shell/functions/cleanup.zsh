# cleanup.zsh
# System cleanup functions - tiered approach
# Extracted from zsh.nix for maintainability

# ============================================
# CLEANUP HELPERS
# ============================================

# Get disk space
__cleanup_get_disk_space() {
  df -h / | tail -n1 | awk '{print $3}'
}

# Log to cleanup history
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

# Confirm risky operation
__cleanup_confirm() {
  local operation="$1"
  local description="$2"
  local risk="$3"
  local yes_flag="$4"

  [[ "$yes_flag" == "true" ]] && return 0

  echo ""
  if confirm "Continue with $operation?"; then
    return 0
  else
    return 1
  fi
}

# ============================================
# TIER 1: CLEANUP-SAFE (Conservative)
# ============================================
function cleanup-safe() {
  local dry_run=false

  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --help|-h)
        echo "Usage: cleanup-safe [OPTIONS]"
        echo "Conservative cleanup (safe, no confirmations)"
        echo "Options: --dry-run, --help"
        return 0 ;;
    esac
  done

  echo ""
  echo -e "\033[1m\033[36m🛡️  SAFE CLEANUP\033[0m"
  echo "============================================"
  [[ "$dry_run" == "true" ]] && echo -e "\033[33mDRY RUN MODE\033[0m"

  local start_time=$(date +%s)
  local disk_before=$(__cleanup_get_disk_space)
  __cleanup_log "safe" "Starting (dry_run=$dry_run)"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would empty Trash, clean temp files, Nix GC"
  else
    rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
    nix-env --delete-generations +5 2>/dev/null || true
    sudo nix-env --delete-generations +5 2>/dev/null || true
    nix-collect-garbage -d &>/dev/null
    command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null
    echo "✅ Safe cleanup completed"
  fi

  local disk_after=$(__cleanup_get_disk_space)
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ Done! Disk: $disk_before → $disk_after (${duration}s)"
  __cleanup_log "safe" "Completed in ${duration}s"
}

# ============================================
# TIER 2: CLEANUP-QUICK (Fast daily)
# ============================================
function cleanup-quick() {
  local dry_run=false

  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --help|-h)
        echo "Usage: cleanup-quick [OPTIONS]"
        echo "Fast daily/weekly cleanup"
        echo "Options: --dry-run, --help"
        return 0 ;;
    esac
  done

  echo ""
  echo -e "\033[1m\033[36m⚡ QUICK CLEANUP\033[0m"
  echo "============================================"
  [[ "$dry_run" == "true" ]] && echo -e "\033[33mDRY RUN MODE\033[0m"

  local start_time=$(date +%s)
  local disk_before=$(__cleanup_get_disk_space)
  __cleanup_log "quick" "Starting (dry_run=$dry_run)"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would run safe + micromamba + docker + pip/npm caches"
  else
    # Safe tier
    rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
    nix-env --delete-generations +5 2>/dev/null || true
    sudo nix-env --delete-generations +5 2>/dev/null || true
    nix-collect-garbage -d &>/dev/null
    command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null

    # Quick additions
    command -v micromamba &>/dev/null && micromamba clean --yes &>/dev/null
    command -v docker &>/dev/null && docker info &>/dev/null && docker image prune -af &>/dev/null
    rm -rf ~/.cache/pip/* ~/.cache/uv/* 2>/dev/null
    command -v npm &>/dev/null && npm cache clean --force &>/dev/null
    echo "✅ Quick cleanup completed"
  fi

  local disk_after=$(__cleanup_get_disk_space)
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ Done! Disk: $disk_before → $disk_after (${duration}s)"
  __cleanup_log "quick" "Completed in ${duration}s"
}

# ============================================
# TIER 3: CLEANUP-STANDARD (Default)
# ============================================
function cleanup-standard() {
  local dry_run=false

  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --yes|-y) ;; # Ignored for standard
      --help|-h)
        echo "Usage: cleanup-standard [OPTIONS] (alias: cleanup)"
        echo "Standard cleanup - recommended for regular maintenance"
        echo "Options: --dry-run, --help"
        return 0 ;;
    esac
  done

  echo ""
  echo -e "\033[1m\033[36m🚀 STANDARD CLEANUP\033[0m"
  echo "============================================"
  [[ "$dry_run" == "true" ]] && echo -e "\033[33mDRY RUN MODE\033[0m"

  local start_time=$(date +%s)
  local disk_before=$(__cleanup_get_disk_space)
  __cleanup_log "standard" "Starting (dry_run=$dry_run)"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would run quick + Git GC + VS Code + AWS caches"
  else
    # Quick tier
    rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
    nix-env --delete-generations +5 2>/dev/null || true
    sudo nix-env --delete-generations +5 2>/dev/null || true
    nix-collect-garbage -d &>/dev/null
    command -v brew &>/dev/null && brew cleanup --prune=30 &>/dev/null
    command -v micromamba &>/dev/null && micromamba clean --yes &>/dev/null
    command -v docker &>/dev/null && docker info &>/dev/null && docker image prune -af &>/dev/null
    rm -rf ~/.cache/pip/* ~/.cache/uv/* 2>/dev/null
    command -v npm &>/dev/null && npm cache clean --force &>/dev/null

    # Standard additions
    [[ -d "$HOME/Dev" ]] && find "$HOME/Dev" -name ".git" -type d -exec sh -c 'cd "$(dirname "{}")" && git gc --quiet 2>/dev/null' \; 2>/dev/null
    [[ -d "$HOME/.aws/cli/cache" ]] && rm -rf "$HOME/.aws/cli/cache"/* 2>/dev/null
    rm -rf ~/Library/Application\ Support/Code/Cache/* ~/Library/Application\ Support/Code/CachedData/* ~/Library/Application\ Support/Code/logs/* 2>/dev/null
    rm -rf ~/Library/Logs/* 2>/dev/null
    echo "✅ Standard cleanup completed"
  fi

  local disk_after=$(__cleanup_get_disk_space)
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ Done! Disk: $disk_before → $disk_after (${duration}s)"
  __cleanup_log "standard" "Completed in ${duration}s"
}

# Default alias
function cleanup() { cleanup-standard "$@"; }

# ============================================
# TIER 4: CLEANUP-DEV (Development-focused)
# ============================================
function cleanup-dev() {
  local dry_run=false

  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --yes|-y) ;;
      --help|-h)
        echo "Usage: cleanup-dev [OPTIONS]"
        echo "Development-focused cleanup (Terraform, Jupyter, __pycache__)"
        echo "Options: --dry-run, --yes, --help"
        return 0 ;;
    esac
  done

  echo ""
  echo -e "\033[1m\033[36m🔧 DEV CLEANUP\033[0m"
  echo "============================================"
  [[ "$dry_run" == "true" ]] && echo -e "\033[33mDRY RUN MODE\033[0m"

  local start_time=$(date +%s)
  local disk_before=$(__cleanup_get_disk_space)
  __cleanup_log "dev" "Starting (dry_run=$dry_run)"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would run standard + .terraform + __pycache__ + docker builder"
  else
    # Standard tier (inline)
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

    # Dev additions
    [[ -d "$HOME/Dev" ]] && {
      find "$HOME/Dev" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
      find "$HOME/Dev" -name ".ipynb_checkpoints" -type d -exec rm -rf {} + 2>/dev/null
      find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
      find "$HOME/Dev" -name "*.pyc" -type f -delete 2>/dev/null
    }
    command -v docker &>/dev/null && docker info &>/dev/null && docker builder prune -af &>/dev/null
    echo "✅ Dev cleanup completed"
  fi

  local disk_after=$(__cleanup_get_disk_space)
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ Done! Disk: $disk_before → $disk_after (${duration}s)"
  __cleanup_log "dev" "Completed in ${duration}s"
}

# ============================================
# TIER 5: CLEANUP-AGGRESSIVE (Maximum)
# ============================================
function cleanup-aggressive() {
  local dry_run=false
  local yes_flag=false

  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --yes|-y) yes_flag=true ;;
      --help|-h)
        echo "Usage: cleanup-aggressive [OPTIONS]"
        echo "Maximum cleanup (WITH CONFIRMATIONS)"
        echo "Includes: Ollama models, HuggingFace, old downloads, Docker volumes"
        echo "Options: --dry-run, --yes, --help"
        echo "⚠️  WARNING: Destructive operation!"
        return 0 ;;
    esac
  done

  # Critical warning
  if [[ "$yes_flag" != "true" ]]; then
    echo ""
    echo "🚨 AGGRESSIVE CLEANUP - DESTRUCTIVE OPERATION"
    echo "Will permanently delete: tool caches, models, old downloads, Docker volumes"
    echo "💡 Run with --dry-run first to preview"
    echo ""
    read -r "confirmation?Type 'DELETE' to confirm: "
    [[ "$confirmation" != "DELETE" ]] && { echo "Cancelled"; return 1; }
  fi

  echo ""
  echo -e "\033[1m\033[31m🔥 AGGRESSIVE CLEANUP\033[0m"
  echo "============================================"
  [[ "$dry_run" == "true" ]] && echo -e "\033[33mDRY RUN MODE\033[0m"

  local start_time=$(date +%s)
  local disk_before=$(__cleanup_get_disk_space)
  __cleanup_log "aggressive" "Starting (dry_run=$dry_run)"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would run dev + aggressive Nix (keep 2) + models + volumes"
  else
    # Dev tier (inline)
    rm -rf ~/.Trash/* /tmp/* ~/Downloads/*.tmp ~/Downloads/*.download 2>/dev/null
    command -v brew &>/dev/null && brew cleanup --prune=all &>/dev/null
    command -v micromamba &>/dev/null && micromamba clean --all --yes &>/dev/null
    rm -rf ~/.cache/* 2>/dev/null
    [[ -d "$HOME/Dev" ]] && {
      find "$HOME/Dev" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null
      find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    }

    # Aggressive additions
    [[ -d "$HOME/.ollama/models" ]] && rm -rf "$HOME/.ollama/models"/* 2>/dev/null
    [[ -d "$HOME/.cache/huggingface" ]] && rm -rf "$HOME/.cache/huggingface"/* 2>/dev/null
    find "$HOME/Downloads" -type f -mtime +30 -delete 2>/dev/null

    # Docker complete cleanup
    command -v docker &>/dev/null && docker info &>/dev/null && docker system prune -af --volumes &>/dev/null

    # Aggressive Nix cleanup
    nix-env --delete-generations +2 2>/dev/null || true
    sudo nix-env --delete-generations +2 2>/dev/null || true
    nix-collect-garbage -d &>/dev/null
    sudo nix-collect-garbage -d &>/dev/null
    nix-store --optimize &>/dev/null
    echo "✅ Aggressive cleanup completed"
  fi

  local disk_after=$(__cleanup_get_disk_space)
  local duration=$(($(date +%s) - start_time))
  echo -e "\n✅ Done! Disk: $disk_before → $disk_after (${duration}s)"
  __cleanup_log "aggressive" "Completed in ${duration}s"
}

# Backward compatibility alias
function cleanup-all() { cleanup-aggressive "$@"; }

# ============================================
# TOOL-SPECIFIC CLEANUP (Quick access)
# ============================================

function cleanup-nix() {
  local keep="${1:-5}"
  echo "❄️  Nix cleanup (keeping last $keep generations)..."
  nix-env --delete-generations +$keep 2>/dev/null || true
  sudo nix-env --delete-generations +$keep 2>/dev/null || true
  nix-collect-garbage -d &>/dev/null
  nix-store --optimize &>/dev/null
  echo "✅ Nix cleanup complete"
}

function cleanup-docker() {
  local volumes="${1:-false}"
  if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
    echo "Docker not available"
    return 1
  fi
  echo "🐳 Docker cleanup..."
  if [[ "$volumes" == "--volumes" ]]; then
    docker system prune -af --volumes
  else
    docker system prune -af
  fi
  echo "✅ Docker cleanup complete"
}

function cleanup-python() {
  echo "🐍 Python cleanup..."
  rm -rf ~/.cache/uv/* ~/.cache/pip/* 2>/dev/null
  [[ -d "$HOME/Dev" ]] && {
    find "$HOME/Dev" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    find "$HOME/Dev" -name "*.pyc" -type f -delete 2>/dev/null
  }
  echo "✅ Python cleanup complete"
}
