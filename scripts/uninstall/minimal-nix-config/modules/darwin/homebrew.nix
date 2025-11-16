# homebrew.nix
#
# Homebrew package management for GUI apps

{ config, pkgs, machineConfig, ... }:

{
  homebrew = {
    enable = true;

    # Behavior on activation
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";  # Uninstall packages not in config
      upgrade = false;
    };

    # Tap repositories
    taps = [
      "homebrew/bundle"
      "homebrew/services"
    ];

    # CLI tools (formulae)
    # Note: Prefer Nix for CLI tools when possible
    brews = [
      # Add Homebrew-only CLI tools here
      # Example:
      # "mas"  # Mac App Store CLI
    ];

    # GUI applications (casks)
    casks = [
      # Browsers
      # "google-chrome"
      # "firefox"

      # Development
      # "visual-studio-code"
      # "docker"
      # "iterm2"

      # Productivity
      # "slack"
      # "notion"
      # "obsidian"

      # Utilities
      # "rectangle"      # Window management
      # "alt-tab"        # Better app switching
      # "raycast"        # Spotlight replacement

      # Add your GUI apps here
    ];

    # Mac App Store apps
    # Requires: brew install mas
    masApps = {
      # "Xcode" = 497799835;
    };
  };
}
