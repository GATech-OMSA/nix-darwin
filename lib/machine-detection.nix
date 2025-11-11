# Machine Detection Helpers
#
# Provides hostname-independent machine type detection with local override support.
#
# Purpose:
#   - Decouple configuration from specific hostnames
#   - Enable flexible machine type detection
#   - Support local overrides for testing
#   - Provide validation for known machines
#
# Functions:
#   - getMachineType: Get machine type with priority system
#   - isPersonal: Check if personal machine
#   - isWork: Check if work machine
#   - requireKnownMachine: Validate machine is recognized
#
# Priority System:
#   1. Local override (hosts/local-override.nix) - highest priority
#   2. Machine mapping (hosts/machines.nix)
#   3. Unknown machine - throws error if validation enabled

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
  # Get machine type with priority: local override > mapping > unknown
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

  # Check if machine is personal type
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

  # Check if machine is work type
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

  # Validate that machine is recognized (not "unknown")
  # Throws error if machine is not in mapping and no local override exists
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

  # Select value based on machine type with fallback support
  # This is re-exported from default.nix but uses the new getMachineType
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
