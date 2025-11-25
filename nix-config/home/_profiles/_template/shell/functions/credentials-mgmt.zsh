# secrets.zsh
# Secrets and credentials management functions
# Extracted from zsh.nix for maintainability

# ============================================
# HELPER: Get machine ID from config
# ============================================
__get_machine_id() {
  local config="$HOME/nix-darwin/config/machine-config.nix"
  if [[ -f "$config" ]]; then
    grep 'machineId =' "$config" | sed 's/.*"\(.*\)".*/\1/'
  fi
}

# ============================================
# SECRETS MANAGEMENT
# ============================================

# Edit encrypted secrets with sops (system-level)
function edit-secrets() {
  local nix_dir="$HOME/nix-darwin"
  local machine_config="$nix_dir/config/machine-config.nix"

  if [[ ! -f "$machine_config" ]]; then
    echo "❌ Error: machine config not found: $machine_config"
    echo "💡 Run setup.sh to create machine configuration"
    return 1
  fi

  local machine_id=$(__get_machine_id)
  if [[ -z "$machine_id" ]]; then
    echo "❌ Error: Could not extract machineId from config"
    return 1
  fi

  local secrets_file="$nix_dir/nix-config/hosts/$machine_id/secrets.yaml"

  if [[ ! -f "$secrets_file" ]]; then
    echo "❌ Error: secrets file not found: $secrets_file"
    echo ""
    echo "💡 To create encrypted secrets:"
    echo "  1. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt"
    echo "  2. Update .sops.yaml with your public key"
    echo "  3. Run: sops $secrets_file"
    return 1
  fi

  if ! command -v sops &> /dev/null; then
    echo "❌ Error: sops not found"
    return 1
  fi

  warn "Editing Encrypted Secrets" "INFO"
  echo "  • File will be decrypted temporarily"
  echo "  • Changes will be re-encrypted on save"
  echo ""

  echo "🔐 Opening: $secrets_file"
  sops "$secrets_file"
}

# Edit encrypted credentials (database passwords, etc.)
function edit-credentials() {
  local creds_dir="$HOME/.secrets"
  local encrypted_file="$creds_dir/credentials.env.enc"

  [[ ! -d "$creds_dir" ]] && { mkdir -p "$creds_dir"; chmod 700 "$creds_dir"; }

  if ! command -v sops &> /dev/null; then
    echo "❌ Error: sops not found"
    return 1
  fi

  if [[ ! -f ~/.config/sops/age/keys.txt ]]; then
    echo "❌ Error: Age key not found"
    echo "Generate with: age-keygen -o ~/.config/sops/age/keys.txt"
    return 1
  fi

  # Create template if doesn't exist
  if [[ ! -f "$encrypted_file" ]]; then
    echo "📝 Creating credentials template..."
    local temp_file=$(mktemp)
    cat > "$temp_file" << 'TEMPLATE'
# Credential Management
# Variables: <PROJECT>_<ENV>_<TYPE>
# Example: TI_PROD_PASSWORD

# ==== LAN CREDENTIALS ====
export LAN_USERNAME="your-lan-id"
export LAN_PASSWORD="your-lan-password"

# ==== ADD YOUR CREDENTIALS BELOW ====
TEMPLATE
    sops --encrypt "$temp_file" > "$encrypted_file"
    rm "$temp_file"
    echo "✅ Template created: $encrypted_file"
  fi

  echo "🔐 Opening credentials..."
  echo "💡 After editing, run: exec zsh"
  sops "$encrypted_file"
}

