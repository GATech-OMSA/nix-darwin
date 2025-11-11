# Profile Migration Implementation Plan

**Project**: profile-migration
**Created**: 2025-11-09
**Status**: Ready for Implementation
**Total Estimated Effort**: ~28.5 hours

---

## Executive Summary

This plan details the complete migration from hostname-based configuration to profile-based architecture for the nix-darwin system. The migration is divided into 4 phases with 14 total tasks, designed to prevent context loss and ensure all functionality is preserved.

**Key Objectives**:
1. Fix build failures from gitignored directories
2. Enable profile switching (personal ↔ work ↔ minimal)
3. Preserve ALL existing functionality
4. Improve configuration where opportunities exist
5. Comprehensive documentation

---

## Phase Overview

| Phase | Focus | Duration | Risk | Prerequisites |
|-------|-------|----------|------|---------------|
| **Phase 1** | Foundation & Cleanup | 6.5h | Low | None |
| **Phase 2** | Profile Structure | 8h | Medium | Phase 1 |
| **Phase 3** | Flake Integration | 6h | High | Phase 1, 2 |
| **Phase 4** | Migration & Improvements | 8h | Medium | Phase 1, 2, 3 |

**Total**: 28.5 hours

---

## Phase 1: Foundation & Cleanup

**Goal**: Establish clean foundation by fixing technical debt

**Duration**: 6.5 hours
**Risk**: Low (no functional changes)

### Tasks

1. **Remove Alias Duplication** (30 min)
   - Problem: `learning` and `ollama` aliases duplicated in zsh.nix + personal.nix
   - Action: Keep in personal.nix only, remove from zsh.nix
   - Add missing `algo` alias to personal.nix

2. **Fix Broken Documentation Links** (2h)
   - Problem: Pre-commit hook blocks on broken links
   - Action: Run validation, fix all broken links
   - Verify: `python3 scripts/check-doc-links.py` passes

3. **Harden Git Hooks** (1h)
   - Problem: Security validation should be mandatory
   - Action: Ensure all validations have `exit 1` on failure
   - Test: Attempt to commit unencrypted secret (should block)

4. **Create Secret Path Registry** (3h)
   - Problem: Secret paths scattered across files
   - Action: Create `lib/secrets-registry.nix` with centralized paths
   - Update: Git hooks, backup scripts to use registry

**Completion Criteria**:
- Zero alias duplication
- All documentation links valid
- Git hooks block security violations
- Secret paths centralized

**Deliverables**: [PHASE-1-FOUNDATION.md](PHASE-1-FOUNDATION.md)

---

## Phase 2: Profile Structure Creation

**Goal**: Create profile directory structure and migrate existing functionality

**Duration**: 8 hours
**Risk**: Medium (structural changes)

### Directory Structure

```
home/_profiles/
├── personal/           # Personal/learning profile
│   ├── default.nix
│   ├── packages.nix
│   ├── aliases.nix
│   ├── starship.toml
│   └── programs/
├── work/              # Work profile (AWS, databases)
│   ├── default.nix
│   ├── packages.nix
│   ├── aliases.nix
│   ├── aws.nix        # AWS multi-role system
│   ├── database.nix   # Database connectors
│   ├── starship.toml
│   └── programs/
├── minimal/           # Minimal troubleshooting profile
│   ├── default.nix
│   ├── packages.nix
│   └── aliases.nix
└── _template/         # Shared base (replaces home/_template)
    ├── programs/
    └── shell/
```

### Tasks

1. **Create Directory Structure** (30 min)
   - Create all profile directories
   - Add .gitkeep files
   - Verify structure with `tree`

2. **Create Personal Profile** (2h)
   - Migrate from `home/_mixins/personal.nix` (18 aliases, 7 packages)
   - Create default.nix, packages.nix, aliases.nix
   - Copy starship.toml
   - Add missing `algo` alias

3. **Create Work Profile** (3h)
   - Migrate from `home/_mixins/work.nix` (445 lines!)
   - Preserve AWS multi-role system (8 functions)
   - Preserve 6 database instance connectors
   - Work-specific aliases and packages
   - Work-optimized starship (AWS-prominent)

4. **Create Minimal Profile** (1h)
   - Essential packages only (coreutils, git, vim, curl, wget)
   - Basic aliases only
   - No starship (basic prompt)

5. **Move Shared Base** (1.5h)
   - Copy `home/_template` to `home/_profiles/_template`
   - Keep original for backward compatibility
   - Update profile imports

