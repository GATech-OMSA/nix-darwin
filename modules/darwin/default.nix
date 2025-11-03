{ config, pkgs, lib, ... }:

{
  # Import all darwin-specific modules
  imports = [
    ./system.nix
    ./homebrew.nix
    ./fonts.nix
    ./security.nix
  ];

  # Enable experimental features
  nix.settings = {
    experimental-features = "nix-command flakes";
    # Optimize builds
    max-jobs = "auto";
  };

  # Enable automatic store optimization (replaces auto-optimise-store)
  nix.optimise.automatic = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nix-daemon is now managed automatically by nix.enable
  # services.nix-daemon.enable = true;  # REMOVED - no longer needed

  # Zsh configuration (base setup, extended in Home Manager)
  programs.zsh = {
    enable = true;

    shellInit = ''
      # Enable completion
      autoload -Uz compinit && compinit

      # History configuration
      export HISTFILE="$HOME/.zsh_history"
      export HISTSIZE=10000
      export SAVEHIST=10000
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_FIND_NO_DUPS
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY

      # PATH management
      typeset -U PATH path
      path=(
        $HOME/bin
        $HOME/.local/bin
        /usr/local/bin
        /opt/homebrew/bin
        /opt/homebrew/sbin
        $path
      )
      export PATH
    '';
  };
}
