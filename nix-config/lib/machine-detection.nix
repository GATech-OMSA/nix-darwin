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



rec {
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
}