**Completion Criteria**:
- All profile directories exist
- Personal profile complete with all aliases/packages
- Work profile preserves AWS & database systems
- Minimal profile functional
- All profiles validate with `nix-instantiate`

**Deliverables**: [PHASE-2-STRUCTURE.md](PHASE-2-STRUCTURE.md)

---

## Phase 3: Flake Integration

**Goal**: Integrate profiles into flake.nix and enable profile switching

**Duration**: 6 hours
**Risk**: High (modifies system entry point)

### Architecture Change

**Before**:
```
flake.nix → hosts/ → home/jimmy/ → home/_mixins/personal.nix  (by hostname)
```

**After**:
```
flake.nix → config/machine-config.nix → home/_profiles/personal/  (by config)
```

### Tasks

1. **Machine Configuration System** (1.5h)
   - Create `config/machine-config.nix` (GITIGNORED)
   - Create `config/machine-config.nix.template` (COMMITTED)
   - Add to .gitignore
   - Validation script

2. **Update flake.nix** (2h)
   - Read `config/machine-config.nix`
   - Extract `profileName` and `machineId`
   - Pass to modules as `specialArgs`
   - Import `home/_profiles/${profileName}`
   - Backward compatibility aliases

3. **Update home/jimmy/default.nix** (1h)
   - Accept `profileName` and `machineId` parameters
   - Remove direct mixin imports
   - Add session variables (ACTIVE_PROFILE, MACHINE_ID)

4. **Profile Switcher Script** (1h)
   - Create `scripts/switch-profile.sh`
   - Validates profile argument
   - Updates `machine-config.nix`
   - Rebuilds system
   - Rollback on failure

5. **End-to-End Testing** (30 min)
   - Test switching to each profile
   - Verify profile-specific features
   - Check environment variables
   - Full health check

**Completion Criteria**:
- Machine config system working
- flake.nix reads config and selects profile
- Profile switching functional
- All profiles tested
- No functionality lost

**Deliverables**: [PHASE-3-INTEGRATION.md](PHASE-3-INTEGRATION.md)

---

## Phase 4: Migration & Cleanup

**Goal**: Archive old system and implement improvements

**Duration**: 8 hours
**Risk**: Medium (cleanup and improvements)

### Tasks

1. **Archive Old Mixin System** (1h)
   - Move `home/_mixins/` to `archive/2025-11-mixins-system/`
   - Move `home/_template/` to archive
   - Create archive README
   - Commit archival
   - Verify system works without old directories

2. **Remove Backward Compatibility** (1h)
   - Remove hostname aliases from flake.nix
   - Update rebuild instructions
   - Update scripts to use machineId

3. **Update Machine Detection** (2h)
   - Remove deprecated functions from `lib/machine-detection.nix`
   - Update all consumers to new API
   - Remove: `getMachineType`, `isPersonal`, `isWork`
   - Keep: `isPersonalType`, `isWorkType`, `selectByMachineType`

4. **Starship Per-Profile** (2h)
   - Personal: Simplified, Python/Node focus
   - Work: AWS/Kubernetes prominent, enterprise languages
   - Minimal: No starship (basic prompt)
   - Test visual differences

5. **Migration Documentation** (2h)
   - Create `docs/guides/profile-migration.md`
   - Update README.md
   - Update CLAUDE.md
   - Profile comparison table
   - Troubleshooting guide

**Completion Criteria**:
- Old system archived
- No backward compatibility code
- Machine detection modernized
- Starship customized per profile
- Documentation comprehensive

**Deliverables**: [PHASE-4-MIGRATION.md](PHASE-4-MIGRATION.md)

---

## Functional Preservation Checklist

### AWS Multi-Role System (Work Profile)
- [ ] `awsuse` function (profile selection)
- [ ] `awslogin` function (SSO authentication)
- [ ] `awswho` function (identity check)
- [ ] `mkAwsAccountHelper` integration
- [ ] `mkAwsInfoCommands` integration
- [ ] Dynamic alias generation (tidev, tisbx, etc.)
- [ ] Last profile restoration
- [ ] accounts.json driven configuration

### Database Connectivity (Work Profile)
- [ ] 6 database instances preserved
- [ ] `dbconnect-*` functions for all instances
- [ ] Environment variable pattern (INSTANCE_ENV_TYPE)
- [ ] Support for: oracle, mssql, postgres, mysql
- [ ] Token helper functionality

