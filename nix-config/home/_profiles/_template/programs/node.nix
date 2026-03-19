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

    # Optional: Configure registry (uncomment if needed)
    # registry=https://registry.npmjs.org/

    # Optional: Configure proxy (uncomment if needed)
    # proxy=http://proxy.company.com:8080/
    # https-proxy=http://proxy.company.com:8080/
  '';
}
