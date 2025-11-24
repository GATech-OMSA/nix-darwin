# nix.nix
#
# Nix daemon and build configuration
# Handles corporate proxy environments and build settings

{ config, pkgs, lib, ... }:

{
  nix = {
    # Use Nix daemon
    useDaemon = true;

    # Nix package to use
    package = pkgs.nix;

    # Build settings
    settings = {
      # Enable experimental features
      experimental-features = [ "nix-command" "flakes" ];

      # Substituters (binary caches) - prefer cached builds
      substituters = [
        "https://cache.nixos.org"
        "https://install.determinate.systems"
      ];

      trusted-substituters = [
        "https://cache.nixos.org"
        "https://cache.flakehub.com"
        "https://install.determinate.systems"
      ];

      # Trust substituter public keys
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
        "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
        "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
        "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
        "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
        "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
        "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
      ];

      # Build settings for corporate environments
      # Prefer substitutes to avoid building from source
      # This helps when behind corporate proxies that block package downloads
      builders-use-substitutes = true;

      # Don't warn about dirty Git trees (useful during development)
      warn-dirty = false;

      # Maximum number of parallel build jobs
      max-jobs = "auto";
      cores = 0;  # Use all cores

      # Sandbox settings (macOS doesn't support full sandbox)
      sandbox = false;

      # Allow unfree packages (needed for some tools)
      allow-unfree = true;
    };

    # Garbage collection settings
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;  # Sunday
        Hour = 2;     # 2 AM
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    # Extra Nix configuration
    extraOptions = ''
      # Keep build logs for debugging
      keep-build-log = true

      # Extra platforms (for Rosetta on Apple Silicon)
      extra-platforms = aarch64-darwin x86_64-darwin

      # HTTP/HTTPS timeouts for corporate proxies
      connect-timeout = 10
    '';
  };
}
