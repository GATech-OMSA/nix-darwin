# Phase 1: Foundation & Cleanup - Profile Migration

**Duration**: ~6.5 hours
**Prerequisites**: None
**Risk Level**: Low (no functional changes)

---

## Overview

Phase 1 establishes a clean foundation by fixing technical debt and preparing the codebase for profile-based architecture. All changes are backward-compatible and preserve existing functionality.

---

## Tasks

### Task 1.1: Remove Alias Duplication
**Effort**: 30 minutes
**Priority**: High
**Risk**: Low

**Problem**: `learning` and `ollama` aliases duplicated in both `zsh.nix` and `personal.nix`

**Current State**:
- `zsh.nix` lines 199-204: learning, aiml, algo, courses, experiments, oss
- `zsh.nix` lines 331-334: ollama-start, models, llama3, codellama
- `personal.nix` lines 78-82: learning, courses, experiments, oss, aiml (duplicates)
- `personal.nix` lines 106-109: ollama-start, models, llama3, codellama (duplicates)

**Action**:
```bash
# 1. Edit home/_template/shell/zsh.nix
# Remove lines 199-204 (learning aliases)
# Remove lines 331-334 (ollama aliases)

# 2. Edit home/_mixins/personal.nix
# Add missing 'algo' alias:
algo = "cd ~/Dev/algorithms";

# 3. Rebuild and test
nix-rebuild && exec zsh
cd ~/learning  # Should work via personal.nix
ollama-start   # Should work via personal.nix
cd ~/Dev/algorithms  # Should work via new algo alias
```

**Acceptance Criteria**:
- [ ] Learning aliases exist ONLY in personal.nix
- [ ] Ollama aliases exist ONLY in personal.nix
- [ ] Algo alias added to personal.nix
- [ ] All aliases work after rebuild
- [ ] No duplication detected in grep search

**Validation**:
```bash
# Should find in personal.nix only
rg "learning.*cd.*learning" home/

# Should find algo in personal.nix
rg "algo.*algorithms" home/_mixins/personal.nix
```

---

### Task 1.2: Fix Broken Documentation Links
**Effort**: 2 hours
**Priority**: High
**Risk**: Low

**Problem**: Pre-commit hook blocks commits when doc links are broken

**Current State**: `scripts/check-doc-links.py` validates all markdown links

**Action**:
```bash
# 1. Run validation
python3 scripts/check-doc-links.py

# 2. Fix any broken links found in:
# - docs/*.md
# - claudedocs/**/*.md
# - README.md
# - CLAUDE.md

# 3. Update relative paths if files moved
# 4. Remove links to deleted files
# 5. Add missing referenced files

# 6. Verify fix
python3 scripts/check-doc-links.py  # Should pass
```

**Acceptance Criteria**:
- [ ] All documentation links resolve correctly
- [ ] Pre-commit hook passes doc validation
- [ ] No broken internal references
- [ ] README.md links work
- [ ] CLAUDE.md links work

**Validation**:
```bash
python3 scripts/check-doc-links.py && echo "✅ All links valid"
```

---

### Task 1.3: Harden Git Hooks to Blocking Mode
**Effort**: 1 hour
**Priority**: High
**Risk**: Low

**Problem**: Security validation should be mandatory, not advisory

**Current State**: `.git/hooks/pre-commit` has 4 validation layers (documented in NOTES.md lines 1682-1900)

**Action**:
```bash
# 1. Review .git/hooks/pre-commit
cat .git/hooks/pre-commit

# 2. Ensure all validations have 'exit 1' on failure:
# - Nix syntax validation
# - File permission checks
# - SOPS encryption validation
# - Documentation link validation

# 3. Test blocking behavior
echo "test" > ~/.db/test_unencrypted
git add ~/.db/test_unencrypted
git commit -m "test"  # Should BLOCK

# 4. Clean up test
rm ~/.db/test_unencrypted
```

**Acceptance Criteria**:
- [ ] Nix syntax errors block commits
- [ ] Permission violations (not 600) block commits
- [ ] Unencrypted secrets block commits
- [ ] Broken doc links block commits
- [ ] No bypass mechanisms exist

**Validation**:
```bash
# Test each validation layer blocks
./scripts/test-git-hooks.sh  # Should pass all blocking tests
```

---

