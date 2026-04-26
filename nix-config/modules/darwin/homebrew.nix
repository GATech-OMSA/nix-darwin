{ config, pkgs, lib, hostname, ... }:

# Homebrew Configuration
#
# Manages GUI applications and Mac App Store apps via Homebrew.
# Controlled by `homebrew.enable` flag in host configuration.

{
  # CLI tools are managed by Nix for better reproducibility

  homebrew = {
    # enable is set in host-specific configs

    onActivation = {
      cleanup = "zap";
      # Supply chain protection: don't auto-pull and upgrade on every rebuild
      # Run `brew update && brew upgrade` manually when ready to review changes
      autoUpdate = false;
      upgrade = false;
    };

    global = {
      brewfile = true;
    };

    taps = [
      "buo/cask-upgrade"
      "anomalyco/tap"     # OpenCode AI coding agent
    ];

    # Only brew formulae that MUST be from Homebrew
    brews = [
      "mas"         # Mac App Store CLI
      "micromamba"  # Conda replacement
      "gemini-cli"  # Google Gemini CLI
      "mole"        # Mac cleanup/optimization CLI (mo clean, mo analyze, mo status)
      "opencode"    # Open source AI coding agent (anomalyco/tap)
    ];

    # GUI applications only
    casks = [
      # Browsers
      "firefox"
      "orion"
      "google-chrome"

      # Development
      "cursor"
      "orbstack"            # Docker & Linux VMs (fast, lightweight)
      # "antigravity"
      "visual-studio-code"
      "claude-code@latest"    # rolling channel; stable `claude-code` cask lags behind
      "ghostty"             # Terminal emulator (Homebrew for personal, Nix for work)
      "iterm2"
      # "dash"
      "warp"
      "fork"
      "microsoft-word"

      # Productivity
      "alfred"
      "raycast"
      "karabiner-elements"

      # AI/LLM
      "chatgpt"
      "claude"
      "codex"
      "codex-app"       # OpenAI Codex GUI (separate from codex CLI)
      "jan"             # Local LLM runner
      "ollama-app"

      # Utilities
      "conductor"
      "appcleaner"
      "keka"
      "keyclu"
      "shottr"
      "obsidian"

      # Communication
      "slack"
      "whatsapp"
      "zoom"

      # Finance
      "tradingview"

      # Other
      "pdf-expert"
      "protonvpn"

      # Fonts are now managed by Nix (see fonts.nix)
    ];

    # Mac App Store apps (requires `mas` to be installed)
    masApps = {
      "Access" = 6469049274;
      "Capital One Shopping" = 1477110326;
      "Consent-O-Matic" = 1606897889;
      "Pages" = 409201541;
      "Rakuten Cash Back" = 1451893560;
    };
  };
}
