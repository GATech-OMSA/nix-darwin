# home/_profiles/_template/programs/delta.nix
#
# Delta - Better git diff with syntax highlighting

{ config, pkgs, lib, ... }:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Nord";
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
    };
  };
}
