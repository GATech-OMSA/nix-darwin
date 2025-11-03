{ config, pkgs, lib, ... }:

{
  # Font management
  # All fonts managed by Nix for reproducibility
  fonts.packages = with pkgs; [
    # Nerd Fonts - new structure in nixpkgs
    # Individual nerd font packages
    nerd-fonts.meslo-lg
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

    # Regular fonts
    fira-code
    jetbrains-mono
    source-code-pro

    # Optional: More fonts if needed
    # ibm-plex
    # inter
    # roboto
  ];
}
