# home/_profiles/_template/programs/fzf.nix
#
# fzf - Fuzzy finder for command-line

{ config, pkgs, lib, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Default command and options are set via home.sessionVariables in home/_template/default.nix
    # FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    # FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git"
    # FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
  };
}
