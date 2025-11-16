#!/usr/bin/env bash
# activate.sh
#
# Apply nix-darwin configuration

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Activating Minimal Nix-Darwin Configuration ==="
echo ""

# Check if configs exist
if [ ! -f "${CONFIG_ROOT}/config/user-config.nix" ] || [ ! -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    echo "Error: Configuration files not found."
    echo ""
    echo "Run this first:"
    echo "  ./scripts/setup/configure.sh"
    echo ""
    exit 1
fi

# Run pre-flight checks if available
if [ -f "${CONFIG_ROOT}/scripts/maintenance/pre-flight-checks.sh" ]; then
    echo "Running pre-flight checks..."
    "${CONFIG_ROOT}/scripts/maintenance/pre-flight-checks.sh" || {
        echo ""
        echo "Pre-flight checks failed. Continue anyway? (y/N)"
        read -p "> " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    }
    echo ""
fi

# Apply configuration
echo "Applying configuration..."
echo ""

cd "${CONFIG_ROOT}"
darwin-rebuild switch --flake .

echo ""
echo "✓ Configuration applied!"
echo ""
echo "Restart your shell to load changes:"
echo "  exec zsh"
echo ""
