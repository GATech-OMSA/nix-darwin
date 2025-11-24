# reload-helpers.nix
#
# Hot reload functions for quick configuration updates without full rebuild
# Provides instant feedback for testing secrets and environment variables

{ lib }:

rec {
  # ==================================================
  # SECRETS HOT RELOAD
  # ==================================================
  # Reload secrets from ~/.zsh_secrets without rebuilding
  # Also supports ~/.zsh_secrets.local for temporary testing
  #
  # Usage:
  #   reload-secrets              # Reload both files
  #   secrets-local edit          # Edit local test overrides
  #   secrets-local show          # Show local overrides
  #   secrets-local rm            # Remove local overrides
  #
  # Files:
  #   ~/.zsh_secrets       - SOPS-managed secrets (edit with: edit-secrets)
  #   ~/.zsh_secrets.local - Local testing overrides (gitignored, temporary)
  #
  # Workflow:
  #   1. secrets-local edit       # Create temporary test credentials
  #   2. reload-secrets           # Apply immediately to current shell
  #   3. Test your changes
  #   4. secrets-local rm         # Clean up when done
  #
  mkSecretsReload = ''
    function reload-secrets() {
      echo "🔄 Reloading secrets..."
      echo ""

      local count=0
      local files=()

      # Reload main secrets (SOPS-managed)
      if [ -f ~/.zsh_secrets ]; then
        source ~/.zsh_secrets
        echo "✅ Reloaded ~/.zsh_secrets"
        files+=("~/.zsh_secrets")
        ((count++))
      else
        echo "⚠️  No ~/.zsh_secrets found"
      fi

      # Reload local secrets (temporary/testing overrides)
      if [ -f ~/.zsh_secrets.local ]; then
        source ~/.zsh_secrets.local
        echo "✅ Reloaded ~/.zsh_secrets.local (overrides)"
        files+=("~/.zsh_secrets.local")
        ((count++))
      fi

      if [ $count -eq 0 ]; then
        echo ""
        echo "❌ No secret files found"
        echo ""
        echo "💡 Create secrets:"
        echo "   - Permanent: edit-secrets (SOPS-encrypted)"
        echo "   - Testing: secrets-local edit (temporary)"
        return 1
      fi

      echo ""
      echo "📊 Summary:"
      echo "   • Reloaded: $count file(s)"
      echo "   • Scope: Current shell only"
      echo ""
      echo "💡 For permanent changes: edit-secrets + nix-rebuild"
    }

    # Aliases for convenience
    alias secrets-reload='reload-secrets'
    alias reload-env='reload-secrets'
  '';

  # ==================================================
  # LOCAL SECRETS HELPER
  # ==================================================
  # Helper to create and manage ~/.zsh_secrets.local for testing
  # Local secrets override SOPS-managed secrets temporarily
  #
  mkLocalSecretsHelper = ''
    function secrets-local() {
      local action="''${1:-help}"

      case "$action" in
        edit|e)
          echo "✏️  Opening ~/.zsh_secrets.local for editing..."
          echo ""

          # Create file with template if it doesn't exist
          if [ ! -f ~/.zsh_secrets.local ]; then
            cat > ~/.zsh_secrets.local <<'EOF'
# Local Secrets - Temporary Testing Overrides
# This file is gitignored and not managed by Nix
# Use for testing credentials without touching encrypted secrets
#
# Example:
# export OPENAI_API_KEY="sk-test-..."
# export AWS_ACCESS_KEY_ID="AKIA..."
# export DATABASE_PASSWORD="test-password"
#
# When done testing: secrets-local rm

EOF
            echo "📝 Created ~/.zsh_secrets.local with template"
          fi

          ''${EDITOR:-vim} ~/.zsh_secrets.local
          echo ""
          echo "💡 Run: reload-secrets (to apply changes)"
          ;;

        show|s|cat)
          if [ -f ~/.zsh_secrets.local ]; then
            echo "📄 ~/.zsh_secrets.local contents:"
            echo ""
            cat ~/.zsh_secrets.local
          else
            echo "❌ No ~/.zsh_secrets.local found"
            echo ""
            echo "💡 Create with: secrets-local edit"
          fi
          ;;

        delete|rm|remove)
          if [ -f ~/.zsh_secrets.local ]; then
            rm ~/.zsh_secrets.local
            echo "✅ Deleted ~/.zsh_secrets.local"
            echo ""
            echo "💡 Run: reload-secrets (to clear overrides)"
          else
            echo "❌ No ~/.zsh_secrets.local found"
          fi
          ;;

        path|location)
          if [ -f ~/.zsh_secrets.local ]; then
            echo "📍 ~/.zsh_secrets.local exists"
            ls -lh ~/.zsh_secrets.local
          else
            echo "❌ ~/.zsh_secrets.local not found"
          fi
          ;;

        help|h|"")
          echo "Usage: secrets-local <action>"
          echo ""
          echo "Actions:"
          echo "  edit (e)     - Edit ~/.zsh_secrets.local"
          echo "  show (s)     - Show contents"
          echo "  delete (rm)  - Delete local secrets"
          echo "  path         - Show file location"
          echo "  help (h)     - Show this help"
          echo ""
          echo "Purpose:"
          echo "  ~/.zsh_secrets.local is for temporary testing"
          echo "  • Overrides values from ~/.zsh_secrets"
          echo "  • Gitignored and not managed by Nix"
          echo "  • Perfect for testing API keys/credentials"
          echo ""
          echo "Files:"
          echo "  ~/.zsh_secrets        - SOPS-managed (permanent)"
          echo "  ~/.zsh_secrets.local  - Local testing (temporary)"
          echo ""
          echo "Workflow:"
          echo "  1. secrets-local edit      # Create test credentials"
          echo "  2. reload-secrets          # Apply to current shell"
          echo "  3. Test your changes"
          echo "  4. secrets-local rm        # Clean up when done"
          echo ""
          echo "Examples:"
          echo "  secrets-local edit         # Open in \$EDITOR"
          echo "  secrets-local show         # View contents"
          echo "  secrets-local rm           # Remove file"
          ;;

        *)
          echo "❌ Unknown action: $action"
          echo ""
          echo "💡 Run: secrets-local help"
          return 1
          ;;
      esac
    }

    # Shorter alias
    alias sec='secrets-local'
  '';

  # ==================================================
  # GENERATE ALL HOT RELOAD FUNCTIONS
  # ==================================================
  # Combine all hot reload helpers into single export
  #
  mkAllHotReloadFunctions =
    mkSecretsReload + "\n\n" +
    mkLocalSecretsHelper;
}
