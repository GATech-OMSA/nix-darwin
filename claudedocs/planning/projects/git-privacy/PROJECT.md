# Project: git-privacy

**Status**: 🟢 In Progress
**Started**: 2025-11-09
**Estimated Completion**: ~157 minutes (57 min complete, 100 min remaining)
**Priority**: 🟡 Important

---

## Objective

Remove hardcoded personal data from git repository and implement user-agnostic configuration pattern.

---

## Scope

### ✅ In Scope

- Refactor git.nix and node.nix to read from userConfig (gitignored)
- Create user-config.nix and machine-config.nix templates
- **Create home/_template/ directory** (doesn't exist yet - copy from home/jimmy/)
- **Move personal directories to archive/** (hosts/mbp-jimmy, hosts/mbp-work, home/jimmy → gitignored archive/)
- Update .gitignore to exclude personal host/home configs AND archive directories
- Create host templates (personal.nix.template, work.nix.template)
- **Enhance setup.sh to create home/{username}/ directory** from template
- **Remove hardcoded fallbacks in flake.nix** (force config file requirement)
- Remove ALL personal identifiers from tracked files (jimmy, jain, jimmie, example-corp)
- Remove personal names from directory paths (mbp-jimmy, mbp-work, home/jimmy)
- Test on personal machine first, then apply to work machine
- Update documentation with setup instructions
- Create local backup branch for work configuration safety
- **Brainstorm documentation privacy updates** (remove personal examples from docs)

### ❌ Out of Scope

- Changing existing functionality or behavior
- Modifying packages, aliases, or tool configurations
- Altering system settings or architecture
- Adding new features beyond privacy hardening

---

## Success Criteria

- [ ] No personal data (name, emails) in tracked git files
- [ ] **No personal identifiers in tracked files**: jimmy, jain, jimmie, example-corp completely removed
- [ ] **No personal names in directory paths**: mbp-jimmy, mbp-work, home/jimmy all gitignored
- [ ] User-agnostic configuration fully implemented
- [ ] Both machines (personal + work) working with config files
- [ ] Work configuration backed up safely in local branch
- [ ] Templates available for new users (hosts/_template/, home/_template/)
- [ ] **setup.sh creates both hosts/ AND home/ directories** from templates
- [ ] Build success rate: 100%
- [ ] Functionality preservation: 100%
- [ ] Documentation completeness: 100%

---

## Dependencies

**Prerequisites** (all complete ✅):
- ✅ User-agnostic templates created for config files (Phase 6 #042)
- ✅ Setup wizard functional for config + hosts (#045)
- ✅ Config discovery system working (#046)

**Enhancements in this project**:
- ⚙️ Enhance setup.sh to create home/{username}/ directory (currently only creates hosts/)
- ⚙️ Create home/_template/ directory (doesn't exist yet)
- ⚙️ Remove hardcoded fallbacks in flake.nix (force config file requirement)

**Context**: Phase 6 created templates and user-agnostic infrastructure, but actual configuration files AND directory names still contain hardcoded personal data. This work completes the refactoring by moving all personal data to gitignored files AND removing personal identifiers from all tracked files/directories.

---

## Timeline

| Task | Duration | Cumulative |
|------|----------|------------|
| #001: Setup & Backup | 5 min | 5 min |
| #002: Create home/_template/ | 10 min | 15 min |
| #003: Clean hosts/_template/ | 5 min | 20 min |
| #004: Archive personal directories | 5 min | 25 min |
| #005: Update .gitignore | 2 min | 27 min |
| #006: Split setup scripts | 25 min | 52 min |
| #007: Remove hardcoded fallbacks | 5 min | 57 min |
| #008: Create recovery point | 5 min | 62 min |
| #009: Create secret templates | 15 min | 77 min |
| #010: Update template default.nix | 10 min | 87 min |
| #011: Enhance configure.sh (Homebrew) | 10 min | 97 min |
| #012: Add secret scanning | 20 min | 117 min |
| #013: Add review step | 20 min | 137 min |
| #014: Update activate.sh | 10 min | 147 min |
| #015: Test personal machine | 20 min | 167 min |
| #016: Apply to work machine | 15 min | 182 min |
| #017: Brainstorm doc updates | (pending) | - |

**Total**: ~157 minutes (excluding #017)

---

## Safety Strategy

**Testing approach**: Test on personal machine first, apply to work only after validation
**Backup plan**: Local backup branch `backup/work-config-real` (DO NOT PUSH)
**Rollback procedure**: `nix-rollback` + `git reset` or restore from backup branch

---

## Risk Assessment

### Low Risk Factors
- Changes tested on personal machine first
- Work config backed up locally before changes
- Build validation before applying
- Clear rollback procedures
- Only location of data changes, not values

### Safety Guarantees
1. **No data loss**: Backup branch preserves original
2. **Incremental testing**: Personal first, work second
3. **Validation gates**: Build test before apply
4. **Quick rollback**: `nix-rollback` + `git reset`
5. **Settings preserved**: All packages, aliases, functions unchanged
