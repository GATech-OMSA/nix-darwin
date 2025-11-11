# Tasks for script-conversion

**Project Status**: 🔵 Planned (0/6 tasks complete)
**Total Effort**: ~12-15 hours

---

## #001 - Audit scripts directory

**Status**: 🔵 Todo
**Effort**: 1h
**Priority**: 🟡 Important
**Depends on**: None

**Description**:
Comprehensive audit of all scripts in `scripts/` directory to understand current landscape, categorize scripts by type, and identify characteristics relevant for conversion decisions.

**Definition of Done**:
- [ ] Complete inventory of all `.sh` files in `scripts/` (~26 scripts)
- [ ] Categorize scripts by purpose (validation, installation, health checks, etc.)
- [ ] Document script characteristics: LOC, complexity, dependencies
- [ ] Identify scripts already in Python (check-doc-links.py)
- [ ] Create initial audit spreadsheet/markdown table

**Maps to Success Criteria**: ✅ "Complete audit with priority matrix"

**Actions**:
1. List all `.sh` files: `ls -la scripts/*.sh`
2. For each script, document:
   - Purpose/function
   - Line count (`wc -l`)
   - Dependencies (external commands, tools)
   - Complexity indicators (loops, conditionals, text processing)
3. Note scripts with performance concerns (run frequently, process large data)
4. Identify scripts with maintainability issues (complex logic, hard to read)
5. Create audit table in NOTES.md

**Blockers**: None

---

## #002 - Create conversion priority matrix

**Status**: 🔵 Todo
**Effort**: 30min
**Priority**: 🟡 Important
**Depends on**: #001

**Description**:
Analyze audit results to create priority matrix scoring scripts on conversion value (complexity, performance needs, maintainability). Select 5-8 high-priority candidates for conversion.

**Definition of Done**:
- [ ] Scoring matrix created with 3 dimensions: complexity, performance, maintainability
- [ ] All scripts scored (1-5 scale for each dimension)
- [ ] 5-8 scripts identified as high-priority conversion candidates
- [ ] Conversion order determined (start with easiest high-value)
- [ ] Rationale documented for each priority candidate

**Maps to Success Criteria**: ✅ "Complete audit with priority matrix"

**Actions**:
1. Define scoring criteria:
   - Complexity (1=simple, 5=very complex logic)
   - Performance (1=not critical, 5=runs frequently/slow)
   - Maintainability (1=easy to read, 5=hard to maintain)
2. Score all scripts from audit
3. Calculate priority score (complexity + performance + maintainability)
4. Select top 5-8 scripts for conversion
5. Order by "ease of conversion" (start with moderate complexity, clear wins)
6. Document in NOTES.md

**Blockers**: None

---

## #003 - Convert priority script 1

**Status**: 🔵 Todo
**Effort**: 2-3h
**Priority**: 🟡 Important
**Depends on**: #002

**Description**:
Convert first high-priority script from bash to Python. Use check-doc-links.py as template for structure, error handling, and performance patterns. Validate functionality parity.

**Definition of Done**:
- [ ] Python version created matching original functionality
- [ ] Side-by-side testing shows identical outputs
- [ ] Performance benchmark documented (execution time comparison)
- [ ] Code complexity metrics improved (line count, readability)
- [ ] Original script backed up as `.sh.bak`
- [ ] Conversion notes documented in NOTES.md

**Maps to Success Criteria**: ✅ "5-8 scripts converted with >= original functionality" + "Performance benchmarks documented"

**Actions**:
1. Study original script to understand all functionality
2. Create Python skeleton using check-doc-links.py patterns
3. Convert main logic preserving all features
4. Add error handling and edge cases
5. Test with same inputs as original:
   ```bash
   time scripts/original.sh [args]
   time scripts/original.py [args]
   diff <(scripts/original.sh) <(scripts/original.py)
   ```
6. Document performance improvement
7. Commit: `git commit -m "feat: Convert [script] to Python (Xx speedup)"`

**Blockers**: None

---

## #004 - Convert priority script 2

**Status**: 🔵 Todo
**Effort**: 2-3h
**Priority**: 🟡 Important
**Depends on**: #003

**Description**:
Convert second high-priority script. Apply learnings from first conversion to improve process efficiency.

**Definition of Done**:
- [ ] Python version created matching original functionality
- [ ] Side-by-side testing shows identical outputs
- [ ] Performance benchmark documented
- [ ] Code complexity metrics improved
- [ ] Original script backed up as `.sh.bak`
- [ ] Conversion notes documented in NOTES.md

**Maps to Success Criteria**: ✅ "5-8 scripts converted with >= original functionality" + "Performance benchmarks documented"

**Actions**:
1. Apply conversion template from #003
2. Identify script-specific challenges
3. Convert with functionality parity
4. Validate and benchmark
5. Document improvements and patterns
6. Commit with performance metrics

**Blockers**: None

---

## #005 - Convert priority script 3

**Status**: 🔵 Todo
**Effort**: 2-3h
**Priority**: 🟡 Important
**Depends on**: #004

**Description**:
Convert third high-priority script. Continue refining conversion process and patterns.

**Definition of Done**:
- [ ] Python version created matching original functionality
- [ ] Side-by-side testing shows identical outputs
- [ ] Performance benchmark documented
- [ ] Code complexity metrics improved
- [ ] Original script backed up as `.sh.bak`
- [ ] Conversion notes documented in NOTES.md

**Maps to Success Criteria**: ✅ "5-8 scripts converted with >= original functionality" + "Performance benchmarks documented"

**Actions**:
1. Apply refined conversion template
2. Convert with functionality parity
3. Validate and benchmark
4. Document improvements
5. Commit with metrics

**Blockers**: None

**Progress Notes**:
*Note: Tasks #006-#008 for scripts 4-6 can be added based on progress and priority adjustments after first 3 conversions*

---

## #006 - Document conversion patterns

**Status**: 🔵 Todo
**Effort**: 1h
**Priority**: 🟢 Standard
**Depends on**: #005

**Description**:
Synthesize learnings from conversions into reusable documentation. Create guide for future script conversions including patterns, performance tips, and common pitfalls.

**Definition of Done**:
- [ ] Conversion guide created in NOTES.md or docs/
- [ ] Common bash → Python patterns documented
- [ ] Performance optimization techniques listed
- [ ] Testing/validation checklist created
- [ ] Before/after metrics summary table created
- [ ] Recommendations for future conversions documented

**Maps to Success Criteria**: ✅ "Conversion pattern documentation for future reference"

**Actions**:
1. Review all conversion notes from #003-#005
2. Extract common patterns:
   - Text processing (bash vs Python)
   - File operations (bash vs Python)
   - Error handling patterns
   - Performance optimization techniques
3. Create decision framework: "When to use bash vs Python"
4. Document testing methodology
5. Create metrics summary table:
   ```
   | Script | Original LOC | Python LOC | Speedup | Reduction |
   |--------|--------------|------------|---------|-----------|
   ```
6. Add recommendations for remaining scripts

**Blockers**: None

---

## Progress Summary

| Task | Status | Effort | Depends On |
|------|--------|--------|------------|
| #001 | 🔵 Todo | 1h | None |
| #002 | 🔵 Todo | 30min | #001 |
| #003 | 🔵 Todo | 2-3h | #002 |
| #004 | 🔵 Todo | 2-3h | #003 |
| #005 | 🔵 Todo | 2-3h | #004 |
| #006 | 🔵 Todo | 1h | #005 |

**Completion**: 0% (0/6 tasks)
**Total Effort**: ~12-15 hours
