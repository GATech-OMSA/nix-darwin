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

# Resolve the darwin-rebuild binary: PATH first, then the well-known nix
# profile path (same fallback health-check.sh uses) for when
# /run/current-system / PATH isn't wired up yet. Echoes the resolved path,
# returns 1 with no output if neither is found.
__update_darwin_rebuild_bin() {
  if command -v darwin-rebuild &> /dev/null; then
    echo "darwin-rebuild"
    return 0
  elif [[ -x /nix/var/nix/profiles/system/sw/bin/darwin-rebuild ]]; then
    echo "/nix/var/nix/profiles/system/sw/bin/darwin-rebuild"
    return 0
  fi
  return 1
}

# ============================================
# UPDATE CORES (no `exec zsh` — safe to compose)
# ============================================

__update_nix_core() {
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

  # Restore stashed changes. If `nix flake update` reproduced a diff
  # identical to what's sitting in the stash (e.g. a prior failed run
  # already left flake.lock in that state), `git stash pop` conflicts
  # because the patch is already applied — drop the now-redundant stash
  # instead of popping it. On a genuine conflict, leave the stash intact
  # and tell the user how to resolve it rather than aborting silently.
  if [[ "$had_changes" == "true" ]]; then
    echo "  Restoring stashed changes..."
    local stash_diff current_diff
    stash_diff=$(git stash show -p stash@{0} 2>/dev/null)
    current_diff=$(git diff 2>/dev/null; git diff --cached 2>/dev/null)
    if [[ -n "$stash_diff" && "$stash_diff" == "$current_diff" ]]; then
      echo "  Stash matches the current working tree already — dropping it"
      git stash drop --quiet
    elif git stash pop --quiet; then
      echo "  Stashed changes restored"
    else
      echo "  error: stash pop conflicted — your changes are still safe in the stash." >&2
      echo "  Resolve manually: git -C \"$nix_dir\" stash list; git -C \"$nix_dir\" stash show -p stash@{0}" >&2
      cd - > /dev/null
      return 1
    fi
  fi

  # Security pre-flight ("y"): scan the candidate closure before switching.
  # Builds the new system (the switch below reuses that cached build), shows the
  # CVE delta, and prompts on findings. Skippable via SKIP_SECURITY_PREFLIGHT=1.
  # A non-zero return means the user declined — abort before touching the system.
  if ! FLAKE_ROOT="$nix_dir" bash "$nix_dir/scripts/maintenance/security-preflight.sh"; then
    echo "  Update aborted at security pre-flight (nothing switched)."
    cd - > /dev/null
    return 1
  fi

  local darwin_rebuild_bin
  if ! darwin_rebuild_bin=$(__update_darwin_rebuild_bin); then
    echo "  error: darwin-rebuild not found (checked PATH and /nix/var/nix/profiles/system/sw/bin)" >&2
    cd - > /dev/null
    return 1
  fi

  echo "  Rebuilding darwin configuration..."
  if sudo "$darwin_rebuild_bin" switch --flake "$nix_dir#$machine_id"; then
    echo "  Darwin rebuild completed"
  else
    echo "  error: darwin rebuild failed" >&2
    ((errors++))
  fi

  cd - > /dev/null

  if [ $errors -eq 0 ]; then
    echo "Nix update completed successfully"
    return 0
  else
    echo "warning: nix update completed with $errors error(s)"
    return 1
  fi
}

__update_brew_core() {
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

    # Greedy cask upgrade (incl. apps with auto_updates true) via brew's built-in
    # --greedy — replaces the third-party buo/cask-upgrade tap (`brew cu`), which
    # is now an untrusted tap and redundant. One less external dependency.
    echo "  Upgrading all casks (including auto-update apps)..."
    if brew upgrade --cask --greedy; then
      echo "  All casks upgraded"
    else
      echo "  error: cask upgrade failed" >&2
      ((errors++))
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
    return 0
  else
    echo "▸ Homebrew update completed with $errors error(s)"
    return 1
  fi
}

__update_vscode_core() {
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
      return 0
    else
      echo "▸ VS Code extensions updated ($errors failed)"
      return 1
    fi
  else
    echo "▸ VS Code not found"
    return 1
  fi
}

__update_mas_core() {
  echo "→ Updating Mac App Store apps..."

  if command -v mas &> /dev/null; then
    if mas upgrade; then
      echo "✓ Mac App Store apps updated"
      return 0
    else
      echo "✗ Mac App Store update failed" >&2
      return 1
    fi
  else
    echo "▸ mas not found (install with: brew install mas)"
    return 1
  fi
}

# ============================================
# UPDATE FUNCTIONS (public — compose cores, restart shell once)
# ============================================

function update-nix() {
  __update_nix_core
  local status=$?
  if [ $status -eq 0 ]; then
    __update_restart_shell
  fi
  return $status
}

function update-brew() {
  __update_brew_core
}

function update-vscode() {
  __update_vscode_core
}

function update-mas() {
  __update_mas_core
}

function update-dev() {
  echo "→ Quick development update..."
  local start_time=$(date +%s)
  local errors=0

  __update_nix_core || ((errors++))
  echo ""
  __update_vscode_core || ((errors++))

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

  __update_nix_core || ((errors++))
  echo ""
  __update_brew_core || ((errors++))

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

  __update_nix_core || ((total_errors++))
  echo ""
  __update_brew_core || ((total_errors++))
  echo ""
  __update_vscode_core || ((total_errors++))
  echo ""
  __update_mas_core || ((total_errors++))
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
