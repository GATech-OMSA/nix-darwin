# Phase 6: User-Agnostic Setup - Design Summary

**Date**: 2025-11-07
**Status**: ✅ Design Complete - Ready for Implementation

---

## What We Solved

### 1. Corporate Hostname Reset Problem ✅
**Problem**: Corporate IT resets hostname → breaks configuration

**Solution**: Persistent machine config file
```nix
config/machine-config.nix:
  machineId = "work-macbook-m3"      # Persistent ID
  machineType = "work"               # Survives renames
  expectedHostname = "mbp-work"      # Just a preference
```

**Build command** (works even after hostname change):
```bash
darwin-rebuild switch --flake .
```

---

### 2. VS Code Extension Corruption ✅
**Problem**: Reinstalling extensions corrupts them

**Solution**: Selective management
- **Nix manages**: Only nixpkgs-available extensions (symlinks)
- **User manages**: Marketplace extensions (regular directories)
- **No cleanup**: Both coexist peacefully

**Result**: 42 extensions preserved (12 Nix + 30 marketplace)

---

### 3. Work Profile Preservation ✅
**Problem**: Work profile too specific (24 DBs, 7 projects, AWS accounts)

**Solution**: Two-tier work profile system
```
home/_mixins/
├── work.nix.template    # Minimal template (committed)
└── work-jimmy.nix       # Your specific config (gitignored)
```

**Migration** discovers and preserves:
- 24 database connections (6 instances × 4 environments)
- 7 project directory aliases
- AWS accounts.json (12 accounts)
- Custom shell functions (crypter, database connectors)

---

### 4. Graceful Config Discovery ✅
**Problem**: Missing configs (AWS, VS Code) shouldn't fail setup

**Solution**: Optional config registry with warnings
```bash
🔍 Discovering existing configurations...

✅ AWS configuration found
✅ Git configuration found
⚠️  Starship config not found
   → Starship config will use default

━━━━━━━━━━━━━━━━━━━━━━━━━
Discovery Summary:
✅ 7 configurations found
⚠️  3 configurations missing (will use defaults)
━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### 5. User-Data Directory Renaming ✅
**Problem**: Hardcoded `user-data/` directory

**Solution**: Username-based naming
```
user-data-template/    # Template (committed)
user-data-jimmy/       # User-specific (gitignored)
```

All references use `${username}` variable.

---

## Design Documents Created

1. **[PHASE-6-MACHINE-CONFIG-DESIGN.md](./PHASE-6-MACHINE-CONFIG-DESIGN.md)** (303 lines)
   - Machine configuration system
   - Hostname-independent detection
   - Build command changes

2. **[PHASE-6-USER-DATA-RENAME.md](./PHASE-6-USER-DATA-RENAME.md)** (344 lines)
   - User-data directory renaming
   - Variable-based references
   - Migration flow

3. **[PHASE-6-EXECUTION-PLAN.md](./PHASE-6-EXECUTION-PLAN.md)** (507 lines)
   - Comprehensive implementation plan
   - 10 tasks across 3 tiers
   - Timeline: 24-34 hours (4-7 days)

**Total Design Documentation**: 1,154 lines

---

## Key Architecture Changes

### Configuration System

**NEW**:
```
config/
├── user-config.nix          # User identity (gitignored)
├── machine-config.nix       # Machine identity (gitignored)
├── user-config.nix.template
└── machine-config.nix.template
```

### Directory Structure

**Before**:
```
home/jimmy/          # Hardcoded
user-data/           # Hardcoded
hosts/mbp-work/      # Hostname-dependent
```

**After**:
```
home/jimmy/                    # Example (kept)
home/_mixins/work-jimmy.nix    # User-specific (gitignored)
user-data-jimmy/               # User-specific (gitignored)
hosts/work-macbook-m3/         # Machine ID (persistent)
```

### Flake.nix

**Before**:
```nix
darwinConfigurations."mbp-work" = mkDarwinSystem {
  hostname = "mbp-work";  # BREAKS
  username = "jimmy";
};
```

**After**:
```nix
let
  userConfig = import ./config/user-config.nix;
  machineConfig = import ./config/machine-config.nix;
