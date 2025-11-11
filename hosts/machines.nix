# Machine Type Mapping
#
# This file defines the mapping between hostnames and machine types.
# Machine types are used throughout the configuration to enable/disable
# features, apply different settings, and select appropriate mixins.
#
# Machine Types:
#   - personal: Personal machines (development, learning, personal projects)
#   - work: Work machines (company-specific tools, configurations, policies)
#
# Adding a New Machine:
#   1. Add hostname → type mapping below
#   2. Create host-specific config in hosts/<hostname>/
#   3. Add appropriate mixins in flake.nix
#
# Local Override:
#   For testing or temporary type changes, create hosts/local-override.nix:
#     "testing"
#   This file is gitignored and takes precedence over this mapping.

{
  # Personal Machines
  "mbp-jimmy" = "personal";

  # Work Machines
  "mbp-work" = "work";

  # Add more machines here as needed:
  # "macbook-pro-2024" = "personal";
  # "imac-home" = "personal";
  # "work-laptop" = "work";
}
