# Phase 6: User-Agnostic Setup - Execution Plan

**Status**: 📋 Design Complete - Ready for Implementation
**Started**: 2025-11-07
**Target**: Complete user-agnostic transformation

---

## Executive Summary

Transform nix-darwin from single-user ("jimmy") to fully user-agnostic system where:
- ✅ Any user can clone and setup with minimal configuration
- ✅ Hostname changes (corporate IT) don't break the system
- ✅ Work profiles preserve user-specific customizations
- ✅ Migration-first approach imports existing configs
- ✅ VS Code extensions don't corrupt during setup
- ✅ All configs optional with graceful warnings

---

## Phase Overview

### Goals
1. Remove all hardcoded "jimmy" references
2. Support hostname-independent machine detection
3. Preserve work profile customizations
4. Graceful handling of missing configs
5. VS Code extension preservation
6. User-data directory renaming

### Scope
- **In Scope**: Variable-based configs, migration wizard, machine config system
- **Out of Scope**: Multi-user same-repo support (deferred), advanced secrets management

### Success Criteria
- [ ] New user can run `./setup.sh` and have working system
- [ ] Corporate hostname changes don't break configuration
- [ ] Work profile (24 DBs, 7 projects, AWS) preserved
- [ ] VS Code extensions don't corrupt
- [ ] Missing configs (AWS, VS Code) warn but don't fail
- [ ] All references use `${username}` variables

---

## Architecture Changes

### 1. Configuration System

**New files** (gitignored):
```
config/
├── user-config.nix         # User identity
└── machine-config.nix      # Machine identity (survives hostname changes)
```

**Templates** (committed):
```
config/
├── user-config.nix.template
└── machine-config.nix.template
```

**config/user-config.nix** (per-user):
```nix
{
  username = "jimmy";
  fullName = "Jimmy Jain";
  email = "jimmy-jain@users.noreply.github.com";
}
```

**config/machine-config.nix** (per-machine):
```nix
{
  machineId = "work-macbook-m3";        # Persistent ID
  machineType = "work";                 # or "personal"
  description = "Work MacBook Pro M3";
  expectedHostname = "mbp-work";        # Preferred (may be reset by IT)
  mixins = [ "base" "dev" "work" ];
  system = "aarch64-darwin";
}
```

### 2. Directory Structure Changes

**Before**:
```
home/jimmy/          # Hardcoded username
user-data/           # Hardcoded directory
hosts/mbp-work/      # Hostname-dependent
```

**After**:
```
home/jimmy/                    # Kept as example (not gitignored)
home/_mixins/
  ├── work.nix.template        # Minimal template (committed)
  └── work-jimmy.nix           # User-specific (gitignored)

user-data-template/            # Template (committed)
user-data-jimmy/               # User-specific (gitignored)

hosts/work-macbook-m3/         # Machine ID (not hostname)
```

### 3. Flake.nix Transformation

**OLD** (hostname-dependent):
```nix
darwinConfigurations."mbp-work" = mkDarwinSystem {
  hostname = "mbp-work";  # BREAKS when IT renames
  username = "jimmy";
  mixins = [ "base" "dev" "work" ];
};
```

**NEW** (config-driven):
```nix
let
  userConfig = import ./config/user-config.nix;
  machineConfig = import ./config/machine-config.nix;

  actualHostname = lib.fileContents (pkgs.runCommand "hostname" {} "hostname > $out");

  mkDarwinSystem = nix-darwin.lib.darwinSystem {
    system = machineConfig.system;
    specialArgs = {
      inherit inputs;
      username = userConfig.username;
      hostname = actualHostname;          # May change
      machineType = machineConfig.machineType;  # Fixed
      machineId = machineConfig.machineId;      # Persistent
      myLib = import ./lib { inherit lib pkgs; };
    };
    modules = [
      ./hosts/${machineConfig.machineId}
      ./home/_mixins/${machineConfig.machineType}.nix
      ./home/${userConfig.username}
    ];
  };
in
{
  darwinConfigurations.${machineConfig.machineId} = mkDarwinSystem;
  darwinConfigurations.${actualHostname} = mkDarwinSystem;  # Convenience
}
```

---

## Implementation Tasks

### Tier 0: SOPS Setup (MUST BE FIRST) 🔐

#### Task 6.0: SOPS Encryption Setup
**Effort**: 1-2 hours
**Priority**: 🔴 CRITICAL - MUST COMPLETE BEFORE ANY SECRETS HANDLING

