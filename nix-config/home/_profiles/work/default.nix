# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure

{ config, pkgs, lib, myLib, hostname, userConfig, ... }:

let
  # Corporate CA bundle path (used by both AWS_CA_BUNDLE env var and ~/.aws/config)
  caBundlePath = "$HOME/.config/certs/cacert.pem";

  # Access proxy configuration from user-config.nix
  proxies = userConfig.proxies or {};

  # Helper to build proxy environment variables
  goProxyVars = if (proxies.go.enabled or false) then {
    GOPROXY = "${proxies.go.url or "https://proxy.golang.org"},direct";
    GOPRIVATE = proxies.go.private or "";
    GOSUMDB = "off";  # If Nexus cannot mirror Go's sum database
  } else {};

  pythonProxyVars = if (proxies.python.enabled or false) then {
    PIP_INDEX_URL = proxies.python.url or "https://pypi.org/simple";
    PIP_TRUSTED_HOST = proxies.python.trustedHost or "";
  } else {};

  npmProxyVars = if (proxies.npm.enabled or false) then {
    NPM_CONFIG_REGISTRY = proxies.npm.url or "https://registry.npmjs.org";
  } else {};

in {
  imports = [
    ../_template/programs      # Base program configs
    ../_template/shell/zsh.nix # Base shell config
    ../../_template/development # Development configs (Python, Node, AI/ML)
    ./packages.nix             # Work-specific packages
    ./aliases.nix              # Work-specific aliases
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
    AWS_CA_BUNDLE = caBundlePath;

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
