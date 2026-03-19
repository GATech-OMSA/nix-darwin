#!/usr/bin/env bash
# Import sops-install-secrets binary
#
# Run this on the proxied machine BEFORE nix-rebuild.
# Installs the pre-built binary to a local path that the Nix overlay references.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_FILE="$SCRIPT_DIR/sops-install-secrets.gz"
CHECKSUM_FILE="$SCRIPT_DIR/.sha256"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/sops-install-secrets"

if [[ ! -f "$EXPORT_FILE" ]]; then
  echo "Error: $EXPORT_FILE not found"
  echo ""
  echo "Run ./cache/sops-nix/export.sh on a non-proxied machine first."
  exit 1
fi

# Verify checksum if available
if [[ -f "$CHECKSUM_FILE" ]]; then
  EXPECTED=$(cat "$CHECKSUM_FILE")
  ACTUAL=$(shasum -a 256 "$EXPORT_FILE" | cut -d' ' -f1)
  if [[ "$ACTUAL" != "$EXPECTED" ]]; then
    echo "Error: checksum mismatch"
    echo "  Expected: $EXPECTED"
    echo "  Actual:   $ACTUAL"
    echo ""
    echo "The binary may be corrupted or tampered with."
    echo "Re-run ./cache/sops-nix/export.sh on the source machine."
    exit 1
  fi
  echo "Checksum verified."
fi

mkdir -p "$INSTALL_DIR"

echo "Installing sops-install-secrets to $INSTALL_PATH..."
gunzip -c "$EXPORT_FILE" > "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# Verify the binary is executable and correct architecture
if ! file "$INSTALL_PATH" | /usr/bin/grep -q "Mach-O"; then
  echo "Warning: binary does not appear to be a macOS executable."
  echo "Check that it was exported on a compatible machine ($(uname -m))."
  exit 1
fi

echo ""
echo "Binary installed at: $INSTALL_PATH"
echo "Now run nix-rebuild — the overlay will use this binary."
