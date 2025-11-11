{ config, pkgs, lib, hostname, myLib, ... }:

let
  # Dock apps configuration (left to right order)
  # Apps are listed in the order they appear in the Dock

  workDockApps = [
    "/Applications/Safari.app"
    "/System/Applications/Mail.app"
    "/System/Applications/Calendar.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/Microsoft Teams.app"
    "/System/Applications/Notes.app"
    "/Applications/iTerm.app"
    # "/System/Applications/System Settings.app"
  ];

  personalDockApps = [
    "/Applications/Safari.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Mail.app"
    "/System/Applications/FaceTime.app"
    "/System/Applications/Phone.app"
    "/System/Applications/Notes.app"
    "/System/Applications/Music.app"
    "/System/Applications/System Settings.app"
    "/Applications/iTerm.app"
    "/Applications/Visual Studio Code.app"
  ];

  # Select apps based on machine type
  persistentApps = myLib.selectByMachine hostname {
    work = workDockApps;
    personal = personalDockApps;
  };
in
{
  # macOS System Defaults
  system.defaults = {
    # Dock settings
    dock = {
      autohide = false;
      show-recents = false;
      orientation = "bottom";
      tilesize = 68;
      minimize-to-application = true;
      show-process-indicators = true;
      launchanim = false;  # Faster app launching
      persistent-apps = persistentApps;
      # persistent-others: Add folders/files to right side of Dock
      # Example: ["/Users/jimmy/Downloads" "/Users/jimmy/Documents"]
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
