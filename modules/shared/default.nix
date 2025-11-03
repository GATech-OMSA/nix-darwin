{ config, pkgs, lib, ... }:

{
  # Import all shared modules
  imports = [
    ./packages.nix
    ./users.nix
  ];
}
