# nix-index
#
# Provides a `command-not-found` handler that suggests which Nix package
# to install when an unrecognized command is typed. Replaces the default
# macOS "command not found" message with actionable package suggestions.

{ config, pkgs, lib, ... }:

{
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
}
