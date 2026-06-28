# Custom Packages — entry point
#
# Collects this repo's own derivations so they can be injected via an overlay
# (see ../overlays/default.nix) and referenced as `pkgs.<name>` anywhere.
#
# Usage (in an overlay): (final: _prev: import ../pkgs { pkgs = final; })
# Then add `pkgs.security-scan` to environment.systemPackages, etc.

{ pkgs }:

{
  # CVE scan of the live system closure + brew cask drift. Bundles vulnix.
  security-scan = pkgs.callPackage ./security-scan { };
}
