# Documentation Consolidation Plan

**Based on:** DOCS-REVIEW.md analysis
**Date:** November 2025
**Action Items:** 5 consolidations

---

## 🎯 Consolidation Actions

### 1. QUICK-REFERENCE.md → Archive ✅ **RECOMMENDED**

**Current State:**
- File: `docs/QUICK-REFERENCE.md` (114 lines)
- Content: Secrets, environment vars, basic AWS, hot reloading
- Written: Before AWS-AND-SECRETS-WORKFLOW.md

**Overlap with AWS-AND-SECRETS-WORKFLOW.md:**
- ✅ Secrets management - Better coverage in AWS-AND-SECRETS-WORKFLOW
- ✅ Environment variables - Covered
- ✅ Hot reloading - Now updated with reload-secrets in AWS-AND-SECRETS-WORKFLOW
- ✅ AWS basics - Much more comprehensive in AWS-AND-SECRETS-WORKFLOW

**Decision:** ✅ **Archive**

**Action:**
```bash
mkdir -p .temp/docs/archive/quick-reference/
git mv docs/QUICK-REFERENCE.md .temp/docs/archive/quick-reference/
git commit -m "docs: Archive QUICK-REFERENCE.md (superseded by AWS-AND-SECRETS-WORKFLOW)"
```

**Reason:** AWS-AND-SECRETS-WORKFLOW.md (766 lines) is comprehensive and includes everything from QUICK-REFERENCE plus much more detail.

---

### 2. AWS-CONFIG-STATUS.md → Rename as Dated Snapshot ✅ **COMPLETED**

**Current State:**
- File: `docs/work/aws/AWS-CONFIG-STATUS.md` (641 lines)
- Date: November 6, 2025 (recent!)
- Content: Point-in-time validation report with health scores

**Analysis:**
- ✅ Recent (Nov 6, 2025)
- 📊 Specific validation results (16/19 checks passed)
- ⚠️ Machine-specific (macbook-pro-m1)
- 📸 Valuable as historical snapshot of configuration state

**Decision:** ✅ **Renamed as dated snapshot**

**Action Taken:**
```bash
git mv docs/work/aws/AWS-CONFIG-STATUS.md docs/work/aws/AWS-CONFIG-STATUS-2025-11-06.md
# Preserves validation report as historical reference
# Date in filename makes temporal nature clear
```

**Recommendation:** Keep this pattern for future validation reports - name with date to preserve snapshots over time.

---

### 3. claudedocs/guides/project-workflow.md → Archive ✅ **COMPLETED**

**Current State:**
- File: `claudedocs/guides/project-workflow.md` (236 lines)
- Main file: `claudedocs/guides/DEVELOPMENT-WORKFLOW.md` (653 lines)

**Analysis:**
- ✅ DEVELOPMENT-WORKFLOW.md is a comprehensive superset
- ✅ All examples from project-workflow.md covered in detail
- ✅ DEVELOPMENT-WORKFLOW adds: backlog grooming, context switching, checklists, anti-patterns

**Decision:** ✅ **Archived**

**Action Taken:**
```bash
git mv claudedocs/guides/project-workflow.md deprecated/docs/project-workflow/
# Documented in deprecated/docs/README.md
```

---

### 4. claudedocs/guides/CLEAN-SETUP-STEPS.md → Archive ✅ **COMPLETED**

**Current State:**
- File: `claudedocs/guides/CLEAN-SETUP-STEPS.md` (327 lines)
- Main setup: `docs/installation.md` (859 lines)

**Analysis:**
- ✅ CLEAN-SETUP-STEPS is a transitional work document from username-agnostic refactoring
- ✅ installation.md is current, production-ready v2.0.0 guide
- ✅ Historical value preserved as snapshot of refactoring decisions

**Decision:** ✅ **Archived**

**Action Taken:**
```bash
git mv claudedocs/guides/CLEAN-SETUP-STEPS.md deprecated/docs/clean-setup-steps/
# Documented in deprecated/docs/README.md
```

---

### 5. docs/learning/README.md → Gitignore ✅ **COMPLETED (Phase 1)**

**Current State:**
- File: `docs/learning/README.md` (1,479 lines!)
- Content: Personal learning notes

**Decision:** ✅ **Move to gitignore**

**Action:**
```bash
# Add to .gitignore
echo "/docs/learning/" >> .gitignore

# Archive current version
mkdir -p .temp/docs/archive/
git mv docs/learning .temp/docs/archive/

# Commit
git commit -m "docs: Archive personal learning notes (add to gitignore)"
```

