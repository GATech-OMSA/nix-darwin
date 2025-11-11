# Documentation & Changelog Guidelines

**Prevent markdown sprawl. Keep docs maintainable.**

---

## 📋 When to CREATE New Documentation

### YES – Create New Docs For:

✅ **Major architectural changes**
- New system design patterns
- Significant refactoring that changes how things work
- New infrastructure components (e.g., "Added AWS Lambda integration guide")

✅ **New user-facing features**
- New tool workflows
- New package groups or library functions
- Process changes that affect daily usage

✅ **Critical knowledge that doesn't fit existing docs**
- New guide type needed (e.g., "Multi-machine setup guide")
- New reference section (e.g., "Kubernetes reference")
- Standalone troubleshooting for complex systems

### NO – Don't Create New Docs For:

❌ **Small fixes, tweaks, improvements**
- Bug fixes in existing code
- Minor performance improvements
- Small feature additions to existing functionality

❌ **Internal refactoring**
- Code reorganization
- Optimization
- Dependency updates

❌ **Documentation that's already covered**
- Information that fits in existing guides
- Supplementary details for covered topics
- Variations of documented processes

---

## 🔄 When to UPDATE Existing Documentation

### YES – Update Docs For:

✅ **Major feature additions** to existing systems
- New major option to existing tool
- Expanded capability that changes usage
- New section in existing guide (e.g., add Python UV setup to Languages Reference)

✅ **Breaking changes**
- API changes that affect usage
- Command syntax changes
- Configuration structure changes

✅ **Major bug fixes** that affect user workflow
- Workaround removal (process simplified)
- Fixed behavior that users depend on

✅ **Clarifications for frequently asked questions**
- Pattern that users keep asking about
- Gotcha that users keep hitting
- Better explanation of existing feature

### NO – Don't Update Docs For:

❌ **Small fixes**
- Single-line bug fixes
- Minor improvements
- Edge case fixes

❌ **Internal optimizations**
- Performance improvements users don't see
- Code quality improvements
- Refactoring that doesn't change behavior

❌ **Version bumps**
- Package updates
- Dependency version changes
- Non-breaking updates

---

## 📝 Changelog Management

### CHANGELOG Format

**Location:** `docs/appendix/faq.md` (Changelog section)

**Format:**
```markdown
## Changelog

### [YYYY-MM-DD] - Brief Title

**Major Changes:**
- Change 1
- Change 2

**Breaking Changes:**
- Breaking change 1

**New Features:**
- Feature 1
- Feature 2

**Improvements:**
- Improvement 1

**Bug Fixes:**
- Fix 1
```

---

## When to UPDATE the Changelog

### YES – Update Changelog For:

✅ **Major features**
- New integration (e.g., "Added Lambda routing for aws-integration")
- New system capability
- Significant user-facing improvement

✅ **Breaking changes**
- Command changes
- Configuration structure changes
- Behavior changes users depend on

✅ **Architecture changes**
- System redesign
- New architectural pattern
- Significant refactoring visible to users

✅ **Major bug fixes**
- Fixes that change user workflow
- Fixes for significant issues
- Workaround removal

### NO – Don't Update Changelog For:

❌ **Small bug fixes**
- Single-line fixes
- Edge case fixes
- Internal bugs users don't notice

❌ **Minor improvements**
- Performance tweaks
- Code quality improvements
- Refactoring

❌ **Documentation updates**
- Adding docs
- Clarifying docs
- Grammar/clarity in existing docs

❌ **Version bumps**
- Package updates
- Dependency updates
- Non-breaking updates

❌ **Small feature additions**
- One-off improvements
- Options/flags
- Variations on existing features

---

## 📊 Decision Matrix

| Change Type | Create New Doc? | Update Doc? | Update Changelog? |
|---|---|---|---|
| Bug fix (small) | ❌ No | ❌ No | ❌ No |
| Bug fix (major/breaking) | ❌ No | ✅ Yes (affected guide) | ✅ Yes |
| Feature (small) | ❌ No | ✅ Yes (existing section) | ❌ No |
| Feature (major) | ✅ Yes (if new type) | ✅ Yes (if exists) | ✅ Yes |
| Architecture change | ✅ Yes | ✅ Yes (multiple) | ✅ Yes |
| Refactoring (invisible) | ❌ No | ❌ No | ❌ No |
| Optimization | ❌ No | ❌ No | ❌ No |
| Version bump | ❌ No | ❌ No | ❌ No |
| Security patch | ❌ No | ✅ Yes (if significant) | ✅ Yes (if critical) |

---

## 📚 Examples

### Example 1: Add Python UV Support

**Scenario:** Add UV (fast venv) support to system

**What to do:**
- ✅ Update: `docs/reference/languages.md` (add UV section)
- ✅ Update: Changelog (feature addition)
- ❌ Don't create: New doc (fits in existing Languages Reference)

