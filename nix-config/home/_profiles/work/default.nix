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
  caBundleVars = if hasCaBundle then {
    AWS_CA_BUNDLE = caBundlePath;
    NODE_EXTRA_CA_CERTS = caBundlePath;
    REQUESTS_CA_BUNDLE = caBundlePath;   # Python requests library
    PIP_CERT = caBundlePath;             # pip TLS verification
    SSL_CERT_FILE = caBundlePath;        # Generic OpenSSL (curl, etc.)
  } else {};

  # Proxy env vars (Go via shared myLib.go.proxyVars; Python/npm/cargo inline)
  goProxyVars = if (proxies.go.enabled or false) then myLib.go.proxyVars proxies.go else {};

  pythonProxyVars = if (proxies.python.enabled or false) then {
    PIP_INDEX_URL = proxies.python.url or "https://pypi.org/simple";
    PIP_TRUSTED_HOST = proxies.python.trustedHost or "";
  } else {};

  npmProxyVars = if (proxies.npm.enabled or false) then {
    NPM_CONFIG_REGISTRY = proxies.npm.url or "https://registry.npmjs.org";
  } else {};

  cargoProxyVars = if (proxies.cargo.enabled or false) && hasCaBundle then {
    CARGO_HTTP_CAINFO = caBundlePath;
  } else {};

in {
  # Shared imports + starship wiring live in _template/profile-base.nix;
  # this profile contributes its proxy/session deltas.
  imports = [
    (import ../_template/profile-base.nix { profileDir = ../work; })
  ];

  # Add Rancher Desktop to PATH (for Docker CLI)
  home.sessionPath = [
    "$HOME/.rd/bin"  # Rancher Desktop binaries (docker, kubectl, etc.)
  ];

  # Work-specific session variables (common block via myLib + proxy fan-out)
  home.sessionVariables = myLib.mkProfileSessionVars {
    mode = "work";
    awsProfile = "work-domain";  # auto-restored from ~/.aws/.last_profile
    workspace = "$HOME/Work";
  }
  // caBundleVars
  // goProxyVars
  // pythonProxyVars
  // npmProxyVars
  // cargoProxyVars;
}