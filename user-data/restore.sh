#!/bin/bash
# Restore non-secret application data and user content
# Run this after setting up a new machine and cloning nix-darwin

set -e

BACKUP_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "📦 Restoring user data from $BACKUP_DIR"
echo ""

if [ ! -d "$BACKUP_DIR/app-configs" ] && [ ! -d "$BACKUP_DIR/user-content" ]; then
  echo "❌ No backups found in $BACKUP_DIR"
  echo "   Run backup.sh on your old machine first, then copy user-data/ folder"
  exit 1
fi

# App Configs
if [ -d "$BACKUP_DIR/app-configs" ]; then
  echo "🔧 Restoring application configs..."

  # Claude Code
  if [ -f "$BACKUP_DIR/app-configs/claude.json" ]; then
    cp "$BACKUP_DIR/app-configs/claude.json" ~/.claude.json
    echo "  ✅ Claude config"
  fi

  # Continue.dev
  if [ -d "$BACKUP_DIR/app-configs/continue" ]; then
    mkdir -p ~/.continue
    cp "$BACKUP_DIR/app-configs/continue/config.json" ~/.continue/ 2>/dev/null || true
    cp "$BACKUP_DIR/app-configs/continue/config.ts" ~/.continue/ 2>/dev/null || true
    echo "  ✅ Continue.dev config"
  fi

  # Gemini
  if [ -f "$BACKUP_DIR/app-configs/gemini/settings.json" ]; then
    mkdir -p ~/.gemini
    cp "$BACKUP_DIR/app-configs/gemini/settings.json" ~/.gemini/
    echo "  ✅ Gemini config"
  fi

  # iTerm2 preferences
  if [ -f "$BACKUP_DIR/app-configs/iterm2/com.googlecode.iterm2.plist" ]; then
    mkdir -p ~/Library/Preferences
    cp "$BACKUP_DIR/app-configs/iterm2/com.googlecode.iterm2.plist" ~/Library/Preferences/
    echo "  ✅ iTerm2 preferences"
  fi

  # Cursor configs
  if [ -d "$BACKUP_DIR/app-configs/cursor" ]; then
    mkdir -p ~/.cursor
    cp "$BACKUP_DIR/app-configs/cursor/argv.json" ~/.cursor/ 2>/dev/null || true
    cp "$BACKUP_DIR/app-configs/cursor/cli-config.json" ~/.cursor/ 2>/dev/null || true
    echo "  ✅ Cursor config"
  fi

  echo ""
fi

# User Content
if [ -d "$BACKUP_DIR/user-content" ]; then
  echo "📝 Restoring user content..."

  # VS Code custom snippets
  if [ -d "$BACKUP_DIR/user-content/vscode-snippets" ]; then
    mkdir -p ~/Library/Application\ Support/Code/User/snippets
    rsync -av --exclude='.DS_Store' "$BACKUP_DIR/user-content/vscode-snippets/" ~/Library/Application\ Support/Code/User/snippets/ 2>/dev/null || true
    echo "  ✅ VS Code snippets"
  fi

  # VS Code settings (NOT managed by Nix)
  if [ -f "$BACKUP_DIR/user-content/vscode/settings.json" ]; then
    mkdir -p ~/Library/Application\ Support/Code/User
    cp "$BACKUP_DIR/user-content/vscode/settings.json" ~/Library/Application\ Support/Code/User/
    echo "  ✅ VS Code settings.json"
  fi

  # VS Code spell dictionary
  if [ -f "$BACKUP_DIR/user-content/vscode/spell-dictionary.txt" ]; then
    mkdir -p ~/.vscode
    cp "$BACKUP_DIR/user-content/vscode/spell-dictionary.txt" ~/.vscode/
    echo "  ✅ VS Code spell dictionary"
  fi

  # VS Code argv.json (CLI config)
  if [ -f "$BACKUP_DIR/user-content/vscode/argv.json" ]; then
    mkdir -p ~/.vscode
    cp "$BACKUP_DIR/user-content/vscode/argv.json" ~/.vscode/
    echo "  ✅ VS Code argv.json"
  fi

  # Jupyter configs
  if [ -d "$BACKUP_DIR/user-content/jupyter" ]; then
    mkdir -p ~/.jupyter
    cp "$BACKUP_DIR/user-content/jupyter/"* ~/.jupyter/ 2>/dev/null || true
    echo "  ✅ Jupyter configs"
  fi

  # IPython configs
  if [ -f "$BACKUP_DIR/user-content/ipython/ipython_config.py" ]; then
    mkdir -p ~/.ipython/profile_default
    cp "$BACKUP_DIR/user-content/ipython/ipython_config.py" ~/.ipython/profile_default/
    echo "  ✅ IPython config"
  fi

  echo ""
fi

# SSH known_hosts
if [ -f "$BACKUP_DIR/ssh_known_hosts" ]; then
  mkdir -p ~/.ssh
  cp "$BACKUP_DIR/ssh_known_hosts" ~/.ssh/known_hosts
  chmod 600 ~/.ssh/known_hosts
  echo "✅ SSH known_hosts"
  echo ""
fi

# Zoxide database
if [ -f "$BACKUP_DIR/zoxide_database" ]; then
  cp "$BACKUP_DIR/zoxide_database" ~/.z
  echo "✅ Zoxide database"
  echo ""
fi

# Claude todos only (projects not backed up - too large)
if [ -d "$BACKUP_DIR/user-content/claude/todos" ]; then
  mkdir -p ~/.claude/todos
  rsync -av --exclude='.DS_Store' "$BACKUP_DIR/user-content/claude/todos/" ~/.claude/todos/ 2>/dev/null || true
  echo "✅ Claude todos"
  echo ""
fi

echo "✅ Restore complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Encrypted secrets are already restored by nix-darwin (sops-nix)"
echo "  2. If this is a new machine, restart iTerm2 to load preferences"
echo "  3. Restart VS Code to load custom snippets"
