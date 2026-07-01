# home/_profiles/personal/default.nix
#
# Personal profile configuration
# For: Learning, personal projects, hobby development

{ config, pkgs, lib, myLib, hostname, ... }:

{
  # Shared imports + starship wiring live in _template/profile-base.nix.
  imports = [
    (import ../_template/profile-base.nix { profileDir = ../personal; })
  ];

  # Personal-specific session variables
  home.sessionVariables = myLib.mkProfileSessionVars {
    mode = "home";
    awsProfile = "personal";
    workspace = "$HOME/Dev";
  };
}