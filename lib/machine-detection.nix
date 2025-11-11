# Machine Detection Helpers
#
# Provides machine type checking functions that work directly with machineType.
#
# DEPRECATION NOTE:
#   Hostname-based functions (getMachineType, requireKnownMachine) are deprecated.
#   Use machineType directly from machineConfig (flake.nix) instead.
#
# Purpose:
#   - Provide backward-compatible type checking
#   - Support direct machineType comparisons
#   - Enable migration from hostname to machineType
#
# Functions:
#   - isPersonalType: Check if machineType is "personal" (NEW - preferred)
#   - isWorkType: Check if machineType is "work" (NEW - preferred)
#   - isPersonal: Check if hostname maps to personal (DEPRECATED)
#   - isWork: Check if hostname maps to work (DEPRECATED)
#   - getMachineType: Get type from hostname (DEPRECATED)
#   - requireKnownMachine: Validate hostname (DEPRECATED)

{ lib }:

let
  # Import machine mapping
  machines = import ../hosts/machines.nix;

  # Try to import local override if it exists
  # This allows testing different machine types without modifying tracked files
  localOverridePath = ../hosts/local-override.nix;
  hasLocalOverride = builtins.pathExists localOverridePath;
  localOverride = if hasLocalOverride
    then builtins.readFile localOverridePath
    else null;

in rec {
  # ==================================================
  # NEW API: Direct machineType functions (PREFERRED)
  # ==================================================

  # Check if machine type is personal
  #
  # Args:
  #   machineType: String - The machine type from machineConfig
  #
  # Returns:
  #   Bool - true if machineType is "personal"
  #
  # Example:
  #   isPersonalType "personal" => true
  #   isPersonalType "work" => false
  #
  # Usage in modules:
  #   lib.mkIf (myLib.isPersonalType machineType) { ... }
  isPersonalType = machineType: machineType == "personal";

  # Check if machine type is work
  #
  # Args:
  #   machineType: String - The machine type from machineConfig
  #
  # Returns:
  #   Bool - true if machineType is "work"
  #
  # Example:
  #   isWorkType "work" => true
  #   isWorkType "personal" => false
  #
  # Usage in modules:
  #   lib.mkIf (myLib.isWorkType machineType) { ... }
  isWorkType = machineType: machineType == "work";

  # Select value based on machine type
  #
  # Args:
  #   machineType: String - The machine type from machineConfig
  #   values: AttrSet - Map of machine type to value
  #
  # Returns:
  #   Any - Value for machine type, or default if provided
  #
  # Throws:
  #   Error if no value for machine type and no default
  #
  # Example:
  #   selectByMachineType "work" { personal = "X"; work = "Y"; }
  #   => "Y"
  #
  # Usage in modules:
  #   email = myLib.selectByMachineType machineType {
  #     personal = "personal@example.com";
  #     work = "work@example.com";
  #   };
  selectByMachineType = machineType: values:
    let
      hasDefault = values ? default;
    in
      if values ? ${machineType} then
        values.${machineType}
      else if hasDefault then
        values.default
      else
        throw "No value for machine type '${machineType}' and no default provided";

  # ==================================================
  # DEPRECATED API: Hostname-based functions
  # ==================================================
  # These are kept for backward compatibility only.
  # Use the new API (isPersonalType, isWorkType, selectByMachineType) instead.

  # DEPRECATED: Get machine type with priority: local override > mapping > unknown
  #
  # Args:
  #   hostname: String - The machine hostname
  #
  # Returns:
  #   String - Machine type ("personal" | "work" | "unknown")
  #
  # Examples:
  #   getMachineType "mbp-jimmy" => "personal"
  #   getMachineType "mbp-work" => "work"
  #   getMachineType "unknown-host" => "unknown"
  getMachineType = hostname:
    if localOverride != null then
      # Local override takes precedence (for testing)
      lib.removeSuffix "\n" localOverride
    else if machines ? ${hostname} then
      # Use machine mapping
      machines.${hostname}
    else
      # Unknown machine
      "unknown";

  # DEPRECATED: Check if machine is personal type
  # Use isPersonalType instead
  #
  # Args:
  #   hostname: String - The machine hostname
  #
  # Returns:
  #   Bool - true if machine type is "personal"
  #
  # Example:
  #   isPersonal "mbp-jimmy" => true
  #   isPersonal "mbp-work" => false
  isPersonal = hostname:
    (getMachineType hostname) == "personal";

  # DEPRECATED: Check if machine is work type
  # Use isWorkType instead
  #
  # Args:
  #   hostname: String - The machine hostname
  #
  # Returns:
  #   Bool - true if machine type is "work"
  #
  # Example:
  #   isWork "mbp-work" => true
  #   isWork "mbp-jimmy" => false
  isWork = hostname:
    (getMachineType hostname) == "work";

  # DEPRECATED: Validate that machine is recognized (not "unknown")
  # Throws error if machine is not in mapping and no local override exists
  # This function is still used in flake.nix for backward compatibility
  #
  # Args:
  #   hostname: String - The machine hostname
  #
  # Returns:
  #   String - The machine type if recognized
  #
  # Throws:
  #   Error if machine type is "unknown"
  #
  # Example:
  #   requireKnownMachine "mbp-jimmy" => "personal"
  #   requireKnownMachine "random-host" => throws error
  requireKnownMachine = hostname:
    let
      type = getMachineType hostname;
    in
      if type == "unknown" then
        throw ''
          Unknown machine: ${hostname}

          This machine is not defined in hosts/machines.nix

          To fix this, either:
            1. Add "${hostname}" to hosts/machines.nix with appropriate type
            2. Create hosts/local-override.nix with desired type (for testing)

          Known machines:
            ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (k: v: "${k} → ${v}") machines)}
        ''
      else
        type;

  # DEPRECATED: Select value based on machine type with fallback support
  # Use selectByMachineType instead
  # This is kept for backward compatibility only
  #
  # Args:
  #   hostname: String - The machine hostname
  #   values: AttrSet - Map of machine type to value
  #
  # Returns:
  #   Any - Value for machine type, or default if provided
  #
  # Throws:
  #   Error if no value for machine type and no default
  #
  # Example:
  #   selectByMachine "mbp-work" { personal = "X"; work = "Y"; default = "Z"; }
  #   => "Y"
  selectByMachine = hostname: values:
    let
      type = getMachineType hostname;
      hasDefault = values ? default;
    in
      if values ? ${type} then
        values.${type}
      else if hasDefault then
        values.default
      else
        throw "No value for machine type '${type}' and no default provided";
}
