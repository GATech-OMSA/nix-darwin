# home/_profiles/personal/packages.nix
#
# Packages specific to personal profile

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ============================================
    # ACTIVE PERSONAL TOOLS
    # ============================================
    # neofetch  # Deprecated/unmaintained — use fastfetch (installed in system packages)

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
}
