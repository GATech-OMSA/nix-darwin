# home/_profiles/personal/default.nix
#
# Personal profile configuration
# For: Learning, personal projects, hobby development

{ config, pkgs, lib, myLib, hostname, ... }:

{
  imports = [
    ../_template/programs       # Profile-shared program configs
    ../_template/shell/zsh.nix  # Profile-shared shell config
    ../../_template/development # Development configs (Python, Node, AI/ML)
    ./packages.nix              # Personal packages
    ./aliases.nix               # Personal aliases
  ];

  # Personal-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
    WORKSPACE = "$HOME/Dev";
  };

  # Starship prompt (personal theme)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
