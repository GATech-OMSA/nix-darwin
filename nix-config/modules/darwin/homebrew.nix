{ config, pkgs, lib, hostname, ... }:

# Homebrew Configuration
#
# Manages GUI applications and Mac App Store apps via Homebrew.
# Controlled by `homebrew.enable` flag in host configuration.

{
  # CLI tools are managed by Nix for better reproducibility

  # Supply-chain hardening for the brew CLI itself (download-time defenses).
  # Tap-trust enforcement is left ON (do NOT set HOMEBREW_NO_REQUIRE_TAP_TRUST).
  environment.variables = {
    HOMEBREW_NO_INSECURE_REDIRECT = "1";  # refuse http/insecure redirects on downloads
    HOMEBREW_NO_ANALYTICS = "1";          # no telemetry
    HOMEBREW_NO_AUTO_UPDATE = "1";        # no implicit metadata pulls; update-brew runs `brew update` explicitly
  };

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
      # buo/cask-upgrade removed: now an untrusted third-party tap, and its `brew cu`
      # is redundant with brew's built-in `brew upgrade --cask --greedy` (used in
      # update-brew). One fewer external code source in the supply chain.
      "anomalyco/tap"     # OpenCode AI coding agent (trust the formula, not whole tap)
    ];

    # Only brew formulae that MUST be from Homebrew
    brews = [
      "mas"         # Mac App Store CLI
      # gemini-cli removed 2026-06-28: brew formula deprecated (disabled 2026-12-18).
      # Replaced by the antigravity-cli cask below (command: agy). NOTE: this changes
      # the `gemini` command to `agy` — reconfigure the peers@arc gemini integration.
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
      "antigravity-cli"     # Google Antigravity agentic CLI (command: agy) — replaces deprecated gemini-cli; cask auto_updates
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
