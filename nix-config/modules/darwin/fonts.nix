{ config, pkgs, lib, ... }:

# Font Management
#
# System fonts managed by Nix for reproducibility.
# Includes Nerd Fonts for terminal, programming fonts, and system fonts.

{
  fonts.packages = with pkgs; [
    # Nerd Fonts - new structure in nixpkgs
    # Individual nerd font packages
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

    # Regular fonts
    source-code-pro

    # Optional: More fonts if needed
    # ibm-plex
    # inter
    # roboto
  ];
}
