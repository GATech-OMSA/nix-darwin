{ config, pkgs, lib, ... }:

{
  # Node.js development configuration
  # NPM configuration is now in programs/node.nix (machine-specific)

  home.packages = with pkgs; [
    nodejs_22  # Includes npm by default
    nodePackages.pnpm
    nodePackages.yarn
  ];
}
