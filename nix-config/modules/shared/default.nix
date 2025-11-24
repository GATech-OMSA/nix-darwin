{ config, pkgs, lib, ... }:

# Shared Modules - Module Imports
#
# Imports all cross-platform configuration modules (packages, users, nix).

{
  imports = [
    ./nix.nix
    ./packages.nix
    ./users.nix
  ];
}
