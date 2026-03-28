{ config, pkgs, lib, ... }:

{
  # Python development configuration

  home.packages = with pkgs; [
    python313
    uv    # Fast Python package manager
    ruff  # Fast linter/formatter
    # micromamba  # Build broken - install via Homebrew: brew install micromamba
  ];

  # Micromamba configuration
  home.file.".condarc".text = ''
    channels:
      - conda-forge
      - defaults
    channel_priority: flexible
    auto_activate_base: false
    show_channel_urls: true
    changeps1: false  # Don't modify prompt - Starship handles environment display
  '';

  # UV configuration
  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-managed";
  };
}
