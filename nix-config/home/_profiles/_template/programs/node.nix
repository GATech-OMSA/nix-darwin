{ config, pkgs, lib, hostname, myLib, profileName, userConfig, ... }:

let
  proxies = userConfig.proxies or {};
  npmProxyEnabled = proxies.npm.enabled or false;
  npmRegistryUrl = proxies.npm.url or "https://registry.npmjs.org";
in
{
  # NPM Configuration - Declarative setup
  # Replaces manual ~/.npmrc management
  # Registry is set automatically when proxies.npm is enabled in user-config.nix

  home.file.".npmrc".text = ''
    # NPM initialization defaults
    init-author-name=${userConfig.fullName}
    init-author-email=${userConfig.email}
    init-license=MIT

    # Save exact versions (no ^ or ~)
    save-exact=true

    # Supply chain protection: reject packages published less than 7 days ago
    # Gives community time to detect and remove malicious releases
    min-release-age=7
  ''
  + lib.optionalString npmProxyEnabled ''

    # Corporate registry (from user-config.nix proxies.npm)
    registry=${npmRegistryUrl}
  '';
}
