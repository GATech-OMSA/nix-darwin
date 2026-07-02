# reload-helpers.nix
#
# Hot reload functions for quick configuration updates without full rebuild
# Provides instant feedback for testing secrets and environment variables

{ lib }:

rec {
  # ==================================================
  # SHARED LOCAL FILE HELPERS
  # ==================================================

  mkLocalFileHelpers = ''
    function __local_file_upsert_prefix() {
      local file="$1"
      local prefix="$2"
      local replacement="$3"
      local tmp_file

      tmp_file=$(mktemp)
      awk -v prefix="$prefix" -v replacement="$replacement" '
        BEGIN { replaced = 0 }
        substr($0, 1, length(prefix)) == prefix {
          if (!replaced) {
            print replacement
            replaced = 1
          }
          next
        }
        { print }
        END {
          if (!replaced) {
            print replacement
          }
        }
      ' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
    }

    function __local_file_remove_prefix() {
      local file="$1"
      local prefix="$2"
      local tmp_file

      tmp_file=$(mktemp)
      awk -v prefix="$prefix" '
        substr($0, 1, length(prefix)) != prefix { print }
      ' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
    }
  '';

  # ==================================================
  # SECRETS HOT RELOAD (private helper)
  # ==================================================
  # Re-source ~/.zsh_secrets and ~/.zsh_secrets.local into the CURRENT shell
  # process without a full respin. Used internally by `secrets-local add/unset`
  # so a new test value is available immediately. Not exposed as a public
  # command — for a full environment refresh (zshenv/zshrc/secrets/local
  # overrides all at once), use `respin` (alias in zsh.nix, = `exec zsh`;
  # both files are auto-sourced by zshrc on every init, see SOURCE SECRETS).
  #
  # Files:
  #   ~/.zsh_secrets       - SOPS-managed secrets (edit with: edit-secrets)
  #   ~/.zsh_secrets.local - Local testing overrides (gitignored, temporary)
  #
  # Workflow:
  #   1. secrets-local edit       # Create temporary test credentials
  #   2. respin                   # Apply to current shell (full refresh)
  #   3. Test your changes
  #   4. secrets-local rm         # Clean up when done
  #
  mkSecretsReload = ''
    function __reload_secret_files() {
      echo "Reloading secrets..."
      echo ""

      local count=0
      local files=()

      # Reload main secrets (SOPS-managed)
      if [ -f ~/.zsh_secrets ]; then
        if source ~/.zsh_secrets 2>/dev/null; then
          echo "Reloaded ~/.zsh_secrets"
          files+=("~/.zsh_secrets")
          count=$(( count + 1 ))
        else
          echo "error: failed to source ~/.zsh_secrets (syntax error?)"
        fi
      else
        echo "warning: no ~/.zsh_secrets found"
      fi

      # Reload local secrets (temporary/testing overrides)
      if [ -f ~/.zsh_secrets.local ]; then
        if source ~/.zsh_secrets.local 2>/dev/null; then
          echo "Reloaded ~/.zsh_secrets.local (overrides)"
          files+=("~/.zsh_secrets.local")
          count=$(( count + 1 ))
        else
          echo "error: failed to source ~/.zsh_secrets.local (syntax error?)"
        fi
      fi

      if [ $count -eq 0 ]; then
        echo ""
        echo "error: no secret files found"
        echo ""
        echo "   Create secrets:"
        echo "   - Permanent: edit-secrets (SOPS-encrypted)"
        echo "   - Testing: secrets-local edit (temporary)"
        return 1
      fi

      echo ""
      echo "Summary:"
      echo "   • Reloaded: $count file(s)"
      echo "   • Scope: Current shell only"
      echo ""
      echo "   For permanent changes: edit-secrets + nix-rebuild"
    }
  '';

  # ==================================================
  # LOCAL SECRETS HELPER
  # ==================================================
  # Helper to create and manage ~/.zsh_secrets.local for testing
  # Local secrets override SOPS-managed secrets temporarily
  #
  mkLocalSecretsHelper = ''
    function __ensure_local_secrets_file() {
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
        chmod 600 ~/.zsh_secrets.local 2>/dev/null || true
        echo "Created ~/.zsh_secrets.local with template"
      fi
    }

    function secrets-local() {
      local action="''${1:-help}"

      case "$action" in
        edit|e)
          echo "Opening ~/.zsh_secrets.local for editing..."
          echo ""

          __ensure_local_secrets_file

          ''${EDITOR:-vim} ~/.zsh_secrets.local
          echo ""
          echo "   Run: respin (to apply changes)"
          ;;

        set|add)
          local key="''${2:-}"
          shift 2
          local value="$*"

          if [[ -z "$key" || -z "$value" ]]; then
            echo "Usage: secrets-local add <ENV_VAR> <value>"
            return 1
          fi

          if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            echo "error: invalid environment variable name: $key"
            return 1
          fi

          __ensure_local_secrets_file

          local escaped_value="''${value//\'/\'\\\'\'}"
          local prefix="export $key="
          local line="export $key='$escaped_value'"

          __local_file_upsert_prefix ~/.zsh_secrets.local "$prefix" "$line"
          chmod 600 ~/.zsh_secrets.local 2>/dev/null || true
          export "$key=$value"
          __reload_secret_files >/dev/null 2>&1 || true

          echo "Saved and reloaded: $key"
          echo "   File: ~/.zsh_secrets.local"
          ;;

        unset|rm-key|delete-key|remove-key)
          local key="''${2:-}"

          if [[ -z "$key" ]]; then
            echo "Usage: secrets-local unset <ENV_VAR>"
            return 1
          fi

          if [ ! -f ~/.zsh_secrets.local ]; then
            echo "error: no ~/.zsh_secrets.local found"
            return 1
          fi

          __local_file_remove_prefix ~/.zsh_secrets.local "export $key="
          unset "$key" 2>/dev/null || true
          __reload_secret_files >/dev/null 2>&1 || true

          echo "Removed and reloaded: $key"
          ;;

        show|s|cat)
          if [ -f ~/.zsh_secrets.local ]; then
            echo "~/.zsh_secrets.local contents:"
            echo ""
            cat ~/.zsh_secrets.local
          else
            echo "error: no ~/.zsh_secrets.local found"
            echo ""
            echo "   Create with: secrets-local edit"
          fi
          ;;

        delete|rm|remove)
          if [ -f ~/.zsh_secrets.local ]; then
            /bin/rm ~/.zsh_secrets.local
            echo "Deleted ~/.zsh_secrets.local"
            echo ""
            echo "   Run: respin (to clear overrides)"
          else
            echo "error: no ~/.zsh_secrets.local found"
          fi
          ;;

        path|location)
          if [ -f ~/.zsh_secrets.local ]; then
            echo "~/.zsh_secrets.local exists"
            ls -lh ~/.zsh_secrets.local
          else
            echo "error: ~/.zsh_secrets.local not found"
          fi
          ;;

        help|h|"")
          echo "Usage: secrets-local <action>"
          echo ""
          echo "Actions:"
          echo "  edit (e)     - Edit ~/.zsh_secrets.local"
          echo "  add          - Add or update ENV var and export it now"
          echo "  unset        - Remove ENV var and unset it now"
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
          echo "  2. respin                  # Apply to current shell"
          echo "  3. Test your changes"
          echo "  4. secrets-local rm        # Clean up when done"
          echo ""
          echo "Examples:"
          echo "  secrets-local edit         # Open in \$EDITOR"
          echo "  secrets-local add FOO bar  # Persist + export now"
          echo "  secrets-local unset FOO    # Remove local override"
          echo "  secrets-local show         # View contents"
          echo "  secrets-local rm           # Remove file"
          ;;

        *)
          echo "error: unknown action: $action"
          echo ""
          echo "   Run: secrets-local help"
          return 1
          ;;
      esac
    }

    # Shorter alias
    alias sec='secrets-local'
  '';

  # ==================================================
  # LOCAL ZSHRC HELPER
  # ==================================================
  # Helper to manage ~/.zshrc.local for aliases and local overrides
  #
  mkLocalZshrcHelper = ''
    function __ensure_zshrc_local() {
      if [ ! -f ~/.zshrc.local ]; then
        cat > ~/.zshrc.local <<'EOF'
# ~/.zshrc.local
# Local shell overrides — not managed by Nix, no rebuild needed.

# Claude Code aliases
alias cc='claude'
alias ccr='claude --resume'
alias ccc='claude --continue'
alias cca='claude --add-dir'

# --dangerously-skip-permissions variants are intentionally NOT seeded.
# A typo (cc! vs cc) silently runs Claude with all guardrails off, including
# permission prompts for shell exec and file writes. If you want them, add
# the three-line block below to ~/.zshrc.local manually:
#   alias 'cc!'='claude --dangerously-skip-permissions'
#   alias 'ccr!'='claude --dangerously-skip-permissions --resume'
#   alias 'ccc!'='claude --dangerously-skip-permissions --continue'

# Variants
alias ccw='claude -w'
alias ccwt='claude -w --tmux'
alias ccq='claude --bare -p'
alias ccs='claude --model sonnet'
alias ccm='claude --effort max'

# Config shortcuts
alias ccconfig='code ~/.claude/settings.json'
alias awsconfig='code ~/.aws/config'
alias zshrc='code ~/.zshrc'
alias zshrclocal='code ~/.zshrc.local'
alias zshenv='code ~/.zshenv'
alias zshenvlocal='code ~/.zshenv.local'
alias zshsecrets='code ~/.zsh_secrets'
alias sshconf='code ~/.ssh/config'
alias zprofile='code ~/.zprofile'

EOF
        chmod 600 ~/.zshrc.local 2>/dev/null || true
        echo "Created ~/.zshrc.local with template"
      fi
    }

    function zsh-local() {
      local action="''${1:-help}"

      case "$action" in
        edit|e)
          __ensure_zshrc_local
          ''${EDITOR:-vim} ~/.zshrc.local
          ;;

        show|s|cat)
          if [ -f ~/.zshrc.local ]; then
            cat ~/.zshrc.local
          else
            echo "error: no ~/.zshrc.local found"
            echo ""
            echo "   Create with: zsh-local edit"
          fi
          ;;

        reload|r)
          if [ -f ~/.zshrc.local ]; then
            if source ~/.zshrc.local 2>/dev/null; then
              echo "Reloaded ~/.zshrc.local"
            else
              echo "error: failed to source ~/.zshrc.local (syntax error?)"
              return 1
            fi
          else
            echo "error: no ~/.zshrc.local found"
            return 1
          fi
          ;;

        alias)
          local subaction="''${2:-help}"

          case "$subaction" in
            add|set)
              local name="''${3:-}"
              shift 3
              local value="$*"

              if [[ -z "$name" || -z "$value" ]]; then
                echo "Usage: zsh-local alias add <name> <command>"
                return 1
              fi

              if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_!%+.-]*$ ]]; then
                echo "error: invalid alias name: $name"
                return 1
              fi

              __ensure_zshrc_local

              local escaped_value="''${value//\'/\'\\\'\'}"
              local prefix="alias $name="
              local line="alias $name='$escaped_value'"

              __local_file_upsert_prefix ~/.zshrc.local "$prefix" "$line"
              chmod 600 ~/.zshrc.local 2>/dev/null || true
              alias "$name=$value"

              echo "Saved and loaded alias: $name"
              echo "   Command: $value"
              ;;

            rm|remove|delete|unset)
              local name="''${3:-}"

              if [[ -z "$name" ]]; then
                echo "Usage: zsh-local alias rm <name>"
                return 1
              fi

              if [ ! -f ~/.zshrc.local ]; then
                echo "error: no ~/.zshrc.local found"
                return 1
              fi

              __local_file_remove_prefix ~/.zshrc.local "alias $name="
              unalias "$name" 2>/dev/null || true

              echo "Removed alias: $name"
              ;;

            show)
              if [ -f ~/.zshrc.local ]; then
                grep '^alias ' ~/.zshrc.local || true
              else
                echo "error: no ~/.zshrc.local found"
                return 1
              fi
              ;;

            *)
              echo "Usage: zsh-local alias <add|rm|show> ..."
              echo ""
              echo "Examples:"
              echo "  zsh-local alias add cc claude"
              echo "  zsh-local alias add ccr 'claude --resume'"
              echo "  zsh-local alias rm cc"
              echo "  zsh-local alias show"
              return 1
              ;;
          esac
          ;;

        help|h|"")
          echo "Usage: zsh-local <action>"
          echo ""
          echo "Actions:"
          echo "  edit            - Open ~/.zshrc.local"
          echo "  show            - Show ~/.zshrc.local"
          echo "  reload          - Source ~/.zshrc.local now"
          echo "  alias add       - Add or update alias and load it now"
          echo "  alias rm        - Remove alias from file and current shell"
          echo "  alias show      - Show aliases stored in ~/.zshrc.local"
          echo ""
          echo "Examples:"
          echo "  zsh-local alias add cc claude"
          echo "  zsh-local alias add ccr 'claude --resume'"
          echo "  zsh-local alias rm cc"
          echo "  zsh-local reload"
          ;;

        *)
          echo "error: unknown action: $action"
          echo ""
          echo "   Run: zsh-local help"
          return 1
          ;;
      esac
    }

    alias zlocal='zsh-local'
  '';

  # ==================================================
  # GENERATE ALL HOT RELOAD FUNCTIONS
  # ==================================================
  # Combine all hot reload helpers into single export
  #
  mkAllHotReloadFunctions =
    mkLocalFileHelpers + "\n\n" +
    mkSecretsReload + "\n\n" +
    mkLocalSecretsHelper + "\n\n" +
    mkLocalZshrcHelper;
}
