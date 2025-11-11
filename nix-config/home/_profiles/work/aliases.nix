# home/_profiles/work/aliases.nix
#
# Aliases specific to work profile

{ config, lib, myLib, ... }:

{
  programs.zsh.shellAliases = {
    # ============================================
    # WORK PROJECT DIRECTORY SHORTCUTS
    # ============================================
    fscst = "cd ~/Dev/scst";
    fti = "cd ~/Dev/tririga";
    fps-proj = "cd ~/Dev/paging-solution";
    fmp = "cd ~/Dev/misc-projects";
    fwfhub = "cd ~/Dev/workforce-hub";
    fap = "cd ~/Dev/webMethods/api";
    fdeploys = "cd ~/Dev/production-deploys";
  };
}
