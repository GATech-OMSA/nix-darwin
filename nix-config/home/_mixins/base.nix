{ config, pkgs, lib, ... }:

{
  # Base configuration for all machines
  # Essential tools and settings that every machine should have
  # Note: wget, curl, tree, htop installed system-wide in modules/shared/packages.nix

  # Zoxide - smarter cd command
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # NOTE: fzf is configured in _template/programs/fzf.nix
  # with custom zsh integration to suppress zle warnings

  # bat - better cat
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  # direnv - automatic environment switching
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # eza - modern ls replacement
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  # Starship prompt - Custom Catppuccin Powerline with AWS
  # Configuration is profile-specific (personal/work have different themes)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
