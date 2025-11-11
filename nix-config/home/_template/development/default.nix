# Development Tools Configuration
#
# Aggregates all development-related configurations

{ config, pkgs, lib, ... }:

{
  imports = [
    ./python.nix
    ./node.nix
    ./ai-ml.nix
  ];
}
