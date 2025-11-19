{ config, pkgs, lib, myLib, hostname, ... }:

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
    # Note: bat, eza, fzf, zoxide, direnv - installed via programs.* in home/_mixins/base.nix
    ripgrep  # Better grep (rg)
    fd  # Better find
    delta  # Better git diff
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
    httpie

    # System Utilities
    htop
    tree
    watch
    tldr  # Simplified man pages
    fastfetch  # System info (modern replacement for neofetch)

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

in
{
  # System packages shared across all machines
  # CLI tools managed by Nix (not Homebrew) for reproducibility
  # Machine-specific packages should go in mixins (personal.nix, work.nix, dev.nix)

  environment.systemPackages =
    # Essential packages for all machines
    essentialPackages
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
