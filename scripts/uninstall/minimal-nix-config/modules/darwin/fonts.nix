# fonts.nix
#
# Font management

{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    # Nerd Fonts (programming fonts with icons)
    fira-code
    fira-code-nerdfont
    jetbrains-mono
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Meslo" ]; })

    # Standard fonts
    fira
    fira-sans
    roboto
    source-code-pro
  ];
}
