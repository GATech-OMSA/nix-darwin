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

### 2. AWS-CONFIG-STATUS.md → Update or Archive

**Current State:**
- File: `docs/work/aws/AWS-CONFIG-STATUS.md` (641 lines)
- Date: November 6, 2025 (recent!)
- Content: Point-in-time validation report with health scores

**Analysis:**
- ✅ Recent (Nov 6)
- 📊 Specific validation results (16/19 checks passed)
- ⚠️ Machine-specific (macbook-pro-m1)
- ❓ Will become outdated quickly

**Options:**
1. **Keep as historical reference** - Rename to `AWS-CONFIG-STATUS-2025-11-06.md`
2. **Archive** - Move to `.temp/docs/archive/`
3. **Convert to template** - Create `AWS-VALIDATION-TEMPLATE.md` for future checks

**Recommendation:** ⚠️ **DECISION NEEDED**

**Questions for User:**
- Is this a one-time audit or do you want regular status reports?
- Should we keep historical validation reports?
- Should we create an automated validation script?

---

### 3. claudedocs/guides/project-workflow.md → Consolidate

**Current State:**
- File: `claudedocs/guides/project-workflow.md` (236 lines)
- Main file: `claudedocs/guides/DEVELOPMENT-WORKFLOW.md` (653 lines)

**Overlap:** Need to check content

**Action:** Compare files and merge unique content

```bash
# Check for unique content
diff -u claudedocs/guides/DEVELOPMENT-WORKFLOW.md claudedocs/guides/project-workflow.md

# If redundant:
git rm claudedocs/guides/project-workflow.md
git commit -m "docs: Consolidate project-workflow into DEVELOPMENT-WORKFLOW"
```

---

### 4. claudedocs/guides/CLEAN-SETUP-STEPS.md → Review

**Current State:**
- File: `claudedocs/guides/CLEAN-SETUP-STEPS.md` (327 lines)
- Main setup: `docs/installation.md` (859 lines)

**Analysis Needed:** Check if CLEAN-SETUP-STEPS has unique content vs installation.md

**Action:** Compare and decide

---

### 5. docs/learning/README.md → Gitignore

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

### Phase 2: Compare and Decide (User Decision)

```bash
# 1. Review project-workflow vs DEVELOPMENT-WORKFLOW
code --diff claudedocs/guides/DEVELOPMENT-WORKFLOW.md claudedocs/guides/project-workflow.md

# 2. Review CLEAN-SETUP-STEPS vs installation.md
code --diff docs/installation.md claudedocs/guides/CLEAN-SETUP-STEPS.md

# 3. Decide on AWS-CONFIG-STATUS.md
# Options:
#   a) Keep as historical reference
#   b) Archive
#   c) Create validation template
```

### Phase 3: Final Cleanup

```bash
# After phase 2 decisions:
# - Commit consolidations
# - Update main README with doc index
# - Update CLAUDE.md with new doc structure
```

---

## 🎯 Expected Results

### Before Consolidation
- Total docs: 94 files
- User docs: 21 files
- Overlap: 5+ instances

### After Phase 1
- Total docs: ~90 files (-4)
- User docs: 19 files (-2)
- Overlap: 3 instances
- Learning notes: Gitignored

### After Phase 2 (if all consolidated)
- Total docs: ~85-88 files
- User docs: 16-18 files
- Overlap: Minimal
- Structure: Clear separation

---

## 📊 File Status Matrix

| File | Size | Status | Action | Priority |
|------|------|--------|--------|----------|
| `QUICK-REFERENCE.md` | 114 | ❌ Redundant | Archive | **HIGH** |
| `learning/README.md` | 1,479 | ⚠️ Personal | Gitignore | **HIGH** |
| `project-workflow.md` | 236 | 🔍 Maybe redundant | Compare | MEDIUM |
| `CLEAN-SETUP-STEPS.md` | 327 | 🔍 Maybe redundant | Compare | MEDIUM |
| `AWS-CONFIG-STATUS.md` | 641 | ❓ Point-in-time | User decision | LOW |

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
