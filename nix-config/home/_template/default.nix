{ config, pkgs, lib, inputs, profileName ? "personal", machineId ? "default", hostname, myLib, username, ... }:

{
  # Home Manager configuration for user (username-agnostic)
  # This is the main entry point for user-level configuration
  # Profile-specific config comes from home/_profiles/${profileName}

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";  # NEVER CHANGE

    # Session variables
    sessionVariables = {
      # Profile information
      ACTIVE_PROFILE = profileName;
      MACHINE_ID = machineId;

      # Universal settings
      EDITOR = "code --wait";
      VISUAL = "code";
      PAGER = "less";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # Python
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
      # UV_PYTHON_PREFERENCE defined in development/python.nix

      # AWS
      AWS_PAGER = "";
      AWS_DEFAULT_OUTPUT = "json";

      # FZF
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";

      # Terraform
      TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
    };

    # Packages specific to user (not system-wide)
    packages = with pkgs; [
      # Add user-specific packages here
    ];

    # Activation scripts (run on every rebuild)
    activation = {
      secureCredentialPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        home_dir="${config.home.homeDirectory}"

        # Keep sensitive local auth material locked down on every activation.
        if [ -d "$home_dir/.ssh" ]; then
          chmod 700 "$home_dir/.ssh" 2>/dev/null || true
          [ -f "$home_dir/.ssh/config" ] && chmod 600 "$home_dir/.ssh/config" 2>/dev/null || true
          find "$home_dir/.ssh" -maxdepth 1 -type f ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
          find "$home_dir/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        fi

        if [ -d "$home_dir/.aws" ]; then
          chmod 700 "$home_dir/.aws" 2>/dev/null || true
          [ -f "$home_dir/.aws/credentials" ] && chmod 600 "$home_dir/.aws/credentials" 2>/dev/null || true
          [ -f "$home_dir/.aws/config" ] && chmod 600 "$home_dir/.aws/config" 2>/dev/null || true
        fi

        if [ -d "$home_dir/.config/sops/age" ]; then
          chmod 700 "$home_dir/.config/sops/age" 2>/dev/null || true
          [ -f "$home_dir/.config/sops/age/keys.txt" ] && chmod 600 "$home_dir/.config/sops/age/keys.txt" 2>/dev/null || true
        fi
      '';

      installGitHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
        NIX_DARWIN_DIR="${config.home.homeDirectory}/nix-darwin"
        HOOKS_SRC="$NIX_DARWIN_DIR/scripts/git-hooks"

        if [ -d "$NIX_DARWIN_DIR/.git" ]; then
          mkdir -p "$NIX_DARWIN_DIR/.git/hooks"

          for hook in pre-commit pre-push; do
            src="$HOOKS_SRC/$hook.sh"
            dst="$NIX_DARWIN_DIR/.git/hooks/$hook"
            if [ -f "$src" ]; then
              $DRY_RUN_CMD cp "$src" "$dst"
              $DRY_RUN_CMD chmod +x "$dst"
            fi
          done
        fi
      '';
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
