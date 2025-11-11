{ config, pkgs, lib, ... }:

# Shared Modules - Module Imports
#
# Imports all cross-platform configuration modules (packages, users).

{
  imports = [
    ./packages.nix
    ./users.nix
  ];
}
