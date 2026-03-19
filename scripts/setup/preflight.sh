#!/usr/bin/env bash
# Nix-Darwin Pre-Flight Inspector
#
# Read-only diagnostic that checks system state and produces a numbered
# action plan. Designed for fresh clones, machine migrations, or any time
# you need to know "where am I in the setup pipeline?"
#
# Usage:
#   ./preflight.sh          # Run all checks
#   ./preflight.sh --json   # Machine-readable JSON output
#   ./preflight.sh --help   # Show help
#
# Exit codes:
#   0 - System is READY (all checks pass)
#   1 - Critical issues found (REQUIRED actions)
#   2 - Warnings only (RECOMMENDED/OPTIONAL actions)

# Do NOT set -e — every check must run even if earlier ones fail
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_VERSION="1.0.0"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
JSON_MODE=false

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Action plan (arrays of "PRIORITY|message" entries)
ACTIONS=()

# Detected system state
DETECTED_MACOS_VERSION=""
DETECTED_CHIP=""
DETECTED_ARCH=""
DETECTED_HOSTNAME=""
DETECTED_MODEL=""
DETECTED_MACHINE_ID=""
OVERALL_STAGE=""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
  if [ "$JSON_MODE" = true ]; then return; fi
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

print_step() {
  if [ "$JSON_MODE" = true ]; then return; fi
  echo ""
  echo -e "${BOLD}${BLUE}$1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

success() {
  ((PASS_COUNT++))
  if [ "$JSON_MODE" = true ]; then return; fi
  echo -e "${GREEN}  ✓ $1${NC}"
}

error() {
  ((FAIL_COUNT++))
  if [ "$JSON_MODE" = true ]; then return; fi
  echo -e "${RED}  ✗ $1${NC}"
}

warning() {
  ((WARN_COUNT++))
  if [ "$JSON_MODE" = true ]; then return; fi
  echo -e "${YELLOW}  ▸ $1${NC}"
}

info() {
  if [ "$JSON_MODE" = true ]; then return; fi
  echo -e "${DIM}    $1${NC}"
}

add_action() {
  local priority="$1"
  local message="$2"
  ACTIONS+=("${priority}|${message}")
}

# ============================================================================
# CHECK 1: SYSTEM DETECTION
# ============================================================================

check_system() {
  print_step "1. System Detection"

  # macOS version
  DETECTED_MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
  local macos_name=$(sw_vers -productName 2>/dev/null || echo "unknown")

  # Chip and architecture
  DETECTED_CHIP=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Chip' | awk -F': ' '{print $2}' | xargs)
  DETECTED_MODEL=$(system_profiler SPHardwareDataType 2>/dev/null | grep 'Model Name' | awk -F': ' '{print $2}' | xargs)

  if [[ "$DETECTED_CHIP" =~ "Apple" ]]; then
    DETECTED_ARCH="aarch64-darwin"
  else
    DETECTED_ARCH="x86_64-darwin"
  fi

  DETECTED_HOSTNAME=$(hostname | sed 's/\.local$//')

  # Generate expected machine ID (same logic as configure.sh)
  if [ -n "$DETECTED_MODEL" ] && [ -n "$DETECTED_CHIP" ]; then
    local model_lower=$(echo "$DETECTED_MODEL" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local chip_version=$(echo "$DETECTED_CHIP" | grep -o 'M[0-9]' | tr '[:upper:]' '[:lower:]')
    DETECTED_MACHINE_ID="${model_lower}-${chip_version}"
  fi

  success "$macos_name $DETECTED_MACOS_VERSION"
  success "$DETECTED_MODEL ($DETECTED_CHIP)"
  success "Architecture: $DETECTED_ARCH"
  success "Hostname: $DETECTED_HOSTNAME"
  success "Auto-detected machineId: $DETECTED_MACHINE_ID"
}

# ============================================================================
# CHECK 2: NIX STATUS
# ============================================================================

check_nix() {
  print_step "2. Nix Status"

  # Nix installed?
  if ! command -v nix &>/dev/null; then
    error "Nix is not installed"
    add_action "REQUIRED" "Install Nix: ./scripts/setup/bootstrap.sh"
    return
  fi

  local nix_version=$(nix --version 2>/dev/null | head -1)
  success "Nix installed: $nix_version"

  # Daemon running?
  if pgrep -x "nix-daemon" > /dev/null 2>&1; then
    success "Nix daemon is running"
  else
    error "Nix daemon is not running"
    add_action "REQUIRED" "Start Nix daemon: sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
  fi

  # Flakes enabled?
  if nix flake --help &>/dev/null; then
    success "Flakes enabled"
  else
    warning "Flakes may not be enabled"
    info "Check ~/.config/nix/nix.conf for: experimental-features = nix-command flakes"
    add_action "REQUIRED" "Enable flakes in ~/.config/nix/nix.conf: experimental-features = nix-command flakes"
  fi
}

# ============================================================================
# CHECK 3: NIX-DARWIN STATUS
# ============================================================================

check_nix_darwin() {
  print_step "3. Nix-Darwin Status"

  if command -v darwin-rebuild &>/dev/null; then
    success "darwin-rebuild is available"

    # Check current generation
    local current_gen=$(darwin-rebuild --list-generations 2>/dev/null | tail -1)
    if [ -n "$current_gen" ]; then
      success "Current generation: $current_gen"
    else
      warning "No generations found (fresh install?)"
    fi
  else
    warning "darwin-rebuild not found"
    info "Will be installed during first activation (activate.sh)"
    # Not required if this is a fresh clone — configure.sh comes first
  fi
}

# ============================================================================
# CHECK 4: REQUIRED TOOLS
# ============================================================================

check_tools() {
  print_step "4. Required Tools"

  local tools=("sops" "age" "age-keygen" "git")
  local missing_tools=()

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      local ver=""
      case "$tool" in
        git) ver=$(git --version 2>/dev/null | head -1) ;;
        sops) ver=$(sops --version 2>/dev/null | head -1) ;;
        age) ver=$(age --version 2>/dev/null | head -1) ;;
        age-keygen) ver="present" ;;
      esac
      success "$tool: $ver"
    else
      error "$tool: not found"
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    add_action "REQUIRED" "Install missing tools (${missing_tools[*]}): ./scripts/setup/bootstrap.sh"
  fi
}

