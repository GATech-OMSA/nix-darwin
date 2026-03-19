#!/usr/bin/env bash
# Validate Secret Registry
#
# Purpose: Validate that the centralized secret registry is complete and accurate
# Usage: ./scripts/validate-secret-registry.sh [--verbose]
#
# This script:
# 1. Loads secret paths from the Nix registry
# 2. Checks which paths exist on this machine
# 3. Reports on found/missing paths (missing may exist on other machines)
# 4. Validates registry integrity

set -euo pipefail

# Require bash 4+ for associative arrays and mapfile
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "Error: This script requires bash 4 or higher"
  echo "Current version: ${BASH_VERSION}"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Usage: $0 [--verbose]"
      exit 1
      ;;
  esac
done

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "Validating Secret Registry"
echo "=============================="
echo ""

# Check if Nix is available
if ! command -v nix &> /dev/null; then
  echo -e "${RED}error: nix not found${NC}"
  echo "   This script requires Nix to be installed"
  exit 1
fi

# Check if flake exists
if [ ! -f "$REPO_ROOT/flake.nix" ]; then
  echo -e "${RED}error: flake.nix not found${NC}"
  echo "   Expected at: $REPO_ROOT/flake.nix"
  exit 1
fi

# Load secret paths from registry
echo "Loading paths from registry..."
mapfile -t SECRET_PATHS < <(
  nix eval "$REPO_ROOT#secretPaths" --json 2>/dev/null | jq -r '.[]' | sed "s|\${HOME}|$HOME|g"
)

if [ ${#SECRET_PATHS[@]} -eq 0 ]; then
  echo -e "${RED}error: failed to load secret paths from registry${NC}"
  exit 1
fi

echo "   Loaded ${#SECRET_PATHS[@]} paths from registry"
echo ""

# Load paths by type
declare -A PATHS_BY_TYPE
for type in aws database tokens ssh credentials general; do
  type_upper=$(echo "$type" | tr '[:lower:]' '[:upper:]')
  var_name="TYPE_${type_upper}_PATHS"

  # Load paths into array
  paths_json=$(nix eval "$REPO_ROOT#secretsByType.$type" --json 2>/dev/null | jq -r '.[]' | sed "s|\${HOME}|$HOME|g")
  count=$(echo "$paths_json" | wc -l | tr -d ' ')

  PATHS_BY_TYPE[$type]=$count

  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}$type:${NC} $count paths"
  fi
done

if [ "$VERBOSE" = true ]; then
  echo ""
fi

# Check each path
found_count=0
missing_count=0
missing_paths=()

echo "Checking path existence..."
echo ""

for path in "${SECRET_PATHS[@]}"; do
  # Skip paths with wildcards (glob patterns)
  if [[ "$path" == *"*"* ]]; then
    continue
  fi

  if [ -e "$path" ] || [ -L "$path" ]; then
    found_count=$((found_count + 1))
    if [ "$VERBOSE" = true ]; then
      echo -e "  ${GREEN}$path${NC}"
    fi
  else
    missing_count=$((missing_count + 1))
    missing_paths+=("$path")
    if [ "$VERBOSE" = true ]; then
      echo -e "  ${YELLOW}warning:${NC} $path (may exist on other machines)"
    fi
  fi
done

echo ""
echo "Summary"
echo "=========="
echo ""
echo "Total paths in registry: ${#SECRET_PATHS[@]}"
echo -e "${GREEN}Found on this machine:${NC}   $found_count"
echo -e "${YELLOW}Missing (machine-specific):${NC} $missing_count"
echo ""

# Show breakdown by type
echo "Breakdown by Type"
echo "===================="
echo ""
for type in "${!PATHS_BY_TYPE[@]}"; do
  count=${PATHS_BY_TYPE[$type]}
  printf "  %-12s %3d paths\n" "$type:" "$count"
done
echo ""

# List missing paths if any
if [ $missing_count -gt 0 ]; then
  echo "warning: missing Paths (machine-specific)"
  echo "===================================="
  echo ""
  echo "These paths are registered but don't exist on this machine."
  echo "This is normal if they are specific to other machines (e.g., work vs personal)."
  echo ""
  for path in "${missing_paths[@]}"; do
    echo "  • $path"
  done
  echo ""
fi

# Validate glob patterns
echo "Validating glob patterns..."
mapfile -t GLOB_PATTERNS < <(
  nix eval "$REPO_ROOT#secretGlobPatterns" --json 2>/dev/null | jq -r '.[]' | sed "s|\${HOME}|$HOME|g"
)

pattern_count=${#GLOB_PATTERNS[@]}
echo "   $pattern_count glob patterns registered"
echo ""

if [ "$VERBOSE" = true ]; then
  echo "Glob patterns:"
  for pattern in "${GLOB_PATTERNS[@]}"; do
    echo "  • $pattern"
  done
  echo ""
fi

# Validate registry metadata
echo "Validating registry metadata..."
nix eval "$REPO_ROOT#lib.secrets.meta" --json 2>/dev/null | jq '.'
echo ""

# Validate no duplicates
echo "Checking for duplicates..."
duplicates=$(printf '%s\n' "${SECRET_PATHS[@]}" | sort | uniq -d)
if [ -n "$duplicates" ]; then
  echo -e "${RED}error: duplicate paths found:${NC}"
  echo "$duplicates"
  exit 1
else
  echo "   No duplicates found"
fi
echo ""

# Final status
echo "=============================="
echo -e "${GREEN}Secret registry validation complete${NC}"
echo "=============================="
echo ""

# Exit with appropriate code
if [ $missing_count -gt 0 ]; then
  echo "Note: Some paths are missing on this machine (expected for machine-specific secrets)"
  exit 0
else
  exit 0
fi
