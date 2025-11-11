# Warning System for Risky Operations
#
# Purpose: Provide reusable warning and confirmation functions for high-risk operations
# Usage: Import in lib/default.nix and use in shell configurations
#
# Design Philosophy:
# - Three warning levels: INFO, WARNING, CRITICAL
# - Visual feedback with colors and emojis
# - Confirmation prompts for destructive operations
# - Consistent messaging across the system

{ lib }:

rec {
  # ============================================
  # WARNING LEVELS
  # ============================================

  warningLevels = {
    INFO = {
      emoji = "ℹ️";
      color = "blue";
      prefix = "INFO";
    };
    WARNING = {
      emoji = "⚠️";
      color = "yellow";
      prefix = "WARNING";
    };
    CRITICAL = {
      emoji = "🚨";
      color = "red";
      prefix = "CRITICAL";
    };
  };

  # ============================================
  # MESSAGE GENERATORS
  # ============================================

  # Generate warning message with appropriate level
  # Usage: mkWarningMessage "WARNING" "This will delete files"
  mkWarningMessage = level: message:
    let
      levelData = warningLevels.${level};
    in ''
      echo "${levelData.emoji} ${levelData.prefix}: ${message}"
    '';

  # Generate multi-line warning with details
  # Usage: mkDetailedWarning "CRITICAL" "Cleanup" ["Will delete caches", "Will remove build artifacts"]
  mkDetailedWarning = level: title: details:
    let
      levelData = warningLevels.${level};
      detailLines = lib.concatMapStringsSep "\n" (d: "  • ${d}") details;
    in ''
      echo ""
      echo "${levelData.emoji} ${levelData.prefix}: ${title}"
      ${detailLines}
      echo ""
    '';

  # ============================================
  # CONFIRMATION PROMPTS
  # ============================================

  # Generate confirmation prompt
  # Usage: mkConfirmPrompt "Continue with rebuild?"
  mkConfirmPrompt = question:
    ''
      read -q "REPLY?${question} (y/N) "
      echo ""
      [[ "$REPLY" =~ ^[Yy]$ ]]
    '';

  # Generate confirmation with default yes
  # Usage: mkConfirmPromptDefaultYes "Apply changes?"
  mkConfirmPromptDefaultYes = question:
    ''
      read -q "REPLY?${question} (Y/n) "
      echo ""
      [[ ! "$REPLY" =~ ^[Nn]$ ]]
    '';

  # Generate timeout confirmation (auto-proceed after N seconds)
  # Usage: mkTimedConfirm 10 "Continue?"
  mkTimedConfirm = seconds: question:
    ''
      read -t ${toString seconds} -q "REPLY?${question} (y/N, auto-proceed in ${toString seconds}s) " || true
      echo ""
      [[ "$REPLY" =~ ^[Yy]$ ]] || [ -z "$REPLY" ]
    '';

  # ============================================
  # RISKY OPERATION WRAPPERS
  # ============================================

  # Wrap command with warning and confirmation
  # Usage: mkRiskyOperation {
  #   level = "WARNING";
  #   message = "This will rebuild your system";
  #   details = ["Nix packages will be updated", "System may restart"];
  #   command = "darwin-rebuild switch";
  # }
  mkRiskyOperation = { level, message, details ? [], command, skipFlag ? null }:
    let
      warningMsg = if details == []
        then mkWarningMessage level message
        else mkDetailedWarning level message details;

      skipCheck = if skipFlag != null
        then ''
          # Check for skip flag
          local skip_confirmation=false
          for arg in "$@"; do
            if [[ "$arg" == "${skipFlag}" ]]; then
              skip_confirmation=true
              break
            fi
          done
        ''
        else "local skip_confirmation=false";
    in ''
      ${skipCheck}

      if [ "$skip_confirmation" = false ]; then
        ${warningMsg}
        if ${mkConfirmPrompt "Do you want to proceed?"}; then
          ${command}
        else
          echo "❌ Operation cancelled"
          return 1
        fi
      else
        ${command}
      fi
    '';

  # Wrap command with critical warning requiring explicit confirmation
  # Usage: mkCriticalOperation {
  #   message = "DESTRUCTIVE OPERATION";
  #   warningText = "This will permanently delete data";
  #   confirmText = "Type 'yes' to confirm";
  #   command = "rm -rf /path";
  # }
  mkCriticalOperation = { message, warningText, confirmText ? "yes", command }:
    ''
      echo ""
      echo "🚨 ${message}"
      echo "⚠️  ${warningText}"
      echo ""
      read -r "confirmation?Type '${confirmText}' to confirm: "

      if [[ "$confirmation" == "${confirmText}" ]]; then
        ${command}
      else
        echo "❌ Operation cancelled (incorrect confirmation)"
        return 1
      fi
    '';

  # ============================================
  # PRE-FLIGHT CHECKS
  # ============================================

  # Generate pre-flight check wrapper
  # Usage: mkPreFlightCheck {
  #   name = "Git Status";
  #   check = "git diff --quiet";
  #   failureMessage = "Uncommitted changes detected";
  #   level = "WARNING";
  #   continueOnFailure = true;
  # }
  mkPreFlightCheck = { name, check, failureMessage, level ? "WARNING", continueOnFailure ? true }:
    let
      levelData = warningLevels.${level};
    in ''
      echo "🔍 Pre-flight check: ${name}..."
      if ! ${check}; then
        echo "${levelData.emoji} ${failureMessage}"
        ${if continueOnFailure then ''
          if ! ${mkConfirmPrompt "Continue anyway?"}; then
            echo "❌ Operation cancelled"
            return 1
          fi
        '' else ''
          echo "❌ Pre-flight check failed - aborting"
          return 1
        ''}
      else
        echo "  ✅ ${name} passed"
      fi
    '';

  # Generate multiple pre-flight checks
  # Usage: mkPreFlightChecks [
  #   { name = "Check 1"; check = "test -f file"; failureMessage = "File missing"; }
  #   { name = "Check 2"; check = "command -v tool"; failureMessage = "Tool not found"; }
  # ]
  mkPreFlightChecks = checks:
    lib.concatMapStringsSep "\n" (c:
      mkPreFlightCheck {
        name = c.name;
        check = c.check;
        failureMessage = c.failureMessage;
        level = c.level or "WARNING";
        continueOnFailure = c.continueOnFailure or true;
      }
    ) checks;

  # ============================================
  # SPECIALIZED WARNING FUNCTIONS
  # ============================================

  # Warning for Nix rebuild operations
  mkNixRebuildWarning = { showDiff ? false }:
    mkRiskyOperation {
      level = "WARNING";
      message = "System Rebuild";
      details = [
        "This will rebuild your entire system configuration"
        "Changes will be applied immediately"
        "Previous generation will be available for rollback"
      ] ++ lib.optional showDiff "Run 'nix-diff' to see changes first";
      command = "darwin-rebuild switch --flake ~/nix-darwin";
      skipFlag = "--yes";
    };

  # Warning for aggressive cleanup operations
  mkCleanupWarning = { cleanupType ? "standard" }:
    let
      criticalWarning = cleanupType == "aggressive";
      details = if criticalWarning then [
        "⚠️  DESTRUCTIVE OPERATION"
        "Will delete Nix store, build caches, and old generations"
        "Cannot be undone"
        "System may need to download packages again"
      ] else [
        "Will clean caches and old generations"
        "Safe operation - can rebuild if needed"
      ];
    in
    if criticalWarning then
      mkCriticalOperation {
        message = "AGGRESSIVE CLEANUP";
        warningText = lib.concatStringsSep "\n" details;
        confirmText = "DELETE";
        command = ""; # Command will be filled by caller
      }
    else
      mkRiskyOperation {
        level = "WARNING";
        message = "Cleanup Operation";
        details = details;
        command = ""; # Command will be filled by caller
      };

  # Warning for secrets editing
  mkSecretsWarning =
    mkRiskyOperation {
      level = "INFO";
      message = "Editing Encrypted Secrets";
      details = [
        "File will be decrypted temporarily"
        "Changes will be re-encrypted on save"
        "Make sure SOPS keys are configured correctly"
      ];
      command = ""; # Command will be filled by caller
    };

  # Warning for Git force operations
  mkGitForceWarning = { operation ? "push" }:
    mkCriticalOperation {
      message = "GIT FORCE ${lib.toUpper operation}";
      warningText = "This can overwrite remote history and cause data loss for collaborators";
      confirmText = "FORCE";
      command = ""; # Command will be filled by caller
    };

  # ============================================
  # SHELL HELPER FUNCTIONS
  # ============================================

  # Generate shell helper functions for warnings
  # These can be used in zsh.nix initExtra
  mkWarningHelpers = ''
    # Display warning message
    # Usage: warn "MESSAGE" [LEVEL]
    function warn() {
      local message="$1"
      local level="''${2:-WARNING}"

      case "$level" in
        INFO)
          echo "ℹ️  INFO: $message"
          ;;
        WARNING)
          echo "⚠️  WARNING: $message"
          ;;
        CRITICAL)
          echo "🚨 CRITICAL: $message"
          ;;
        *)
          echo "⚠️  $message"
          ;;
      esac
    }

    # Confirm action with user
    # Usage: confirm "Question?" && command
    function confirm() {
      local question="$1"
      read -q "REPLY?$question (y/N) "
      echo ""
      [[ "$REPLY" =~ ^[Yy]$ ]]
    }

    # Wrap risky command with confirmation
    # Usage: risky "WARNING" "This is dangerous" "rm -rf /"
    function risky() {
      local level="$1"
      local message="$2"
      shift 2

      warn "$message" "$level"
      if confirm "Proceed?"; then
        "$@"
      else
        echo "❌ Operation cancelled"
        return 1
      fi
    }

    # Critical operation requiring explicit confirmation
    # Usage: critical "DELETE" "This will delete everything" "rm -rf /"
    function critical() {
      local confirm_text="$1"
      local message="$2"
      shift 2

      echo ""
      echo "🚨 CRITICAL OPERATION"
      echo "⚠️  $message"
      echo ""
      read -r "confirmation?Type '$confirm_text' to confirm: "

      if [[ "$confirmation" == "$confirm_text" ]]; then
        "$@"
      else
        echo "❌ Operation cancelled (incorrect confirmation)"
        return 1
      fi
    }
  '';
}
