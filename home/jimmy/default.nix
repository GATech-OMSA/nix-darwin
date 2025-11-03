{ config, pkgs, lib, inputs, mixins, hostname, myLib, ... }:

{
  # Home Manager configuration for jimmy
  # This is the main entry point for user-level configuration

  home = {
    username = "jimmy";
    homeDirectory = "/Users/jimmy";
    stateVersion = "24.05";  # Check home-manager releases

    # Session variables
    sessionVariables = {
      EDITOR = "code --wait";
      VISUAL = "code";
      PAGER = "less";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # Python
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
      UV_PYTHON_PREFERENCE = "only-managed";

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
      installGitHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Install git hooks for secrets validation
        NIX_DARWIN_DIR="$HOME/nix-darwin"

        # Only install if .git directory exists
        if [ -d "$NIX_DARWIN_DIR/.git" ]; then
          # Check if hooks already exist (skip if present to save time)
          if [ ! -f "$NIX_DARWIN_DIR/.git/hooks/pre-commit" ] || [ ! -f "$NIX_DARWIN_DIR/.git/hooks/pre-push" ]; then
            echo "🪝 Installing git hooks for secrets validation..."

            # Ensure hooks directory exists
            mkdir -p "$NIX_DARWIN_DIR/.git/hooks"

            # Install pre-commit hook
            cat > "$NIX_DARWIN_DIR/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook to check for unencrypted secrets files

SECRETS_DIR="$HOME/nix-darwin/hosts"

# Find all secrets.yaml files
for secrets_file in $(find "$SECRETS_DIR" -name "secrets.yaml" 2>/dev/null); do
  # Check if file is staged for commit
  if git diff --cached --name-only | grep -q "$(basename $(dirname $secrets_file))/secrets.yaml"; then
    # Check if file is encrypted (SOPS files are binary)
    if file "$secrets_file" | grep -q "ASCII text"; then
      echo "❌ ERROR: Unencrypted secrets file detected: $secrets_file"
      echo "   Please encrypt with: sops -e -i $secrets_file"
      exit 1
    fi
  fi
done

exit 0
EOF

            # Install pre-push hook
            cat > "$NIX_DARWIN_DIR/.git/hooks/pre-push" << 'EOF'
#!/bin/bash
# Pre-push hook to check for unencrypted secrets files

SECRETS_DIR="$HOME/nix-darwin/hosts"

# Find all secrets.yaml files
for secrets_file in $(find "$SECRETS_DIR" -name "secrets.yaml" 2>/dev/null); do
  # Check if file is encrypted (SOPS files are binary)
  if file "$secrets_file" | grep -q "ASCII text"; then
    echo "❌ ERROR: Unencrypted secrets file detected: $secrets_file"
    echo "   Please encrypt with: sops -e -i $secrets_file"
    exit 1
  fi
done

exit 0
EOF

            # Make hooks executable
            chmod +x "$NIX_DARWIN_DIR/.git/hooks/pre-commit"
            chmod +x "$NIX_DARWIN_DIR/.git/hooks/pre-push"

            echo "  ✅ Git hooks installed successfully"
          fi
        fi
      '';
    };
  };

  # Import all configurations
  imports = [
    # Mixins (reusable configurations)
    ../_mixins/base.nix
    ../_mixins/dev.nix
  ]
  # Import machine-specific mixins based on hostname
  ++ myLib.importIfPersonal hostname ../_mixins/personal.nix
  ++ myLib.importIfWork hostname ../_mixins/work.nix
  ++ [
    # Individual program configurations
    ./shell/zsh.nix
    ./programs/git.nix
    ./programs/vscode.nix
    ./programs/direnv.nix
    ./programs/ssh.nix
    ./programs/aws.nix
    ./development/python.nix
    ./development/node.nix
    ./development/ai-ml.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
