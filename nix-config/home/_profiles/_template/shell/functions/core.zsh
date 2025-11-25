# core.zsh
# Core utility functions for shell configuration
# Extracted from zsh.nix for maintainability

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Create directory and cd into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
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

# Display warning message
# Usage: warn "MESSAGE" [LEVEL]
function warn() {
  local message="$1"
  local level="${2:-WARNING}"

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

# Quick note-taking
function note() {
  if [ -z "$1" ]; then
    echo "Usage: note <your note>"
    return 1
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S'): $@" >> ~/Documents/daily-notes.md
  echo "✅ Note added to ~/Documents/daily-notes.md"
}
