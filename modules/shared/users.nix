{ config, pkgs, lib, username, ... }:

{
  # User account configuration
  #
  # ARCHITECTURE NOTE:
  # User definitions are fully owned by host-specific configs to avoid
  # evaluation order conflicts in Nix's module system.
  #
  # Each host config (hosts/*/default.nix) defines:
  #   - users.users.${username}.name
  #   - users.users.${username}.home
  #   - users.users.${username}.shell
  #
  # This ensures all required attributes are defined together,
  # preventing "option is used but not defined" errors.
  #
  # See: hosts/mbp-jimmy/default.nix and hosts/mbp-work/default.nix
}
