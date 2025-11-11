#!/usr/bin/env bash
# Check that all secrets files are properly encrypted with SOPS
# Used by git hooks and can be run manually

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Find all secrets files that should be encrypted
# Pattern: hosts/*/secrets.yaml
secrets_files=$(find "$REPO_ROOT/hosts" -type f -name "secrets.yaml" 2>/dev/null || true)

if [ -z "$secrets_files" ]; then
    echo -e "${YELLOW}No secrets files found to check${NC}"
    exit 0
fi

echo "Checking secrets encryption status..."
echo ""

unencrypted_found=0

for file in $secrets_files; do
    # Get relative path for display
    rel_path="${file#$REPO_ROOT/}"

    if [ ! -f "$file" ]; then
        continue
    fi

    # Check for SOPS encryption markers
    # Encrypted files must have both 'sops:' metadata section and 'ENC[' encrypted values
    if grep -q "sops:" "$file" && grep -q "ENC\[" "$file"; then
        echo -e "${GREEN}✓${NC} $rel_path (encrypted)"
    else
        echo -e "${RED}✗${NC} $rel_path (UNENCRYPTED)"
        unencrypted_found=1
    fi
done

echo ""

if [ $unencrypted_found -eq 1 ]; then
    echo -e "${RED}ERROR: Unencrypted secrets files detected!${NC}"
    echo ""
    echo "You must encrypt these files before committing:"
    echo "  sops -e -i <file>"
    echo ""
    echo "Or use the edit command which auto-encrypts on save:"
    echo "  sops <file>"
    echo ""
    echo "For more info: see docs/guides/secrets.md"
    exit 1
else
    echo -e "${GREEN}All secrets files are properly encrypted${NC}"
    exit 0
fi
