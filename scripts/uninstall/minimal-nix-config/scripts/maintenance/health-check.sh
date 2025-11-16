#!/usr/bin/env bash
# health-check.sh
#
# Check system health

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== System Health Check ==="
echo ""

# Check Nix
echo "Nix:"
if command -v nix &> /dev/null; then
    nix_version=$(nix --version | head -1)
    echo "  ✓ $nix_version"
else
    echo "  ✗ Nix not installed"
fi
echo ""

# Check nix-darwin
echo "nix-darwin:"
if command -v darwin-rebuild &> /dev/null; then
    echo "  ✓ darwin-rebuild available"

    # Check current generation
    current_gen=$(darwin-rebuild --list-generations | grep current | head -1 || echo "unknown")
    echo "  Current generation: $current_gen"
else
    echo "  ✗ darwin-rebuild not available"
fi
echo ""

# Check config files
echo "Configuration:"
if [ -f "${CONFIG_ROOT}/config/user-config.nix" ]; then
    echo "  ✓ user-config.nix exists"
else
    echo "  ✗ user-config.nix missing"
fi

if [ -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    echo "  ✓ machine-config.nix exists"
else
    echo "  ✗ machine-config.nix missing"
fi
echo ""

# Check flake
echo "Flake:"
cd "${CONFIG_ROOT}"
if nix flake metadata . &> /dev/null; then
    echo "  ✓ Flake is valid"
else
    echo "  ✗ Flake has errors"
fi
echo ""

# Check Homebrew
echo "Homebrew:"
if command -v brew &> /dev/null; then
    brew_version=$(brew --version | head -1)
    echo "  ✓ $brew_version"

    # Check for updates
    outdated=$(brew outdated | wc -l | tr -d ' ')
    if [ "$outdated" -gt 0 ]; then
        echo "  ⚠ $outdated package(s) outdated"
    else
        echo "  ✓ All packages up to date"
    fi
else
    echo "  ✗ Homebrew not installed"
fi
echo ""

# Disk space
echo "Disk Space:"
nix_store_size=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "unknown")
echo "  Nix store size: $nix_store_size"

# Check for old generations
old_gens=$(darwin-rebuild --list-generations | wc -l | tr -d ' ')
echo "  Generations: $old_gens"
if [ "$old_gens" -gt 10 ]; then
    echo "  ⚠ Consider running: darwin-rebuild --rollback or nix-collect-garbage -d"
fi
echo ""

echo "=== Health check complete ===" echo ""
