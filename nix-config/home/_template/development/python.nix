{ config, pkgs, lib, ... }:

{
  # Python development configuration

  home.packages = with pkgs; [
    python313
    uv    # Fast Python package manager
    ruff  # Fast linter/formatter
    # micromamba  # Build broken - install via Homebrew: brew install micromamba
  ];

  # Micromamba configuration — disabled; uv is the standard (CLAUDE.md)
  /*
  home.file.".condarc".text = ''
    channels:
      - conda-forge
      - defaults
    channel_priority: flexible
    auto_activate_base: false
    show_channel_urls: true
    changeps1: false  # Don't modify prompt - Starship handles environment display
  '';
  */

  # UV configuration
  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-managed";
  };

  # UV supply chain protection: reject packages published less than 14 days ago.
  # Widened from 7d alongside the npm quarantine given elevated supply-chain risk.
  xdg.configFile."uv/uv.toml".text = ''
    exclude-newer = "14 days"
  '';
}
