{ config, pkgs, lib, ... }:

{
  # System packages shared across all machines
  # CLI tools managed by Nix (not Homebrew) for reproducibility

  environment.systemPackages = with pkgs; [
    # Version Control
    git
    git-lfs
    gh  # GitHub CLI

    # Editors
    vim
    neovim

    # Shell
    zsh

    # Python Development
    python313
    python313Packages.pip
    uv  # Fast Python package manager
    ruff  # Fast Python linter/formatter
    # micromamba  # BROKEN: Compilation error with fmt library (see overlays/default.nix)
    #             # Using Homebrew instead (brew install micromamba)

    # Node.js Development (commented out - not needed for Python/AI/ML focus)
    # nodejs_22
    # nodePackages.npm
    # nodePackages.pnpm
    # nodePackages.yarn

    # Infrastructure as Code
    # terraform
    # terraform-docs
    # tflint
    # tfsec

    # Cloud
    awscli2

    # Containers & Orchestration
    docker-compose
    kubectl
    k9s
    kubernetes-helm

    # Modern CLI Tools (replacements for standard Unix tools)
    ripgrep  # Better grep (rg)
    fd  # Better find
    bat  # Better cat with syntax highlighting
    eza  # Better ls with icons
    fzf  # Fuzzy finder
    delta  # Better git diff
    dust  # Better du
    duf  # Better df
    btop  # Better top
    procs  # Better ps
    sd  # Better sed
    zoxide  # Smart cd replacement (z)
    direnv  # Environment switcher
    nix-direnv  # Fast direnv for Nix

    # Data Tools
    # sqlite
    # postgresql_16
    # redis

    # JSON/YAML/TOML Tools
    jq
    yq-go
    dasel

    # Network Tools
    wget
    curl
    httpie

    # System Utilities
    htop
    tree
    watch
    tldr  # Simplified man pages
    neofetch  # System info

    # File Utilities
    rsync
    unzip
    p7zip
    duti  # Default application handler

    # Text Processing
    gnused
    gawk
    pandoc  # Document converter

    # Development Utilities
    go  # Go language
    php  # PHP

    # Interview Prep & System Design
    mermaid-cli  # Text-to-diagram for system design
    graphviz     # Graph/architecture visualization
    plantuml     # UML diagrams

    # Performance & Benchmarking
    hyperfine    # Command-line benchmarking tool
    entr         # Run commands when files change

    # AI/ML Development
    ollama       # LLM inference engine

    # Code Quality & Development
    pre-commit   # Git hooks framework

    # Note-taking & Documentation
    nb           # CLI note-taking

    # macOS Specific
    mkalias

    # Additional useful tools
    tmux  # Terminal multiplexer
    starship  # Modern shell prompt
    age  # Encryption tool (for secrets)
    sops  # Secrets management
  ];

  # Environment variables
  environment.variables = {
    EDITOR = "code --wait";
    VISUAL = "code";
    PAGER = "less";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
