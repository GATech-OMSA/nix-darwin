# DEVELOPMENT-WORKFLOW.md

**Task Execution & Project Management for Claude**

This guide tells Claude how to work on tasks, manage projects, and keep documentation updated.

---

## 📋 Before Starting Any Work

**ALWAYS check these files:**
1. `claudedocs/planning/ACTIVE.md` - What projects are active?
2. `claudedocs/planning/projects/[project-name]/` - What's the current task?
3. `claudedocs/planning/BACKLOG.md` - What's next?

---

## 🚀 Starting a New Project

### Step 1: Create Project Directory
```bash
mkdir -p claudedocs/planning/projects/[project-name]
```

### Step 2: Copy Templates
```bash
cp claudedocs/planning/templates/PROJECT.md claudedocs/planning/projects/[project-name]/
cp claudedocs/planning/templates/TASKS.md claudedocs/planning/projects/[project-name]/
cp claudedocs/planning/templates/NOTES.md claudedocs/planning/projects/[project-name]/
```

### Step 3: Fill in PROJECT.md
- **Objectives:** What are we building/fixing?
- **Scope:** What's included?
- **Success Criteria:** How do we know it's done?
- **Out of Scope:** What's NOT included?

### Step 4: Break Down into TASKS.md
- Task #001, #002, etc.
- Each task: 1-3 hours of work
- Clear "Definition of Done" for each

### Step 5: Update ACTIVE.md
```markdown
## [project-name]
- Status: 📋 PLANNING
- Progress: PROJECT.md written
- Next: Start tasks
```

### Step 6: Create Git Branch
```bash
git checkout -b [project-name]-001
```

---

## 🔍 Weekly Backlog Grooming

**When**: Weekly review or when ready for new work

**Purpose**: Convert backlog items into structured projects

### Grooming Process:

1. **Review BACKLOG.md** - Check all categories (Bugs, Enhancements, Features, Technical Debt, Documentation)

2. **Assess priority** using impact + effort matrix:
   ```
   High Impact + Low Effort  → Groom immediately (Quick wins)
   High Impact + High Effort → Groom strategically (Plan carefully)
   Low Impact + Low Effort   → Groom when capacity (Fill gaps)
   Low Impact + High Effort  → Archive or defer (Low ROI)
   ```

3. **Group related items** - Example: 3 Zsh bugs → single `zsh-improvements` project

4. **Create project structure**:
   ```bash
   mkdir -p projects/[project-name]/
   cp templates/PROJECT.md projects/[project-name]/
   cp templates/TASKS.md projects/[project-name]/
   cp templates/NOTES.md projects/[project-name]/
   ```

5. **Fill templates** - Convert backlog items to PROJECT.md objectives and TASKS.md tasks

6. **Update ACTIVE.md** - Add to 📋 Planned section:
   ```markdown
   ### [project-name]
   **Status**: 🔵 Planned (0/X tasks, 0%)
   **Current Task**: Not started
   **Objective**: [from backlog item]
   **Effort**: ~X hours
   **Blockers**: None
   ```

7. **Clean BACKLOG.md** - Move groomed items to "Recently Groomed" section

### Impact Levels Reference:

- 🔥 **Critical** - System broken, blocks all work, security issue
- 🔴 **High** - Significant user impact, major productivity gain
- 🟡 **Medium** - Noticeable improvement, quality of life
- 🟢 **Low** - Nice to have, minor improvement

---

## 📅 Daily Work Session

### Start of Session:
1. **Read ACTIVE.md** - What's the current project?
2. **Read PROJECT.md** - What are we building?
3. **Read TASKS.md** - What's the current task status?
4. **Read NOTES.md** - Any learnings from previous sessions?

### During Session:
1. **Pick next task** from TASKS.md
2. **Update task status** as you work:
   ```markdown
   ## #003 - Task Name
   - Status: 🔄 IN PROGRESS (60% done)
   - Started: [time]
   - Blockers: [any issues]
   ```
3. **Work on task**
4. **Test the change**

### End of Session:
1. **Update TASKS.md** with final status:
   ```markdown
   ## #003 - Task Name
   - Status: ✅ DONE
   - Time: 2 hours
   - Notes: [what you learned]
   ```
2. **Update NOTES.md** with learnings:
   ```markdown
   ## Session Notes - [date]
   - Discovered: [finding]
   - Blocker: [if any]
   - Next: [what to resume from]
   ```
3. **Commit with task reference:**
   ```bash
   git commit -m "feat: [project-name] #003 - description of what you did"
   ```

---

## ✅ Task Naming Convention

**Use this format for everything:**
```
[project-name] #XXX
```

