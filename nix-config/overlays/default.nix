# Overlays - Package Overrides and Customizations
#
# Purpose: Modify existing nixpkgs packages without forking nixpkgs
# Usage: Import in flake.nix to apply customizations

{ inputs, userConfig }:

let
  # Extract proxy configuration
  goProxy = userConfig.proxies.go or { enabled = false; };

  # Check for pre-built sops-install-secrets binary (for proxied machines)
  # Resolution order:
  #   1. ~/.local/bin/sops-install-secrets (manually imported)
  #   2. cache/sops-nix/sops-install-secrets.gz (auto-extracted from repo)
  # Note: builtins.getEnv requires --impure (rebuild.sh always passes this)
  homeDir = builtins.getEnv "HOME";
  flakeRoot = builtins.getEnv "FLAKE_ROOT";

  # Check ~/.local/bin first
  localBinPath =
    if homeDir != "" then homeDir + "/.local/bin/sops-install-secrets" else "";
  hasLocalBin = localBinPath != "" && builtins.pathExists localBinPath;

  # Fallback: check repo cache (no manual import.sh needed)
  repoCachePath =
    if flakeRoot != "" then flakeRoot + "/cache/sops-nix/sops-install-secrets.gz" else "";
  hasRepoCache = repoCachePath != "" && builtins.pathExists repoCachePath;

  # Copy into Nix store for sandbox access
  prebuiltSopsStorePath =
    if hasLocalBin
    then builtins.path { path = localBinPath; name = "sops-install-secrets"; }
    else if hasRepoCache
    then builtins.path { path = repoCachePath; name = "sops-install-secrets.gz"; }
    else null;

  hasPrebuiltSops = hasLocalBin || hasRepoCache;
in

[
  # ============================================
  # SOPS-NIX CORPORATE PROXY SUPPORT
  # ============================================
  # Issue: Corporate proxy blocks Go module downloads from proxy.golang.org
  #
  # Resolution order:
  #   1. Pre-built binary at ~/.local/bin/sops-install-secrets (via cache/sops-nix/)
  #   2. Go proxy override from user-config.nix
  #   3. Default (build from source)
  (_final: prev:
    if hasPrebuiltSops then {
      # Use pre-built binary — avoids Go build entirely
      sops-install-secrets = prev.runCommand "sops-install-secrets" {} (
        if hasLocalBin then ''
          mkdir -p $out/bin
          cp ${prebuiltSopsStorePath} $out/bin/sops-install-secrets
          chmod +x $out/bin/sops-install-secrets
        '' else ''
          mkdir -p $out/bin
          ${prev.gzip}/bin/gunzip -c ${prebuiltSopsStorePath} > $out/bin/sops-install-secrets
          chmod +x $out/bin/sops-install-secrets
        ''
      );
    }
    else if goProxy.enabled or false then {
      # Use corporate Go proxy for building from source
      sops-install-secrets = inputs.sops-nix.packages.${prev.system}.sops-install-secrets.overrideAttrs (_: {
        overrideModAttrs = _: {
          GOPROXY = "${goProxy.url},direct";
          GOPRIVATE = goProxy.private or "";
          GOSUMDB = "off";
        };
      });
    } else
      { }  # No override — build from source using default proxy.golang.org
  )
]
