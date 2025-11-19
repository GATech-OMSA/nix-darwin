{ config, pkgs, lib, ... }:

# Personal Configuration
#
# Personal machine-specific configuration (MACHINE_MODE="home").
# Includes personal app launchers, learning shortcuts, and curated tool menus.
# Commented sections are tools for personal projects and learning.

{
  # Personal-specific packages moved to _profiles/personal/packages.nix
  # This keeps mixins focused on behavior (functions, aliases, env vars)
  # and profiles focused on packages (tools, CLI utilities)

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };

  # Personal-specific shell aliases
  programs.zsh.shellAliases = {
    # ============================================
    # LEARNING DIRECTORY SHORTCUTS - DEPRECATED: Use zoxide (z <dir>)
    # ============================================

    # ============================================
    # OLLAMA SHORTCUTS
    # ============================================
    ollama-start = "ollama serve";
    models = "ollama list";
    llama3 = "ollama run llama3";
    codellama = "ollama run codellama";

    # ============================================
    # APP LAUNCHERS - Personal Applications
    # ============================================
    # These are personal-specific apps installed via Homebrew
    # (Homebrew is enabled on personal Mac, disabled on work Mac)

    # Browsers
    ff = "open -a Firefox";
    orion = "open -a Orion";

    # AI/LLM Tools
    cld = "open -a Claude";
    gpt = "open -a ChatGPT";
    pplx = "open -a Perplexity";
    obs = "open -a Obsidian";
    jan = "open -a Jan";

    # Development Tools
    cursor = "open -a Cursor";
    cur = "open -a Cursor";

    # Productivity
    pdf = "open -a 'PDF Expert'";
    shot = "open -a Shottr";
    alfred = "open -a Alfred";

    # Communication
    zoom = "open -a Zoom";
    wa = "open -a WhatsApp";
    whatsapp = "open -a WhatsApp";

    # Other Personal Apps
    tv = "open -a TradingView";
    vpn = "open -a ProtonVPN";
  };
}
