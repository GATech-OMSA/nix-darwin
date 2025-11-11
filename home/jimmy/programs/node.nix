{ config, pkgs, lib, hostname, myLib, ... }:

let
  # Machine-specific NPM config
  npmEmail = myLib.selectByMachine hostname {
    personal = "jimmy-jain@users.noreply.github.com";
    work = "user@example.com";
  };

  npmAuthor = myLib.selectByMachine hostname {
    personal = "Jim";
    work = "Jim";
  };
in
{
  # NPM Configuration - Declarative setup
  # Replaces manual ~/.npmrc management

  home.file.".npmrc".text = ''
    # NPM initialization defaults
    init-author-name=${npmAuthor}
    init-author-email=${npmEmail}
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
