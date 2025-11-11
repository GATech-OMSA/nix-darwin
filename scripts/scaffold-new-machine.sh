#!/bin/bash
# Scaffold New Machine Configuration
#
# Interactive script to create a new machine configuration from template
# Usage: ./scripts/scaffold-new-machine.sh

set -e  # Exit on error

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/hosts/_template"

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   New Machine Configuration Scaffold${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check we're in the repo root
if [ ! -f "$REPO_ROOT/flake.nix" ]; then
  echo -e "${RED}Error: Must run from nix-darwin repository root${NC}"
  exit 1
fi

# Get hostname
echo -e "${GREEN}📝 Machine Configuration${NC}"
echo ""
read -p "Enter new hostname (e.g., mbp-alice): " HOSTNAME

if [ -z "$HOSTNAME" ]; then
  echo -e "${RED}Error: Hostname cannot be empty${NC}"
  exit 1
fi

# Check if hostname already exists
if [ -d "$REPO_ROOT/hosts/$HOSTNAME" ]; then
  echo -e "${RED}Error: Host '$HOSTNAME' already exists${NC}"
  exit 1
fi

# Get username
read -p "Enter username (e.g., alice): " USERNAME

if [ -z "$USERNAME" ]; then
  echo -e "${RED}Error: Username cannot be empty${NC}"
  exit 1
fi

# Get computer name
read -p "Enter computer name (e.g., Alice's MacBook Pro): " COMPUTER_NAME

if [ -z "$COMPUTER_NAME" ]; then
  COMPUTER_NAME="${USERNAME}'s Mac"
fi

# Get machine type
echo ""
echo "Select machine type:"
echo "  1) personal - Personal machine (default AWS, personal email)"
echo "  2) work - Work machine (work AWS, work email)"
echo "  3) minimal - Minimal configuration (base only)"
read -p "Enter choice [1-3] (default: 1): " MACHINE_TYPE_CHOICE

case $MACHINE_TYPE_CHOICE in
  1|"")
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
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

# Get architecture
echo ""
echo "Select system architecture:"
echo "  1) aarch64-darwin - Apple Silicon (M1/M2/M3)"
echo "  2) x86_64-darwin - Intel Mac"
read -p "Enter choice [1-2] (default: 1): " ARCH_CHOICE

case $ARCH_CHOICE in
  1|"")
    SYSTEM="aarch64-darwin"
    ;;
  2)
    SYSTEM="x86_64-darwin"
    ;;
  *)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

# Confirmation
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   Configuration Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Hostname:      $HOSTNAME"
echo "Username:      $USERNAME"
echo "Computer Name: $COMPUTER_NAME"
echo "Machine Type:  $MACHINE_TYPE"
echo "Architecture:  $SYSTEM"
echo "Mixins:        $MIXINS"
echo ""
read -p "Create this configuration? [y/N]: " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo -e "${GREEN}🚀 Creating configuration...${NC}"

# Step 1: Copy template
echo "  📁 Copying template to hosts/$HOSTNAME/"
cp -r "$TEMPLATE_DIR" "$REPO_ROOT/hosts/$HOSTNAME"

# Step 2: Update default.nix
echo "  ✏️  Customizing hosts/$HOSTNAME/default.nix"
sed -i '' "s/REPLACE_WITH_COMPUTER_NAME/$COMPUTER_NAME/g" "$REPO_ROOT/hosts/$HOSTNAME/default.nix"

# Step 3: Update machines.nix
echo "  ✏️  Adding to hosts/machines.nix"
# Insert before the closing brace
sed -i '' "s/^}$/  \"$HOSTNAME\" = \"$MACHINE_TYPE\";\n}/" "$REPO_ROOT/hosts/machines.nix"

# Step 4: Show flake.nix addition
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}   Manual Steps Required${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${BLUE}1. Add to flake.nix:${NC}"
echo ""
echo "darwinConfigurations.\"$HOSTNAME\" = mkDarwinSystem {"
echo "  hostname = \"$HOSTNAME\";"
echo "  system = \"$SYSTEM\";"
echo "  username = \"$USERNAME\";"
echo "  mixins = $MIXINS;"
echo "};"
echo ""

echo -e "${BLUE}2. Setup secrets encryption:${NC}"
echo ""
echo "# Generate age key (if not already done)"
echo "mkdir -p ~/.config/sops/age"
echo "age-keygen -o ~/.config/sops/age/keys.txt"
echo ""
echo "# Get public key"
echo "grep \"public key:\" ~/.config/sops/age/keys.txt"
echo ""
echo "# Add public key to secrets/.sops.yaml"
echo "code secrets/.sops.yaml"
echo ""
echo "# Encrypt secrets file"
echo "sops hosts/$HOSTNAME/secrets.yaml"
echo ""

echo -e "${BLUE}3. Build configuration:${NC}"
echo ""
echo "# First-time build"
echo "sudo nix run nix-darwin -- switch --flake .#$HOSTNAME"
echo ""
echo "# Subsequent rebuilds"
echo "darwin-rebuild switch --flake ~/nix-darwin"
echo ""

echo -e "${GREEN}✅ Template created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Edit flake.nix (add darwinConfiguration shown above)"
echo "  2. Setup SOPS encryption (commands shown above)"
echo "  3. Customize configuration as needed"
echo "  4. Build and test"
echo ""
echo "See hosts/$HOSTNAME/README.md for detailed instructions."
echo ""
