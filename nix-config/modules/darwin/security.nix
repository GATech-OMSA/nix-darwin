{ config, pkgs, lib, ... }:

# Security Settings
#
# macOS security and privacy configuration.
# Future enhancements: Firewall rules, FileVault settings, privacy controls.

{

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Future security enhancements can go here:
  # - Firewall rules
  # - Yubico PAM
  # - Additional authentication methods
}
