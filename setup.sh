#!/usr/bin/env bash
# Nix-Darwin User-Agnostic Setup Script
#
# Comprehensive setup wizard for new users and machine configuration
#
# Usage:
#   ./setup.sh                # Auto-detect scenario and guide user
#   ./setup.sh --migrate      # Force: migrate local secrets
#   ./setup.sh --restore      # Force: restore from encrypted secrets
#   ./setup.sh --fresh        # Force: fresh setup (no secrets)
#   ./setup.sh --configure    # Just machine config
#   ./setup.sh --force        # Allow reconfiguration
#   ./setup.sh --help         # Show help

set -e  # Exit on error
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_VERSION="2.0.0"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Global variables
EXPLICIT_MODE=""
FORCE_RECONFIG="no"
DRY_RUN="no"
USERNAME=""
MACHINE_ID=""
MACHINE_TYPE=""
MACHINE_DESCRIPTION=""
FULL_NAME=""
EMAIL=""
SYSTEM_ARCH=""
MIXINS=""

# Detection results
declare -a SECRETS_FILES
LOCAL_SECRETS_FOUND="no"
SOPS_KEY_EXISTS="no"
MACHINE_CONFIG_EXISTS="no"
declare -A DISCOVERED_SECRETS
declare -A SELECTED_SECRETS
declare -A DISCOVERED_CONFIGS
declare -A CONFIG_DETAILS

# SOPS key info
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
AGE_PUBLIC_KEY=""

# State tracking for abort/resume
STATE_FILE="$HOME/.nix-darwin-setup.state"
BACKUP_DIR=""
CURRENT_PHASE=""
SOPS_KEY_BACKED_UP="no"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

