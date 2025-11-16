# packages.nix
#
# System packages managed by Nix
# Edit this file to add/remove packages, then run: darwin-rebuild switch --flake .

{ config, pkgs, machineConfig, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    # ===== Essential Tools =====
    git
    gh              # GitHub CLI
    curl
    wget

    # ===== Modern CLI Tools =====
    # These replace standard Unix tools with better alternatives
    eza             # Better ls
    bat             # Better cat
    fd              # Better find
    ripgrep         # Better grep (rg)
    fzf             # Fuzzy finder
    zoxide          # Better cd (z)
    delta           # Better git diff
    dust            # Better du
    duf             # Better df
    btop            # Better top/htop
    procs           # Better ps

    # ===== Data Tools =====
    jq              # JSON processor
    yq-go           # YAML processor

    # ===== Shell & Terminal =====
    starship        # Prompt
    tmux            # Terminal multiplexer
    direnv          # Directory-based environments

    # ===== Development =====
    # Uncomment what you need
    # awscli2         # AWS CLI
    # nodejs          # Node.js
    # python3         # Python
    # rustc           # Rust compiler
    # cargo           # Rust package manager
    # go              # Go language
    # docker          # Docker CLI
    # docker-compose  # Docker Compose

    # ===== Security & Secrets =====
    # sops            # Secrets encryption
    # age             # Encryption tool

    # ===== System Utilities =====
    tree
    watch
    htop
    coreutils
    findutils
    gnugrep
    gnused

    # ===== Add your packages below =====
    # ...
  ];

  # You can also add machine-specific packages
  # Example:
  # environment.systemPackages = with pkgs; [
  #   (if machineConfig.machineType == "work" then [
  #     awscli2
  #     kubectl
  #   ] else [])
  # ];
}
