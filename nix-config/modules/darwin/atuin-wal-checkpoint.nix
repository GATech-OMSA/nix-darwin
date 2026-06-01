{ config, pkgs, lib, username, ... }:

# Atuin WAL Checkpoint LaunchAgent
#
# Empirical note (2026-04-28): `PRAGMA journal_size_limit` is per-connection,
# not persistent across the database file — atuin opens its own connection and
# resets the limit. So we can't simply set a journal_size_limit pragma at shell
# init and call it done. Instead, we periodically checkpoint the WAL via a
# user LaunchAgent. This bounds WAL growth and keeps shell init fast (each
# `atuin` call at startup has to traverse any uncommitted WAL pages).
#
# PASSIVE checkpoint is intentional — it's non-blocking when other connections
# are open (e.g. a long-running shell with atuin loaded). TRUNCATE would
# block/fail in that case. The heavier TRUNCATE remains in `system-cleanup.sh`
# as a user-initiated last resort.

let
  homeDir = "/Users/${username}";
  atuinDir = "${homeDir}/.local/share/atuin";

  checkpointScript = pkgs.writeShellScript "atuin-wal-checkpoint" ''
    set -uo pipefail
    SQLITE=/usr/bin/sqlite3
    [[ -x "$SQLITE" ]] || exit 0  # macOS ships sqlite3 — skip cleanly if not

    for db in history.db records.db; do
      path="${atuinDir}/$db"
      [[ -f "$path" ]] || continue
      # PASSIVE: never blocks on other readers/writers. Returns
      # (busy, log_pages, checkpointed_pages). We don't care about the result;
      # any progress reduces the WAL.
      "$SQLITE" "$path" 'PRAGMA wal_checkpoint(PASSIVE);' >/dev/null 2>&1
    done
  '';
in
{
  launchd.user.agents.atuin-wal-checkpoint = {
    serviceConfig = {
      Label = "dev.nixconf.atuin-wal-checkpoint";
      ProgramArguments = [ "${checkpointScript}" ];
      # Every 6 hours. Atuin commits frequently, but WAL bloat takes days to
      # become a problem; quarterly within a day is plenty.
      StartInterval = 21600;
      # Run once at agent load too — fresh login should benefit.
      RunAtLoad = true;
      StandardOutPath = "/tmp/atuin-wal-checkpoint.out.log";
      StandardErrorPath = "/tmp/atuin-wal-checkpoint.err.log";
    };
  };
}
