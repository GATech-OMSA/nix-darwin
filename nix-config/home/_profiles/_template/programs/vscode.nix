{ config, pkgs, lib, ... }:

{
  # VS Code configuration
  # Extensions managed by user via VS Code UI (not Nix)
  # Use backup-user-data / restore-user-data for migration

  programs.vscode = {
    enable = true;

    # No extensions managed by Nix
    # User installs extensions via VS Code UI
    #
    # Extension Management Workflow:
    # 1. Fresh machine: Install VS Code, manually install extensions
    # 2. Run: backup-user-data
    #    → Creates extension list + install script in user-data-${username}/vscode/
    # 3. Migrate to new machine: Run restore-user-data
    #    → Shows install script: ./user-data-${username}/vscode/install-extensions.sh
    #
    # Settings managed in user-data/, not Nix:
    # - Settings: ~/Library/Application Support/Code/User/settings.json
    # - Keybindings: ~/Library/Application Support/Code/User/keybindings.json
    # - Snippets: ~/Library/Application Support/Code/User/snippets/
    #
    # All backed up via: backup-user-data
    # All restored via: restore-user-data
  };
}