print_step() {
  echo ""
  echo -e "${BOLD}${BLUE}$1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

success() {
  echo -e "${GREEN}✅ $1${NC}"
}

error() {
  echo -e "${RED}❌ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
  echo -e "${CYAN}ℹ️  $1${NC}"
}

prompt() {
  echo -e "${MAGENTA}❓ $1${NC}"
}

# ============================================================================
# STATE MANAGEMENT & RECOVERY
# ============================================================================

save_state() {
  cat > "$STATE_FILE" <<EOF
# Nix-Darwin Setup State
# Generated: $(date)
phase=$CURRENT_PHASE
timestamp=$(date +%s)
backup=$BACKUP_DIR
username=$USERNAME
machine_id=$MACHINE_ID
machine_type=$MACHINE_TYPE
email=$EMAIL
full_name=$FULL_NAME
system_arch=$SYSTEM_ARCH
sops_key_backed_up=$SOPS_KEY_BACKED_UP
EOF

  info "State saved to: $STATE_FILE"
}

load_state() {
  if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    return 0
  fi
  return 1
}

cleanup_state() {
  rm -f "$STATE_FILE"
  success "State file cleaned up"
}

handle_interrupt() {
  echo ""
  echo ""
  warning "⏸️  Setup interrupted by user"
  echo ""

  # Save current state
  save_state

  echo ""
  success "✅ State saved. Your progress is preserved."
  echo ""
  echo "📦 Backup location: ${BACKUP_DIR:-none}"
  echo "💾 State file: $STATE_FILE"
  echo ""
  echo "Recovery options:"
  echo "  1. Resume:  ./setup.sh --resume"
  echo "  2. Restore: ./setup.sh --restore-backup"
  echo "  3. Cleanup: rm $STATE_FILE"
  echo ""

  exit 130  # Standard SIGINT exit code
}

setup_interrupt_handler() {
  trap 'handle_interrupt' INT TERM
}

create_backup() {
  local timestamp=$(date +%s)
  BACKUP_DIR="$HOME/.nix-darwin-setup-backup-$timestamp"

  print_step "📦 Creating Safety Backup"

  info "Creating backup directory..."
  mkdir -p "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR"

  local backup_count=0

  # Backup AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    cp "$HOME/.aws/credentials" "$BACKUP_DIR/aws-credentials"
    ((backup_count++))
    success "AWS credentials backed up"
  fi

  if [ -f "$HOME/.aws/config" ]; then
    cp "$HOME/.aws/config" "$BACKUP_DIR/aws-config"
    ((backup_count++))
    success "AWS config backed up"
  fi

  # Backup SSH keys
  for key in "$HOME/.ssh/id_"*; do
    if [ -f "$key" ] && [[ "$key" != *.pub ]]; then
      local key_name=$(basename "$key")
      cp "$key" "$BACKUP_DIR/ssh-$key_name"
      ((backup_count++))
      success "SSH key backed up: $key_name"
    fi
  done

  # Backup database credentials
  if [ -d "$HOME/.db" ]; then
    cp -r "$HOME/.db" "$BACKUP_DIR/db-connections"
    local db_count=$(find "$HOME/.db" -type f 2>/dev/null | wc -l | tr -d ' ')
    backup_count=$((backup_count + db_count))
    success "Database credentials backed up: $db_count files"
  fi

  # Backup tokens
  if [ -d "$HOME/.tokens" ]; then
    cp -r "$HOME/.tokens" "$BACKUP_DIR/tokens"
    local token_count=$(find "$HOME/.tokens" -type f 2>/dev/null | wc -l | tr -d ' ')
    backup_count=$((backup_count + token_count))
    success "API tokens backed up: $token_count files"
  fi

  # Create manifest
  cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
Nix-Darwin Setup Backup
=======================
Created: $(date)
Hostname: $(hostname)
User: $(whoami)
Purpose: Safety backup before SOPS migration

Files backed up: $backup_count

To restore this backup:
  ./setup.sh --restore-backup $BACKUP_DIR

Contents:
$(ls -lh "$BACKUP_DIR")
EOF

  echo ""
  success "✅ Backup created: $BACKUP_DIR"
  success "   $backup_count file(s) backed up"
  echo ""

  # Update state
  save_state
}

restore_from_backup() {
  local backup_dir="${1:-}"

  # Auto-detect if not provided
  if [ -z "$backup_dir" ]; then
    backup_dir=$(find "$HOME" -maxdepth 1 -name ".nix-darwin-setup-backup-*" -type d 2>/dev/null | sort -r | head -1)
  fi

  if [ ! -d "$backup_dir" ]; then
    error "Backup not found: $backup_dir"
    echo ""
    info "Available backups:"
    find "$HOME" -maxdepth 1 -name ".nix-darwin-setup-backup-*" -type d 2>/dev/null || echo "  (none)"
    exit 1
  fi

  print_header "📦 Restore from Backup"

  echo "Backup: $backup_dir"
  echo "Created: $(stat -f %Sm "$backup_dir")"
  echo ""
  echo "Files to restore:"
  ls -lh "$backup_dir" | grep -v "^total" | grep -v "MANIFEST" | awk '{print "  " $9 " (" $5 ")"}'
  echo ""

  read -p "Restore? This will overwrite current files [yes/no]: " confirm

  if [ "$confirm" != "yes" ]; then
    info "Restore cancelled"
    exit 0
  fi

  # Restore AWS credentials
  if [ -f "$backup_dir/aws-credentials" ]; then
    mkdir -p "$HOME/.aws"
    cp "$backup_dir/aws-credentials" "$HOME/.aws/credentials"
    chmod 600 "$HOME/.aws/credentials"
    success "Restored: AWS credentials"
  fi

  if [ -f "$backup_dir/aws-config" ]; then
    mkdir -p "$HOME/.aws"
    cp "$backup_dir/aws-config" "$HOME/.aws/config"
    chmod 600 "$HOME/.aws/config"
    success "Restored: AWS config"
  fi

  # Restore SSH keys
  for key in "$backup_dir"/ssh-*; do
    if [ -f "$key" ]; then
      local key_name=$(basename "$key" | sed 's/^ssh-//')
      cp "$key" "$HOME/.ssh/$key_name"
      chmod 600 "$HOME/.ssh/$key_name"
      success "Restored: SSH key $key_name"
    fi
  done

  # Restore database credentials
  if [ -d "$backup_dir/db-connections" ]; then
    cp -r "$backup_dir/db-connections" "$HOME/.db"
    chmod -R 600 "$HOME/.db"/*
    success "Restored: Database credentials"
  fi

  # Restore tokens
  if [ -d "$backup_dir/tokens" ]; then
    cp -r "$backup_dir/tokens" "$HOME/.tokens"
    chmod -R 600 "$HOME/.tokens"/*
    success "Restored: API tokens"
  fi

  # Cleanup state
  cleanup_state

  echo ""
  success "✅ Restore complete! Original state recovered."
  echo ""
  echo "You can now:"
  echo "  • Run setup again: ./setup.sh"
  echo "  • Keep backup: Saved in $backup_dir"
  echo ""
}

check_for_resume() {
  if [ -f "$STATE_FILE" ]; then
    load_state

    echo ""
    warning "⚠️  Incomplete setup detected from previous run"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase:       $phase"
    echo "Started:     $(date -r $timestamp 2>/dev/null || date)"
    echo "Backup:      $backup"
    echo ""
    echo "Options:"
    echo "  [r] Resume from where you left off (recommended)"
    echo "  [s] Start fresh (restores from backup if available)"
    echo "  [a] Abort (keeps current state)"
    echo ""
    read -p "Choice [r/s/a]: " choice

    case "$choice" in
      r|R)
        info "Resuming from: $phase"
        # Load all state variables
        CURRENT_PHASE="$phase"
        BACKUP_DIR="$backup"
        # Continue with normal flow
        ;;
      s|S)
        if [ -n "$backup" ] && [ -d "$backup" ]; then
          restore_from_backup "$backup"
        else
          warning "No backup found, starting fresh"
          cleanup_state
        fi
        ;;
      a|A)
        info "Exiting without changes"
        exit 0
        ;;
      *)
        check_for_resume  # Re-prompt
        ;;
    esac

    echo ""
  fi
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_prerequisites() {
  print_step "Step 0: Prerequisites Check"

  info "Checking required tools..."
  echo ""

  # Check Nix
  if command -v nix &>/dev/null; then
    success "Nix installed"
  else
    error "Nix not installed"
    echo ""
    echo "Install Nix: https://nixos.org/download.html"
    exit 1
  fi

  # Check nix-darwin
  if command -v darwin-rebuild &>/dev/null; then
    success "nix-darwin installed"
  else
    error "nix-darwin not installed"
    echo ""
    echo "Install nix-darwin: https://github.com/LnL7/nix-darwin"
    exit 1
  fi

  # Check SOPS
  if command -v sops &>/dev/null; then
    success "SOPS installed"
  else
    error "SOPS not installed"
    echo ""
    echo "Install SOPS:"
    echo "  brew install sops"
    echo "  or"
    echo "  nix-env -iA nixpkgs.sops"
    exit 1
  fi

  # Check age
  if command -v age &>/dev/null; then
    success "age installed"
  else
    error "age not installed"
    echo ""
    echo "Install age:"
    echo "  brew install age"
    echo "  or"
    echo "  nix-env -iA nixpkgs.age"
    exit 1
  fi

  # Check git
  if command -v git &>/dev/null; then
    success "git installed"
  else
    error "git not installed"
    exit 1
  fi

  echo ""
  success "All prerequisites satisfied"
  echo ""
}

# ============================================================================
# DETECTION PHASE
# ============================================================================

detect_environment() {
  print_step "📊 Environment Detection"

  info "Analyzing repository state..."
  echo ""

  # 1. Find encrypted secrets.yaml files
  while IFS= read -r -d '' file; do
    SECRETS_FILES+=("$file")
  done < <(find "$REPO_ROOT/hosts" -name "secrets.yaml" -print0 2>/dev/null)

  # 2. Check for local secrets
  local secrets_count=0
  [ -f "$HOME/.aws/credentials" ] && ((secrets_count++))
  [ -f "$HOME/.aws/config" ] && ((secrets_count++))
  for key in "$HOME/.ssh/id_"*; do
    [ -f "$key" ] && [[ "$key" != *.pub ]] && ((secrets_count++))
  done
  [ -d "$HOME/.db" ] && secrets_count=$((secrets_count + $(find "$HOME/.db" -type f 2>/dev/null | wc -l)))
  [ -d "$HOME/.tokens" ] && secrets_count=$((secrets_count + $(find "$HOME/.tokens" -type f 2>/dev/null | wc -l)))

  [ $secrets_count -gt 0 ] && LOCAL_SECRETS_FOUND="yes"

  # 3. Check SOPS key
  [ -f "$AGE_KEY_FILE" ] && SOPS_KEY_EXISTS="yes"

  # 4. Check machine config
  [ -f "$REPO_ROOT/config/machine-config.nix" ] && MACHINE_CONFIG_EXISTS="yes"

  # Display results
  echo -e "${BOLD}Detection Results:${NC}"
  echo ""

  if [ ${#SECRETS_FILES[@]} -gt 0 ]; then
    success "Found ${#SECRETS_FILES[@]} encrypted secrets.yaml file(s)"
    for file in "${SECRETS_FILES[@]}"; do
      local machine_name=$(echo "$file" | sed "s|.*/hosts/||;s|/secrets.yaml||")
      echo "    • $machine_name"
    done
  else
    info "No encrypted secrets.yaml found"
  fi

  if [ "$LOCAL_SECRETS_FOUND" = "yes" ]; then
    success "Found $secrets_count local secret(s) to migrate"
  else
    info "No local secrets found"
  fi

  if [ "$SOPS_KEY_EXISTS" = "yes" ]; then
    success "SOPS age key exists"
  else
    info "No SOPS key (will generate or restore)"
  fi

  if [ "$MACHINE_CONFIG_EXISTS" = "yes" ]; then
    warning "Machine already configured"
    echo "    Location: config/machine-config.nix"
  else
    info "Machine not yet configured"
  fi

  echo ""
}

# ============================================================================
# INFORMATION GATHERING
# ============================================================================

show_username_impact() {
  local from="$1"
  local to="$2"

  cat <<EOF

⚠️  Impact of username change: '$from' → '$to'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This will affect:
  • User-data directory: user-data-$to/
  • Home directory references: /Users/$to
  • Nix configuration paths
  • Git commits (if using username for git)

✅ Safe to change - all references will be updated
⚠️  Note: System files in /Users/$from won't move automatically

EOF
}

show_email_impact() {
  local from="$1"
  local to="$2"

  cat <<EOF

📧 Email change: '$from' → '$to'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This email will be used for:
  • Git commits (git config user.email)
  • Work profile configuration (if work machine)
  • User identification in config files

✅ Recommended: Use your primary Git email
💡 Tip: Check with 'git config --global user.email'

EOF
}

gather_user_info() {
  print_step "📝 System Information"

  # Auto-detect system values
  local detected_user="$(whoami)"
  local detected_email="$(git config --global user.email 2>/dev/null || echo "")"
  local detected_name="$(git config --global user.name 2>/dev/null || echo "")"
  local detected_hostname="$(hostname | sed 's/\.local$//')"

  # Display detected values
  echo "📋 Detected from your system:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-15s %-30s %s\n" "Username:" "$detected_user" "✓"
  printf "%-15s %-30s %s\n" "Email:" "${detected_email:-(not set)}" "$([ -n "$detected_email" ] && echo "✓" || echo "⚠️")"
  printf "%-15s %-30s %s\n" "Full name:" "${detected_name:-(not set)}" "$([ -n "$detected_name" ] && echo "✓" || echo "⚠️")"
  printf "%-15s %-30s %s\n" "Hostname:" "$detected_hostname" "✓"
  echo ""

  # Show warnings for missing values
  [ -z "$detected_email" ] && warning "No git email configured - will prompt"
  [ -z "$detected_name" ] && warning "No git name configured - will prompt"
  echo ""

  # Keep or customize choice
  echo "Options:"
  echo "  [k] Keep detected values (fastest - just press Enter)"
  echo "  [c] Customize specific values"
  echo ""
  read -p "Choice [k/c] (default: k): " keep_or_change
  keep_or_change="${keep_or_change:-k}"

  if [[ "$keep_or_change" =~ ^[Kk]$ ]]; then
    # Fast path - use detected values
    USERNAME="$detected_user"
    EMAIL="$detected_email"
    FULL_NAME="$detected_name"
    MACHINE_ID="$detected_hostname"

    # Prompt only for missing values
    if [ -z "$EMAIL" ]; then
      echo ""
      read -p "Email (required): " EMAIL
      while [ -z "$EMAIL" ]; do
        warning "Email is required"
        read -p "Email: " EMAIL
      done
    fi

    if [ -z "$FULL_NAME" ]; then
      echo ""
      read -p "Full name (required): " FULL_NAME
      while [ -z "$FULL_NAME" ]; do
        warning "Full name is required"
        read -p "Full name: " FULL_NAME
      done
    fi

  else
    # Custom path - selective changes
    info "Customize values (press Enter to keep detected)"
    echo ""

    # Username
    echo "Username: $detected_user"
    read -p "Change? [y/N]: " change_user
    if [[ "$change_user" =~ ^[Yy]$ ]]; then
      read -p "New username: " custom_user
      show_username_impact "$detected_user" "$custom_user"
      read -p "Confirm change? [y/N]: " confirm
      USERNAME="${confirm:+$custom_user}"
      USERNAME="${USERNAME:-$detected_user}"
    else
      USERNAME="$detected_user"
    fi
    echo ""

    # Email
    if [ -n "$detected_email" ]; then
      echo "Email: $detected_email"
      read -p "Change? [y/N]: " change_email
      if [[ "$change_email" =~ ^[Yy]$ ]]; then
        read -p "New email: " EMAIL
        show_email_impact "$detected_email" "$EMAIL"
      else
        EMAIL="$detected_email"
      fi
    else
      read -p "Email (required): " EMAIL
      while [ -z "$EMAIL" ]; do
        warning "Email is required"
        read -p "Email: " EMAIL
      done
    fi
    echo ""

    # Full name
    if [ -n "$detected_name" ]; then
      echo "Full name: $detected_name"
      read -p "Change? [y/N]: " change_name
      if [[ "$change_name" =~ ^[Yy]$ ]]; then
        read -p "New full name: " FULL_NAME
      else
        FULL_NAME="$detected_name"
      fi
    else
      read -p "Full name (required): " FULL_NAME
      while [ -z "$FULL_NAME" ]; do
        warning "Full name is required"
        read -p "Full name: " FULL_NAME
      done
    fi
    echo ""

    # Machine ID
    echo "Machine ID: $detected_hostname"
    read -p "Change? [y/N]: " change_id
    if [[ "$change_id" =~ ^[Yy]$ ]]; then
      read -p "New machine ID: " MACHINE_ID
    else
      MACHINE_ID="$detected_hostname"
    fi
    echo ""
  fi

  # Machine type (always ask)
  echo "Machine type:"
  echo "  1) Personal Mac"
  echo "  2) Work Mac"
  echo "  3) Minimal (base only)"
  read -p "Select [1-3]: " MACHINE_TYPE_CHOICE

  case $MACHINE_TYPE_CHOICE in
    1)
      MACHINE_TYPE="personal"
      MIXINS='[ "base" "dev" "personal" ]'
      ;;
    2)
      MACHINE_TYPE="work"
      MIXINS='[ "base" "dev" "work" ]'
      ;;
    3)
      MACHINE_TYPE="minimal"
      MIXINS='[ "base" ]'
      ;;
    *)
      error "Invalid choice"
      exit 1
      ;;
  esac

  # Machine description
  local default_desc="${USERNAME}'s ${MACHINE_TYPE} Mac"
  read -p "Machine description [$default_desc]: " MACHINE_DESCRIPTION
  MACHINE_DESCRIPTION="${MACHINE_DESCRIPTION:-$default_desc}"

  # System architecture (auto-detect with confirmation)
  local detected_arch="$(uname -m)"
  echo ""
  echo "System architecture:"
  if [ "$detected_arch" = "arm64" ]; then
    echo "  Detected: Apple Silicon (M1/M2/M3)"
    read -p "Correct? [Y/n]: " arch_confirm
    if [[ ! $arch_confirm =~ ^[Nn]$ ]]; then
      SYSTEM_ARCH="aarch64-darwin"
    else
      SYSTEM_ARCH="x86_64-darwin"
    fi
  else
    echo "  Detected: Intel Mac"
    read -p "Correct? [Y/n]: " arch_confirm
    if [[ ! $arch_confirm =~ ^[Nn]$ ]]; then
      SYSTEM_ARCH="x86_64-darwin"
    else
      SYSTEM_ARCH="aarch64-darwin"
    fi
  fi

  # Summary
  echo ""
  echo -e "${BOLD}Configuration Summary:${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Username:     $USERNAME"
  echo "  Full Name:    $FULL_NAME"
  echo "  Email:        $EMAIL"
  echo "  Machine ID:   $MACHINE_ID"
  echo "  Machine Type: $MACHINE_TYPE"
  echo "  Description:  $MACHINE_DESCRIPTION"
  echo "  Architecture: $SYSTEM_ARCH"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  read -p "Looks good? [Y/n]: " confirm
  if [[ $confirm =~ ^[Nn]$ ]]; then
    echo ""
    info "Let's try again..."
    gather_user_info  # Restart
    return
  fi

  echo ""
}

