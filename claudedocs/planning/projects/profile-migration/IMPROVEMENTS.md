# Improvement Opportunities - Profile Migration

**Source:** Comprehensive audit of 22 files (8,137+ lines)
**Created:** 2025-11-09
**Status:** Catalogued from Phase 1 audit findings

---

## High Priority (Must Address in Migration)

### 1. Remove Alias Duplication (zsh.nix ↔ personal.nix)

**Issue:** learning, ollama aliases duplicated in both files

**Current State:**
- `zsh.nix` lines 199-204: learning, aiml, algo, courses, experiments, oss
- `zsh.nix` lines 331-334: ollama-start, models, llama3, codellama
- `personal.nix` lines 78-82: learning, courses, experiments, oss, aiml (same aliases)
- `personal.nix` lines 106-109: ollama-start, models, llama3, codellama (same aliases)

**Impact:** Confusion about which file controls these aliases

**Recommendation:**
- Keep in `personal.nix` ONLY (profile-specific)
- Remove from `zsh.nix` (universal base)
- Add missing `algo` alias to `personal.nix`

**Effort:** 30 minutes

---

### 2. Starship Configuration Per-Profile

**Issue:** starship.toml currently shared across all machines

**Current State:**
- `home/_mixins/starship.toml` - 391 lines
- Catppuccin Mocha powerline theme
- Universal format string with AWS, kubernetes, language detectors

**Opportunity:**
- **Personal profile:** Simpler prompt, focus on Python/Node, hobby projects
- **Work profile:** AWS segment prominent, kubernetes, terraform, multiple languages
- **Minimal profile:** Bare minimum (directory, git, character)

**Recommendation:**
- Create `home/_profiles/personal/starship.toml`
- Create `home/_profiles/work/starship.toml`
- Create `home/_profiles/minimal/starship.toml`
- Remove from `home/_mixins/` (no longer shared)

**Effort:** 2 hours

---

### 3. Fix Missing Alias (algo)

**Issue:** `algo` alias referenced in zsh.nix but not defined in personal.nix

**Current State:**
- `zsh.nix` line 201: `algo = "cd ~/Dev/algorithms";`
- `personal.nix`: Missing this alias

**Impact:** Inconsistent navigation shortcuts

**Recommendation:**
- Add `algo = "cd ~/Dev/algorithms";` to `personal.nix`

**Effort:** 5 minutes

---

### 4. Machine Detection Migration

**Issue:** Current system uses deprecated hostname-based detection

**Current State:**
- `lib/machine-detection.nix` has DEPRECATED API (getMachineType, isPersonal, isWork)
- New API exists (isPersonalType, isWorkType, selectByMachineType)
- Some code still uses deprecated API

**Migration Required:**
- Audit all usages of deprecated functions
- Update to new machineType-based API
- Remove deprecated functions after migration

**Effort:** 4 hours

---

## Medium Priority (Quality Improvements)

### 5. Modularize zsh.nix (3,313 Lines!)

**Issue:** Single massive file is hard to maintain

**Current State:**
- 14 major sections in one file
- 150+ aliases
- 80+ functions
- Cleanup system (5 tiers)
- Work-specific conditional block

**Recommendation - Option A (Simple Split):**
```
home/_template/shell/
├── zsh.nix (core config, imports)
├── aliases.nix (150+ aliases)
├── functions.nix (80+ universal functions)
├── cleanup.nix (cleanup system)
├── secrets.nix (secrets management functions)
└── work.nix (work-specific conditional block)
```

**Recommendation - Option B (Profile Integration):**
- Move work-specific functions to `work.nix` mixin
- Keep only universal aliases/functions in zsh.nix
- Profile-specific aliases stay in profile configs

**Effort:** 6-8 hours (Option A), 10-12 hours (Option B)

---

### 6. Git Alias Documentation

**Issue:** 80+ git aliases lack inline categorization

**Current State:**
- `home/_template/programs/git.nix` lines 81-212
- Aliases are documented in comments but not grouped in file

**Recommendation:**
- Add section comments within git.nix matching docs
- Group aliases: Status (4), Commit (9), Branch (7), Log (10+), etc.
- Makes git.nix more maintainable

**Effort:** 1 hour

---

### 7. Consolidate Security Validation Logic

**Issue:** SOPS validation logic duplicated

