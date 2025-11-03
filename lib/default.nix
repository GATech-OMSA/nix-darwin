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
  # MACHINE TYPE HELPERS
  # ============================================

  # Determine machine type from hostname
  # Returns: "personal" | "work" | "unknown"
  machineType = hostname:
    if hostname == "mbp-jimmy" then "personal"
    else if hostname == "mbp-work" then "work"
    else "unknown";

  # Check if machine is personal
  isPersonal = hostname: (machineType hostname) == "personal";

  # Check if machine is work
  isWork = hostname: (machineType hostname) == "work";

  # Select value based on machine type
  # Usage: selectByMachine hostname { personal = "X"; work = "Y"; default = "Z"; }
  selectByMachine = hostname: values:
    let
      type = machineType hostname;
      hasDefault = values ? default;
    in
      if values ? ${type} then values.${type}
      else if hasDefault then values.default
      else throw "No value for machine type '${type}' and no default provided";

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

  # Generate multiple update functions at once
  # Usage: mkUpdateFunctions [ { name = ".."; command = ".."; description = ".." } ... ]
  mkUpdateFunctions = functions:
    lib.concatMapStringsSep "\n\n" mkUpdateFunction functions;

  # Generate scaffold/project creation function
  # Usage: mkScaffoldFunction {
  #   name = "newproject";
  #   baseDir = "$HOME/Dev";
  #   description = "Create new project";
  #   template = "touch README.md && git init";
  # }
  mkScaffoldFunction = { name, baseDir, description, template }:
    ''
      function ${name}() {
        if [ -z "$1" ]; then
          echo "Usage: ${name} <project-name>"
          return 1
        fi

        local project_name="$1"
        local project_dir="${baseDir}/$project_name"

        if [ -d "$project_dir" ]; then
          echo "❌ Project '$project_name' already exists at $project_dir"
          return 1
        fi

        echo "📦 ${description}: $project_name"
        mkdir -p "$project_dir"
        cd "$project_dir"

        ${template}

        echo "✅ ${description} created: $project_name"
        echo "📍 Location: $project_dir"

        if command -v code &> /dev/null; then
          code .
        fi
      }
    '';

  # Generate multiple scaffold functions
  mkScaffoldFunctions = functions:
    lib.concatMapStringsSep "\n\n" mkScaffoldFunction functions;

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
  # ENVIRONMENT MANAGEMENT
  # ============================================

  # Generate environment manager function (for conda, venv, etc.)
  # Usage: mkEnvManagerFunction {
  #   tool = "micromamba";
  #   name = "activate-env";
  #   action = "activate";
  #   listCommand = "micromamba env list";
  # }
  mkEnvManagerFunction = { tool, name, action, listCommand ? null }:
    ''
      function ${name}() {
        if [ -z "$1" ]; then
          echo "Usage: ${name} <environment-name>"
          ${lib.optionalString (listCommand != null) ''
            echo ""
            echo "Available environments:"
            ${listCommand}
          ''}
        else
          ${tool} ${action} "$1"
        fi
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
  # TIMING HELPERS
  # ============================================

  # Wrap function with duration tracking
  # Usage: mkTimedFunction { name = "long-task"; body = "sleep 5 && echo done"; }
  mkTimedFunction = { name, body }:
    ''
      function ${name}() {
        local start_time=$(date +%s)
        ${body}
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "⏱️  Duration: $((duration / 60))m $((duration % 60))s"
      }
    '';

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
  # LIST & ATTRIBUTE SET UTILITIES
  # ============================================

  # Filter attributes by predicate
  filterAttrs = pred: set:
    lib.filterAttrs (name: value: pred name value) set;

  # Map over attribute values
  mapAttrValues = f: set:
    lib.mapAttrs (name: value: f value) set;

  # Create package group from list of names
  # Usage: mkPackageGroup ["git" "vim" "curl"] pkgs
  mkPackageGroup = names: pkgs:
    map (name: pkgs.${name}) names;

  # ============================================
  # CLEANUP HELPERS
  # ============================================

  # Import cleanup helper library
  # Provides: mkCleanupFunction, mkCleanupGroup, mkDiskSpaceReport, mkCleanupLog, etc.
  cleanup = import ./cleanup.nix { inherit lib; pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem or "x86_64-darwin"}; };

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
}