# ============================================================================
# SOPS KEY MANAGEMENT
# ============================================================================

generate_sops_key() {
  print_step "🔐 SOPS Key Generation"

  # CRITICAL WARNING CHECKPOINT
  cat <<EOF

⚠️  ${BOLD}SOPS KEY GENERATION CHECKPOINT${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
We're about to generate your encryption key.

🔐 ${BOLD}CRITICAL: This key is the ONLY way to decrypt your secrets!${NC}

After generation, you MUST save it by:
  1. Writing it on paper (recommended)
  2. Storing in password manager
  3. Keeping multiple backups

⚡ ${BOLD}Without this key, your secrets are UNRECOVERABLE!${NC}

Do NOT proceed until you're ready for this responsibility.

EOF

  read -p "Type 'yes' to confirm you understand: " confirm
  if [ "$confirm" != "yes" ]; then
    error "Aborting - user not ready for key responsibility"
    exit 1
  fi
  echo ""

  if [ "$DRY_RUN" = "yes" ]; then
    info "[DRY RUN] Would create: $AGE_KEY_FILE"
    AGE_PUBLIC_KEY="age1dry-run-example-key-123"
    success "[DRY RUN] Age key would be generated: $AGE_PUBLIC_KEY"
  else
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    age-keygen -o "$AGE_KEY_FILE" 2>&1 | tee /tmp/age-keygen-output.txt
    AGE_PUBLIC_KEY=$(grep "Public key:" /tmp/age-keygen-output.txt | cut -d: -f2 | tr -d ' ')
    rm -f /tmp/age-keygen-output.txt

    chmod 600 "$AGE_KEY_FILE"

    success "Age key generated: $AGE_PUBLIC_KEY"
  fi
  echo ""

  # Force user confirmation
  echo -e "${BOLD}📋 BACKUP YOUR KEY NOW!${NC}"
  echo ""
  info "Key location: $AGE_KEY_FILE"
  echo ""
  echo "Backup options:"
  echo "  • Password manager (1Password, Bitwarden)"
  echo "  • USB drive (encrypted)"
  echo "  • Paper backup (secure location)"
  echo "  • Cloud storage (encrypted)"
  echo ""
  warning "Without this key, you CANNOT decrypt your secrets!"
  echo ""

  while true; do
    read -p "Have you saved your key securely? (yes/no): " confirm
    case $confirm in
      yes|YES|y|Y )
        success "Key backup confirmed"
        break
        ;;
      no|NO|n|N )
        echo ""
        warning "You MUST save your key before continuing!"
        echo "Please back up your key to at least one secure location."
        echo ""
        ;;
      * )
        echo "Please answer 'yes' or 'no'"
        ;;
    esac
  done

  echo ""

  # Verify SOPS works
  info "Verifying SOPS functionality..."

  if [ "$DRY_RUN" = "yes" ]; then
    success "[DRY RUN] SOPS encryption and decryption would be verified"
  else
    local test_file=$(mktemp)
    echo "test-$(date +%s)" > "$test_file"

    if sops -e -i "$test_file" 2>/dev/null && sops -d "$test_file" > /dev/null 2>&1; then
      success "SOPS encryption and decryption verified"
    else
      error "SOPS verification failed!"
      rm -f "$test_file"
      exit 1
    fi

    rm -f "$test_file"
  fi
  echo ""
}