**Current State:**
- `pre-commit` hook: Checks sops: + mac: + ENC[
- `check-secrets-encrypted.sh`: Checks sops: + ENC[ (no MAC check)
- Pre-push hook: Simple binary check

**Recommendation:**
- Create single validation function in library
- All hooks call same function
- Ensures consistency

**Effort:** 2 hours

---

### 8. VS Code Profile-Specific Extensions

**Issue:** Extensions managed manually, could differ per profile

**Current State:**
- `vscode.nix` enables VS Code, no Nix-managed extensions
- Extensions via backup/restore scripts
- Settings/keybindings in user-data/

**Opportunity:**
- **Work profile:** Enterprise extensions (Docker, Kubernetes, Terraform)
- **Personal profile:** ML/AI extensions (Python, Jupyter, Copilot)
- **Minimal profile:** Basic code editing only

**Recommendation:**
- Keep manual management (current approach works)
- OR: Add optional Nix-managed critical extensions per profile
- Document recommended extensions per profile in README

**Effort:** 4 hours (Nix-managed), 1 hour (documentation only)

---

### 9. AWS Config Validation

**Issue:** accounts.json format not validated

**Current State:**
- `programs/aws.nix` reads accounts.json dynamically
- Supports string OR object format
- No validation of required fields

**Recommendation:**
- Add validation function in lib/aws-helpers.nix
- Check required fields: id, default_role
- Validate additional_roles if present
- Helpful error messages

**Effort:** 2 hours

---

## Low Priority (Nice to Have)

### 10. SSH Multiple Keys Per Profile

**Issue:** Single SSH key for all profiles

**Current State:**
- `programs/ssh.nix` uses `~/.ssh/id_ed25519`
- Work machines might need separate key

**Recommendation:**
- Support `~/.ssh/id_ed25519_work` for work profile
- Update SSH config per profile
- Document key generation workflow

**Effort:** 2 hours

---

### 11. Cleanup System Documentation

**Issue:** 5 cleanup tiers lack selection guide

**Current State:**
- zsh.nix has 5 tiers: safe, quick, standard, dev, aggressive
- No clear guidance on when to use each

**Recommendation:**
- Add inline documentation
- Create decision tree: daily→quick, weekly→standard, monthly→dev, etc.

**Effort:** 1 hour

---

### 12. Update Functions Dry-Run Support

**Issue:** Not all update functions support dry-run

**Current State:**
- Cleanup functions: Have dry-run mode
- Update functions: Missing dry-run

**Recommendation:**
- Add --dry-run flag to update-nix, update-brew, update-all
- Show what would be updated without executing

**Effort:** 3 hours

---

### 13. Performance - Zsh Startup Profiling

**Issue:** 3,313-line zsh.nix might impact startup time

**Current State:**
- zprof profiling commented out (lines 3295-3303)
- No baseline performance metrics

**Recommendation:**
- Uncomment zprof, measure baseline
- Identify slow sections
- Optimize if startup > 500ms

**Effort:** 2 hours

---

### 14. Function Usage Examples

**Issue:** Complex functions lack examples

**Current State:**
- Functions like cleanup tiers, update system, secrets management
- Documentation in code but no examples

**Recommendation:**
- Add usage examples to function comments
- Create cheat sheet in docs/

**Effort:** 2 hours

---

### 15. Error Handling Improvements

**Issue:** Some functions have minimal error handling

**Current State:**
- Many functions use basic error messages
- Some missing input validation

**Recommendation:**
- Add input validation to all functions
- Improve error messages with suggestions
- Add exit code consistency

**Effort:** 4 hours

---

### 16. Direnv Whitelist Pre-Population

**Issue:** Empty whitelist requires manual configuration

**Current State:**
- `programs/direnv.nix` has commented whitelist example
- User must manually add trusted directories

**Recommendation:**
- Pre-populate with common directories per profile:
  - Personal: `~/Dev`, `~/learning`
  - Work: `~/Work`, `~/repositories`

**Effort:** 30 minutes

---

### 17. Credentials Template Enhancement

**Issue:** credentials.env template could be more comprehensive

**Current State:**
- Basic template in edit-credentials function
- Shows TRIRIGA, HRDB, Payroll examples

**Recommendation:**
- Add more database type examples
- Add API token examples
- Add service account examples

**Effort:** 1 hour

---

### 18. Default Settings Templates (VS Code)

**Issue:** No default settings.json templates provided

**Current State:**
- VS Code settings in user-data/
- No profile-specific templates

**Recommendation:**
- Create settings templates:
  - `user-data-template/vscode/settings-personal.json`
  - `user-data-template/vscode/settings-work.json`
- User copies and customizes

**Effort:** 2 hours

---

### 19. Karabiner Profile-Specific Configs

**Issue:** Keybindings could differ per profile

**Current State:**
- Single karabiner.json for all machines
- Work and personal might want different shortcuts

**Recommendation:**
- Support per-profile Karabiner configs
- Copy from profile-specific user-data location

**Effort:** 2 hours

---

### 20. Jump Host Templates (SSH)

**Issue:** No ProxyJump examples provided

**Current State:**
- `programs/ssh.nix` has commented examples
- No documentation of common patterns

**Recommendation:**
- Provide bastion host template
- Document multi-hop SSH patterns
- Add to docs/reference/

**Effort:** 1 hour

---

## Summary

**Total Opportunities:** 20
**Estimated Total Effort:** 52-56 hours

**Breakdown by Priority:**
- **High (Must Address):** 4 items, ~7 hours
- **Medium (Quality):** 9 items, ~30-34 hours
- **Low (Nice to Have):** 7 items, ~15 hours

**Immediate Action Items (Pre-Migration):**
1. Remove alias duplication (30 min)
2. Fix missing algo alias (5 min)
3. Starship per-profile (2 hours)
4. Machine detection migration (4 hours)

**Post-Migration Enhancements:**
- Modularize zsh.nix (6-12 hours)
- Profile-specific extensions/settings (varies)
- Documentation improvements (5-7 hours)