**Flow**:
```bash
./setup.sh --migrate

Step 1: SOPS Encryption Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 Setting up secrets encryption...

1️⃣ Generating age encryption key...
   ✅ Age key generated: age1xyz...abc123

2️⃣ Save your encryption key!

   ⚠️  CRITICAL: Store this key securely!

   Key location: ~/.config/sops/age/keys.txt

   📋 Backup options:
      - Password manager (1Password, Bitwarden)
      - USB drive (encrypted)
      - Paper backup (secure location)

   ⚠️  Without this key, you CANNOT decrypt your secrets!

   ❓ Have you saved your key securely? (yes/no)
   → yes

3️⃣ Verifying key backup...
   ✅ Key file readable
   ✅ Key format valid
   ✅ SOPS can use this key

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SOPS setup complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 2: Secrets Migration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❓ Do you want to migrate existing secrets? (yes/no)
   → yes

🔍 Discovering secrets...

Found secrets to migrate:
  ✅ AWS credentials (~/.aws/credentials)
  ✅ SSH private keys (~/.ssh/id_*)
  ✅ Database credentials (~/.db/*)
  ✅ API tokens (~/.tokens/*)
  ✅ Git token
  ✅ HCP Terraform token
  ✅ Jira API token

❓ Migrate all discovered secrets? (yes/no/review)
   → yes

📝 Creating secrets.yaml...
   ✅ AWS credentials → encrypted
   ✅ SSH keys → encrypted
   ✅ Database credentials → encrypted
   ✅ API tokens → encrypted

🔐 Encrypting secrets.yaml with SOPS...
   ✅ File encrypted successfully

🔍 Verification...
   ✅ Can decrypt with your key
   ✅ All secrets accessible
   ✅ File is binary (encrypted)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Secrets migration complete
   Location: hosts/${machineId}/secrets.yaml
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  IMPORTANT: Keep your age key secure!
   If lost, you cannot decrypt these secrets.

Press Enter to continue with system configuration...
```

**Deliverables**:
- [ ] Generate age encryption key
- [ ] Save key to `~/.config/sops/age/keys.txt`
- [ ] **Force user confirmation** of key backup
- [ ] Display key backup instructions
- [ ] Verify key is valid and SOPS can use it
- [ ] Discover existing secrets (AWS, SSH, DB, tokens)
- [ ] Interactive review of discovered secrets
- [ ] User confirmation to proceed with migration
- [ ] Copy secrets to `secrets.yaml`
- [ ] Encrypt `secrets.yaml` with SOPS
- [ ] **Verification step**: Decrypt and verify secrets accessible
- [ ] Show encrypted file is binary format
- [ ] Block further setup until SOPS verified

**Critical Safety Checks**:
```bash
# 1. Key generation verification
if [ ! -f ~/.config/sops/age/keys.txt ]; then
  echo "❌ Age key not found!"
  exit 1
fi

# 2. Key format validation
if ! grep -q "AGE-SECRET-KEY" ~/.config/sops/age/keys.txt; then
  echo "❌ Invalid age key format!"
  exit 1
fi

# 3. User confirmation (blocking)
while true; do
  read -p "Have you saved your key securely? (yes/no): " confirm
  case $confirm in
    yes|YES|y|Y ) break ;;
    * ) echo "⚠️  Please save your key before continuing!" ;;
  esac
done

# 4. Encryption test
if ! sops -e -i hosts/${machineId}/secrets.yaml; then
  echo "❌ SOPS encryption failed!"
  exit 1
fi

# 5. Decryption verification
if ! sops -d hosts/${machineId}/secrets.yaml > /dev/null 2>&1; then
  echo "❌ Cannot decrypt with your key!"
  exit 1
fi

echo "✅ SOPS verified - proceeding with setup"
```

