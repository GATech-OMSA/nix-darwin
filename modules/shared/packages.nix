{ config, pkgs, lib, myLib, hostname, ... }:

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
    # Note: bat, eza, fzf, zoxide, direnv - installed via programs.* in home/_mixins/base.nix
    ripgrep  # Better grep (rg)
    fd  # Better find
    delta  # Better git diff
    dust  # Better du
    duf  # Better df
    btop  # Better top
    procs  # Better ps
    sd  # Better sed
    nix-direnv  # Fast direnv for Nix

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

    # Performance & Benchmarking
    hyperfine    # Command-line benchmarking tool
    entr         # Run commands when files change

    # Code Quality & Development
    pre-commit   # Git hooks framework
    nodePackages.markdown-link-check  # Validate markdown links

    # Note-taking & Documentation
    nb           # CLI note-taking

    # macOS Specific
    mkalias
    tmux  # Terminal multiplexer

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
    k9s
    kubernetes-helm

    # Cloud
    awscli2

    # Infrastructure as Code (commented out - uncomment if needed)
    # terraform
    # terraform-docs
    # tflint
    # tfsec

    # Interview Prep & System Design
    mermaid-cli  # Text-to-diagram for system design
    graphviz     # Graph/architecture visualization
    plantuml     # UML diagrams

    # AI/ML Development
    ollama       # LLM inference engine
  ];

  # Work-specific packages (work machine only)
  # Currently in home/_mixins/work.nix, but could be moved here if desired
  # workPackages = with pkgs; [
  #   # Database tools are currently in work.nix home.packages
  # ];

  # Personal-specific packages (personal machine only)
  # personalPackages = with pkgs; [
  #   # Future personal-only tools
  # ];

in
{
  # System packages shared across all machines
  # CLI tools managed by Nix (not Homebrew) for reproducibility

  environment.systemPackages =
    # Essential packages for all machines
    essentialPackages

    # Development packages for all dev machines
    ++ developmentPackages

    # Future: Conditional packages based on machine type
    # Uncomment and define workPackages/personalPackages above to enable
    #
    # ++ (myLib.mkConditionalPackages {
    #   condition = myLib.isWork hostname;
    #   packages = workPackages;
    # })
    # ++ (myLib.mkConditionalPackages {
    #   condition = myLib.isPersonal hostname;
    #   packages = personalPackages;
    # });
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
  #   - Python: home/jimmy/development/python.nix (UV, Micromamba)
  #   - Node.js: Commented out - not needed for current focus
  #   - Infrastructure: Terraform, etc. commented out - enable per project
  #   - Data Tools: sqlite, postgresql, redis commented out - install per project
  #   - User Programs: bat, eza, fzf, zoxide, direnv via home/_mixins/base.nix
}
