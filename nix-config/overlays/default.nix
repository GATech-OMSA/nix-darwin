# Overlays - Package Overrides and Customizations
#
# Purpose: Modify existing nixpkgs packages without forking nixpkgs
# Usage: Import in flake.nix to apply customizations

{ inputs, userConfig, machineConfig, myLib }:

let
  # Extract proxy configuration
  goProxy = userConfig.proxies.go or { enabled = false; };

  # Hash-pinned, vendored sops-install-secrets (cache/sops-nix/sops-install-secrets.gz).
  # A pure path literal — no builtins.getEnv / builtins.pathExists — so this overlay
  # no longer forces --impure. The file is tracked in the repo, so it's present in
  # every checkout (CI included); builtins.path + sha256 verifies it at eval time.
  # Update the pin via:
  #   shasum -a 256 cache/sops-nix/sops-install-secrets.gz | cut -d' ' -f1
  pinnedSopsHash = "cf4f9155cc2d77fa99e1ee285f5efa87a780d51136be33152eec7a3366e0c0f4";
  prebuiltSopsStorePath = builtins.path {
    path = ../../cache/sops-nix/sops-install-secrets.gz;
    name = "sops-install-secrets.gz";
    sha256 = pinnedSopsHash;
  };

  # Work has no local override capability — always build from source (via the
  # corporate Go proxy when configured, else the default proxy.golang.org).
  # Personal uses the vendored, hash-pinned binary, skipping the Go build.
  isWorkProfile = (machineConfig.profileName or "") == "work";
  usePrebuiltSops = !isWorkProfile;
in

[
  # ============================================
  # SOPS-NIX CORPORATE PROXY SUPPORT
  # ============================================
  # Issue: Corporate proxy blocks Go module downloads from proxy.golang.org
  #
  # Resolution:
  #   - Personal: vendored, hash-pinned sops-install-secrets (no Go build).
  #   - Work: Go proxy override from user-config.nix, else default source build.
  # The previous ~/.local/bin override (an un-pinned, user-managed binary) was
  # dropped — the vendored cache is the same binary (verified byte-identical),
  # now hash-checked at eval time instead of silently trusted.
  (_final: prev:
    if usePrebuiltSops then {
      sops-install-secrets = prev.runCommand "sops-install-secrets" {} ''
        mkdir -p $out/bin
        ${prev.gzip}/bin/gunzip -c ${prebuiltSopsStorePath} > $out/bin/sops-install-secrets
        chmod +x $out/bin/sops-install-secrets
      '';
    }
    else if goProxy.enabled or false then {
      # Use corporate Go proxy for building from source
      sops-install-secrets = inputs.sops-nix.packages.${prev.system}.sops-install-secrets.overrideAttrs (_: {
        overrideModAttrs = _: myLib.go.proxyVars goProxy;
      });
    } else
      { }  # No override — build from source using default proxy.golang.org
  )

  # ============================================
  # DIRENV — skip checkPhase
  # ============================================
  # Issue: direnv's test suite hangs/is extremely slow on Apple Silicon
  # (filesystem semantics tests, sandbox overhead). Tests pass in CI;
  # locally they routinely hit 15+ min. Skip them — cached binaries on
  # cache.nixos.org are already test-validated upstream.
  (_final: prev: {
    direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
  })

  # ============================================
  # CUSTOM PACKAGES (nix-config/pkgs)
  # ============================================
  # Inject this repo's own derivations so they're available as pkgs.<name>
  # (e.g. pkgs.security-scan) and can go into environment.systemPackages.
  (final: _prev: import ../pkgs { pkgs = final; })
]