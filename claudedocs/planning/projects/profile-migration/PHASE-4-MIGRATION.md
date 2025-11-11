# Phase 4: Migration & Cleanup - Profile Migration

**Duration**: ~8 hours
**Prerequisites**: Phase 1, 2, and 3 complete and tested
**Risk Level**: Medium (cleanup and improvements)

---

## Overview

Phase 4 completes the migration by archiving the old system, implementing high-priority improvements, and updating documentation. This phase ensures the codebase is clean, maintainable, and well-documented.

---

## Tasks

### Task 4.1: Archive Old Mixin System
**Effort**: 1 hour
**Priority**: High
**Risk**: Low

**Problem**: Old `home/_mixins/` system no longer used but kept for backward compatibility. Should be archived after Phase 3 is stable.

**Prerequisites**: Phase 3 tested for at least 1 week with no issues

**Action**:
```bash
# 1. Verify new system is stable
echo "⚠️  Before archiving, confirm:"
echo "  - Phase 3 has been running for 1+ weeks"
echo "  - No issues with profile switching"
echo "  - All functionality verified"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Aborted. Run this task after stabilization period."
  exit 1
fi

# 2. Create archive directory
mkdir -p archive/2025-11-mixins-system

# 3. Move old mixins
mv home/_mixins archive/2025-11-mixins-system/
mv home/_template archive/2025-11-mixins-system/

# 4. Create README in archive
cat > archive/2025-11-mixins-system/README.md << 'EOF'
# Archived: Mixin-Based Configuration System

**Archived Date**: $(date +%Y-%m-%d)
**Reason**: Migrated to profile-based architecture
**Migration Project**: `claudedocs/planning/projects/profile-migration/`

## What Was Here

- `home/_mixins/`: Machine-specific configurations (base, dev, personal, work)
- `home/_template/`: Shared base configurations

## Why Archived

The hostname-based mixin system was replaced with profile-based architecture that:
- Separates machine identity from behavior (machineId vs profileName)
- Enables profile switching without rebuilding entire system
- Provides better isolation between personal/work/minimal profiles
- Fixes build failures from gitignored directories

## Migration Details

See: `claudedocs/planning/projects/profile-migration/PROJECT.md`

New location: `home/_profiles/{personal,work,minimal,_template}/`

## Restoration

If needed, old mixins can be restored from this archive directory.
EOF

# 5. Update .gitignore (remove old patterns if any)
# (Old patterns may no longer apply)

# 6. Commit the archival
git add archive/2025-11-mixins-system
git add home/  # Removal of _mixins and _template
git commit -m "chore: Archive old mixin system after profile migration

Migrated to profile-based architecture in home/_profiles/.
Old mixin system archived to archive/2025-11-mixins-system/ for reference.

Refs: claudedocs/planning/projects/profile-migration/"

# 7. Rebuild to confirm no dependencies on old system
nix-rebuild && exec zsh
health-check
```

**Acceptance Criteria**:
- [ ] home/_mixins/ moved to archive
- [ ] home/_template/ moved to archive
- [ ] README created in archive explaining migration
- [ ] System builds without old directories
- [ ] All profiles still work correctly
- [ ] Changes committed to git

**Validation**:
```bash
# Old directories should not exist
[ ! -d "home/_mixins" ] && echo "✅ _mixins archived"
[ ! -d "home/_template" ] && echo "✅ _template archived"

# New system should work
nix-rebuild && echo "✅ Build succeeds without old system"
```

---

### Task 4.2: Remove Backward Compatibility Code
**Effort**: 1 hour
**Priority**: Medium
**Risk**: Low

**Problem**: flake.nix has hostname aliases for backward compatibility. Remove after archival.

**Prerequisites**: Task 4.1 complete and tested

