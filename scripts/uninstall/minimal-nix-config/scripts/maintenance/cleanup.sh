#!/usr/bin/env bash
# cleanup.sh
#
# Clean up old Nix generations and garbage collect

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Nix Cleanup ==="
echo ""

# Show current disk usage
echo "Current Nix store size:"
nix_store_size=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "unknown")
echo "  ${nix_store_size}"
echo ""

# Show generations
echo "Current generations:"
darwin-rebuild --list-generations | tail -5
echo ""

# Count generations
generation_count=$(darwin-rebuild --list-generations | wc -l | tr -d ' ')
echo "Total generations: ${generation_count}"
echo ""

# Options
echo "Cleanup options:"
echo "  1. Delete old generations (keep last 5)"
echo "  2. Delete old generations (keep last 10)"
echo "  3. Delete generations older than 30 days"
echo "  4. Garbage collect only (remove unused packages)"
echo "  5. Full cleanup (delete old generations + GC)"
echo "  6. Cancel"
echo ""

read -p "Choose option [1-6]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}Deleting all but last 5 generations...${NC}"
        darwin-rebuild --list-generations | head -n -5 | awk '{print $1}' | while read gen; do
            sudo nix-env -p /nix/var/nix/profiles/system --delete-generations "$gen" || true
        done
        echo -e "${GREEN}✓ Old generations deleted${NC}"
        ;;
    2)
        echo ""
        echo -e "${YELLOW}Deleting all but last 10 generations...${NC}"
        darwin-rebuild --list-generations | head -n -10 | awk '{print $1}' | while read gen; do
            sudo nix-env -p /nix/var/nix/profiles/system --delete-generations "$gen" || true
        done
        echo -e "${GREEN}✓ Old generations deleted${NC}"
        ;;
    3)
        echo ""
        echo -e "${YELLOW}Deleting generations older than 30 days...${NC}"
        sudo nix-collect-garbage --delete-older-than 30d
        echo -e "${GREEN}✓ Old generations deleted${NC}"
        ;;
    4)
        echo ""
        echo -e "${YELLOW}Running garbage collection...${NC}"
        sudo nix-collect-garbage
        echo -e "${GREEN}✓ Garbage collection complete${NC}"
        ;;
    5)
        echo ""
        echo -e "${YELLOW}Full cleanup: deleting old generations + GC...${NC}"
        echo ""

        # Delete old generations
        darwin-rebuild --list-generations | head -n -5 | awk '{print $1}' | while read gen; do
            sudo nix-env -p /nix/var/nix/profiles/system --delete-generations "$gen" || true
        done

        # Garbage collect
        sudo nix-collect-garbage -d

        # Optimize store
        sudo nix-store --optimize

        echo ""
        echo -e "${GREEN}✓ Full cleanup complete${NC}"
        ;;
    6)
        echo ""
        echo "Cancelled."
        exit 0
        ;;
    *)
        echo ""
        echo "Invalid choice."
        exit 1
        ;;
esac

echo ""

# Show new disk usage
echo "New Nix store size:"
new_size=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "unknown")
echo "  ${new_size}"
echo ""

echo "Remaining generations:"
darwin-rebuild --list-generations | tail -5
echo ""

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""