**Examples:**
- ✅ `aws-integration #005`
- ✅ `shell-cli-v2 #003`
- ✅ `nix-optimization #008`

**NOT:**
- ❌ `Phase 5 Task 3`
- ❌ `Task 3`
- ❌ `AWS thing`

**Why?** Keeps tasks globally identifiable across all projects.

---

## 🔗 Handling Cross-Project Dependencies

### When One Project Needs Another

**Example**: `aws-enhancements #004` needs Zsh completion caching from `zsh-improvements #002`

### In PROJECT.md

```markdown
## Dependencies

**Prerequisites**:
- ✅ Internal: Previous task done
- 🔄 Cross-project: zsh-improvements #002 (completion caching)

**Cross-Project Blockers**:
- Blocked by: other-project #003 (waiting for feature X)
```

### In TASKS.md

```markdown
## #004 - AWS Profile Completion
**Depends on**: zsh-improvements #002 (cross-project)
**Blockers**: Cross-project: Waiting for zsh-improvements #002 (ETA: 2 days)
```

### In ACTIVE.md

```markdown
### aws-enhancements
**Status**: 🟡 Paused (blocked) (3/5 tasks, 60%)
**Current Task**: #004 - AWS profile completion
**Blockers**:
- 🚧 Cross-project: Waiting for zsh-improvements #002 (ETA: 2 days)
```

### Best Practices

1. **Always specify ETA** for blocked tasks when known
2. **Update regularly** - Check blocker status daily
3. **Communicate** - If you're blocking another project, prioritize accordingly
4. **Consider workarounds** - Can you proceed without the dependency?
5. **Document in NOTES.md** - Track why dependency exists and alternatives considered

---

## 🔄 Handling Context Switches

### When to Switch Projects

**Valid reasons to pause and switch:**
- Blocked by dependency (wait time > 1 day)
- Higher priority work arrives
- Need mental break from current project
- Waiting for external input/approval
- Discovered blocker that requires different expertise

### Switching Process

**From Project A → Project B:**

1. **Save Progress** (Project A):
   - Update current task status in TASKS.md
   - Document stopping point in NOTES.md:
     ```markdown
     ### Session [Date] - Paused at Task #XXX
     - Completed: Steps 1-3 of #XXX
     - Next: Need to complete step 4 (implement error handling)
     - Blockers: Waiting for dependency / Higher priority work
     ```

2. **Update ACTIVE.md** (Project A):
   - Move from 🟢 In Progress → 🟡 Paused
   - Change status: `🟡 Paused (context switch) (X/Y tasks, Z%)`
   - Add pause reason to **Quick Resume**:
     ```markdown
     **Quick Resume**: Continue with #XXX step 4. Paused for [reason]. See NOTES.md for context.
     ```

3. **Start Project B**:
   - Move from 📋 Planned → 🟢 In Progress
   - Update status: `🟢 Active (0/Y tasks, 0%)`
   - Begin with #001 or continue from where paused

4. **Update ACTIVE.md date**:
   - `**Last Updated**: YYYY-MM-DD`

### Resuming Project A

**When ready to resume:**

1. **Read context** (in order):
   - ACTIVE.md → Find paused project
   - NOTES.md → Read "Paused at Task #XXX" entry
   - TASKS.md → Check current task status
   - PROJECT.md → Refresh on objectives

2. **Handle Project B**:
   - If complete: Archive it
   - If pausing: Follow switching process above
   - If deprioritizing: Move to 🟡 Paused or back to 📋 Planned

3. **Resume Project A**:
   - Move from 🟡 Paused → 🟢 In Progress
   - Update status: `🟢 Active (X/Y tasks, Z%)`
   - Continue from documented stopping point

### Key Principles

1. **One Active Project**: Only ONE project in 🟢 In Progress at a time
2. **Always Document**: Record stopping point in NOTES.md before switching
3. **Update Immediately**: Don't delay status updates (prevents confusion)
4. **Clear Resume Path**: Quick Resume should tell you exactly what to do next
5. **Track Pause Reason**: Helps decide when to resume

### Example: Full Context Switch

```markdown
# Scenario: Working on aws-integration, switch to urgent bug fix

## Step 1: Pause aws-integration
TASKS.md: Mark #003 as "🟡 In Progress (paused at step 3)"
NOTES.md: "Session 2025-11-08 - Paused #003 at testing phase, 2 tests passing"
ACTIVE.md: Move to 🟡 Paused, Quick Resume: "Continue #003 testing, 2/5 tests pass"

## Step 2: Start urgent-bugfix
ACTIVE.md: Move to 🟢 In Progress
TASKS.md: Mark #001 as "🟡 In Progress"

## Step 3: Resume aws-integration (after bug fix done)
Read NOTES.md: "Paused at testing, 2 tests passing"
ACTIVE.md: Move to 🟢 In Progress
TASKS.md: Continue #003 from testing phase
```

