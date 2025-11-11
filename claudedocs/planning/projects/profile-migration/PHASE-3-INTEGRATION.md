# Phase 3: Flake Integration - Profile Migration

**Duration**: ~6 hours
**Prerequisites**: Phase 1 and Phase 2 complete
**Risk Level**: High (modifies system entry point)

---

## Overview

Phase 3 integrates the profile system into flake.nix, making profiles the active configuration source. This is the critical phase where the system switches from hostname-based mixins to profile-based architecture.

---

## Architecture Changes

**Before (Current)**:
```nix
flake.nix
  → hosts/mbp-jimmy/default.nix
    → home/jimmy/default.nix
      → home/_mixins/base.nix
      → home/_mixins/dev.nix
      → home/_mixins/personal.nix  # Selected by hostname
```

**After (Profile-Based)**:
```nix
flake.nix (reads config/machine-config.nix)
  → hosts/mbp-jimmy/default.nix (passes profileName)
    → home/jimmy/default.nix
      → home/_profiles/${profileName}/default.nix
        → home/_profiles/personal/  # Selected by config, not hostname
```

---

## Tasks

### Task 3.1: Create Machine Configuration System
**Effort**: 1.5 hours
**Priority**: Critical
**Risk**: Medium

**Problem**: Need persistent machine identity separate from profile choice

**Action**:
```bash
# 1. Create config/machine-config.nix (GITIGNORED - machine-specific)
mkdir -p config
cat > config/machine-config.nix << 'EOF'
# config/machine-config.nix
#
# Machine-specific configuration (GITIGNORED)
# This file is unique per machine and persists machine identity

{
  # Machine identity (NEVER changes, even if hostname changes)
  machineId = "mbp-jimmy-2021";

  # Profile selection (CAN change - user switches profiles)
  profileName = "personal";  # Options: "personal" | "work" | "minimal"

  # Machine metadata
  description = "Jimmy's personal MacBook Pro";
  expectedHostname = "mbp-jimmy";  # Advisory only, can change

  # System architecture
  system = "aarch64-darwin";  # Or "x86_64-darwin"

  # Profile-specific overrides
  profileOverrides = {
    # Can override specific profile settings here if needed
  };
}
EOF

# 2. Create config/machine-config.nix.template (COMMITTED - for new machines)
cat > config/machine-config.nix.template << 'EOF'
# config/machine-config.nix.template
#
# Template for machine-specific configuration
# Copy to machine-config.nix and customize

{
  # Machine identity (choose unique ID)
  machineId = "CHANGE-ME";  # Example: "mbp-jimmy-2021" or "mbp-work-2024"

  # Profile selection
  profileName = "personal";  # Options: "personal" | "work" | "minimal"

  # Machine metadata
  description = "CHANGE-ME";  # Example: "Jimmy's work laptop"
  expectedHostname = "CHANGE-ME";  # Example: "mbp-work"

  # System architecture
  system = "aarch64-darwin";  # Or "x86_64-darwin" for Intel Macs

  # Profile-specific overrides
  profileOverrides = {};
}
EOF

# 3. Add to .gitignore
echo "config/machine-config.nix" >> .gitignore

# 4. Create validation script
cat > scripts/validate-machine-config.sh << 'EOF'
#!/usr/bin/env bash
# Validates machine-config.nix

if [ ! -f "config/machine-config.nix" ]; then
  echo "❌ config/machine-config.nix not found"
  echo "📝 Copy from config/machine-config.nix.template and customize"
  exit 1
fi

# Check for CHANGE-ME placeholders
if grep -q "CHANGE-ME" config/machine-config.nix; then
  echo "❌ Found CHANGE-ME placeholders in config/machine-config.nix"
  echo "📝 Please customize all values"
  exit 1
fi

# Validate Nix syntax
if ! nix-instantiate --eval --strict config/machine-config.nix &>/dev/null; then
  echo "❌ Invalid Nix syntax in config/machine-config.nix"
  exit 1
fi

echo "✅ Machine configuration valid"
EOF
chmod +x scripts/validate-machine-config.sh

# 5. Test validation
./scripts/validate-machine-config.sh
```