# ============================================================================
# CHECK 5: AGE KEY
# ============================================================================

check_age_key() {
  print_step "5. Age Encryption Key"

  local age_key_file="$HOME/.config/sops/age/keys.txt"

  if [ ! -f "$age_key_file" ]; then
    error "Age key not found: $age_key_file"
    add_action "REQUIRED" "Generate age key: age-keygen -o ~/.config/sops/age/keys.txt"
    return
  fi

  success "Age key exists: $age_key_file"

  # Check permissions
  local perms=$(stat -f "%Lp" "$age_key_file" 2>/dev/null)
  if [ "$perms" = "600" ]; then
    success "Permissions: $perms (correct)"
  else
    warning "Permissions: $perms (should be 600)"
    add_action "RECOMMENDED" "Fix age key permissions: chmod 600 $age_key_file"
  fi

  # Extract public key from local key file
  local local_pubkey=$(grep "# public key:" "$age_key_file" 2>/dev/null | cut -d: -f2 | tr -d ' ')

  if [ -z "$local_pubkey" ]; then
    warning "Could not extract public key from age key file"
    return
  fi

  success "Public key: ${local_pubkey:0:20}..."

  # Check if it matches .sops.yaml
  local sops_yaml="$REPO_ROOT/.sops.yaml"
  if [ -f "$sops_yaml" ]; then
    if grep -q "$local_pubkey" "$sops_yaml" 2>/dev/null; then
      success "Public key matches .sops.yaml"
    else
      warning "Public key does NOT match .sops.yaml"
      info "Local key:  $local_pubkey"
      local sops_key=$(grep 'age1' "$sops_yaml" 2>/dev/null | grep -v '#' | head -1 | tr -d ' &*')
      if [ -n "$sops_key" ]; then
        info ".sops.yaml: $sops_key"
      fi
      # Smart suggestion based on whether secrets exist
      local has_secrets=false
      for host_dir in "$REPO_ROOT"/nix-config/hosts/*/; do
        if [ -f "${host_dir}secrets.yaml" ]; then
          has_secrets=true
          break
        fi
      done
      if [ "$has_secrets" = true ]; then
        add_action "REQUIRED" "Age key mismatch: secrets exist encrypted with a different key. Restore the matching private key from backup, or re-encrypt secrets with your current key"
      else
        add_action "RECOMMENDED" "Update .sops.yaml with your current public key: $local_pubkey"
      fi
    fi
  else
    warning ".sops.yaml not found in repo root"
    add_action "REQUIRED" "Create .sops.yaml or run configure.sh to generate it"
  fi
}

# ============================================================================
# CHECK 6: CONFIG FILES
# ============================================================================

check_config_files() {
  print_step "6. Configuration Files"

  local machine_config="$REPO_ROOT/config/machine-config.nix"
  local user_config="$REPO_ROOT/config/user-config.nix"

  # machine-config.nix
  if [ -f "$machine_config" ]; then
    success "config/machine-config.nix exists"

    # Check for valid field names
    if grep -q 'machineId' "$machine_config" 2>/dev/null; then
      local config_machine_id=$(grep 'machineId' "$machine_config" | cut -d '"' -f 2)
      success "machineId = \"$config_machine_id\""

      # Compare with detected machine ID (config includes profile suffix)
      if [ -n "$DETECTED_MACHINE_ID" ] && [[ "$config_machine_id" != "$DETECTED_MACHINE_ID"* ]]; then
        warning "machineId doesn't match detected hardware: $DETECTED_MACHINE_ID"
        info "This is OK if you intentionally chose a different ID"
      fi
    else
      error "machineId field not found in machine-config.nix"
      add_action "REQUIRED" "Add machineId field to config/machine-config.nix"
    fi

    # Check for legacy field names
    if grep -q 'machineType' "$machine_config" 2>/dev/null; then
      error "Legacy field 'machineType' found (renamed to 'profileName')"
      add_action "REQUIRED" "Rename 'machineType' to 'profileName' in config/machine-config.nix"
    fi

    # Check for placeholder values
    if grep -q 'CHANGE-ME' "$machine_config" 2>/dev/null; then
      error "Placeholder values (CHANGE-ME) still present"
      add_action "REQUIRED" "Replace placeholder values in config/machine-config.nix (run configure.sh or edit manually)"
    fi

    # Check profileName
    if grep -q 'profileName' "$machine_config" 2>/dev/null; then
      local profile=$(grep 'profileName' "$machine_config" | cut -d '"' -f 2)
      success "profileName = \"$profile\""
    fi
  else
    error "config/machine-config.nix not found"
    info "Template available: config/machine-config.nix.template"
    add_action "REQUIRED" "Create config/machine-config.nix: run ./scripts/setup/configure.sh"
  fi

  # user-config.nix
  if [ -f "$user_config" ]; then
    success "config/user-config.nix exists"

    # Check for placeholder values
    if grep -q 'REPLACE_' "$user_config" 2>/dev/null; then
      error "Placeholder values (REPLACE_*) still present"
      add_action "REQUIRED" "Replace placeholder values in config/user-config.nix (run configure.sh or edit manually)"
    else
      local username=$(grep 'username' "$user_config" | head -1 | cut -d '"' -f 2)
      if [ -n "$username" ]; then
        success "username = \"$username\""
      fi
    fi
  else
    error "config/user-config.nix not found"
    info "Template available: config/user-config.nix.template"
    add_action "REQUIRED" "Create config/user-config.nix: run ./scripts/setup/configure.sh"
  fi
}

# ============================================================================
# CHECK 7: HOST DIRECTORY
# ============================================================================

check_host_directory() {
  print_step "7. Host Directory"

  # Determine which machine ID to check
  local machine_id=""
  local machine_config="$REPO_ROOT/config/machine-config.nix"

  if [ -f "$machine_config" ]; then
    machine_id=$(grep 'machineId' "$machine_config" 2>/dev/null | cut -d '"' -f 2)
  fi

  if [ -z "$machine_id" ] || [ "$machine_id" = "CHANGE-ME" ]; then
    # Fall back to auto-detected
    machine_id="$DETECTED_MACHINE_ID"
    if [ -z "$machine_id" ]; then
      warning "Cannot determine machineId — skipping host directory check"
      return
    fi
    info "Using auto-detected machineId: $machine_id"
  fi

  local host_dir="$REPO_ROOT/nix-config/hosts/$machine_id"

  if [ -d "$host_dir" ]; then
    success "nix-config/hosts/$machine_id/ exists"

    # Check for required files
    if [ -f "$host_dir/default.nix" ]; then
      success "default.nix present"
    else
      error "default.nix missing"
      add_action "REQUIRED" "Create nix-config/hosts/$machine_id/default.nix (copy from _template)"
    fi

    # Check for profile-specific secrets module
    local profile=""
    if [ -f "$machine_config" ]; then
      profile=$(grep 'profileName' "$machine_config" 2>/dev/null | cut -d '"' -f 2)
    fi
    if [ -n "$profile" ] && [ "$profile" != "minimal" ]; then
      if [ -f "$host_dir/secrets-${profile}.nix" ]; then
        success "secrets-${profile}.nix present"
      else
        warning "secrets-${profile}.nix not found (may be OK if secrets are in default.nix)"
      fi
    fi
  else
    error "nix-config/hosts/$machine_id/ not found"
    info "Available hosts:"
    for d in "$REPO_ROOT"/nix-config/hosts/*/; do
      local dirname=$(basename "$d")
      if [ "$dirname" != "_template" ]; then
        info "  - $dirname"
      fi
    done
    add_action "REQUIRED" "Create host directory: run ./scripts/setup/configure.sh or copy from _template"
  fi
}

