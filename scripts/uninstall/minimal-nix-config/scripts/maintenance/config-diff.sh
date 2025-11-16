#!/usr/bin/env bash
# config-diff.sh
#
# Show what changed in the configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=== Configuration Diff ==="
echo ""

cd "$CONFIG_ROOT"

# Check if in git repo
if [ ! -d .git ]; then
    echo "Not a git repository."
    echo ""
    echo "To track changes, initialize git:"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m 'Initial commit'"
    exit 1
fi

# Show status
echo -e "${CYAN}Git Status:${NC}"
git status --short
echo ""

# Show diff of tracked files
if git diff --quiet; then
    echo -e "${GREEN}No changes in tracked files${NC}"
else
    echo -e "${YELLOW}Changes in tracked files:${NC}"
    echo ""
    git diff --stat
    echo ""
    echo "To see detailed changes:"
    echo "  git diff"
fi

echo ""

# Show untracked files (excluding gitignored)
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
    echo -e "${YELLOW}Untracked files:${NC}"
    echo "$untracked" | sed 's/^/  /'
    echo ""
fi

# Show recent commits
echo -e "${CYAN}Recent commits:${NC}"
git log --oneline -5 || echo "  No commits yet"
echo ""

# Module-specific diffs
echo -e "${CYAN}Changes by module:${NC}"
echo ""

if git diff --quiet modules/shared/packages.nix; then
    echo -e "  packages.nix:  ${GREEN}no changes${NC}"
else
    echo -e "  packages.nix:  ${YELLOW}modified${NC}"
    added=$(git diff modules/shared/packages.nix | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')
    removed=$(git diff modules/shared/packages.nix | grep "^-" | grep -v "^---" | wc -l | tr -d ' ')
    echo "    +${added} -${removed} lines"
fi

if git diff --quiet modules/darwin/homebrew.nix; then
    echo -e "  homebrew.nix:  ${GREEN}no changes${NC}"
else
    echo -e "  homebrew.nix:  ${YELLOW}modified${NC}"
    added=$(git diff modules/darwin/homebrew.nix | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')
    removed=$(git diff modules/darwin/homebrew.nix | grep "^-" | grep -v "^---" | wc -l | tr -d ' ')
    echo "    +${added} -${removed} lines"
fi

if git diff --quiet modules/darwin/system.nix; then
    echo -e "  system.nix:    ${GREEN}no changes${NC}"
else
    echo -e "  system.nix:    ${YELLOW}modified${NC}"
fi

echo ""
echo "To view detailed diff:"
echo "  git diff"
echo ""
echo "To commit changes:"
echo "  git add <files>"
echo "  git commit -m 'Description of changes'"
echo ""
