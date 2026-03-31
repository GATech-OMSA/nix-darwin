{ config, pkgs, lib, hostname, myLib, profileName, userConfig, ... }:

{
  # NPM Configuration - Declarative setup
  # Replaces manual ~/.npmrc management

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

    # Optional: Configure registry (uncomment if needed)
    # registry=https://registry.npmjs.org/

    # Optional: Configure proxy (uncomment if needed)
    # proxy=http://proxy.company.com:8080/
    # https-proxy=http://proxy.company.com:8080/
  '';
}