# ============================================================================
# CHECK 8: SECRETS
# ============================================================================

check_secrets() {
  print_step "8. Secrets"

  local machine_id=""
  local machine_config="$REPO_ROOT/config/machine-config.nix"

  if [ -f "$machine_config" ]; then
    machine_id=$(grep 'machineId' "$machine_config" 2>/dev/null | cut -d '"' -f 2)
  fi

  if [ -z "$machine_id" ] || [ "$machine_id" = "CHANGE-ME" ]; then
    machine_id="$DETECTED_MACHINE_ID"
  fi

  if [ -z "$machine_id" ]; then
    warning "Cannot determine machineId — skipping secrets check"
    return
  fi

  local secrets_file="$REPO_ROOT/nix-config/hosts/$machine_id/secrets.yaml"

  if [ ! -f "$secrets_file" ]; then
    warning "No secrets.yaml found for $machine_id"
    info "Secrets will be created during configure.sh"
    return
  fi

  success "secrets.yaml exists"

  # Check if encrypted
  if grep -q "sops:" "$secrets_file" 2>/dev/null && grep -q "mac:" "$secrets_file" 2>/dev/null; then
    success "secrets.yaml is encrypted (SOPS)"

    # Try to decrypt
    if command -v sops &>/dev/null; then
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      if sops -d "$secrets_file" > /dev/null 2>&1; then
        success "Decryption successful with current age key"
      else
        error "Cannot decrypt with current age key"
        add_action "REQUIRED" "Secrets are encrypted with a different key. Restore matching private key from backup, or re-encrypt with current key"
      fi
    else
      warning "sops not installed — cannot verify decryption"
    fi
  else
    warning "secrets.yaml appears to be plaintext (not encrypted)"
    add_action "RECOMMENDED" "Encrypt secrets: sops -e -i $secrets_file"
  fi
}

