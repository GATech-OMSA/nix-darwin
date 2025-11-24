# Helper Functions and Utilities
#
# Purpose: Reusable Nix functions for configuration management
# Usage: Import in flake.nix and use across your configuration

{ inputs }:

let
  inherit (inputs.nixpkgs) lib;

  # Import machine detection helpers
  machineDetection = import ./machine-detection.nix { inherit lib; };
in
rec {
  # ============================================
  # MACHINE TYPE HELPERS
  # ============================================
  # Re-export machine detection functions for compatibility
  # These now use the flexible machine detection system from machine-detection.nix

  # NEW API: Direct machineType functions (PREFERRED)
  # Check if machine type is personal
  isPersonalType = machineDetection.isPersonalType;

  # Check if machine type is work
  isWorkType = machineDetection.isWorkType;

  # Select value based on machine type (direct)
  # Usage: selectByMachineType machineType { personal = "X"; work = "Y"; }
  selectByMachineType = machineDetection.selectByMachineType;

  # DEPRECATED API: Hostname-based functions (for backward compatibility)
  # Determine machine type from hostname
  # Returns: "personal" | "work" | "unknown"
  # Now uses hosts/machines.nix mapping with local override support
  machineType = machineDetection.getMachineType;

  # DEPRECATED: Check if machine is personal
  # Use isPersonalType instead
  isPersonal = machineDetection.isPersonal;

  # DEPRECATED: Check if machine is work
  # Use isWorkType instead
  isWork = machineDetection.isWork;

  # DEPRECATED: Validate machine is recognized (throws error if unknown)
  requireKnownMachine = machineDetection.requireKnownMachine;

  # DEPRECATED: Select value based on machine type
  # Use selectByMachineType instead
  # Usage: selectByMachine hostname { personal = "X"; work = "Y"; default = "Z"; }
  selectByMachine = machineDetection.selectByMachine;

  # Conditional import based on predicate
  # Usage: importIf isPersonal hostname ./personal.nix
  importIf = pred: hostname: path:
    if pred hostname then [ path ] else [];

  # Import file only for personal machines
  importIfPersonal = hostname: importIf isPersonal hostname;

  # Import file only for work machines
  importIfWork = hostname: importIf isWork hostname;

  # ============================================
  # SHELL FUNCTION GENERATORS
  # ============================================

  # Generate update function with consistent error handling
  # Usage: mkUpdateFunction { name = "update-nix"; command = "nix flake update"; description = "Updating Nix flake"; }
  mkUpdateFunction = { name, command, description }:
    ''
      function ${name}() {
        echo "🔄 ${description}..."
        local errors=0

        if ${command}; then
          echo "  ✅ ${name} completed"
        else
          echo "  ❌ ${name} failed" >&2
          ((errors++))
        fi

        return $errors
      }
    '';

  # ============================================
  # ENVIRONMENT VARIABLE HELPERS
  # ============================================

  # Create environment variable set (ensures all values are strings)
  mkEnvVars = vars:
    builtins.mapAttrs (name: value: toString value) vars;

  # Merge multiple env var sets (later sets override earlier ones)
  mergeEnvVars = sets:
    lib.foldl' (acc: set: acc // set) {} sets;

  # ============================================
  # CONFIGURATION HELPERS
  # ============================================

  # Merge multiple configurations
  mergeConfigs = configs:
    lib.foldl' (acc: cfg: acc // cfg) {} configs;

  # Create Starship preset configuration
  # Usage: mkStarshipPreset "catppuccin-powerline" pkgs
  mkStarshipPreset = preset: pkgs:
    pkgs.runCommand "starship-${preset}" {} ''
      ${pkgs.starship}/bin/starship preset ${preset} -o $out
    '';

  # ============================================
  # NAVIGATION ALIASES
  # ============================================

  # Create navigation aliases for directory shortcuts
  # Usage: mkNavigationAliases "$HOME/Dev" { learning = "learning"; aiml = "ai-ml"; }
  # Results in: { learning = "cd $HOME/Dev/learning"; aiml = "cd $HOME/Dev/ai-ml"; }
  mkNavigationAliases = baseDir: dirs:
    lib.mapAttrs' (name: path:
      lib.nameValuePair name "cd ${baseDir}/${path}"
    ) dirs;

  # ============================================
  # STATUS MESSAGES
  # ============================================

  # Consistent status message helpers for shell scripts
  msg = {
    success = msg: ''echo "✅ ${msg}"'';
    error = msg: ''echo "❌ ${msg}" >&2'';
    warning = msg: ''echo "⚠️  ${msg}"'';
    info = msg: ''echo "ℹ️  ${msg}"'';
    loading = msg: ''echo "🔄 ${msg}..."'';
    rocket = msg: ''echo "🚀 ${msg}"'';
    package = msg: ''echo "📦 ${msg}"'';
    pin = msg: ''echo "📍 ${msg}"'';
  };

  # ============================================
  # COMMAND HELPERS
  # ============================================

  # Check if command exists and execute conditional code
  # Usage: mkCommandCheck { command = "docker"; onSuccess = "docker ps"; onFailure = "echo not found"; }
  mkCommandCheck = { command, onSuccess, onFailure ? null }:
    ''
      if command -v ${command} &> /dev/null; then
        ${onSuccess}
      ${lib.optionalString (onFailure != null) ''
      else
        ${onFailure}
      ''}
      fi
    '';

  # Generate function with argument validation
  # Usage: mkFunctionWithArgs {
  #   name = "myfunction";
  #   requiredArgs = 1;
  #   usage = "<argument>";
  #   body = "echo $1";
  # }
  mkFunctionWithArgs = { name, requiredArgs ? 1, usage, body }:
    let
      argChecks = lib.concatMapStringsSep "\n" (n: ''
        if [ -z "$${toString n}" ]; then
          echo "Usage: ${name} ${usage}"
          return 1
        fi
      '') (lib.range 1 requiredArgs);
    in ''
      function ${name}() {
        ${argChecks}
        ${body}
      }
    '';

  # ============================================
  # PACKAGE MANAGEMENT
  # ============================================

  # Create conditional package groups
  # Usage: mkConditionalPackages { condition = true; packages = [ pkgs.git pkgs.vim ]; }
  mkConditionalPackages = { condition, packages }:
    if condition then packages else [];

  # Create multiple package groups with enable/disable flags
  # Usage: mkPackageGroups {
  #   infrastructure = { enabled = false; packages = [ "terraform" "tflint" ]; };
  #   dataTools = { enabled = true; packages = [ "sqlite" "postgresql" ]; };
  # } pkgs
  mkPackageGroups = groups: pkgs:
    lib.flatten (lib.mapAttrsToList (name: spec:
      mkConditionalPackages {
        condition = spec.enabled or true;
        packages = map (p: pkgs.${p}) spec.packages;
      }
    ) groups);

  # ============================================
  # FILE HELPERS
  # ============================================

  # Source file if it exists
  # Usage: mkSourceIfExists "/path/to/file.sh"
  mkSourceIfExists = file: ''
    [ -f ${file} ] && source ${file}
  '';

  # Source multiple files if they exist
  # Usage: mkSourcePlugins [ { path = "~/.plugin1"; } { path = "~/.plugin2"; } ]
  mkSourcePlugins = plugins:
    lib.concatMapStringsSep "\n" (p: mkSourceIfExists p.path) plugins;


  # ============================================
  # DATABASE & CREDENTIAL HELPERS
  # ============================================

  # Import database helper library
  # Provides: mkDatabaseConnector, mkDatabaseConnectors, mkDatabaseList, mkTokenHelper, mkTokenHelpers
  database = import ./database-helpers.nix { inherit lib; };

  # ============================================
  # AWS HELPERS
  # ============================================

  # Import AWS helper library
  # Provides: mkAwsProfileAliases, mkAwsProjectAliases, mkAwsProfileAliasesWithPrefix
  aws = import ./aws-helpers.nix { inherit lib; };

  # ============================================
  # MIXIN HELPERS
  # ============================================

  # Import mixin helper library
  # Provides: mkMixin, mkConditionalMixinComponents, mergeMixins
  mixin = import ./mixin-helpers.nix { inherit lib; };

  # ============================================
  # SECRETS REGISTRY
  # ============================================

  # Import secrets registry
  # Single source of truth for all credential and secret file locations
  # Provides: secretPaths, secretsByType, secretGlobPatterns, helpers, stats, meta
  secrets = import ./secrets-registry.nix { inherit lib; };

  # ============================================
  # WARNING SYSTEM
  # ============================================

  # Import warning system
  # Provides confirmation prompts and warning messages for risky operations
  # Functions: mkWarningMessage, mkConfirmPrompt, mkRiskyOperation, mkCriticalOperation,
  #            mkPreFlightCheck, mkNixRebuildWarning, mkCleanupWarning, mkSecretsWarning,
  #            mkGitForceWarning, mkWarningHelpers
  warnings = import ./warnings.nix { inherit lib; };
}
