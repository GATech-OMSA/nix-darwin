{ config, pkgs, lib, hostname, myLib, machineType, ... }:

let
  # Machine-specific NPM config
  npmEmail = myLib.selectByMachineType machineType {
    personal = "jimmy-jain@users.noreply.github.com";
    work = "user@example.com";
  };

  npmAuthor = myLib.selectByMachineType machineType {
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