# ============================================================================
# CHECK 9: FLAKE HEALTH
# ============================================================================

check_flake() {
  print_step "9. Flake Health"

  if [ ! -f "$REPO_ROOT/flake.nix" ]; then
    error "flake.nix not found"
    add_action "REQUIRED" "Repository may be incomplete — ensure you cloned the correct repo"
    return
  fi
  success "flake.nix exists"

  if [ ! -f "$REPO_ROOT/flake.lock" ]; then
    warning "flake.lock not found"
    add_action "RECOMMENDED" "Generate lock file: nix flake update (in repo root)"
  else
    success "flake.lock exists"
  fi

  # Try nix flake metadata (quick syntax/structure check)
  if command -v nix &>/dev/null; then
    if nix flake metadata "$REPO_ROOT" --no-write-lock-file &>/dev/null 2>&1; then
      success "Flake metadata valid"
    else
      error "Flake metadata check failed"
      info "Run: nix flake check --show-trace"
      add_action "REQUIRED" "Fix flake errors: nix flake check --show-trace"
    fi
  else
    warning "Nix not installed — cannot validate flake"
  fi
}

# ============================================================================
# CHECK 10: OVERALL STAGE
# ============================================================================

determine_stage() {
  print_step "10. Overall Stage"

  local has_nix=false
  local has_config=false
  local has_host=false
  local is_ready=false

  command -v nix &>/dev/null && has_nix=true

  local machine_config="$REPO_ROOT/config/machine-config.nix"
  if [ -f "$machine_config" ] && ! grep -q 'CHANGE-ME' "$machine_config" 2>/dev/null; then
    has_config=true
  fi

  # Determine machine ID for host check
  local machine_id=""
  if [ -f "$machine_config" ]; then
    machine_id=$(grep 'machineId' "$machine_config" 2>/dev/null | cut -d '"' -f 2)
  fi
  if [ -n "$machine_id" ] && [ "$machine_id" != "CHANGE-ME" ] && [ -d "$REPO_ROOT/nix-config/hosts/$machine_id" ]; then
    has_host=true
  fi

  if [ "$FAIL_COUNT" -eq 0 ] && [ "$has_nix" = true ] && [ "$has_config" = true ] && [ "$has_host" = true ]; then
    is_ready=true
  fi

  if [ "$is_ready" = true ]; then
    OVERALL_STAGE="READY"
  elif [ "$has_config" = true ] && [ "$has_host" = true ]; then
    OVERALL_STAGE="CONFIGURED"
  elif [ "$has_nix" = true ]; then
    OVERALL_STAGE="BOOTSTRAPPED"
  else
    OVERALL_STAGE="FRESH_CLONE"
  fi

  if [ "$JSON_MODE" = true ]; then return; fi

  local stage_color
  case "$OVERALL_STAGE" in
    READY)        stage_color="$GREEN" ;;
    CONFIGURED)   stage_color="$YELLOW" ;;
    BOOTSTRAPPED) stage_color="$YELLOW" ;;
    FRESH_CLONE)  stage_color="$RED" ;;
  esac

  echo -e "  Stage: ${BOLD}${stage_color}${OVERALL_STAGE}${NC}"
  echo ""

  case "$OVERALL_STAGE" in
    FRESH_CLONE)
      info "Pipeline: [bootstrap.sh] -> configure.sh -> activate.sh" ;;
    BOOTSTRAPPED)
      info "Pipeline: bootstrap.sh -> [configure.sh] -> activate.sh" ;;
    CONFIGURED)
      info "Pipeline: bootstrap.sh -> configure.sh -> [activate.sh]" ;;
    READY)
      info "System is ready. Use: nix-rebuild && exec zsh" ;;
  esac
}

