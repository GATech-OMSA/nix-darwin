#!/usr/bin/env bash
# Count documentation files and verify against CLAUDE.md claims
# Usage: ./scripts/count-docs.sh [--warn|--strict]
# --warn: Only warn on mismatches (default)
# --strict: Exit 1 on mismatches

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MODE="${1:---warn}"

echo -e "${BLUE}📊 Counting documentation files...${NC}"

# Count actual markdown files in docs/
ACTUAL_COUNT=$(find docs -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo -e "  Found: ${GREEN}$ACTUAL_COUNT${NC} markdown files in docs/"

# Extract claimed count from CLAUDE.md
if [[ -f "CLAUDE.md" ]]; then
    # Look for pattern: "**N well-organized documentation files**" or "**N comprehensive guides**"
    CLAIMED_COUNT=$(grep -oE '\*\*[0-9]+ (well-organized documentation files|comprehensive guides)\*\*' CLAUDE.md | grep -oE '[0-9]+' | head -1)

    if [[ -n "$CLAIMED_COUNT" ]]; then
        echo -e "  CLAUDE.md claims: ${YELLOW}$CLAIMED_COUNT${NC} files"

        if [[ "$ACTUAL_COUNT" -eq "$CLAIMED_COUNT" ]]; then
            echo -e "${GREEN}✅ File count matches!${NC}"
            exit 0
        else
            echo -e "${RED}❌ Mismatch: $ACTUAL_COUNT actual vs $CLAIMED_COUNT claimed${NC}"
            echo -e "${YELLOW}   Update CLAUDE.md file count references${NC}"

            if [[ "$MODE" == "--strict" ]]; then
                exit 1
            else
                echo -e "${YELLOW}   ⚠️  Warning only (use --strict to fail)${NC}"
                exit 0
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Could not find file count claim in CLAUDE.md${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ CLAUDE.md not found${NC}"
    exit 1
fi
