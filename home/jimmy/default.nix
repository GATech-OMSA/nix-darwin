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
# Pre-commit hook to check for unencrypted secrets files and credential protection

echo "🔍 Validating secrets and credentials..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data/secrets/*.yaml"
)

CREDENTIAL_PATHS=(
  "$HOME/.db"
  "$HOME/.tokens"
  "$HOME/.credentials"
  "$HOME/.aws/credentials"
)

BLOCKED_PATTERNS=(
  "*_credentials.txt"
  "*_credentials.json"
  "*_credentials.yaml"
  "*_password.txt"
  "*_secrets.txt"
)

# Check if any credential files are staged
echo "  🛡️  Checking for blocked credential files..."
for pattern in "''${BLOCKED_PATTERNS[@]}"; do
  if git diff --cached --name-only | grep -q "$pattern"; then
    echo "❌ ERROR: Attempting to commit credential file matching pattern: $pattern"
    echo "   These files should never be committed. Add to .gitignore."
    exit 1
  fi
done

# Check if .db/, .tokens/, .credentials/ directories are staged
if git diff --cached --name-only | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "❌ ERROR: Attempting to commit credential directory (.db/, .tokens/, or .credentials/)"
  echo "   These directories contain plaintext credentials and should never be committed."
  echo "   Fix: Ensure .gitignore contains these directories"
  exit 1
fi

# Check SOPS-encrypted files
echo "  🔐 Validating SOPS encryption..."
for pattern in "''${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # Check if staged for commit
    rel_path="''${secrets_file#$HOME/nix-darwin/}"
    if git diff --cached --name-only | grep -q "$rel_path"; then
      # Must be binary (SOPS encrypted)
      if file "$secrets_file" | grep -q "ASCII text"; then
        echo "❌ ERROR: Unencrypted secrets file detected: $secrets_file"
        echo "   Please encrypt with: sops -e -i $secrets_file"
        exit 1
      fi
      echo "  ✅ Encrypted: $rel_path"
    fi
  done
done

echo "✅ All security checks passed"
exit 0
EOF

            # Install pre-push hook
            cat > "$NIX_DARWIN_DIR/.git/hooks/pre-push" << 'EOF'
#!/bin/bash
# Pre-push hook to check for unencrypted secrets files and credential protection

echo "🔍 Final security check before push..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data/secrets/*.yaml"
)

CREDENTIAL_PATHS=(
  "$HOME/.db"
  "$HOME/.tokens"
  "$HOME/.credentials"
)

# Check SOPS-encrypted files
echo "  🔐 Validating all SOPS-encrypted files..."
error_found=0

for pattern in "''${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # Must be binary (SOPS encrypted)
    if file "$secrets_file" | grep -q "ASCII text"; then
      echo "❌ ERROR: Unencrypted secrets file detected: $secrets_file"
      echo "   Please encrypt with: sops -e -i $secrets_file"
      error_found=1
    fi
  done
done

# Final check: ensure no credential directories in git index
echo "  🛡️  Checking git index for credential files..."
if git ls-files | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "❌ ERROR: Credential files found in git index"
  echo "   These should never be committed. Remove with: git rm --cached <file>"
  error_found=1
fi

if [ $error_found -eq 1 ]; then
  echo ""
  echo "❌ Push blocked due to security issues. Please fix the above errors."
  exit 1
fi

echo "✅ All security checks passed - safe to push"
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
    ./programs/node.nix
    ./programs/karabiner.nix
    ./development/python.nix
    ./development/node.nix
    ./development/ai-ml.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