**Secret Discovery Logic**:
```bash
discover_secrets() {
  declare -A SECRETS

  # AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    SECRETS["aws_credentials"]="$HOME/.aws/credentials"
  fi

  # SSH keys (private only)
  for key in "$HOME/.ssh/id_"*; do
    if [ -f "$key" ] && ! [[ "$key" == *.pub ]]; then
      key_name=$(basename "$key")
      SECRETS["ssh_${key_name}"]="$key"
    fi
  done

  # Database credentials
  if [ -d "$HOME/.db" ]; then
    find "$HOME/.db" -type f | while read db_file; do
      rel_path="${db_file#$HOME/.db/}"
      SECRETS["db_${rel_path//\//_}"]="$db_file"
    done
  fi

  # API tokens
  if [ -d "$HOME/.tokens" ]; then
    for token in "$HOME/.tokens/"*; do
      if [ -f "$token" ]; then
        token_name=$(basename "$token")
        SECRETS["token_${token_name}"]="$token"
      fi
    done
  fi

  # Display discovered secrets for review
  echo ""
  echo "Found secrets to migrate:"
  for secret_key in "${!SECRETS[@]}"; do
    echo "  ✅ ${SECRETS[$secret_key]}"
  done
  echo ""
}
```

**Validation**:
```bash
# After SOPS setup:
✅ Age key exists at ~/.config/sops/age/keys.txt
✅ User confirmed key backup
✅ SOPS can encrypt files
✅ SOPS can decrypt files
✅ secrets.yaml is binary (encrypted)
✅ All discovered secrets imported

# Abort if any check fails
```

**Blocking Behavior**:
- **CANNOT proceed** to config discovery until SOPS verified
- **CANNOT proceed** without user confirming key backup
- **CANNOT proceed** if encryption/decryption fails
- **MUST verify** encrypted file is binary format

---

### Tier 1: Foundation (Critical Path)

#### Task 6.1: Configuration System Setup
**Effort**: 2-3 hours
**Priority**: 🔴 Critical

**Deliverables**:
- [ ] Create `config/user-config.nix.template`
- [ ] Create `config/machine-config.nix.template`
- [ ] Update `.gitignore` to ignore `config/*.nix` (not templates)
- [ ] Update `flake.nix` to import configs
- [ ] Pass `machineType` to all modules (replace `hostname` checks)

**Validation**:
```bash
# Should work even if hostname changes
darwin-rebuild switch --flake .
```

---

#### Task 6.2: Machine Detection Refactor
**Effort**: 2-3 hours
**Priority**: 🔴 Critical

**Deliverables**:
- [ ] Update `lib/machine-detection.nix` to use `machineType` parameter
- [ ] Replace all `hostname == "mbp-work"` with `machineType == "work"`
- [ ] Update `hosts/machines.nix` documentation (now historical reference)
- [ ] Add `machineType` parameter to all modules

**Files to update**:
- `lib/machine-detection.nix`
- `lib/default.nix`
- `modules/darwin/system.nix`
- `home/jimmy/programs/ssh.nix`
- All files using `myLib.isWork` or `myLib.isPersonal`

**Validation**:
```bash
grep -r 'hostname == "mbp' home/ modules/
# Should return 0 results
```

---

#### Task 6.3: User-Data Directory Rename
**Effort**: 1-2 hours
**Priority**: 🟡 Important

**Deliverables**:
- [ ] Create `user-data-template/` from current `user-data/`
- [ ] Update all references from `user-data/` to `user-data-${username}/`
- [ ] Update `backup.sh` to auto-detect username
- [ ] Update `restore.sh` to auto-detect username
- [ ] Add `user-data-*/` to `.gitignore`
- [ ] Rename `user-data/` → `user-data-jimmy/`

**Files to update**:
- `home/jimmy/default.nix` (secrets paths)
- `home/jimmy/shell/zsh.nix`
- `home/jimmy/programs/karabiner.nix`
- `home/jimmy/programs/vscode.nix` (comments)
- `user-data/backup.sh`
- `user-data/restore.sh`

**Validation**:
```bash
ls user-data-jimmy/
# Directory exists and is gitignored
grep -r 'user-data/' home/ --include="*.nix"
# Should only show variable-based references
```

---

### Tier 2: Migration Wizard (User Facing)

#### Task 6.4: Setup Wizard - Machine Configuration
**Effort**: 3-4 hours
**Priority**: 🟡 Important

**Deliverables**:
- [ ] Create `./setup.sh --configure-machine` command
- [ ] Interactive prompts for machine type, ID, description
- [ ] Generate `config/machine-config.nix`
- [ ] Generate `config/user-config.nix`
- [ ] Hostname setting (with corporate IT warning)

