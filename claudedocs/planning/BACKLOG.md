# Backlog - New Items Intake

Lightweight intake queue for new improvement ideas. Items are periodically reviewed, prioritized, and moved to PROGRESS.md for execution.

**Last Updated**: 2025-11-06

---

## Intake Queue (Unprioritized)

- [ ] **Convert Shell Scripts to Python**: Convert appropriate shell scripts to Python for better performance and maintainability
  - **Type**: Technical Debt / Enhancement
  - **Context**: Link checker conversion (bash → Python) showed 14x performance improvement (0.456s → 0.033s) and 3x code reduction (213 → 63 lines). Other shell scripts may benefit from similar conversion.
  - **Components**:
    1. Audit existing scripts in `scripts/` directory
    2. Identify candidates: complex logic, text processing, performance-critical
    3. Keep bash for: simple wrappers, system integration, one-liners
    4. Convert prioritized scripts maintaining functionality
  - **Candidates**: TBD after audit
  - **Impact**: Medium - Improved performance, maintainability, and cross-platform compatibility
  - **Effort**: Medium (2-4h per script) - depends on complexity and number of scripts
  - **Dependencies**: None
  - **Added**: 2025-11-07
  - **Triggered By**: Successful `check-doc-links.sh` → `check-doc-links.py` conversion

- [ ] **True User-Agnostic Configuration with Setup Wizard**: Enable anyone to clone repo and setup without editing hardcoded usernames
  - **Type**: New Feature / Enhancement
  - **Context**: Phase 2 achieved machine-type agnostic (personal/work detection) but still requires manual edits to username/directories. Current setup has hardcoded "jimmy" in `home/jimmy/`, `flake.nix`, and host configs. True agnosticism means zero manual edits - clone, run wizard, done.
  - **Components**:
    1. Interactive setup wizard (`./setup.sh`) - prompts for username, email, machine type, hostname
    2. Template-based user directory generation (`home/${username}/` from template)
    3. Auto-generated flake.nix configuration
    4. Template-based host scaffolding (copy template → customize)
    5. Zero-config first run experience
  - **User Journey**: Clone → `./setup.sh` → Answer prompts → Auto-configured system ready
  - **Impact**: High - Makes repo truly reusable by community, not just personal use
  - **Effort**: Large (8-12 hours) - template system, wizard UI, dynamic directory structure
  - **Dependencies**: Phase 3 template system (#3.3 in PROGRESS.md)
  - **Added**: 2025-11-06

<!--
Template for adding new items:

- [ ] **Item Name**: Brief description
  - **Type**: Bug Fix / Enhancement / New Feature / Technical Debt
  - **Context**: Problem statement and motivation
  - **Effort**: Unknown / Small (<2h) / Medium (2-4h) / Large (>4h)
  - **Added**: YYYY-MM-DD

-->

---

## Review Process

### When to Add Items

Add to backlog when:
- Discovering bugs or issues during development
- Identifying technical debt that should be addressed
- Getting feature requests or enhancement ideas
- Finding gaps in documentation or tooling

### Prioritization Framework

During periodic review, evaluate each item:

1. **Impact Assessment**:
   - 🔴 **Critical**: Blocks work, security issue, data loss risk
   - 🟡 **High**: Significant productivity improvement, quality enhancement
   - 🟢 **Medium**: Nice-to-have, minor improvement
   - ⚪ **Low**: Polish, optimization, future consideration

2. **Effort Estimation**:
   - **Small**: <2 hours, single file, straightforward
   - **Medium**: 2-4 hours, multiple files, moderate complexity
   - **Large**: >4 hours, architectural change, significant scope

3. **Priority Matrix**:
   ```
   High Impact + Low Effort  → Phase 1-2 (Quick wins)
   High Impact + High Effort → Phase 2-3 (Strategic)
   Low Impact + Low Effort   → Phase 4-5 (Polish)
   Low Impact + High Effort  → Archive (Defer/Skip)
   ```

### Moving to Execution

Once prioritized:
1. Assign to appropriate phase in PROGRESS.md
2. Add task number (e.g., #3.9)
3. Document dependencies and success criteria
4. Remove from BACKLOG.md intake queue

---

## Archive (Deferred/Won't Do)

*No archived items*

<!--
Template for archived items:

- **Item Name**: Brief description
  - **Reason**: Why deferred/rejected
  - **Archived**: YYYY-MM-DD

-->
