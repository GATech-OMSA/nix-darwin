# Project: script-conversion

**Status**: 🔵 Planned
**Started**: Not started
**Estimated Completion**: ~12-15 hours
**Priority**: 🟡 Important

---

## Objective

Modernize shell scripts to Python for improved performance, maintainability, and cross-platform compatibility. Build on the success of `check-doc-links.py` conversion (14x speedup, 3x code reduction) by converting high-value scripts in the repository.

---

## Scope

### ✅ In Scope

- Audit all scripts in `scripts/` directory (~26 files)
- Create priority matrix based on: complexity, performance needs, maintenance burden
- Convert 5-8 high-priority scripts to Python
- Document conversion patterns and performance improvements
- Maintain functionality parity with original scripts
- Create testing validation for converted scripts

### ❌ Out of Scope

- Converting ALL scripts (keep bash for simple wrappers, system integration)
- Rewriting scripts that work well as bash (one-liners, simple file operations)
- Creating new features beyond original script capabilities
- Comprehensive test framework (basic validation only)
- Converting scripts outside `scripts/` directory

---

## Success Criteria

- [ ] Complete audit with priority matrix (complexity, performance, maintainability scores)
- [ ] 5-8 scripts converted with >= original functionality
- [ ] Performance benchmarks documented (execution time comparison)
- [ ] Code complexity metrics show improvement (line count, readability)
- [ ] All converted scripts validated (functionality testing)
- [ ] Conversion pattern documentation for future reference

---

## Dependencies

**Prerequisites** (must complete first):
- ✅ Python 3.13 installed via Nix (already available)
- ✅ check-doc-links.py conversion complete (provides conversion template)

**Cross-Project Blockers** (this project blocks other projects):
- None

**Enables** (what this unlocks):
- Future script modernization efforts
- Performance optimization opportunities
- Better cross-platform compatibility
- Easier maintenance and debugging

**Context**: The successful `check-doc-links.sh` → `check-doc-links.py` conversion demonstrated significant gains (14x speedup: 0.456s → 0.033s, 3x code reduction: 213 → 63 lines). Many other scripts in the repository have similar characteristics (complex logic, text processing, performance-critical) that would benefit from Python conversion.

---

## Timeline

| Task | Duration | Cumulative |
|------|----------|------------|
| #001: Audit scripts directory | 1h | 1h |
| #002: Create priority matrix | 30min | 1.5h |
| #003: Convert priority script 1 | 2-3h | 3.5-4.5h |
| #004: Convert priority script 2 | 2-3h | 5.5-7.5h |
| #005: Convert priority script 3 | 2-3h | 7.5-10.5h |
| #006: Document conversion patterns | 1h | 8.5-11.5h |

**Total**: ~12-15 hours (depends on script complexity)

---

## Safety Strategy

**Testing approach**:
- Run original script and Python version side-by-side with same inputs
- Compare outputs for parity
- Validate edge cases and error handling
- Performance benchmarking before/after

**Backup plan**:
- Keep original `.sh` files as `.sh.bak` during conversion
- Only delete originals after validation passes
- Git history preserves all originals

**Risk mitigation**:
- Convert one script at a time with validation
- Test on non-critical scripts first
- Document any behavior changes

---

## Risk Assessment

### Low Risk Factors
- Python 3.13 already available in Nix configuration
- Successful conversion template exists (check-doc-links.py)
- Original scripts preserved in git history
- Incremental approach (one script at a time)

### Medium Risk Factors
- Some scripts may have bash-specific features hard to replicate
- Performance assumptions may not hold for all scripts
- Time estimates depend on script complexity

### Safety Guarantees
1. All originals preserved in git history before deletion
2. Validation required before removing original
3. Incremental conversion (no big-bang approach)
4. Rollback via git revert if issues discovered

### Rollback Procedures
```bash
# If conversion causes issues, restore original:
git checkout HEAD -- scripts/script-name.sh
git rm scripts/script-name.py

# Or revert entire conversion commit:
git revert <commit-hash>
```
