# update.zsh
# System update functions
# Extracted from zsh.nix for maintainability

# ============================================
# UPDATE HELPERS
# ============================================

# Auto-restart shell in interactive mode (for functions that change shell config)
# WARNING: This function calls `exec zsh` which terminates the current shell immediately.
# MUST be called as the LAST statement in any function - no code after it will execute.
# Only call this after all cleanup, logging, and state updates are complete.
__update_restart_shell() {
  if [[ -o interactive ]]; then
    echo "Restarting shell..."
    exec zsh
  fi
}

# ============================================
# UPDATE FUNCTIONS
# ============================================

function update-nix() {
  echo "Updating Nix Darwin..."
  local errors=0
  local nix_dir="$HOME/nix-darwin"

  # Read machineId from config (hostname != flake config name)
  local machine_id
  machine_id=$(nix eval --raw --file "$nix_dir/config/machine-config.nix" machineId 2>/dev/null)
  if [ -z "$machine_id" ]; then
    echo "  error: failed to read machineId from config/machine-config.nix" >&2
    return 1
  fi

  echo "  Updating flake inputs..."
  cd "$nix_dir" || return 1

  # Stash uncommitted changes if any
  local had_changes=false
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    had_changes=true
    echo "  Stashing uncommitted changes..."
    git stash push -m "update-nix auto-stash $(date +%Y%m%d-%H%M%S)" --quiet
  fi

  if nix flake update; then
    echo "  Flake inputs updated"
  else
    echo "  error: flake update failed" >&2
    ((errors++))
  fi

  # Restore stashed changes
  if [[ "$had_changes" == "true" ]]; then
    echo "  Restoring stashed changes..."
    git stash pop --quiet
  fi

  echo "  Rebuilding darwin configuration..."
  if sudo FLAKE_ROOT="$nix_dir" darwin-rebuild switch --flake "$nix_dir#$machine_id" --impure; then
    echo "  Darwin rebuild completed"
  else
    echo "  error: darwin rebuild failed" >&2
    ((errors++))
  fi

  cd - > /dev/null

  if [ $errors -eq 0 ]; then
    echo "Nix update completed successfully"
    __update_restart_shell
  else
    echo "warning: nix update completed with $errors error(s)"
    return 1
  fi
}

function update-brew() {
  echo "Updating Homebrew..."
  local errors=0

  if command -v brew &> /dev/null; then
    echo "  Updating Homebrew..."
    if brew update; then
      echo "  Homebrew updated"
    else
      echo "  error: homebrew update failed" >&2
      ((errors++))
    fi

    echo "  Upgrading packages..."
    if brew upgrade; then
      echo "  Packages upgraded"
    else
      echo "  error: package upgrade failed" >&2
      ((errors++))
    fi

    echo "  Upgrading all casks (including auto-update apps)..."
    if brew commands | grep -q "^cu$"; then
      if brew cu -afy; then
        echo "  All casks upgraded"
      else
        echo "  error: cask upgrade failed" >&2
        ((errors++))
      fi
    else
      echo "  warning: brew-cask-upgrade not installed, skipping"
      echo "     Install: brew tap buo/cask-upgrade && brew install brew-cask-upgrade"
    fi

    echo "  Cleaning up..."
    if brew cleanup --prune=all; then
      echo "  Cleanup completed"
    else
      echo "  error: cleanup failed" >&2
      ((errors++))
    fi

    echo "  Running diagnostics..."
    brew doctor
  else
    echo "  warning: homebrew not found"
    return 1
  fi

  if [ $errors -eq 0 ]; then
    echo "✓ Homebrew update completed successfully"
  else
    echo "▸ Homebrew update completed with $errors error(s)"
    return 1
  fi
}

function update-mamba() {
  echo "→ Updating Micromamba..."
  local errors=0

  if command -v micromamba &> /dev/null; then
    echo "  → Updating micromamba environments..."
    # Update all environments dynamically using JSON for robust parsing
    local env_list=""
    if command -v jq &>/dev/null; then
      # Try JSON parsing first (more robust)
      local json_output
      if json_output=$(micromamba env list --json 2>/dev/null) && [[ -n "$json_output" ]]; then
        env_list=$(echo "$json_output" | jq -r '.envs[]' 2>/dev/null | xargs -I{} basename {} 2>/dev/null)
      fi
    fi
    # Fallback to text parsing if jq not available or JSON parsing failed
    if [[ -z "$env_list" ]]; then
      env_list=$(micromamba env list 2>/dev/null | tail -n +3 | awk '{print $1}')
    fi
    if [ -n "$env_list" ]; then
      for env in $env_list; do
        if [ "$env" != "base" ]; then  # Skip the base installation
          echo "    • Updating $env..."
          if micromamba update -n "$env" --all -y 2>/dev/null; then
            echo "    ✓ $env updated"
          else
            echo "    ▸ $env skipped or failed" >&2
            ((errors++))
          fi
        fi
      done
    else
      echo "    → No environments to update"
    fi
  else
    echo "  ▸ Micromamba not found"
    return 1
  fi

  if [ $errors -eq 0 ]; then
    echo "✓ Micromamba update completed successfully"
  else
    echo "▸ Micromamba update completed with $errors error(s)"
    return 1
  fi
}

function update-vscode() {
  echo "→ Updating VS Code extensions..."
  local errors=0

  if command -v code &> /dev/null; then
    local extensions
    extensions=$(code --list-extensions 2>/dev/null)
    if [ -n "$extensions" ]; then
      while IFS= read -r extension; do
        if ! code --install-extension "$extension" --force &> /dev/null; then
          ((errors++))
        fi
      done <<< "$extensions"
    fi

    if [ $errors -eq 0 ]; then
      echo "✓ VS Code extensions updated"
    else
      echo "▸ VS Code extensions updated ($errors failed)"
    fi
  else
    echo "▸ VS Code not found"
    return 1
  fi
}

function update-mas() {
  echo "→ Updating Mac App Store apps..."

  if command -v mas &> /dev/null; then
    if mas upgrade; then
      echo "✓ Mac App Store apps updated"
    else
      echo "✗ Mac App Store update failed" >&2
      return 1
    fi
  else
    echo "▸ mas not found (install with: brew install mas)"
    return 1
  fi
}

function update-dev() {
  echo "→ Quick development update..."
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
  echo "→ Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

  if [ $errors -eq 0 ]; then
    echo "✓ Development update completed!"
    __update_restart_shell
  else
    echo "▸ Completed with $errors error(s)"
    return 1
  fi
}

function update-system() {
  echo "→ System update..."
  local start_time=$(date +%s)
  local errors=0

  update-nix || ((errors++))
  echo ""
  update-brew || ((errors++))

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo ""
  echo "→ Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"

  if [ $errors -eq 0 ]; then
    echo "✓ System update completed!"
    __update_restart_shell
  else
    echo "▸ Completed with $errors error(s)"
    return 1
  fi
}

function update-all() {
  echo "✓ Complete system update..."
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

  echo "→ Checking for macOS updates..."
  softwareupdate --list
  echo ""

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  echo "================================================"
  echo "→ Update Summary:"
  echo "→ Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
  echo "✗ Errors: $total_errors"

  if [ $total_errors -eq 0 ]; then
    echo ""
    echo "✓ All updates completed successfully!"
    __update_restart_shell
  else
    echo ""
    echo "▸ Completed with $total_errors error(s)"
    return 1
  fi
}
