# Helper Functions and Utilities
#
# Purpose: Reusable Nix functions for configuration management
# Usage: Import in flake.nix and use across your configuration

{ inputs }:

let
  inherit (inputs.nixpkgs) lib;
in
rec {
  # ============================================
  # PROFILE HELPERS
  # ============================================

  # Check if profile is personal
  isPersonalProfile = profileName: profileName == "personal";

  # Check if profile is work
  isWorkProfile = profileName: profileName == "work";

  # Select value based on profile
  # Usage: selectByProfile profileName { personal = "X"; work = "Y"; }
  selectByProfile = profileName: values:
    values.${profileName}
      or (values.default
      or (throw "No value for profile '${profileName}' and no default provided"));


  # ============================================
  # STATUS MESSAGES
  # ============================================

  # Consistent status message helpers for shell scripts
  msg = {
    success = msg: ''echo "${msg}"'';
    error = msg: ''echo "error: ${msg}" >&2'';
    warning = msg: ''echo "warning: ${msg}"'';
    info = msg: ''echo "${msg}"'';
    loading = msg: ''echo "${msg}..."'';
    rocket = msg: ''echo "${msg}"'';
    package = msg: ''echo "${msg}"'';
    pin = msg: ''echo "${msg}"'';
  };

  # ============================================
  # SHELL HELPERS
  # ============================================

  # Generate a lazy-loaded completion wrapper for a CLI tool
  # The tool's completion is generated on first use and cached
  #
  # Usage in zsh.nix initContent:
  #   ${myLib.mkLazyCompletion {
  #     name = "kubectl";
  #     binary = "${pkgs.kubectl}/bin/kubectl";
  #     completionCommand = "${pkgs.kubectl}/bin/kubectl completion zsh";
  #   }}
  mkLazyCompletion = { name, binary, completionCommand }: ''
    function ${name}() {
      unfunction "$0"
      if [[ ! -f "$HOME/.cache/zsh/${name}_completion" ]]; then
        ${completionCommand} > "$HOME/.cache/zsh/${name}_completion"
      fi
      source "$HOME/.cache/zsh/${name}_completion"
      $0 "$@"
    }
  '';

  # ============================================
  # DATABASE & CREDENTIAL HELPERS
  # ============================================

  # Import database helper library
  database = import ./database-helpers.nix { inherit lib; };

  # ============================================
  # AWS HELPERS
  # ============================================

  # Import AWS helper library
  aws = import ./aws-helpers.nix { inherit lib; };

  # ============================================
  # HOT RELOAD HELPERS
  # ============================================

  # Import hot reload functions
  # Provides instant configuration updates without full rebuild
  reload = import ./reload-helpers.nix { inherit lib; };
}
