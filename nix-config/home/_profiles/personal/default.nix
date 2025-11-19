# home/_profiles/personal/default.nix
#
# Personal profile configuration
# For: Learning, personal projects, hobby development

{ config, pkgs, lib, myLib, hostname, userConfig, ... }:

let
  # ============================================
  # PROXY CONFIGURATION HELPERS
  # ============================================
  # Extract proxy settings from userConfig (if defined)
  # Most personal machines won't need proxies, but home labs might
  proxies = userConfig.proxies or {};

  # Build proxy environment variables (only if enabled)
  goProxyVars =
    if (proxies.go.enabled or false)
    then {
      GOPROXY = "${proxies.go.url},direct";
      GOPRIVATE = proxies.go.private;
      GOSUMDB = "off";
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
    ../../_mixins/base.nix      # Base configuration (zoxide, fzf, bat, eza, direnv, starship)
    ../_template/programs       # Profile-shared program configs
    ../_template/shell          # Profile-shared shell configs
    ../../_template/development # Development configs (Python, Node, AI/ML)
    ./packages.nix              # Personal packages
    ./aliases.nix               # Personal aliases
  ];

  # Personal-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
    WORKSPACE = "$HOME/Dev";
  }
  # Conditionally merge proxy environment variables (if configured)
  // goProxyVars
  // pythonProxyVars
  // npmProxyVars;
}
