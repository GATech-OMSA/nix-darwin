# home/_profiles/minimal/aliases.nix
#
# Essential aliases only

_:

{
  programs.zsh.shellAliases = {
    # Basic navigation
    ".." = "cd ..";
    "..." = "cd ../..";

    # Essential git
    g = "git";
    gs = "git status";

    # Rebuild
    rebuild = "darwin-rebuild switch --flake .";
  };
}
