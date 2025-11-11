#!/usr/bin/env bash

#
# check-doc-links.sh - Validate all markdown links in documentation
#
# Usage:
#   ./scripts/check-doc-links.sh              # Check internal links only
#   CHECK_EXTERNAL=true ./scripts/check-doc-links.sh  # Check all links
#

set -euo pipefail

# Configuration
DOCS_DIR="${DOCS_DIR:-docs}"
CHECK_EXTERNAL="${CHECK_EXTERNAL:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Verbose logging
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$@" >&2
    fi
}

# Check if file exists
check_internal_link() {
    local source_file="$1"
    local link="$2"
    local source_dir
    source_dir="$(dirname "$source_file")"

    # Remove anchor if present
    local file_path="${link%%#*}"

    # Skip if it's just an anchor
    if [[ -z "$file_path" ]]; then
        return 0
    fi

    # Resolve relative path
    local full_path
    if [[ "$file_path" == /* ]]; then
        # Absolute path from docs root
        full_path="$DOCS_DIR${file_path}"
    else
        # Relative path
        full_path="$source_dir/$file_path"
    fi

    # Normalize path
    if command -v python3 &>/dev/null; then
        full_path="$(python3 -c "import os; print(os.path.normpath('$full_path'))" 2>/dev/null || echo "$full_path")"
    fi

    log "  Checking: $link -> $full_path"

    if [[ ! -f "$full_path" ]]; then
        echo "$source_file: $link -> file not found: $full_path" >&2
        return 1
    fi

    return 0
}

# Check external URL
check_external_link() {
    local source_file="$1"
    local url="$2"

    log "  Checking external: $url"

    # Use curl with timeout
    if ! curl -s -f -L --max-time 10 -o /dev/null "$url" 2>/dev/null; then
        echo "$source_file: $url -> HTTP error or timeout" >&2
        return 1
    fi

    return 0
}

# Check links in a file
check_file() {
    local file="$1"
    local total=0
    local external=0
    local broken=0

    log "Checking $file..."

    # Extract links
    local links
    links=$(sed -n 's/.*](\([^)]*\)).*/\1/p' "$file" 2>/dev/null || true)

    if [[ -z "$links" ]]; then
        echo "0:0:0"  # total:external:broken
        return 0
    fi

    while IFS= read -r link; do
        [[ -z "$link" ]] && continue
        ((total++))

        # Categorize link
        if [[ "$link" =~ ^https?:// ]]; then
            ((external++))
            if [[ "$CHECK_EXTERNAL" == "true" ]]; then
                if ! check_external_link "$file" "$link"; then
                    ((broken++))
                fi
            fi
        elif [[ "$link" =~ ^mailto: ]] || [[ "$link" =~ ^# ]]; then
            # Skip mailto links and pure anchors
            :
        else
            # Internal link
            if ! check_internal_link "$file" "$link"; then
                ((broken++))
            fi
        fi
    done <<< "$links"

    echo "$total:$external:$broken"
}

# Main execution
main() {
    msg "$GREEN" "🔍 Scanning documentation links..."
    echo

    # Find all markdown files (use system find to avoid alias issues)
    local md_files
    mapfile -t md_files < <(/usr/bin/find "$DOCS_DIR" -type f -name "*.md" 2>/dev/null | sort)

    if [[ ${#md_files[@]} -eq 0 ]]; then
        msg "$RED" "❌ No markdown files found in $DOCS_DIR"
        exit 1
    fi

    msg "$BLUE" "Found ${#md_files[@]} markdown files"
    echo

    # Counters
    local total_links=0
    local total_external=0
    local total_broken=0
    local broken_files=0

    # Check each file
    for file in "${md_files[@]}"; do
        local result errors
        errors=$(mktemp)
        result=$(check_file "$file" 2>"$errors")

        IFS=':' read -r links external broken <<< "$result"

        # Add to totals (default to 0 if empty)
        total_links=$((total_links + ${links:-0}))
        total_external=$((total_external + ${external:-0}))
        total_broken=$((total_broken + ${broken:-0}))

        if [[ ${broken:-0} -gt 0 ]]; then
            ((broken_files++))
            msg "$RED" "❌ $file ($broken broken links)"
            cat "$errors"
            echo
        else
            msg "$GREEN" "✅ $file ($links links)"
        fi

        rm -f "$errors"
    done

    echo
    msg "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    msg "$GREEN" "📊 Link Check Summary"
    msg "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Total links found:        $total_links"
    echo "External links:           $total_external"

    if [[ "$CHECK_EXTERNAL" == "false" ]]; then
        msg "$YELLOW" "  (external links not checked - set CHECK_EXTERNAL=true to check)"
    fi

    echo

    if [[ $total_broken -gt 0 ]]; then
        msg "$RED" "❌ Broken links found:     $total_broken (in $broken_files files)"
        msg "$RED" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    else
        msg "$GREEN" "✅ All links valid!"
        msg "$GREEN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi
}

# Run main
main "$@"