### Task 1.4: Create Secret Path Registry
**Effort**: 3 hours
**Priority**: High
**Risk**: Medium

**Problem**: Secret paths scattered across multiple files, no single source of truth

**Current State**:
- Git hooks check specific paths (hardcoded)
- User-data backup/restore has separate lists
- No centralized registry

**Action**:
```bash
# 1. Create lib/secrets-registry.nix
cat > lib/secrets-registry.nix << 'EOF'
# lib/secrets-registry.nix
#
# Centralized registry of all secret paths in the system.
# Used by: git hooks, backup/restore, permission validators

{ lib }:

{
  # Secret file paths that must be encrypted with SOPS
  sopsSecretPaths = [
    "user-data/secrets/credentials.env"
    "user-data/secrets/api-keys.env"
    ".aws/credentials"
  ];

  # Secret directories with sensitive files
  secretDirectories = [
    "~/.db"
    "~/.tokens"
    "~/.aws"
  ];

  # File permissions requirements
  permissionRequirements = {
    "~/.db/*" = "600";
    "~/.tokens/*" = "600";
    ".aws/credentials" = "600";
  };

  # Files that must exist with specific content patterns
  requiredSecretPatterns = {
    "user-data/secrets/credentials.env" = {
      mustContain = [ "sops:" "mac:" "ENC[" ];
      description = "SOPS encrypted credentials";
    };
  };

  # Generate validation function for git hooks
  mkSecretValidator = { secretPaths, directories, permissions }:
    ''
      # Generated secret validation logic
      # Called by: .git/hooks/pre-commit
    '';
}
EOF

# 2. Update .git/hooks/pre-commit to use registry
# 3. Update scripts/check-secrets-encrypted.sh to use registry
# 4. Update user-data/backup.sh to use registry

# 5. Rebuild and test
nix-rebuild
./scripts/validate-secret-registry.sh
```

**Acceptance Criteria**:
- [ ] lib/secrets-registry.nix created
- [ ] All secret paths documented in one place
- [ ] Git hooks use registry for validation
- [ ] Backup scripts use registry for file lists
- [ ] Permission validator uses registry
- [ ] No hardcoded secret paths remain

**Validation**:
```bash
# Should find no hardcoded secret paths
rg "\.db|\.tokens|credentials" .git/hooks/ scripts/ \
  --type-not nix | wc -l  # Should be 0

# Registry should be imported
rg "secrets-registry" .git/hooks/pre-commit
```

---

## Phase 1 Completion Criteria

**All tasks complete when**:
- [ ] No alias duplication (Task 1.1)
- [ ] All documentation links valid (Task 1.2)
- [ ] Git hooks block all security violations (Task 1.3)
- [ ] Secret paths centralized in registry (Task 1.4)
- [ ] Full system rebuild succeeds: `nix-rebuild`
- [ ] All tests pass: `./scripts/health-check.sh`

**Expected State After Phase 1**:
- Clean, DRY alias structure
- Valid documentation with working links
- Hardened security validation
- Centralized secret management
- Zero technical debt blocking Phase 2

**Dependencies for Phase 2**:
- None - Phase 1 is independent

---

## Rollback Plan

If Phase 1 causes issues:

```bash
# 1. Rollback to previous generation
nix-rollback

# 2. Restore shell
exec zsh

# 3. Verify system working
health-check
```

**Risk Mitigation**:
- All changes are additive (removal of duplication doesn't break functionality)
- Secret registry is new - doesn't modify existing secrets
- Git hooks are already present - just hardening
- Documentation fixes don't affect code

---

## Testing Checklist

After completing Phase 1:

```bash
# 1. Alias functionality
cd ~/learning        # Should work
ollama-start        # Should work
cd ~/Dev/algorithms # Should work (new algo alias)

# 2. Documentation
./scripts/check-doc-links.sh  # Should pass

# 3. Security
echo "test" > ~/.db/unencrypted
git add ~/.db/unencrypted
git commit -m "test"  # Should BLOCK
rm ~/.db/unencrypted

# 4. Secret registry
./scripts/validate-secret-registry.sh  # Should pass

# 5. Full system
nix-rebuild  # Should succeed
exec zsh     # Should load without errors
health-check # Should pass all checks
```

---

**Next Phase**: [Phase 2: Profile Structure Creation](PHASE-2-STRUCTURE.md)
