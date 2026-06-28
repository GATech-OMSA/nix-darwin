{ config, pkgs, lib, machineId, username, ... }:

# Secrets Watcher LaunchAgent
#
# Watches the per-host secrets.yaml file. When sops re-encrypts (after
# `secrets-edit`), launchd fires deploy-secrets.sh automatically, so the
# user doesn't need to run it manually before the next rebuild. Output
# is captured to a per-event timestamped log; the last 10 are kept.
#
# Why this exists: rule #001 of the nix-resilience-followup project moved
# secret deployment OUT of HM activation. Activation now only verifies.
# This agent is the automatic writer that fills the gap.
#
# WatchPaths fires on inode change. sops uses atomic rename on save,
# producing a new inode every time, so this triggers reliably.

let
  homeDir = config.users.users.${username}.home;
  repoDir = "${homeDir}/nix-darwin";
  secretsFile = "${repoDir}/nix-config/hosts/${machineId}/secrets.yaml";
  stateDir = "${homeDir}/.local/state/secrets-deploy";

  # Wrapper script: run deploy-secrets, capture per-event log, rotate to last 10.
  #
  # launchd hands agents a minimal PATH, so deploy-secrets.sh would otherwise
  # have to hunt for sops/yq (and could pick a wrong/stray yq). Prepend the
  # exact nix-store sops + mikefarah yq this build pins, then the system dirs
  # for the coreutils (grep/sed/awk/diff/find/...) the script also relies on.
  # Nix bins go first so they win deploy-secrets' "must live in /nix/store" guard.
  watchScript = pkgs.writeShellScript "secrets-deploy-watcher" ''
    set -uo pipefail
    export PATH="${lib.makeBinPath [ pkgs.sops pkgs.yq-go ]}:/usr/bin:/bin"
    /bin/mkdir -p "${stateDir}"
    ts=$(/bin/date -u +%Y%m%dT%H%M%SZ)
    log_file="${stateDir}/$ts.log"
    {
      printf '[%s] secrets.yaml changed — running deploy-secrets.sh\n' "$ts"
      "${repoDir}/scripts/secrets/deploy-secrets.sh"
      printf '[%s] exit=%d\n' "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)" "$?"
    } >> "$log_file" 2>&1

    # Keep newest 10 logs.
    /bin/ls -1t "${stateDir}"/*.log 2>/dev/null | /usr/bin/tail -n +11 \
      | while IFS= read -r old; do /bin/rm -f "$old"; done
  '';
in
{
  launchd.user.agents.secrets-deploy-watcher = {
    serviceConfig = {
      Label = "dev.nixconf.secrets-deploy-watcher";
      ProgramArguments = [ "${watchScript}" ];
      WatchPaths = [ secretsFile ];
      # Don't fire at login — only on actual file change.
      RunAtLoad = false;
      # Coalesce rapid consecutive events from a single sops save.
      ThrottleInterval = 10;
      # launchd's own stdout/stderr — point at /tmp so a missing $stateDir
      # at first load doesn't lose error output.
      StandardOutPath = "/tmp/secrets-deploy-watcher.out.log";
      StandardErrorPath = "/tmp/secrets-deploy-watcher.err.log";
    };
  };
}
