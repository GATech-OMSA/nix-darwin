#!/usr/bin/env bash
#
# System Maintenance & Cleanup
#
# Comprehensive maintenance script for macOS, Nix, and Homebrew.
# Cleans up caches, logs, and temporary files to recover disk space.
#
# Usage:
#   system-cleanup.sh          # Interactive mode
#   system-cleanup.sh --force  # Skip confirmations
#

set -e

# ============================================ 
# COLORS
# ============================================ 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FORCE=false
if [[ "$1" == "--force" ]]; then
  FORCE=true
fi

confirm() {
  if [[ "$FORCE" == "true" ]]; then return 0; fi
  read -p "❓ $1 (y/N) " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]]
}

header() {
  echo -e "\n${BLUE}==== $1 ====${NC}"
}

success() {
  echo -e "${GREEN}✅ $1${NC}"
}

# ============================================ 
# NIX CLEANUP
# ============================================ 
header "Nix Maintenance"

if confirm "Run Nix garbage collection (removes old generations)?"; then
  echo "🧹 Cleaning up Nix store..."
  nix-collect-garbage -d
  success "Nix garbage collected"
fi

if confirm "Optimise Nix store (links duplicate files)?"; then
  echo "⚙️  Optimising Nix store..."
  nix-store --optimise
  success "Nix store optimised"
fi

# ============================================ 
# HOMEBREW CLEANUP
# ============================================ 
header "Homebrew Maintenance"

if command -v brew &> /dev/null; then
  if confirm "Clean up Homebrew cache and old versions?"; then
    echo "🧹 Running brew cleanup..."
    brew cleanup -s
    rm -rf "$(brew --cache)"
    success "Homebrew cleaned"
  fi
else
  echo "ℹ️  Homebrew not found, skipping."
fi

# ============================================
# MACOS CLEANUP
# ============================================
header "macOS Maintenance"

if confirm "Clear user caches (safe) and system caches (best effort)?"; then
  echo "🧹 Clearing user caches (~/Library/Caches)..."
  rm -rf ~/Library/Caches/*
  success "User caches cleared"

  echo "🧹 Clearing system caches (/Library/Caches)..."
  echo "   (Note: Some system files are protected by SIP - ignoring errors)"
  sudo rm -rf /Library/Caches/* 2>/dev/null || true
  success "System caches cleared (allowed files only)"
fi

if confirm "Clear logs?"; then
  echo "🧹 Clearing user logs..."
  rm -rf ~/Library/Logs/*
  
  echo "🧹 Clearing system logs..."
  sudo rm -rf /private/var/log/* 2>/dev/null || true
  sudo rm -rf /Library/Logs/* 2>/dev/null || true
  success "Logs cleared"
fi
if confirm "Empty Trash?"; then
  echo "🗑️  Emptying Trash..."
  rm -rf ~/.Trash/*
  success "Trash emptied"
fi

# ============================================ 
# DOCKER CLEANUP
# ============================================ 
if command -v docker &> /dev/null; then
  header "Docker Maintenance"
  if confirm "Prune unused Docker data (containers, images, networks)?"; then
    docker system prune -f
    success "Docker system pruned"
  fi
fi

header "Maintenance Complete"
df -h / | tail -n 1 | awk '{print "📍 Remaining disk space: " $4}'
