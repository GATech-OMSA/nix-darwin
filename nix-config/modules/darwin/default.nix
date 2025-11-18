{ config, pkgs, lib, ... }:

# Darwin Modules - Module Imports
#
# Imports all macOS-specific configuration modules.

{
  imports = [
    ./system.nix
    ./homebrew.nix
    ./fonts.nix
    ./security.nix
  ];

  # Disable nix-darwin's Nix management - Determinate Nix handles this
  # Determinate Nix manages the daemon, /etc/nix/nix.conf, and Nix installation
  nix.enable = false;

  # Note: nix.settings and nix.optimise are not available when nix.enable = false
  # Determinate Nix provides its own configuration via /etc/nix/nix.conf

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nix-daemon is now managed automatically by Determinate Nix
  # services.nix-daemon.enable = true;  # REMOVED - no longer needed

  # Fix Home Manager permissions issue - ensure user owns .local/state
  # This prevents "Permission denied" errors during Home Manager activation
  system.activationScripts.preActivation.text = ''
    for user_home in /Users/*; do
      user=$(basename "$user_home")
      if [ -d "$user_home/.local/state" ]; then
        chown -R "$user:staff" "$user_home/.local/state" 2>/dev/null || true
      fi
    done
  '';

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
