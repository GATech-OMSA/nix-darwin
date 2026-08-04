#!/usr/bin/env bash

# ============================================================================
# COMPREHENSIVE SECRET AUDIT SCRIPT
# ============================================================================
#
# Performs system-wide secret scanning with privacy-conscious approach
#
# Features:
#   - Configurable scan depth (default: 3 directories)
#   - MIME type detection (text vs binary)
#   - Pattern matching for common secret formats
#   - Privacy-focused (fingerprints only for keys)
#   - Performance optimized with progress indicators
#
# Usage:
#   ./audit-secrets.sh                    # Scan with depth=3
#   ./audit-secrets.sh --depth 5          # Custom depth
#   ./audit-secrets.sh --quick            # Fast scan (depth=2)
#   ./audit-secrets.sh --dry-run          # Show what would be scanned
#

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner

# ============================================================================
# CONFIGURATION
# ============================================================================

DEFAULT_DEPTH=3
SCAN_DEPTH=$DEFAULT_DEPTH
DRY_RUN=false
OUTPUT_FILE=""
START_TIME=$(date +%s)

# File size limit (skip files larger than this)
MAX_FILE_SIZE=$((10 * 1024 * 1024))  # 10MB

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --depth)
      SCAN_DEPTH="$2"
      shift 2
      ;;
    --quick)
      SCAN_DEPTH=2
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--depth N] [--quick] [--dry-run]"
      exit 1
      ;;
  esac
done