### Shell Functionality
- [ ] 150+ aliases preserved
- [ ] 80+ functions preserved
- [ ] Oh-My-Zsh plugins (17+)
- [ ] Auto-activation (UV, Micromamba)
- [ ] Cleanup system (5 tiers)
- [ ] Update functions

### Development Tools
- [ ] Modern CLI tools (eza, bat, ripgrep, fd, dust, duf, btop)
- [ ] Python (UV package manager)
- [ ] Node.js (nvm)
- [ ] Micromamba (conda-compatible)
- [ ] Git (80+ aliases)
- [ ] VS Code
- [ ] Starship prompt

### Security
- [ ] Git pre-commit hook (4 validations)
- [ ] Git pre-push hook (binary check)
- [ ] SOPS encryption enforcement
- [ ] File permission checks (600)
- [ ] Secret path validation
- [ ] Documentation link validation

### Profile-Specific Features
**Personal**:
- [ ] Learning aliases (learning, aiml, algo, courses, experiments, oss)
- [ ] Ollama aliases (ollama-start, models, llama3, codellama)
- [ ] Personal packages (jupyter, obsidian)
- [ ] Simplified starship

**Work**:
- [ ] AWS functions (see above)
- [ ] Database connectors (see above)
- [ ] Work navigation (work, repos, infra, docs)
- [ ] Enterprise packages (kubectl, terraform, awscli2)
- [ ] Work-prominent starship (AWS, K8s)

**Minimal**:
- [ ] Essential CLI only
- [ ] Basic git aliases
- [ ] No advanced features

---

## Risk Management

### High-Risk Areas

1. **Flake.nix Modification** (Phase 3)
   - Risk: System entry point changes could break builds
   - Mitigation: Backup flake.nix, test with `nix flake check`, rollback plan
   - Rollback: `cp flake.nix.backup flake.nix && nix-rollback`

2. **AWS Multi-Role System** (Phase 2, Task 2.3)
   - Risk: Complex 445-line work.nix with AWS/database integration
   - Mitigation: Careful migration preserving all functions, extensive testing
   - Validation: Test all AWS functions after migration

3. **Machine Detection Library** (Phase 4, Task 4.3)
   - Risk: Breaking changes to widely-used library
   - Mitigation: Audit all usages first, update systematically
   - Validation: Full system rebuild after changes

### Medium-Risk Areas

1. **Profile Structure Creation** (Phase 2)
   - Risk: Missing functionality during migration
   - Mitigation: Comprehensive audit (already done), checklists
   - Validation: Compare old vs new line-by-line

2. **Profile Switching** (Phase 3)
   - Risk: Profile switching might break active system
   - Mitigation: Test thoroughly before archiving old system
   - Validation: Switch between all profiles multiple times

### Low-Risk Areas

1. **Foundation Cleanup** (Phase 1)
   - Risk: Minimal, mostly DRY improvements
   - Mitigation: All changes are additive or remove duplication

2. **Documentation** (Phase 4)
   - Risk: None (documentation only)
   - Mitigation: Review for accuracy

---

## Testing Strategy

### Phase-Level Testing

**After Each Phase**:
```bash
# 1. Nix validation
nix flake check --show-trace  # Must pass

# 2. System rebuild
nix-rebuild  # Must succeed

# 3. Shell restart
exec zsh  # Must load without errors

# 4. Health check
health-check  # All checks must pass
```

### Profile-Specific Testing

**For Each Profile** (Phase 3 onwards):
```bash
# 1. Switch profile
./scripts/switch-profile.sh [profile]
exec zsh

# 2. Check environment
echo $ACTIVE_PROFILE     # Should match
echo $MACHINE_MODE       # Should match

# 3. Test profile features
# Personal: cd ~/learning, ollama-start
# Work: awswho, dbconnect-ti
# Minimal: g s

# 4. Health check
health-check
```

### Functionality Testing

**Critical Functions** (After Phase 2):
```bash
# AWS (work profile)
awsuse
awslogin
awswho

# Database (work profile)
dbconnect-ti
dbconnect-hrdb

# Shell
cleanup-quick
update-nix

# Git
g s
g aa && g cm "test" && g ps
```

### Security Testing

**Git Hooks** (After Phase 1):
```bash
# Test blocking
echo "test" > ~/.db/unencrypted
git add ~/.db/unencrypted
git commit -m "test"  # Should BLOCK
rm ~/.db/unencrypted

# Test permissions
touch ~/.db/test_file
chmod 644 ~/.db/test_file
git add ~/.db/test_file
git commit -m "test"  # Should BLOCK
rm ~/.db/test_file
```

