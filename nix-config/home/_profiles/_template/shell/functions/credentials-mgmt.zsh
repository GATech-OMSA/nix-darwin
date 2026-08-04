# credentials-mgmt.zsh
# Workspace backup and restore functions

# ============================================
# WORKSPACE BACKUP & RESTORE
# ============================================

function backup-workspace() {
  local script="$HOME/nix-darwin/scripts/workspace/backup.sh"
  if [[ ! -f "$script" ]]; then
    echo "✗ Backup script not found: $script"
    return 1
  fi
  bash "$script" "$@"
}

function restore-workspace() {
  local script="$HOME/nix-darwin/scripts/workspace/restore.sh"
  if [[ ! -f "$script" ]]; then
    echo "✗ Restore script not found: $script"
    return 1
  fi
  bash "$script" "$@"
}
