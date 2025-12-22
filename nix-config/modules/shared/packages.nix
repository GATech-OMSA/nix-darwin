{ config, pkgs, lib, myLib, hostname, profileName ? "personal", ... }:

# System Packages
#
# Cross-platform system packages available on all machines.
# Machine-specific packages should go in mixins (personal.nix, work.nix, dev.nix).

let
  # ============================================
  # PACKAGE GROUPS BY CATEGORY
  # ============================================

  # Essential packages for ALL machines
  essentialPackages = with pkgs; [
    # Version Control
    git
    git-lfs
    gh  # GitHub CLI

    # Editors
    vim
    neovim

    # Shell
    zsh

    # Modern CLI Tools (replacements for standard Unix tools)
    # Note: bat, eza, fzf, zoxide, direnv, atuin - installed via programs.* in home/_mixins/base.nix
    ripgrep  # Better grep (rg)
    fd  # Better find
    delta  # Better git diff (line-based)
    difftastic  # Syntax-aware diff (structural, use alongside delta)
    dust  # Better du
    duf  # Better df
    btop  # Better top
    procs  # Better ps
    sd  # Better sed
    gum  # Interactive CLI components (used by install-awesome-apps.sh)
    nix-direnv  # Fast direnv for Nix

    # JSON/YAML/TOML Tools
    jq
    yq-go
    dasel

    # Network Tools
    wget
    curl
    xh         # Better httpie alternative (faster, Rust-based)

    # System Utilities
    htop
    tree
    watch
    tldr  # Simplified man pages
    navi  # Interactive command cheatsheet (better than tldr for complex commands)
    fastfetch  # System info (modern replacement for neofetch)
    glow  # Terminal markdown viewer

    # File Utilities
    rsync
    unzip
    p7zip
    duti  # Default application handler

    # Text Processing
    gnused
    gawk
    pandoc  # Document converter

    # Performance & Benchmarking
    hyperfine    # Command-line benchmarking tool
    entr         # Run commands when files change

    # TUI Tools (Terminal User Interfaces)
    lazygit      # Beautiful TUI for git operations
    lazydocker   # Beautiful TUI for Docker management
    yazi         # Blazing fast terminal file manager
    jless        # Interactive JSON viewer
    zellij       # Modern terminal multiplexer (alongside tmux)
    helix        # Fast modal editor (alternative to vim/neovim)

    # Code Quality & Development
    pre-commit   # Git hooks framework
    nodePackages.markdown-link-check  # Validate markdown links
    just         # Command runner

    # Code Analysis & Search (enhance Claude Code)
    ast-grep     # Structural code search (AST-based, better than regex)
    tokei        # Fast code statistics (lines, languages, etc.)
    repomix      # Pack entire repo into single AI-friendly file

    # Note-taking & Documentation
    nb           # CLI note-taking
    mdbook       # Fast documentation generator (Rust)

    # Security
    gitleaks     # Secret scanning for git repos (pre-commit integration)

    # macOS Specific
    mkalias
    tmux  # Terminal multiplexer

    # Nix Tooling
    nh  # Modern Nix helper (better darwin-rebuild UX)

    # Secrets Management
    age  # Encryption tool (for secrets)
    sops  # Secrets management
  ];

  # Development packages (all dev machines - both work and personal)
  developmentPackages = with pkgs; [
    # Development Utilities
    go  # Go language
    php  # PHP

    # Containers & Orchestration
    docker-compose
    kubectl
    kubectx      # Fast K8s context/namespace switching (includes kubens)
    k9s
    kubernetes-helm
    stern        # Multi-pod log tailing for K8s
    terraform    # Infrastructure as code

    # Database
    usql         # Universal SQL client (PostgreSQL, MySQL, SQLite, MSSQL, etc.)

    # Cloud
    awscli2

    # Interview Prep & System Design
    mermaid-cli  # Text-to-diagram for system design
    graphviz     # Graph/architecture visualization
    plantuml     # UML diagrams
  ];

  # Personal-only packages (AI/ML tools not needed on work machines)
  personalPackages = with pkgs; [
    # ollama       # LLM inference engine - Using Homebrew cask 'ollama-app' instead (build issues in nixpkgs)
  ];

in
{
  # System packages shared across all machines
  # CLI tools managed by Nix (not Homebrew) for reproducibility
  # Machine-specific packages should go in mixins (personal.nix, work.nix, dev.nix)

  environment.systemPackages =
    # Essential packages for all machines
    essentialPackages

    # Development packages for all dev machines
    ++ developmentPackages

    # Personal-only packages (AI/ML)
    ++ lib.optionals (profileName == "personal") personalPackages
  ;

  # Implementation Notes:
  # ======================
  #
  # Package Organization:
  #   - essentialPackages: Required on ALL machines (67 packages)
  #   - developmentPackages: Development tools for all dev machines (9 packages)
  #   - workPackages: Work-specific tools (commented out - currently in work.nix)
  #   - personalPackages: Personal-specific tools (commented out)
  #
  # Conditional Installation:
  #   - Currently: All machines get essential + development packages
  #   - Future: Enable conditional blocks above for machine-specific packages
  #   - Use myLib.mkConditionalPackages with myLib.isWork/isPersonal hostname
  #
  # Machine-Specific Packages:
  #   - Work: Database drivers (unixODBC, freetds, postgresql_16, pgcli) in work.nix
  #   - Personal: Currently minimal (neofetch)
  #
  # Other Package Locations:
  #   - Python: home/_template/development/python.nix (UV, Micromamba)
  #   - Node.js: Commented out - not needed for current focus
  #   - Infrastructure: Terraform, etc. commented out - enable per project
  #   - Data Tools: sqlite, postgresql, redis commented out - install per project
  #   - User Programs: bat, eza, fzf, zoxide, direnv via home/_mixins/base.nix
}