---

## Rollback Strategy

### Phase-Level Rollback

**If Phase N Fails**:
```bash
# 1. Rollback to previous generation
nix-rollback

# 2. Restart shell
exec zsh

# 3. Verify system working
health-check

# 4. Review and fix issues
# Then retry phase
```

### System-Level Rollback

**If Catastrophic Failure**:
```bash
# 1. Restore flake.nix
cp flake.nix.backup flake.nix

# 2. Restore machine config (if needed)
rm config/machine-config.nix
cp config/machine-config.nix.backup config/machine-config.nix

# 3. Rollback generations
nix-rollback  # Repeat until stable

# 4. Full system check
nix flake check
nix-rebuild
health-check
```

---

## Dependencies

### External Dependencies
- Nix 2.18+
- nix-darwin
- Home Manager 24.05+
- macOS (tested on Sonoma/Sequoia)

### Internal Dependencies
- lib/aws-helpers.nix (work profile AWS functions)
- lib/database-helpers.nix (work profile DB connectors)
- lib/machine-detection.nix (will be updated in Phase 4)
- lib/secrets-registry.nix (created in Phase 1)

### Skill Dependencies
- Nix/NixOS expertise (flake, modules, imports)
- Shell scripting (bash, zsh)
- Git (hooks, pre-commit, pre-push)
- AWS (multi-role SSO)
- System architecture (separation of concerns)

---

## Success Criteria

### Technical Success
- [ ] All 4 phases complete
- [ ] All tests passing
- [ ] Zero build errors
- [ ] Profile switching functional
- [ ] All existing functionality preserved
- [ ] No performance degradation

### Quality Success
- [ ] No technical debt from migration
- [ ] Code is clean and maintainable
- [ ] Documentation comprehensive
- [ ] Git history clear
- [ ] No deprecated functions

### User Success
- [ ] User can switch profiles easily
- [ ] User understands new architecture
- [ ] User has clear documentation
- [ ] User can set up new machines
- [ ] User can troubleshoot issues

---

## Timeline Estimate

**Assuming 4-hour work sessions**:

| Session | Phase | Tasks | Duration |
|---------|-------|-------|----------|
| 1 | Phase 1 | All 4 tasks | 6.5h (2 sessions) |
| 2-3 | Phase 2 | Tasks 2.1-2.3 | 5.5h |
| 4 | Phase 2 | Tasks 2.4-2.5 | 2.5h |
| 5 | Phase 3 | Tasks 3.1-3.3 | 4.5h |
| 6 | Phase 3 | Tasks 3.4-3.5 | 1.5h |
| 7-8 | Phase 4 | All 5 tasks | 8h (2 sessions) |

**Total**: ~7-8 work sessions (~28.5 hours)

**Calendar Time**: 2-3 weeks (assuming 3-4 sessions per week)

---

## Next Steps

**To Begin Implementation**:

1. Review this plan thoroughly
2. Confirm understanding of all phases
3. Set up project tracking:
   - Update `TASKS.md` with implementation tasks
   - Update `ACTIVE.md` status
4. Start with Phase 1, Task 1.1
5. Follow the plan sequentially
6. Document discoveries in `NOTES.md`
7. Update task status as you progress

**First Command**:
```bash
# Start Phase 1
cd ~/nix-darwin
cat claudedocs/planning/projects/profile-migration/PHASE-1-FOUNDATION.md
# Begin Task 1.1: Remove Alias Duplication
```

---

## References

- **Project Documentation**: `claudedocs/planning/projects/profile-migration/PROJECT.md`
- **Audit Findings**: `claudedocs/planning/projects/profile-migration/NOTES.md` (1,900+ lines)
- **Improvement Opportunities**: `claudedocs/planning/projects/profile-migration/IMPROVEMENTS.md`
- **Phase Details**:
  - [PHASE-1-FOUNDATION.md](PHASE-1-FOUNDATION.md)
  - [PHASE-2-STRUCTURE.md](PHASE-2-STRUCTURE.md)
  - [PHASE-3-INTEGRATION.md](PHASE-3-INTEGRATION.md)
  - [PHASE-4-MIGRATION.md](PHASE-4-MIGRATION.md)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-09
**Status**: Ready for Implementation
