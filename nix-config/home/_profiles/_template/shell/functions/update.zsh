# update.zsh
# System update functions
# Extracted from zsh.nix for maintainability

# ============================================
# UPDATE FUNCTIONS
# ============================================

function update-nix() {
  echo "❄️  Updating Nix Darwin..."
  local errors=0
  local nix_dir="$HOME/nix-darwin"

  # Read machineId from config (hostname != flake config name)
  local machine_id
  machine_id=$(nix eval --raw --file "$nix_dir/config/machine-config.nix" machineId 2>/dev/null)
  if [ -z "$machine_id" ]; then
    echo "  ❌ Failed to read machineId from config/machine-config.nix" >&2
    return 1
  fi

  echo "  📦 Updating flake inputs..."
  cd "$nix_dir" || return 1

  if nix flake update; then
    echo "  ✅ Flake inputs updated"
  else
    echo "  ❌ Flake update failed" >&2
    ((errors++))
  fi

  echo "  📦 Rebuilding darwin configuration..."
  if sudo FLAKE_ROOT="$nix_dir" darwin-rebuild switch --flake "$nix_dir#$machine_id" --impure; then
    echo "  ✅ Darwin rebuild completed"
  else
    echo "  ❌ Darwin rebuild failed" >&2
    ((errors++))
  fi

  cd - > /dev/null

  if [ $errors -eq 0 ]; then
    echo "✅ Nix update completed successfully"
  else
    echo "⚠️  Nix update completed with $errors error(s)"
    return 1
  fi
}

function update-brew() {
  echo "🍺 Updating Homebrew..."
  local errors=0

  if command -v brew &> /dev/null; then
    echo "  📦 Updating Homebrew..."
    if brew update; then
      echo "  ✅ Homebrew updated"
    else
      echo "  ❌ Homebrew update failed" >&2
      ((errors++))
    fi

    echo "  📦 Upgrading packages..."
    if brew upgrade; then
      echo "  ✅ Packages upgraded"
    else
      echo "  ❌ Package upgrade failed" >&2
      ((errors++))
    fi

    echo "  📦 Upgrading all casks (including auto-update apps)..."
    if brew cu -afy; then
      echo "  ✅ All casks upgraded"
    else
      echo "  ❌ Cask upgrade failed" >&2
      ((errors++))
    fi

    echo "  🧹 Cleaning up..."
    if brew cleanup --prune=all; then
      echo "  ✅ Cleanup completed"
    else
      echo "  ❌ Cleanup failed" >&2
      ((errors++))
    fi

    echo "  🩺 Running diagnostics..."
    brew doctor
  else
    echo "  ⚠️  Homebrew not found"
    return 1
  fi

  if [ $errors -eq 0 ]; then
    echo "✅ Homebrew update completed successfully"
  else
    echo "⚠️  Homebrew update completed with $errors error(s)"
    return 1
  fi
}

function update-mamba() {
  echo "🐍 Updating Micromamba..."
  local errors=0

  if command -v micromamba &> /dev/null; then
    echo "  📦 Updating micromamba environments..."
    # Update all environments dynamically
    local env_list=$(micromamba env list | tail -n +3 | awk '{print $1}')
    if [ -n "$env_list" ]; then
      for env in $env_list; do
        if [ "$env" != "base" ]; then  # Skip the base installation
          echo "    • Updating $env..."
          if micromamba update -n "$env" --all -y 2>/dev/null; then
            echo "    ✅ $env updated"
          else
            echo "    ⚠️  $env skipped or failed" >&2
          fi
        fi
      done
    else
      echo "    ℹ️  No environments to update"
    fi
  else
    echo "  ⚠️  Micromamba not found"
    return 1
  fi

  if [ $errors -eq 0 ]; then
    echo "✅ Micromamba update completed successfully"
  else
    echo "⚠️  Micromamba update completed with $errors error(s)"
    return 1
  fi
}

function update-vscode() {
  echo "💻 Updating VS Code extensions..."

  if command -v code &> /dev/null; then
    code --list-extensions | while read extension; do
      code --install-extension "$extension" --force &> /dev/null
    done
    echo "✅ VS Code extensions updated"
  else
    echo "⚠️  VS Code not found"
    return 1
  fi
}

function update-mas() {
  echo "🍎 Updating Mac App Store apps..."

  if command -v mas &> /dev/null; then
    if mas upgrade; then
      echo "✅ Mac App Store apps updated"
    else
      echo "❌ Mac App Store update failed" >&2
      return 1
    fi
  else
    echo "⚠️  mas not found (install with: brew install mas)"
    return 1
  fi
}

function update-dev() {
  echo "⚡ Quick development update..."
  local start_time=$(date +%s)
  local errors=0

  update-nix || ((errors++))
  echo ""
  update-mamba || ((errors++))
  echo ""
  update-vscode || ((errors++))

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo ""
  echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

  if [ $errors -eq 0 ]; then
    echo "✅ Development update completed!"
  else
    echo "⚠️  Completed with $errors error(s)"
    return 1
  fi
}

function update-system() {
  echo "💻 System update..."
  local start_time=$(date +%s)
  local errors=0

  update-nix || ((errors++))
  echo ""
  update-brew || ((errors++))

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo ""
  echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

  if [ $errors -eq 0 ]; then
    echo "✅ System update completed!"
  else
    echo "⚠️  Completed with $errors error(s)"
    return 1
  fi
}

function update-all() {
  echo "🚀 Complete system update..."
  echo "================================================"

  local start_time=$(date +%s)
  local total_errors=0

  update-nix || ((total_errors++))
  echo ""
  update-brew || ((total_errors++))
  echo ""
  update-mamba || ((total_errors++))
  echo ""
  update-vscode || ((total_errors++))
  echo ""
  update-mas || ((total_errors++))
  echo ""

  echo "🍎 Checking for macOS updates..."
  softwareupdate --list
  echo ""

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo "================================================"
  echo "📊 Update Summary:"
  echo "⏱️  Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
  echo "❌ Errors: $total_errors"

  if [ $total_errors -eq 0 ]; then
    echo ""
    echo "✅ All updates completed successfully!"
    echo "💡 Consider restarting your terminal"
  else
    echo ""
    echo "⚠️  Completed with $total_errors error(s)"
    return 1
  fi
}
