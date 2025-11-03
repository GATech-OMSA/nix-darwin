{ config, pkgs, lib, username, ... }:

{
  # User account configuration
  # Note: User details are set in host-specific configs
  # This file contains shared user settings

  users.users.${username} = {
    shell = pkgs.zsh;
    # home is set in host-specific config
  };
}
