# Phase 6: Machine Configuration Design

## Problem Statement

**Corporate IT resets hostname** → Can't rely on hostname for machine type detection

Current system:
```nix
hosts/machines.nix:
  "mbp-jimmy" = "personal";
  "mbp-work" = "work";
```

**Fails when**: Corporate IT renames `mbp-work` → `C02ABC123DEF` after restart

## Solution: Persistent Machine Configuration File

### Architecture

```
config/
├── user-config.nix          # User identity (gitignored)
├── machine-config.nix       # THIS machine config (gitignored)
└── machines.nix.template    # Template for reference (committed)
```

**Key Insight**: Machine config is **per-machine**, not **per-hostname**

### 1. Machine Config File

**Location**: `config/machine-config.nix` (gitignored, created during setup)

```nix
{
  # Machine identity - survives hostname changes
  machineId = "work-macbook-m3";
  machineType = "work";  # or "personal"

  # Display names (for user reference)
  description = "Work MacBook Pro M3";

  # Hostname handling
  expectedHostname = "mbp-work";  # What you WANT it to be
  actualHostname = null;  # Auto-detected at build time

  # Mixins for this machine
  mixins = [ "base" "dev" "work" ];

  # System architecture
  system = "aarch64-darwin";
}
```

### 2. Setup Wizard Flow

```bash
./setup.sh --configure-machine

# Interactive prompts:
❓ What type of machine is this?
   1) Personal Mac
   2) Work Mac
   → 2

❓ Give this machine a unique ID (e.g., work-macbook-m3):
   → work-macbook-m3

❓ Description for this machine:
   → Work MacBook Pro M3

❓ What hostname do you WANT? (current: C02ABC123DEF)
   → mbp-work

⚠️  Warning: Corporate IT may reset hostname
   We'll handle this gracefully - config survives hostname changes

✅ Machine configuration saved to: config/machine-config.nix

📝 Setting hostname to: mbp-work
   Run this command: sudo scutil --set HostName mbp-work
   (May be reset by corporate IT - that's OK!)
```

### 3. Updated Flake.nix

**OLD** (hostname-dependent):
```nix
darwinConfigurations."mbp-work" = mkDarwinSystem {
  hostname = "mbp-work";  # BREAKS when IT renames it
  username = "jimmy";
  mixins = [ "base" "dev" "work" ];
};
```

**NEW** (config-file driven):
```nix
outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, sops-nix }:
  let
    userConfig = import ./config/user-config.nix;
    machineConfig = import ./config/machine-config.nix;

    # Use machineId (persistent) not hostname (volatile)
    configName = machineConfig.machineId;

    # Detect actual hostname at build time
    actualHostname = builtins.readFile (
      pkgs.runCommand "get-hostname" {} ''
        hostname > $out
      ''
    );

    mkDarwinSystem =
      nix-darwin.lib.darwinSystem {
        system = machineConfig.system;

        specialArgs = {
          inherit inputs;
          username = userConfig.username;
          hostname = actualHostname;  # Real hostname (may change)
          machineType = machineConfig.machineType;  # Fixed type
          machineId = machineConfig.machineId;  # Persistent ID
          myLib = import ./lib { inherit lib pkgs; };
        };

        modules = [
          # Machine-specific config
          ./hosts/${configName}

          # Mixins based on machineType
          ./home/_mixins/${machineConfig.machineType}.nix

          # User config
          ./home/${userConfig.username}
        ];
      };
  in
  {
    # Single configuration - works regardless of hostname
    darwinConfigurations.${configName} = mkDarwinSystem;

    # Convenience alias for current hostname
    darwinConfigurations.${actualHostname} = mkDarwinSystem;
  };
```

### 4. Build Command Changes

**OLD** (needs exact hostname):
```bash
darwin-rebuild switch --flake .#mbp-work
```

**NEW** (hostname-independent):
```bash
# Option 1: Use machine ID
darwin-rebuild switch --flake .#work-macbook-m3

# Option 2: Auto-detect from machine-config.nix
darwin-rebuild switch --flake .

# Option 3: Use current hostname (works even if renamed)
darwin-rebuild switch --flake .#$(hostname)
```

### 5. Alias in Zsh

