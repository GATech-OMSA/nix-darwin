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

# Docker configs (user preferences, NOT daemon settings)
if [ -f ~/.docker/config.json ]; then
  mkdir -p "$BACKUP_DIR/app-configs/docker"
  cp ~/.docker/config.json "$BACKUP_DIR/app-configs/docker/"
  echo "  ✅ Docker config"
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

# VS Code settings (NOT managed by Nix)
if [ -f ~/Library/Application\ Support/Code/User/settings.json ]; then
  mkdir -p "$BACKUP_DIR/user-content/vscode"
  cp ~/Library/Application\ Support/Code/User/settings.json "$BACKUP_DIR/user-content/vscode/"
  echo "  ✅ VS Code settings.json"
fi

# VS Code spell dictionary
if [ -f ~/.vscode/spell-dictionary.txt ]; then
  mkdir -p "$BACKUP_DIR/user-content/vscode"
  cp ~/.vscode/spell-dictionary.txt "$BACKUP_DIR/user-content/vscode/"
  echo "  ✅ VS Code spell dictionary"
fi

# VS Code argv.json (CLI config)
if [ -f ~/.vscode/argv.json ]; then
  mkdir -p "$BACKUP_DIR/user-content/vscode"
  cp ~/.vscode/argv.json "$BACKUP_DIR/user-content/vscode/"
  echo "  ✅ VS Code argv.json"
fi

# VS Code extensions list + install script
if [ -d ~/.vscode/extensions ]; then
  mkdir -p "$BACKUP_DIR/vscode"

  # Generate extensions list (filter out symlinks from Nix)
  ls -1 ~/.vscode/extensions | grep -v "^extensions.json$" > "$BACKUP_DIR/vscode/extensions-list.txt"

  local ext_count=$(wc -l < "$BACKUP_DIR/vscode/extensions-list.txt" 2>/dev/null | tr -d ' ')

  # Generate install script
  cat > "$BACKUP_DIR/vscode/install-extensions.sh" <<'INSTALL_SCRIPT'
#!/bin/bash
# Auto-generated: Install VS Code extensions from backup
# Run this script to restore VS Code extensions on a new machine

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_LIST="$SCRIPT_DIR/extensions-list.txt"

if [ ! -f "$EXT_LIST" ]; then
  echo "❌ Extensions list not found: $EXT_LIST"
  exit 1
fi

echo "📦 Installing VS Code extensions..."
echo ""

installed=0
failed=0

while IFS= read -r ext; do
  # Skip empty lines
  if [ -z "$ext" ]; then
    continue
  fi

  # Extract extension ID (format: publisher.name-version)
  # Remove version number to get just publisher.name
  ext_id=$(echo "$ext" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*//')

  # Skip if looks like a symlink or invalid
  if [[ "$ext" == *"->"* ]] || [[ ! "$ext_id" =~ \. ]]; then
    continue
  fi

  echo "📦 Installing: $ext_id"
  if code --install-extension "$ext_id" 2>/dev/null; then
    ((installed++))
  else
    echo "   ⚠️  Failed to install: $ext_id"
    ((failed++))
  fi
done < "$EXT_LIST"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation complete!"
echo "   Installed: $installed extensions"
if [ $failed -gt 0 ]; then
  echo "   Failed: $failed extensions"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INSTALL_SCRIPT

  chmod +x "$BACKUP_DIR/vscode/install-extensions.sh"

  echo "  ✅ VS Code extensions ($ext_count extensions + install script)"
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

# Claude configuration and data
if [ -d ~/.claude ]; then
  mkdir -p "$BACKUP_DIR/app-configs/claude"

  # Backup framework files (*.md)
  for file in ~/.claude/*.md; do
    if [ -f "$file" ]; then
      cp "$file" "$BACKUP_DIR/app-configs/claude/" 2>/dev/null || true
    fi
  done

  # Backup settings.json
  if [ -f ~/.claude/settings.json ]; then
    cp ~/.claude/settings.json "$BACKUP_DIR/app-configs/claude/"
  fi

  # Backup .superclaude-metadata.json
  if [ -f ~/.claude/.superclaude-metadata.json ]; then
    cp ~/.claude/.superclaude-metadata.json "$BACKUP_DIR/app-configs/claude/"
  fi

  # Backup custom commands (if exists)
  if [ -d ~/.claude/commands ]; then
    mkdir -p "$BACKUP_DIR/app-configs/claude/commands"
    rsync -av --exclude='.DS_Store' ~/.claude/commands/ "$BACKUP_DIR/app-configs/claude/commands/" 2>/dev/null || true
  fi

  # Backup custom agents (if exists)
  if [ -d ~/.claude/agents ]; then
    mkdir -p "$BACKUP_DIR/app-configs/claude/agents"
    rsync -av --exclude='.DS_Store' ~/.claude/agents/ "$BACKUP_DIR/app-configs/claude/agents/" 2>/dev/null || true
  fi

  # Backup todos (user-content, not app-configs)
  if [ -d ~/.claude/todos ]; then
    mkdir -p "$BACKUP_DIR/user-content/claude/todos"
    rsync -av --exclude='.DS_Store' ~/.claude/todos/ "$BACKUP_DIR/user-content/claude/todos/" 2>/dev/null || true
  fi

  echo "  ✅ Claude config and data"
fi

echo ""
echo "✅ Backup complete!"
echo ""
echo "📍 Location: $BACKUP_DIR"
echo "💾 To save: Copy this directory to external drive or cloud storage"
echo ""
echo "Example:"
echo "  cp -r $BACKUP_DIR /Volumes/ExternalDrive/nix-darwin-userdata-backup"