**Acceptance Criteria**:
- [ ] config/machine-config.nix created (gitignored)
- [ ] config/machine-config.nix.template committed
- [ ] .gitignore includes machine-config.nix
- [ ] Validation script created and passes
- [ ] Machine ID is unique and descriptive

---

### Task 3.2: Update flake.nix for Profile Support
**Effort**: 2 hours
**Priority**: Critical
**Risk**: High

**Problem**: flake.nix currently hardcodes hostname-based machine detection. Need to read machine-config.nix and pass profileName to configurations.

**Current flake.nix** (simplified):
```nix
darwinConfigurations = {
  "mbp-jimmy" = nix-darwin.lib.darwinSystem {
    modules = [
      ./hosts/mbp-jimmy
      home-manager.darwinModules.home-manager {
        home-manager.users.jimmy = import ./home/jimmy;
      }
    ];
  };
};
```

**Action**:
```bash
# 1. Backup current flake.nix
cp flake.nix flake.nix.backup

# 2. Read and understand current flake.nix structure
cat flake.nix

# 3. Modify flake.nix to support profiles
# Add at top of darwinConfigurations:

cat > flake.nix.new << 'EOF'
{
  description = "nix-darwin system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ... }:
  let
    # Read machine configuration (with fallback for new installations)
    machineConfig = if builtins.pathExists ./config/machine-config.nix
                    then import ./config/machine-config.nix
                    else {
                      machineId = "default";
                      profileName = "personal";
                      system = "aarch64-darwin";
                    };

    # Extract key values
    profileName = machineConfig.profileName or "personal";
    machineId = machineConfig.machineId or "default";
    system = machineConfig.system or "aarch64-darwin";

    # Create shared module arguments
    sharedModuleArgs = {
      inherit profileName machineId;
      myLib = import ./lib { inherit (nixpkgs) lib; };
    };

  in {
    # Darwin configurations (indexed by machineId now, not hostname)
    darwinConfigurations = {
      "${machineId}" = nix-darwin.lib.darwinSystem {
        inherit system;

        specialArgs = sharedModuleArgs;

        modules = [
          ./modules/darwin
          ./modules/shared

          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = sharedModuleArgs;

            home-manager.users.jimmy = { config, pkgs, ... }: {
              imports = [
                ./home/jimmy
                ./home/_profiles/${profileName}
              ];
            };
          }
        ];
      };
    };

    # Backward compatibility: hostname aliases
    # Allows: darwin-rebuild switch --flake .#mbp-jimmy
    darwinConfigurations."mbp-jimmy" = self.darwinConfigurations."${machineId}";
    darwinConfigurations."mbp-work" = self.darwinConfigurations."${machineId}";
  };
}
EOF

# 4. Validate new flake.nix
nix flake check --show-trace

# 5. If validation passes, replace
if [ $? -eq 0 ]; then
  mv flake.nix.new flake.nix
  echo "✅ flake.nix updated successfully"
else
  echo "❌ Validation failed, keeping original flake.nix"
  rm flake.nix.new
  exit 1
fi
```

**Acceptance Criteria**:
- [ ] flake.nix reads config/machine-config.nix
- [ ] profileName extracted and passed to modules
- [ ] machineId used for configuration indexing
- [ ] Backward compatibility aliases exist
- [ ] `nix flake check` passes
- [ ] Syntax is valid

**Validation**:
```bash
nix flake check --show-trace  # Must pass
nix flake show                # Should show configurations
```

---

### Task 3.3: Update home/jimmy/default.nix
**Effort**: 1 hour
**Priority**: Critical
**Risk**: Medium

**Problem**: home/jimmy/default.nix currently imports mixins directly. Need to make it profile-aware.

