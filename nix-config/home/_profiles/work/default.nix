# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure, database connectivity

{ config, pkgs, lib, myLib, hostname, userConfig, ... }:

let
  # Access proxy configuration from user-config.nix
  proxies = userConfig.proxies or {};

  # Helper to build proxy environment variables
  goProxyVars = if (proxies.go.enabled or false) then {
    GOPROXY = "${proxies.go.url},direct";
    GOPRIVATE = proxies.go.private;
    GOSUMDB = "off";  # If Nexus cannot mirror Go's sum database
  } else {};

  pythonProxyVars = if (proxies.python.enabled or false) then {
    PIP_INDEX_URL = proxies.python.url;
    PIP_TRUSTED_HOST = proxies.python.trustedHost or "";
  } else {};

  npmProxyVars = if (proxies.npm.enabled or false) then {
    NPM_CONFIG_REGISTRY = proxies.npm.url;
  } else {};

in {
  imports = [
    ../_template/programs  # Base program configs
    ../_template/shell     # Base shell configs
    ./packages.nix         # Work-specific packages
    ./aliases.nix          # Work-specific aliases
    ./aws.nix              # AWS configuration
    ./database.nix         # Database instances
    ./programs             # Work program overrides
  ];

  # Add Rancher Desktop to PATH (for Docker CLI)
  home.sessionPath = [
    "$HOME/.rd/bin"  # Rancher Desktop binaries (docker, kubectl, etc.)
  ];

  # Work-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "work-domain";  # Default, auto-restored from ~/.aws/.last_profile
    WORKSPACE = "$HOME/Work";

    # AWS Configuration (corporate CA bundle)
    AWS_CA_BUNDLE = "$HOME/.config/certs/cacert.pem";

    # ODBC Configuration
    ODBCSYSINI = "/usr/local/etc";
    ODBCINI = "/usr/local/etc/odbc.ini";
  }
  // goProxyVars      # Merge Go proxy vars if enabled
  // pythonProxyVars  # Merge Python proxy vars if enabled
  // npmProxyVars;    # Merge NPM proxy vars if enabled

  # Starship prompt (work theme)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
