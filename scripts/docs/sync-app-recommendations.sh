#!/usr/bin/env bash
#
# sync-app-recommendations.sh - Regenerate the installed-apps section of
# docs/app-recommendations.md from nix-config/modules/darwin/homebrew.nix.
#
# Reads the casks list and masApps attrset from homebrew.nix, then rewrites
# the block between `<!-- BEGIN GENERATED:apps -->` and
# `<!-- END GENERATED:apps -->` markers in docs/app-recommendations.md.
# Manually-curated text outside those markers is left untouched.
#
# Usage:
#   sync-app-recommendations.sh           # rewrite in place
#   sync-app-recommendations.sh --check   # exit 1 if drift, no writes
#
# Why pure-bash parsing (not nix eval): the pre-commit hook needs sub-second
# turnaround on every commit that touches *.nix. nix eval against
# darwinConfigurations takes 10–30s after a generation change. We own
# homebrew.nix and its format is controlled, so a regex parse is reliable.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="$REPO_ROOT/nix-config/modules/darwin/homebrew.nix"
DOC="$REPO_ROOT/docs/app-recommendations.md"
BEGIN_MARKER="<!-- BEGIN GENERATED:apps -->"
END_MARKER="<!-- END GENERATED:apps -->"

CHECK_ONLY=false
case "${1:-}" in
  --check) CHECK_ONLY=true ;;
  --help|-h)
    /usr/bin/sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
    exit 0
    ;;
  '') ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac

[[ -f "$SOURCE" ]] || { echo "Source not found: $SOURCE" >&2; exit 1; }
[[ -f "$DOC" ]] || { echo "Doc not found: $DOC" >&2; exit 1; }

