{ config, pkgs, lib, hostname, ... }:

{
  # Homebrew configuration
  # Only GUI apps and Mac App Store apps
  # CLI tools are managed by Nix for better reproducibility

  homebrew = {
    # enable is set in host-specific configs
    # Personal Mac: homebrew.enable = true
    # Work Mac: homebrew.enable = true (toggle to false if IT manages)

    onActivation = {
      cleanup = "zap";  # Uninstall packages not in config
      autoUpdate = true;
      upgrade = true;
    };

    global = {
      brewfile = true;
    };

    taps = [
      "buo/cask-upgrade"
    ];

    # Only brew formulae that MUST be from Homebrew
    brews = [
      "mas"  # Mac App Store CLI
      "micromamba"  # Conda replacement (Nix build broken on macOS)
    ];

    # GUI applications only
    casks = [
      # Browsers
      "firefox"
      "orion"

      # Development
      "cursor"
      "visual-studio-code"
      "claude-code"
      "docker"  # Changed from docker-desktop
      "iterm2"

      # Productivity
      "alfred"
      "rectangle"  # Will suggest AeroSpace alternative

      # AI/LLM
      "chatgpt"
      "claude"
      "jan"
      "ollama"  # Changed from ollama-app

      # Utilities
      "appcleaner"
      "keka"
      "keyclu"
      "shottr"
      "obsidian"  # Markdown editor and knowledge management

      # Communication
      "whatsapp"
      "zoom"

      # Other
      "pdf-expert"
      "tradingview"
      "protonvpn"

      # Fonts are now managed by Nix (see fonts.nix)
    ];

    # Mac App Store apps (requires `mas` to be installed)
    masApps = {
      "Access" = 6469049274;
      "Capital One Shopping" = 1477110326;
      "Consent-O-Matic" = 1606897889;
      "Dynaper" = 1435296403;
      # "Microsoft Excel" = 462058435;
      # "Microsoft PowerPoint" = 462062816;
      # "Microsoft Word" = 462054704;
      "MindNode Classic" = 1289197285;
      "Pages" = 409201541;
      "Paranoia Text Encryption Pro" = 935278498;
      "Perplexity" = 6714467650;
      "Rakuten Cash Back" = 1451893560;
      "TrashMe 3" = 1490879410;
    };
  };
}
