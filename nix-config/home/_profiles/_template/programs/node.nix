{ config, pkgs, lib, hostname, myLib, profileName, userConfig, ... }:

let
  proxies = userConfig.proxies or {};
  # Only apply corporate npm settings on the work profile to prevent
  # Nexus registry and writable prefix leaking into personal/minimal
  isWorkProfile = myLib.isWorkProfile profileName;
  npmProxyEnabled = isWorkProfile && (proxies.npm.enabled or false);
  npmRegistryUrl = proxies.npm.url or "https://registry.npmjs.org";
  npmGlobalPrefix = proxies.npm.globalPrefix or "$HOME/.npm-global";
  corporateCaBundle = proxies.corporateCaBundle or "";
  hasCaBundle = corporateCaBundle != "";
in
{
  # NPM Configuration - Declarative setup
  # Replaces manual ~/.npmrc management
  # Corporate registry, writable prefix, and CA bundle are work-profile only

  home.file.".npmrc".text = ''
    # NPM initialization defaults
    init-author-name=${userConfig.fullName}
    init-author-email=${userConfig.email}
    init-license=MIT

    # Save exact versions (no ^ or ~)
    save-exact=true

    # Supply chain protection: reject packages published less than 14 days ago.
    # Gives the community time to detect and pull malicious releases — widened
    # from 7d given elevated supply-chain risk. Trade-off: legit patches also
    # wait 14d, so urgent security bumps may need a manual --before override.
    min-release-age=14
  ''
  + lib.optionalString npmProxyEnabled ''

    # Corporate registry (work profile, from user-config.nix proxies.npm)
    registry=${npmRegistryUrl}

    # Writable global prefix (Nix store is read-only)
    prefix=${npmGlobalPrefix}
  ''
  + lib.optionalString (npmProxyEnabled && hasCaBundle) ''

    # Corporate CA bundle for TLS verification
    cafile=${corporateCaBundle}
  '';

  # Add writable npm global bin to PATH (work profile only)
  home.sessionPath = lib.mkIf npmProxyEnabled [
    "${npmGlobalPrefix}/bin"
  ];
}
