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

  # fzf - fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

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

  # Zsh configuration with hot-reload layer
  programs.zsh = {
    enable = true;
    initExtraFirst = ''
      # ================================================================
      # HOT-RELOAD LAYER (No rebuild required for changes)
      # ================================================================
      # Source local secrets (editable without nix-rebuild)
      # Usage: echo "export MY_API_KEY=..." >> ~/.config/secrets/local.env
      #        source ~/.zshrc
      if [ -f "$HOME/.config/secrets/local.env" ]; then
        source "$HOME/.config/secrets/local.env"
      fi

      # Source user customizations (editable without nix-rebuild)
      # Usage: echo "alias mytest='echo test'" >> ~/.zshrc.local
      #        source ~/.zshrc
      if [ -f "$HOME/.zshrc.local" ]; then
        source "$HOME/.zshrc.local"
      fi
    '';
  };
}
