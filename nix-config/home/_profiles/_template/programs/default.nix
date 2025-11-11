# home/_profiles/_template/programs/default.nix
#
# Base program configurations shared across all profiles

{ config, pkgs, lib, ... }:

{
  imports = [
    ./aws.nix
    ./bat.nix
    ./direnv.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./karabiner.nix
    ./node.nix
    ./ssh.nix
    ./vscode.nix
    ./zoxide.nix
  ];
}