# ============================================================================
# PARSE — extract (name, comment) tuples from a `name = [ ... ];` block
# in homebrew.nix. Skips commented-out lines (`# "foo"`) and section headers.
# Captures trailing inline comments after `# ` on the same line.
# ============================================================================
parse_list_block() {
  local block_name="$1"
  /usr/bin/awk -v name="$block_name" '
    BEGIN { inblk = 0 }
    # Block start: matches `  casks = [` (with optional whitespace)
    $0 ~ "^[[:space:]]*" name "[[:space:]]*=[[:space:]]*\\[" { inblk = 1; next }
    inblk && /^[[:space:]]*\];/ { inblk = 0; next }
    inblk {
      line = $0
      # Skip commented-out items: leading `#` then a quoted name
      if (line ~ /^[[:space:]]*#[[:space:]]*"/) next
      # Match "name" optionally followed by # comment
      if (match(line, /"[^"]+"/)) {
        item = substr(line, RSTART + 1, RLENGTH - 2)
        comment = ""
        rest = substr(line, RSTART + RLENGTH)
        if (match(rest, /#[[:space:]]*/)) {
          comment = substr(rest, RSTART + RLENGTH)
          # Strip trailing whitespace
          sub(/[[:space:]]+$/, "", comment)
        }
        printf "%s\t%s\n", item, comment
      }
    }
  ' "$SOURCE"
}

# Same idea for `masApps = { "Name" = 1234; }` attrset entries.
parse_attrset_block() {
  local block_name="$1"
  /usr/bin/awk -v name="$block_name" '
    BEGIN { inblk = 0 }
    $0 ~ "^[[:space:]]*" name "[[:space:]]*=[[:space:]]*\\{" { inblk = 1; next }
    inblk && /^[[:space:]]*\};/ { inblk = 0; next }
    inblk {
      line = $0
      if (line ~ /^[[:space:]]*#/) next
      # "Key Name" = 12345;
      if (match(line, /"[^"]+"[[:space:]]*=[[:space:]]*[0-9]+/)) {
        chunk = substr(line, RSTART, RLENGTH)
        # Extract name and id
        match(chunk, /"[^"]+"/); key = substr(chunk, RSTART + 1, RLENGTH - 2)
        match(chunk, /[0-9]+$/); id = substr(chunk, RSTART, RLENGTH)
        comment = ""
        rest = substr(line, RSTART + RLENGTH)
        if (match(rest, /#[[:space:]]*/)) {
          comment = substr(rest, RSTART + RLENGTH)
          sub(/[[:space:]]+$/, "", comment)
        }
        printf "%s\t%s\t%s\n", key, id, comment
      }
    }
  ' "$SOURCE"
}

# ============================================================================
# RENDER — build the generated block as a single string.
# Sorted alphabetically (case-insensitive) for stable diffs.
# ============================================================================
render_block() {
  local cask_lines mas_lines
  cask_lines=$(parse_list_block "casks" | LC_ALL=C /usr/bin/sort -f)
  mas_lines=$(parse_attrset_block "masApps" | LC_ALL=C /usr/bin/sort -f)

  local cask_count mas_count
  cask_count=$(printf '%s\n' "$cask_lines" | /usr/bin/awk 'NF{c++} END{print c+0}')
  mas_count=$(printf '%s\n' "$mas_lines" | /usr/bin/awk 'NF{c++} END{print c+0}')

  printf '%s\n' "$BEGIN_MARKER"
  printf '## Currently Installed (Generated)\n\n'
  printf '_This section is generated from `nix-config/modules/darwin/homebrew.nix` by_\n'
  printf '_`scripts/docs/sync-app-recommendations.sh`. Do not edit by hand —_\n'
  printf '_re-run via `just docs-apps` after editing `homebrew.nix`._\n\n'

  printf '### Casks (%d)\n\n' "$cask_count"
  printf '| Cask | Note |\n| --- | --- |\n'
  printf '%s\n' "$cask_lines" | while IFS=$'\t' read -r name comment; do
    [[ -z "$name" ]] && continue
    # Escape pipe characters in comments to keep the table rendering correct
    comment="${comment//|/\\|}"
    printf '| `%s` | %s |\n' "$name" "$comment"
  done

  printf '\n### Mac App Store (%d)\n\n' "$mas_count"
  printf '| App | App ID | Note |\n| --- | --- | --- |\n'
  printf '%s\n' "$mas_lines" | while IFS=$'\t' read -r app id comment; do
    [[ -z "$app" ]] && continue
    comment="${comment//|/\\|}"
    printf '| %s | `%s` | %s |\n' "$app" "$id" "$comment"
  done

  printf '\n%s\n' "$END_MARKER"
}

# ============================================================================
# REWRITE — replace the marker block in $DOC with the freshly rendered one.
# Errors loudly if markers are missing, asymmetric, or out of order.
# ============================================================================
rewrite_doc() {
  local rendered="$1"
  /usr/bin/grep -qF "$BEGIN_MARKER" "$DOC" || {
    echo "Begin marker not found in $DOC: $BEGIN_MARKER" >&2
    echo "Add the marker pair somewhere in the doc, then re-run." >&2
    exit 1
  }
  /usr/bin/grep -qF "$END_MARKER" "$DOC" || {
    echo "End marker not found in $DOC: $END_MARKER" >&2
    exit 1
  }

  local begin_line end_line
  begin_line=$(/usr/bin/grep -nF "$BEGIN_MARKER" "$DOC" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
  end_line=$(/usr/bin/grep -nF "$END_MARKER" "$DOC" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
  [[ "$end_line" -gt "$begin_line" ]] || {
    echo "End marker (line $end_line) not after begin marker (line $begin_line)" >&2
    exit 1
  }

  local tmp="$DOC.tmp"
  {
    /usr/bin/sed -n "1,$((begin_line - 1))p" "$DOC"
    printf '%s\n' "$rendered"
    /usr/bin/sed -n "$((end_line + 1)),\$p" "$DOC"
  } > "$tmp"
  /bin/mv "$tmp" "$DOC"
}

# ============================================================================
# MAIN
# ============================================================================
RENDERED=$(render_block)

if [[ "$CHECK_ONLY" == true ]]; then
  # Compose what the file *would* look like and diff against current
  begin_line=$(/usr/bin/grep -nF "$BEGIN_MARKER" "$DOC" 2>/dev/null | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
  end_line=$(/usr/bin/grep -nF "$END_MARKER" "$DOC" 2>/dev/null | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
  if [[ -z "$begin_line" || -z "$end_line" ]]; then
    echo "Markers missing in $DOC — run sync-app-recommendations.sh once to insert." >&2
    exit 1
  fi
  if ! /usr/bin/diff -u "$DOC" <(
    /usr/bin/sed -n "1,$((begin_line - 1))p" "$DOC"
    printf '%s\n' "$RENDERED"
    /usr/bin/sed -n "$((end_line + 1)),\$p" "$DOC"
  ) >/dev/null 2>&1; then
    echo "drift: $DOC is out of date relative to $SOURCE" >&2
    echo "fix:   just docs-apps" >&2
    exit 1
  fi
  exit 0
fi

rewrite_doc "$RENDERED"
echo "✓ Updated $(/usr/bin/basename "$DOC")"
