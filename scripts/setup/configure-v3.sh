#!/usr/bin/env bash

# ============================================================================
# CONFIGURE V3 - PAGINATED WIZARD EDITION
# ============================================================================
#
# Beautiful paginated wizard for nix-darwin configuration
# Navigate with arrow keys through multi-step setup
#
# Usage:
#   ./configure-v3.sh           # Interactive wizard
#   ./configure-v3.sh --dry-run # Preview without creating files
#
# Features:
#   - Multi-page wizard with ←→ navigation
#   - Clean, focused information per page
#   - Progress indicator
#   - Elegant gum styling
#

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$SCRIPT_DIR"
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
# COLORS & FORMATTING
# ============================================================================

PALETTE_TEAL="#00F5D4"
PALETTE_BLUE="#008E9B"
PALETTE_BORDER="#005F69"
PALETTE_LIME="#9EF01A"
PALETTE_RED="#FF5555"
PALETTE_YELLOW="#FFB86C"
PALETTE_PURPLE="#BD93F9"

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

# Configuration state
declare -A CONFIG=(
  [username]=""
  [email]=""
  [fullName]=""
  [machineId]=""
  [profile]=""
  [homebrew]=""
  [description]=""
  [arch]=""
)

# Detected values
declare -A DETECTED=(
  [username]=""
  [email]=""
  [fullName]=""
  [machineId]=""
  [hostname]=""
  [model]=""
  [chip]=""
  [arch]=""
)

# Page state
CURRENT_PAGE=1
TOTAL_PAGES=7

# ============================================================================
# UI HELPERS
# ============================================================================

clear_screen() {
  clear
  echo ""
}

title() {
  gum style \
    --foreground="$PALETTE_TEAL" \
    --border="double" \
    --border-foreground="$PALETTE_BORDER" \
    --align="center" \
    --width=80 \
    --padding="1 0" \
    --bold \
    "$@"
}

page_title() {
  gum style \
    --foreground="$PALETTE_PURPLE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --align="center" \
    --width=80 \
    --padding="1 2" \
    --bold \
    "$@"
}

info_card() {
  gum style \
    --foreground="$PALETTE_BLUE" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 3" \
    --margin="1 0" \
    --width=80 \
    "$@"
}

success_card() {
  gum style \
    --foreground="$PALETTE_LIME" \
    --border="rounded" \
    --border-foreground="$PALETTE_BORDER" \
    --padding="1 3" \
    --margin="1 0" \
    --width=80 \
    "$@"
}

progress_bar() {
  local current=$1
  local total=$2
  local width=60
  local filled=$((current * width / total))
  local empty=$((width - filled))

  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  gum style \
    --foreground="$PALETTE_TEAL" \
    --align="center" \
    "Page $current of $total" \
    "$bar"
}

navigation_hint() {
  echo ""
  gum style \
    --foreground="$PALETTE_YELLOW" \
    --align="center" \
    --faint \
    "← Previous  |  → Next  |  q Quit"
}

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

detect_system() {
  DETECTED[username]=$(whoami)
  DETECTED[email]=$(git config --global user.email 2>/dev/null || echo "")
  DETECTED[fullName]=$(git config --global user.name 2>/dev/null || echo "")
  DETECTED[hostname]=$(scutil --get ComputerName 2>/dev/null || hostname)
  DETECTED[model]=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
  DETECTED[chip]=$(sysctl -n machdep.cpu.brand_string 2>/dev/null | sed 's/  */ /g')

  local arch=$(uname -m)
  case "$arch" in
    arm64) DETECTED[arch]="aarch64-darwin" ;;
    x86_64) DETECTED[arch]="x86_64-darwin" ;;
    *) DETECTED[arch]="$arch" ;;
  esac

  # Generate machine ID
  local model="${DETECTED[model]}"
  local chip="${DETECTED[chip]}"

  local machine_id="macbook"
  if echo "$model" | grep -qi "macbookpro"; then
    machine_id="macbook-pro"
  elif echo "$model" | grep -qi "macbookair"; then
    machine_id="macbook-air"
  fi

  if echo "$chip" | grep -qi "apple m1"; then
    machine_id="${machine_id}-m1"
  elif echo "$chip" | grep -qi "apple m2"; then
    machine_id="${machine_id}-m2"
  elif echo "$chip" | grep -qi "apple m3"; then
    machine_id="${machine_id}-m3"
  fi

  DETECTED[machineId]="$machine_id"

  # Initialize config with detected values
  CONFIG[username]="${DETECTED[username]}"
  CONFIG[email]="${DETECTED[email]}"
  CONFIG[fullName]="${DETECTED[fullName]}"
  CONFIG[machineId]="${DETECTED[machineId]}"
  CONFIG[description]="${DETECTED[hostname]}"
  CONFIG[arch]="${DETECTED[arch]}"
}