**Action**:
```bash
# 1. Backup flake.nix
cp flake.nix flake.nix.pre-cleanup

# 2. Edit flake.nix to remove backward compatibility section
# Remove these lines:
# darwinConfigurations."mbp-jimmy" = self.darwinConfigurations."${machineId}";
# darwinConfigurations."mbp-work" = self.darwinConfigurations."${machineId}";

# 3. Update rebuild commands to use machineId
# Document in README.md:
cat >> README.md << 'EOF'

## Rebuilding the System

```bash
# Use machine ID from config/machine-config.nix
darwin-rebuild switch --flake .

# Or specify explicitly:
darwin-rebuild switch --flake .#$(grep machineId config/machine-config.nix | awk '{print $3}' | tr -d '";')
```
EOF

# 4. Test rebuild with new approach
nix-rebuild

# 5. Update scripts to use machineId
# Update any scripts that reference hostname directly
```

**Acceptance Criteria**:
- [ ] Hostname aliases removed from flake.nix
- [ ] README updated with new rebuild instructions
- [ ] All scripts updated to use machineId
- [ ] System rebuilds successfully
- [ ] No references to old hostnames in code

---

### Task 4.3: Update Machine Detection Library
**Effort**: 2 hours
**Priority**: High
**Risk**: Medium

**Problem**: `lib/machine-detection.nix` has deprecated hostname-based API. Remove after migration to profile-based system.

**Current State** (from NOTES.md):
- Deprecated: `getMachineType`, `isPersonal`, `isWork`
- New: `isPersonalType`, `isWorkType`, `selectByMachineType`

**Action**:
```bash
# 1. Backup library
cp lib/machine-detection.nix lib/machine-detection.nix.backup

# 2. Audit all usages of deprecated functions
echo "🔍 Finding deprecated function usages..."
rg "getMachineType|isPersonal\(|isWork\(" --type nix

# 3. Replace deprecated calls with new API
# For each usage found:
# getMachineType hostname → Use machineType from config
# isPersonal hostname → isPersonalType machineType
# isWork hostname → isWorkType machineType

# 4. Remove deprecated functions from lib/machine-detection.nix
cat > lib/machine-detection.nix << 'EOF'
# lib/machine-detection.nix
#
# Machine type detection and conditional configuration
# Version 2.0 - Profile-based architecture
#
# BREAKING CHANGE: Removed hostname-based detection
# Now uses machineType from config/machine-config.nix

{ lib }:

{
  # Machine type predicates
  isPersonalType = machineType: machineType == "personal";
  isWorkType = machineType: machineType == "work";
  isMinimalType = machineType: machineType == "minimal";

  # Select value based on machine type
  # Usage: selectByMachineType "personal" { personal = X; work = Y; }
  selectByMachineType = machineType: values:
    if values ? ${machineType}
    then values.${machineType}
    else values.default or (throw "No value for machineType: ${machineType}");

  # Conditional imports based on machine type
  # Usage: importIf (isWorkType machineType) ./work-config.nix
  importIf = condition: path:
    if condition then [ path ] else [ ];

  # DEPRECATED FUNCTIONS REMOVED:
  # - getMachineType (use profileName from config instead)
  # - isPersonal (use isPersonalType with machineType)
  # - isWork (use isWorkType with machineType)
  # Migration guide: See claudedocs/planning/projects/profile-migration/
}
EOF

# 5. Update all consumers to use new API
# Find and update all files that import machine-detection

# 6. Test system rebuild
nix flake check --show-trace
nix-rebuild

# 7. Commit changes
git add lib/machine-detection.nix
git commit -m "refactor: Remove deprecated hostname-based detection API

Completed migration to profile-based architecture.
All machine detection now uses machineType from config.

BREAKING CHANGE: Removed getMachineType, isPersonal, isWork functions.
Use isPersonalType, isWorkType with machineType parameter instead.

Refs: claudedocs/planning/projects/profile-migration/"
```

**Acceptance Criteria**:
- [ ] All deprecated functions removed from library
- [ ] All usages updated to new API
- [ ] System builds successfully
- [ ] No references to deprecated functions remain
- [ ] Migration documented in commit message