# ============================================================================
# OUTPUT: ACTION PLAN
# ============================================================================

print_action_plan() {
  if [ "$JSON_MODE" = true ]; then return; fi

  if [ ${#ACTIONS[@]} -eq 0 ]; then
    print_header "No Actions Required"
    echo -e "  ${GREEN}System is fully configured and ready.${NC}"
    echo ""
    return
  fi

  print_header "Action Plan"

  local num=1

  # REQUIRED actions first
  for action in "${ACTIONS[@]}"; do
    local priority="${action%%|*}"
    local message="${action#*|}"
    if [ "$priority" = "REQUIRED" ]; then
      echo -e "  ${RED}${num}. [REQUIRED]${NC} $message"
      ((num++))
    fi
  done

  # RECOMMENDED actions
  for action in "${ACTIONS[@]}"; do
    local priority="${action%%|*}"
    local message="${action#*|}"
    if [ "$priority" = "RECOMMENDED" ]; then
      echo -e "  ${YELLOW}${num}. [RECOMMENDED]${NC} $message"
      ((num++))
    fi
  done

  # OPTIONAL actions
  for action in "${ACTIONS[@]}"; do
    local priority="${action%%|*}"
    local message="${action#*|}"
    if [ "$priority" = "OPTIONAL" ]; then
      echo -e "  ${CYAN}${num}. [OPTIONAL]${NC} $message"
      ((num++))
    fi
  done

  echo ""
}

# ============================================================================
# OUTPUT: SUMMARY
# ============================================================================

print_summary() {
  if [ "$JSON_MODE" = true ]; then return; fi

  print_header "Summary"

  echo -e "  ${GREEN}Passed:   $PASS_COUNT${NC}"
  if [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}Warnings: $WARN_COUNT${NC}"
  fi
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Failed:   $FAIL_COUNT${NC}"
  fi
  echo ""
}

# ============================================================================
# OUTPUT: JSON
# ============================================================================

print_json() {
  if [ "$JSON_MODE" != true ]; then return; fi

  # Build actions JSON array
  local actions_json=""
  local first=true
  for action in "${ACTIONS[@]}"; do
    local priority="${action%%|*}"
    local message="${action#*|}"
    # Escape quotes in message
    message=$(printf '%s' "$message" | sed 's/"/\\"/g')
    if [ "$first" = true ]; then
      first=false
    else
      actions_json="$actions_json,"
    fi
    actions_json="$actions_json{\"priority\":\"$priority\",\"message\":\"$message\"}"
  done

  printf '{\n'
  printf '  "version": "%s",\n' "$SCRIPT_VERSION"
  printf '  "stage": "%s",\n' "$OVERALL_STAGE"
  printf '  "system": {\n'
  printf '    "macos_version": "%s",\n' "$DETECTED_MACOS_VERSION"
  printf '    "chip": "%s",\n' "$DETECTED_CHIP"
  printf '    "arch": "%s",\n' "$DETECTED_ARCH"
  printf '    "hostname": "%s",\n' "$DETECTED_HOSTNAME"
  printf '    "model": "%s",\n' "$DETECTED_MODEL"
  printf '    "machine_id": "%s"\n' "$DETECTED_MACHINE_ID"
  printf '  },\n'
  printf '  "counts": {\n'
  printf '    "passed": %d,\n' "$PASS_COUNT"
  printf '    "warnings": %d,\n' "$WARN_COUNT"
  printf '    "failed": %d\n' "$FAIL_COUNT"
  printf '  },\n'
  printf '  "actions": [%s]\n' "$actions_json"
  printf '}\n'
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
  cat << EOF
Nix-Darwin Pre-Flight Inspector v${SCRIPT_VERSION}

Read-only diagnostic that checks system state and produces an action plan.

Usage:
  ./preflight.sh          Run all checks with human-readable output
  ./preflight.sh --json   Machine-readable JSON output
  ./preflight.sh --help   Show this help

Checks performed:
   1. System detection    macOS version, chip, arch, hostname, machineId
   2. Nix status          installed? version? daemon? flakes?
   3. nix-darwin status   darwin-rebuild available? current generation?
   4. Required tools      sops, age, age-keygen, git
   5. Age key             exists? permissions? matches .sops.yaml?
   6. Config files        machine-config.nix, user-config.nix valid?
   7. Host directory      nix-config/hosts/{machineId}/ with required files?
   8. Secrets             encrypted? decryptable with current key?
   9. Flake health        metadata valid? flake.lock present?
  10. Overall stage       FRESH_CLONE / BOOTSTRAPPED / CONFIGURED / READY

Exit codes:
  0  System is READY (all checks pass)
  1  Critical issues found (REQUIRED actions exist)
  2  Warnings only (RECOMMENDED/OPTIONAL actions)

This script makes NO changes to the system.

EOF
}

# ============================================================================
# MAIN
# ============================================================================

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_help
      exit 0
      ;;
    --json|-j)
      JSON_MODE=true
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--json] [--help]"
      exit 1
      ;;
  esac
  shift
done

# Run all checks
if [ "$JSON_MODE" != true ]; then
  print_header "Nix-Darwin Pre-Flight Inspector v${SCRIPT_VERSION}"
fi

check_system
check_nix
check_nix_darwin
check_tools
check_age_key
check_config_files
check_host_directory
check_secrets
check_flake
determine_stage

# Output results
if [ "$JSON_MODE" = true ]; then
  print_json
else
  print_action_plan
  print_summary
fi

# Exit code
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
  exit 2
else
  exit 0
fi