restore_sops_key() {
  print_step "🔑 SOPS Key Restoration"

  warning "You need to restore your age key to decrypt existing secrets."
  echo ""
  echo "Restoration options:"
  echo "  1) From file (password manager export, USB backup, cloud)"
  echo "  2) Manual entry (copy/paste or type from paper backup)"
  echo ""
  read -p "Select [1-2]: " restore_method

  if [ "$DRY_RUN" = "yes" ]; then
    info "[DRY RUN] Would restore key to: $AGE_KEY_FILE"
    success "[DRY RUN] Age key would be restored"
    SOPS_KEY_EXISTS="yes"
  else
    mkdir -p "$(dirname "$AGE_KEY_FILE")"

    case $restore_method in
      1)
        read -p "Path to age key backup file: " key_source
        if [ ! -f "$key_source" ]; then
          error "File not found: $key_source"
          exit 1
        fi
        cp "$key_source" "$AGE_KEY_FILE"
        ;;
      2)
        echo ""
        info "Age key format starts with: AGE-SECRET-KEY-1..."
        echo ""
        echo "Paste your age key below and press Ctrl+D when done:"
        cat > "$AGE_KEY_FILE"
        ;;
      *)
        error "Invalid choice"
        exit 1
        ;;
    esac

    chmod 600 "$AGE_KEY_FILE"

    # Validate key format
    if ! grep -q "AGE-SECRET-KEY" "$AGE_KEY_FILE"; then
      error "Invalid age key format!"
      echo ""
      echo "Age keys start with: AGE-SECRET-KEY-1..."
      exit 1
    fi

    success "Age key restored"
    SOPS_KEY_EXISTS="yes"
  fi
  echo ""
}

# ============================================================================
# SECRET DISCOVERY
# ============================================================================

discover_secrets() {
  print_step "🔍 Secrets Discovery"

  info "Scanning for existing secrets..."
  echo ""

  local secrets_count=0

  # AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    DISCOVERED_SECRETS["aws_credentials"]="$HOME/.aws/credentials"
    ((secrets_count++))
    success "AWS credentials"
  fi

  if [ -f "$HOME/.aws/config" ]; then
    DISCOVERED_SECRETS["aws_config"]="$HOME/.aws/config"
    ((secrets_count++))
    success "AWS config"
  fi

  # SSH keys
  for key in "$HOME/.ssh/id_"*; do
    if [ -f "$key" ] && [[ "$key" != *.pub ]]; then
      local key_name=$(basename "$key")
      DISCOVERED_SECRETS["ssh_${key_name}"]="$key"
      ((secrets_count++))
      success "SSH key: $key_name"
    fi
  done

  # Database credentials
  if [ -d "$HOME/.db" ]; then
    while IFS= read -r -d '' db_file; do
      local rel_path="${db_file#$HOME/.db/}"
      local secret_key="db_${rel_path//\//_}"
      DISCOVERED_SECRETS["$secret_key"]="$db_file"
      ((secrets_count++))
    done < <(find "$HOME/.db" -type f -print0 2>/dev/null)

    if [ $secrets_count -gt 0 ]; then
      success "Database credentials: $(find "$HOME/.db" -type f 2>/dev/null | wc -l | tr -d ' ') files"
    fi
  fi

  # API tokens
  if [ -d "$HOME/.tokens" ]; then
    for token in "$HOME/.tokens/"*; do
      if [ -f "$token" ]; then
        local token_name=$(basename "$token")
        DISCOVERED_SECRETS["token_${token_name}"]="$token"
        ((secrets_count++))
        success "API token: $token_name"
      fi
    done
  fi

  echo ""

  if [ $secrets_count -eq 0 ]; then
    warning "No secrets found to migrate"
    return 1
  else
    success "Found $secrets_count secret(s) to migrate"
    return 0
  fi
}

# ============================================================================
# CONFIG DISCOVERY
# ============================================================================

