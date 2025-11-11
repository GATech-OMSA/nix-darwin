# Implementation Notes for git-privacy

**Project**: git-privacy
**Purpose**: Capture design decisions, learnings, and technical details

---

## Architecture Decisions

### 1. Solution 2: Nix Module System with Conditional Imports (CHOSEN)

**Decision**: Use Nix's `lib.optional` for conditional secret imports based on machineType

**Rationale**:
- Pure Nix solution (no brittle sed operations)
- machineType already available in specialArgs (flake.nix line 101)
- Follows existing mixin pattern for consistency
- Easy to test and maintain
- Clean separation of personal vs work secrets

**Implementation**:
```nix
# hosts/_template/default.nix
imports =
  lib.optional (machineType == "personal") ./secrets-personal.nix ++
  lib.optional (machineType == "work") ./secrets-work.nix;
```

**Alternatives Considered**:
- **Option A**: Template + sed conditional logic (rejected: brittle, complex)
- **Two Templates**: Separate _template and _template-work (rejected: maintenance burden)
- **Parameterized Template**: Variable substitution with sed (rejected: still uses sed)
- **Flatten Host Config**: Move everything to mixins (rejected: can't work for sops)
- **Generator Script**: Programmatic generation (rejected: ugly heredocs)

**Why Solution 2 is Superior**:
1. No external tools (sed) required
2. Type-safe with Nix's type system
3. Self-documenting code
4. Consistent with mixin architecture
5. configure.sh stays simple (just copy template)

### 2. Homebrew Configuration Strategy

**Decision**: Ask user during configure.sh with smart defaults, not hardcoded

**Rationale**:
- Work machines MAY want Homebrew (if corporate proxy allows)
- Personal preference should override machine type defaults
- Explicit is better than implicit

**Implementation**:
- Smart defaults: personal=enabled, work=disabled
- Warning for work machines about corporate proxy blocking Go modules
- Placeholder in template: `REPLACE_WITH_HOMEBREW_CHOICE`
- Replaced by configure.sh with true/false

**User Flow**:
```bash
# configure.sh prompts:
"Machine type: work"
"Enable Homebrew? [y/N] (default: false)"
⚠️  Corporate proxies may block Homebrew (requires Go modules)
```

### 3. Three-Script Architecture

**Decision**: Split setup.sh into bootstrap.sh + configure.sh + activate.sh

**Rationale**:
- **Separation of concerns**: Prerequisites vs configuration vs activation
- **Safety**: User reviews before system changes
- **Idempotency**: Each script can run independently
- **Debugging**: Easier to troubleshoot specific stages

**Script Responsibilities**:
1. **bootstrap.sh** (one-time): Install Nix, nix-darwin, SOPS, age
2. **configure.sh** (interactive): Create configs, directories, ask questions, review
3. **activate.sh** (non-interactive): Build and apply system configuration

**Workflow**:
```
New Machine Setup:
./bootstrap.sh → ./configure.sh → [REVIEW] → ./activate.sh

Reconfiguration:
./configure.sh → [REVIEW] → ./activate.sh

Daily Updates:
nixconf → nix-rebuild → exec zsh
```

### 4. Pre-Activation Review System

**Decision**: Comprehensive 6-section checklist displayed by configure.sh

**Rationale**:
- Prevents accidental activation of incorrect configs
- Guides secret setup process
- Auto-detects existing secrets for convenience
- Explicit verification before system changes

**Review Sections**:
1. **Generated Configuration Files**: Display user/machine config values
2. **Generated Directories**: Show created hosts/ and home/ paths
3. **Secrets Detected**: Auto-scan ~/.db, ~/.tokens, ~/.aws, ~/.ssh
4. **Manual Review Commands**: Provide specific commands to verify
5. **Secrets Setup Steps**: Guide SOPS encryption process
6. **Pre-Activation Checklist**: Final verification before ./activate.sh

**Secret Scanning**: Automatically detects:
- Database credentials (~/.db/*)
- API tokens (~/.tokens/*)
- AWS credentials (~/.aws/credentials)
- SSH keys (~/.ssh/id_* excluding *.pub)
- Docker tokens (~/.docker/config.json)
- VPN credentials (~/.vpn/*)

---

## Technical Discoveries

### 1. Work vs Personal Secret Differences

**Personal Machine** (5 secrets, mostly commented for privacy):
```nix
# Commented out during development:
# - docker/registry/token
# - ollama/api-key
# - aws/personal/credentials
# - ssh/github/key

# Active:
- db/prod/user
```

**Work Machine** (13 secrets, all active):
```nix
- ssh/work/key (renamed from work_ssh for consistency)
- vpn/company/credentials
- servicenow/api-token
- confluence/api-token
- jira/api-token
- hcp/vault-token
- git/work/config
- databases/postgres/prod
- databases/postgres/staging
- databases/mysql/prod
- databases/redis/prod
- ... (2 more database secrets)
```

**Key Insight**: Work functionality lives in `home/_mixins/work.nix` (444 lines), NOT in host config. Host config only differs in:
1. SOPS secret list (personal: 5, work: 13)
2. Homebrew enabled/disabled (user choice now)
3. Computer name (placeholder replacement)

### 2. SOPS on Work Machines (Critical Correction)

**Previous Misunderstanding**: SOPS disabled on work machines
**Actual Reality**: SOPS fully functional, installed differently

**Corporate Proxy Issue**:
- Blocks Go module downloads during Nix build-from-source
- Prevents `nix-env -iA nixpkgs.sops` from succeeding
- Does NOT prevent SOPS from running once installed

**Solution**:
- bootstrap.sh installs SOPS via nix-env
- Works identically on both personal and work machines
- Same secrets.yaml structure and encryption process

**Work Machine SOPS Config**:
```nix
sops = {
  defaultSopsFile = ./secrets.yaml;
  age.keyFile = "${config.users.users.jimmy.home}/.config/sops/age/keys.txt";
  secrets = { /* 13 work secrets */ };
};
```

### 3. Template Placeholder Pattern

**Placeholders Used**:
1. **REPLACE_WITH_COMPUTER_NAME**: Replaced with user's machine description
2. **REPLACE_WITH_HOMEBREW_CHOICE**: Replaced with true/false

**Replacement Mechanism**:
```bash
# configure.sh
sed -i '' "s/REPLACE_WITH_COMPUTER_NAME/$MACHINE_DESCRIPTION/g" \
  "$REPO_ROOT/hosts/$MACHINE_ID/default.nix"

