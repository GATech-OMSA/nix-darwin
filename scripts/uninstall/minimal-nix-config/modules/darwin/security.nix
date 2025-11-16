# security.nix
#
# Security and privacy settings

{ config, pkgs, ... }:

{
  security = {
    # PAM (authentication)
    pam.enableSudoTouchIdAuth = true;  # Use Touch ID for sudo
  };

  system.defaults = {
    # Screensaver & lock
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 5;  # Seconds
    };

    # Privacy settings
    NSGlobalDomain = {
      # Disable crash reporter
      "com.apple.CrashReporter.DialogType" = "none";
    };

    # Firewall
    alf = {
      globalstate = 1;  # Enable firewall
      allowsignedenabled = 1;  # Allow signed apps
      stealthenabled = 1;  # Enable stealth mode
    };
  };
}
