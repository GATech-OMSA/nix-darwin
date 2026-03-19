{ config, pkgs, lib, inputs, profileName ? "personal", machineId ? "default", mixins ? [], hostname, myLib, username, ... }:

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
      installGitHooks = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Install git hooks for secrets validation
        NIX_DARWIN_DIR="${config.home.homeDirectory}/nix-darwin"

        # Only install if .git directory exists
        if [ -d "$NIX_DARWIN_DIR/.git" ]; then
          # Check if hooks already exist (skip if present to save time)
          if [ ! -f "$NIX_DARWIN_DIR/.git/hooks/pre-commit" ] || [ ! -f "$NIX_DARWIN_DIR/.git/hooks/pre-push" ]; then
            echo "Installing git hooks for secrets validation..."

            # Ensure hooks directory exists
            mkdir -p "$NIX_DARWIN_DIR/.git/hooks"

            # Install pre-commit hook
            cat > "$NIX_DARWIN_DIR/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook to check for unencrypted secrets files and credential protection

echo "→ Validating secrets and credentials..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data-${username}/secrets/*.yaml"
)

BLOCKED_PATTERNS=(
  "*_credentials.txt"
  "*_credentials.json"
  "*_credentials.yaml"
  "*_password.txt"
  "*_secrets.txt"
)

# Cache staged files list once (avoid repeated git calls)
STAGED_FILES=$(git diff --cached --name-only)

# Check if any credential files are staged
echo "  → Checking for blocked credential files..."
for pattern in "''${BLOCKED_PATTERNS[@]}"; do
  if echo "$STAGED_FILES" | grep -q "$pattern"; then
    echo "✗ ERROR: Attempting to commit credential file matching pattern: $pattern"
    echo "   These files should never be committed. Add to .gitignore."
    exit 1
  fi
done

# Check if .db/, .tokens/, .credentials/ directories are staged
if echo "$STAGED_FILES" | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "✗ ERROR: Attempting to commit credential directory (.db/, .tokens/, or .credentials/)"
  echo "   These directories contain plaintext credentials and should never be committed."
  echo "   Fix: Ensure .gitignore contains these directories"
  exit 1
fi

# Check SOPS-encrypted files
echo "  → Validating SOPS encryption..."
for pattern in "''${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # Check if staged for commit
    rel_path="''${secrets_file#$HOME/nix-darwin/}"
    if echo "$STAGED_FILES" | grep -q "$rel_path"; then
      # SOPS can encrypt in two formats:
      # 1. Binary format (completely encrypted)
      # 2. YAML format (encrypted values with SOPS metadata)

      # Check for binary format
      if ! file "$secrets_file" | grep -q "ASCII text"; then
        echo "  ✓ Encrypted (binary): $rel_path"
        continue
      fi

      # Check for SOPS YAML format (has sops: metadata section)
      if grep -q "^sops:" "$secrets_file" && grep -q "mac:" "$secrets_file"; then
        echo "  ✓ Encrypted (YAML): $rel_path"
        continue
      fi

      # Check for SOPS encrypted values (ENC[AES256_GCM pattern)
      if grep -q "ENC\[AES256_GCM" "$secrets_file"; then
        echo "  ✓ Encrypted (YAML): $rel_path"
        continue
      fi

      # Not encrypted
      echo "✗ ERROR: Unencrypted secrets file detected: $secrets_file"
      echo "   Please encrypt with: sops -e -i $secrets_file"
      exit 1
    fi
  done
done

echo "✓ All security checks passed"
exit 0
EOF

            # Install pre-push hook
            cat > "$NIX_DARWIN_DIR/.git/hooks/pre-push" << 'EOF'
#!/bin/bash
# Pre-push hook to check for unencrypted secrets files and credential protection

echo "→ Final security check before push..."

SECRETS_PATHS=(
  "$HOME/nix-darwin/hosts/*/secrets.yaml"
  "$HOME/nix-darwin/user-data-${username}/secrets/*.yaml"
)

CREDENTIAL_PATHS=(
  "$HOME/.db"
  "$HOME/.tokens"
  "$HOME/.credentials"
)

# Check SOPS-encrypted files
echo "  → Validating all SOPS-encrypted files..."
error_found=0

for pattern in "''${SECRETS_PATHS[@]}"; do
  for secrets_file in $pattern; do
    [ -f "$secrets_file" ] || continue

    # SOPS can encrypt in two formats:
    # 1. Binary format (completely encrypted)
    # 2. YAML format (encrypted values with SOPS metadata)

    # Check for binary format (skip ASCII text check if binary)
    if ! file "$secrets_file" | grep -q "ASCII text"; then
      continue
    fi

    # Check for SOPS YAML format (has sops: metadata section)
    if grep -q "^sops:" "$secrets_file" && grep -q "mac:" "$secrets_file"; then
      continue
    fi

    # Check for SOPS encrypted values (ENC[AES256_GCM pattern)
    if grep -q "ENC\[AES256_GCM" "$secrets_file"; then
      continue
    fi

    # Not encrypted
    echo "✗ ERROR: Unencrypted secrets file detected: $secrets_file"
    echo "   Please encrypt with: sops -e -i $secrets_file"
    error_found=1
  done
done

# Final check: ensure no credential directories in git index
echo "  → Checking git index for credential files..."
if git ls-files | grep -E '(^\.db/|^\.tokens/|^\.credentials/)'; then
  echo "✗ ERROR: Credential files found in git index"
  echo "   These should never be committed. Remove with: git rm --cached <file>"
  error_found=1
fi

if [ $error_found -eq 1 ]; then
  echo ""
  echo "✗ Push blocked due to security issues. Please fix the above errors."
  exit 1
fi

echo "✓ All security checks passed - safe to push"
exit 0
EOF

            # Make hooks executable
            chmod +x "$NIX_DARWIN_DIR/.git/hooks/pre-commit"
            chmod +x "$NIX_DARWIN_DIR/.git/hooks/pre-push"

            echo "  ✓ Git hooks installed successfully"
          fi
        fi
      '';
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
