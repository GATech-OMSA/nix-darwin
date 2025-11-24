{ config, pkgs, lib, ... }:

# Shared Modules - Module Imports
#
# Imports all cross-platform configuration modules (packages, users).
# Note: nix.nix is disabled because Determinate Nix manages the daemon (see darwin/default.nix)

{
  imports = [
    # ./nix.nix  # DISABLED - conflicts with Determinate Nix (nix.enable = false in darwin/default.nix)
    ./packages.nix
    ./users.nix
  ];
}
