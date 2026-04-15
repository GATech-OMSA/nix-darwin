{ config, pkgs, lib, inputs, username, userConfig ? {}, ... }:

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
    ./packages.nix
    ./builders.nix
  ];

  # Disable Nix management - Determinate Nix handles daemon and installation
  # Determinate Nix manages its own daemon that conflicts with nix-darwin's native Nix management
  nix.enable = false;

  # Manage /etc/nix/nix.custom.conf declaratively
  # Determinate Nix !include's this file, making it the correct mechanism for
  # injecting settings — nix.settings is dead code when nix.enable = false.
  environment.etc."nix/nix.custom.conf".text = ''
    # Managed by nix-darwin — do not edit directly.
    # Source: nix-config/modules/darwin/default.nix

    # ==== Determinate Nix installer defaults ====
    # Store optimization — deduplicate identical files via hard links
    auto-optimise-store = true

    # Auto garbage collection — safety net when disk runs low
    min-free = 10737418240
    max-free = 21474836480

    # ==== Security ====
    # Isolate builds from the host environment
    sandbox = true

    # Allow root and the primary user to manage trusted substituters
    trusted-users = root ${username}

    # ==== Distributed builds ====
    # Let remote builders fetch from cache.nixos.org instead of uploading from local
    builders-use-substitutes = true
  '' + lib.optionalString goProxyEnabled ''

    # ==== Corporate proxy support ====
    # Allow Go proxy environment variables to pass through to the build sandbox.
    # Required when Go packages use proxyVendor = true behind a corporate proxy.
    impure-env-vars = GOPROXY GOPRIVATE GOSUMDB
  '';

  # Pin nixpkgs in the flake registry to the flake.lock-locked version.
  # Determinate Nix ships a global registry pointing to FlakeHub's weekly nixpkgs,
  # so `nix shell nixpkgs#hello` resolves to a different nixpkgs than the flake.
  # Cannot use nix.registry (gated behind nix.enable) so write the file directly.
  environment.etc."nix/registry.json".text = builtins.toJSON {
    version = 2;
    flakes = [
      {
        from  = { type = "indirect"; id = "nixpkgs"; };
        to    = { type = "path"; path = inputs.nixpkgs.outPath; };
        exact = true;
      }
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

  # Create macOS aliases in /Applications for Nix-installed GUI apps
  # Without this, Nix apps only appear in /Applications/Nix Apps/ and
  # Spotlight/Dock can't find them at /Applications/AppName.app
  system.activationScripts.postActivation.text = ''
    nixAppsDir="/Applications/Nix Apps"
    if [ -d "$nixAppsDir" ]; then
      echo "Creating macOS aliases for Nix apps in /Applications..."
      for app in "$nixAppsDir"/*.app; do
        [ -e "$app" ] || continue
        appName=$(basename "$app")
        target="/Applications/$appName"
        # Remove stale alias if it exists
        if [ -e "$target" ] || [ -L "$target" ]; then
          /bin/rm -rf "$target"
        fi
        ${pkgs.mkalias}/bin/mkalias "$app" "$target"
      done
    fi
  '';

  # Zsh configuration (base setup, extended in Home Manager)
  programs.zsh = {
    enable = true;
    enableCompletion = false; # Disable system-wide compinit (handled by Home Manager)

    shellInit = ''
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