### Anti-Patterns to Avoid

❌ **Multiple Active Projects**: Don't have 2+ projects in 🟢 In Progress
❌ **No Documentation**: Don't switch without documenting stopping point
❌ **Stale Status**: Don't leave projects in old status for days
❌ **Vague Resume**: Don't write "Continue where left off" (be specific!)

---

## 🏁 Completing a Project

### When All Tasks Are Done:

1. **Update TASKS.md**
   ```markdown
   # Tasks for [project-name]
   
   Status: ✅ ALL TASKS COMPLETE (8/8)
   ```

2. **Update PROJECT.md**
   ```markdown
   # [project-name]
   
   Status: ✅ COMPLETE
   Completed: [date]
   ```

3. **Create Retrospective** (Optional but recommended)
   ```bash
   # Create file:
   claudedocs/planning/archive/[YYYY-MM-project-name]/RETROSPECTIVE.md
   
   # Include:
   - What went well
   - What was hard
   - Lessons learned
   - Metrics (duration, accuracy)
   - Artifacts to reuse
   ```

4. **Archive Project**
   ```bash
   mv claudedocs/planning/projects/[project-name] \
      claudedocs/planning/archive/2025-01-[project-name]
   ```

5. **Update COMPLETED.md**
   Add project summary to chronological index:
   ```markdown
   #### [project-name]
   **Completed**: YYYY-MM-DD
   **Duration**: X tasks, ~Y hours
   **Archive**: `archive/YYYY-MM-[project-name]/`

   **Objective**: One-sentence project goal

   **Key Deliverables**:
   - Deliverable 1
   - Deliverable 2
   - Deliverable 3

   **Impact**:
   - ✅ Measurable impact 1
   - ✅ Measurable impact 2

   **Success Criteria**: ✅ All X tasks completed
   ```

6. **Update ACTIVE.md**
   - Remove project from active list
   - Move to "Recently Completed" section with brief summary

7. **Commit**
   ```bash
   git commit -m "feat: [project-name] - Complete (8/8 tasks, [duration])"
   ```

---

## 📝 Task Structure

### Each Task Should Have:

**In TASKS.md:**
```markdown
## #005 - Task Title

**Estimate:** 2 hours
**Status:** ⏳ NOT STARTED | 🔄 IN PROGRESS | ✅ DONE

**Definition of Done:**
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3

**Maps to Success Criteria:** ✅ "Success Criterion Name"

**Blockers:** None
```

**Key Point:** Each task should:
- Be 1-3 hours of work (sweet spot)
- Have clear acceptance criteria
- Map to a project success criterion
- Be independent or clearly state dependencies

---

## 📚 NOTES.md Structure

### Organize by Category:

```markdown
# Implementation Notes for [project-name]

## Architecture Decisions
- Decision 1: [what, why, alternatives considered]
- Decision 2: [what, why, alternatives considered]

## Technical Discoveries
- Discovery 1: [finding and learning]
- Discovery 2: [finding and learning]

## Gotchas & Edge Cases
- Gotcha 1: [symptom, root cause, fix]
- Gotcha 2: [symptom, root cause, fix]

## Performance Baselines
| Metric | Value | Notes |

## Debugging Log
### Issue: [title]
- Symptoms: [how it failed]
- Cause: [root cause]
- Solution: [fix]
```

**Why?** Makes it easy to find information later and fast-track similar future projects.

---

## 🔄 Git Workflow

### Commits Should Include Task Reference:

```bash
# Good:
git commit -m "feat: aws-integration #005 - Add Lambda routing logic"
git commit -m "fix: shell-cli-v2 #007 - Handle null attribute edge case"
git commit -m "refactor: nix-optimization #003 - Extract package groups"

# Not good:
git commit -m "fix stuff"
git commit -m "working on task"
git commit -m "changes"
```

### Branch Naming:
```bash
git checkout -b [project-name]-001
git checkout -b [project-name]-002
```

### Before Pushing:
```bash
git log --oneline
# Verify all commits have [project-name] #XXX reference
```

---

## 📊 Task Status Indicators

Use these consistently in TASKS.md:

| Status | Symbol | Meaning |
|--------|--------|---------|
| Not Started | ⏳ | Haven't touched yet |
| In Progress | 🔄 | Currently working |
| Blocked | ⚠️ | Waiting on something |
| Done | ✅ | Complete & tested |
| Hold | 🟡 | Paused, will resume |

