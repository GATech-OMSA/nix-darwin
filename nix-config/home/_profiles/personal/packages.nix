# home/_profiles/personal/packages.nix
#
# Packages specific to personal profile
# All packages commented out — uncomment as needed

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ============================================
    # CREATIVE & MEDIA TOOLS
    # ============================================
    # Video & audio
    # ffmpeg             # Video/audio converter
    # yt-dlp             # Video/audio downloader — removed 2026-06-28: co-pulled ffmpeg→unbound (use `nix run nixpkgs#yt-dlp`)
    # obs-studio         # Screen recording/streaming
    # handbrake          # Video transcoder
    # sox                # Sound processing

    # Image
    # imagemagick        # Image manipulation CLI — removed 2026-06-28: pulled libraw/openexr/libheif/libde265 CVEs (use `nix run nixpkgs#imagemagick`)
    # darktable          # Photo workflow
    # inkscape           # Vector graphics editor

    # Code screenshots & terminal recording
    # silicon            # Create code screenshots from terminal
    # vhs                # Record terminal sessions as GIFs
    # charm-freeze       # Generate code images from terminal

    # ============================================
    # TERMINAL PRODUCTIVITY
    # ============================================
    # File managers
    # yazi               # Blazing fast terminal file manager (Rust)
    # superfile          # Modern TUI file manager

    # Search & navigation
    # television         # Fuzzy finder TUI for files/text/git

    # Rendering & display
    glow               # Terminal Markdown renderer
    # onefetch           # Git repo info (neofetch for repos)

    # Shells & multiplexers
    # nushell            # Structured data shell (modern shell alternative)
    # zellij             # Terminal multiplexer (tmux alternative)

    # Editors
    # helix              # Post-modern terminal editor (Rust, Vim-like)

    # ============================================
    # AI/ML EXPERIMENTATION
    # ============================================
    # LLM tools (local)
    # ollama             # Local LLM inference (installed separately)
    # aider-chat         # AI pair programming in terminal
    # fabric-ai          # AI-powered CLI for text processing
    # whisper-cpp        # Local speech-to-text (OpenAI Whisper)
    # llm                # CLI for LLMs
    # aichat             # Chat with AI in terminal

    # ML frameworks (prefer venv over global install)
    # python3Packages.pytorch
    # python3Packages.tensorflow
    # python3Packages.scikit-learn
    # python3Packages.transformers

    # Data science (prefer venv over global install)
    # python3Packages.jupyter
    # python3Packages.pandas
    # python3Packages.numpy
    # python3Packages.matplotlib

    # Model tools
    # mlflow             # ML experiment tracking

    # ============================================
    # PRODUCTIVITY & WRITING
    # ============================================
    # Note-taking
    # nb                 # CLI note-taking, bookmarking, knowledge base
    # marksman           # Markdown LSP
    # vale               # Prose linter

    # PDF & reading
    # calibre            # E-book manager
    # zathura            # Minimal PDF viewer

    # Task management
    # taskwarrior        # CLI task manager
    # timewarrior        # Time tracking

    # ============================================
    # LEARNING & RESEARCH
    # ============================================
    # zotero             # Reference manager
    # anki               # Spaced repetition flashcards
    # jupyter            # Interactive notebooks

    # ============================================
    # PRIVACY & SECURITY
    # ============================================
    # minisign           # Simple file signing tool
    # rage               # Modern encryption tool (age-compatible, Rust)
    # pass               # Unix password manager

    # ============================================
    # BACKUP & SYNC
    # ============================================
    rclone             # Cloud storage sync
    # syncthing          # P2P file sync
    restic             # Incremental backup tool
    # borgbackup         # Deduplicating backup program

    # ============================================
    # PERSONAL AUTOMATION
    # ============================================
    # espanso            # Text expander
  ];
}
