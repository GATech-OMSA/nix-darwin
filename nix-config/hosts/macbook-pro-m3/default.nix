{ config, pkgs, lib, username, hostname, machineType, ... }:

{
  # Host-specific configuration template
  # Copy this directory and customize for your new machine
  #
  # Secrets: Load appropriate secrets file based on machine type
  #   - personal: loads secrets-personal.nix
  #   - work: loads secrets-work.nix

  # Conditional secret imports based on machine type
  imports =
    lib.optional (machineType == "personal") ./secrets-personal.nix ++
    lib.optional (machineType == "work") ./secrets-work.nix;

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
