{ config, pkgs, lib, ... }:

{
  # Node.js development configuration

  home.packages = with pkgs; [
    nodejs_22
    nodePackages.npm
    nodePackages.pnpm
    nodePackages.yarn
  ];

  # npm configuration
  home.file.".npmrc".text = ''
    init-author-name=Jimmy Jain
    init-author-email=jimmy-jain@users.noreply.github.com
    init-license=MIT
    save-exact=true
  '';
}
