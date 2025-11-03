{ config, pkgs, lib, ... }:

{
  # VS Code configuration - Fully declarative
  # Settings + Extensions managed by Nix
  # Using Home Manager vscode structure

  programs.vscode = {
    enable = true;

    # Use profiles (modern syntax)
    profiles.default = {
      # Extensions - using only well-tested packages from nixpkgs
      # More extensions can be added after verifying they exist
      extensions = with pkgs.vscode-extensions; [
        # Themes & Icons
        pkief.material-icon-theme

        # Git
        eamodio.gitlens

        # Python Development
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy

        # GitHub Copilot
        github.copilot
        github.copilot-chat

        # Formatters & Linting
        esbenp.prettier-vscode
        charliermarsh.ruff

        # Documentation & Markdown
        yzhang.markdown-all-in-one
        bierner.markdown-mermaid

        # Code Quality
        usernamehw.errorlens
        streetsidesoftware.code-spell-checker

        # Jupyter & Data Science
        ms-toolsai.jupyter
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-slideshow

        # Other utilities
        tamasfe.even-better-toml
      ];

      # Note: Install these manually via VS Code UI (not in nixpkgs):
      # - Vitesse theme (antfu.theme-vitesse)
      # - LeetCode (LeetCode.vscode-leetcode) - for interview prep
      # - Better Comments (aaron-bond.better-comments) - document thinking
      # - Draw.io Integration (hediet.vscode-drawio) - system design diagrams

      # User settings - MANAGED IN user-data/, NOT NIX
      # This allows editing settings in VS Code UI without rebuilding
      # Settings are backed up via: backup-user-data
      # Settings are synced via: sync-user-data
      # Settings file location: ~/Library/Application Support/Code/User/settings.json
      #
      # To restore settings on new machine: restore-user-data

      # userSettings removed - see comment above
      # Original settings preserved in user-data/user-content/vscode/settings.json

      # userSettings = {}; # Empty - managed in user-data/

      # Keybindings (can be customized)
      keybindings = [];
    };
  };
}
