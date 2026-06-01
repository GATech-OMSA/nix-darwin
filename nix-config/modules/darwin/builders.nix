# builders.nix
#
# Distributed build configuration for cross-machine Nix builds.
# Offloads heavy builds to remote machines via SSH.
#
# nix.distributedBuilds and nix.buildMachines are gated behind nix.enable,
# which is false (Determinate Nix). We write /etc/nix/machines directly.
#
# Current status: no active builders.
#   - Work ↔ Personal is blocked (MDM on work machine restricts SSH)
#   - Ready for a second personal machine — uncomment and fill in below
#
# Prerequisites (when adding a builder):
#   1. Enable Remote Login on both machines (System Settings → General → Sharing)
#   2. Exchange SSH keys: ssh-copy-id jimmy@<other-host>
#   3. Test: nix store ping --store ssh://jimmy@<other-host>
#   4. Rebuild on both machines: nix-rebuild && exec zsh

{ config, pkgs, lib, myLib, profileName ? "personal", hostname, username, ... }:

let
  # Format: store-uri system ssh-key max-jobs speed-factor features mandatory-features
  # Using - for ssh-key (uses default ~/.ssh/id_ed25519 via ssh config)
  remoteMachines = myLib.selectByProfile profileName {

    # Uncomment when a second personal machine is available:
    # personal = ''
    #   ssh://${username}@<other-host> aarch64-darwin - 8 1 benchmark,big-parallel -
    # '';

    # Work machine is MDM-managed — cross-machine SSH is blocked
    work = "";

    personal = "";
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
