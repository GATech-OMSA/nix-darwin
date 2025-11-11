{ config, pkgs, lib, ... }:

# Personal Configuration
#
# Personal machine-specific configuration (MACHINE_MODE="home").
# Includes personal app launchers, learning shortcuts, and curated tool menus.
# Commented sections are tools for personal projects and learning.

{
  # Personal-specific packages
  home.packages = with pkgs; [
    # ============================================
    # ACTIVE PERSONAL TOOLS
    # ============================================
    neofetch

    # ============================================
    # CREATIVE & MEDIA TOOLS (Uncomment as needed)
    # ============================================
    # Video editing & processing
    # ffmpeg         # Video/audio converter
    # handbrake      # Video transcoder
    # obs-studio     # Screen recording/streaming

    # Image editing & graphics
    # imagemagick    # Image manipulation CLI
    # gimp           # Photo editor
    # inkscape       # Vector graphics editor
    # darktable      # Photo workflow

    # Audio tools
    # audacity       # Audio editor
    # sox            # Sound processing

    # ============================================
    # PRODUCTIVITY & ORGANIZATION (Uncomment as needed)
    # ============================================
    # Note-taking & writing
    # obsidian       # Knowledge base (via Homebrew)
    # marksman       # Markdown LSP
    # pandoc         # Document converter (in shared packages)
    # vale           # Prose linter

    # PDF & reading
    # calibre        # E-book manager
    # zathura        # Minimal PDF viewer
    # qpdfview       # PDF viewer

    # Task management
    # taskwarrior    # CLI task manager
    # timewarrior    # Time tracking

    # ============================================
    # LEARNING & RESEARCH (Uncomment as needed)
    # ============================================
    # Research tools
    # zotero         # Reference manager
    # anki           # Spaced repetition flashcards

    # Documentation browsers
    # devdocs-desktop # Offline documentation
    # zeal           # Documentation browser

    # Learning platforms
    # jupyter        # Interactive notebooks

    # ============================================
    # AI/ML EXPERIMENTATION (Uncomment as needed)
    # ============================================
    # LLM tools (local)
    # ollama         # Local LLM inference (installed separately)
    # llm            # CLI for LLMs
    # aichat         # Chat with AI in terminal

    # ML frameworks & tools
    # python3Packages.pytorch     # PyTorch
    # python3Packages.tensorflow  # TensorFlow
    # python3Packages.scikit-learn  # ML library
    # python3Packages.transformers  # Hugging Face transformers

    # Data science
    # python3Packages.jupyter  # Jupyter notebooks
    # python3Packages.pandas   # Data manipulation
    # python3Packages.numpy    # Numerical computing
    # python3Packages.matplotlib  # Plotting

    # Model tools
    # huggingface-cli  # Hugging Face CLI
    # mlflow          # ML experiment tracking

    # ============================================
    # PERSONAL UTILITIES (Uncomment as needed)
    # ============================================
    # Backup & sync
    # rclone         # Cloud storage sync
    # syncthing      # P2P file sync
    # restic         # Backup tool

    # Password & secrets
    # pass           # Unix password manager
    # pwgen          # Password generator

    # Personal automation
    # espanso        # Text expander
    # hazel          # Automated file organization
  ];

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };

  # Personal-specific shell aliases
  programs.zsh.shellAliases = {
    # ============================================
    # LEARNING DIRECTORY SHORTCUTS
    # ============================================
    learning = "cd ~/Dev/learning";
    algo = "cd ~/Dev/algorithms";
    courses = "cd ~/Dev/courses";
    experiments = "cd ~/Dev/experiments";

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
