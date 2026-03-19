# home/_profiles/_template/programs/default.nix
#
# Base program configurations shared across all profiles

{ config, pkgs, lib, machineId, ... }:

let
  nixDarwinDir = "${config.home.homeDirectory}/nix-darwin";
in
{
  imports = [
    ./atuin.nix
    ./aws.nix
    ./bat.nix
    ./delta.nix
    ./direnv.nix
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./karabiner.nix
    ./node.nix
    ./ssh.nix
    ./zoxide.nix
  ];

  # ==================================================
  # SOPS SECRET DEPLOYMENT (shared across all profiles)
  # ==================================================
  # Runs deploy-secrets.sh on every rebuild. The script decrypts secrets.yaml
  # and deploys each key to its target path. Keys not in secrets.yaml are skipped,
  # so the same script works for personal and work profiles.
  home.activation.deploySopsSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DEPLOY_SCRIPT="${nixDarwinDir}/scripts/secrets/deploy-secrets.sh"
    if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
      echo "warning: deploy-secrets.sh not found at $DEPLOY_SCRIPT" >&2
    elif [[ ! -x "$DEPLOY_SCRIPT" ]]; then
      echo "warning: deploy-secrets.sh not executable, run: chmod +x $DEPLOY_SCRIPT" >&2
    else
      $DRY_RUN_CMD "$DEPLOY_SCRIPT" || echo "warning: secret deployment failed (exit $?)" >&2
    fi
  '';
}
