{ config, pkgs, lib, username, hostname, machineType, ... }:

{
  # Host-specific configuration template
  # Copy this directory and customize for your new machine
  #
  # Secrets: Only load sops-nix secrets for personal machines
  #   - personal: loads secrets-personal.nix (uses sops-nix)
  #   - work: uses Homebrew sops + manual secret management (corporate proxy workaround)

  # Conditional secret imports (only for personal - work uses Homebrew sops)
  imports = lib.optional (machineType == "personal") ./secrets-personal.nix;

  networking = {
    hostName = hostname;
    computerName = "DWCLQJ6L5V";  # e.g., "John's MacBook Pro"
    localHostName = hostname;
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Set primary user (required for some nix-darwin features)
  system.primaryUser = username;

  # Homebrew configuration (will be replaced by configure.sh)
  # false will be replaced with true or false
  homebrew.enable = false;

  # System state version (don't change this)
  system.stateVersion = 5;
}
