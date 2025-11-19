# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure, database connectivity

{ config, pkgs, lib, myLib, hostname, ... }:

{
  imports = [
    ../../_mixins/base.nix # Base configuration (zoxide, fzf, bat, eza, direnv, starship)
    ../_template/programs  # Base program configs
    ../_template/shell     # Base shell configs
    ./packages.nix         # Work-specific packages
    ./aliases.nix          # Work-specific aliases
    ./aws.nix              # AWS configuration
    ./database.nix         # Database instances
  ];

  # AWS CLI configuration with corporate CA bundle
  programs.aws = {
    caBundle = "~/.config/certs/cacert.pem";
  };

  # Work-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "work-domain";  # Default, auto-restored from ~/.aws/.last_profile
    WORKSPACE = "$HOME/Work";

    # ODBC Configuration
    ODBCSYSINI = "/usr/local/etc";
    ODBCINI = "/usr/local/etc/odbc.ini";
  };


}
