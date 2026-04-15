# builders.nix
#
# Distributed build configuration for cross-machine Nix builds.
# Each machine lists the other as a remote builder so either can
# offload work via SSH.
#
# nix.distributedBuilds and nix.buildMachines are gated behind nix.enable,
# which is false (Determinate Nix). We write /etc/nix/machines directly.
#
# Prerequisites (manual, one-time):
#   1. Enable Remote Login on both machines (System Settings → General → Sharing)
#   2. Exchange SSH keys:
#        ssh-copy-id jimmy@mbp-work    (from personal)
#        ssh-copy-id jimmy@mbp-jimmy   (from work)
#   3. Test connectivity:
#        nix store ping --store ssh://jimmy@mbp-work
#        nix store ping --store ssh://jimmy@mbp-jimmy
#   4. Rebuild on both machines: nix-rebuild && exec zsh

{ config, pkgs, lib, myLib, profileName ? "personal", hostname, username, ... }:

let
  # Each machine sees the OTHER as its remote builder.
  # Format: store-uri system ssh-key max-jobs speed-factor features mandatory-features
  # Using - for ssh-key (uses default ~/.ssh/id_ed25519 via ssh config)
  remoteMachines = myLib.selectByProfile profileName {

    personal = ''
      ssh://${username}@mbp-work aarch64-darwin - 8 1 benchmark,big-parallel -
    '';

    work = ''
      ssh://${username}@mbp-jimmy aarch64-darwin - 8 1 benchmark,big-parallel -
    '';

    # Minimal profile has no remote builders
    minimal = "";
    default = "";
  };

  enableBuilders = remoteMachines != "";
in
{
  # Write /etc/nix/machines directly — nix.buildMachines is gated behind nix.enable
  # The Nix daemon reads this via `builders = @/etc/nix/machines` in nix.conf
  environment.etc."nix/machines" = lib.mkIf enableBuilders {
    text = ''
      # Managed by nix-darwin — do not edit directly.
      # Source: nix-config/modules/darwin/builders.nix
      #
      # Remote builder: the other machine in this 2-machine setup.
      # See file header for setup prerequisites.
      ${remoteMachines}
    '';
  };
}
