# secrets-work.nix
#
# SOPS configuration metadata for work machine
# Secret deployment handled by scripts/secrets/deploy-secrets.sh
# Runs automatically on rebuild via Home Manager activation hook
#
# Edit secrets: secrets-edit
# Manual deploy: secrets-deploy
# Reload shell: respin

{ config, pkgs, username, ... }:

{
  sops = {
    # Path to your age key
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    # Default secrets file for this host
    defaultSopsFile = ./secrets.yaml;
  };
}