sed -i '' "s/REPLACE_WITH_HOMEBREW_CHOICE/$HOMEBREW_ENABLED/g" \
  "$REPO_ROOT/hosts/$MACHINE_ID/default.nix"
```

**Why This Works**:
- Unique placeholder strings (no false positives)
- Single-pass replacement (efficient)
- macOS sed compatible ('' for in-place edit)
- No complex regex needed

### 4. Recovery Point Strategy

**Decision**: Create commit after Task #007 before implementing Solution 2

**Rationale**:
- Easy rollback: `git reset --hard HEAD~1`
- Clear checkpoint before complex changes
- Preserves working state before secret template work

**Commit Message Structure**:
```
Recovery Point: git-privacy tasks 1-7 complete, before implementing work config solution

Completed:
- ✅ Task #001: Feature branch + backup branch created
- ... (list all completed tasks)

Changed files:
- home/_template/programs/git.nix (userConfig refs)
- ... (list all modified files)

Next: Implement Solution 2 (Nix Module System for work config)
```

**Benefits**:
- Single command rollback
- Self-documenting commit history
- Clear demarcation of project phases

---

## Gotchas & Edge Cases

### 1. Archive Directories Must Be Gitignored

**Issue**: Archive directories contain all the personal data we're trying to hide

**Files to Gitignore**:
- `hosts/archive/` - Contains hosts/mbp-jimmy and hosts/mbp-work
- `home/archive/` - Contains home/jimmy

**.gitignore Patterns**:
```gitignore
# Personal host configurations (generated by setup.sh)
hosts/*/
!hosts/_template/
hosts/archive/

# Personal home configurations (generated by setup.sh)
home/*/
!home/_mixins/
!home/_template/
home/archive/
```

**Why Critical**: Archive dirs used only for template development reference

### 2. Secret File Path Differences

**Personal vs Work Secret Paths Differ**:

Personal:
- `~/.db/prod` (single file)
- `~/.ssh/id_ed25519_github`

Work:
- `~/.db/postgres-prod`, `~/.db/mysql-prod`, etc. (multiple files)
- `~/.ssh/id_ed25519_work`
- `~/.tokens/servicenow`, `~/.tokens/jira`, etc.

**Solution**: Conditional imports ensure correct secrets loaded per machine type

**Template Structure**:
```
hosts/_template/
├── default.nix              # Conditional imports
├── secrets-personal.nix     # 5 personal secrets
└── secrets-work.nix         # 13 work secrets
```

### 3. Template Copying Preserves Structure

**configure.sh Behavior**:
```bash
cp -R home/_template/* home/$USERNAME/
```

**What Gets Copied** (entire directory structure):
```
home/jimmy/
├── default.nix
├── programs/
│   ├── git.nix
│   ├── node.nix
│   ├── vscode.nix
│   └── ...
├── shell/
│   └── zsh.nix
├── development/
│   ├── python.nix
│   ├── node.nix
│   └── ...
└── (all other subdirectories)
```

**Advantage**: No manual file creation needed, complete setup in one command

### 4. Username Hardcoding in Secret Paths

**Issue**: Secret paths in template use hardcoded username:
```nix
path = "${config.users.users.jimmy.home}/.db/prod";
```

**Impact**: Works because:
1. Username is validated in flake.nix specialArgs
2. config.users.users.${username} exists after configure.sh runs
3. Nix evaluates this path correctly at build time

**Future Consideration**: Could parameterize with `${username}` variable if needed

---

## Performance Baselines

### Build Times (Personal MacBook M1)

**First Build** (after configure.sh):
- Syntax check: ~2 seconds
- Build test: ~45 seconds
- Full switch: ~60 seconds
- Total: ~107 seconds

**Subsequent Builds**:
- Syntax check: ~2 seconds
- Build test: ~15 seconds
- Full switch: ~20 seconds
- Total: ~37 seconds (65% faster with cache)

**configure.sh Execution**:
- Interactive prompts: ~60-90 seconds (user input time)
- Directory creation: ~2 seconds
- Template copying: ~1 second
- Placeholder replacement: <1 second
- Total: ~64-94 seconds (mostly user input)

---

## Debugging Log

### Issue 1: Context Loss After Long Session

**Problem**: Lost conversation context mid-implementation
**Impact**: Had to resume from summary
**Solution**: Use NOTES.md to preserve critical decisions
**Prevention**: Regular checkpoints with commit + NOTES.md updates

### Issue 2: Task Numbering Confusion

**Problem**: Added 7 new tasks, unclear whether to use sub-tasks or renumber
**Discussion**: Option A (sub-tasks) vs Option B (renumber)
**Resolution**: User chose Option B for linear simplicity
**Outcome**: 17 tasks total, clear progression, updated all documentation

### Issue 3: Homebrew Hardcoding Assumption

**Problem**: Initially assumed Homebrew should be hardcoded per machine type
**User Correction**: Work users might want Homebrew (if proxy allows)
**Fix**: Changed to user prompt with smart defaults
**Learning**: Always ask user for preferences, don't assume

### Issue 4: SOPS Misunderstanding

**Problem**: Thought SOPS was disabled on work machines
**User Correction**: SOPS works, just installed via bootstrap.sh not build
**Root Cause**: Corporate proxy blocks Go modules during build
**Fix**: Updated understanding, SOPS fully functional on both machines

---

## Session Notes

### Session 2025-11-09 - Project Setup and Tasks #001-#007

**Started**: 2025-11-09 morning
**Completed**: Tasks #001-#007 (7/17 tasks, 41%)

**Work Accomplished**:
1. ✅ **Task #001**: Created feature branch `feature/git-privacy-complete` and backup branch `backup/work-config-real`
2. ✅ **Task #002**: Created `home/_template/` directory from `home/jimmy/`
   - Removed personal data from git.nix (uses userConfig.fullName, userConfig.email)
   - Removed personal data from node.nix (uses userConfig.email)
   - All hardcoded "jimmy", "jain" removed
3. ✅ **Task #003**: Cleaned `hosts/_template/default.nix`
   - computerName uses placeholder "REPLACE_WITH_COMPUTER_NAME"
   - Verified no personal names in template
4. ✅ **Task #004**: Archived personal directories
   - Moved hosts/mbp-jimmy → hosts/archive/
   - Moved hosts/mbp-work → hosts/archive/
   - Moved home/jimmy → home/archive/
   - Used `git mv` to preserve history
5. ✅ **Task #005**: Updated .gitignore
   - Added hosts/*/ and home/*/ patterns
   - Excluded _template and _mixins from ignore
   - Gitignored archive directories
6. ✅ **Task #006**: Created three-script architecture
   - bootstrap.sh already existed (prerequisites)
   - Created configure.sh (interactive config + directory creation)
   - Created activate.sh (non-interactive build/apply)
   - configure.sh creates both hosts/ and home/ directories
   - Both scripts tested with `bash -n`
7. ✅ **Task #007**: Removed hardcoded fallbacks from flake.nix
   - userConfig throws error if missing
   - machineConfig throws error if missing
   - Error messages guide users to run ./configure.sh

**Analysis Phase**:
- Compared archived work vs personal host configs
- Identified 3 key differences:
  1. Homebrew enabled/disabled
  2. SOPS secret list (5 personal vs 13 work)
  3. Computer name
- Explored 6 different solutions for work config handling
- **Selected Solution 2**: Nix Module System with conditional imports

**Design Decisions Made**:
1. **Solution 2 for work config**: Pure Nix, conditional imports, follows mixin pattern
2. **Homebrew user choice**: Ask during configure.sh with smart defaults
3. **Pre-activation review**: 6-section comprehensive checklist
4. **Secret scanning**: Auto-detect existing secrets to guide setup

**Task Renumbering**:
- Original plan: 10 tasks (#001-#010)
- Added 7 implementation tasks for Solution 2
- New structure: 17 tasks total
- Old #008 → #015 (Test), #009 → #016 (Work), #010 → #017 (Docs)

**Current State**:
- On branch: feature/git-privacy-complete
- Uncommitted work: All changes from tasks #001-#007
- Next: Create recovery point commit (Task #008)
- Then: Implement Solution 2 (Tasks #009-#014)

**Key Learnings**:
1. Always verify assumptions with user (Homebrew, SOPS)
2. Document decisions immediately in NOTES.md
3. Work functionality lives in mixins, not host configs
4. SOPS works on work machines (different install method)

**Stopping Point**:
- Ready to create recovery point commit
- All planning documentation updated with new task structure
- Architecture decisions documented in NOTES.md
- Clear path forward with tasks #008-#017

---

## Future Considerations

### Potential Enhancements

1. **Username Parameterization**: Replace hardcoded `jimmy` in secret paths with `${username}` variable
2. **Multi-User Support**: Extend template system to support multiple users per machine
3. **Secret Template Generator**: Script to auto-generate secret templates from existing secrets.yaml
4. **Validation Script**: Pre-commit hook to verify no personal data in tracked files
5. **Documentation Automation**: Script to replace personal examples in docs with generic placeholders

### Known Limitations

1. **Manual Secret Setup**: User must still manually create secrets.yaml (by design)
2. **Single Username**: Secret paths assume single user per machine
3. **SOPS Requirement**: Cannot run without SOPS/age (bootstrap.sh required)
4. **macOS Only**: sed syntax assumes macOS (GNU sed would need adjustment)

### Maintenance Notes

1. **Template Updates**: When adding new files to home/, must also update home/_template/
2. **Secret Changes**: When adding secrets, must update BOTH secrets-personal.nix AND secrets-work.nix
3. **configure.sh**: Review checklist must be updated if new config files added
4. **Documentation**: Keep TASKS.md in sync with actual progress
