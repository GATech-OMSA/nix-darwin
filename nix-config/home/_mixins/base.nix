{ config, pkgs, lib, ... }:

{
  # Base configuration for all machines
  # Essential tools and settings that every machine should have
  # Note: wget, curl, tree, htop installed system-wide in modules/shared/packages.nix

  # Zoxide - smarter cd command
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # NOTE: fzf is configured in _template/programs/fzf.nix
  # with custom zsh integration to suppress zle warnings

  # bat - better cat
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  # direnv - automatic environment switching
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # eza - modern ls replacement
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  # Starship prompt - Custom Catppuccin Powerline with AWS
  # Configuration is profile-specific (personal/work have different themes)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Atuin - magical shell history with SQLite storage
  # Replaces Ctrl-R with powerful fuzzy search, filter by exit code, directory, etc.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"  # Keep up-arrow for normal history navigation
    ];
    settings = {
      # Search mode: prefix (default), fulltext, fuzzy, skim
      search_mode = "fuzzy";
      # Filter mode: global (all history), host, session, directory
      filter_mode = "global";
      # Style: auto, full, compact
      style = "compact";
      # Show preview of full command
      show_preview = true;
      # Max preview height
      max_preview_height = 4;
      # Inline height (0 = full screen)
      inline_height = 0;
      # History filter - exclude commands starting with space
      history_filter = [
        "^\\s+"      # Ignore commands starting with space
        "^exit$"     # Ignore exit
        "^clear$"    # Ignore clear
      ];
      # Sync settings (disabled by default - enable if you want cloud sync)
      auto_sync = false;
      sync_frequency = "1h";
      # Enter accepts immediately (vs enter to select, tab to accept)
      enter_accept = true;
    };
  };
}
