# home/_profiles/minimal/packages.nix
#
# Bare minimum packages for basic functionality

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Essential CLI tools only
    coreutils
    git
    vim
    curl
    wget
  ];
}