discover_configs() {
  print_step "🔍 Configuration Discovery"

  info "Scanning for existing configurations..."
  echo ""

  local found_count=0
  local missing_count=0

  # AWS Configuration (comprehensive detection)
  if [ -f "$HOME/.aws/config" ] || [ -f "$HOME/.aws/credentials" ] || [ -f "$HOME/.aws/accounts.json" ]; then
    DISCOVERED_CONFIGS["aws"]="found"
    local aws_details=""
    local aws_type="unknown"
    local has_sso=false
    local has_credentials=false

    # Detect SSO sessions
    local sso_session_count=0
    if [ -f "$HOME/.aws/config" ]; then
      sso_session_count=$(grep -c "^\[sso-session " "$HOME/.aws/config" 2>/dev/null || echo "0")
      if [ $sso_session_count -gt 0 ]; then
        has_sso=true
        aws_type="SSO"
      fi
    fi

    # Detect credential-based profiles
    if [ -f "$HOME/.aws/credentials" ]; then
      local cred_profile_count=$(grep -c "^\[" "$HOME/.aws/credentials" 2>/dev/null || echo "0")
      if [ $cred_profile_count -gt 0 ]; then
        has_credentials=true
        if [ "$aws_type" = "SSO" ]; then
          aws_type="Mixed (SSO + Credentials)"
        else
          aws_type="Credentials"
        fi
      fi
    fi

    # Count total profiles
    local profile_count=0
    local sso_profile_count=0
    local regular_profile_count=0

    if [ -f "$HOME/.aws/config" ]; then
      profile_count=$(grep -c "^\[profile " "$HOME/.aws/config" 2>/dev/null || echo "0")

      # Count SSO-based profiles
      if [ -f "$HOME/.aws/config" ]; then
        sso_profile_count=$(grep -A 5 "^\[profile " "$HOME/.aws/config" | grep -c "sso_session = " 2>/dev/null || echo "0")
        regular_profile_count=$((profile_count - sso_profile_count))
      fi
    fi

    # Detect regions used
    local regions=""
    if [ -f "$HOME/.aws/config" ]; then
      regions=$(grep "^region = " "$HOME/.aws/config" 2>/dev/null | cut -d= -f2 | tr -d ' ' | sort -u | tr '\n' ',' | sed 's/,$//' || echo "")
      # Also check sso_region
      local sso_regions=$(grep "^sso_region = " "$HOME/.aws/config" 2>/dev/null | cut -d= -f2 | tr -d ' ' | sort -u | tr '\n' ',' | sed 's/,$//' || echo "")
      if [ -n "$sso_regions" ]; then
        if [ -n "$regions" ]; then
          regions="$regions,$sso_regions"
        else
          regions="$sso_regions"
        fi
      fi
      # Deduplicate
      regions=$(echo "$regions" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//' || echo "")
    fi

    # Count accounts (if accounts.json exists)
    local account_count=0
    if [ -f "$HOME/.aws/accounts.json" ]; then
      account_count=$(jq 'length' "$HOME/.aws/accounts.json" 2>/dev/null || echo "0")
    fi

    # Build detailed summary
    aws_details="Type: $aws_type"

    if [ $sso_session_count -gt 0 ]; then
      aws_details="$aws_details | SSO Sessions: $sso_session_count"
    fi

    if [ $profile_count -gt 0 ]; then
      if [ $sso_profile_count -gt 0 ] && [ $regular_profile_count -gt 0 ]; then
        aws_details="$aws_details | Profiles: $profile_count ($sso_profile_count SSO, $regular_profile_count credential-based)"
      elif [ $sso_profile_count -gt 0 ]; then
        aws_details="$aws_details | Profiles: $profile_count (SSO)"
      else
        aws_details="$aws_details | Profiles: $profile_count"
      fi
    fi

    if [ $account_count -gt 0 ]; then
      aws_details="$aws_details | Accounts: $account_count"
    fi

    if [ -n "$regions" ]; then
      local region_count=$(echo "$regions" | tr ',' '\n' | wc -l | tr -d ' ')
      if [ $region_count -le 3 ]; then
        aws_details="$aws_details | Regions: $regions"
      else
        aws_details="$aws_details | Regions: $region_count different"
      fi
    fi

    CONFIG_DETAILS["aws"]="$aws_details"
    ((found_count++))

    # Suggest machine type based on AWS setup
    if [ "$has_sso" = true ]; then
      success "AWS configuration (${BOLD}Work setup detected${NC})"
      info "   $aws_details"
      if [ -z "$MACHINE_TYPE" ]; then
        warning "   💡 Hint: SSO setup suggests this is a work machine"
      fi
    else
      success "AWS configuration (${BOLD}Personal setup${NC})"
      info "   $aws_details"
    fi
  else
    DISCOVERED_CONFIGS["aws"]="missing"
    CONFIG_DETAILS["aws"]="Will use default AWS configuration"
    ((missing_count++))
    warning "AWS config not found → Will use defaults"
  fi

  # Git Configuration
  if git config --global user.email &>/dev/null; then
    DISCOVERED_CONFIGS["git"]="found"
    local git_user=$(git config --global user.name 2>/dev/null || echo "unknown")
    local git_email=$(git config --global user.email 2>/dev/null || echo "unknown")
    CONFIG_DETAILS["git"]="$git_user <$git_email>"
    ((found_count++))
    success "Git configuration ($git_user <$git_email>)"
  else
    DISCOVERED_CONFIGS["git"]="missing"
    CONFIG_DETAILS["git"]="Will be configured from user-config.nix"
    ((missing_count++))
    warning "Git config not found → Will configure from setup"
  fi

  # SSH Configuration
  if [ -f "$HOME/.ssh/config" ]; then
    DISCOVERED_CONFIGS["ssh_config"]="found"
    local host_count=$(grep -c "^Host " "$HOME/.ssh/config" 2>/dev/null || echo "0")
    CONFIG_DETAILS["ssh_config"]="$host_count host entries"
    ((found_count++))
    success "SSH configuration ($host_count hosts)"
  else
    DISCOVERED_CONFIGS["ssh_config"]="missing"
    CONFIG_DETAILS["ssh_config"]="Will use nix-darwin managed SSH config"
    ((missing_count++))
    info "SSH config not found → Will be managed by nix-darwin"
  fi

  # SSH known_hosts
  if [ -f "$HOME/.ssh/known_hosts" ]; then
    DISCOVERED_CONFIGS["ssh_known_hosts"]="found"
    local known_hosts_count=$(wc -l < "$HOME/.ssh/known_hosts" 2>/dev/null || echo "0")
    CONFIG_DETAILS["ssh_known_hosts"]="$known_hosts_count entries"
    ((found_count++))
    success "SSH known_hosts ($known_hosts_count entries)"
  else
    DISCOVERED_CONFIGS["ssh_known_hosts"]="missing"
    CONFIG_DETAILS["ssh_known_hosts"]="Will be populated as you connect"
    info "SSH known_hosts not found → Will be created on first use"
  fi

  # VS Code Extensions
  if [ -d "$HOME/.vscode/extensions" ] || [ -d "$HOME/Library/Application Support/Code/User/extensions" ]; then
    DISCOVERED_CONFIGS["vscode"]="found"
    local ext_count=0

    if [ -d "$HOME/.vscode/extensions" ]; then
      ext_count=$(find "$HOME/.vscode/extensions" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      ext_count=$((ext_count - 1))  # Subtract parent dir
    elif [ -d "$HOME/Library/Application Support/Code/User/extensions" ]; then
      ext_count=$(find "$HOME/Library/Application Support/Code/User/extensions" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      ext_count=$((ext_count - 1))
    fi

    CONFIG_DETAILS["vscode"]="$ext_count extensions"
    ((found_count++))
    success "VS Code extensions ($ext_count extensions)"
  else
    DISCOVERED_CONFIGS["vscode"]="missing"
    CONFIG_DETAILS["vscode"]="Will be installed from vscode.nix"
    ((missing_count++))
    info "VS Code extensions not found → Will install from config"
  fi

  # VS Code Settings
  if [ -f "$HOME/Library/Application Support/Code/User/settings.json" ]; then
    DISCOVERED_CONFIGS["vscode_settings"]="found"
    CONFIG_DETAILS["vscode_settings"]="Custom settings file exists"
    ((found_count++))
    success "VS Code settings.json"
  else
    DISCOVERED_CONFIGS["vscode_settings"]="missing"
    CONFIG_DETAILS["vscode_settings"]="Will use default VS Code settings"
    info "VS Code settings not found → Will use defaults"
  fi

  # Starship Configuration
  if [ -f "$HOME/.config/starship.toml" ]; then
    DISCOVERED_CONFIGS["starship"]="found"
    CONFIG_DETAILS["starship"]="Custom starship config"
    ((found_count++))
    success "Starship configuration"
  else
    DISCOVERED_CONFIGS["starship"]="missing"
    CONFIG_DETAILS["starship"]="Will use nix-darwin managed starship"
    info "Starship config not found → Will use nix-darwin config"
  fi

  # Zsh custom plugins/themes
  if [ -d "$HOME/.oh-my-zsh/custom" ]; then
    DISCOVERED_CONFIGS["zsh_custom"]="found"
    local custom_count=$(find "$HOME/.oh-my-zsh/custom" -mindepth 1 -maxdepth 1 -type f -o -type d 2>/dev/null | wc -l | tr -d ' ')
    CONFIG_DETAILS["zsh_custom"]="$custom_count custom items"
    ((found_count++))
    success "Zsh custom plugins/themes ($custom_count items)"
  else
    DISCOVERED_CONFIGS["zsh_custom"]="missing"
    CONFIG_DETAILS["zsh_custom"]="Oh-My-Zsh not installed or no custom items"
    info "Zsh custom not found → Will use nix-darwin shell config"
  fi

  # Homebrew packages (informational only)
  if command -v brew &>/dev/null; then
    DISCOVERED_CONFIGS["homebrew"]="found"
    local brew_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    local cask_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
    CONFIG_DETAILS["homebrew"]="$brew_count formulas, $cask_count casks"
    ((found_count++))
    success "Homebrew packages ($brew_count formulas, $cask_count casks)"
  else
    DISCOVERED_CONFIGS["homebrew"]="missing"
    CONFIG_DETAILS["homebrew"]="Will be installed by nix-darwin"
    info "Homebrew not found → Will be managed by nix-darwin"
  fi

  # Project directories (work profile specific)
  if [ -d "$HOME/Dev" ]; then
    DISCOVERED_CONFIGS["dev_projects"]="found"
    local project_count=$(find "$HOME/Dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    CONFIG_DETAILS["dev_projects"]="$project_count projects in ~/Dev"
    ((found_count++))
    success "Development projects ($project_count in ~/Dev)"
  else
    DISCOVERED_CONFIGS["dev_projects"]="missing"
    CONFIG_DETAILS["dev_projects"]="No ~/Dev directory"
    info "~/Dev not found → Will be created if needed"
  fi

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}Discovery Summary:${NC}"
  echo -e "${GREEN}✅ $found_count configurations found${NC}"
  echo -e "${YELLOW}⚠️  $missing_count configurations missing (will use defaults)${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  return 0
}

backup_discovered_configs() {
  print_step "📦 Backing Up Discovered Configurations"

  if [ -z "$BACKUP_DIR" ]; then
    warning "No backup directory set, skipping config backup"
    return 0
  fi

  local backup_count=0

  info "Backing up discovered configurations..."
  echo ""

  # AWS config (non-secret files)
  if [ "${DISCOVERED_CONFIGS[aws]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/aws"

    # Main config file (includes SSO sessions and profiles)
    if [ -f "$HOME/.aws/config" ]; then
      cp "$HOME/.aws/config" "$BACKUP_DIR/configs/aws/"
      ((backup_count++))
    fi

    # Accounts registry (custom accounts.json)
    if [ -f "$HOME/.aws/accounts.json" ]; then
      cp "$HOME/.aws/accounts.json" "$BACKUP_DIR/configs/aws/"
      ((backup_count++))
    fi

    # SSO cache directory (session tokens - can be regenerated, but backup for convenience)
    if [ -d "$HOME/.aws/sso/cache" ]; then
      mkdir -p "$BACKUP_DIR/configs/aws/sso"
      cp -r "$HOME/.aws/sso/cache" "$BACKUP_DIR/configs/aws/sso/" 2>/dev/null || true
      info "  SSO cache backed up (can be regenerated)"
    fi

    # CLI cache (optional, can be regenerated)
    if [ -d "$HOME/.aws/cli/cache" ]; then
      mkdir -p "$BACKUP_DIR/configs/aws/cli"
      cp -r "$HOME/.aws/cli/cache" "$BACKUP_DIR/configs/aws/cli/" 2>/dev/null || true
    fi

    # Last selected profile (if exists)
    if [ -f "$HOME/.aws/.last_profile" ]; then
      cp "$HOME/.aws/.last_profile" "$BACKUP_DIR/configs/aws/"
      ((backup_count++))
    fi

    success "AWS configuration (including SSO sessions)"
  fi

  # Git config
  if [ "${DISCOVERED_CONFIGS[git]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/git"
    git config --global --list > "$BACKUP_DIR/configs/git/global-config.txt" 2>/dev/null && ((backup_count++))
    success "Git configuration"
  fi

  # SSH config
  if [ "${DISCOVERED_CONFIGS[ssh_config]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/ssh"
    cp "$HOME/.ssh/config" "$BACKUP_DIR/configs/ssh/" 2>/dev/null && ((backup_count++))
    success "SSH configuration"
  fi

  # SSH known_hosts
  if [ "${DISCOVERED_CONFIGS[ssh_known_hosts]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/ssh"
    cp "$HOME/.ssh/known_hosts" "$BACKUP_DIR/configs/ssh/" 2>/dev/null && ((backup_count++))
    success "SSH known_hosts"
  fi

  # VS Code settings
  if [ "${DISCOVERED_CONFIGS[vscode_settings]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/vscode"
    cp "$HOME/Library/Application Support/Code/User/settings.json" "$BACKUP_DIR/configs/vscode/" 2>/dev/null && ((backup_count++))
    success "VS Code settings"
  fi

  # VS Code extensions list
  if [ "${DISCOVERED_CONFIGS[vscode]}" = "found" ] && command -v code &>/dev/null; then
    mkdir -p "$BACKUP_DIR/configs/vscode"
    code --list-extensions > "$BACKUP_DIR/configs/vscode/extensions.txt" 2>/dev/null && ((backup_count++))
    success "VS Code extensions list"
  fi

  # Starship config
  if [ "${DISCOVERED_CONFIGS[starship]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/starship"
    cp "$HOME/.config/starship.toml" "$BACKUP_DIR/configs/starship/" 2>/dev/null && ((backup_count++))
    success "Starship configuration"
  fi

  # Zsh custom
  if [ "${DISCOVERED_CONFIGS[zsh_custom]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/zsh"
    cp -r "$HOME/.oh-my-zsh/custom" "$BACKUP_DIR/configs/zsh/" 2>/dev/null && ((backup_count++))
    success "Zsh custom plugins/themes"
  fi

  # Homebrew package lists
  if [ "${DISCOVERED_CONFIGS[homebrew]}" = "found" ]; then
    mkdir -p "$BACKUP_DIR/configs/homebrew"
    brew list --formula > "$BACKUP_DIR/configs/homebrew/formulas.txt" 2>/dev/null && ((backup_count++))
    brew list --cask > "$BACKUP_DIR/configs/homebrew/casks.txt" 2>/dev/null && ((backup_count++))
    success "Homebrew package lists"
  fi

  echo ""
  if [ $backup_count -gt 0 ]; then
    success "✅ Backed up $backup_count configuration file(s)"
  else
    info "No configurations backed up"
  fi
  echo ""
}

# ============================================================================
# SECRET MIGRATION
# ============================================================================

migrate_secrets() {
  local target_secrets_file="$REPO_ROOT/hosts/$MACHINE_ID/secrets.yaml"

  print_step "📝 Secrets Migration"

  # SECRET MIGRATION WARNING CHECKPOINT
  cat <<EOF

⚠️  ${BOLD}SECRET MIGRATION CHECKPOINT${NC}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

About to migrate your secrets to encrypted storage.

✅ ${BOLD}Safety measures in place:${NC}
  • Full backup: ${BACKUP_DIR:-(none - will create)}
  • Original files will be kept (not deleted)
  • Can restore anytime: ./setup.sh --restore-backup
  • Can resume if interrupted: ./setup.sh --resume

⏸️  ${BOLD}Safe to interrupt (Ctrl+C) at any time${NC}
  • Progress saved automatically
  • Backup remains intact
  • No data loss

Secrets to migrate: ${#DISCOVERED_SECRETS[@]} file(s)
Estimated time: 1-2 minutes

EOF

  read -p "Continue with migration? [yes/no]: " migration_confirm
  if [ "$migration_confirm" != "yes" ]; then
    warning "Migration skipped by user"
    return 0
  fi
  echo ""

  echo "Migrate options:"
  echo "  1) Migrate all discovered secrets"
  echo "  2) Review and select individually"
  echo "  3) Skip migration"
  read -p "Select [1-3]: " migrate_choice

  case $migrate_choice in
    1)
      for secret_key in "${!DISCOVERED_SECRETS[@]}"; do
        SELECTED_SECRETS["$secret_key"]="${DISCOVERED_SECRETS[$secret_key]}"
      done
      ;;
    2)
      info "Review each secret individually..."
      echo ""
      for secret_key in "${!DISCOVERED_SECRETS[@]}"; do
        echo "Secret: ${DISCOVERED_SECRETS[$secret_key]}"
        read -p "  Migrate? [Y/n]: " migrate_this
        if [[ ! $migrate_this =~ ^[Nn]$ ]]; then
          SELECTED_SECRETS["$secret_key"]="${DISCOVERED_SECRETS[$secret_key]}"
          success "  Will migrate"
        else
          info "  Skipped"
        fi
        echo ""
      done
      ;;
    3)
      info "Skipping secrets migration"
      return 0
      ;;
    *)
      error "Invalid choice"
      exit 1
      ;;
  esac

  if [ ${#SELECTED_SECRETS[@]} -eq 0 ]; then
    info "No secrets selected"
    return 0
  fi

  echo ""
  info "Creating secrets.yaml..."
  echo ""

  if [ "$DRY_RUN" = "yes" ]; then
    info "[DRY RUN] Would create: $target_secrets_file"
    for secret_key in "${!SELECTED_SECRETS[@]}"; do
      local secret_file="${SELECTED_SECRETS[$secret_key]}"
      if [ -f "$secret_file" ]; then
        success "  [DRY RUN] $secret_key → would be added"
      fi
    done
    echo ""
    info "[DRY RUN] Would encrypt with SOPS"
    success "[DRY RUN] Would verify binary format"
    success "[DRY RUN] Would verify decryption"
  else
    mkdir -p "$(dirname "$target_secrets_file")"

    # Create secrets file
    cat > "$target_secrets_file" <<EOF
# Encrypted secrets for $MACHINE_ID
# Edit with: sops $target_secrets_file
# Generated: $(date)

EOF

    for secret_key in "${!SELECTED_SECRETS[@]}"; do
      local secret_file="${SELECTED_SECRETS[$secret_key]}"
      if [ -f "$secret_file" ]; then
        echo "# $secret_key" >> "$target_secrets_file"
        echo "${secret_key}: |" >> "$target_secrets_file"
        sed "s/^/  /" "$secret_file" >> "$target_secrets_file"
        echo "" >> "$target_secrets_file"
        success "  $secret_key → added"
      fi
    done

    echo ""
    info "Encrypting with SOPS..."

    if sops -e -i "$target_secrets_file"; then
      success "Encrypted successfully"
    else
      error "SOPS encryption failed!"
      exit 1
    fi

    # Verify binary format
    if ! file "$target_secrets_file" | grep -q "data"; then
      error "Not encrypted (plaintext detected)!"
      exit 1
    fi

    success "Verified: binary encrypted format"

    # Test decryption
    if sops -d "$target_secrets_file" > /dev/null 2>&1; then
      success "Decryption verified"
    else
      error "Cannot decrypt!"
      exit 1
    fi
  fi

  echo ""
}

# ============================================================================
# MACHINE CONFIGURATION
# ============================================================================

configure_machine() {
  print_step "⚙️  Machine Configuration"

  if [ "$DRY_RUN" = "yes" ]; then
    info "[DRY RUN] Would create config/user-config.nix with:"
    echo "  username: $USERNAME"
    echo "  fullName: $FULL_NAME"
    echo "  email: $EMAIL"
    echo ""

    info "[DRY RUN] Would create config/machine-config.nix with:"
    echo "  machineId: $MACHINE_ID"
    echo "  machineType: $MACHINE_TYPE"
    echo "  description: $MACHINE_DESCRIPTION"
    echo "  mixins: $MIXINS"
    echo "  system: $SYSTEM_ARCH"
    echo ""

    if [ ! -d "$REPO_ROOT/hosts/$MACHINE_ID" ]; then
      info "[DRY RUN] Would create hosts/$MACHINE_ID/"
    fi
  else
    mkdir -p "$REPO_ROOT/config"

    # 1. user-config.nix
    cat > "$REPO_ROOT/config/user-config.nix" <<EOF
{
  username = "$USERNAME";
  fullName = "$FULL_NAME";
  email = "$EMAIL";
}
EOF

    success "Created config/user-config.nix"

    # 2. machine-config.nix
    cat > "$REPO_ROOT/config/machine-config.nix" <<EOF
{
  machineId = "$MACHINE_ID";
  machineType = "$MACHINE_TYPE";
  description = "$MACHINE_DESCRIPTION";
  expectedHostname = "$(hostname)";
  mixins = $MIXINS;
  system = "$SYSTEM_ARCH";
}
EOF

    success "Created config/machine-config.nix"

    # 3. Create hosts directory if needed
    if [ ! -d "$REPO_ROOT/hosts/$MACHINE_ID" ]; then
      mkdir -p "$REPO_ROOT/hosts/$MACHINE_ID"

      # Copy from template if available
      if [ -f "$REPO_ROOT/hosts/_template/default.nix" ]; then
        cp "$REPO_ROOT/hosts/_template/default.nix" "$REPO_ROOT/hosts/$MACHINE_ID/"
        sed -i.bak "s/REPLACE_WITH_COMPUTER_NAME/$MACHINE_DESCRIPTION/g" "$REPO_ROOT/hosts/$MACHINE_ID/default.nix" 2>/dev/null && rm -f "$REPO_ROOT/hosts/$MACHINE_ID/default.nix.bak" || true
      fi

      success "Created hosts/$MACHINE_ID/"
    fi
  fi

  echo ""
}

# ============================================================================
# FLOW IMPLEMENTATIONS
# ============================================================================

flow_restore() {
  print_header "🔄 Restore Flow"
  info "Restoring configuration from encrypted secrets"
  echo ""

  # Handle multiple secrets files
  local target_secrets=""

  if [ ${#SECRETS_FILES[@]} -gt 1 ]; then
    echo "Found multiple encrypted secrets:"
    local i=1
    for file in "${SECRETS_FILES[@]}"; do
      local machine_name=$(echo "$file" | sed "s|.*/hosts/||;s|/secrets.yaml||")
      echo "  $i) $machine_name"
      ((i++))
    done
    echo "  $i) None (new machine)"
    echo ""

    read -p "Which machine are you setting up? [1-$i]: " machine_choice

    if [ "$machine_choice" -le "${#SECRETS_FILES[@]}" ]; then
      target_secrets="${SECRETS_FILES[$((machine_choice-1))]}"
      local detected_id=$(echo "$target_secrets" | sed "s|.*/hosts/||;s|/secrets.yaml||")

      info "Using secrets for: $detected_id"
      echo ""

      read -p "Use this machine ID? [Y/n]: " use_detected
      if [[ ! $use_detected =~ ^[Nn]$ ]]; then
        MACHINE_ID="$detected_id"
        info "Machine ID set to: $MACHINE_ID"
        echo ""
      fi
    else
      flow_fresh
      return
    fi
  else
    target_secrets="${SECRETS_FILES[0]}"
  fi

  # Restore or verify SOPS key
  if [ "$SOPS_KEY_EXISTS" = "yes" ]; then
    info "Testing existing age key..."

    if sops -d "$target_secrets" > /dev/null 2>&1; then
      success "Can decrypt with existing key"
    else
      error "Existing key cannot decrypt secrets!"
      echo ""
      warning "Need to restore correct key"

      # Backup existing key
      local backup_file="${AGE_KEY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
      cp "$AGE_KEY_FILE" "$backup_file"
      warning "Backed up existing key: $backup_file"
      echo ""

      SOPS_KEY_EXISTS="no"
    fi
  fi

  if [ "$SOPS_KEY_EXISTS" = "no" ]; then
    restore_sops_key

    # Verify can decrypt
    info "Verifying decryption..."
    if sops -d "$target_secrets" > /dev/null 2>&1; then
      success "Can decrypt secrets"
    else
      error "Cannot decrypt with restored key!"
      echo ""
      echo "This means:"
      echo "  • Wrong key restored, OR"
      echo "  • Secrets encrypted with different key"
      exit 1
    fi
  fi

  echo ""

  # Gather remaining info if needed
  if [ -z "$MACHINE_ID" ]; then
    gather_user_info
  fi

  # Configure machine
  configure_machine

  print_header "✅ Restore Complete"
  success "SOPS key verified"
  success "Secrets can be decrypted"
  success "Machine configured"
}

flow_migrate() {
  print_header "📦 Migrate Flow"
  info "Migrating local secrets to nix-darwin"
  echo ""

  # Phase 1: Create backup BEFORE any changes
  if [ "$LOCAL_SECRETS_FOUND" = "yes" ] && [ -z "$BACKUP_DIR" ]; then
    CURRENT_PHASE="backup"
    create_backup
  fi

  # Phase 2: Generate SOPS key if needed
  CURRENT_PHASE="sops_key_generation"
  if [ "$SOPS_KEY_EXISTS" = "no" ]; then
    generate_sops_key
  else
    success "Using existing age key"
    echo ""
  fi

  # Phase 3: Gather user info
  CURRENT_PHASE="user_info"
  gather_user_info

  # Phase 4: Discover configurations
  CURRENT_PHASE="config_discovery"
  discover_configs
  backup_discovered_configs

  # Phase 5: Discover and migrate secrets
  CURRENT_PHASE="secret_migration"
  if discover_secrets; then
    migrate_secrets
  else
    warning "No secrets to migrate"
  fi

  # Phase 6: Configure machine
  CURRENT_PHASE="machine_config"
  configure_machine

  # Cleanup state on successful completion
  cleanup_state

  print_header "✅ Migration Complete"
  success "Local secrets encrypted"
  success "Machine configured"
}

flow_fresh() {
  print_header "🆕 Fresh Setup Flow"
  info "Setting up new machine"
  echo ""

  # Generate SOPS key for future use
  if [ "$SOPS_KEY_EXISTS" = "no" ]; then
    generate_sops_key
  else
    success "Using existing age key"
    echo ""
  fi

  # Gather user info
  gather_user_info

  # Configure machine (no secrets)
  configure_machine

  print_header "✅ Fresh Setup Complete"
  success "SOPS ready for future secrets"
  success "Machine configured"
  info "Add secrets later: sops hosts/$MACHINE_ID/secrets.yaml"
}

flow_hybrid_merge() {
  print_header "🔀 Hybrid Merge Flow"
  info "Merging encrypted secrets with local secrets"
  echo ""

  # First do restore flow (partial)
  flow_restore

  echo ""
  info "Now discovering additional local secrets..."
  echo ""

  # Discover local secrets
  if ! discover_secrets; then
    warning "No additional local secrets found"
    return
  fi

  # Merge them
  local target_secrets="$REPO_ROOT/hosts/$MACHINE_ID/secrets.yaml"
  local temp_file=$(mktemp)

  info "Decrypting existing secrets..."
  sops -d "$target_secrets" > "$temp_file"

  info "Merging new secrets..."
  echo ""

  local added_count=0
  for secret_key in "${!DISCOVERED_SECRETS[@]}"; do
    if ! grep -q "^${secret_key}:" "$temp_file"; then
      echo "${secret_key}: |" >> "$temp_file"
      sed "s/^/  /" "${DISCOVERED_SECRETS[$secret_key]}" >> "$temp_file"
      echo "" >> "$temp_file"
      success "  Added: $secret_key"
      ((added_count++))
    else
      info "  Skipped: $secret_key (already exists)"
    fi
  done

  if [ $added_count -gt 0 ]; then
    info "Re-encrypting merged secrets..."
    cp "$temp_file" "$target_secrets"
    sops -e -i "$target_secrets"
    success "Merged and re-encrypted"
  else
    info "No new secrets to add"
  fi

  rm -f "$temp_file"
  echo ""
}

flow_reconfigure() {
  print_header "🔧 Reconfigure Flow"
  warning "Machine already configured"
  echo ""

  info "Existing configuration:"
  if [ -f "$REPO_ROOT/config/machine-config.nix" ]; then
    cat "$REPO_ROOT/config/machine-config.nix"
  fi

  echo ""
  echo "Options:"
  echo "  1) Update configuration"
  echo "  2) Skip (exit)"
  echo "  3) Force reconfigure (delete and recreate)"
  read -p "Select [1-3]: " reconfig_choice

  case $reconfig_choice in
    1)
      gather_user_info
      configure_machine
      success "Configuration updated"
      ;;
    2)
      info "Exiting without changes"
      exit 0
      ;;
    3)
      warning "Deleting existing configuration..."
      rm -f "$REPO_ROOT/config/machine-config.nix"
      rm -f "$REPO_ROOT/config/user-config.nix"
      gather_user_info
      configure_machine
      success "Configuration recreated"
      ;;
    *)
      error "Invalid choice"
      exit 1
      ;;
  esac
}

# ============================================================================
# ROUTING LOGIC
# ============================================================================

route_to_flow() {
  print_step "🎯 Determining Setup Flow"

  # Explicit mode override
  if [ -n "$EXPLICIT_MODE" ]; then
    info "Using explicit mode: $EXPLICIT_MODE"
    case $EXPLICIT_MODE in
      migrate) flow_migrate; return ;;
      restore) flow_restore; return ;;
      fresh) flow_fresh; return ;;
      configure)
        gather_user_info
        configure_machine
        return
        ;;
    esac
  fi

  # Check for reconfiguration
  if [ "$MACHINE_CONFIG_EXISTS" = "yes" ] && [ "$FORCE_RECONFIG" != "yes" ]; then
    flow_reconfigure
    return
  fi

  # Auto-detect scenario
  if [ ${#SECRETS_FILES[@]} -gt 0 ]; then
    # Has encrypted secrets
    if [ "$LOCAL_SECRETS_FOUND" = "yes" ]; then
      # HYBRID
      info "Detected: Encrypted secrets AND local secrets"
      echo ""
      echo "What would you like to do?"
      echo "  1) Merge (restore encrypted + add local)"
      echo "  2) Use encrypted only"
      echo "  3) Use local only"
      read -p "Select [1-3]: " hybrid_choice

      case $hybrid_choice in
        1) flow_hybrid_merge ;;
        2) flow_restore ;;
        3) flow_migrate ;;
        *) error "Invalid choice"; exit 1 ;;
      esac
    else
      # RESTORE only
      info "Detected: Restore from backup/fork"
      flow_restore
    fi
  else
    # No encrypted secrets
    if [ "$LOCAL_SECRETS_FOUND" = "yes" ]; then
      # MIGRATE
      info "Detected: Migrate local secrets"
      flow_migrate
    else
      # FRESH
      info "Detected: Fresh setup"
      flow_fresh
    fi
  fi
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

show_help() {
  cat << EOF
Nix-Darwin User-Agnostic Setup Script v${SCRIPT_VERSION}

Usage:
  ./setup.sh [MODE]

Modes:
  (none)               Auto-detect scenario and guide user [DEFAULT]
  --migrate            Force: migrate local secrets
  --restore            Force: restore from encrypted secrets
  --fresh              Force: fresh setup (no secrets)
  --configure          Just machine configuration (alias: --configure-machine)
  --configure-machine  Same as --configure
  --force              Allow reconfiguration
  --dry-run           Test run without making changes
  --resume            Resume from interrupted setup
  --restore-backup    Restore from backup directory
  --help              Show this help

Auto-Detection:
  The script analyzes your environment and automatically determines
  the appropriate setup flow:

  • Restore: encrypted secrets.yaml exists
  • Migrate: local secrets found (~/.aws, ~/.ssh, etc.)
  • Fresh: no secrets found
  • Hybrid: both encrypted and local secrets

Safety Features:
  • Automatic backup before any changes
  • State tracking for resume capability
  • Graceful interrupt handling (Ctrl+C safe)
  • Warning checkpoints before critical operations
  • Restore capability from any point

Examples:
  ./setup.sh                          # Auto-detect and guide
  ./setup.sh --migrate                # Force migrate flow
  ./setup.sh --restore                # Force restore flow
  ./setup.sh --fresh                  # Force fresh setup
  ./setup.sh --configure-machine      # Just machine config
  ./setup.sh --force                  # Reconfigure existing
  ./setup.sh --resume                 # Resume interrupted setup
  ./setup.sh --restore-backup         # Restore latest backup
  ./setup.sh --restore-backup <path>  # Restore specific backup
  ./setup.sh --dry-run --migrate      # Test migration without changes

Recovery:
  If setup is interrupted:
    1. State is automatically saved
    2. Resume with: ./setup.sh --resume
    3. Or restore with: ./setup.sh --restore-backup

For more information:
  docs/guides/installation.md

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --migrate)
      EXPLICIT_MODE="migrate"
      shift
      ;;
    --restore)
      EXPLICIT_MODE="restore"
      shift
      ;;
    --fresh)
      EXPLICIT_MODE="fresh"
      shift
      ;;
    --configure|--configure-machine)
      EXPLICIT_MODE="configure"
      shift
      ;;
    --force)
      FORCE_RECONFIG="yes"
      shift
      ;;
    --dry-run)
      DRY_RUN="yes"
      shift
      ;;
    --resume)
      EXPLICIT_MODE="resume"
      shift
      ;;
    --restore-backup)
      restore_from_backup "$2"
      exit 0
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      echo ""
      show_help
      exit 1
      ;;
  esac
done

# Main execution
print_header "Nix-Darwin Setup Wizard v${SCRIPT_VERSION}"

if [ "$DRY_RUN" = "yes" ]; then
  warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

# Setup interrupt handler
setup_interrupt_handler

# Check for resume
check_for_resume

check_prerequisites
detect_environment
route_to_flow

echo ""
print_header "✅ Setup Complete"
echo ""
info "Next steps:"
echo "  1. Review configuration: config/machine-config.nix"
echo "  2. Update flake.nix to reference your machine"
echo "  3. Build: darwin-rebuild switch --flake ."
echo ""
