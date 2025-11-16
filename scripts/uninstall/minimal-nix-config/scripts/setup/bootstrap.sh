#!/usr/bin/env bash
# bootstrap.sh
#
# Initial setup for minimal nix-darwin on a new machine

set -euo pipefail

echo "=== Minimal Nix-Darwin Bootstrap ==="
echo ""

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "Error: Nix is not installed."
    echo ""
    echo "Install Nix first:"
    echo "  https://nixos.org/download.html"
    echo ""
    echo "Recommended (Determinate Systems installer):"
    echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
    echo ""
    exit 1
fi

echo "✓ Nix is installed"
echo ""

# Check if nix-darwin is installed
if ! command -v darwin-rebuild &> /dev/null; then
    echo "Installing nix-darwin..."
    echo ""

    # Install nix-darwin
    nix run nix-darwin -- switch --flake .

    echo ""
    echo "✓ nix-darwin installed"
else
    echo "✓ nix-darwin is already installed"
fi

echo ""
echo "Next steps:"
echo "  1. ./scripts/setup/configure.sh   # Set up machine/user configs"
echo "  2. ./scripts/setup/activate.sh    # Apply configuration"
echo ""
