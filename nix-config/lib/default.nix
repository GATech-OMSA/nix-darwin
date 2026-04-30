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

  # ============================================
  # SECRET REGISTRY
  # ============================================

  # Central list of local secret targets managed or audited by this repo.
  # Paths use ${HOME} so flake outputs stay machine-independent.
  secrets = rec {
    pathsByType = {
      aws = [
        "\${HOME}/.aws/credentials"
        "\${HOME}/.aws/accounts.json"
        "\${HOME}/.aws/.last_profile"
      ];

      ai = [
        "\${HOME}/.codex/auth.json"
        "\${HOME}/.codex/config.toml"
        "\${HOME}/.gemini/oauth_creds.json"
        "\${HOME}/.gemini/google_accounts.json"
        "\${HOME}/.claude/settings.local.json"
      ];

      containers = [
        "\${HOME}/.docker/config.json"
        "\${HOME}/.docker/.token_seed"
      ];

      tokens = [
        "\${HOME}/.tokens/git_token"
        "\${HOME}/.tokens/hcp_terraform_token"
        "\${HOME}/.tokens/jira_api_token"
        "\${HOME}/.tokens/confluence_token"
      ];

      ssh = [
        "\${HOME}/.ssh/id_ed25519"
        "\${HOME}/.ssh/polymarket-quant"
        "\${HOME}/.ssh/hft-demo-key.pem"
        "\${HOME}/.ssh/id_ed25519_work"
        "\${HOME}/.ssh/known_hosts"
      ];

      git = [
        "\${HOME}/.config/gh/hosts.yml"
      ];

      credentials = [
        "\${HOME}/.credentials/servicenow"
        "\${HOME}/.credentials/vpn"
      ];

      general = [
        "\${HOME}/.zsh_secrets"
        "\${HOME}/.zsh_secrets.local"
        "\${HOME}/.secrets/credentials.env"
        "\${HOME}/.secrets/credentials.env.enc"
        "\${HOME}/.config/secrets/local.env"
        "\${HOME}/.config/sops/age/keys.txt"
      ];
    };

    paths = lib.unique (lib.flatten (lib.attrValues pathsByType));

    globPatterns = [
      "\${HOME}/.ssh/id_*"
      "\${HOME}/.tokens/*"
      "\${HOME}/.credentials/*"
      "\${HOME}/.aws/*"
      "\${HOME}/backup/.zsh_secrets-*"
      "\${HOME}/Dev/*/.env"
      "\${HOME}/Dev/*/*/.env"
      "\${HOME}/Desktop/*/.env"
    ];

    meta = {
      version = 1;
      description = "Local secret target registry for validation and permission audits";
      categories = builtins.attrNames pathsByType;
      pathCount = builtins.length paths;
      globPatternCount = builtins.length globPatterns;
    };
  };
}