# ============================================================================
# WIZARD PAGES
# ============================================================================

page_welcome() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  info_card \
    "Welcome to the nix-darwin configuration wizard!" \
    "" \
    "This wizard will guide you through setting up your" \
    "declarative macOS system configuration." \
    "" \
    "What you'll configure:" \
    "  • User information (name, email)" \
    "  • Machine identity (username-agnostic)" \
    "  • System profile (personal, work, minimal)" \
    "  • Package management (Homebrew integration)" \
    "  • Secrets encryption (SOPS + age)" \
    "" \
    "Navigate using arrow keys, press Enter to continue."

  navigation_hint
}

page_prerequisites() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "🔍 Prerequisites Check"

  echo ""

  local checks=""
  local all_good=true

  # Check each prerequisite
  if command -v nix &>/dev/null; then
    local ver=$(nix --version 2>/dev/null | awk '{print $3}')
    checks+="  ✓ Nix $ver\n"
  else
    checks+="  ✗ Nix not installed\n"
    all_good=false
  fi

  if command -v sops &>/dev/null; then
    local ver=$(sops --version 2>&1 | head -n1 | awk '{print $2}')
    checks+="  ✓ SOPS $ver\n"
  else
    checks+="  ✗ SOPS not installed\n"
    all_good=false
  fi

  if command -v age &>/dev/null; then
    local ver=$(age --version 2>&1 | head -n1 | xargs)
    checks+="  ✓ age $ver\n"
  else
    checks+="  ✗ age not installed\n"
    all_good=false
  fi

  if command -v git &>/dev/null; then
    local ver=$(git --version 2>/dev/null | awk '{print $3}')
    checks+="  ✓ git $ver\n"
  else
    checks+="  ✗ git not installed\n"
    all_good=false
  fi

  if [ "$all_good" = true ]; then
    success_card "$(echo -e "$checks")" "" "All prerequisites satisfied!"
  else
    info_card "$(echo -e "$checks")" "" "Missing tools detected. Run ./bootstrap.sh first."
  fi

  navigation_hint
}

page_detection() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "🔎 System Detection"

  echo ""

  info_card \
    "Detected Configuration:" \
    "" \
    "  Username         ${DETECTED[username]}" \
    "  Email            ${DETECTED[email]:-<not configured>}" \
    "  Full Name        ${DETECTED[fullName]:-<not configured>}" \
    "" \
    "  Machine ID       ${DETECTED[machineId]}" \
    "  Hostname         ${DETECTED[hostname]}" \
    "  Model            ${DETECTED[model]}" \
    "  Chip             ${DETECTED[chip]}" \
    "  Architecture     ${DETECTED[arch]}"

  echo ""

  info_card \
    "💡 What is Machine ID?" \
    "" \
    "A username-agnostic identifier that follows the hardware," \
    "not the user. Examples: macbook-pro-m1, macbook-air-m2" \
    "" \
    "It controls:" \
    "  • Host configuration location" \
    "  • Secrets storage path" \
    "  • Workspace directory" \
    "  • Build target name"

  navigation_hint
}

page_user_config() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "👤 User Configuration"

  echo ""

  # Username
  gum style --foreground="$PALETTE_BLUE" "Username (system user):"
  local new_username=$(gum input --value="${CONFIG[username]}" \
    --prompt="  " \
    --width=70)
  [ -n "$new_username" ] && CONFIG[username]="$new_username"

  echo ""

  # Email
  gum style --foreground="$PALETTE_BLUE" "Email (for git commits):"
  local new_email=$(gum input --value="${CONFIG[email]}" \
    --placeholder="your@email.com" \
    --prompt="  " \
    --width=70)
  [ -n "$new_email" ] && CONFIG[email]="$new_email"

  echo ""

  # Full Name
  gum style --foreground="$PALETTE_BLUE" "Full Name (for git commits):"
  local new_name=$(gum input --value="${CONFIG[fullName]}" \
    --placeholder="Your Full Name" \
    --prompt="  " \
    --width=70)
  [ -n "$new_name" ] && CONFIG[fullName]="$new_name"

  echo ""

  # Machine ID
  gum style --foreground="$PALETTE_BLUE" "Machine ID (suggested: ${DETECTED[machineId]}):"
  local new_machine=$(gum input --value="${CONFIG[machineId]}" \
    --prompt="  " \
    --width=70)
  [ -n "$new_machine" ] && CONFIG[machineId]="$new_machine"

  navigation_hint
}

