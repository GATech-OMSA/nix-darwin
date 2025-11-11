# Profile-Based Architecture Migration

**Status:** 🟢 Ready for Implementation - Option B Selected
**Started:** November 9, 2025
**Analysis Complete:** November 9, 2025
**Approach Selected:** November 9, 2025 - **Option B (IMPLEMENTATION)**
**Target Completion:** 2-3 weeks (~28.5 hours estimated)
**Priority:** High
**Complexity:** High

**✅ DECISION MADE**: Following **Option B (IMPLEMENTATION approach)** - Manual 4-phase execution with self-contained profiles

## Context

Current nix-darwin configuration has three critical issues:
1. **Build failures** - gitignored directories cause Nix flake evaluation errors
2. **Hardcoded identity** - hostname-based detection embeds personal info
3. **Limited flexibility** - can't switch profiles or share configs privately

## Objectives

### Primary Goals
1. Fix build failures caused by gitignored directories
2. Separate machine identity from behavior (machineId vs profileName)
3. Enable profile switching (personal ↔ work ↔ minimal)
4. **Preserve ALL existing functionality** without loss
5. **Improve configuration** where opportunities exist

### Success Criteria
- ✅ `darwin-rebuild switch --flake .` succeeds without errors
- ✅ All existing features preserved (AWS, aliases, starship, git, secrets)
- ✅ Profile switching works seamlessly
- ✅ Configuration improvements documented and implemented
- ✅ Migration path tested and automated

## Scope

### In Scope
- Comprehensive functionality audit across all files
- Proposal validation against existing implementation
- Improvement opportunity identification
- Detailed migration plan with phased approach
- Automated migration scripts
- Testing framework for validation

### Out of Scope
- Complete architectural redesign beyond profile system
- New feature additions unrelated to profile migration
- Performance optimization (unless critical)

## Current Phase: Analysis

### Phase 1: Comprehensive Functionality Audit
**Status:** 🟢 In Progress

Systematically audit all existing functionality:

**1.1 Core Library Functions (lib/)**
- [ ] aws-helpers.nix - AWS profile/alias system
- [ ] database-helpers.nix - DB connection helpers
- [ ] machine-detection.nix - Hostname-based detection
- [ ] mixin-helpers.nix - Mixin composition
- [ ] secrets-registry.nix - Secret path registry
- [ ] warnings.nix - Warning/confirmation system

**1.2 Scripts (scripts/)**
- [ ] Health checks and validation scripts
- [ ] AWS helper test scripts
- [ ] Secret encryption validation
- [ ] Backup/restore functionality
- [ ] Installation and setup scripts

**1.3 Home Configuration (home/)**
- [ ] Shell configuration (zsh, starship)
- [ ] Program configs (git, vscode, aws)
- [ ] Development tools (python, node, ai-ml)
- [ ] Mixins (base, dev, personal, work)

**1.4 Host Configuration (hosts/)**
- [ ] Host-specific settings
- [ ] Secrets management (SOPS)
- [ ] Machine definitions

**1.5 Git Hooks & Security**
- [ ] Pre-commit hooks (secret scanning)
- [ ] Pre-push hooks
- [ ] Permission validation

### Phase 2: Proposal Validation
Compare PROFILE-BASED-ARCHITECTURE-PROPOSAL.md against actual implementation to find:
- Conflicts with existing logic
- Missing functionality in proposal
- Better configuration approaches

### Phase 3: Improvement Opportunities
Identify areas where profile-based architecture enables better:
- Code organization
- Configuration management
- User experience
- Security posture

### Phase 4: Implementation Planning
Create detailed task breakdown similar to git-privacy project structure.

## Dependencies

- Existing project: git-privacy (privacy enhancements)
- Current configuration must remain functional during analysis
- No breaking changes until migration phase

## Stakeholders

- Primary: User (jimmy)
- System: nix-darwin configuration

## Risk Assessment

**High Risks:**
- Data loss during migration
- Configuration breakage
- Missing functionality in migration

**Mitigations:**
- Comprehensive audit before any changes
- Automated backup before migration
- Phased rollout with validation gates
- Rollback procedures documented

## Notes

- This evolved from git-privacy project
- Analysis phase complete: 22 files audited (8,137+ lines)
- Two different implementation approaches documented
- Awaiting decision before starting implementation

## Related Documents

### Analysis & Planning (✅ Complete)
- **PROFILE-BASED-ARCHITECTURE-PROPOSAL.md** - Original comprehensive proposal (5,075 lines, 14 sections)
  - Executive summary, architecture, directory structure, profile system
  - Multi-machine scenarios, migration path, onboarding flow
  - 6-phase approach with automated migration script
- **NOTES.md** - Audit findings (1,900+ lines documenting all 22 files)
- **IMPROVEMENTS.md** - 20 improvement opportunities catalogued
- **APPROACH-COMPARISON.md** - ⚠️ **DECISION DOCUMENT** comparing two approaches

### Implementation Plans (Two Options)

**Option 1: PROPOSAL Approach** (from PROFILE-BASED-ARCHITECTURE-PROPOSAL.md)
- Automated migration with `scripts/migrate-to-profiles.sh`
- Keep mixins system, add profile templates
- Single `config/profile.nix` configuration
- 6 phases: Pre-migration, Core, Scripts, Testing, Docs, Release
- Lower risk, more automation

**Option 2: IMPLEMENTATION Approach** (created during analysis)
- **IMPLEMENTATION-PLAN.md** - Master plan (4 phases, 28.5h)
- **PHASE-1-FOUNDATION.md** - Foundation & Cleanup (6.5h, 4 tasks)
- **PHASE-2-STRUCTURE.md** - Profile Structure (8h, 5 tasks)
- **PHASE-3-INTEGRATION.md** - Flake Integration (6h, 5 tasks)
- **PHASE-4-MIGRATION.md** - Migration & Improvements (8h, 5 tasks)
- Replace mixins with profiles, modular structure
- Manual phase-by-phase approach
- Higher risk, more control

### Tracking
- **TASKS.md** - 14 analysis tasks (all complete)
- **TASKS_UPDATE.md** - Progress tracking and summary

### ✅ Decision Made: Option B (IMPLEMENTATION Approach)

**Selected:** November 9, 2025

**Rationale:**
- Manual 4-phase execution provides full control and understanding
- Self-contained profile structure is cleaner long-term architecture
- Replace mixins with profiles for better maintainability
- Higher visibility into each change (educational value)
- Same end result as HYBRID but with complete transparency

**Alternative Approaches Documented:**
- See **APPROACH-COMPARISON.md** for comparison of all options
- PROPOSAL approach (Option A) preserved in PROFILE-BASED-ARCHITECTURE-PROPOSAL.md
- Can reference PROPOSAL's migration script if needed during execution

**Execution Plan:**
- Follow **IMPLEMENTATION-PLAN.md** (master plan)
- Execute phases sequentially: 1 → 2 → 3 → 4
- Each phase has detailed breakdown in PHASE-N-*.md files
- Estimated total: ~28.5 hours over 2-3 weeks

**Next Step**: Begin **Phase 1: Foundation & Cleanup** (Task 1.1 - Remove alias duplication)
