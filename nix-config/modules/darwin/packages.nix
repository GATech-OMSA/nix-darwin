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
    # Note: bat, eza, fzf, zoxide, direnv, atuin — installed via programs.* in _template/programs/
    ripgrep  # Better grep (rg)
    fd  # Better find
    delta  # Better git diff (line-based)
    difftastic  # AST-based structural diff — ignores pure reformatting (use via git difftool)
    dust  # Better du
    duf  # Better df
    btop  # Better top
    procs  # Better ps
    sd  # Better sed
    gum  # Interactive CLI components
    nix-direnv  # Fast direnv for Nix

    # JSON/YAML/TOML Tools
    jq
    yq-go

    # Network Tools
    wget
    curl
    xh         # Better httpie alternative (faster, Rust-based)

    # System Utilities
    watch
    # tealdeer  # Fast tldr client (Rust, same pages, offline cache)
    # fastfetch  # System info — removed 2026-06-28: pulled imagemagick (libraw/openexr/libheif/libde265 CVEs) for the logo
    # glow  # Terminal markdown viewer

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

    # TUI Tools (Terminal User Interfaces)
    lazygit      # Beautiful TUI for git operations
    lazydocker   # Beautiful TUI for Docker management
    # yazi         # Terminal file manager — removed 2026-06-28: pulled imagemagick + ffmpeg→unbound (CVSS 10.0) for previews

    # Code Quality & Development
    pre-commit   # Git hooks framework
    # markdown-link-check  # Validate markdown links — removed 2026-06-28: pulled nodejs→ada CVE (use `npx markdown-link-check`)
    just         # Command runner

    # Code Analysis & Search (enhance Claude Code)
    # ast-grep     # Structural code search (AST-based, better than regex)
    # tokei        # Fast code statistics (lines, languages, etc.)
    # repomix      # Pack repo into one AI-friendly file — removed 2026-06-28: pulled nodejs→ada CVE (use `npx repomix`)

    # Security
    gitleaks     # Secret scanning for git repos (pre-commit integration)
    security-scan  # Custom (nix-config/pkgs): CVE scan of system closure + brew cask drift; bundles vulnix

    # macOS Specific
    mkalias
    tmux  # Terminal multiplexer

    # Nix Tooling
    nh  # Modern Nix helper (better darwin-rebuild UX)
    nix-output-monitor  # Pretty build progress (pipe rebuild through nom)
    nvd          # Package version diff between generations
    deadnix      # Find unused code in .nix files
    statix       # Nix linter and fixer
    nixd         # Nix LSP — option/attr completion + eval diagnostics in editors
    comma        # Run any nixpkg without installing (, cowsay hello)

    # Data & Log Tools
    jnv          # Interactive JSON filter with live jq preview
    tailspin     # Zero-config log file highlighter
    moreutils    # ts, sponge, parallel, and other unix essentials
    watchexec    # Execute commands on file changes

    # Secrets Management
    age  # Encryption tool (for secrets)
    sops  # Secrets management
  ];

  # Development packages (all dev machines - both work and personal)
  developmentPackages = with pkgs; [
    # Development Utilities
    gnumake  # Build automation
    go  # Go language
    bun  # Fast JavaScript runtime and package manager

    # Containers & Orchestration
    kubectl
    kubectx      # Fast K8s context/namespace switching (includes kubens)
    k9s
    kubernetes-helm
    opentofu     # Infrastructure as code — MPL 2.0 fork; replaces terraform (BSL since v1.6)

    # Cloud
    awscli2
    granted      # AWS SSO helper — encrypts SSO tokens in keychain (awscli caches them plaintext)

    # Interview Prep & System Design
    # mermaid-cli  # Text-to-diagram — disabled (pulls in chromium); GitHub/Obsidian/VS Code render natively
    graphviz     # Graph/architecture visualization
  ];

  # Work-only packages
  workPackages = with pkgs; [
    ghostty-bin  # Terminal emulator (pre-built macOS binary from nixpkgs)
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
    essentialPackages
    ++ developmentPackages
    ++ (myLib.selectByProfile profileName {
      work = workPackages;
      personal = personalPackages;
      default = [];
    })
  ;
}
