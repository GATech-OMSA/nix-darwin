{ config, pkgs, lib, username, hostname, profileName, ... }:

{
  # Host-specific configuration template
  # Copy this directory and customize for your new machine
  #
  # Secrets are loaded based on profileName (personal/work):
  #   - personal: loads secrets-personal.nix
  #   - work: loads secrets-work.nix

  # Conditional secret imports based on profile
  imports =
    lib.optional (profileName == "personal") ./secrets-personal.nix ++
    lib.optional (profileName == "work") ./secrets-work.nix;

  networking = {
    hostName = hostname;
    computerName = "Jimmy's MacBook Pro";  # e.g., "John's MacBook Pro"
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
  # true will be replaced with true or false
  homebrew.enable = true;

  # System state version (don't change this)
  system.stateVersion = 5;
}
