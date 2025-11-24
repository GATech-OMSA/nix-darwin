# home/_profiles/minimal/default.nix
#
# Minimal profile for troubleshooting and lightweight environments

{ config, pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./aliases.nix
  ];

  # Minimal session variables
  home.sessionVariables = {
    MACHINE_MODE = "minimal";
  };

  # No starship - use basic prompt
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
