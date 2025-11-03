{ config, pkgs, lib, myLib, hostname, ... }:

let
  # Toggle for custom keybindings
  enableKeybindings = true;  # Set to false to disable all custom keybindings

  # Karabiner config directory
  karabinerConfigDir = "${config.home.homeDirectory}/.config/karabiner";
  karabinerUserData = "${config.home.homeDirectory}/nix-darwin/user-data/user-content/karabiner";
in

{
  # Install Karabiner-Elements via Homebrew (conditional on toggle)
  # Note: Karabiner-Elements is not available in nixpkgs, must use Homebrew
  # This will be picked up by the darwin homebrew module in modules/darwin/homebrew.nix

  # Activation script to sync Karabiner configuration from user-data
  home.activation.syncKarabinerConfig = lib.mkIf enableKeybindings (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Sync Karabiner-Elements configuration from user-data

      if [ "${toString enableKeybindings}" = "1" ]; then
        ${myLib.msg.info "Syncing Karabiner-Elements configuration..."}

        # Create Karabiner config directory if it doesn't exist
        mkdir -p "${karabinerConfigDir}"
        mkdir -p "${karabinerConfigDir}/assets/complex_modifications"

        # Check if user-data config exists
        if [ -d "${karabinerUserData}" ]; then
          # Copy main configuration
          if [ -f "${karabinerUserData}/karabiner.json" ]; then
            cp "${karabinerUserData}/karabiner.json" "${karabinerConfigDir}/karabiner.json"
            ${myLib.msg.success "Karabiner configuration synced"}
          else
            ${myLib.msg.warning "No karabiner.json found in user-data (will be created on first run)"}
          fi

          # Copy complex modifications
          if [ -d "${karabinerUserData}/assets/complex_modifications" ]; then
            cp -r "${karabinerUserData}/assets/complex_modifications/"* \
               "${karabinerConfigDir}/assets/complex_modifications/" 2>/dev/null || true
            ${myLib.msg.success "Complex modifications synced"}
          fi
        else
          ${myLib.msg.info "User-data Karabiner directory not found (first-time setup)"}
          mkdir -p "${karabinerUserData}/assets/complex_modifications"
        fi

        ${myLib.msg.success "Karabiner setup complete"}
        echo "  ⚠️  Note: Grant 'Input Monitoring' permission in System Settings when prompted"
      fi
    ''
  );

  # Session variable to indicate keybindings are enabled
  home.sessionVariables = lib.mkIf enableKeybindings {
    CUSTOM_KEYBINDINGS_ENABLED = "true";
  };
}
