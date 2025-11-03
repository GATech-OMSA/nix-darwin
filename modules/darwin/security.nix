{ config, pkgs, lib, ... }:

{
  # Security settings

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Future security enhancements can go here:
  # - Firewall rules
  # - Yubico PAM
  # - Additional authentication methods
}
