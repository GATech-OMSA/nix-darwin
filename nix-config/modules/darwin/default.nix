{ config, pkgs, lib, userConfig ? {}, ... }:

# Darwin Modules - Module Imports
#
# Imports all macOS-specific configuration modules.

let
  # Extract proxy configuration from user-config.nix
  proxies = userConfig.proxies or {};
  goProxyEnabled = proxies.go.enabled or false;
in
{
  imports = [
    ./system.nix
    ./homebrew.nix
    ./fonts.nix
    ./security.nix
  ];

  # Disable Nix management - Determinate Nix handles daemon and installation
  # Determinate Nix manages its own daemon that conflicts with nix-darwin's native Nix management
  nix.enable = false;
  nix.settings = {
    experimental-features = "nix-command flakes";
    # Optimize builds
    max-jobs = "auto";
    # Keep Determinate Nix cache settings
    trusted-substituters = [ "https://cache.flakehub.com" ];

    # Allow Go proxy environment variables to pass through to build sandbox
    # Required for corporate proxy support with proxyVendor = true
    # These impure env vars are only used when packages explicitly enable proxyVendor
    impure-env-vars = lib.mkIf goProxyEnabled [
      "GOPROXY"
      "GOPRIVATE"
      "GOSUMDB"
    ];
  };

  # System-wide environment variables for Nix builds
  # These are available during darwin-rebuild and all Nix builds
  environment.variables = lib.mkIf goProxyEnabled {
    GOPROXY = "${proxies.go.url},direct";
    GOPRIVATE = proxies.go.private;
    GOSUMDB = "off";  # Corporate proxy cannot mirror Go's sum database
  };

  # Store optimization disabled - requires nix.enable = true
  # Determinate Nix handles optimization separately
  # nix.optimise.automatic = true;

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