**Action**:
```bash
# 1. Backup current home/jimmy/default.nix
cp home/jimmy/default.nix home/jimmy/default.nix.backup

# 2. Modify home/jimmy/default.nix
cat > home/jimmy/default.nix << 'EOF'
# home/jimmy/default.nix
#
# User-specific configuration (profile-agnostic)
# Profile-specific config comes from home/_profiles/${profileName}

{ config, pkgs, lib, myLib, profileName ? "personal", machineId ? "default", ... }:

{
  # User identity
  home.username = "jimmy";
  home.homeDirectory = "/Users/jimmy";

  # State version (NEVER CHANGE)
  home.stateVersion = "24.05";

  # NOTE: Profile imports happen in flake.nix
  # This file contains only profile-agnostic user settings

  # Universal programs (not in profiles)
  programs.home-manager.enable = true;

  # Profile information (for debugging)
  home.sessionVariables = {
    ACTIVE_PROFILE = profileName;
    MACHINE_ID = machineId;
  };

  # Import user-specific but profile-agnostic configs
  imports = [
    # Add user-specific configs here that apply to ALL profiles
  ];
}
EOF

# 3. Validate
nix-instantiate --eval home/jimmy/default.nix \
  --arg config {} \
  --arg pkgs 'import <nixpkgs> {}' \
  --arg lib '(import <nixpkgs> {}).lib' \
  --arg myLib {} \
  --argstr profileName "personal" \
  --argstr machineId "test"
```

**Acceptance Criteria**:
- [ ] Accepts profileName and machineId parameters
- [ ] No longer imports mixins directly
- [ ] Profile imports handled by flake.nix
- [ ] Session variables show active profile
- [ ] Nix syntax validates

---

### Task 3.4: Create Profile Switcher Script
**Effort**: 1 hour
**Priority**: High
**Risk**: Low

**Purpose**: Allow users to switch profiles easily

**Action**:
```bash
# Create scripts/switch-profile.sh
cat > scripts/switch-profile.sh << 'EOF'
#!/usr/bin/env bash
# Switch between profiles

set -euo pipefail

PROFILE="${1:-}"
VALID_PROFILES=("personal" "work" "minimal")

show_usage() {
  cat << USAGE
Usage: switch-profile.sh [profile]

Profiles:
  personal  - Personal/learning environment
  work      - Work environment (AWS, databases)
  minimal   - Minimal troubleshooting environment

Current profile: $(grep 'profileName =' config/machine-config.nix | awk '{print $3}' | tr -d '";')

Example:
  switch-profile.sh work

USAGE
}

# Validate profile argument
if [ -z "$PROFILE" ]; then
  show_usage
  exit 1
fi

# Check if profile is valid
if [[ ! " ${VALID_PROFILES[@]} " =~ " ${PROFILE} " ]]; then
  echo "❌ Invalid profile: $PROFILE"
  echo "Valid profiles: ${VALID_PROFILES[@]}"
  exit 1
fi

# Check machine config exists
if [ ! -f "config/machine-config.nix" ]; then
  echo "❌ config/machine-config.nix not found"
  echo "📝 Run: cp config/machine-config.nix.template config/machine-config.nix"
  exit 1
fi

# Update machine-config.nix
echo "🔄 Switching to profile: $PROFILE"
sed -i.bak "s/profileName = \"[^\"]*\"/profileName = \"$PROFILE\"/" config/machine-config.nix

# Show diff
echo "📝 Configuration change:"
diff config/machine-config.nix.bak config/machine-config.nix || true

# Rebuild system
echo "🔨 Rebuilding system with new profile..."
if darwin-rebuild switch --flake .; then
  echo "✅ Successfully switched to $PROFILE profile"
  echo "🔄 Restart your shell: exec zsh"
  rm config/machine-config.nix.bak
else
  echo "❌ Rebuild failed, restoring previous configuration"
  mv config/machine-config.nix.bak config/machine-config.nix
  exit 1
fi
EOF

chmod +x scripts/switch-profile.sh

# 2. Add convenience alias to zsh
# (Will be added in profiles/_template/shell/zsh.nix)
echo "switch-profile = \"~/nix-darwin/scripts/switch-profile.sh\"" >> home/_profiles/_template/shell/aliases.nix || true
```

**Acceptance Criteria**:
- [ ] Script validates profile argument
- [ ] Script updates machine-config.nix
- [ ] Script rebuilds system automatically
- [ ] Script shows helpful error messages
- [ ] Script has rollback on failure
- [ ] Convenience alias added

