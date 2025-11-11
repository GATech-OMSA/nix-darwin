# Backlog - New Items Intake

**Purpose**: Lightweight intake queue for new work items
**Review**: Weekly grooming to assess priority and create projects
**Last Updated**: 2025-11-09 (Added: enhanced secret scanning, secret management scripts)

---

## 🐛 Bugs (Fix existing issues)

- **Env file scanning not detecting .env* files** - Pattern-based env file detection may not be working
  - Impact: 🟡 Medium (affects secret discovery completeness)
  - Effort: 1-2 hours (debug find command, test across patterns)
  - Discovered: 2025-11-09 during configure.sh testing with .env.test
  - Location: configure.sh lines 737-746
  - Test case: Create ~/.env.test, run scan, verify appears in secrets.yaml
  - Added: 2025-11-09

<!--
- **[Bug name]** - Description
  - Impact: 🔥 Critical / 🔴 High / 🟡 Medium / 🟢 Low
  - Effort: X hours
  - Discovered: Context/date
  - Added: YYYY-MM-DD
-->

---

## ✨ Enhancements (Improve existing features)

- **Enhanced Secret Scanning** - Comprehensive secret discovery with deeper traversal and more patterns
  - Impact: 🟡 Medium (improves completeness of secret discovery, reduces manual work)
  - Effort: 2-3 hours (deeper traversal, pattern expansion, age key detection)
  - Context: Current scanning is shallow (top-level only) and missing patterns
  - Benefits:
    - Fix `.env*` pattern detection bug (related to existing bug)
    - Deeper directory traversal (not just top-level files)
    - Age key auto-detection (for env vars, not encryption)
    - More file patterns (database configs, cloud credentials, etc.)
    - Better coverage reduces manual secret entry burden
  - Location: configure.sh secret scanning section
  - Related: Consolidates with "Env file scanning" bug in Bugs section
  - Added: 2025-11-09

- **Secret Management Convenience Scripts** - User-friendly wrappers for common secret operations
  - Impact: 🟡 Medium (major UX improvement, reduces friction)
  - Effort: 3-4 hours (4 scripts + documentation + testing)
  - Context: Users need to remember SOPS commands and encryption workflows
  - Scripts to create:
    - `edit-secrets` - Direct SOPS editing wrapper (handles encrypt/decrypt transparently)
    - `rescan-secrets` - Backup → rescan → merge → encrypt workflow
    - `backup-secrets` - Create timestamped backups of secrets.yaml
    - `view-secrets` - View decrypted secrets without editing
  - Features:
    - All handle encryption/decryption automatically
    - Smart backup before destructive operations
    - Merge logic (preserve existing + add new discoveries)
    - Clear error messages if age keys mismatch
  - Benefits: Lower barrier to secret management, less error-prone
  - Added: 2025-11-09

<!--
- **[Enhancement name]** - Description
  - Impact: 🔥 Critical / 🔴 High / 🟡 Medium / 🟢 Low
  - Effort: X hours
  - Context: Why this matters
  - Added: YYYY-MM-DD
-->

---

## 🚀 Features (New capabilities)

*No features in backlog*

<!--
- **[Feature name]** - Description
  - Impact: 🔥 Critical / 🔴 High / 🟡 Medium / 🟢 Low
  - Effort: X hours
  - Context: User need or problem this solves
  - Added: YYYY-MM-DD
-->

---

## 🧹 Technical Debt

*No technical debt in backlog*

<!--
- **[Debt item]** - Description
  - Impact: 🔥 Critical / 🔴 High / 🟡 Medium / 🟢 Low
  - Effort: X hours
  - Context: Why this technical debt matters
  - Added: YYYY-MM-DD
-->

---

## 📚 Documentation

*No documentation items in backlog*

<!--
- **[Doc improvement]** - Description
  - Impact: 🔥 Critical / 🔴 High / 🟡 Medium / 🟢 Low
  - Effort: X hours
  - Context: What's missing or unclear
  - Added: YYYY-MM-DD
-->

---

## ✅ Recently Groomed (Moved to Projects)

- **Convert Shell Scripts to Python** → projects/script-conversion/ (2025-11-08)
  - Original impact: 🟡 Medium (performance, maintainability, cross-platform)
  - Project status: 🔵 Planned (0/6 tasks, ~12-15 hours)
  - Notes: Builds on check-doc-links.py success (14x speedup, 3x code reduction)

<!--
- **[Item name]** → projects/[name]/ (YYYY-MM-DD)
  - Original impact: Impact level
  - Project status: 🔵 Planned / 🟢 Active / ✅ Complete
-->

---

## Review Process

### When to Add Items

Add to backlog when:
- Discovering bugs or issues during development
- Identifying technical debt that should be addressed
- Getting feature requests or enhancement ideas
- Finding gaps in documentation or tooling
- Quick ideas that need later evaluation

### Impact Levels

Use these to prioritize work:

- 🔥 **Critical** - System broken, blocks all work, security issue, data loss risk
- 🔴 **High** - Significant user impact, blocks important work, major productivity gain
- 🟡 **Medium** - Noticeable improvement, quality of life enhancement
- 🟢 **Low** - Nice to have, minor improvement, polish

### Effort Estimation

- **Small**: <2 hours, single file, straightforward
- **Medium**: 2-4 hours, multiple files, moderate complexity
- **Large**: >4 hours, architectural change, significant scope

### Priority Matrix

```
High Impact + Low Effort  → Groom immediately (Quick wins)
High Impact + High Effort → Groom strategically (Plan carefully)
Low Impact + Low Effort   → Groom when capacity (Fill gaps)
Low Impact + High Effort  → Archive or defer (Low ROI)
```

### Grooming Process

**Weekly review** (or when ready for new work):

1. **Review items** by impact and effort
2. **Group related items** - Multiple related bugs/features → single project
3. **Create project**:
   ```bash
   mkdir -p projects/[project-name]/
   cp templates/PROJECT.md projects/[project-name]/
   cp templates/TASKS.md projects/[project-name]/
   cp templates/NOTES.md projects/[project-name]/
   ```
4. **Fill project templates** from backlog items
5. **Update ACTIVE.md** → Add to 📋 Planned section
6. **Clean backlog** → Move items to "Recently Groomed" section

---

## Archive (Deferred/Won't Do)

*No archived items*

<!--
- **[Item name]** - Brief description
  - Reason: Why deferred/rejected
  - Archived: YYYY-MM-DD
-->
