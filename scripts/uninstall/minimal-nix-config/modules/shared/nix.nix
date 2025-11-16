# nix.nix
#
# Nix daemon and settings configuration

{ config, pkgs, ... }:

{
  # Enable nix-daemon
  services.nix-daemon.enable = true;

  # Nix settings
  nix = {
    # Enable flakes and nix-command
    settings = {
      experimental-features = "nix-command flakes";

      # Build settings
      max-jobs = "auto";
      cores = 0;  # Use all cores

      # Trusted users
      trusted-users = [ "@admin" ];

      # Keep build logs
      keep-outputs = true;
      keep-derivations = true;

      # Sandbox (security)
      sandbox = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 7; };  # Run every Sunday
      options = "--delete-older-than 30d";
    };

    # Optimise store
    optimise = {
      automatic = true;
      interval = { Weekday = 7; Hour = 3; };  # Sunday 3am
    };
  };

  # Nix package
  nixpkgs.config.allowUnfree = true;
}