**Validation**:
```bash
# Should find no deprecated calls
rg "getMachineType|\.isPersonal\(|\.isWork\(" --type nix && \
  echo "❌ Deprecated calls found" || \
  echo "✅ No deprecated calls"
```

---

### Task 4.4: Implement Starship Per-Profile
**Effort**: 2 hours
**Priority**: High (from IMPROVEMENTS.md #2)
**Risk**: Low

**Problem**: Starship prompt currently shared across all profiles. Should be customized per profile.

**Action**:
```bash
# 1. Starship configs already created in Phase 2
# - home/_profiles/personal/starship.toml
# - home/_profiles/work/starship.toml

# 2. Enhance work profile starship (AWS-prominent)
cat > home/_profiles/work/starship.toml << 'EOF'
# Work profile starship configuration
# Emphasizes AWS profile, Kubernetes context, and enterprise tools

format = """
[](#9A348E)\
$os\
$username\
[](bg:#DA627D fg:#9A348E)\
$directory\
[](fg:#DA627D bg:#FCA17D)\
$git_branch\
$git_status\
[](fg:#FCA17D bg:#86BBD8)\
$aws\
[](fg:#86BBD8 bg:#06969A)\
$kubernetes\
$terraform\
[](fg:#06969A bg:#33658A)\
$python\
$nodejs\
$golang\
$rust\
[ ](fg:#33658A)\
$character
"""

# AWS segment (PROMINENT for work)
[aws]
symbol = "  "
style = "bg:#86BBD8 fg:#000000"
format = '[[$symbol($profile )(\($region\)) ](bg:#86BBD8 fg:#000000)]($style)'
disabled = false

# Kubernetes segment (work uses k8s)
[kubernetes]
symbol = "☸ "
style = "bg:#06969A fg:#000000"
format = '[[$symbol($context )]($style)]($style)'
disabled = false

# Terraform segment (work uses IaC)
[terraform]
symbol = "💠 "
style = "bg:#06969A fg:#000000"
format = '[[$symbol$workspace ]($style)]($style)'
disabled = false

# Multi-language support (enterprise work)
[python]
symbol = " "
style = "bg:#33658A fg:#000000"
format = '[[$symbol($virtualenv )]($style)]($style)'

[nodejs]
symbol = " "
style = "bg:#33658A fg:#000000"
format = '[[$symbol($version )]($style)]($style)'

[golang]
symbol = " "
style = "bg:#33658A fg:#000000"
format = '[[$symbol($version )]($style)]($style)'

# ... rest of configuration
EOF

# 3. Simplify personal profile starship (learning-focused)
cat > home/_profiles/personal/starship.toml << 'EOF'
# Personal profile starship configuration
# Simpler, focused on learning and personal projects

format = """
[](#9A348E)\
$os\
$username\
[](bg:#DA627D fg:#9A348E)\
$directory\
[](fg:#DA627D bg:#FCA17D)\
$git_branch\
$git_status\
[](fg:#FCA17D bg:#86BBD8)\
$python\
$nodejs\
[ ](fg:#86BBD8)\
$character
"""

# No AWS segment (personal doesn't use AWS)
[aws]
disabled = true

# Python segment (learning focus)
[python]
symbol = " "
style = "bg:#86BBD8 fg:#000000"
format = '[[$symbol($virtualenv )]($style)]($style)'

[nodejs]
symbol = " "
style = "bg:#86BBD8 fg:#000000"
format = '[[$symbol($version )]($style)]($style)'

# Git (learning uses git heavily)
[git_branch]
symbol = " "
style = "bg:#FCA17D fg:#000000"
format = '[[$symbol$branch ]($style)]($style)'

# ... rest of configuration
EOF

# 4. Minimal profile: no starship (basic prompt)
# Already configured in Phase 2 - uses default zsh prompt

# 5. Test each profile's prompt
for profile in personal work minimal; do
  echo "Testing $profile starship..."
  ./scripts/switch-profile.sh $profile
  exec zsh
  # Verify prompt looks correct
done
```

**Acceptance Criteria**:
- [ ] Personal starship: simplified, learning-focused
- [ ] Work starship: AWS/k8s prominent, enterprise languages
- [ ] Minimal: no starship (basic prompt)
- [ ] Each profile has distinct visual appearance
- [ ] Prompts are functional and informative

**Expected Visual Difference**:
- **Personal**: Directory → Git → Python/Node → Prompt
- **Work**: Directory → Git → AWS → Kubernetes → Terraform → Languages → Prompt
- **Minimal**: Simple text prompt only

---

### Task 4.5: Create Migration Documentation
**Effort**: 2 hours
**Priority**: High
**Risk**: Low

**Problem**: Need comprehensive documentation of the migration for future reference and new machines.

**Action**:
```bash
# 1. Create migration guide
cat > docs/guides/profile-migration.md << 'EOF'
# Profile Migration Guide

**Status**: ✅ Complete (November 2025)
**Migration Project**: `claudedocs/planning/projects/profile-migration/`

---

## Overview

This system migrated from **hostname-based mixins** to **profile-based architecture** in November 2025.

**Before**: Configuration determined by hostname (mbp-jimmy → personal, mbp-work → work)
**After**: Configuration determined by profile selection in `config/machine-config.nix`

---

## Key Changes

### 1. Machine Identity vs Profile Behavior

**Machine Identity** (`machineId`):
- Persistent identifier for the physical machine
- NEVER changes, even if hostname changes
- Example: "mbp-jimmy-2021", "mbp-work-2024"

**Profile Behavior** (`profileName`):
- Current configuration profile
- CAN change - user switches profiles
- Options: "personal", "work", "minimal"

### 2. Directory Structure

```
OLD: home/_mixins/{personal,work}.nix
NEW: home/_profiles/{personal,work,minimal}/
```

### 3. Configuration File

```nix
# config/machine-config.nix (GITIGNORED)
{
  machineId = "mbp-jimmy-2021";    # Identity
  profileName = "personal";        # Behavior (switchable)
}
```

---

## Switching Profiles

```bash
# Switch to work profile
switch-profile work

# Switch to personal profile
switch-profile personal

# Switch to minimal (troubleshooting)
switch-profile minimal
```

---

## Setting Up New Machines

1. Copy template:
```bash
cp config/machine-config.nix.template config/machine-config.nix
```

2. Customize:
```nix
{
  machineId = "mbp-yourname-2024";  # Unique ID
  profileName = "personal";          # Initial profile
  description = "Your MacBook Pro";
  expectedHostname = "mbp-yourname";
  system = "aarch64-darwin";  # Or "x86_64-darwin"
}
```

3. Build:
```bash
darwin-rebuild switch --flake .
```

---

## Profile Comparison

| Feature | Personal | Work | Minimal |
|---------|----------|------|---------|
| **Purpose** | Learning, personal projects | Corporate, AWS, databases | Troubleshooting |
| **Packages** | Jupyter, Obsidian | AWS CLI, kubectl, terraform | Essential CLI only |
| **Aliases** | learning, ollama | AWS, database shortcuts | Basic navigation |
| **Functions** | - | awsuse, awslogin, dbconnect-* | - |
| **Starship** | Simplified, Python/Node focus | AWS/K8s prominent | No starship |
| **MACHINE_MODE** | "home" | "work" | "minimal" |

---

## Migration Timeline

- **Phase 1** (6.5h): Foundation & cleanup
- **Phase 2** (8h): Profile structure creation
- **Phase 3** (6h): Flake integration & testing
- **Phase 4** (8h): Migration & improvements

**Total**: ~28.5 hours

---

## Archived Components

Old system archived to: `archive/2025-11-mixins-system/`

Contains:
- `home/_mixins/` - Old mixin files
- `home/_template/` - Old shared base
- `README.md` - Archival documentation

---

## Troubleshooting

### "Profile not found" error
```bash
# Ensure profile directory exists
ls home/_profiles/$PROFILE/default.nix
```

### Profile switch failed
```bash
# Rollback to previous generation
nix-rollback
exec zsh
```

### Machine config not found
```bash
# Create from template
cp config/machine-config.nix.template config/machine-config.nix
# Customize and rebuild
```

---

## References

- **Project Documentation**: `claudedocs/planning/projects/profile-migration/`
- **Architecture Overview**: `docs/architecture/overview.md`
- **Usage Guide**: `docs/guides/usage.md`
EOF

# 2. Update main README.md
# Add section about profiles

# 3. Update CLAUDE.md with profile information
# Update sections 1, 6, and 9 to reference profiles

# 4. Create profile comparison diagram
# (Can be added later with ASCII art or mermaid diagram)

# 5. Commit documentation
git add docs/guides/profile-migration.md
git add README.md CLAUDE.md
git commit -m "docs: Add profile migration guide and update instructions

Comprehensive documentation of hostname→profile migration.
Includes setup guide, troubleshooting, and profile comparison.

Refs: claudedocs/planning/projects/profile-migration/"
```

**Acceptance Criteria**:
- [ ] Migration guide created in docs/guides/
- [ ] README.md updated with profile information
- [ ] CLAUDE.md updated with profile instructions
- [ ] Troubleshooting section comprehensive
- [ ] Setup instructions clear for new machines
- [ ] Profile comparison table helpful

---

## Phase 4 Completion Criteria

**All tasks complete when**:
- [ ] Old mixin system archived (Task 4.1)
- [ ] Backward compatibility code removed (Task 4.2)
- [ ] Machine detection library updated (Task 4.3)
- [ ] Starship per-profile implemented (Task 4.4)
- [ ] Migration documentation complete (Task 4.5)
- [ ] All profiles tested and stable
- [ ] Documentation comprehensive and accurate
- [ ] No technical debt from migration

**Expected State After Phase 4**:
- Clean, modern profile-based system
- No legacy code or backward compatibility
- Comprehensive documentation
- Per-profile customization (starship)
- Ready for long-term use

---

## Final Validation

After completing all 4 phases:

```bash
# 1. Test all profiles
for profile in personal work minimal; do
  echo "=== Testing $profile ==="
  ./scripts/switch-profile.sh $profile
  exec zsh
  health-check

  # Profile-specific tests
  case $profile in
    personal)
      cd ~/learning && echo "✅ Personal alias works"
      ;;
    work)
      awswho && echo "✅ AWS functions work"
      ;;
    minimal)
      g s && echo "✅ Basic git works"
      ;;
  esac
done

# 2. Verify no old system references
rg "_mixins" --type nix | grep -v archive | wc -l  # Should be 0

# 3. Check documentation
python3 scripts/check-doc-links.py  # Should pass

# 4. Full system check
nix flake check --show-trace  # Must pass
nix-rebuild && exec zsh
health-check  # Must pass

# 5. Verify git status clean
git status  # Should show clean working tree
```

---

## Post-Migration Checklist

**System Health**:
- [ ] All profiles switch without errors
- [ ] All existing functionality preserved
- [ ] No performance degradation
- [ ] Git hooks still enforcing security
- [ ] Backup/restore scripts work

**Code Quality**:
- [ ] No deprecated functions remaining
- [ ] No backward compatibility code
- [ ] No technical debt from migration
- [ ] Library functions clean and modern
- [ ] Nix syntax clean (nix flake check passes)

**Documentation**:
- [ ] Migration guide complete
- [ ] README updated
- [ ] CLAUDE.md updated
- [ ] Troubleshooting comprehensive
- [ ] All doc links valid

**Git Repository**:
- [ ] Old system archived properly
- [ ] All changes committed
- [ ] Commit messages clear and professional
- [ ] Git history clean and understandable

---

**Project Complete**: Profile migration is now finished! 🎉

**Next Steps**:
- Monitor system stability for 2-4 weeks
- Consider implementing medium-priority improvements from IMPROVEMENTS.md
- Update documentation as needed based on real-world usage
