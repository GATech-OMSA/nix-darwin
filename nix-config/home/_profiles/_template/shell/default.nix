# home/_profiles/_template/shell/default.nix
#
# Base shell configurations shared across all profiles

{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
  ];
}
