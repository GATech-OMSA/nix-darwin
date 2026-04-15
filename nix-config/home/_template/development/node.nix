{ config, pkgs, lib, ... }:

{
  # Node.js development configuration
  # NPM configuration is now in programs/node.nix (profile-specific)
  #
  # Package manager policy:
  #   - npm: supported (bundled with Node, managed via .npmrc)
  #   - Bun: installed system-wide as a runtime, not as a package manager
  #   - pnpm/yarn: use per-project via corepack if needed, not managed globally
  #   - corepack: not enabled globally — project-level packageManager field handles it

  home.packages = with pkgs; [
    nodejs_22  # Includes npm by default
  ];
}