page_profile() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "📱 Profile Selection"

  echo ""

  local profile=$(gum choose \
    --header="Select your machine profile:" \
    --header.foreground="$PALETTE_TEAL" \
    --cursor="▶ " \
    --cursor.foreground="$PALETTE_TEAL" \
    --selected.foreground="$PALETTE_LIME" \
    --selected="${CONFIG[profile]:-Personal}" \
    "Personal" \
    "Work" \
    "Minimal")

  CONFIG[profile]="$(echo "$profile" | tr '[:upper:]' '[:lower:]')"

  echo ""

  case "${CONFIG[profile]}" in
    personal)
      info_card \
        "📱 Personal Profile" \
        "" \
        "  • All development tools and languages" \
        "  • Personal AWS profile by default" \
        "  • Personal email in git config" \
        "  • Full shell customizations" \
        "  • Recommended for home use"
      ;;
    work)
      info_card \
        "💼 Work Profile" \
        "" \
        "  • Work-specific AWS profiles" \
        "  • Work email in git config" \
        "  • Corporate security tools" \
        "  • Work-appropriate aliases" \
        "  • For company laptops"
      ;;
    minimal)
      info_card \
        "🛠️  Minimal Profile" \
        "" \
        "  • Base system only, no extras" \
        "  • Fastest builds and rebuilds" \
        "  • Good for debugging issues" \
        "  • Can upgrade to personal/work later"
      ;;
  esac

  navigation_hint
}

page_homebrew() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "🍺 Homebrew Configuration"

  echo ""

  local choice=$(gum choose \
    --header="Enable Homebrew for GUI applications?" \
    --header.foreground="$PALETTE_TEAL" \
    --cursor="▶ " \
    --cursor.foreground="$PALETTE_TEAL" \
    --selected.foreground="$PALETTE_LIME" \
    --selected="${CONFIG[homebrew]:-Yes}" \
    "Yes" \
    "No")

  CONFIG[homebrew]="$choice"

  echo ""

  if [ "$choice" = "Yes" ]; then
    success_card \
      "✓ Homebrew Enabled" \
      "" \
      "GUI applications from Homebrew Casks will be available." \
      "Examples: browsers, editors, creative tools" \
      "" \
      "Managed declaratively via modules/darwin/homebrew.nix"
  else
    info_card \
      "Homebrew Disabled" \
      "" \
      "Only Nix packages will be available." \
      "More reproducible but fewer GUI apps." \
      "" \
      "You can enable Homebrew later by editing your config."
  fi

  navigation_hint
}

page_review() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  progress_bar $CURRENT_PAGE $TOTAL_PAGES
  echo ""

  page_title "📋 Review & Confirm"

  echo ""

  local homebrew_status="Disabled"
  [ "${CONFIG[homebrew]}" = "Yes" ] && homebrew_status="Enabled"

  info_card \
    "Your Configuration:" \
    "" \
    "  Username         ${CONFIG[username]}" \
    "  Email            ${CONFIG[email]}" \
    "  Full Name        ${CONFIG[fullName]}" \
    "" \
    "  Machine ID       ${CONFIG[machineId]}" \
    "  Profile          ${CONFIG[profile]}" \
    "  Homebrew         $homebrew_status" \
    "  Architecture     ${CONFIG[arch]}"

  echo ""

  info_card \
    "Files to be created:" \
    "" \
    "  $REPO_ROOT/config/user-config.nix" \
    "  $REPO_ROOT/config/machine-config.nix" \
    "  $REPO_ROOT/hosts/${CONFIG[machineId]}/default.nix" \
    "  $REPO_ROOT/hosts/${CONFIG[machineId]}/secrets.yaml"

  navigation_hint

  echo ""
  gum style --foreground="$PALETTE_LIME" --align="center" "Press → to create configuration files"
}

# ============================================================================
# WIZARD NAVIGATION
# ============================================================================

