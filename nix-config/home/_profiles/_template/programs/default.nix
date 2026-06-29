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
    ./nix-index.nix
    ./node.nix
    ./ssh.nix
    ./zoxide.nix
  ];

  # ==================================================
  # SOPS SECRET VERIFICATION (shared across all profiles)
  # ==================================================
  # Activation no longer writes secrets — it only VERIFIES that the targets
  # listed in the manifest (written by secrets-deploy) exist with the right
  # mode. This eliminates the 2026-04-28 failure class where a silent decrypt
  # error inside activation corrupted ~/.zsh_secrets.
  #
  # Writers:
  #   • secrets-deploy (manual)               — primary path
  #   • launchd agent on secrets.yaml change  — automatic
  #   • activate.sh (first-boot bootstrap)    — initial deploy
  home.activation.verifySopsSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    VERIFY_SCRIPT="${nixDarwinDir}/scripts/secrets/verify-secrets.sh"
    if [[ ! -x "$VERIFY_SCRIPT" ]]; then
      echo "warning: verify-secrets.sh missing or not executable at $VERIFY_SCRIPT" >&2
      echo "         skipping secret verification (this should not happen on a healthy checkout)" >&2
    else
      $DRY_RUN_CMD "$VERIFY_SCRIPT" --quiet
    fi
  '';
}
