#!/usr/bin/env bash
# validate-machine-config.sh
#
# Validate machine and user config files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== Config Validation ==="
echo ""

ERRORS=0

# Check user-config.nix
echo "Validating user-config.nix..."
if [ ! -f "${CONFIG_ROOT}/config/user-config.nix" ]; then
    echo "  ✗ File not found"
    ERRORS=$((ERRORS + 1))
else
    # Check required fields
    if ! grep -q "username" "${CONFIG_ROOT}/config/user-config.nix"; then
        echo "  ✗ Missing 'username' field"
        ERRORS=$((ERRORS + 1))
    fi

    if ! grep -q "fullName" "${CONFIG_ROOT}/config/user-config.nix"; then
        echo "  ✗ Missing 'fullName' field"
        ERRORS=$((ERRORS + 1))
    fi

    if ! grep -q "email" "${CONFIG_ROOT}/config/user-config.nix"; then
        echo "  ✗ Missing 'email' field"
        ERRORS=$((ERRORS + 1))
    fi

    if [ $ERRORS -eq 0 ]; then
        echo "  ✓ Valid"
    fi
fi

echo ""

# Check machine-config.nix
echo "Validating machine-config.nix..."
if [ ! -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    echo "  ✗ File not found"
    ERRORS=$((ERRORS + 1))
else
    # Check required fields
    if ! grep -q "machineId" "${CONFIG_ROOT}/config/machine-config.nix"; then
        echo "  ✗ Missing 'machineId' field"
        ERRORS=$((ERRORS + 1))
    fi

    if ! grep -q "machineType" "${CONFIG_ROOT}/config/machine-config.nix"; then
        echo "  ✗ Missing 'machineType' field"
        ERRORS=$((ERRORS + 1))
    fi

    if ! grep -q "description" "${CONFIG_ROOT}/config/machine-config.nix"; then
        echo "  ✗ Missing 'description' field"
        ERRORS=$((ERRORS + 1))
    fi

    # Check machineType is valid
    if grep -q 'machineType = "work"' "${CONFIG_ROOT}/config/machine-config.nix" || \
       grep -q 'machineType = "personal"' "${CONFIG_ROOT}/config/machine-config.nix"; then
        :  # Valid
    else
        echo "  ⚠️  machineType should be 'personal' or 'work'"
    fi

    if [ $ERRORS -eq 0 ]; then
        echo "  ✓ Valid"
    fi
fi

echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ Found $ERRORS error(s)"
    echo ""
    echo "To fix, run:"
    echo "  ./scripts/setup/configure.sh"
    exit 1
else
    echo "✅ All configs are valid"
    exit 0
fi
