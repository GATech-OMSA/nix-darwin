{ config, pkgs, lib, username, hostname, machineType, ... }:

{
  # Host-specific configuration template
  # Copy this directory and customize for your new machine
  #
  # Secrets are automatically loaded based on machineType:
  #   - personal: loads secrets-personal.nix
  #   - work: loads secrets-work.nix

  # Conditional secret imports based on machine type
  imports =
    lib.optional (machineType == "personal") ./secrets-personal.nix ++
    lib.optional (machineType == "work") ./secrets-work.nix;

  networking = {
    hostName = hostname;
    computerName = "REPLACE_WITH_COMPUTER_NAME";  # e.g., "John's MacBook Pro"
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
  # REPLACE_WITH_HOMEBREW_CHOICE will be replaced with true or false
  homebrew.enable = REPLACE_WITH_HOMEBREW_CHOICE;

  # System state version (don't change this)
  system.stateVersion = 5;
}
