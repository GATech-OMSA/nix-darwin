#!/usr/bin/env bash
# Switch between profiles
#
# Usage: switch-profile.sh <personal|work|minimal>

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${REPO_ROOT}/scripts/lib/run-banner.sh"  # run_banner
CONFIG_FILE="$REPO_ROOT/config/machine-config.nix"
PROFILE="${1:-}"
VALID_PROFILES=("personal" "work" "minimal")

show_usage() {
  local current="unknown"
  if [ -f "$CONFIG_FILE" ]; then
    current=$(grep 'profileName =' "$CONFIG_FILE" | awk '{print $3}' | tr -d '";')
  fi
  cat << USAGE
Usage: switch-profile.sh [profile]

Profiles:
  personal  - Personal/learning environment
  work      - Work environment (AWS, databases)
  minimal   - Minimal troubleshooting environment

Current profile: $current

Example:
  switch-profile.sh work

USAGE
}

# Validate profile argument
if [ -z "$PROFILE" ]; then
  show_usage
  exit 1
fi

# Check if profile is valid
if [[ ! " ${VALID_PROFILES[@]} " =~ " ${PROFILE} " ]]; then
  echo "error: invalid profile: $PROFILE"
  echo "Valid profiles: ${VALID_PROFILES[*]}"
  exit 1
fi

# Check machine config exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "error: $CONFIG_FILE not found"
  echo "Run: cp config/machine-config.nix.template config/machine-config.nix"
  exit 1
fi

# Read machineId before making changes
MACHINE_ID=$(nix eval --raw --file "$CONFIG_FILE" machineId 2>/dev/null)
if [ -z "$MACHINE_ID" ]; then
  echo "error: failed to read machineId from $CONFIG_FILE"
  exit 1
fi

run_banner "switch-profile" "target_profile=$PROFILE" "$@"

# Update machine-config.nix
echo "Switching to profile: $PROFILE"
sed -i.bak "s/profileName = \"[^\"]*\"/profileName = \"$PROFILE\"/" "$CONFIG_FILE"

# Show diff
echo "Configuration change:"
diff "$CONFIG_FILE.bak" "$CONFIG_FILE" || true

# Rebuild system targeting the specific machine
echo "Rebuilding system with new profile..."
if sudo darwin-rebuild switch --flake "$REPO_ROOT#$MACHINE_ID"; then
  echo "Successfully switched to $PROFILE profile"
  echo "Restart your shell: exec zsh"
  rm "$CONFIG_FILE.bak"
else
  echo "error: rebuild failed, restoring previous configuration"
  mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
  exit 1
fi
