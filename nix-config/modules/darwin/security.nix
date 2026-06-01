{ config, pkgs, lib, myLib, profileName ? "personal", ... }:

# Security Settings
#
# macOS security and privacy configuration: firewall hardening,
# stealth mode, and Touch ID authentication for sudo.

{

  # ==== Firewall ====

  # Enable the application firewall to block unsolicited inbound connections.
  # Stealth mode makes the machine silent to port scans (no ICMP or TCP RST replies),
  # reducing attack surface on untrusted networks.
  # Disabled on work profile — MDM manages its own firewall policy.
  networking.applicationFirewall.enable = myLib.selectByProfile profileName {
    personal = true;
    work     = false;   # MDM manages its own firewall policy
    minimal  = true;
    default  = true;
  };
  networking.applicationFirewall.enableStealthMode = myLib.selectByProfile profileName {
    personal = true;
    work     = false;
    minimal  = true;
    default  = true;
  };

  # ==== PAM / Authentication ====

  # Touch ID for sudo avoids password prompts for local admin operations
  # while keeping authentication strong (biometric + Secure Enclave).
  security.pam.services.sudo_local.touchIdAuth = true;

  # TODO: security.pam.services.sudo_local.reattach = true;
  # — add when nix-darwin version supports it (enables Touch ID inside tmux sessions)

}