```nix
# home/jimmy/shell/zsh.nix

programs.zsh.shellAliases = {
  # Always works, regardless of hostname
  nix-rebuild = "darwin-rebuild switch --flake ~/nix-darwin";

  # Explicit machine ID (survives renames)
  nix-rebuild-work = "darwin-rebuild switch --flake ~/nix-darwin#work-macbook-m3";
};
```

### 6. Machine Detection in Code

**OLD** (hostname-based):
```nix
{ hostname, ... }:
{
  programs.ssh.matchBlocks = lib.optionalAttrs (hostname == "mbp-work") {
    "work-bastion" = { ... };
  };
}
```

**NEW** (machineType-based):
```nix
{ machineType, ... }:
{
  programs.ssh.matchBlocks = lib.optionalAttrs (machineType == "work") {
    "work-bastion" = { ... };
  };
}
```

### 7. Hostname Reset Handling

When corporate IT renames hostname:

```bash
# Before: C02ABC123DEF
# After IT change: MacBook-Pro-5

# Your config still works:
nix-rebuild
# ✅ Reads config/machine-config.nix
# ✅ machineType = "work" (unchanged)
# ✅ Loads work.nix mixin
# ✅ All work configs applied

# Optionally reset hostname back:
sudo scutil --set HostName mbp-work
```

### 8. Multi-Machine Setup

**Scenario**: You have 2 machines (personal + work)

```
# Machine 1 (personal):
config/machine-config.nix:
  machineId = "personal-macbook-m1"
  machineType = "personal"
  mixins = [ "base" "dev" "personal" ]

# Machine 2 (work):
config/machine-config.nix:
  machineId = "work-macbook-m3"
  machineType = "work"
  mixins = [ "base" "dev" "work" ]
```

**Git strategy**:
- `config/*.nix` gitignored on each machine
- When you deploy to new machine: `./setup.sh --configure-machine` creates fresh config

### 9. Directory Structure

```
nix-darwin/
├── config/
│   ├── user-config.nix              # gitignored (per-user)
│   ├── machine-config.nix           # gitignored (per-machine)
│   ├── user-config.nix.template     # committed (reference)
│   └── machine-config.nix.template  # committed (reference)
├── hosts/
│   ├── work-macbook-m3/            # Machine ID as folder name
│   │   ├── default.nix
│   │   └── secrets.yaml
│   └── personal-macbook-m1/
│       ├── default.nix
│       └── secrets.yaml
├── home/
│   ├── jimmy/                      # Username as folder
│   └── _mixins/
│       ├── work.nix.template       # committed
│       ├── work-jimmy.nix          # gitignored
│       └── personal.nix
```

### 10. Migration Command

```bash
# First time setup on work Mac:
./setup.sh --migrate

❓ Machine type: work
❓ Machine ID: work-macbook-m3
❓ Current hostname: C02ABC123DEF
❓ Preferred hostname: mbp-work

# Creates:
✅ config/machine-config.nix
✅ hosts/work-macbook-m3/
✅ home/_mixins/work-jimmy.nix

# Sets hostname (temporary until IT resets):
sudo scutil --set HostName mbp-work

# Build using machine ID (survives renames):
darwin-rebuild switch --flake .#work-macbook-m3

# Or just:
darwin-rebuild switch --flake .
```

## Benefits

1. ✅ **Hostname-independent**: Works even when corporate IT renames machine
2. ✅ **Persistent identity**: `machineType` survives all changes
3. ✅ **Multi-machine ready**: Each machine has own config file
4. ✅ **User-agnostic**: Template system for new users
5. ✅ **Simple setup**: One command to configure machine
6. ✅ **Backward compatible**: Can still use hostname if stable

## Implementation Checklist

- [ ] Create `config/machine-config.nix.template`
- [ ] Update `flake.nix` to read machine-config.nix
- [ ] Pass `machineType` to all modules (replace hostname checks)
- [ ] Update `lib/machine-detection.nix` to use machineType
- [ ] Create `./setup.sh --configure-machine` command
- [ ] Update all hostname-based logic to machineType
- [ ] Add config/*.nix to .gitignore
- [ ] Create templates for reference
- [ ] Update documentation
- [ ] Test hostname change scenario
