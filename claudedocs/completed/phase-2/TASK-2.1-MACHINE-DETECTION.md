# Task 2.1: Hostname-Independent Machine Detection

**Status**: ✅ COMPLETE  
**Date**: 2024-11-06  
**Phase**: Phase 2 - Infrastructure Improvements  

---

## Objective

Replace hardcoded hostname checks with a flexible machine type detection system that decouples configuration from specific hostnames.

## Problem Statement

The system used `hostname == "mbp-jimmy"` and `hostname == "mbp-work"` checks throughout the codebase, making the configuration:
- Non-portable (hostname changes break configuration)
- Fragile (adding new machines requires finding all checks)
- Hard to test (can't easily simulate different machine types)

## Solution Implemented

Created a flexible machine type detection system with:

1. **Central Mapping** (`hosts/machines.nix`)
   - Single source of truth for hostname → type mapping
   - Easy to add new machines

2. **Detection Library** (`lib/machine-detection.nix`)
   - Flexible type detection with priority system
   - Local override support for testing
   - Build-time validation

3. **Helper Functions** (re-exported via `lib/default.nix`)
   - `isPersonal hostname` - Boolean check
   - `isWork hostname` - Boolean check
   - `selectByMachine hostname { ... }` - Value selection
   - `requireKnownMachine hostname` - Validation

---

## Files Created

### 1. hosts/machines.nix (32 lines)
Central hostname → machine type mapping:

```nix
{
  # Personal Machines
  "mbp-jimmy" = "personal";

  # Work Machines
  "mbp-work" = "work";
}
```

### 2. lib/machine-detection.nix (150 lines)
Machine detection with local override support:

```nix
{
  getMachineType = hostname: /* priority system */;
  isPersonal = hostname: (getMachineType hostname) == "personal";
  isWork = hostname: (getMachineType hostname) == "work";
  requireKnownMachine = hostname: /* validation */;
  selectByMachine = hostname: values: /* selection */;
}
```

Priority System:
1. Local override (`hosts/local-override.nix`) - highest
2. Machine mapping (`hosts/machines.nix`)
3. Unknown machine - throws error

### 3. hosts/README.md (155 lines)
Complete documentation covering:
- Machine type system overview
- Adding new machines
- Using helper functions
- Local override for testing
- Examples and best practices

---

## Files Modified

### 1. lib/default.nix
- Import machine-detection.nix
- Re-export functions for compatibility
- Added requireKnownMachine

### 2. flake.nix
- Validate machine type in mkDarwinSystem
- Pass machineType to all modules
- Enable build-time validation

### 3. .gitignore
- Added `hosts/local-override.nix` for testing

### 4. modules/darwin/system.nix
**BEFORE**:
```nix
persistentApps = if hostname == "mbp-work"
  then workDockApps
  else personalDockApps;
```

**AFTER**:
```nix
persistentApps = myLib.selectByMachine hostname {
  work = workDockApps;
  personal = personalDockApps;
};
```

### 5. home/jimmy/programs/ssh.nix
**BEFORE**:
```nix
matchBlocks = { ... } // lib.optionalAttrs (hostname == "mbp-work") { ... };
```

**AFTER**:
```nix
matchBlocks = { ... } // lib.optionalAttrs (myLib.isWork hostname) { ... };
```

### 6. hosts/mbp-jimmy/secrets.yaml
- Re-encrypted (timestamp update only)

---

## Usage Examples

### In Configuration Files

```nix
{ config, pkgs, hostname, myLib, ... }:

{
  # Select value by machine type
  environment.systemPackages = myLib.selectByMachine hostname {
    personal = personalPackages;
    work = workPackages;
    default = basePackages;
  };

  # Boolean checks
  programs.vscode.enable = myLib.isPersonal hostname;
  programs.teams.enable = myLib.isWork hostname;

  # Conditional attributes
  programs.ssh.matchBlocks = {
    "*" = { /* common config */ };
  } // lib.optionalAttrs (myLib.isWork hostname) {
    "work-bastion" = { /* work-specific */ };
  };
}
```

### Adding a New Machine

1. **Add to hosts/machines.nix**:
   ```nix
   {
     "mbp-jimmy" = "personal";
     "mbp-work" = "work";
     "imac-home" = "personal";  # ADD THIS
   }
   ```

2. **Create host config**:
   ```bash
   mkdir -p hosts/imac-home
   # Create hosts/imac-home/default.nix
   ```

3. **Add to flake.nix**:
   ```nix
   darwinConfigurations."imac-home" = mkDarwinSystem {
     hostname = "imac-home";
     username = "jimmy";
     mixins = [ "base" "dev" "personal" ];
   };
   ```

4. **Build**:
   ```bash
   darwin-rebuild switch --flake ~/nix-darwin#imac-home
   ```

### Local Override for Testing

```bash
# Test as "work" machine
echo '"work"' > hosts/local-override.nix
darwin-rebuild build --flake ~/nix-darwin

# Test as "testing" type
echo '"testing"' > hosts/local-override.nix
darwin-rebuild build --flake ~/nix-darwin

# Remove override
rm hosts/local-override.nix
```

---

## Validation Results

### Build & Tests
✅ `nix flake check` - Passed  
✅ `darwin-rebuild build` - Success  
✅ `darwin-rebuild switch` - Full activation successful  
✅ Local override test - Working correctly  
✅ No hardcoded hostname checks remain (verified via grep)  

### Code Quality
✅ Backward compatible - All existing APIs preserved  
✅ Documentation complete - hosts/README.md comprehensive  
✅ Validation enabled - Unknown machines fail at build time  
✅ Testing support - Local override for experimentation  
✅ Clean git status - All changes staged  

---

## Benefits Achieved

1. **Portability**: Configuration no longer tied to specific hostnames
2. **Flexibility**: Adding new machines requires only a mapping entry
3. **Testing**: Local override enables safe experimentation
4. **Validation**: Build fails for unknown machines (safety)
5. **Maintainability**: Single source of truth in hosts/machines.nix
6. **Clarity**: Explicit machine type in one central location

---

## Breaking Changes

**None** - System is fully backward compatible:
- All existing helper functions preserved
- Same API for isPersonal, isWork, selectByMachine
- Internal implementation changed, external interface identical
- NEW function: requireKnownMachine for validation

---

## Success Criteria

- [x] hosts/machines.nix created with hostname mappings
- [x] lib/machine-detection.nix created with helper functions  
- [x] All hostname checks converted to machine type checks
- [x] Build succeeds with no errors
- [x] Local override works for testing
- [x] Documentation complete

**ALL CRITERIA MET** ✅

---

## Git Changes

**Files Modified**: 9 total (3 new, 6 modified)  
**Lines Added**: ~320 (code + documentation)

```
Changes staged:
  modified:   .gitignore
  modified:   flake.nix
  modified:   home/jimmy/programs/ssh.nix
  new file:   hosts/README.md
  new file:   hosts/machines.nix
  modified:   hosts/mbp-jimmy/secrets.yaml
  modified:   lib/default.nix
  new file:   lib/machine-detection.nix
  modified:   modules/darwin/system.nix
```

---

## Next Steps

1. Commit changes to git
2. Consider CI validation for machine type detection
3. Update CLAUDE.md with new patterns
4. Continue Phase 2 infrastructure improvements

---

## Related Documentation

- [hosts/README.md](../hosts/README.md) - Machine detection system guide
- [lib/README.md](../lib/README.md) - Helper function reference
- [MASTER-EXECUTION-PLAN.md](planning/MASTER-EXECUTION-PLAN.md) - Overall roadmap
