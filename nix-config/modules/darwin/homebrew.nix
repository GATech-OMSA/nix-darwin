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
      # "micromamba"  # Conda replacement — disabled; uv is the standard (CLAUDE.md)
      "gemini-cli"  # Google Gemini CLI
      "gh"          # GitHub CLI
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
      "microsoft-excel"        # migrated from MAS — `mas uninstall 462058435` first
      "microsoft-powerpoint"   # migrated from MAS — `mas uninstall 462062816` first
      "bruno"                  # Git-friendly local API client (modern Postman) — also on nix
      "proxyman"               # Native HTTP/HTTPS debugging proxy with SSL inspection
      "kaleidoscope"           # Best-in-class visual diff/merge for code, folders, images

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
      "appcleaner"
      "keka"
      "keyclu"
      "shottr"
      "obsidian"
      "hush"                # migrated from MAS — `mas uninstall 1544743900` first
      "betterdisplay"       # HiDPI/brightness for external monitors on Apple Silicon
      "little-snitch"       # Outbound firewall — per-app network monitoring

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
      "AdBlock Pro" = 1018301773;
      "Capital One Shopping" = 1477110326;
      "Consent-O-Matic" = 1606897889;
      "DarkModeSafari" = 6755151037;
      "Pages" = 409201541;
      "Rakuten Cash Back" = 1451893560;
      "uBlock Origin Lite" = 6745342698;
      "Uplock" = 6469049274;     # was published as "Access" before rename
    };
  };
}
