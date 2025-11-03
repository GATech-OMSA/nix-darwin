#!/bin/bash
# Backup non-secret application data and user content
# This backs up data that can't be managed declaratively by Nix

set -e

BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "📦 Backing up user data to $BACKUP_DIR"
echo ""

# App Configs
echo "🔧 Backing up application configs..."
mkdir -p "$BACKUP_DIR/app-configs"

# Claude Code
if [ -f ~/.claude.json ]; then
  cp ~/.claude.json "$BACKUP_DIR/app-configs/claude.json"
  echo "  ✅ Claude config"
fi

# Continue.dev
if [ -d ~/.continue ]; then
  mkdir -p "$BACKUP_DIR/app-configs/continue"
  cp ~/.continue/config.json "$BACKUP_DIR/app-configs/continue/" 2>/dev/null || true
  cp ~/.continue/config.ts "$BACKUP_DIR/app-configs/continue/" 2>/dev/null || true
  echo "  ✅ Continue.dev config"
fi

# Gemini
if [ -f ~/.gemini/settings.json ]; then
  mkdir -p "$BACKUP_DIR/app-configs/gemini"
  cp ~/.gemini/settings.json "$BACKUP_DIR/app-configs/gemini/"
  echo "  ✅ Gemini config"
fi

# iTerm2 preferences
if [ -f ~/Library/Preferences/com.googlecode.iterm2.plist ]; then
  mkdir -p "$BACKUP_DIR/app-configs/iterm2"
  cp ~/Library/Preferences/com.googlecode.iterm2.plist "$BACKUP_DIR/app-configs/iterm2/"
  echo "  ✅ iTerm2 preferences"
fi

# Cursor configs
if [ -d ~/.cursor ]; then
  mkdir -p "$BACKUP_DIR/app-configs/cursor"
  cp ~/.cursor/argv.json "$BACKUP_DIR/app-configs/cursor/" 2>/dev/null || true
  cp ~/.cursor/cli-config.json "$BACKUP_DIR/app-configs/cursor/" 2>/dev/null || true
  echo "  ✅ Cursor config"
fi

echo ""

# User Content
echo "📝 Backing up user content..."
mkdir -p "$BACKUP_DIR/user-content"

# VS Code custom snippets
if [ -d ~/Library/Application\ Support/Code/User/snippets ]; then
  mkdir -p "$BACKUP_DIR/user-content/vscode-snippets"
  rsync -av --exclude='.DS_Store' ~/Library/Application\ Support/Code/User/snippets/ "$BACKUP_DIR/user-content/vscode-snippets/" 2>/dev/null || true
  echo "  ✅ VS Code snippets"
fi

# VS Code spell dictionary
if [ -f ~/.vscode/spell-dictionary.txt ]; then
  mkdir -p "$BACKUP_DIR/user-content/vscode"
  cp ~/.vscode/spell-dictionary.txt "$BACKUP_DIR/user-content/vscode/"
  echo "  ✅ VS Code spell dictionary"
fi

# Jupyter configs (custom only)
if [ -d ~/.jupyter ]; then
  mkdir -p "$BACKUP_DIR/user-content/jupyter"
  # Only backup custom configs, not default ones
  for file in jupyter_lab_config.py jupyter_notebook_config.py; do
    if [ -f ~/.jupyter/$file ]; then
      cp ~/.jupyter/$file "$BACKUP_DIR/user-content/jupyter/"
    fi
  done
  echo "  ✅ Jupyter configs"
fi

# IPython configs
if [ -f ~/.ipython/profile_default/ipython_config.py ]; then
  mkdir -p "$BACKUP_DIR/user-content/ipython"
  cp ~/.ipython/profile_default/ipython_config.py "$BACKUP_DIR/user-content/ipython/"
  echo "  ✅ IPython config"
fi

# SSH known_hosts (not secret, but useful)
if [ -f ~/.ssh/known_hosts ]; then
  cp ~/.ssh/known_hosts "$BACKUP_DIR/ssh_known_hosts"
  echo "  ✅ SSH known_hosts"
fi

# Zoxide database (directory navigation history)
if [ -f ~/.z ]; then
  cp ~/.z "$BACKUP_DIR/zoxide_database"
  echo "  ✅ Zoxide database"
fi

# Claude todos only (projects are too large - 22M+)
if [ -d ~/.claude/todos ]; then
  mkdir -p "$BACKUP_DIR/user-content/claude"
  rsync -av --exclude='.DS_Store' ~/.claude/todos/ "$BACKUP_DIR/user-content/claude/todos/" 2>/dev/null || true
  echo "  ✅ Claude todos"
fi

echo ""
echo "✅ Backup complete!"
echo ""
echo "📍 Location: $BACKUP_DIR"
echo "💾 To save: Copy user-data/ to external drive or cloud storage"
echo ""
echo "Example:"
echo "  cp -r ~/nix-darwin/user-data /Volumes/ExternalDrive/nix-darwin-userdata-backup"
