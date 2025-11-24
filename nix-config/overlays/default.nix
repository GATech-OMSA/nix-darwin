# Overlays - Package Overrides and Customizations
#
# Purpose: Modify existing nixpkgs packages without forking nixpkgs
# Usage: Import in flake.nix to apply customizations

{ inputs }:

[
  # ============================================
  # GO PROXY CONFIGURATION (CORPORATE PROXY)
  # ============================================
  # TODO: buildGoModule overlay breaks other packages
  # Need different approach for corporate proxy
  # Temporarily disabled - SOPS will also be disabled

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
  # SOPS-NIX CORPORATE PROXY SUPPORT
  # ============================================
  # Issue: Corporate proxy blocks Go module downloads from proxy.golang.org
  # Solution: Use proxyVendor attribute to allow GOPROXY from environment
  #
  # Background:
  # - Example Corp blocks direct access to proxy.golang.org
  # - Internal Nexus proxy available at nexus.example.com
  # - nixpkgs buildGoModule supports proxyVendor = true for corporate proxies
  # - When proxyVendor is true, go mod download respects GOPROXY env var
  #
  # Reference:
  # - nixpkgs PR #173092: "buildGoModule: allow goproxy"
  # - pkgs/build-support/go/module.nix contains proxyVendor support
  # - 40+ packages in nixpkgs use this pattern (gitea, go-mockery, mieru, etc.)
  (final: prev:
    let
      # Call sops-nix package set with our modified buildGoModule
      sops-nix-pkgs = prev.callPackage inputs.sops-nix.outPath {
        vendorHash = "sha256-pMw/LIOF2TbaOFL+G0MpzfMPsJWJmtIGESrbDjwfi3Y=";
        # Override buildGo124Module to add proxyVendor for all Go builds in sops-nix
        buildGo124Module = args: prev.buildGo124Module (args // {
          proxyVendor = true;
        });
      };
    in
    {
      # Use the sops-install-secrets from our modified package set
      inherit (sops-nix-pkgs) sops-install-secrets;
    }
  )

  # ============================================
  # ADDITIONAL CUSTOMIZATIONS
  # ============================================
  # Add more overlays as needed for:
  # - Package feature flags
  # - Build optimizations
  # - Custom patches
  # - Tool consolidation
]
