# Tasks - Profile Migration

## Phase 1: Comprehensive Functionality Audit 🟢 In Progress

### 1.1 Core Library Functions (lib/)

#### profile-migration #001 - Audit lib/aws-helpers.nix
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 2h
**Assignee:** AI Assistant

**Description:**
Audit AWS helper library to document all functionality that must be preserved.

**Acceptance Criteria:**
- [ ] Document all functions (mkAwsAccountHelper, mkAwsInfoCommands, etc.)
- [ ] Document accounts.json integration
- [ ] Document generated aliases (tidev, tisbx, etc.)
- [ ] Document shell functions (awsuse, awslogin, awswho, etc.)
- [ ] Verify compatibility with profile-based architecture
- [ ] Identify improvement opportunities

**Blockers:** None

---

#### profile-migration #002 - Audit lib/database-helpers.nix
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 1.5h
**Assignee:** AI Assistant

**Description:**
Audit database connection helpers for preservation requirements.

**Acceptance Criteria:**
- [ ] Document mkDatabaseInstance functionality
- [ ] Document environment variable pattern (INSTANCE_ENV_TYPE)
- [ ] Document all database types (oracle, mssql, postgres, mysql)
- [ ] Document dbconnect-* shell functions
- [ ] Verify token helper functionality
- [ ] Identify improvement opportunities

**Blockers:** None

---

#### profile-migration #003 - Audit lib/machine-detection.nix
**Status:** 🔵 Ready
**Priority:** Critical
**Effort:** 2h
**Assignee:** AI Assistant

**Description:**
Audit machine detection logic - this is CORE to the migration.

**Acceptance Criteria:**
- [ ] Document current hostname-based detection
- [ ] Document machines.nix mapping
- [ ] Document deprecated vs new API
- [ ] Identify conflicts with profile-based approach
- [ ] Design migration path for this module
- [ ] Propose improved detection logic

**Blockers:** None

---

#### profile-migration #004 - Audit lib/mixin-helpers.nix
**Status:** 🔵 Ready
**Priority:** Medium
**Effort:** 1h
**Assignee:** AI Assistant

**Description:**
Audit mixin composition helpers.

**Acceptance Criteria:**
- [ ] Document mkMixin functionality
- [ ] Document mixin merging logic
- [ ] Verify compatibility with profile system
- [ ] Identify improvement opportunities

**Blockers:** None

---

#### profile-migration #005 - Audit lib/secrets-registry.nix
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 1.5h
**Assignee:** AI Assistant

**Description:**
Audit secrets management registry.

**Acceptance Criteria:**
- [ ] Document all secret paths
- [ ] Document SOPS integration
- [ ] Document age key management
- [ ] Verify user-data compatibility
- [ ] Identify improvement opportunities

**Blockers:** None

---

#### profile-migration #006 - Audit lib/warnings.nix
**Status:** 🔵 Ready
**Priority:** Low
**Effort:** 0.5h
**Assignee:** AI Assistant

**Description:**
Audit warning/confirmation system.

**Acceptance Criteria:**
- [ ] Document warning functions
- [ ] Verify profile migration warnings needed
- [ ] Identify improvement opportunities

**Blockers:** None

---

### 1.2 Scripts Audit (scripts/)

#### profile-migration #007 - Audit critical scripts
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 3h
**Assignee:** AI Assistant

**Description:**
Audit all scripts for compatibility and preservation.

**Files to audit:**
- health-check.sh
- check-secrets-encrypted.sh
- install-awesome-apps.sh
- pre-flight-checks.sh
- validate-aws-config.sh
- verify-backups.sh
- test-aws-helpers.sh
- config-diff.sh

**Acceptance Criteria:**
- [ ] Document script functionality
- [ ] Identify hostname dependencies
- [ ] Design profile-aware versions
- [ ] Document improvement opportunities

**Blockers:** None

---

### 1.3 Home Configuration Audit (home/)

#### profile-migration #008 - Audit home/_mixins/
**Status:** 🟡 In Progress
**Priority:** Critical
**Effort:** 4h
**Assignee:** AI Assistant

**Description:**
Audit all mixins for complete functionality inventory.

**Files:**
- base.nix
- dev.nix
- personal.nix
- work.nix
- starship.toml

**Acceptance Criteria:**
- [ ] Document ALL shell aliases (personal vs work)
- [ ] Document ALL packages (personal vs work)
- [ ] Document ALL session variables
- [ ] Document starship configuration
- [ ] Map to profile templates
- [ ] Identify improvement opportunities

**Blockers:** None

---

#### profile-migration #009 - Audit home/_template/programs/
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 3h
**Assignee:** AI Assistant

**Description:**
Audit all program configurations.

**Files:**
- git.nix
- vscode.nix
- aws.nix
- ssh.nix
- direnv.nix
- karabiner.nix

**Acceptance Criteria:**
- [ ] Document git configuration (aliases, hooks)
- [ ] Document VSCode setup
- [ ] Document AWS CLI configuration
- [ ] Document SSH configuration
- [ ] Verify profile compatibility

**Blockers:** None

---

#### profile-migration #010 - Audit home/_template/shell/
**Status:** 🔵 Ready
**Priority:** Critical
**Effort:** 2h
**Assignee:** AI Assistant

**Description:**
Audit shell configuration - zsh setup.

**Acceptance Criteria:**
- [ ] Document ALL shell aliases
- [ ] Document ALL shell functions
- [ ] Document plugin configuration
- [ ] Document initExtra content
- [ ] Map to profile system

**Blockers:** None

---

### 1.4 Git Hooks & Security Audit

#### profile-migration #011 - Audit git hooks
**Status:** 🔵 Ready
**Priority:** High
**Effort:** 1.5h
**Assignee:** AI Assistant

**Description:**
Audit git pre-commit and pre-push hooks.

**Acceptance Criteria:**
- [ ] Document pre-commit secret scanning
- [ ] Document pre-push validation
- [ ] Document permission checks
- [ ] Verify user-data compatibility
- [ ] Identify improvements

**Blockers:** None

---

## Phase 2: Proposal Validation (Not Started)

### 2.1 Compare Proposal vs Implementation

#### profile-migration #012 - Validate proposal completeness
**Status:** ⚪ Pending
**Priority:** Critical
**Effort:** 4h
**Dependencies:** #001-#011

**Description:**
Compare PROFILE-BASED-ARCHITECTURE-PROPOSAL.md against audit findings.

**Acceptance Criteria:**
- [ ] Identify missing functionality in proposal
- [ ] Identify conflicts with existing logic
- [ ] Document gaps in migration plan
- [ ] Propose solutions

**Blockers:** Phase 1 must complete

---

## Phase 3: Improvement Opportunities (Not Started)

#### profile-migration #013 - Catalog improvements
**Status:** ⚪ Pending
**Priority:** Medium
**Effort:** 2h
**Dependencies:** #001-#012

**Description:**
Document all improvement opportunities discovered during audit.

**Blockers:** Phase 1 and 2 must complete

---

## Phase 4: Implementation Planning (Not Started)

#### profile-migration #014 - Create detailed implementation plan
**Status:** ⚪ Pending
**Priority:** Critical
**Effort:** 4h
**Dependencies:** #001-#013

**Description:**
Create phased implementation plan with tasks.

**Blockers:** All analysis phases must complete

---

## Summary

**Total Tasks:** 14
**Status Breakdown:**
- 🟡 In Progress: 1
- 🔵 Ready: 12
- ⚪ Pending: 1

**Estimated Effort:** ~33 hours (analysis + planning)