navigate_wizard() {
  detect_system

  while true; do
    case $CURRENT_PAGE in
      1) page_welcome ;;
      2) page_prerequisites ;;
      3) page_detection ;;
      4) page_user_config ;;
      5) page_profile ;;
      6) page_homebrew ;;
      7) page_review ;;
    esac

    # Get navigation input
    read -rsn1 key

    case "$key" in
      $'\x1b')  # ESC sequence
        read -rsn2 -t 0.1 key
        case "$key" in
          '[D')  # Left arrow
            if [ $CURRENT_PAGE -gt 1 ]; then
              ((CURRENT_PAGE--))
            fi
            ;;
          '[C')  # Right arrow
            if [ $CURRENT_PAGE -lt $TOTAL_PAGES ]; then
              ((CURRENT_PAGE++))
            else
              # On last page, proceed with creation
              break
            fi
            ;;
        esac
        ;;
      'q'|'Q')
        echo ""
        gum style --foreground="$PALETTE_RED" "Setup cancelled"
        exit 0
        ;;
      '')  # Enter key
        if [ $CURRENT_PAGE -lt $TOTAL_PAGES ]; then
          ((CURRENT_PAGE++))
        else
          break
        fi
        ;;
    esac
  done
}

# ============================================================================
# CONFIGURATION CREATION
# ============================================================================

create_configuration() {
  clear_screen

  title "⚙️  nix-darwin Setup Wizard"

  echo ""
  gum style --foreground="$PALETTE_PURPLE" --bold "Creating Configuration..."
  echo ""

  if [ "$DRY_RUN" = true ]; then
    info_card \
      "[DRY RUN] Would create:" \
      "" \
      "  mkdir -p $REPO_ROOT/config" \
      "  mkdir -p $REPO_ROOT/nix-config/hosts/${CONFIG[machineId]}" \
      "" \
      "  config/user-config.nix" \
      "  config/machine-config.nix" \
      "  nix-config/hosts/${CONFIG[machineId]}/default.nix" \
      "  nix-config/hosts/${CONFIG[machineId]}/secrets.yaml"

    echo ""
    gum style --foreground="$PALETTE_LIME" "✓ [DRY RUN] Configuration preview complete"
    return
  fi

  # Create directories
  mkdir -p "$REPO_ROOT/config"
  mkdir -p "$REPO_ROOT/nix-config/hosts/${CONFIG[machineId]}"

  # Create user-config.nix
  cat > "$REPO_ROOT/config/user-config.nix" <<EOF
{
  username = "${CONFIG[username]}";
  fullName = "${CONFIG[fullName]}";
  email = "${CONFIG[email]}";
}
EOF

  # Create machine-config.nix
  local homebrew_bool="true"
  [ "${CONFIG[homebrew]}" = "No" ] && homebrew_bool="false"

  cat > "$REPO_ROOT/config/machine-config.nix" <<EOF
{
  machineId = "${CONFIG[machineId]}";
  profileName = "${CONFIG[profile]}";
  description = "${CONFIG[description]}";
  system = "${CONFIG[arch]}";
}
EOF

  # Create host default.nix
  cat > "$REPO_ROOT/nix-config/hosts/${CONFIG[machineId]}/default.nix" <<EOF
{ config, pkgs, ... }:

{
  networking.computerName = "${CONFIG[description]}";
  networking.hostName = "${CONFIG[machineId]}";

  homebrew.enable = $homebrew_bool;

  imports = [
    ./secrets.nix
  ];
}
EOF

  # Create secrets template
  cat > "$REPO_ROOT/nix-config/hosts/${CONFIG[machineId]}/secrets.yaml" <<'EOF'
# Secrets Configuration (will be encrypted by activate.sh)
test_secret: "hello-world"
EOF

  success_card \
    "✓ Configuration Created" \
    "" \
    "Files created successfully:" \
    "  ✓ config/user-config.nix" \
    "  ✓ config/machine-config.nix" \
    "  ✓ nix-config/hosts/${CONFIG[machineId]}/default.nix" \
    "  ✓ nix-config/hosts/${CONFIG[machineId]}/secrets.yaml"

  echo ""

  info_card \
    "Next Steps:" \
    "" \
    "  1. Run ./activate-v3.sh to build your system" \
    "  2. Or run ./activate.sh for standard activation"

  echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  # Check for gum
  if ! command -v gum &>/dev/null; then
    echo "Error: gum is not installed"
    echo "Install with: brew install gum"
    exit 1
  fi

  navigate_wizard
  create_configuration
}

main
