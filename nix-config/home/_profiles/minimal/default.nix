# home/_profiles/minimal/default.nix
#
# Minimal profile for troubleshooting and lightweight environments

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../_mixins/base.nix # Base configuration (zoxide, fzf, bat, eza, direnv, starship)
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
