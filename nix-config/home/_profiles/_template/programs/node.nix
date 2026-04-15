{ config, pkgs, lib, hostname, myLib, profileName, userConfig, ... }:

let
  proxies = userConfig.proxies or {};
  npmProxyEnabled = proxies.npm.enabled or false;
  npmRegistryUrl = proxies.npm.url or "https://registry.npmjs.org";
  # Nix-managed npm has a read-only prefix (/nix/store), so global installs fail.
  # Work profile uses Nix npm — redirect global prefix to a writable directory.
  npmGlobalPrefix = proxies.npm.globalPrefix or "$HOME/.npm-global";
in
{
  # NPM Configuration - Declarative setup
  # Replaces manual ~/.npmrc management
  # Registry and global prefix are set when proxies.npm is enabled in user-config.nix

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

    # Writable global prefix (Nix store is read-only)
    prefix=${npmGlobalPrefix}
  '';
}
