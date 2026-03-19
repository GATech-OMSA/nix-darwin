#!/usr/bin/env bash
# Export sops-install-secrets binary
#
# Run this on a machine WITHOUT proxy restrictions (e.g., personal machine).
# Extracts just the static Go binary (~14MB compressed) for use on proxied machines.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_FILE="$SCRIPT_DIR/sops-install-secrets.gz"
CHECKSUM_FILE="$SCRIPT_DIR/.sha256"

echo "Building sops-install-secrets..."
nix build github:Mic92/sops-nix#sops-install-secrets -o "$SCRIPT_DIR/.result"

BINARY="$SCRIPT_DIR/.result/bin/sops-install-secrets"
if [[ ! -f "$BINARY" ]]; then
  echo "Error: binary not found at $BINARY"
  echo "Checking result contents:"
  /usr/bin/find "$SCRIPT_DIR/.result" -type f
  exit 1
fi

echo "Compressing binary..."
gzip -c "$BINARY" > "$EXPORT_FILE"

# Save store path and checksum for verification
STORE_PATH=$(nix path-info github:Mic92/sops-nix#sops-install-secrets)
echo "$STORE_PATH" > "$SCRIPT_DIR/.store-path"
shasum -a 256 "$EXPORT_FILE" | cut -d' ' -f1 > "$CHECKSUM_FILE"

# Cleanup build symlink
rm -f "$SCRIPT_DIR/.result"

COMP_SIZE=$(du -h "$EXPORT_FILE" | cut -f1)
SHA=$(cat "$CHECKSUM_FILE")
echo ""
echo "Exported to: $EXPORT_FILE ($COMP_SIZE)"
echo "SHA256:      $SHA"
echo "Store path:  $STORE_PATH"
echo ""
echo "Next steps:"
echo "  1. Commit the .gz and .sha256 files to the repo"
echo "  2. On the proxied machine, run: ./cache/sops-nix/import.sh"
