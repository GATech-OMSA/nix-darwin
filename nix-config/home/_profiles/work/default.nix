# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure, database connectivity

{ config, pkgs, lib, myLib, hostname, userConfig, ... }:

let
  # ============================================
  # PROXY CONFIGURATION HELPERS
  # ============================================
  # Extract proxy settings from userConfig (if defined)
  proxies = userConfig.proxies or {};

  # Build proxy environment variables (only if enabled)
  goProxyVars =
    if (proxies.go.enabled or false)
    then {
      GOPROXY = "${proxies.go.url},direct";
      GOPRIVATE = proxies.go.private;
      GOSUMDB = "off";  # Corporate proxies can't mirror Go's sum database
    }
    else {};

  pythonProxyVars =
    if (proxies.python.enabled or false)
    then {
      PIP_INDEX_URL = proxies.python.url;
      PIP_TRUSTED_HOST = proxies.python.trustedHost or "";
    }
    else {};

  npmProxyVars =
    if (proxies.npm.enabled or false)
    then {
      NPM_CONFIG_REGISTRY = proxies.npm.url;
    }
    else {};

in {
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
  }
  # Conditionally merge proxy environment variables
  // goProxyVars      # Merge Go proxy vars if enabled
  // pythonProxyVars  # Merge Python proxy vars if enabled
  // npmProxyVars;    # Merge NPM proxy vars if enabled
}
