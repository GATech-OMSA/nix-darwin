#!/usr/bin/env bash

# Simple test of fzf multi-select

echo "Testing fzf multi-select functionality..."
echo ""
echo "Instructions:"
echo "  - Use arrow keys to navigate"
echo "  - Press TAB to select/deselect items"
echo "  - Press ENTER when done"
echo ""
echo "You should see a ✓ next to selected items"
echo ""
read -p "Press ENTER to start test..."

SELECTED=$(printf "Apple\nBanana\nCherry\nDate\nElderberry" | \
  fzf --multi \
      --prompt="Fruits > " \
      --header="Press TAB to select multiple items, ENTER when done" \
      --marker="✓ " \
      --pointer="▶ ")

echo ""
echo "You selected:"
echo "$SELECTED"
echo ""

if [ -z "$SELECTED" ]; then
  echo "Nothing selected"
else
  COUNT=$(echo "$SELECTED" | wc -l | tr -d ' ')
  echo "Total items selected: $COUNT"
fi
