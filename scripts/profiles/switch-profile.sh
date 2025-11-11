#!/usr/bin/env bash
# Switch between profiles

set -euo pipefail

PROFILE="${1:-}"
VALID_PROFILES=("personal" "work" "minimal")

show_usage() {
  cat << USAGE
Usage: switch-profile.sh [profile]

Profiles:
  personal  - Personal/learning environment
  work      - Work environment (AWS, databases)
  minimal   - Minimal troubleshooting environment

Current profile: $(grep 'profileName =' config/machine-config.nix | awk '{print $3}' | tr -d '";')

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
  echo "❌ Invalid profile: $PROFILE"
  echo "Valid profiles: ${VALID_PROFILES[@]}"
  exit 1
fi

# Check machine config exists
if [ ! -f "config/machine-config.nix" ]; then
  echo "❌ config/machine-config.nix not found"
  echo "📝 Run: cp config/machine-config.nix.template config/machine-config.nix"
  exit 1
fi

# Update machine-config.nix
echo "🔄 Switching to profile: $PROFILE"
sed -i.bak "s/profileName = \"[^\"]*\"/profileName = \"$PROFILE\"/" config/machine-config.nix

# Show diff
echo "📝 Configuration change:"
diff config/machine-config.nix.bak config/machine-config.nix || true

# Rebuild system
echo "🔨 Rebuilding system with new profile..."
if darwin-rebuild switch --flake .; then
  echo "✅ Successfully switched to $PROFILE profile"
  echo "🔄 Restart your shell: exec zsh"
  rm config/machine-config.nix.bak
else
  echo "❌ Rebuild failed, restoring previous configuration"
  mv config/machine-config.nix.bak config/machine-config.nix
  exit 1
fi
