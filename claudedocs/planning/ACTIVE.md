# Active Projects

**Purpose**: Quick overview of all active work for AI and developers
**Last Updated**: 2025-11-09

**Quick Start**:
- 📂 **All projects**: `claudedocs/planning/projects/`
- 📋 **Project details**: Read `projects/[name]/PROJECT.md` for objectives
- ✅ **Task status**: Read `projects/[name]/TASKS.md` for current progress
- 📝 **Notes**: Read `projects/[name]/NOTES.md` for context and decisions

---

## 🟢 In Progress

### profile-migration
**Status**: 🟢 **READY TO START** - Option B (IMPLEMENTATION) Selected
**Current Phase**: Phase 1 - Foundation & Cleanup (Task 1.1 ready)
**Objective**: Migrate from hostname-based to profile-based architecture, fix build failures, preserve ALL functionality
**Effort**: Analysis complete (~22.5h), Implementation: ~28.5h (4 phases)
**Blockers**: None
**Location**: `projects/profile-migration/`
**Related**: Evolved from git-privacy project

**✅ DECISION MADE**: Following **Option B (IMPLEMENTATION approach)** - Manual 4-phase execution with self-contained profiles.

**Why Option B:** Full control, cleaner long-term architecture, replace mixins with self-contained profiles, educational value.

**Analysis Complete**:
- ✅ **Comprehensive Audit**: 22 files (8,137+ lines), all functionality documented in NOTES.md
- ✅ **Original Proposal**: PROFILE-BASED-ARCHITECTURE-PROPOSAL.md discovered (5,075 lines)
- ✅ **Improvement Catalog**: 20 opportunities identified in IMPROVEMENTS.md
- ✅ **Two Implementation Plans**: Both PROPOSAL approach and new IMPLEMENTATION approach documented
- ✅ **Approach Comparison**: APPROACH-COMPARISON.md analyzes both, recommends HYBRID

**Two Approaches Documented**:

**Option A: PROPOSAL Approach** (from existing PROFILE-BASED-ARCHITECTURE-PROPOSAL.md)
- ✅ Comprehensive design (5,075 lines, 14 sections)
- ✅ Automated migration script (500 lines)
- ✅ Keep mixins, add profile templates
- ✅ Single `config/profile.nix`
- ✅ Lower risk, proven design
- Effort: ~12-16 hours

**Option B: IMPLEMENTATION Approach** (created during analysis)
- ✅ Detailed 4-phase plan (PHASE-1 through PHASE-4 docs)
- ✅ Manual step-by-step execution
- ✅ Replace mixins with self-contained profiles
- ✅ Separate `config/machine-config.nix`
- ✅ Higher control, cleaner architecture
- Effort: ~28.5 hours

**Option C: HYBRID Approach** (RECOMMENDED in APPROACH-COMPARISON.md)
- ✅ Combines PROPOSAL's automation + IMPLEMENTATION's structure
- ✅ Use automated migration script
- ✅ Use self-contained profile directories
- ✅ Migrate mixin content to profiles
- ✅ Best of both worlds
- Effort: ~18-22 hours

**Key Deliverables**:
- `PROFILE-BASED-ARCHITECTURE-PROPOSAL.md` - Original comprehensive proposal
- `NOTES.md` - 1,900+ lines of audit findings
- `IMPROVEMENTS.md` - 20 improvement opportunities
- `APPROACH-COMPARISON.md` - ⚠️ **DECISION DOCUMENT**
- `IMPLEMENTATION-PLAN.md` - Alternative 4-phase plan
- `PHASE-1 through PHASE-4` - Detailed phase breakdowns

**Next Step**:
1. **DECIDE** which approach to follow (A, B, or C)
2. Read APPROACH-COMPARISON.md for detailed analysis
3. Begin implementation after decision

### git-privacy
**Status**: 🟡 Paused (context switch) (7/17 tasks, 41%)
**Current Task**: #008 - Create recovery point commit (was in progress)
**Objective**: Remove hardcoded personal data from git repository (files AND directories)
**Effort**: ~157 minutes total (57 min complete, 100 min remaining)
**Pause Reason**: Expanded into profile-migration project - broader architectural changes needed
**Last Updated**: 2025-11-09
**Location**: `projects/git-privacy/`

**Quick Resume**: Tasks #001-#007 complete (templates, scripts created). Solution 2 ready to implement. HOWEVER: Analysis revealed this is part of larger architectural migration to profile-based system. Pausing to complete profile-migration analysis first, then will integrate git-privacy work into that implementation. See `projects/profile-migration/` for current work.

---

## 📋 Planned

### script-conversion
**Status**: 🔵 Planned (0/6 tasks, 0%)
**Current Task**: Not started - ready to begin with #001
**Objective**: Modernize shell scripts to Python for performance and maintainability
**Effort**: ~12-15 hours total
**Blockers**: None - Python 3.13 available via Nix ✅
**Location**: `projects/script-conversion/`

**Quick Resume**: Start with #001 (Audit scripts directory). See `projects/script-conversion/TASKS.md` for full task breakdown. Builds on check-doc-links.py success (14x speedup).

<!--
Example of project with cross-project blockers:

### project-name
**Status**: 🟡 Paused (blocked) (X/Y tasks, Z%)
**Current Task**: #XXX - Task name
**Objective**: Brief project goal
**Effort**: ~X hours total
**Blockers**:
- 🚧 Cross-project: Waiting for other-project #XXX (feature Y, ETA: 2 days)
- Internal: #XXX must complete first
**Location**: `projects/[name]/`

**Quick Resume**: Cannot proceed until blockers cleared. See TASKS.md for details.

---

Example of paused project (context switch):

### project-name
**Status**: 🟡 Paused (context switch) (X/Y tasks, Z%)
**Current Task**: #XXX - Task name (in progress when paused)
**Objective**: Brief project goal
**Effort**: ~X hours total
**Pause Reason**: Switched to higher-priority work / Waiting for input / Mental break
**Last Updated**: YYYY-MM-DD
**Location**: `projects/[name]/`

**Quick Resume**: Continue with #XXX step 4 (implement error handling). See NOTES.md for stopping point details.
-->

---

## 🟡 Paused

*No paused projects*

---

## ✅ Recently Completed

- **config-system** - Comprehensive configuration enhancements (51 tasks, 92 hours)
  - Archived to: `archive/2025-11-config-system/`
  - Completed: 2025-11-08