run_banner "audit-secrets" "depth=$SCAN_DEPTH dry_run=$DRY_RUN" "$@"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info() {
  echo -e "${BLUE}[i]${NC}  $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

warning() {
  echo -e "${YELLOW}!${NC}  $*"
}

critical() {
  echo -e "${RED}✗${NC} $*"
}

banner() {
  echo ""
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}║          Secret Audit - System-Wide Scan              ║${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_step() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$*${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ============================================================================
# EXCLUSION PATTERNS
# ============================================================================

EXCLUDED_DIRS=(
  ".git"
  "node_modules"
  ".npm"
  ".cargo"
  ".rustup"
  "Library/Caches"
  "Library/Logs"
  "Library/Application Support/Google"
  "Library/Application Support/Slack"
  ".Trash"
  ".cache"
  "__pycache__"
  ".pytest_cache"
  ".venv"
  "venv"
  ".conda"
  "miniconda3"
  "anaconda3"
  ".docker"
  ".kube/cache"
  "go/pkg"
)

# Known safe patterns (config files that aren't secrets)
SAFE_PATTERNS=(
  ".*\.md$"
  ".*\.log$"
  ".*README.*"
  ".*LICENSE.*"
  ".*package-lock\.json$"
)

# Secret filename patterns
SECRET_FILENAME_PATTERNS=(
  ".*password.*"
  ".*secret.*"
  ".*token.*"
  ".*key.*"
  ".*credential.*"
  ".*\.pem$"
  ".*\.key$"
  ".*\.pkcs.*"
  ".*id_rsa.*"
  ".*id_ed25519.*"
  ".*\.p12$"
  ".*\.pfx$"
  ".env"
  ".env.local"
  ".env.production"
  ".netrc"
  ".dockercfg"
  ".docker/config.json"
)

# Secret content patterns
SECRET_CONTENT_PATTERNS=(
  "AKIA[0-9A-Z]{16}"                    # AWS Access Key
  "aws_secret_access_key.*[0-9a-zA-Z/+]{40}"  # AWS Secret
  "ghp_[0-9a-zA-Z]{36}"                 # GitHub Personal Access Token
  "gho_[0-9a-zA-Z]{36}"                 # GitHub OAuth Token
  "sk_live_[0-9a-zA-Z]{24,}"            # Stripe Live Key
  "sk_test_[0-9a-zA-Z]{24,}"            # Stripe Test Key
  "sk-[0-9a-zA-Z]{48}"                  # OpenAI API Key
  "sk-ant-[0-9a-zA-Z-]{95}"             # Anthropic API Key
  "Bearer [0-9a-zA-Z-._~+/]+=*"         # Bearer Token
  "Basic [A-Za-z0-9+/=]{20,}"           # Basic Auth
  "-----BEGIN.*PRIVATE KEY-----"        # Private Key
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

is_excluded_dir() {
  local dir="$1"
  local basename_dir=$(basename "$dir")

  for excluded in "${EXCLUDED_DIRS[@]}"; do
    if [[ "$basename_dir" == "$excluded" ]] || [[ "$dir" == *"/$excluded/"* ]]; then
      return 0
    fi
  done
  return 1
}

is_safe_file() {
  local file="$1"

  for pattern in "${SAFE_PATTERNS[@]}"; do
    if [[ "$file" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

is_text_file() {
  local file="$1"

  # Check file size first
  local size=$(stat -f%z "$file" 2>/dev/null || echo 0)
  if [[ $size -gt $MAX_FILE_SIZE ]]; then
    return 1
  fi

  # Use MIME type detection
  local mime=$(file -b --mime-type "$file" 2>/dev/null)

  case "$mime" in
    text/*|application/json|application/xml|application/x-yaml)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

matches_filename_pattern() {
  local file="$1"
  local basename_file=$(basename "$file")

  for pattern in "${SECRET_FILENAME_PATTERNS[@]}"; do
    if [[ "$basename_file" =~ $pattern ]] || [[ "$file" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

scan_file_content() {
  local file="$1"
  local matches=()

  for pattern in "${SECRET_CONTENT_PATTERNS[@]}"; do
    if grep -q -E "$pattern" "$file" 2>/dev/null; then
      matches+=("$pattern")
    fi
  done

  if [[ ${#matches[@]} -gt 0 ]]; then
    return 0
  fi
  return 1
}

get_file_fingerprint() {
  local file="$1"

  # For SSH/GPG keys, show fingerprint only
  if [[ "$file" =~ \.pub$ ]]; then
    # Public key - safe to show fingerprint
    if command -v ssh-keygen &>/dev/null; then
      ssh-keygen -lf "$file" 2>/dev/null | awk '{print $2}' || echo "[fingerprint unavailable]"
    else
      echo "[ssh-keygen not available]"
    fi
  elif [[ "$file" =~ id_rsa|id_ed25519 ]] && [[ ! "$file" =~ \.pub$ ]]; then
    # Private key - show fingerprint of corresponding public key if exists
    if [[ -f "${file}.pub" ]]; then
      if command -v ssh-keygen &>/dev/null; then
        ssh-keygen -lf "${file}.pub" 2>/dev/null | awk '{print $2}' || echo "[fingerprint unavailable]"
      else
        echo "[ssh-keygen not available]"
      fi
    else
      echo "[private key - no public key found]"
    fi
  else
    # For other files, show first few characters only
    head -c 16 "$file" 2>/dev/null | base64 | head -c 24 || echo "[unreadable]"
  fi
}

# ============================================================================
# SCAN LOGIC
# ============================================================================

scan_directory() {
  local scan_root="$1"
  local depth="$2"

  local total_files=0
  local scanned_files=0
  local suspicious_files=0
  local findings=()

  print_step "Scanning: $scan_root (depth: $depth)"

  if [[ "$DRY_RUN" == true ]]; then
    info "DRY RUN - Would scan with these settings:"
    echo "  Scan root: $scan_root"
    echo "  Max depth: $depth"
    echo "  Max file size: $((MAX_FILE_SIZE / 1024 / 1024))MB"
    echo "  Excluded directories: ${#EXCLUDED_DIRS[@]} patterns"
    return
  fi

  # Find all files up to specified depth
  while IFS= read -r -d '' file; do
    total_files=$(( total_files + 1 ))

    # Progress indicator every 100 files
    if (( total_files % 100 == 0 )); then
      echo -ne "\r${BLUE}[i]${NC}  Progress: $total_files files checked, $suspicious_files suspicious"
    fi

    # Skip if in excluded directory
    local dir=$(dirname "$file")
    if is_excluded_dir "$dir"; then
      continue
    fi

    # Skip if not readable
    if [[ ! -r "$file" ]]; then
      continue
    fi

    # Skip if not a text file
    if ! is_text_file "$file"; then
      continue
    fi

    scanned_files=$(( scanned_files + 1 ))

    local filename_match=false
    if matches_filename_pattern "$file"; then
      filename_match=true
    fi

    # Skip known-safe docs/config only after path-based secret checks.
    if [[ "$filename_match" == false ]] && is_safe_file "$file"; then
      continue
    fi

    # Check content patterns
    local content_match=false
    if scan_file_content "$file"; then
      content_match=true
    fi

    # Report findings
    if [[ "$filename_match" == true ]] || [[ "$content_match" == true ]]; then
      suspicious_files=$(( suspicious_files + 1 ))

      local severity="MEDIUM"
      if [[ "$content_match" == true ]]; then
        severity="HIGH"
      fi

      local fingerprint=$(get_file_fingerprint "$file")

      findings+=("$severity|$file|$fingerprint")
    fi

  done < <(find "$scan_root" -maxdepth "$depth" -type f -print0 2>/dev/null)

  # Clear progress line
  echo -ne "\r\033[K"

  success "Scanned $scanned_files text files (total: $total_files files)"

  if [[ ${#findings[@]} -gt 0 ]]; then
    warning "Found $suspicious_files suspicious files"
    echo ""

    # Sort by severity
    printf '%s\n' "${findings[@]}" | sort -t'|' -k1,1r | while IFS='|' read -r severity file fingerprint; do
      case "$severity" in
        HIGH)
          critical "[$severity] $file"
          echo "   Fingerprint: $fingerprint"
          ;;
        MEDIUM)
          warning "[$severity] $file"
          echo "   Fingerprint: $fingerprint"
          ;;
      esac
    done
  else
    success "No suspicious files found"
  fi

  echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  banner

  info "Audit Configuration:"
  echo "  Scan depth: $SCAN_DEPTH directories"
  echo "  Max file size: $((MAX_FILE_SIZE / 1024 / 1024))MB"
  echo "  Excluded directories: ${#EXCLUDED_DIRS[@]} patterns"
  echo "  Dry run: $DRY_RUN"
  echo ""

  # Scan common secret locations
  declare -a scan_locations=(
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.aws"
    "$HOME/.config"
    "$HOME/.db"
    "$HOME/.tokens"
    "$HOME/.credentials"
    "$HOME/.docker"
    "$HOME/.kube"
  )

  for location in "${scan_locations[@]}"; do
    if [[ -d "$location" ]]; then
      scan_directory "$location" "$SCAN_DEPTH"
    fi
  done

  # Output report to file if requested
  if [[ -n "$OUTPUT_FILE" ]]; then
    info "Note: Use shell redirection for reports (e.g., secrets-audit > report.txt)"
  fi

  local end_time=$(date +%s)
  local duration=$((end_time - START_TIME))

  print_step "Audit Complete"
  echo ""
  success "Total time: ${duration}s"
  echo ""
}

main
