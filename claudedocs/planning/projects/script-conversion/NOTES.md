# Notes: script-conversion

**Project**: script-conversion
**Status**: 🔵 Planned
**Last Updated**: 2025-11-08

---

## Session Log

### Session 2025-11-08 - Project Setup
- Created project structure in `claudedocs/planning/projects/script-conversion/`
- Groomed from BACKLOG.md (Technical Debt section)
- 6 tasks defined (~12-15 hours total effort)
- Ready to start when capacity available

---

## Design Decisions

### Decision: Python as Target Language
**Date**: 2025-11-08
**Context**: Need to modernize shell scripts for better performance and maintainability
**Decision**: Convert high-value scripts from bash to Python 3.13
**Alternatives Considered**:
- Keep all bash (status quo) - Rejected: Performance and maintainability issues
- Convert to Go/Rust - Rejected: Overkill for scripting, larger learning curve
- Use compiled bash (shc) - Rejected: Doesn't address maintainability
**Consequences**:
- ✅ Significant performance improvements (14x seen in check-doc-links)
- ✅ Better cross-platform compatibility
- ✅ Easier to maintain and debug
- ⚠️ Need Python available (already in Nix config)
- ⚠️ Some bash-specific features may be harder to replicate

### Decision: Incremental Conversion Approach
**Date**: 2025-11-08
**Context**: ~26 scripts to potentially convert
**Decision**: Convert 5-8 high-priority scripts first, keep bash for simple wrappers
**Alternatives Considered**:
- Convert all scripts - Rejected: Too risky, some scripts work fine as bash
- Keep all bash - Rejected: Missing performance/maintainability gains
**Consequences**:
- ✅ Lower risk (incremental validation)
- ✅ Learn patterns from early conversions
- ✅ Flexibility to adjust approach
- ⚠️ Codebase will have mix of bash/Python temporarily

---

## Learnings

### What Worked Well (Baseline: check-doc-links.py)
- Path library for clean file operations
- Regex for robust pattern matching
- Set operations for deduplication
- Minimal subprocess calls (avoid shelling out)
- Clear error messages with context

### Success Metrics from Baseline
- **Performance**: 14x speedup (0.456s → 0.033s)
- **Code Quality**: 3x reduction (213 lines → 63 lines)
- **Readability**: Significantly improved (Python vs complex bash)

### What to Watch Out For
- Bash-specific features (process substitution, etc.)
- Performance assumptions may not hold for all scripts
- Testing needs to be thorough (functionality parity critical)

---

## Technical Details

### Audit Structure (Task #001)

*To be filled: Comprehensive inventory*

**Template**:
```
| Script | LOC | Purpose | Complexity | Performance | Maintainability | Dependencies |
|--------|-----|---------|------------|-------------|-----------------|--------------|
```

### Priority Matrix (Task #002)

*To be filled: Scoring and prioritization*

**Scoring Criteria**:
- Complexity (1=simple, 5=very complex)
- Performance (1=not critical, 5=runs frequently/slow)
- Maintainability (1=easy, 5=hard to maintain)
- **Priority Score** = Sum of scores

### Conversion Notes

#### Script 1 (Task #003)
*To be filled during conversion*

#### Script 2 (Task #004)
*To be filled during conversion*

#### Script 3 (Task #005)
*To be filled during conversion*

### Performance Measurement

**Methodology**:
```bash
# Before conversion
time scripts/script-name.sh [args]

# After conversion
time scripts/script-name.py [args]

# Validation
diff <(scripts/script-name.sh) <(scripts/script-name.py)
```

**Metrics to Track**:
- Execution time (real, user, sys)
- Line count reduction
- Code complexity (cyclomatic if available)
- Memory usage (if relevant)

---

## Patterns & Best Practices (Task #006)

*To be synthesized from conversion experiences*

### Common Bash → Python Patterns
*To be documented after conversions*

### Performance Optimization Techniques
*To be documented after conversions*

### Testing & Validation Checklist
*To be created based on conversion learnings*

---

## Future Recommendations

*To be filled after completing initial conversions*

### Scripts to Convert Next
*Prioritized list after validation of approach*

### Scripts to Keep as Bash
*With rationale - simple wrappers, system integration, one-liners*

---

## References

- Baseline conversion: scripts/check-doc-links.py (commit from 2025-11-07)
- Python 3.13 docs: https://docs.python.org/3.13/
- Backlog item: BACKLOG.md Technical Debt section