**User Flow**:
```bash
./setup.sh --configure-machine

❓ What type of machine is this?
   1) Personal Mac
   2) Work Mac
→ 2

❓ Machine ID: work-macbook-m3
❓ Description: Work MacBook Pro M3
❓ Your name: Jimmy Jain
❓ Your email: jimmy@example.com
❓ Preferred hostname: mbp-work

⚠️  Corporate IT may reset hostname
   Config survives hostname changes!

✅ Created config/user-config.nix
✅ Created config/machine-config.nix
```

---

#### Task 6.5: Config Discovery System
**Effort**: 3-4 hours
**Priority**: 🟡 Important

**Deliverables**:
- [ ] Config registry system (AWS, Git, Zsh, SSH, VS Code, etc.)
- [ ] Graceful warnings for missing configs
- [ ] Parser functions for each config type
- [ ] Backup of discovered configs
- [ ] Summary report of found/missing configs

**Discovery Output**:
```bash
./setup.sh --migrate

🔍 Discovering existing configurations...

✅ AWS configuration found
✅ Git configuration found
✅ VS Code extensions found (42 extensions)
⚠️  Starship config not found
   → Starship config will use default
⚠️  SSH config not found
   → SSH config will be generated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Discovery Summary:
✅ 7 configurations found
⚠️  3 configurations missing (will use defaults)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

#### Task 6.6: VS Code Extension Preservation
**Effort**: 2-3 hours
**Priority**: 🟡 Important

**Deliverables**:
- [ ] VS Code extension parser (list existing extensions)
- [ ] Filter nixpkgs-available vs marketplace extensions
- [ ] Generate `vscode.nix` with only nixpkgs extensions
- [ ] Documentation: how to add marketplace extensions

**Preservation Strategy**:
- Nix manages: Extensions available in nixpkgs (symlinks)
- User manages: Marketplace extensions (regular directories)
- No cleanup: Both coexist peacefully

**Output**:
```bash
✅ VS Code configuration:
   - Nixpkgs extensions: 12 managed by Nix
   - Marketplace extensions: 30 remain in ~/.vscode/extensions/
   Total: 42 extensions preserved
```

---

#### Task 6.7: Work Profile Migration
**Effort**: 4-5 hours
**Priority**: 🔴 Critical (for work machine)

**Deliverables**:
- [ ] Project directory discovery (~/Dev/)
- [ ] Database connection discovery (~/.db/)
- [ ] AWS accounts.json import
- [ ] Custom shell function extraction
- [ ] Generate `work-jimmy.nix` from discovered config
- [ ] Template `work.nix.template` for new users

**Migration Logic**:
```bash
# For work machines:
🏢 Work machine detected

📊 Analyzing work environment...
  ✅ Found 7 project directories
  ✅ Found 24 database connections (6 instances × 4 envs)
  ✅ Found ~/.aws/accounts.json (12 accounts)
  ✅ Found 3 custom shell functions

📝 Creating work-jimmy.nix...
  - Project aliases: 7 generated
  - Database instances: 6 configured
  - AWS accounts: 12 imported
  - Custom functions: 3 preserved

🔒 Added work-jimmy.nix to .gitignore
   → Your work setup stays private
```

---

### Tier 3: Polish & Documentation

#### Task 6.8: ~~SOPS Setup Integration~~ → MOVED TO TIER 0
**Status**: ✅ Moved to Task 6.0 (Tier 0)
**Reason**: SOPS must be set up FIRST before any secrets handling

**Note**: See Task 6.0 for complete SOPS setup design including:
- Age key generation
- User confirmation of key backup
- Secret discovery and migration
- Encryption verification
- Blocking until SOPS verified

---

#### Task 6.9: Documentation Updates
**Effort**: 3-4 hours
**Priority**: 🟡 Important

**Deliverables**:
- [ ] Update `docs/guides/installation.md` with new setup flow
- [ ] Create `docs/guides/multi-machine-setup.md`
- [ ] Update `CLAUDE.md` with Phase 6 changes
- [ ] Update `README.md` with setup wizard examples
- [ ] Create `config/README.md` explaining config system

**Documentation Coverage**:
- Setup wizard usage
- Machine configuration
- Work profile customization
- Hostname change handling
- Multi-machine deployment

---

#### Task 6.10: Testing & Validation
**Effort**: 2-3 hours
**Priority**: 🔴 Critical

**Test Scenarios**:
- [ ] Fresh machine setup (no existing config)
- [ ] Migration from existing setup (all configs present)
- [ ] Migration with missing configs (graceful warnings)
- [ ] Work machine setup (database, AWS, projects)
- [ ] Personal machine setup
- [ ] Hostname change simulation
- [ ] Multi-machine deployment (clone to second Mac)

**Validation Commands**:
```bash
# Test 1: Fresh setup
./setup.sh --fresh

