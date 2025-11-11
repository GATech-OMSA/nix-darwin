# home/_profiles/_template/programs/eza.nix
#
# eza - Modern ls replacement with git integration

{ config, pkgs, lib, ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };
}
