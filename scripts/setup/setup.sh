#!/usr/bin/env bash
# setup.sh - DEPRECATED
#
# This script has been deprecated in favor of the three-script setup flow.
# Use the following scripts instead:
#
#   1. ./bootstrap.sh   - Install prerequisites (Nix, nix-darwin, SOPS, age)
#   2. ./configure.sh   - Create configuration files
#   3. ./activate.sh    - Build and activate nix-darwin
#
# For more information, see CLEAN-SETUP-STEPS.md

echo ""
echo "⚠️  DEPRECATED: setup.sh has been replaced"
echo ""
echo "Please use the new three-script flow instead:"
echo ""
echo "  1. ./bootstrap.sh   # Install prerequisites"
echo "  2. ./configure.sh   # Create configuration"
echo "  3. ./activate.sh    # Build and activate"
echo ""
echo "See CLEAN-SETUP-STEPS.md for detailed instructions."
echo ""
exit 1