# Test 2: Migration
./setup.sh --migrate

# Test 3: Machine config only
./setup.sh --configure-machine

# Test 4: Hostname change
sudo scutil --set HostName different-name
darwin-rebuild switch --flake .
# Should still work!

# Test 5: Multi-machine
# On second Mac:
git clone <repo>
./setup.sh --configure-machine
# Different machineId but same username
```

---

## Dependencies

### External Dependencies
- SOPS (age) for secrets encryption
- Existing nix-darwin installation
- Git for version control

### Internal Dependencies
- Phase 2: Machine detection system (completed)
- Phase 3: Template system (completed)
- Phase 5: Documentation system (completed)

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Corporate IT resets hostname | High | High | Use persistent machineType |
| Work profile too complex to migrate | High | Medium | Two-tier system (template + user-specific) |
| VS Code extensions corrupt | High | Medium | Selective management (nixpkgs only) |
| Missing configs break build | Medium | High | Graceful warnings, optional configs |
| Multi-machine sync issues | Medium | Low | Separate config files per machine |
| Secrets migration complexity | Medium | Medium | SOPS integration with wizard |

---

## Rollback Plan

**If Phase 6 fails**:
1. Revert flake.nix to use hardcoded values
2. Keep user-data/ as-is (don't rename)
3. Fall back to hostname-based detection
4. Document manual migration steps

**Checkpoint Strategy**:
- Git commit after each tier completion
- Tag: `phase-6-tier-1`, `phase-6-tier-2`, `phase-6-tier-3`
- Keep backlog item for "True User-Agnostic" if pivot needed

---

## Timeline Estimate

| Tier | Tasks | Effort | Duration |
|------|-------|--------|----------|
| **Tier 0** | **6.0 (SOPS)** | **1-2 hours** | **0.5 day** |
| Tier 1 | 6.1-6.3 | 5-8 hours | 1-2 days |
| Tier 2 | 6.4-6.7 | 12-16 hours | 2-3 days |
| Tier 3 | 6.9-6.10 | 5-7 hours | 1-2 days |
| **Total** | **11 tasks** | **23-33 hours** | **4-7 days** |

**Critical Path**: Task 6.0 (SOPS) MUST complete before any other tasks

---

## Validation Checkpoints

### After Tier 0 (SOPS) - MUST PASS BEFORE CONTINUING
- [ ] Age key generated and saved
- [ ] User confirmed key backup
- [ ] SOPS can encrypt test file
- [ ] SOPS can decrypt encrypted file
- [ ] All discovered secrets copied to secrets.yaml
- [ ] secrets.yaml encrypted (binary format)
- [ ] Can decrypt secrets.yaml with age key
- [ ] 🚨 **BLOCKING**: Cannot proceed to Tier 1 until all checks pass

### After Tier 1
- [ ] Build succeeds with machineType-based detection
- [ ] Hostname change doesn't break system
- [ ] user-data directory renamed and working

### After Tier 2
- [ ] Setup wizard creates valid configs
- [ ] Migration preserves all existing settings
- [ ] VS Code extensions preserved
- [ ] Work profile (24 DBs, 7 projects) migrated

### After Tier 3
- [ ] SOPS encrypts secrets successfully
- [ ] Documentation complete
- [ ] All test scenarios pass

---

## Related Documents

- [PHASE-6-MACHINE-CONFIG-DESIGN.md](./PHASE-6-MACHINE-CONFIG-DESIGN.md) - Machine configuration system
- [PHASE-6-USER-DATA-RENAME.md](./PHASE-6-USER-DATA-RENAME.md) - User-data directory renaming
- [BACKLOG.md](./BACKLOG.md) - Original feature request (Backlog item)

---

## Success Metrics

**Quantitative**:
- Zero hardcoded "jimmy" references in code
- 100% config discovery without failures
- All test scenarios pass
- Build time unchanged (<2 minutes)

**Qualitative**:
- New user can setup in <10 minutes
- Hostname changes handled transparently
- Work profiles preserved without data loss
- Documentation clear and complete

---

**Status**: 📋 Design Phase Complete
**Next Step**: Begin Tier 1 implementation
**Owner**: To be determined during implementation