**Changelog entry:**
```markdown
### [2025-01-20] - Python UV Support

**New Features:**
- Added UV for fast project virtual environments
- Auto-activation of `.venv` directories
```

---

### Example 2: Fix Zsh Alias Bug

**Scenario:** Git alias `g s` was returning wrong status

**What to do:**
- ✅ Update: `home/jimmy/programs/git.nix` (fix code)
- ❌ Don't update docs: (behavior didn't change, just fixed)
- ❌ Don't update changelog: (internal fix, users don't care)

**Reasoning:** Bug was internal, fix restores expected behavior, no user communication needed.

---

### Example 3: Add AWS Multi-Role System

**Scenario:** Implement new AWS IAM role switching for work Mac

**What to do:**
- ✅ Create: `claudedocs/reference/aws/AWS-MULTI-ROLE.md` (new system)
- ✅ Update: `docs/reference/infrastructure.md` (link to new guide)
- ✅ Update: Changelog (major feature)

**Changelog entry:**
```markdown
### [2025-01-15] - AWS Multi-Role System

**Major Features:**
- Added AWS IAM role switching for work environment
- New commands: awslogin, awswho for role management
- See AWS Multi-Role Guide for details
```

---

### Example 4: Refactor Nix Module

**Scenario:** Reorganize shell configuration for cleanliness

**What to do:**
- ✅ Update: Code (refactor)
- ❌ Don't update docs: (no behavior change)
- ❌ Don't update changelog: (internal refactoring)

**Reasoning:** Refactoring is internal; users don't see or care about the change.

---

## 🎯 Guidelines for Claude

### Create New Documentation When:

1. **New user-facing system** that needs explanation
   - Not: "I added a function" (belongs in code comments)
   - Yes: "I created a new workflow for X" (needs guide)

2. **New reference material** that's substantial
   - Not: "I added a new alias" (goes in existing shell reference)
   - Yes: "I documented a new tool integration" (needs reference section)

3. **Complex enough that users ask "how do I...?"**
   - If: Users will ask about it → document it
   - If: Obvious from context → don't document it

### Update Existing Documentation When:

1. **Existing section grows significantly**
   - Add subsection to existing guide
   - Add new section to existing reference
   - Update table of contents

2. **Process changes affect existing workflows**
   - Update affected guide
   - Update relevant reference
   - Add note to related sections

3. **Clarification is needed** for existing feature
   - Add example to existing section
   - Add troubleshooting entry
   - Add FAQ item

### Skip Documentation For:

1. **Every small change**
   - Bug fixes: Don't document
   - Tweaks: Don't document
   - Refactoring: Don't document

2. **Things that don't affect users**
   - Internal optimizations
   - Code cleanup
   - Dependency updates

3. **Things already documented**
   - Variation on documented feature
   - New option to existing tool
   - Incremental improvement

---

## 🚫 Prevent Markdown Sprawl

### Anti-Patterns to Avoid:

❌ **One doc per task**
- Creates: TASK-001.md, TASK-002.md, etc.
- Instead: Keep tasks in TASKS.md, only document finished patterns

❌ **Documentation for everything**
- Creates docs for every small improvement
- Instead: Only document major changes

❌ **Duplicate documentation**
- Same info in multiple places
- Instead: Link to canonical source

❌ **Project-specific docs that belong in guides**
- Creates: `PROJECT-AWS.md`, `PROJECT-SHELL.md`
- Instead: Add to appropriate reference guide

---

## ✅ Good Practices

✅ **Consolidate related changes**
- Multiple small improvements → One changelog entry
- Related features → One guide with sections

✅ **Link instead of duplicate**
- Refer to existing docs
- Link to canonical source
- Add summary, then link for details

✅ **Update existing structure**
- Add sections to existing guides
- Expand existing reference
- Don't create parallel docs

✅ **Keep changelog high-level**
- Summary of significant changes
- Not every commit
- Grouped by feature/type

---

## 📋 Checklist for Claude

Before creating a new document, ask:

- [ ] Is this major/significant enough to deserve its own doc?
- [ ] Does this already fit in an existing guide/reference?
- [ ] Will users actively reference this multiple times?
- [ ] Or should I just add a section to existing docs?

Before updating the changelog, ask:

- [ ] Is this a major feature or breaking change?
- [ ] Will users care about this change?
- [ ] Does this affect user workflow or capability?
- [ ] Or is this internal/minor?

---

## 🎯 Summary

| Decision | Ask | Answer |
|---|---|---|
| **Create new doc?** | "Will users actively reference this?" | Yes → Create. No → Add to existing. |
| **Update doc?** | "Does this significantly change usage?" | Yes → Update. No → Skip. |
| **Update changelog?** | "Is this major/breaking/user-visible?" | Yes → Update. No → Skip. |

**Goal:** Keep docs maintainable. Only document what users need to know.
