#!/usr/bin/env bash
# Master validation script for documentation
# Runs all documentation validation checks
# Usage: ./scripts/validate-docs.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Documentation Validation Suite       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

FAILURES=0

# Check 1: Link validation
echo -e "${YELLOW}[1/2]${NC} Validating documentation links..."
if python3 "$SCRIPT_DIR/check-doc-links.py" CLAUDE.md; then
    echo -e "${GREEN}      ✅ Link validation passed${NC}"
else
    echo -e "${RED}      ❌ Link validation failed${NC}"
    ((FAILURES++))
fi
echo ""

# Check 2: File count verification
echo -e "${YELLOW}[2/2]${NC} Verifying documentation file count..."
if "$SCRIPT_DIR/count-docs.sh" --warn; then
    echo -e "${GREEN}      ✅ File count verification passed${NC}"
else
    echo -e "${YELLOW}      ⚠️  File count verification warning${NC}"
    # Don't increment failures for warnings
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
if [[ $FAILURES -eq 0 ]]; then
    echo -e "${GREEN}║  ✅ All validation checks passed!     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}║  ❌ $FAILURES validation check(s) failed   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
