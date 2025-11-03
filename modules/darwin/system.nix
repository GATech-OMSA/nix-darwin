{ config, pkgs, lib, ... }:

{
  # macOS System Defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = false;
      show-recents = false;
      orientation = "bottom";
      tilesize = 72;
      minimize-to-application = true;
      show-process-indicators = true;
      launchanim = false;  # Faster app launching
      persistent-apps = [];  # Clean dock, add apps manually
      persistent-others = [];
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
      ShowStatusBar = true;
      ShowPathbar = true;
      FXDefaultSearchScope = "SCcf";  # Search current folder
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";  # List view
      _FXShowPosixPathInTitle = true;  # Show full path in title
    };

    # Global macOS settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.swipescrolldirection" = false;  # Natural scrolling off
      AppleInterfaceStyle = "Dark";  # Dark mode
      ApplePressAndHoldEnabled = false;  # Enable key repeat
    };

    # Screenshot settings
    screencapture = {
      location = "~/Desktop/Screenshots";
      type = "png";
      disable-shadow = false;
    };

    # Trackpad
    trackpad = {
      Clicking = true;  # Tap to click
      TrackpadThreeFingerDrag = true;  # Three finger drag
    };

    # Custom preferences
    CustomUserPreferences = {
      "com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;  # Don't write .DS_Store on network
        DSDontWriteUSBStores = true;  # Don't write .DS_Store on USB
      };
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
    };
  };

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = false;
  };

  # Startup chime
  system.startup.chime = false;
}
