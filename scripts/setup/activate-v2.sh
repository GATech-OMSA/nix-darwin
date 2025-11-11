#!/usr/bin/env bash

# ============================================================================
# ACTIVATE V2 - GUM EDITION
# ============================================================================
#
# Beautiful interactive activation script for nix-darwin
# Uses gum for modern terminal UI with progress tracking
#
# Usage:
#   ./activate-v2.sh           # Interactive mode
#   ./activate-v2.sh --dry-run # Preview without building
#
# Features:
#   - Modern TUI powered by gum
#   - Real-time build progress
#   - Pre-flight validation checks
#   - Secrets encryption verification
#   - Visual success/failure feedback
#

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
  esac
done

# ============================================================================
# COLORS & FORMATTING (Gum-optimized palette)
# ============================================================================

# Modern Palette
PALETTE_TEAL="#00F5D4"
PALETTE_BLUE="#008E9B"
PALETTE_BORDER="#005F69"
PALETTE_LIME="#9EF01A"
PALETTE_RED="#FF5555"
PALETTE_YELLOW="#FFB86C"
PALETTE_PURPLE="#BD93F9"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

banner() {
  gum style \
    --foreground="$PALETTE_TEAL" \
    --border-foreground="$PALETTE_BORDER" \
    --border="double" \
    --align="center" \
    --width=80 \
    --margin="1 0" \
    --padding="1 4" \
    "$@"
}

section() {
  echo ""
  gum style \
    --foreground="$PALETTE_PURPLE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="0 2" \
    --margin="1 0" \
    --bold \
    "$@"
  echo ""
}

info_box() {
  gum style \
    --foreground="$PALETTE_BLUE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 2" \
    --margin="0 2" \
    --width=76 \
    "$@"
}

success() {
  gum style --foreground="$PALETTE_LIME" "✓ $*"
}

warning() {
  gum style --foreground="$PALETTE_YELLOW" "⚠ $*"
}

error() {
  gum style --foreground="$PALETTE_RED" "✗ $*"
}

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

