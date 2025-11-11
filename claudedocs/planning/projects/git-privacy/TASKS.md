# Tasks for git-privacy

**Project Status**: 🟢 In Progress (7/17 tasks complete, 41%)
**Total Effort**: ~157 minutes (excluding #017 TBD)

---

## #001 - Setup & Backup

**Status**: ✅ Completed
**Effort**: 5 minutes
**Priority**: 🔴 Critical
**Completed**: 2025-11-09

**Description**:
Create feature branch and backup work configuration before any changes.

**Completed Actions**:
- ✅ Feature branch `feature/git-privacy-complete` created and checked out
- ✅ Backup branch `backup/work-config-real` exists locally with current state
- ✅ Backup committed with clear message (local only - DO NOT PUSH)
- ✅ Returned to feature branch ready for work

**Maps to Success Criteria**: ✅ "Work configuration backed up safely in local branch"

---

## #002 - Create home/_template/ Directory

**Status**: ✅ Completed
**Effort**: 10 minutes
**Priority**: 🔴 Critical
**Depends on**: #001
**Completed**: 2025-11-09

**Description**:
Create home/_template/ directory from home/jimmy/ and remove personal data.

**Completed Actions**:
- ✅ Directory `home/_template/` created
- ✅ All files copied from `home/jimmy/` to `home/_template/`
- ✅ `programs/git.nix` cleaned: uses `userConfig.fullName` and `userConfig.email`
- ✅ `programs/node.nix` cleaned: uses `userConfig.email`
- ✅ No hardcoded "jimmy", "jain", "jimmie", "example-corp" in template files

**Maps to Success Criteria**: ✅ "Templates available for new users (home/_template/)"

---

## #003 - Clean hosts/_template/

**Status**: ✅ Completed
**Effort**: 5 minutes
**Priority**: 🟡 Important
**Depends on**: #002
**Completed**: 2025-11-09

**Description**:
Remove remaining personal data from hosts/_template/default.nix.

**Completed Actions**:
- ✅ `computerName` uses placeholder "REPLACE_WITH_COMPUTER_NAME"
- ✅ No hardcoded personal names in template
- ✅ Template verified clean

**Maps to Success Criteria**: ✅ "No personal identifiers in tracked files"

---

## #004 - Archive Personal Directories

**Status**: ✅ Completed
**Effort**: 5 minutes
**Priority**: 🔴 Critical
**Depends on**: #003
**Completed**: 2025-11-09

**Description**:
Move personal directories (hosts/mbp-jimmy, hosts/mbp-work, home/jimmy) to archive/ subdirectories.

**Completed Actions**:
- ✅ Directories `hosts/archive/` and `home/archive/` created
- ✅ `hosts/mbp-jimmy/` moved to `hosts/archive/`
- ✅ `hosts/mbp-work/` moved to `hosts/archive/`
- ✅ `home/jimmy/` moved to `home/archive/`
- ✅ Git tracking preserved (using `git mv`)

**Maps to Success Criteria**: ✅ "No personal names in directory paths"

---

## #005 - Update .gitignore

**Status**: ✅ Completed
**Effort**: 2 minutes
**Priority**: 🔴 Critical
**Depends on**: #004
**Completed**: 2025-11-09

**Description**:
Add .gitignore patterns to exclude generated personal directories and archive.

**Completed Actions**:
- ✅ .gitignore updated with hosts/*/ pattern (excluding _template)
- ✅ .gitignore updated with home/*/ pattern (excluding _mixins and _template)
- ✅ .gitignore updated with archive/ directories
- ✅ Patterns tested with `git status`

**Maps to Success Criteria**: ✅ "No personal names in directory paths"

---

## #006 - Split Setup into Configure + Activate Scripts

**Status**: ✅ Completed
**Effort**: 25 minutes
**Priority**: 🔴 Critical
**Depends on**: #005
**Completed**: 2025-11-09

**Description**:
Refactor setup.sh into three-stage architecture for safer configuration and activation.

**Three-Stage Architecture**:
1. **bootstrap.sh** - Pre-requisites (Nix, SOPS) - ALREADY EXISTS ✅
2. **configure.sh** - Interactive config creation (CREATED ✅)
3. **activate.sh** - Non-interactive system activation (CREATED ✅)

**Completed Actions**:
- ✅ `bootstrap.sh` already exists (prerequisites: Nix, nix-darwin, SOPS, age)
- ✅ `configure.sh` created with interactive configuration logic
- ✅ `configure.sh` creates `config/user-config.nix` and `config/machine-config.nix`
- ✅ `configure.sh` creates `hosts/{machineId}/` from template
- ✅ `configure.sh` creates `home/{username}/` from template (NEW functionality)
- ✅ `configure.sh` replaces all placeholders correctly
- ✅ `activate.sh` created with non-interactive build/apply logic
- ✅ Both scripts tested with `bash -n`

**Maps to Success Criteria**: ✅ "setup.sh creates both hosts/ AND home/ directories from templates"

---

## #007 - Remove Hardcoded Fallbacks

**Status**: ✅ Completed
**Effort**: 5 minutes
**Priority**: 🟡 Important
**Depends on**: #006
**Completed**: 2025-11-09

**Description**:
Update flake.nix to throw errors if config files missing (force setup.sh requirement).

**Completed Actions**:
- ✅ flake.nix userConfig throws error if missing
- ✅ flake.nix machineConfig throws error if missing
- ✅ No hardcoded "jimmy" fallback values
- ✅ Error messages guide users to run ./configure.sh

**Maps to Success Criteria**: ✅ "User-agnostic configuration fully implemented"

---

## #008 - Create Recovery Point Commit

**Status**: 🔵 Todo
**Effort**: 5 minutes
**Priority**: 🔴 Critical
**Depends on**: #007

**Description**:
Commit current state (Tasks #001-#007 complete) as recovery point before implementing Solution 2.

**Definition of Done**:
- [ ] All changes from tasks #001-#007 committed
- [ ] Commit message includes "Recovery Point" prefix
- [ ] Message details all completed tasks and files changed
- [ ] Easy rollback available: `git reset --hard HEAD~1`

**Maps to Success Criteria**: ✅ "Work configuration backed up safely"

**Actions**:
1. Stage all changes: `git add -A`
2. Commit with detailed message:
```bash
git commit -m "Recovery Point: git-privacy tasks 1-7 complete, before implementing work config solution

Completed:
- ✅ Task #001: Feature branch + backup branch created
- ✅ Task #002: home/_template/ created from home/jimmy/
- ✅ Task #003: hosts/_template/ verified clean
- ✅ Task #004: Personal directories archived
- ✅ Task #005: .gitignore patterns added
- ✅ Task #006: Three-script architecture created
- ✅ Task #007: Hardcoded fallbacks removed from flake.nix

Changed files:
- home/_template/programs/git.nix (userConfig refs)
- home/_template/programs/node.nix (userConfig refs)
- .gitignore (gitignore patterns)
- bootstrap.sh (NEW - prerequisites installer)
- configure.sh (NEW - interactive config creator)
- activate.sh (NEW - system activator)
- flake.nix (removed fallbacks, throws errors)
- hosts/archive/ (archived mbp-jimmy, mbp-work)
- home/archive/ (archived jimmy/)

Next: Implement Solution 2 (Nix Module System for work config)"
```

**Blockers**: None

---

## #009 - Create Secret Template Files

**Status**: 🔵 Todo
**Effort**: 15 minutes
**Priority**: 🔴 Critical
**Depends on**: #008

**Description**:
Create two secret template files in hosts/_template/ for personal vs work machines.

**Definition of Done**:
- [ ] File `hosts/_template/secrets-personal.nix` created with 5 personal secrets
- [ ] File `hosts/_template/secrets-work.nix` created with 13 work secrets
- [ ] Personal secrets: docker, ollama, aws_creds, ssh/github/key, db/prod (commented for privacy)
- [ ] Work secrets: ssh/work/key, vpn, servicenow, confluence, jira, hcp, git, databases (active)
- [ ] Renamed: work_ssh → ssh/work/key for consistency
- [ ] Both files use sops configuration with age keyFile

**Maps to Success Criteria**: ✅ "Both machines (personal + work) working with config files"

**Actions**:
1. Create `hosts/_template/secrets-personal.nix`:
```nix
{ config, pkgs, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${config.users.users.jimmy.home}/.config/sops/age/keys.txt";

    secrets = {
      # Personal machine secrets (commented for privacy - uncomment as needed)

      # "docker/registry/token" = {
      #   path = "${config.users.users.jimmy.home}/.docker/config.json";
      # };

      # "ollama/api-key" = {
      #   path = "${config.users.users.jimmy.home}/.ollama/api-key";
      # };

      # "aws/personal/credentials" = {
      #   path = "${config.users.users.jimmy.home}/.aws/credentials";
      # };

      # "ssh/github/key" = {
      #   path = "${config.users.users.jimmy.home}/.ssh/id_ed25519_github";
      #   mode = "0600";
      # };

      "db/prod/user" = {
        path = "${config.users.users.jimmy.home}/.db/prod";
        mode = "0600";
      };
    };
  };
}
```

2. Create `hosts/_template/secrets-work.nix` with 13 work secrets (vpn, servicenow, jira, confluence, hcp, git, databases, etc.)

**Blockers**: None

---

## #010 - Update Template default.nix

**Status**: 🔵 Todo
**Effort**: 10 minutes
**Priority**: 🔴 Critical
**Depends on**: #009

**Description**:
Add conditional imports and Homebrew placeholder to hosts/_template/default.nix.

**Definition of Done**:
- [ ] Conditional imports using `lib.optional (machineType == "personal")`
- [ ] Imports secrets-personal.nix for personal machines
- [ ] Imports secrets-work.nix for work machines
- [ ] Homebrew placeholder: `REPLACE_WITH_HOMEBREW_CHOICE`
- [ ] Template uses machineType from specialArgs

**Maps to Success Criteria**: ✅ "Both machines supported from same template"

**Actions**:
1. Edit `hosts/_template/default.nix`:
```nix
{ config, pkgs, lib, machineType, hostname, ... }:
{
  # Conditional imports based on machine type
  imports =
    lib.optional (machineType == "personal") ./secrets-personal.nix ++
    lib.optional (machineType == "work") ./secrets-work.nix;

  # Networking
  networking = {
    computerName = "REPLACE_WITH_COMPUTER_NAME";
    hostName = hostname;
  };

  # Homebrew (user choice - set during configure.sh)
  homebrew.enable = REPLACE_WITH_HOMEBREW_CHOICE;  # true or false

  # Minimal system config
  system.stateVersion = 5;
}
```

**Blockers**: None

---

## #011 - Enhance configure.sh with Homebrew Question

**Status**: 🔵 Todo
**Effort**: 10 minutes
**Priority**: 🔴 Critical
**Depends on**: #010

**Description**:
Add Homebrew prompt to configure.sh and update placeholder replacement logic.

**Definition of Done**:
- [ ] Homebrew question added after machine type selection
- [ ] Smart defaults: personal=yes, work=no
- [ ] Warning displayed for work machines about corporate proxy
- [ ] REPLACE_WITH_HOMEBREW_CHOICE placeholder replaced with true/false
- [ ] User can override default for any machine type

**Maps to Success Criteria**: ✅ "Homebrew configurable per user preference"

**Actions**:
1. Add Homebrew prompt in configure.sh after machine type:
```bash
# Ask about Homebrew (regardless of machine type)
echo ""
echo "Homebrew package manager:"
if [[ "$MACHINE_TYPE" == "work" ]]; then
  warning "Corporate proxies may block Homebrew (requires Go modules)"
fi
read -p "Enable Homebrew? [y/N] (default: ${HOMEBREW_DEFAULT}): " homebrew_choice

if [[ -z "$homebrew_choice" ]]; then
  HOMEBREW_ENABLED="$HOMEBREW_DEFAULT"
elif [[ "$homebrew_choice" =~ ^[Yy]$ ]]; then
  HOMEBREW_ENABLED="true"
else
  HOMEBREW_ENABLED="false"
fi
```

2. Add placeholder replacement:
```bash
sed -i '' "s/REPLACE_WITH_HOMEBREW_CHOICE/$HOMEBREW_ENABLED/g" \
  "$REPO_ROOT/hosts/$MACHINE_ID/default.nix"
```

**Blockers**: None

---

## #012 - Add Secret Scanning to configure.sh

**Status**: 🔵 Todo
**Effort**: 20 minutes
**Priority**: 🟡 Important
**Depends on**: #011

**Description**:
Scan for existing secrets and store findings for review step.

**Definition of Done**:
- [ ] Scan ~/.db/* for database credentials
- [ ] Scan ~/.tokens/* for API tokens
- [ ] Scan ~/.aws/credentials for AWS credentials
- [ ] Scan ~/.ssh/id_* for SSH keys (exclude *.pub)
- [ ] Scan ~/.docker/config.json for Docker tokens
- [ ] Scan ~/.vpn/* for VPN credentials
- [ ] Store findings in DETECTED_SECRETS variable
- [ ] Only scan if directories exist

**Maps to Success Criteria**: ✅ "Secrets management clear and guided"

**Actions**:
1. Add secret scanning function:
```bash
scan_secrets() {
  DETECTED_SECRETS=""

  # Database credentials
  if [ -d "$HOME/.db" ]; then
    for f in "$HOME/.db"/*; do
      [ -f "$f" ] && DETECTED_SECRETS="$DETECTED_SECRETS\n  • $f → Add as secret"
    done
  fi

  # API tokens
  if [ -d "$HOME/.tokens" ]; then
    for f in "$HOME/.tokens"/*; do
      [ -f "$f" ] && DETECTED_SECRETS="$DETECTED_SECRETS\n  • $f → Add as secret"
    done
  fi

  # AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    DETECTED_SECRETS="$DETECTED_SECRETS\n  • ~/.aws/credentials → Add as secret"
  fi

  # SSH keys (exclude .pub)
  for f in "$HOME/.ssh/id_"*; do
    if [[ -f "$f" && ! "$f" =~ \.pub$ ]]; then
      DETECTED_SECRETS="$DETECTED_SECRETS\n  • $f → Add as secret"
    fi
  done
}
```

2. Call before review step: `scan_secrets`

**Blockers**: None

---

## #013 - Add Comprehensive Review Step to configure.sh

**Status**: 🔵 Todo
**Effort**: 20 minutes
**Priority**: 🔴 Critical
**Depends on**: #012

**Description**:
Display comprehensive 6-section review checklist before user runs activate.sh.

**Definition of Done**:
- [ ] Section 1: Generated configuration files displayed
- [ ] Section 2: Generated directories listed
- [ ] Section 3: Detected secrets shown (from scan)
- [ ] Section 4: Manual review commands listed
- [ ] Section 5: Secret setup steps provided
- [ ] Section 6: Pre-activation checklist displayed
- [ ] Warning: DO NOT run activate.sh until review complete
- [ ] Comprehensive review output at end of configure.sh

**Maps to Success Criteria**: ✅ "User must review before activation"

**Actions**:
Add to end of configure.sh:
```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VERIFICATION CHECKLIST - REVIEW BEFORE ACTIVATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣ GENERATED CONFIGURATION FILES"
echo "   ☐ config/user-config.nix"
echo "     • Username: $USERNAME"
echo "     • Full Name: $FULL_NAME"
echo "     • Email: $EMAIL"
echo ""
echo "   ☐ config/machine-config.nix"
echo "     • Machine ID: $MACHINE_ID"
echo "     • Machine Type: $MACHINE_TYPE"
echo "     • Architecture: $SYSTEM_ARCH"
echo "     • Mixins: $MIXINS"
echo "     • Homebrew: $HOMEBREW_ENABLED"
echo ""
echo "2️⃣ GENERATED DIRECTORIES"
echo "   ☐ hosts/$MACHINE_ID/ (from _template/)"
echo "   ☐ home/$USERNAME/ (from _template/)"
echo ""
echo "3️⃣ SECRETS DETECTED (need to be added to secrets.yaml)"
if [ -n "$DETECTED_SECRETS" ]; then
  echo "   🔍 Found the following secrets on your system:"
  echo -e "$DETECTED_SECRETS"
  echo ""
  echo "   ⚠️  These paths are currently UNENCRYPTED"
else
  echo "   ℹ️  No secrets detected (you can add them later)"
fi
echo ""
echo "4️⃣ FILES TO REVIEW MANUALLY"
echo "   ☐ cat config/user-config.nix          # Verify personal info"
echo "   ☐ cat config/machine-config.nix       # Verify machine settings"
echo "   ☐ ls -la hosts/$MACHINE_ID/           # Check generated files"
echo "   ☐ ls -la home/$USERNAME/              # Check generated files"
echo "   ☐ git status                          # Review what's tracked"
echo ""
echo "5️⃣ SECRETS SETUP (if you have secrets)"
echo "   ☐ Create hosts/$MACHINE_ID/secrets.yaml"
echo "   ☐ Add detected secrets (see section 3️⃣ above)"
echo "   ☐ Encrypt: sops -e -i hosts/$MACHINE_ID/secrets.yaml"
echo "   ☐ Verify: sops -d hosts/$MACHINE_ID/secrets.yaml | head"
echo ""
echo "6️⃣ PRE-ACTIVATION CHECKLIST"
echo "   ☐ All generated configs reviewed and correct"
echo "   ☐ Secrets encrypted (if applicable)"
echo "   ☐ Ready to build system"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ CONFIGURATION COMPLETE"
echo ""
echo "Next step: Review everything above, then run:"
echo "  ./activate.sh"
echo ""
echo "⚠️  DO NOT run activate.sh until you have:"
echo "   1. Reviewed all generated files"
echo "   2. Set up secrets (if needed)"
echo "   3. Verified everything is correct"
echo ""
```

**Blockers**: None

---

## #014 - Update activate.sh to Re-Display Review Info

**Status**: 🔵 Todo
**Effort**: 10 minutes
**Priority**: 🟢 Standard
**Depends on**: #013

**Description**:
Show summary at start of activate.sh as final reminder.

**Definition of Done**:
- [ ] activate.sh displays brief summary at start
- [ ] Shows machine type, mixins, Homebrew status
- [ ] Reminds user this will apply to system
- [ ] Confirms before proceeding

**Maps to Success Criteria**: ✅ "User informed before system changes"

**Actions**:
Add to start of activate.sh:
```bash
echo ""
echo "🚀 Activating nix-darwin configuration..."
echo ""
echo "Configuration summary:"
echo "  • Machine Type: $(grep machineType config/machine-config.nix | cut -d'"' -f2)"
echo "  • Mixins: $(grep mixins config/machine-config.nix | cut -d'[' -f2 | cut -d']' -f1)"
echo "  • Homebrew: $(grep 'homebrew.enable' hosts/*/default.nix | awk '{print $NF}' | tr -d ';')"
echo ""
read -p "Continue with activation? [Y/n]: " confirm
if [[ $confirm =~ ^[Nn]$ ]]; then
  echo "Activation cancelled"
  exit 0
fi
echo ""
```

**Blockers**: None

---

## #015 - Test on Personal Machine

**Status**: 🔵 Todo
**Effort**: 20 minutes
**Priority**: 🔴 Critical
**Depends on**: #014

**Description**:
Test complete workflow on personal machine before touching work machine.

**Definition of Done**:
- [ ] Changes committed to feature branch
- [ ] Existing configs removed (config/*.nix, hosts/mbp-jimmy, home/jimmy)
- [ ] configure.sh runs successfully and creates directories
- [ ] Review checklist verified
- [ ] Syntax validation passes: `nix-instantiate --parse flake.nix`
- [ ] Build test passes: `darwin-rebuild build --flake ~/nix-darwin`
- [ ] Apply successful: `darwin-rebuild switch --flake ~/nix-darwin`
- [ ] Git config verified: `git config user.name` and `git config user.email`
- [ ] Shell restart works: `exec zsh`
- [ ] Aliases functional: `g s`, `nixconf`
- [ ] Privacy verified: No "jimmy" in tracked files

**Maps to Success Criteria**: ✅ "Build success rate: 100%", ✅ "Functionality preservation: 100%"

**Actions**:
1. Commit all changes: `git add -A && git commit -m "feat: Complete git privacy implementation"`
2. Remove existing configs: `rm -rf config/*.nix hosts/mbp-jimmy home/jimmy`
3. Run configure: `./configure.sh` → Review output → Verify all sections
4. Set up secrets if needed
5. Run activate: `./activate.sh`
6. Syntax check: `nix-instantiate --parse flake.nix`
7. Build test: `darwin-rebuild build --flake ~/nix-darwin`
8. Apply: `darwin-rebuild switch --flake ~/nix-darwin`
9. Verify git: `git config user.name`, `git config user.email`
10. Restart shell: `exec zsh`
11. Test aliases: `g s`, `nixconf`
12. Privacy check: `grep -r "jimmy\|jain\|jimmie\|example-corp" . --exclude-dir=.git --exclude-dir=archive`

**Rollback Plan** (if validation fails):
```bash
nix-rollback
git checkout backup/work-config-real
darwin-rebuild switch --flake ~/nix-darwin
```

**Blockers**: None (All previous tasks must succeed)

---

## #016 - Apply to Work Machine

**Status**: 🔵 Todo
**Effort**: 15 minutes
**Priority**: 🟡 Important
**Depends on**: #015 (MUST succeed first)

**Description**:
Apply proven configuration to work machine (only after personal machine succeeds).

**Definition of Done**:
- [ ] Changes synced to work machine
- [ ] configure.sh run with work credentials
- [ ] Build test passes on work: `darwin-rebuild build --flake ~/nix-darwin`
- [ ] Apply successful on work: `darwin-rebuild switch --flake ~/nix-darwin`
- [ ] Git config shows work email: `git config user.email`
- [ ] Work mixin loaded: `echo $MACHINE_MODE` → "work"
- [ ] Work-specific tools functional: AWS, database connectors, ODBC
- [ ] Corporate settings preserved: CA bundle, etc.

**Maps to Success Criteria**: ✅ "Both machines (personal + work) working with config files"

**Actions** (on work machine):
1. Sync changes: `git pull origin feature/git-privacy-complete`
2. Remove existing configs: `rm -rf config/*.nix`
3. Run configure: `./configure.sh`
   - Enter work email: `user@example.com`
   - Enter machineType: `work`
   - Answer Homebrew prompt
   - Review checklist
4. Set up work secrets in hosts/mbp-work/secrets.yaml
5. Run activate: `./activate.sh`
6. Build test: `darwin-rebuild build --flake ~/nix-darwin`
7. Apply: `darwin-rebuild switch --flake ~/nix-darwin`
8. Verify: `git config user.email` → work email
9. Test: `exec zsh`, AWS tools, database connectors
10. Verify work mixin: `echo $MACHINE_MODE` → "work"

**Rollback Plan** (work machine):
```bash
git checkout backup/work-config-real
darwin-rebuild switch --flake ~/nix-darwin
```

**Blockers**: #015 validation must succeed first

---

## #017 - Brainstorm Documentation Updates

**Status**: 🔵 Todo (awaiting user confirmation)
**Effort**: TBD
**Priority**: 🟢 Standard
**Depends on**: #016

**Description**:
Identify all documentation files containing personal examples and plan replacement strategy.

**Definition of Done**:
- [ ] Complete list of docs containing "jimmy", "jain", "jimmie", "example-corp"
- [ ] Replacement strategy defined (variables, placeholders, generic examples)
- [ ] User reviewed and approved plan
- [ ] **HALT: Get user confirmation before updating any docs**

**Maps to Success Criteria**: ✅ "Documentation completeness: 100%"

**Actions**:
1. Search docs: `grep -r "jimmy\|jain\|jimmie\|example-corp" docs/ claudedocs/`
2. Create list of affected files
3. Propose replacement strategy:
   - Replace with `{username}`, `{fullName}`, `{email}` variables
   - Use generic examples: "user@example.com", "User Name"
   - Update screenshots/examples to be generic
4. **Present plan to user for approval**
5. **WAIT for user confirmation before proceeding**

**Blockers**: User confirmation required before execution

---

## Progress Summary

| Task | Status | Effort | Cumulative | Depends On |
|------|--------|--------|------------|------------|
| #001 | ✅ Completed | 5 min | 5 min | None |
| #002 | ✅ Completed | 10 min | 15 min | #001 |
| #003 | ✅ Completed | 5 min | 20 min | #002 |
| #004 | ✅ Completed | 5 min | 25 min | #003 |
| #005 | ✅ Completed | 2 min | 27 min | #004 |
| #006 | ✅ Completed | 25 min | 52 min | #005 |
| #007 | ✅ Completed | 5 min | 57 min | #006 |
| #008 | 🔵 Todo | 5 min | 62 min | #007 |
| #009 | 🔵 Todo | 15 min | 77 min | #008 |
| #010 | 🔵 Todo | 10 min | 87 min | #009 |
| #011 | 🔵 Todo | 10 min | 97 min | #010 |
| #012 | 🔵 Todo | 20 min | 117 min | #011 |
| #013 | 🔵 Todo | 20 min | 137 min | #012 |
| #014 | 🔵 Todo | 10 min | 147 min | #013 |
| #015 | 🔵 Todo | 20 min | 167 min | #014 |
| #016 | 🔵 Todo | 15 min | 182 min | #015 |
| #017 | 🔵 Todo | TBD | - | #016, User approval |

**Completion**: 41% (7/17)
**Time Spent**: 57 minutes
**Time Remaining**: ~125 minutes (excluding #017)