**Reason:** Personal learning notes shouldn't be in official repo docs.

---

## 📋 Implementation Order

### Phase 1: Simple Archives (Do Now) ✅

```bash
# 1. Archive QUICK-REFERENCE (clearly redundant)
mkdir -p .temp/docs/archive/quick-reference/
git mv docs/QUICK-REFERENCE.md .temp/docs/archive/quick-reference/

# 2. Move learning notes
echo "/docs/learning/" >> .gitignore
git mv docs/learning .temp/docs/archive/

# 3. Commit
git add .gitignore
git commit -m "docs: Archive redundant documentation

- Archive QUICK-REFERENCE.md (superseded by AWS-AND-SECRETS-WORKFLOW)
- Move learning notes to archive and gitignore
- Reduces documentation overlap and noise"
```

### Phase 2: Compare and Decide ✅ **COMPLETED**

```bash
# 1. Review project-workflow vs DEVELOPMENT-WORKFLOW
# Analysis: project-workflow.md is redundant superset
git mv claudedocs/guides/project-workflow.md deprecated/docs/project-workflow/

# 2. Review CLEAN-SETUP-STEPS vs installation.md
# Analysis: CLEAN-SETUP-STEPS is transitional work document
git mv claudedocs/guides/CLEAN-SETUP-STEPS.md deprecated/docs/clean-setup-steps/

# 3. AWS-CONFIG-STATUS.md decision
# Decision: Rename as dated snapshot for historical reference
git mv docs/work/aws/AWS-CONFIG-STATUS.md docs/work/aws/AWS-CONFIG-STATUS-2025-11-06.md

# 4. Updated deprecated/docs/README.md with new entries
```

### Phase 3: Final Cleanup ⏳ **PENDING**

```bash
# After phase 2 completion:
# - ✅ Commit Phase 2 consolidations
# - ⏳ Update DOCS-REVIEW.md with results
# - ⏳ Consider documentation index (optional)
```

---

## 🎯 Expected Results

### Before Consolidation
- Total docs: 94 files
- User docs: 21 files
- Overlap: 5+ instances

### After Phase 1 ✅
- Total docs: ~90 files (-4)
- User docs: 19 files (-2)
- Overlap: 3 instances
- Learning notes: Gitignored

### After Phase 2 ✅ **CURRENT STATE**
- Total docs: ~87 files (-7 total)
- User docs: 17 files (-4 total)
- Overlap: Minimal (all redundancies archived)
- Structure: Clear separation
- Historical docs: Preserved in deprecated/docs/ with clear documentation

---

## 📊 File Status Matrix

| File | Size | Status | Action | Priority | Result |
|------|------|--------|--------|----------|--------|
| `QUICK-REFERENCE.md` | 114 | ❌ Redundant | Archive | **HIGH** | ✅ Archived (Phase 1) |
| `learning/README.md` | 1,479 | ⚠️ Personal | Gitignore | **HIGH** | ✅ Archived + Gitignored (Phase 1) |
| `project-workflow.md` | 236 | ❌ Redundant | Archive | MEDIUM | ✅ Archived (Phase 2) |
| `CLEAN-SETUP-STEPS.md` | 327 | ❌ Transitional | Archive | MEDIUM | ✅ Archived (Phase 2) |
| `AWS-CONFIG-STATUS.md` | 641 | 📸 Snapshot | Rename | LOW | ✅ Renamed with date (Phase 2) |

---

## ✅ Phase 1 Ready to Execute

**Immediate consolidations (no review needed):**

1. ✅ Archive `QUICK-REFERENCE.md` - Clearly superseded
2. ✅ Gitignore `docs/learning/` - Personal notes

**Commands:**
```bash
# Execute Phase 1
mkdir -p .temp/docs/archive/quick-reference/
git mv docs/QUICK-REFERENCE.md .temp/docs/archive/quick-reference/
git mv docs/learning .temp/docs/archive/
echo "/docs/learning/" >> .gitignore
git add .gitignore
git commit -m "docs: Archive redundant documentation

- Archive QUICK-REFERENCE.md (superseded by AWS-AND-SECRETS-WORKFLOW)
- Move learning notes to archive and gitignore"

# Done! Reduced from 94 → ~90 docs
```

---

**Ready to proceed with Phase 1?**
