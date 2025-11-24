# Machine Configuration System

This directory contains machine-specific configurations and the machine type detection system.

## Machine Types

The system supports flexible machine type detection that decouples configuration from specific hostnames.

### Available Machine Types

- **personal**: Personal machines (development, learning, personal projects)
- **work**: Work machines (company-specific tools, configurations, policies)

### Machine Mapping

The mapping between hostnames and machine types is defined in `machines.nix`:

```nix
{
  "mbp-jimmy" = "personal";
  "mbp-work" = "work";
}
```

## Adding a New Machine

1. **Add hostname to `machines.nix`**:
   ```nix
   {
     "mbp-jimmy" = "personal";
     "mbp-work" = "work";
     "new-machine" = "personal";  # Add this line
   }
   ```

2. **Create host-specific directory**:
   ```bash
   mkdir -p hosts/new-machine
   ```

3. **Create configuration files** in `hosts/new-machine/`:
   - `default.nix` - Main configuration
   - `secrets.yaml` - Encrypted secrets (optional)

4. **Add to flake.nix**:
   ```nix
   darwinConfigurations."new-machine" = mkDarwinSystem {
     hostname = "new-machine";
     username = "your-username";
     mixins = [ "base" "dev" "personal" ];  # or "work"
   };
   ```

5. **Build and switch**:
   ```bash
   darwin-rebuild switch --flake ~/nix-darwin#new-machine
   ```

## Local Override for Testing

You can temporarily override the machine type without modifying tracked files:

1. **Create override file**:
   ```bash
   echo '"testing"' > hosts/local-override.nix
   ```

2. **Build to test**:
   ```bash
   darwin-rebuild build --flake ~/nix-darwin
   ```

3. **Remove override**:
   ```bash
   rm hosts/local-override.nix
   ```

**Note**: `local-override.nix` is gitignored and takes precedence over the machine mapping.

## Using Machine Type Detection

In your configuration files, use the provided helper functions:

```nix
{ config, pkgs, hostname, myLib, ... }:

{
  # Check if personal machine
  home.sessionVariables = myLib.selectByMachine hostname {
    personal = { MACHINE_MODE = "home"; };
    work = { MACHINE_MODE = "work"; };
  };

  # Conditional imports
  imports = myLib.importIfPersonal hostname ./personal-only.nix;

  # Boolean checks
  programs.foo.enable = myLib.isWork hostname;
}
```

### Available Helper Functions

From `myLib`:

- `machineType hostname` - Get machine type ("personal" | "work" | "unknown")
- `isPersonal hostname` - Returns true if machine is personal
- `isWork hostname` - Returns true if machine is work
- `requireKnownMachine hostname` - Validates machine is recognized (throws error if unknown)
- `selectByMachine hostname { personal = X; work = Y; default = Z; }` - Select value by type
- `importIfPersonal hostname path` - Import file only on personal machines
- `importIfWork hostname path` - Import file only on work machines

## Directory Structure

```
hosts/
├── README.md                 # This file
├── machines.nix              # Hostname → type mapping
├── local-override.nix        # Local testing override (gitignored)
├── mbp-jimmy/               # Personal Mac configuration
│   ├── default.nix
│   └── secrets.yaml
└── mbp-work/                # Work Mac configuration
    ├── default.nix
    └── secrets.yaml
```

## Validation

The system validates that all hostnames are recognized during build:

```bash
# This will fail if hostname is not in machines.nix
darwin-rebuild build --flake ~/nix-darwin

# Error message will show:
# Unknown machine: unknown-host
# This machine is not defined in hosts/machines.nix
# To fix this, either:
#   1. Add "unknown-host" to hosts/machines.nix with appropriate type
#   2. Create hosts/local-override.nix with desired type (for testing)
```

## Benefits

1. **Portability**: Changing hostname doesn't break configuration
2. **Flexibility**: Easy to add new machines without code changes
3. **Testing**: Local override supports experimentation
4. **Validation**: Build-time checks ensure known machines
5. **Clarity**: Explicit machine type mapping in one file
6. **Maintainability**: Single source of truth for machine classification
