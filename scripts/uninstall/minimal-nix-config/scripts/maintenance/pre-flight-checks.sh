#!/usr/bin/env bash
# pre-flight-checks.sh
#
# Pre-flight checks before darwin-rebuild

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Pre-Flight Checks ==="
echo ""

ERRORS=0

# Check Nix is installed
if ! command -v nix &> /dev/null; then
    echo "✗ Nix is not installed"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Nix is installed"
fi

# Check nix-darwin is installed
if ! command -v darwin-rebuild &> /dev/null; then
    echo "✗ darwin-rebuild not found"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ darwin-rebuild available"
fi

# Check config files exist
if [ ! -f "${CONFIG_ROOT}/config/user-config.nix" ]; then
    echo "✗ user-config.nix missing"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ user-config.nix exists"
fi

if [ ! -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    echo "✗ machine-config.nix missing"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ machine-config.nix exists"
fi

# Check flake is valid
cd "${CONFIG_ROOT}"
if nix flake check . &> /dev/null; then
    echo "✓ Flake is valid"
else
    echo "✗ Flake has errors"
    ERRORS=$((ERRORS + 1))
fi

# Check disk space
available_space=$(df -h /nix | awk 'NR==2 {print $4}')
echo "✓ Available disk space: $available_space"

echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ $ERRORS error(s) found"
    exit 1
else
    echo "✅ All checks passed"
    exit 0
fi
