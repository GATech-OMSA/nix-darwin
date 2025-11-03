{ config, pkgs, username, hostname, ... }:

{
  # Host-specific configuration for work MacBook M3
  networking = {
    hostName = hostname;
    computerName = "Work MacBook Pro";
    localHostName = hostname;
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Set primary user
  system.primaryUser = username;

  # Homebrew configuration for work Mac
  # Allow toggle: true to use Homebrew, false to disable 
  homebrew.enable = false; 

  # System state version
  system.stateVersion = 5;
}
