# Overlays - Package Overrides and Customizations
#
# Purpose: Modify existing nixpkgs packages without forking nixpkgs
# Usage: Import in flake.nix to apply customizations

{ inputs }:

[
  # ============================================
  # PYTHON VERSION PINNING
  # ============================================
  # Pin Python 3.13 to prevent breaking changes from nixpkgs-unstable updates
  (final: prev: {
    # Pin to Python 3.13.x - update version as needed for security patches
    # Check current version: nix eval nixpkgs#python313.version
    python313 = prev.python313.overrideAttrs (old: {
      # Uncomment to pin to specific version:
      # version = "3.13.0";
      # Note: May require updating hash if pinning exact version
    });
  })

  # ============================================
  # MICROMAMBA FIX (BROKEN IN NIXPKGS)
  # ============================================
  # Status: Micromamba 1.5.8 build BROKEN on macOS
  # Error: Compilation failure with fmt library formatter
  # Last tested: 2025-11-02
  #
  # Build error:
  #   error: no viable conversion from 'const fmt::formatter<mamba::specs::Version>'
  #   to 'fmt::detail::value<fmt::context>'
  #
  # Workaround: Using Homebrew
  #   - See modules/darwin/homebrew.nix (micromamba in brews list)
  #   - Command: brew install micromamba
  #
  # Tracking:
  #   - Nixpkgs issue: https://github.com/NixOS/nixpkgs/issues/micromamba
  #   - When fixed upstream, uncomment and test:
  #
  # (final: prev: {
  #   micromamba = prev.micromamba.overrideAttrs (old: {
  #     # Try newer version or apply patch
  #   });
  # })

  # ============================================
  # ADDITIONAL CUSTOMIZATIONS
  # ============================================
  # Add more overlays as needed for:
  # - Package feature flags
  # - Build optimizations
  # - Custom patches
  # - Tool consolidation
]
