{ config, pkgs, lib, myLib, username, hostname, profileName, ... }:

{
  # Host-specific configuration for macbook-pro-m1-personal
  #
  # Secrets are loaded based on profileName (personal/work/minimal)

  imports = myLib.selectByProfile profileName {
    personal = [ ./secrets-personal.nix ];
    work = [ ./secrets-work.nix ];
    default = [];
  };

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
