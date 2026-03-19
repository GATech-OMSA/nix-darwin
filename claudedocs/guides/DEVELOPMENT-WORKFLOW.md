# Development Workflow

**Task Execution & Project Management for Claude**

This guide tells Claude how to work on tasks, manage projects, and keep documentation updated.

---

## Before Starting Any Work

**ALWAYS check these files (gitignored, local only):**
1. `claudedocs/planning/ACTIVE.md` - What projects are active?
2. `claudedocs/planning/projects/[project-name]/` - What's the current task?
3. `claudedocs/planning/BACKLOG.md` - What's next?

---

## Starting a New Project

1. **Create project directory**: `mkdir -p claudedocs/planning/projects/[project-name]`
2. **Create PROJECT.md** with objectives, scope, success criteria
3. **Create TASKS.md** with numbered tasks (#001, #002, etc.) — each 1-3 hours
4. **Create NOTES.md** for discoveries and session logs
5. **Update ACTIVE.md** with project status
6. **Create git branch**: `git checkout -b feat/[project-name]` or `fix/[project-name]`

---

## Daily Work Session

### Start:
1. Read ACTIVE.md → current project
2. Read TASKS.md → current task status
3. Read NOTES.md → previous learnings

### During:
1. Pick next task, update status to IN PROGRESS
2. Work on task, test the change
3. Rebuild if Nix changes: `nix-rebuild && exec zsh`

### End:
1. Update TASKS.md with final status
2. Update NOTES.md with learnings and stopping point
3. Commit: `feat: [project-name] #003 - description`

---

## Task Naming Convention

**Format**: `[project-name] #XXX`

Examples:
- `aws-integration #005`
- `shell-optimization #003`

Cross-project references use the same format in Blockers fields.

---

## Context Switching

**Only ONE project in In Progress at a time.**

### Switching from Project A to Project B:
1. Update TASKS.md with current progress
2. Document stopping point in NOTES.md
3. Move project to Paused in ACTIVE.md with Quick Resume note
4. Start Project B

### Resuming:
1. Read ACTIVE.md → find paused project
2. Read NOTES.md → find stopping point
3. Move back to In Progress

---

## Completing a Project

1. Mark all tasks done in TASKS.md
2. Archive: `mv claudedocs/planning/projects/[name] claudedocs/planning/archive/YYYY-MM-[name]/`
3. Update COMPLETED.md with summary
4. Update ACTIVE.md — remove from active list

---

## Task Status Indicators

| Status | Symbol |
|--------|--------|
| Not Started | ⏳ |
| In Progress | 🔄 |
| Blocked | ⚠️ |
| Done | ✅ |
| Paused | 🟡 |

---

## Git Workflow

### Commits include task reference:
```
feat: aws-integration #005 - Add Lambda routing logic
fix: shell-cli #007 - Handle null attribute edge case
refactor: nix-optimization #003 - Extract package groups
```

### Branch naming:
```
feat/[project-name]
fix/[project-name]
```

---

## Project File Structure

```
claudedocs/planning/           # All gitignored (local only)
├── ACTIVE.md                  # Current project status
├── BACKLOG.md                 # New work intake
├── COMPLETED.md               # Chronological index of done projects
├── projects/                  # Active project directories
│   └── [project-name]/
│       ├── PROJECT.md         # Objectives, scope, criteria
│       ├── TASKS.md           # Numbered tasks with status
│       └── NOTES.md           # Discoveries, session logs
└── archive/                   # Completed projects
    └── YYYY-MM-[name]/
        ├── PROJECT.md
        ├── TASKS.md
        ├── NOTES.md
        └── RETROSPECTIVE.md   # Optional lessons learned
```

---

## Key Rules

- **One active project** at a time
- **Always document** stopping point before switching
- **Update immediately** — don't delay status updates
- **Clear resume path** — Quick Resume should say exactly what to do next
- **Task size** — 1-3 hours each, split if larger
- **No AI attribution** in commits (see CLAUDE.md rule 8)

---

**Last Updated**: 2026-03-15
