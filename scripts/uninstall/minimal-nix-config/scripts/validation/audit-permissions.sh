#!/usr/bin/env bash
# audit-permissions.sh
#
# Audit file permissions for security

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=== File Permissions Audit ==="
echo ""

ISSUES=0

# Check config files aren't world-readable
echo "Checking config file permissions..."
if [ -f "${CONFIG_ROOT}/config/user-config.nix" ]; then
    perms=$(stat -f "%OLp" "${CONFIG_ROOT}/config/user-config.nix")
    if [ "$perms" != "600" ] && [ "$perms" != "640" ] && [ "$perms" != "644" ]; then
        echo "  ⚠️  user-config.nix: $perms (should be 600 or 644)"
        ISSUES=$((ISSUES + 1))
    else
        echo "  ✓ user-config.nix: $perms"
    fi
fi

if [ -f "${CONFIG_ROOT}/config/machine-config.nix" ]; then
    perms=$(stat -f "%OLp" "${CONFIG_ROOT}/config/machine-config.nix")
    if [ "$perms" != "600" ] && [ "$perms" != "640" ] && [ "$perms" != "644" ]; then
        echo "  ⚠️  machine-config.nix: $perms (should be 600 or 644)"
        ISSUES=$((ISSUES + 1))
    else
        echo "  ✓ machine-config.nix: $perms"
    fi
fi

echo ""

# Check workspace permissions (if it contains sensitive data)
if [ -d "${CONFIG_ROOT}/workspace" ]; then
    echo "Checking workspace permissions..."
    for dir in "${CONFIG_ROOT}"/workspace/*/; do
        if [ -d "$dir" ]; then
            perms=$(stat -f "%OLp" "$dir")
            machine=$(basename "$dir")
            if [ "$perms" != "700" ] && [ "$perms" != "755" ]; then
                echo "  ⚠️  workspace/$machine: $perms (consider 700 for privacy)"
            else
                echo "  ✓ workspace/$machine: $perms"
            fi
        fi
    done
    echo ""
fi

# Summary
if [ $ISSUES -gt 0 ]; then
    echo "❌ Found $ISSUES permission issue(s)"
    echo ""
    echo "To fix:"
    echo "  chmod 600 ${CONFIG_ROOT}/config/*.nix"
    echo "  chmod 700 ${CONFIG_ROOT}/workspace/*"
    exit 1
else
    echo "✅ All permissions look good"
    exit 0
fi
