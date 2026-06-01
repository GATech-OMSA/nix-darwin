# home/_profiles/personal/aliases.nix
#
# Aliases specific to personal profile

{ config, lib, myLib, ... }:

{
  programs.zsh.shellAliases = {
    # ============================================
    # LEARNING DIRECTORY SHORTCUTS
    # ============================================
    learning = "cd ~/Dev/learning";
    aiml = "cd ~/Dev/ai-ml";
    algo = "cd ~/Dev/algorithms";
    courses = "cd ~/Dev/courses";
    experiments = "cd ~/Dev/experiments";
    oss = "cd ~/Dev/open-source";

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
    pplx = "open -a Perplexity";  # no Homebrew cask; installed via Mac App Store or direct download
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