in {
  darwinConfigurations.${machineConfig.machineId} = mkDarwinSystem {
    machineType = machineConfig.machineType;  # Survives renames!
  };
}
```

---

## Implementation Plan

### Tier 0: SOPS Setup (1-2 hours) 🔐 MUST BE FIRST
- **Task 6.0: SOPS encryption setup**
  - Generate age key
  - Force user confirmation of backup
  - Discover existing secrets
  - Migrate to secrets.yaml
  - Encrypt with SOPS
  - Verify encryption/decryption
  - 🚨 **BLOCKING**: Must complete before any other tasks

### Tier 1: Foundation (5-8 hours)
- Task 6.1: Configuration system setup
- Task 6.2: Machine detection refactor
- Task 6.3: User-data directory rename

### Tier 2: Migration Wizard (12-16 hours)
- Task 6.4: Setup wizard - machine configuration
- Task 6.5: Config discovery system
- Task 6.6: VS Code extension preservation
- Task 6.7: Work profile migration

### Tier 3: Polish (5-7 hours)
- Task 6.9: Documentation updates
- Task 6.10: Testing & validation

**Total Effort**: 23-33 hours over 4-7 days
**Critical Path**: Task 6.0 must complete first

---

## User Workflows

### SOPS Setup (MUST BE FIRST) 🔐

```bash
./setup.sh --migrate

Step 1: SOPS Encryption Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 Generating age key...
   ✅ Age key: age1xyz...abc123
   ✅ Saved to: ~/.config/sops/age/keys.txt

⚠️  CRITICAL: Save your key securely!
   (Password manager, USB drive, paper backup)

❓ Have you saved your key securely? (yes/no)
   → yes

✅ SOPS verified

Step 2: Secrets Migration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Found 7 secrets to migrate:
  ✅ AWS credentials
  ✅ SSH keys (3 keys)
  ✅ Database credentials (24 files)
  ✅ API tokens (3 tokens)

❓ Migrate all? (yes/no)
   → yes

📝 Creating secrets.yaml...
🔐 Encrypting with SOPS...
✅ Verification passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Secrets setup complete
   Cannot proceed without this step!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Setup Wizard

```bash
./setup.sh --configure-machine

❓ Machine type: work
❓ Machine ID: work-macbook-m3
❓ Your name: Jimmy Jain
❓ Your email: jimmy@example.com
❓ Preferred hostname: mbp-work

⚠️  Corporate IT may reset hostname
   Config survives hostname changes!

✅ Created config/user-config.nix
✅ Created config/machine-config.nix
```

### Migration Flow

```bash
./setup.sh --migrate

🔍 Discovering existing configurations...
  ✅ Found 7 configurations
  ⚠️  3 missing (will use defaults)

🏢 Work machine detected
  ✅ Found 7 project directories
  ✅ Found 24 database connections
  ✅ Found AWS accounts.json

📝 Creating work-jimmy.nix...
  ✅ All work configs preserved

✅ Migration complete!
```

### Build Command

```bash
# Works regardless of hostname
darwin-rebuild switch --flake .

# Or explicitly by machine ID
darwin-rebuild switch --flake .#work-macbook-m3
```

---

## Benefits Achieved

1. ✅ **Hostname-independent**: Survives corporate IT renames
2. ✅ **User-agnostic**: Any user can clone and setup
3. ✅ **Work profile preservation**: All 24 DBs, projects, AWS kept
4. ✅ **VS Code safe**: No extension corruption
5. ✅ **Graceful degradation**: Missing configs warn, don't fail
6. ✅ **Multi-machine ready**: Same user, multiple machines
7. ✅ **Migration-first**: Imports existing setup instead of from-scratch
8. ✅ **Template-based**: Clean starting point for new users

---

## Next Steps

1. **Update PROGRESS.md**: Add Phase 6 tasks (10 tasks)
2. **Begin Implementation**: Start with Tier 1 (foundation)
3. **Create Feature Branch**: `git checkout -b feature/phase-6-user-agnostic`
4. **Incremental Commits**: Commit after each task completion

---

## Questions Answered

**Q: What if corporate IT renames my hostname?**
A: System uses `machineType` from config file, not hostname. Works fine!

**Q: Will my work profile be lost?**
A: No - migration creates `work-jimmy.nix` with all 24 DBs, projects, AWS accounts.

**Q: What about my VS Code extensions?**
A: Preserved - Nix manages nixpkgs extensions, user extensions stay untouched.

**Q: What if I don't have AWS configured?**
A: Graceful warning, uses defaults. Can configure later.

**Q: Can I use this on multiple Macs?**
A: Yes - each Mac gets own `machine-config.nix`, same `user-config.nix`.

---

**Design Status**: ✅ Complete
**Implementation Status**: 📋 Ready to Begin
**Estimated Completion**: 4-7 days (24-34 hours)