---

## 🎯 Common Patterns

### Pattern 1: Task Dependencies
```markdown
## #003 - Task A
- Depends on: #002
- Blocked until: #002 is complete

## #004 - Task B
- Depends on: #002, #003
- Blocked until: Both complete
```

### Pattern 2: Estimation Refinement
```markdown
## #005 - Task C
- Initial estimate: 2 hours
- Actual time spent: 3 hours (60 min exploration)
- Notes: Took longer due to edge cases discovered

→ Use for next project: 1.3x multiplier on similar tasks
```

### Pattern 3: Blocking Issues
```markdown
## #006 - Task D
- Status: ⚠️ BLOCKED
- Blocker: Waiting for AWS credentials setup
- Blocker Impact: Blocks #006, #007, #008
- Blocker ETA: Tomorrow 10 AM
```

---

## 💡 Best Practices

### DO:
✅ Update status frequently (end of each work session)
✅ Document blockers immediately
✅ Keep tasks in 1-3 hour range
✅ Link to relevant documentation
✅ Update NOTES.md with learnings
✅ Commit frequently with [project] #XXX reference

### DON'T:
❌ Let tasks grow beyond 3 hours without splitting
❌ Leave tasks in "IN PROGRESS" for days (mark DONE or BLOCKED)
❌ Forget to update TASKS.md when switching context
❌ Create vague acceptance criteria
❌ Skip NOTES.md (future projects benefit from learnings)
❌ Commit without task reference

---

## 🚫 Anti-Patterns to Avoid

❌ **Creating new files for each task**
- TASK-001.md, TASK-002.md, TASK-003.md
- Instead: Keep all in TASKS.md

❌ **Inconsistent task naming**
- "Phase 5 Task 3", "AWS work", "do stuff"
- Instead: Use [project-name] #XXX format always

❌ **No project structure**
- Random files in planning/
- Instead: Consistent PROJECT.md, TASKS.md, NOTES.md per project

❌ **Bloated NOTES.md**
- 50 pages of free-form thoughts
- Instead: Organized by category with clear sections

❌ **Forgetting to archive completed projects**
- Projects pile up in active/
- Instead: Archive to archive/YYYY-MM-name/ when complete

---

## 📋 Checklist for Starting New Project

- [ ] Create `projects/[project-name]/` directory
- [ ] Copy PROJECT.md, TASKS.md, NOTES.md templates
- [ ] Fill in PROJECT.md (objectives, scope, criteria)
- [ ] Break down into TASKS.md (#001, #002, etc.)
- [ ] Update ACTIVE.md with project status
- [ ] Create git branch: `git checkout -b [project-name]-001`
- [ ] Ready to start!

---

## 📋 Checklist for Each Work Session

**Start:**
- [ ] Read ACTIVE.md (current projects)
- [ ] Read PROJECT.md (context)
- [ ] Read TASKS.md (current status)
- [ ] Read NOTES.md (previous learnings)
- [ ] Pick next task

**During:**
- [ ] Work on task
- [ ] Test changes

**End:**
- [ ] Update TASKS.md (status, time spent)
- [ ] Update NOTES.md (learnings)
- [ ] Commit: `git commit -m "feat: [project-name] #XXX - description"`
- [ ] Log time/progress

---

## 🎓 Example: Complete Task Flow

```markdown
# aws-integration Project

## PROJECT.md
- Status: 🔄 IN PROGRESS
- Started: 2025-01-10
- Est. Completion: 2025-01-24

## TASKS.md

### #001 - Design SQS buffering approach
- Status: ✅ DONE (1 hr)

### #002 - Implement SQS Lambda trigger
- Status: ✅ DONE (2 hrs)

### #003 - Add error handling
- Status: ✅ DONE (1.5 hrs)

### #004 - Test with real messages
- Status: 🔄 IN PROGRESS (1 hr so far, est. 2 hrs total)
- Blocker: None
- Next: Test null attributes, then #005

## NOTES.md
### Architecture Decisions
- Chose SQS for buffering (async, reliable, scalable)

### Technical Discoveries
- Lambda cold start ~2s (included in timing)
- SQS latency <100ms (excellent)

### Gotchas
- Null message attributes crash parser
  - Symptom: Lambda fails on null
  - Fix: Add null check in #008

## Git History
- commit: "feat: aws-integration #001 - Design SQS buffering"
- commit: "feat: aws-integration #002 - Implement Lambda trigger"
- commit: "feat: aws-integration #003 - Add error handling"
- commit: "feat: aws-integration #004 - Test with real messages" [current]
```

---

**This is how Claude should execute projects. Clear structure, frequent updates, good documentation.**