load_configuration() {
  section "📂 Loading Configuration"

  gum spin --spinner="dot" --title="Reading configuration files..." \
    --spinner.foreground="$PALETTE_TEAL" \
    --title.foreground="$PALETTE_TEAL" -- sleep 0.5

  # Check if config files exist
  if [ ! -f "$REPO_ROOT/config/user-config.nix" ]; then
    error "user-config.nix not found"
    echo ""
    echo "Please run ./configure-v2.sh first"
    exit 1
  fi

  if [ ! -f "$REPO_ROOT/config/machine-config.nix" ]; then
    error "machine-config.nix not found"
    echo ""
    echo "Please run ./configure-v2.sh first"
    exit 1
  fi

  # Extract values
  USERNAME=$(grep 'username =' "$REPO_ROOT/config/user-config.nix" | sed 's/.*"\(.*\)".*/\1/')
  MACHINE_ID=$(grep 'machineId =' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')
  PROFILE=$(grep 'profileName =' "$REPO_ROOT/config/machine-config.nix" | sed 's/.*"\(.*\)".*/\1/')

  info_box \
    "📋 Loaded Configuration:" \
    "" \
    "  Username:   $USERNAME" \
    "  Machine ID: $MACHINE_ID" \
    "  Profile:    $PROFILE" \
    "  Host Path:  hosts/$MACHINE_ID/"

  success "Configuration loaded successfully"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

run_preflight_checks() {
  section "🔍 Pre-Flight Validation"

  local checks_passed=0
  local checks_total=6

  # Check 1: Nix installed
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking Nix installation..."
  if command -v nix &>/dev/null; then
    success "Nix is installed"
    ((checks_passed++))
  else
    error "Nix not found"
  fi

  # Check 2: Host directory exists
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking host directory..."
  if [ -d "$REPO_ROOT/nix-config/hosts/$MACHINE_ID" ]; then
    success "Host directory exists: hosts/$MACHINE_ID/"
    ((checks_passed++))
  else
    error "Host directory not found: hosts/$MACHINE_ID/"
  fi

  # Check 3: Flake exists
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking flake.nix..."
  if [ -f "$REPO_ROOT/flake.nix" ]; then
    success "flake.nix found"
    ((checks_passed++))
  else
    error "flake.nix not found"
  fi

  # Check 4: Age key exists
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking age encryption key..."
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    success "Age key found"
    ((checks_passed++))
  else
    warning "Age key not found (secrets will not be encrypted)"
  fi

  # Check 5: SOPS installed
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking SOPS installation..."
  if command -v sops &>/dev/null; then
    success "SOPS is installed"
    ((checks_passed++))
  else
    warning "SOPS not found (secrets will not be encrypted)"
  fi

  # Check 6: Git status clean
  echo ""
  gum style --foreground="$PALETTE_BLUE" "Checking git status..."
  if git diff --quiet 2>/dev/null; then
    success "Working directory is clean"
    ((checks_passed++))
  else
    warning "Uncommitted changes detected"
    ((checks_passed++))
  fi

  echo ""

  if [ $checks_passed -eq $checks_total ]; then
    gum style --foreground="$PALETTE_LIME" --bold "✅ All pre-flight checks passed ($checks_passed/$checks_total)"
  elif [ $checks_passed -ge 4 ]; then
    gum style --foreground="$PALETTE_YELLOW" --bold "⚠️  Pre-flight checks passed with warnings ($checks_passed/$checks_total)"
  else
    gum style --foreground="$PALETTE_RED" --bold "❌ Pre-flight checks failed ($checks_passed/$checks_total)"
    exit 1
  fi
}

# ============================================================================
# SECRETS ENCRYPTION
# ============================================================================

encrypt_secrets() {
  section "🔐 Secrets Encryption"

  local SECRETS_FILE="$REPO_ROOT/nix-config/hosts/$MACHINE_ID/secrets.yaml"

  if [ ! -f "$SECRETS_FILE" ]; then
    warning "No secrets.yaml found - skipping encryption"
    return
  fi

  # Check if already encrypted
  if head -n1 "$SECRETS_FILE" | grep -q "sops:"; then
    success "secrets.yaml is already encrypted"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    info_box \
      "[DRY RUN] Would encrypt:" \
      "" \
      "  File: $SECRETS_FILE" \
      "  Using: SOPS + age encryption" \
      "  Key:  ~/.config/sops/age/keys.txt"
    return
  fi

  gum spin --spinner="dot" --title="Encrypting secrets with SOPS..." \
    --spinner.foreground="$PALETTE_TEAL" \
    --title.foreground="$PALETTE_TEAL" -- \
    sops --encrypt --in-place "$SECRETS_FILE" 2>/dev/null

  if [ $? -eq 0 ]; then
    success "secrets.yaml encrypted successfully"
  else
    error "Failed to encrypt secrets.yaml"
    exit 1
  fi
}

# ============================================================================
# DARWIN REBUILD
# ============================================================================

run_darwin_rebuild() {
  section "🔨 Building System Configuration"

  if [ "$DRY_RUN" = true ]; then
    info_box \
      "[DRY RUN] Would execute:" \
      "" \
      "  Command: darwin-rebuild switch --flake .#$MACHINE_ID" \
      "  Working directory: $REPO_ROOT" \
      "" \
      "This would:" \
      "  1. Evaluate the flake for machine: $MACHINE_ID" \
      "  2. Build all packages and configurations" \
      "  3. Activate the new system generation" \
      "  4. Switch to the new configuration"

    echo ""
    success "[DRY RUN] Build preview complete"
    return
  fi

  echo ""
  info_box \
    "Starting darwin-rebuild..." \
    "" \
    "This may take several minutes on first run." \
    "Building packages, linking configurations, activating system."

  echo ""
  gum style --foreground="$PALETTE_BLUE" "Building configuration for: $MACHINE_ID"
  echo ""

  # Run the actual build with output
  if darwin-rebuild switch --flake "$REPO_ROOT#$MACHINE_ID"; then
    echo ""
    success "Darwin rebuild completed successfully"
    return 0
  else
    echo ""
    error "Darwin rebuild failed"
    return 1
  fi
}

# ============================================================================
# POST-ACTIVATION
# ============================================================================

show_post_activation_summary() {
  section "🎉 Activation Complete"

  info_box \
    "✅ System Successfully Activated!" \
    "" \
    "  Configuration: $MACHINE_ID" \
    "  Profile:       $PROFILE" \
    "  Generation:    $(darwin-rebuild --list-generations | tail -n1 | awk '{print $1}')"

  echo ""

  info_box \
    "📝 Next Steps:" \
    "" \
    "  1. Restart your shell:" \
    "     exec zsh" \
    "" \
    "  2. Verify installation:" \
    "     health-check" \
    "" \
    "  3. Customize further:" \
    "     nixconf" \
    "" \
    "  4. Commit your configuration:" \
    "     git add . && git commit -m \"Initial nix-darwin configuration\""

  echo ""

  info_box \
    "🔐 Managing Secrets:" \
    "" \
    "  Edit encrypted secrets:" \
    "    edit-secrets" \
    "" \
    "  View encrypted secrets:" \
    "    view-secrets"

  echo ""

  banner \
    "🚀 Welcome to nix-darwin!" \
    "" \
    "Your system is now fully configured and activated"

  echo ""
}

show_failure_summary() {
  section "❌ Activation Failed"

  info_box \
    "Build failed. Common issues:" \
    "" \
    "  1. Syntax errors in Nix files" \
    "     Check: nix flake check" \
    "" \
    "  2. Missing dependencies" \
    "     Check: nix flake show" \
    "" \
    "  3. Conflicting configurations" \
    "     Review: recent changes to .nix files" \
    "" \
    "  4. Network issues downloading packages" \
    "     Check: internet connection, retry"

  echo ""

  local action=$(gum choose \
    --header="What would you like to do?" \
    --header.foreground="$PALETTE_TEAL" \
    --cursor="▶ " \
    --cursor.foreground="$PALETTE_TEAL" \
    --selected.foreground="$PALETTE_LIME" \
    "View build log" \
    "Run diagnostics" \
    "Exit")

  case "$action" in
    "View build log")
      echo ""
      gum style --foreground="$PALETTE_BLUE" "Last build log:"
      echo ""
      darwin-rebuild switch --flake "$REPO_ROOT#$MACHINE_ID" --show-trace 2>&1 | tail -n50
      ;;
    "Run diagnostics")
      echo ""
      gum style --foreground="$PALETTE_BLUE" "Running diagnostics..."
      echo ""
      nix flake check "$REPO_ROOT"
      ;;
  esac
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
  banner \
    "🚀 nix-darwin System Activation" \
    "" \
    "Building and activating your configuration"

  load_configuration
  run_preflight_checks

  echo ""

  # Confirmation prompt
  if [ "$DRY_RUN" != true ]; then
    local confirm=$(gum choose \
      --header="Ready to build and activate system?" \
      --header.foreground="$PALETTE_TEAL" \
      --cursor="▶ " \
      --cursor.foreground="$PALETTE_TEAL" \
      --selected.foreground="$PALETTE_LIME" \
      "Yes, proceed with activation" \
      "No, cancel")

    if [[ "$confirm" != "Yes"* ]]; then
      warning "Activation cancelled"
      exit 0
    fi
  fi

  encrypt_secrets

  if run_darwin_rebuild; then
    show_post_activation_summary
  else
    show_failure_summary
    exit 1
  fi
}

main