# Check secrets configuration status
function secrets-status() {
  echo "🔐 Secrets Management Status"
  echo "================================================"
  echo ""

  # Age key
  echo "🔑 Age Key:"
  if [[ -f ~/.config/sops/age/keys.txt ]]; then
    echo "  ✅ Age key exists"
    local pubkey=$(grep "public key:" ~/.config/sops/age/keys.txt | awk '{print $NF}')
    echo "  📌 Public key: $pubkey"
  else
    echo "  ❌ Age key not found"
    echo "     Generate: age-keygen -o ~/.config/sops/age/keys.txt"
  fi
  echo ""

  # SOPS config
  echo "⚙️  SOPS Configuration:"
  [[ -f ~/nix-darwin/secrets/.sops.yaml ]] && echo "  ✅ .sops.yaml exists" || echo "  ❌ .sops.yaml not found"
  echo ""

  # Secrets file
  local machine_id=$(__get_machine_id)
  local secrets_file="$HOME/nix-darwin/nix-config/hosts/$machine_id/secrets.yaml"

  echo "📄 Secrets File:"
  if [[ -n "$machine_id" && -f "$secrets_file" ]]; then
    echo "  ✅ $secrets_file exists"
    if file "$secrets_file" | grep -q "ASCII text"; then
      echo "  ⚠️  WARNING: File is NOT encrypted!"
    else
      echo "  ✅ File is encrypted"
    fi
  else
    echo "  ❌ Secrets file not found"
  fi
  echo ""

  # Tools
  echo "🔧 Tools:"
  command -v sops &>/dev/null && echo "  ✅ sops: $(sops --version 2>&1 | head -n1)" || echo "  ❌ sops not installed"
  command -v age &>/dev/null && echo "  ✅ age: $(age --version 2>&1)" || echo "  ❌ age not installed"
  echo ""

  # Active secrets
  echo "🔓 Active Secrets:"
  [[ -f ~/.zsh_secrets ]] && echo "  ✅ ~/.zsh_secrets" || echo "  ❌ ~/.zsh_secrets not found"
  [[ -f ~/.ssh/id_ed25519 ]] && echo "  ✅ ~/.ssh/id_ed25519" || echo "  ❌ SSH key not found"
  echo ""

  echo "💡 Commands: edit-secrets, edit-credentials, secrets-check"
}

# Validate all secrets are encrypted
function secrets-check() {
  local script="$HOME/nix-darwin/scripts/validation/check-secrets-encrypted.sh"
  if [[ -x "$script" ]]; then
    "$script"
  else
    echo "❌ Validation script not found: $script"
    return 1
  fi
}

# ============================================
# WORKSPACE BACKUP & RESTORE
# ============================================

function backup-workspace() {
  local script="$HOME/nix-darwin/scripts/workspace/backup.sh"
  if [[ ! -f "$script" ]]; then
    echo "❌ Backup script not found: $script"
    return 1
  fi
  bash "$script" "$@"
}

function restore-workspace() {
  local script="$HOME/nix-darwin/scripts/workspace/restore.sh"
  if [[ ! -f "$script" ]]; then
    echo "❌ Restore script not found: $script"
    return 1
  fi
  bash "$script" "$@"
}

function sync-workspace() {
  local script="$HOME/nix-darwin/scripts/workspace/sync.sh"
  if [[ ! -f "$script" ]]; then
    echo "❌ Sync script not found: $script"
    return 1
  fi
  bash "$script" "$@"
}

# ============================================
# SAFE NIX REBUILD WRAPPER
# ============================================
function nix-rebuild-confirm() {
  local nix_dir="$HOME/nix-darwin"

  warn "System Rebuild" "WARNING"
  echo "  • This will rebuild your entire system configuration"
  echo "  • Changes will be applied immediately"
  echo "  • Previous generation available via nix-rollback"
  echo ""

  if confirm "Proceed with rebuild?"; then
    echo ""
    echo "🔄 Running pre-flight checks..."
    if "$nix_dir/scripts/maintenance/pre-flight-checks.sh"; then
      echo ""
      echo "🏗️  Building darwin configuration..."
      sudo darwin-rebuild switch --flake "$nix_dir"
    else
      echo ""
      echo "❌ Pre-flight checks failed"
      return 1
    fi
  else
    echo "❌ Rebuild cancelled"
    return 1
  fi
}

# System health check
function nix-health() {
  local script="$HOME/nix-darwin/scripts/maintenance/health-check.sh"
  if [[ -x "$script" ]]; then
    "$script"
  else
    echo "❌ Health check script not found"
    return 1
  fi
}
