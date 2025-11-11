# home/_profiles/_template/programs/zoxide.nix
#
# zoxide - Smarter cd command that learns your habits

{ config, pkgs, lib, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