**Testing**:
```bash
# Show current profile
./scripts/switch-profile.sh

# Switch to work profile
./scripts/switch-profile.sh work

# Should fail gracefully
./scripts/switch-profile.sh invalid-profile
```

---

### Task 3.5: Test Profile Switching End-to-End
**Effort**: 30 minutes
**Priority**: Critical
**Risk**: Medium

**Purpose**: Validate complete profile system works

**Action**:
```bash
# 1. Initial state check
echo "Current profile:"
grep 'profileName' config/machine-config.nix

# 2. Test personal profile (if not already active)
./scripts/switch-profile.sh personal
exec zsh

# Verify personal-specific features
cd ~/learning  # Should work (personal alias)
ollama-start   # Should work (personal alias)
echo $ACTIVE_PROFILE  # Should be "personal"
echo $MACHINE_MODE    # Should be "home"

# 3. Test work profile
./scripts/switch-profile.sh work
exec zsh

# Verify work-specific features
awsuse         # Should exist (work function)
awswho         # Should exist (work function)
dbconnect-ti   # Should exist (work function)
echo $ACTIVE_PROFILE  # Should be "work"
echo $MACHINE_MODE    # Should be "work"

# 4. Test minimal profile
./scripts/switch-profile.sh minimal
exec zsh

# Verify minimal features
which awsuse   # Should NOT exist
which ollama-start  # Should NOT exist
g s            # Basic git should work
echo $ACTIVE_PROFILE  # Should be "minimal"

# 5. Switch back to original profile
./scripts/switch-profile.sh personal  # Or work, depending on machine
exec zsh

# 6. Full system health check
health-check  # Should pass
```

**Acceptance Criteria**:
- [ ] Profile switching works without errors
- [ ] Profile-specific aliases/functions available in correct profile
- [ ] Profile-specific packages installed in correct profile
- [ ] Environment variables correct per profile
- [ ] Shell prompt reflects profile (starship themes)
- [ ] No functionality lost
- [ ] Can switch between all 3 profiles

**Expected Results**:
- Personal profile: learning aliases, ollama, personal packages
- Work profile: AWS functions, database connectors, work packages
- Minimal profile: basic CLI only, no advanced features

---

## Phase 3 Completion Criteria

**All tasks complete when**:
- [ ] Machine config system created (Task 3.1)
- [ ] flake.nix updated for profiles (Task 3.2)
- [ ] home/jimmy/default.nix profile-aware (Task 3.3)
- [ ] Profile switcher script working (Task 3.4)
- [ ] End-to-end testing passes (Task 3.5)
- [ ] All profiles switch successfully
- [ ] No functionality lost
- [ ] System stable on all profiles

**Expected State After Phase 3**:
- Profile-based system fully operational
- Can switch profiles with simple command
- All existing functionality preserved
- Backward compatibility maintained
- Machine identity separate from profile choice

**Rollback Plan**:
```bash
# If critical issues arise

# 1. Restore original flake.nix
cp flake.nix.backup flake.nix

# 2. Rollback to previous generation
nix-rollback

# 3. Restart shell
exec zsh

# 4. Verify system working
health-check
```

---

## Testing Checklist

After completing Phase 3:

```bash
# 1. Validate flake
nix flake check --show-trace  # Must pass

# 2. Test each profile
for profile in personal work minimal; do
  echo "Testing $profile profile..."
  ./scripts/switch-profile.sh $profile
  exec zsh
  health-check
done

# 3. Verify profile-specific features
# (See Task 3.5 testing steps)

# 4. Check environment variables
echo $ACTIVE_PROFILE
echo $MACHINE_ID
echo $MACHINE_MODE

# 5. Verify backward compatibility
darwin-rebuild switch --flake .#mbp-jimmy  # Should still work

# 6. Full system validation
nix-rebuild && exec zsh
health-check
```

---

**Next Phase**: [Phase 4: Migration & Cleanup](PHASE-4-MIGRATION.md)
