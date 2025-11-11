# home/_profiles/_template/programs/bat.nix
#
# bat - Better cat with syntax highlighting

{ config, pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };
}
