# home/_profiles/_template/programs/atuin.nix
#
# Atuin - Magical shell history with SQLite storage and fuzzy search

{ config, pkgs, lib, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [
      "--disable-up-arrow"  # Keep up-arrow for normal history navigation
    ];
    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
      show_preview = true;
      max_preview_height = 4;
      inline_height = 0;
      history_filter = [
        "^\\s+"      # Ignore commands starting with space
        "^exit$"
        "^clear$"
      ];
      auto_sync = false;
      sync_frequency = "1h";
      enter_accept = true;
      secrets_filter = true;  # Auto-filter AWS keys, tokens, passwords from history
      store_failed = true;    # Store failed commands for debugging
    };
  };
}
