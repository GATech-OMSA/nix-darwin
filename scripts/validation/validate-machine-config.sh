#!/usr/bin/env bash
# Validates machine-config.nix

set -euo pipefail

if [ ! -f "config/machine-config.nix" ]; then
  echo "error: config/machine-config.nix not found"
  echo "Copy from config/machine-config.nix.template and customize"
  exit 1
fi

# Check for CHANGE-ME placeholders
if grep -q "CHANGE-ME" config/machine-config.nix; then
  echo "error: found CHANGE-ME placeholders in config/machine-config.nix"
  echo "Please customize all values"
  exit 1
fi

# Validate Nix syntax
if ! nix-instantiate --eval --strict config/machine-config.nix &>/dev/null; then
  echo "error: invalid Nix syntax in config/machine-config.nix"
  exit 1
fi

echo "Machine configuration valid"
