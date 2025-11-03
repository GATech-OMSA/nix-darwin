{ config, pkgs, lib, ... }:

{
  # Development tools configuration for all dev machines

  home.packages = with pkgs; [
    # Version control
    git
    gh

    # Build tools
    gnumake

    # Documentation
    tldr
  ];

  # Git delta (better git diff)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;  # Explicitly enable git integration
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Nord";
    };
  };
}
