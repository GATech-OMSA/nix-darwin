# Project Workflow Guide

Guide to project-based task management and AI collaboration workflows.

---

## Project Structure

```
claudedocs/planning/
├── BACKLOG.md              # New ideas intake
├── ACTIVE.md               # Current projects overview
├── projects/
│   └── [project-name]/
│       ├── PROJECT.md      # Goals, scope, success criteria
│       ├── TASKS.md        # #001, #002, etc. (continuous)
│       └── NOTES.md        # Decisions, learnings
└── archive/
    └── YYYY-MM-[name]/     # Completed projects
        ├── PROJECT.md
        └── TASKS.md
```

---

## Example 1: Starting a New Project

**Scenario**: Convert shell scripts to Python for performance

```bash
# 1. Create project structure
mkdir -p claudedocs/planning/projects/shell-to-python
cd claudedocs/planning/projects/shell-to-python

# 2. Create PROJECT.md
cat > PROJECT.md <<EOF
# Project: shell-to-python

**Status**: 🟢 Active
**Started**: 2025-11-09

## Objective
Convert performance-critical shell scripts to Python for 10-15x speedup

## Success Criteria
- [ ] All scripts in scripts/ audited
- [ ] 5 critical scripts converted
- [ ] Performance benchmarks documented
EOF

# 3. Create TASKS.md
cat > TASKS.md <<EOF
# Tasks: shell-to-python

## #001 - Audit existing scripts
**Status**: 🔵 Todo
**Effort**: 1h
Inventory all scripts, categorize by complexity

## #002 - Convert check-doc-links
**Status**: ✅ Done
...
EOF

# 4. Update ACTIVE.md
# Add shell-to-python to "In Progress" section

# 5. Start work
git checkout -b shell-to-python-001
```

---

## Example 2: Daily Work Session

**User asks**: "Work on the shell script conversion project"

**AI workflow**:
```bash
# AI reads active projects
cat claudedocs/planning/ACTIVE.md
# → Sees: shell-to-python (3/10 tasks, 30%)

# AI reads current state
cat claudedocs/planning/projects/shell-to-python/TASKS.md
# → Sees: #001 ✅ Done, #002 ✅ Done, #003 🟡 In Progress

# AI continues on #003
# Updates TASKS.md: #003 → ✅ Done
# Starts #004 → 🟡 In Progress
```

**Commits**:
```bash
git commit -m "feat: shell-to-python #003 - Convert health-check script

- Migrate health-check.sh to Python
- Add error handling and colored output
- Benchmark: 0.3s → 0.02s (15x faster)"
```

**Benefits**:
- Clear project context from commit message
- Task number unique within project
- No confusion with other projects

---

## Example 3: Switching Projects

**User**: "Pause shell scripts, work on AWS improvements instead"

```bash
# Create new project
mkdir -p claudedocs/planning/projects/aws-enhancements

# Update ACTIVE.md
🟡 Paused: shell-to-python (3/10 tasks)
🟢 Active: aws-enhancements (0/5 tasks)

# Work on aws-enhancements
git checkout -b aws-enhancements-001

# Commits clearly show project
git commit -m "feat: aws-enhancements #001 - Add profile fuzzy search"
```

**No confusion**: `shell-to-python #003` ≠ `aws-enhancements #003`

---

## Example 4: Completing a Project

```bash
# All tasks done in TASKS.md
cat projects/shell-to-python/TASKS.md
# → All tasks marked ✅ Done

# Update PROJECT.md
cat > projects/shell-to-python/PROJECT.md <<EOF
**Status**: ✅ Complete
**Completed**: 2025-11-15

## Summary
Converted 5 critical scripts to Python
- 10-15x performance improvement
- Better error handling
- 60% code reduction
EOF

# Archive it
mv projects/shell-to-python archive/2025-11-shell-to-python/

# Update ACTIVE.md (remove from active list)
```

---

## Example 5: AI Reference in Conversation

**Old way (phase-based, confusing)**:
```
User: "Continue Phase 5 task 3"
AI: "Which Phase 5? config-system or git-privacy?"
```

**New way (project-based, clear)**:
```
User: "Continue git-privacy"
AI: *reads projects/git-privacy/TASKS.md*
    "Resuming git-privacy #003 - Personal machine validation
     Last status: 🟡 In Progress
     Next: Run build test..."
```

---

## Example 6: Backlog Grooming

```bash
# User adds idea to BACKLOG.md
- [ ] Add multi-language support
  - Type: Enhancement
  - Effort: Large (8h)

# Later, decide to prioritize
# Create project from backlog item
mkdir -p projects/i18n-support

# Copy templates
cp templates/PROJECT.md projects/i18n-support/
cp templates/TASKS.md projects/i18n-support/
cp templates/NOTES.md projects/i18n-support/

# Fill in details from backlog item
# Remove from BACKLOG.md
```

---

## Key Benefits

| Scenario | Old (Phase-based) | New (Project-based) |
|----------|-------------------|---------------------|
| **Starting work** | "Which phase am I on?" | "Which project? Check ACTIVE.md" |
| **Git commits** | `feat: Phase 5 Task 6.1...` (ambiguous) | `feat: git-privacy #003...` (clear) |
| **AI resume** | Searches all phases across files | Reads single project directory |
| **History** | Mixed in COMPLETED.md | Archived by date + project name |
| **Collision** | Phase 5 = which project? | git-privacy #005 ≠ aws #005 |

---

## Quick Reference

**Starting new project**:
1. `mkdir -p projects/[name]`
2. Copy templates from `templates/`
3. Fill in PROJECT.md (objectives, scope)
4. Break down into tasks in TASKS.md
5. Update ACTIVE.md

**Daily work**:
1. Check ACTIVE.md for current project
2. Read PROJECT.md for context
3. Update TASKS.md status
4. Commit: `git commit -m "feat: project-name #XXX - ..."`

**Completing project**:
1. Mark all tasks ✅ in TASKS.md
2. Update PROJECT.md status → ✅ Complete
3. `mv projects/[name] archive/YYYY-MM-[name]/`
4. Update ACTIVE.md

---

**Bottom line**: Project name becomes the namespace, tasks are numbered within that namespace. Simple, scalable, no confusion.
