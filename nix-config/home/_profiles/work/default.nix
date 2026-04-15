# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure

{ config, pkgs, lib, myLib, hostname, userConfig, ... }:

let
  # Access proxy configuration from user-config.nix
  proxies = userConfig.proxies or {};

  # Corporate CA bundle — single source of truth for all proxy clients
  caBundlePath = proxies.corporateCaBundle or "$HOME/.config/certs/cacert.pem";
  hasCaBundle = (proxies.corporateCaBundle or "") != "";

  # CA bundle env vars — fan out to all tools that need TLS trust
  # npm cafile is handled in node.nix via .npmrc
  caBundleVars = if hasCaBundle then {
    AWS_CA_BUNDLE = caBundlePath;
    NODE_EXTRA_CA_CERTS = caBundlePath;
    REQUESTS_CA_BUNDLE = caBundlePath;   # Python requests library
    PIP_CERT = caBundlePath;             # pip TLS verification
    SSL_CERT_FILE = caBundlePath;        # Generic OpenSSL (curl, etc.)
  } else {
    AWS_CA_BUNDLE = caBundlePath;
  };

  # Helper to build proxy environment variables
  goProxyVars = if (proxies.go.enabled or false) then {
    GOPROXY = "${proxies.go.url or "https://proxy.golang.org"},direct";
    GOPRIVATE = proxies.go.private or "";
    GOSUMDB = "off";  # Corporate proxy cannot mirror Go's sum database
  } else {};

  pythonProxyVars = if (proxies.python.enabled or false) then {
    PIP_INDEX_URL = proxies.python.url or "https://pypi.org/simple";
    PIP_TRUSTED_HOST = proxies.python.trustedHost or "";
  } else {};

  npmProxyVars = if (proxies.npm.enabled or false) then {
    NPM_CONFIG_REGISTRY = proxies.npm.url or "https://registry.npmjs.org";
  } else {};

  cargoProxyVars = if (proxies.cargo.enabled or false) then {
    CARGO_HTTP_CAINFO = caBundlePath;
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
  # npm global prefix PATH is managed by node.nix (co-located with .npmrc prefix)
  home.sessionPath = [
    "$HOME/.rd/bin"  # Rancher Desktop binaries (docker, kubectl, etc.)
  ];

  # Work-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "work";
    AWS_PROFILE = "work-domain";  # Default, auto-restored from ~/.aws/.last_profile
    WORKSPACE = "$HOME/Work";
  }
  // caBundleVars     # CA bundle for all TLS-speaking tools
  // goProxyVars      # Merge Go proxy vars if enabled
  // pythonProxyVars  # Merge Python proxy vars if enabled
  // npmProxyVars     # Merge NPM proxy vars if enabled
  // cargoProxyVars;  # Merge Cargo proxy vars if enabled

  # Starship prompt (work theme)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
