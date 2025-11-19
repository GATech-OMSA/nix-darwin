# home/_profiles/work/aliases.nix
#
# Aliases specific to work profile

{ config, lib, myLib, ... }:

{
  programs.zsh.shellAliases = {
    # ============================================
    # WORK PROJECT DIRECTORY SHORTCUTS
    # ============================================
    fscst = "cd ~/Dev/scst";
    fti = "cd ~/Dev/tririga";
    fps-proj = "cd ~/Dev/paging-solution";
    fmp = "cd ~/Dev/misc-projects";
    fwfhub = "cd ~/Dev/workforce-hub";
    fap = "cd ~/Dev/webMethods/api";
    fdeploys = "cd ~/Dev/production-deploys";

    # ============================================
    # AWS CONFIGURATION
    # ============================================
    edit-aws = "$EDITOR ~/.aws/config";
  };

  # ============================================
  # WORK-SPECIFIC FUNCTIONS
  # ============================================
  programs.zsh.initContent = lib.mkAfter ''
    # Edit AWS account mapping (work profile only)
    # Manages aws_accounts field in secrets.yaml for SSO multi-account setup
    function edit-aws-map() {
      local machine_config="$HOME/nix-darwin/config/machine-config.nix"

      if [ ! -f "$machine_config" ]; then
        echo "❌ Error: machine-config.nix not found"
        echo "Expected: $machine_config"
        return 1
      fi

      local machine_id=$(grep 'machineId' "$machine_config" | sed 's/.*"\(.*\)".*/\1/')

      if [ -z "$machine_id" ]; then
        echo "❌ Error: Could not extract machineId from $machine_config"
        return 1
      fi

      local secrets_file="$HOME/nix-darwin/nix-config/hosts/$machine_id/secrets.yaml"

      if [ ! -f "$secrets_file" ]; then
        echo "❌ Error: secrets file not found"
        echo "Expected: $secrets_file"
        echo ""
        echo "💡 To create encrypted secrets:"
        echo "  1. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt"
        echo "  2. Update .sops.yaml with your public key"
        echo "  3. Run: sops $secrets_file"
        return 1
      fi

      if ! command -v sops &> /dev/null; then
        echo "❌ Error: sops not found"
        echo "Install with: brew install sops"
        return 1
      fi

      echo "🗺️  Editing AWS Account Mapping"
      echo ""
      echo "  • Manages aws_accounts field in secrets.yaml"
      echo "  • Maps AWS account IDs to profile names for SSO"
      echo "  • Template: ~/nix-darwin/nix-config/home/_profiles/work/accounts.json.template"
      echo "  • After editing: nix-rebuild to deploy to ~/.aws/accounts.json"
      echo ""
      echo "📖 Documentation: ~/nix-darwin/nix-config/home/_profiles/work/README-accounts.md"
      echo ""
      echo "🔐 Opening secrets file: $secrets_file"
      echo ""

      # Open SOPS editor
      sops "$secrets_file"

      echo ""
      echo "✅ Changes saved and re-encrypted"
      echo ""
      echo "Next steps:"
      echo "  1. Run: nix-rebuild"
      echo "  2. Run: awslist  # Verify profiles loaded"
    }
  '';
}
