# PHASE 1: FOUNDATION CLEANUP - EXECUTION CHECKLIST

**Duration**: ~8 hours (Week 1)
**Goal**: Fix critical issues that would cause rework in later phases
**Success Metric**: Zero duplicates, zero broken links, hardened security, centralized secrets
**Branch**: `feature/phase-1-foundation`

---

## Overview

Phase 1 eliminates technical debt and broken patterns that would complicate all future work. Think of this as "cleaning the workshop before building furniture" - you could skip it, but you'd constantly fight accumulated mess.

**Why These 4 Tasks**:
1. **Duplicates**: Cause confusion, merge conflicts, and maintenance nightmares
2. **Broken Links**: Make documentation unusable when you need it most
3. **Weak Hooks**: False sense of security - warnings are ignored
4. **Scattered Secrets**: Git hooks hardcode paths, miss files, fail silently

**What Changes**:
- Configuration becomes single-source-of-truth
- Documentation becomes reliable navigation
- Git hooks become actual security enforcement
- Secret management becomes centralized and auditable

**What Doesn't Change**:
- System functionality (no feature changes)
- User workflows (same commands work)
- Performance (if anything, slightly faster)

---

## Task 1: Remove Duplicate Configurations (~2 hours)

### Context (Why This Exists)

Over time, configurations accumulate in multiple places:
- Same packages listed in `modules/shared/packages.nix` AND `home/jimmy/programs/`
- Identical shell aliases in `zsh.nix` AND `personal.nix` mixin
- Environment variables defined in 3 different files

**Why It Matters**:
- Change a package in one place → other copy still exists → confusion
- Merge conflicts when editing same config in different locations
- "I swear I changed this!" moments (you did, but in the wrong file)
- Future refactoring requires hunting down all copies

**Impact on Future Work**:
- Phase 2 (machine detection) needs clear config boundaries
- Phase 3 (multi-user) requires single source of truth
- Duplicates would force rework of validated configurations

### Current State (What's Broken)

**Known Duplicates** (from analysis):

1. **Package Duplicates**:
   - `jq` defined in both `modules/shared/packages.nix` and `home/jimmy/development/python.nix`
   - `ripgrep` in system packages and home packages
   - `git` managed by both Nix and Homebrew (legacy)

2. **Alias Duplicates**:
   - `gs` defined in `zsh.nix` (old pattern) AND git aliases use `g s` (new pattern)
   - `ll` defined in multiple mixin files
   - `cd` shortcuts in both base config and personal mixin

3. **Environment Variable Duplicates**:
   - `EDITOR` set in 3 places (zsh.nix, git.nix, vscode.nix)
   - `PATH` modifications scattered across 5 files
   - `AWS_PROFILE` in shell config and AWS helper functions

### Target State (What Success Looks Like)

**Desired End State**:
- Each package listed exactly once in canonical location
- Each alias defined in single authoritative file
- Each environment variable set in one place
- Documentation of "where things go" rules

**Measurable Outcomes**:
- `rg "packages = with pkgs;" -A 5 | sort | uniq -d` returns zero results
- `rg "alias.*=" ~/.config/home-manager/ | sort | uniq -d` returns zero results
- Build succeeds with no "redefined" warnings

**Success Criteria**:
- [ ] Zero duplicate package definitions
- [ ] Zero duplicate alias definitions
- [ ] Zero duplicate environment variable exports
- [ ] Documentation of canonical locations created
- [ ] Build succeeds cleanly

### Files to Edit (Exact Paths)

**Will Audit**:
- `modules/shared/packages.nix` - System packages
- `home/jimmy/default.nix` - Home-level packages
- `home/jimmy/programs/*.nix` - Program-specific packages
- `home/jimmy/shell/zsh.nix` - Shell aliases and environment
- `home/_mixins/*.nix` - Mixin-specific aliases

**Will Create**:
- `docs/architecture/config-locations.md` - Rules for where things go

**Will Not Touch**:
- `flake.nix` - No duplicates here
- `lib/` - Helper functions, not configs
- `hosts/` - Host-specific only, no shared configs

### Implementation Steps (Ultra-Detailed Checklist)

#### Step 1: Audit Package Duplicates (30 minutes)

1. **Search for package definitions**:
   ```bash
   cd ~/nix-darwin
   rg "packages = with pkgs;" -A 20 > /tmp/packages-audit.txt
   ```

2. **Review the audit file**:
   ```bash
   code /tmp/packages-audit.txt
   ```
   Look for same package name appearing multiple times.

3. **Create duplicate list**:
   ```bash
   # Extract package names and count occurrences
   rg "^\s+\w+$" /tmp/packages-audit.txt | sort | uniq -d > /tmp/package-duplicates.txt
   cat /tmp/package-duplicates.txt
   ```

4. **Document findings**:
   ```bash
   echo "# Package Duplicates Found" > /tmp/dedup-plan.md
   echo "" >> /tmp/dedup-plan.md
   echo "## Packages appearing in multiple locations:" >> /tmp/dedup-plan.md
   cat /tmp/package-duplicates.txt >> /tmp/dedup-plan.md
   ```

5. **For each duplicate, decide canonical location**:

   **Decision Rules**:
   - System-wide CLI tools → `modules/shared/packages.nix`
   - Language-specific tools → `home/jimmy/development/<language>.nix`
   - Program-managed packages (VS Code extensions) → `home/jimmy/programs/<program>.nix`
   - User-specific tools → `home/jimmy/default.nix`

6. **Remove duplicates one by one**:
   ```bash
   # Example: Remove jq from home/jimmy/development/python.nix
   code home/jimmy/development/python.nix
   # Delete the "jq" line (it's in modules/shared/packages.nix)
   ```

7. **Test after each removal**:
   ```bash
   nix-rebuild
   # If build fails, restore and reconsider location
   ```

#### Step 2: Audit Alias Duplicates (30 minutes)

1. **Search for alias definitions**:
   ```bash
   rg "alias \w+=" home/jimmy/shell/zsh.nix home/_mixins/*.nix > /tmp/aliases-audit.txt
   ```

2. **Find duplicates**:
   ```bash
   # Extract alias names
   grep -o "alias [^=]*" /tmp/aliases-audit.txt | sort | uniq -d
   ```

3. **Review conflicts**:
   ```bash
   code /tmp/aliases-audit.txt
   ```

   **Known Issues**:
   - Old `gs` (git status) vs new `g s` pattern
   - Multiple `ll` definitions with different flags

4. **Decide on canonical pattern**:

   **Decision**:
   - Git aliases: Use `g <subcommand>` pattern ONLY (remove standalone `gs`, `gaa`, etc.)
   - Shell aliases: Keep in `zsh.nix` base, NOT in mixins unless machine-specific
   - Navigation aliases: Use `myLib.mkNavigationAliases` (remove manual definitions)

5. **Remove duplicate aliases**:
   ```bash
   # Example: Remove old `gs` alias
   code home/jimmy/shell/zsh.nix
   # Delete line: alias gs="git status -s"
   # (Already have `g s` in git.nix)
   ```

6. **Test aliases work**:
   ```bash
   nix-rebuild
   exec zsh
   g s  # Should work
   gs   # Should NOT exist (command not found)
   ll   # Should work (single definition)
   ```

#### Step 3: Audit Environment Variable Duplicates (30 minutes)

1. **Search for environment variable exports**:
   ```bash
   rg "export \w+=" home/ > /tmp/env-vars-audit.txt
   rg "home\.sessionVariables\." home/ >> /tmp/env-vars-audit.txt
   ```

2. **Find duplicates**:
   ```bash
   grep -o "export [^=]*\|sessionVariables\.[^ ]*" /tmp/env-vars-audit.txt | sort | uniq -d
   ```

3. **Review the duplicates**:
   ```bash
   code /tmp/env-vars-audit.txt
   ```

4. **Consolidate to canonical locations**:

   **Decision Rules**:
   - Global environment → `home/jimmy/default.nix` `home.sessionVariables`
   - Shell-specific → `home/jimmy/shell/zsh.nix` (if must be in shell)
   - Program-specific → Program's config file (e.g., `EDITOR` in git.nix)

5. **Example consolidation - `EDITOR`**:

   **Current** (duplicated):
   ```nix
   # In zsh.nix
   export EDITOR=code

   # In git.nix
   core.editor = "code";

   # In vscode.nix
   # Nothing needed - git handles it
   ```

   **After** (single source):
   ```nix
   # In home/jimmy/default.nix
   home.sessionVariables = {
     EDITOR = "code";
   };

   # In git.nix
   # Use $EDITOR environment variable
   core.editor = "${config.home.sessionVariables.EDITOR}";

   # Remove from zsh.nix
   ```

6. **Apply consolidation**:
   ```bash
   code home/jimmy/default.nix
   # Add sessionVariables

   code home/jimmy/programs/git.nix
   # Update to reference sessionVariables

   code home/jimmy/shell/zsh.nix
   # Remove duplicate export
   ```

7. **Test environment variables**:
   ```bash
   nix-rebuild
   exec zsh
   echo $EDITOR  # Should show "code"
   git config core.editor  # Should show "code"
   ```

#### Step 4: Create Configuration Locations Guide (30 minutes)

1. **Create documentation file**:
   ```bash
   code docs/architecture/config-locations.md
   ```

2. **Document the rules**:
   ```markdown
   # Configuration Locations Guide

   **Purpose**: Single source of truth for where each type of configuration belongs.

   ## Package Management

   | Package Type | Location | Example |
   |--------------|----------|---------|
   | System CLI tools | `modules/shared/packages.nix` | jq, ripgrep, curl |
   | Language tooling | `home/jimmy/development/<lang>.nix` | python312, uv, pipx |
   | Program extensions | `home/jimmy/programs/<program>.nix` | VS Code extensions |
   | User-specific tools | `home/jimmy/default.nix` | Personal scripts |

   ## Shell Configuration

   | Config Type | Location | Example |
   |-------------|----------|---------|
   | Core aliases | `home/jimmy/shell/zsh.nix` | ll, la, lt |
   | Git aliases | `home/jimmy/programs/git.nix` | g s, g aa, g cm |
   | Machine-specific | `home/_mixins/personal.nix` or `work.nix` | awslogin (work only) |
   | Navigation | Use `myLib.mkNavigationAliases` | Project shortcuts |

   ## Environment Variables

   | Variable Type | Location | Example |
   |---------------|----------|---------|
   | Global env vars | `home/jimmy/default.nix` sessionVariables | EDITOR, VISUAL |
   | Shell-specific | `home/jimmy/shell/zsh.nix` (if needed) | HISTSIZE, PS1 |
   | Program-specific | Program's config file | Git uses EDITOR |
   | Machine-specific | Mixin files | MACHINE_MODE, AWS_PROFILE |

   ## Decision Tree

   ```
   Need to add configuration?
   ├─ Is it a package?
   │  ├─ System-wide CLI? → modules/shared/packages.nix
   │  ├─ Language tool? → home/jimmy/development/<lang>.nix
   │  └─ User tool? → home/jimmy/default.nix
   │
   ├─ Is it an alias?
   │  ├─ Git command? → home/jimmy/programs/git.nix
   │  ├─ Machine-specific? → home/_mixins/<machine>.nix
   │  └─ General shell? → home/jimmy/shell/zsh.nix
   │
   └─ Is it an environment variable?
      ├─ Used globally? → home/jimmy/default.nix
      ├─ Machine-specific? → home/_mixins/<machine>.nix
      └─ Program-specific? → Program's config file
   ```

   ## Validation

   ```bash
   # Check for duplicates
   rg "packages = with pkgs;" -A 5 | sort | uniq -d  # Should be empty
   rg "alias \w+=" home/ | sort | uniq -d           # Should be empty
   rg "export \w+=" home/ | sort | uniq -d          # Should be empty
   ```

   ## When in Doubt

   1. Check existing similar configuration
   2. Grep for the config type
   3. Follow the most common pattern
   4. Document your choice if creating new pattern
   ```

3. **Save and commit**:
   ```bash
   git add docs/architecture/config-locations.md
   git commit -m "docs: add configuration locations guide

   Documents canonical locations for packages, aliases, and environment
   variables to prevent future duplicates."
   ```

### Testing Strategy (How to Validate)

**Test 1: No Duplicate Packages**
```bash
rg "packages = with pkgs;" -A 20 | grep -o "^\s*\w\+$" | sort | uniq -d
# Expected: No output (zero duplicates)
```

**Test 2: No Duplicate Aliases**
```bash
rg "alias \w+=" home/ | grep -o "alias [^=]*" | sort | uniq -d
# Expected: No output (zero duplicates)
```

**Test 3: No Duplicate Environment Variables**
```bash
rg "export \w+=" home/ | grep -o "export [^=]*" | sort | uniq -d
# Expected: No output (zero duplicates)
```

**Test 4: Build Succeeds**
```bash
nix-rebuild
# Expected: Success with no warnings about redefinitions
```

**Test 5: Aliases Work**
```bash
exec zsh
g s      # Should work (git status)
ll       # Should work (ls -la)
echo $EDITOR  # Should show "code"
```

**Test 6: Documentation Exists**
```bash
ls docs/architecture/config-locations.md
# Expected: File exists
```

### Success Criteria (Definition of Done)

- [ ] Audited all package definitions
- [ ] Removed all duplicate packages
- [ ] Audited all alias definitions
- [ ] Removed all duplicate aliases
- [ ] Audited all environment variable exports
- [ ] Consolidated environment variables to canonical locations
- [ ] Created config-locations.md guide
- [ ] All validation tests pass
- [ ] Build succeeds with no warnings
- [ ] Shell aliases work as expected
- [ ] Environment variables set correctly
- [ ] Committed changes with descriptive message

### Dependencies

**Requires Before Starting**:
- Clean git working directory
- Current generation bootable (test with `nix-rollback`)
- Backup created

**Blocks These Tasks**:
- None (Task 1 is independent)

### Rollback Procedure

**If issues during deduplication**:
```bash
# Rollback Nix changes
nix-rollback

# Rollback git changes
git status  # See what changed
git restore <file>  # Restore specific file
# OR
git reset --hard HEAD~1  # Rollback all changes
```

**Validation after rollback**:
```bash
nix-rebuild  # Should succeed
g s          # Aliases should work
```

### Common Pitfalls

**Pitfall 1: Removing the wrong copy**
- **Issue**: Removed package from wrong location, breaks functionality
- **Solution**: Test after each removal, restore if build fails
- **Prevention**: Remove one duplicate at a time, test immediately

**Pitfall 2: Breaking alias workflows**
- **Issue**: Users expect old alias, removed it
- **Solution**: Keep most-used version, remove others
- **Prevention**: Check git history for usage patterns

**Pitfall 3: Environment variable precedence issues**
- **Issue**: Variable set in multiple places, wrong value wins
- **Solution**: Understand Nix merging order (Home Manager > System)
- **Prevention**: Set in single canonical location only

**Pitfall 4: Forgetting to test in fresh shell**
- **Issue**: Old aliases cached in current shell
- **Solution**: Always `exec zsh` after rebuild to test
- **Prevention**: Include `exec zsh` in testing checklist

### Time Breakdown

- Package audit and removal: 30 minutes
- Alias audit and removal: 30 minutes
- Environment variable consolidation: 30 minutes
- Documentation creation: 30 minutes
- Testing and validation: 15 minutes
- Fixes and adjustments: 15 minutes

**Total**: 2 hours

---

## Task 2: Fix Broken Documentation Links (~2 hours)

### Context (Why This Exists)

Documentation was recently consolidated from 42 files to 17 files. Many internal links still point to old file names or locations.

**Why It Matters**:
- Users click links → 404 → frustration → stop using docs
- "I know we documented this somewhere..." but can't find it
- Broken links make docs look unmaintained and untrustworthy
- External links might be outdated or dead

**Impact on Future Work**:
- Phase 5 adds extensive documentation
- Need working link validation before adding more docs
- Broken links would propagate to new documentation

### Current State (What's Broken)

**Known Issues**:

1. **Internal Links to Old Files**:
   - Links to `docs/installation/quickstart.md` (now part of `docs/guides/installation.md`)
   - Links to `docs/reference/git-aliases.md` (now in `docs/reference/shell.md`)
   - Links to deleted recipe files

2. **Broken Relative Links**:
   - Links using `./` when files moved to subdirectories
   - Links using `../` with incorrect depth

3. **External Links** (possibly outdated):
   - Nix manual links (version-specific URLs)
   - GitHub links to specific commits (might be rebased)

4. **Missing Fragments**:
   - Links to `#section-name` but section renamed or removed

### Target State (What Success Looks Like)

**Desired End State**:
- All internal links point to current file structure
- All external links return 2xx/3xx status codes
- Link validation runs automatically on commit
- Documentation of link maintenance process

**Measurable Outcomes**:
- `./scripts/check-doc-links.sh` reports zero broken links
- Pre-commit hook catches new broken links
- Documentation is navigable without dead ends

**Success Criteria**:
- [ ] All internal markdown links functional
- [ ] All external links validated (alive or replaced)
- [ ] Link checking script created
- [ ] Pre-commit hook updated with link validation
- [ ] Link maintenance documented

### Files to Edit (Exact Paths)

**Will Audit/Fix**:
- All files in `docs/` directory (17 files)
- `README.md`
- `CLAUDE.md`
- Any markdown in `home/` or `modules/` (inline docs)

**Will Create**:
- `scripts/check-doc-links.sh` - Link validation script
- Update `.git/hooks/pre-commit` - Add link checking

**Will Not Touch**:
- Non-markdown files
- External repository links (unless broken)

### Implementation Steps (Ultra-Detailed Checklist)

#### Step 1: Scan for Broken Internal Links (30 minutes)

1. **Find all markdown files**:
   ```bash
   cd ~/nix-darwin
   find docs -name "*.md" > /tmp/doc-files.txt
   cat /tmp/doc-files.txt
   ```

2. **Extract all internal links**:
   ```bash
   # Find markdown links: [text](path.md)
   rg '\[.*?\]\((.*?\.md.*?)\)' docs/ -o -r '$1' > /tmp/internal-links.txt
   cat /tmp/internal-links.txt
   ```

3. **Check each link exists**:
   ```bash
   while IFS= read -r link; do
     # Remove fragment (#section)
     file=$(echo "$link" | cut -d'#' -f1)

     # Skip external links
     [[ "$file" =~ ^https?:// ]] && continue

     # Check if file exists (relative to docs/)
     if [[ ! -f "docs/$file" ]]; then
       echo "BROKEN: $file"
     fi
   done < /tmp/internal-links.txt > /tmp/broken-links.txt

   cat /tmp/broken-links.txt
   ```

4. **Create fix plan**:
   ```bash
   echo "# Documentation Link Fixes" > /tmp/link-fixes.md
   echo "" >> /tmp/link-fixes.md
   echo "## Broken Links Found:" >> /tmp/link-fixes.md
   cat /tmp/broken-links.txt >> /tmp/link-fixes.md
   echo "" >> /tmp/link-fixes.md
   echo "## Fix Strategy:" >> /tmp/link-fixes.md
   ```

#### Step 2: Fix Broken Internal Links (45 minutes)

**Common Fixes**:

1. **Old file structure links**:
   ```bash
   # Find links to old quickstart.md
   rg "\(docs/installation/quickstart\.md\)" docs/

   # Replace with new location
   find docs -name "*.md" -exec sed -i '' 's|docs/installation/quickstart\.md|docs/guides/installation.md|g' {} \;
   ```

2. **Git aliases reference**:
   ```bash
   # Old: docs/reference/git-aliases.md
   # New: docs/reference/shell.md#git

   rg "\(docs/reference/git-aliases\.md\)" docs/
   find docs -name "*.md" -exec sed -i '' 's|docs/reference/git-aliases\.md|docs/reference/shell.md#git|g' {} \;
   ```

3. **Relative path fixes**:
   ```bash
   # From docs/guides/usage.md linking to docs/guides/installation.md
   # Correct: [Installation](installation.md)
   # Wrong: [Installation](../installation.md)

   code docs/guides/usage.md
   # Manually fix relative paths
   ```

4. **Test each fix**:
   ```bash
   # After each replacement, check markdown renders correctly
   code docs/guides/usage.md  # VS Code markdown preview
   ```

#### Step 3: Validate External Links (30 minutes)

1. **Extract external links**:
   ```bash
   rg '\[.*?\]\((https?://[^\)]+)\)' docs/ -o -r '$1' | sort -u > /tmp/external-links.txt
   cat /tmp/external-links.txt
   ```

2. **Check each external link**:
   ```bash
   while IFS= read -r url; do
     status=$(curl -s -o /dev/null -w "%{http_code}" -L "$url")
     if [[ "$status" != "200" && "$status" != "301" && "$status" != "302" ]]; then
       echo "DEAD ($status): $url"
     fi
   done < /tmp/external-links.txt > /tmp/dead-links.txt

   cat /tmp/dead-links.txt
   ```

3. **Fix or replace dead links**:
   ```bash
   # Example: Old Nix manual link
   # Old: https://nixos.org/manual/nix/2.18/
   # New: https://nixos.org/manual/nix/stable/

   rg "nixos.org/manual/nix/2.18" docs/
   find docs -name "*.md" -exec sed -i '' 's|nixos.org/manual/nix/2.18|nixos.org/manual/nix/stable|g' {} \;
   ```

4. **Document intentional broken links** (if any):
   ```markdown
   # In docs/appendix/known-issues.md (if exists)

   ## Known Link Issues

   - Link to XYZ currently broken (service down)
   - Alternative: [ABC](alternative-url)
   ```

#### Step 4: Create Link Checking Script (30 minutes)

1. **Create script file**:
   ```bash
   code scripts/check-doc-links.sh
   ```

2. **Write comprehensive link checker**:
   ```bash
   #!/usr/bin/env bash
   # ─────────────────────────────────────────────────
   # Script: check-doc-links.sh
   # Description: Validate all documentation links
   # Usage: ./scripts/check-doc-links.sh
   # ─────────────────────────────────────────────────

   set -euo pipefail

   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   REPO_ROOT="$(dirname "$SCRIPT_DIR")"

   cd "$REPO_ROOT"

   echo "🔗 Checking Documentation Links"
   echo "================================"
   echo ""

   broken_count=0

   # Check internal links
   echo "📝 Checking internal links..."
   while IFS= read -r file; do
     while IFS= read -r link; do
       # Skip external links
       [[ "$link" =~ ^https?:// ]] && continue
       [[ -z "$link" ]] && continue

       # Remove fragment
       target=$(echo "$link" | cut -d'#' -f1)
       [[ -z "$target" ]] && continue

       # Resolve relative path
       dir=$(dirname "$file")
       resolved="$dir/$target"

       # Check if file exists
       if [[ ! -f "$resolved" ]]; then
         echo "  ❌ BROKEN: $file -> $link"
         ((broken_count++))
       fi
     done < <(grep -o '\[.*\](\([^)]*\))' "$file" | grep -o '(\([^)]*\))' | tr -d '()')
   done < <(find docs -name "*.md")

   # Check external links (optional, can be slow)
   if [[ "${CHECK_EXTERNAL:-false}" == "true" ]]; then
     echo ""
     echo "🌐 Checking external links..."
     while IFS= read -r url; do
       status=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "$url" || echo "000")
       if [[ "$status" != "200" && "$status" != "301" && "$status" != "302" ]]; then
         echo "  ⚠️  Dead ($status): $url"
       fi
     done < <(rg '\[.*?\]\((https?://[^\)]+)\)' docs/ -o -r '$1' | sort -u)
   fi

   echo ""
   if [ $broken_count -eq 0 ]; then
     echo "✅ All internal links are valid!"
     exit 0
   else
     echo "❌ Found $broken_count broken link(s)"
     exit 1
   fi
   ```

3. **Make executable**:
   ```bash
   chmod +x scripts/check-doc-links.sh
   ```

4. **Test the script**:
   ```bash
   ./scripts/check-doc-links.sh
   # Should report current broken links
   ```

#### Step 5: Add Link Validation to Git Hooks (15 minutes)

1. **Update pre-commit hook**:
   ```bash
   code .git/hooks/pre-commit
   ```

2. **Add link checking before commit**:
   ```bash
   # Add after existing checks, before final exit

   # Check documentation links
   if command -v scripts/check-doc-links.sh &> /dev/null; then
     echo "🔗 Checking documentation links..."
     if ! ./scripts/check-doc-links.sh; then
       echo ""
       echo "❌ Broken documentation links detected"
       echo "   Fix broken links or skip with: git commit --no-verify"
       exit 1
     fi
   fi
   ```

3. **Test the hook**:
   ```bash
   # Create intentional broken link
   echo "[Broken Link](nonexistent.md)" >> docs/README.md
   git add docs/README.md
   git commit -m "test"
   # Should fail with broken link error

   # Remove broken link
   git restore docs/README.md
   ```

### Testing Strategy (How to Validate)

**Test 1: Link Checker Runs**
```bash
./scripts/check-doc-links.sh
# Expected: Reports zero broken links
```

**Test 2: Internal Links Work**
```bash
# Manually navigate documentation
code docs/START-HERE.md
# Click links in VS Code markdown preview
# All links should navigate correctly
```

**Test 3: External Links Valid** (optional, slow)
```bash
CHECK_EXTERNAL=true ./scripts/check-doc-links.sh
# Expected: All external links return 2xx/3xx status
```

**Test 4: Pre-Commit Hook Active**
```bash
# Create broken link
echo "[Bad](fake.md)" >> docs/test.md
git add docs/test.md
git commit -m "test"
# Expected: Hook should fail and prevent commit

# Clean up
git restore docs/test.md
```

### Success Criteria (Definition of Done)

- [ ] All internal links validated and fixed
- [ ] All external links validated (dead ones replaced/removed)
- [ ] Link checking script created and executable
- [ ] Pre-commit hook updated with link validation
- [ ] Link checker passes with zero errors
- [ ] Documentation manually navigable (clicked through)
- [ ] Link maintenance process documented
- [ ] Changes committed with descriptive message

### Dependencies

**Requires Before Starting**:
- Task 1 complete (to avoid conflicts with doc changes)

**Blocks These Tasks**:
- Phase 5 documentation tasks (need working link validation)

### Rollback Procedure

```bash
# Rollback link fixes
git restore docs/

# Rollback scripts
git restore scripts/check-doc-links.sh

# Rollback hook changes
git restore .git/hooks/pre-commit
```

### Common Pitfalls

**Pitfall 1: Relative path confusion**
- **Issue**: `./file.md` vs `file.md` vs `../file.md` depends on source file location
- **Solution**: Always use paths relative to docs/ root or current directory
- **Prevention**: Test links in VS Code markdown preview before committing

**Pitfall 2: Fragment links break silently**
- **Issue**: `file.md#section` works even if section doesn't exist
- **Solution**: Manually verify fragment targets exist
- **Prevention**: Keep section names stable, document if changing

**Pitfall 3: Case sensitivity on different systems**
- **Issue**: `File.md` vs `file.md` works on macOS, breaks on Linux
- **Solution**: Always use exact case
- **Prevention**: Consistent lowercase naming for files

### Time Breakdown

- Scan and audit links: 30 minutes
- Fix broken internal links: 45 minutes
- Validate external links: 30 minutes
- Create link checking script: 30 minutes
- Add to pre-commit hook: 15 minutes
- Testing and validation: 15 minutes
- Documentation: 15 minutes

**Total**: 2 hours

---

## Task 3: Harden Git Hooks to Blocking Mode (~1 hour)

### Context (Why This Exists)

Current git hooks show **warnings** but **allow commits** with insecure file permissions. This creates a false sense of security - users see the warning, think "I'll fix it later", and accidentally commit plaintext credentials.

**Why It Matters**:
- **Security compliance**: Credential leaks are serious incidents
- **False security**: Warnings make users think system is protecting them
- **Behavioral**: People ignore warnings, respect errors
- **Audit trail**: Blocking prevents "oops" moments in git history

**Impact on Future Work**:
- Phase 2 centralized secret registry needs enforcement
- Phase 4 security audits assume hooks are blocking
- Can't trust security if hooks are advisory only

### Current State (What's Broken)

**Current Hook Behavior**:
```bash
# In .git/hooks/pre-commit (simplified)
if [ $(stat -f "%A" file) != "600" ]; then
  echo "⚠️  WARNING: Insecure permissions on file"
  echo "   Recommendation: chmod 600 file"
  # ... but then exits 0 (allows commit)
fi
exit 0  # Always succeeds!
```

**Problems**:
1. Users see warning → ignore it → commit anyway
2. No actual enforcement of security policy
3. Creates git history with insecure credential records
4. False sense that "the system warned me, so it's okay"

**Real Example**:
```bash
$ chmod 644 ~/.aws/credentials
$ git commit -m "update aws config"
⚠️  WARNING: ~/.aws/credentials has insecure permissions (644)
   Recommendation: chmod 600 ~/.aws/credentials

[main abc123] update aws config  # Commit succeeded!
```

### Target State (What Success Looks Like)

**Desired Behavior**:
```bash
$ chmod 644 ~/.aws/credentials
$ git commit -m "update aws config"
❌ BLOCKED: Insecure file permissions detected

File: ~/.aws/credentials
Current: 644 (readable by group and others)
Required: 600 (owner read/write only)

Fix with:
  chmod 600 ~/.aws/credentials

Or skip this check (NOT RECOMMENDED):
  git commit --no-verify

# Commit blocked - no changes made
```

**Measurable Outcomes**:
- Commits with insecure permissions **exit 1** (failure)
- Clear error messages with remediation steps
- `--no-verify` bypass documented for emergencies
- Test suite validates hook blocks bad commits

**Success Criteria**:
- [ ] Pre-commit hook exits 1 on insecure permissions
- [ ] Error message shows which files are insecure
- [ ] Error message shows exact fix command
- [ ] `--no-verify` bypass works (for emergencies)
- [ ] Test validates hook blocks bad commits
- [ ] Documentation updated with new behavior

### Files to Edit (Exact Paths)

**Will Edit**:
- `.git/hooks/pre-commit` - Change exit codes and messaging

**Will Create**:
- `scripts/test-git-hooks.sh` - Automated hook testing

**Will Update**:
- `docs/guides/security.md` - Document blocking behavior
- `docs/guides/troubleshooting.md` - Document bypass procedure

### Implementation Steps (Ultra-Detailed Checklist)

#### Step 1: Update Pre-Commit Hook (20 minutes)

1. **Backup existing hook**:
   ```bash
   cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
   ```

2. **Open hook for editing**:
   ```bash
   code .git/hooks/pre-commit
   ```

3. **Find permission checking section**:
   Look for lines like:
   ```bash
   # Check file permissions
   # or
   # Validate credential permissions
   ```

4. **Replace warning with error and exit**:

   **Old (warning) code**:
   ```bash
   if [ "$perms" != "600" ]; then
     echo "⚠️  WARNING: $file has insecure permissions ($perms)"
     echo "   Recommendation: chmod 600 $file"
   fi
   # Continues to next check...
   ```

   **New (blocking) code**:
   ```bash
   insecure_files=()

   # Check each credential file
   for file in "${CREDENTIAL_FILES[@]}"; do
     if [ -f "$file" ]; then
       perms=$(stat -f "%A" "$file")
       if [ "$perms" != "600" ]; then
         insecure_files+=("$file:$perms")
       fi
     fi
   done

   # If any files insecure, block commit
   if [ ${#insecure_files[@]} -gt 0 ]; then
     echo ""
     echo "❌ BLOCKED: Insecure file permissions detected"
     echo ""
     echo "The following files have incorrect permissions:"
     echo ""
     for item in "${insecure_files[@]}"; do
       file="${item%:*}"
       perms="${item#*:}"
       echo "  File: $file"
       echo "  Current: $perms (INSECURE)"
       echo "  Required: 600"
       echo ""
     done
     echo "Fix with:"
     echo "  chmod 600 <file>"
     echo ""
     echo "Or skip this check (NOT RECOMMENDED):"
     echo "  git commit --no-verify"
     echo ""
     exit 1  # Block commit!
   fi
   ```

5. **Test the blocking behavior**:
   ```bash
   # Make a file insecure
   touch test-credential
   chmod 644 test-credential
   git add test-credential

   # Try to commit (should fail)
   git commit -m "test"
   # Expected: Error and exit 1

   # Fix and retry
   chmod 600 test-credential
   git commit -m "test"
   # Expected: Success

   # Clean up
   git reset HEAD~1
   rm test-credential
   ```

#### Step 2: Improve Error Messages (15 minutes)

1. **Make error messages actionable**:

   **Before**:
   ```
   WARNING: File has wrong permissions
   ```

   **After**:
   ```
   ❌ BLOCKED: Insecure file permissions detected

   File: ~/.aws/credentials
   Current: 644 (readable by group and others)
   Required: 600 (owner read/write only)

   Fix with:
     chmod 600 ~/.aws/credentials
   ```

2. **Add color coding** (optional, improves readability):
   ```bash
   # ANSI color codes
   RED='\033[0;31m'
   YELLOW='\033[1;33m'
   GREEN='\033[0;32m'
   NC='\033[0m' # No Color

   echo -e "${RED}❌ BLOCKED:${NC} Insecure file permissions detected"
   ```

3. **Show all issues at once** (don't fail on first issue):
   ```bash
   # Collect all issues first
   issues=()
   for file in "${files[@]}"; do
     # Check file
     if [ problem ]; then
       issues+=("description")
     fi
   done

   # Then report all issues
   if [ ${#issues[@]} -gt 0 ]; then
     for issue in "${issues[@]}"; do
       echo "$issue"
     done
     exit 1
   fi
   ```

#### Step 3: Create Hook Testing Script (20 minutes)

1. **Create test script**:
   ```bash
   code scripts/test-git-hooks.sh
   ```

2. **Write comprehensive tests**:
   ```bash
   #!/usr/bin/env bash
   # Test git hook behavior

   set -e

   echo "🧪 Testing Git Hooks"
   echo "==================="
   echo ""

   # Test 1: Insecure file should block commit
   echo "Test 1: Insecure permissions should block commit"
   touch test-cred
   chmod 644 test-cred
   git add test-cred
   if git commit -m "test" 2>&1 | grep -q "BLOCKED"; then
     echo "  ✅ PASS: Commit blocked for insecure file"
   else
     echo "  ❌ FAIL: Commit should have been blocked"
     exit 1
   fi
   git restore --staged test-cred
   rm test-cred

   # Test 2: Secure file should allow commit
   echo "Test 2: Secure permissions should allow commit"
   touch test-cred
   chmod 600 test-cred
   git add test-cred
   if git commit -m "test" >/dev/null 2>&1; then
     echo "  ✅ PASS: Commit allowed for secure file"
     git reset --soft HEAD~1  # Undo commit
   else
     echo "  ❌ FAIL: Commit should have been allowed"
     exit 1
   fi
   git restore --staged test-cred
   rm test-cred

   # Test 3: --no-verify bypass should work
   echo "Test 3: --no-verify should bypass hook"
   touch test-cred
   chmod 644 test-cred
   git add test-cred
   if git commit --no-verify -m "test" >/dev/null 2>&1; then
     echo "  ✅ PASS: --no-verify bypass works"
     git reset --soft HEAD~1
   else
     echo "  ❌ FAIL: --no-verify should bypass hook"
     exit 1
   fi
   git restore --staged test-cred
   rm test-cred

   echo ""
   echo "✅ All hook tests passed!"
   ```

3. **Make executable and test**:
   ```bash
   chmod +x scripts/test-git-hooks.sh
   ./scripts/test-git-hooks.sh
   ```

#### Step 4: Document New Behavior (10 minutes)

1. **Update security guide**:
   ```bash
   code docs/guides/security.md
   ```

   Add section:
   ```markdown
   ## Git Hook Security

   Git hooks enforce security policies **automatically**:

   ### Pre-Commit Hook

   **What it checks**:
   - File permissions on all credential files
   - Secret file encryption status
   - (Future: More security validations)

   **Behavior**: BLOCKS commits with security issues

   **Example**:
   ```bash
   $ git commit -m "update config"
   ❌ BLOCKED: Insecure file permissions detected

   File: ~/.aws/credentials
   Current: 644
   Required: 600

   Fix with:
     chmod 600 ~/.aws/credentials
   ```

   ### Bypassing Hooks (Emergencies Only)

   **Emergency bypass**:
   ```bash
   git commit --no-verify -m "emergency fix"
   ```

   **When to use**:
   - ✅ Emergency production fix
   - ✅ Reverting broken change
   - ✅ Hook is incorrectly blocking valid change

   **When NOT to use**:
   - ❌ "I'll fix permissions later"
   - ❌ "The warning is annoying"
   - ❌ "It's just a dev environment"

   **After bypass**: Fix the issue immediately!
   ```

2. **Update troubleshooting guide**:
   ```bash
   code docs/guides/troubleshooting.md
   ```

   Add section:
   ```markdown
   ## Git Hook Issues

   ### Commit Blocked by Permissions Check

   **Symptom**: `❌ BLOCKED: Insecure file permissions detected`

   **Cause**: Credential file has insecure permissions (not 600)

   **Solution**:
   ```bash
   # Fix the file permissions
   chmod 600 <file-path>

   # Retry commit
   git commit -m "message"
   ```

   ### Hook Blocking Valid Change

   **Symptom**: Hook blocks commit but you believe file is secure

   **Solution**:
   ```bash
   # Verify permissions
   ls -la <file>

   # If actually 600, might be hook bug
   # Report issue and bypass for now:
   git commit --no-verify -m "message"
   ```
   ```

### Testing Strategy (How to Validate)

**Test 1: Insecure File Blocks Commit**
```bash
touch test-cred
chmod 644 test-cred
git add test-cred
git commit -m "test"
# Expected: Error and exit 1

rm test-cred
```

**Test 2: Secure File Allows Commit**
```bash
touch test-cred
chmod 600 test-cred
git add test-cred
git commit -m "test"
# Expected: Success

git reset HEAD~1
rm test-cred
```

**Test 3: --no-verify Bypass Works**
```bash
touch test-cred
chmod 644 test-cred
git add test-cred
git commit --no-verify -m "test"
# Expected: Success (bypassed hook)

git reset HEAD~1
rm test-cred
```

**Test 4: Error Message Clear**
```bash
chmod 644 ~/.aws/credentials
git add ~/.aws/credentials
git commit -m "test" 2>&1 | grep -q "BLOCKED"
# Expected: Contains "BLOCKED" message

chmod 600 ~/.aws/credentials
```

**Test 5: Test Script Passes**
```bash
./scripts/test-git-hooks.sh
# Expected: All tests pass
```

### Success Criteria (Definition of Done)

- [ ] Pre-commit hook blocks insecure commits (exit 1)
- [ ] Error messages show exact file and permissions
- [ ] Error messages show fix commands
- [ ] `--no-verify` bypass works
- [ ] Test script validates hook behavior
- [ ] Security guide documents blocking behavior
- [ ] Troubleshooting guide documents bypass procedure
- [ ] All validation tests pass
- [ ] Changes committed

### Dependencies

**Requires Before Starting**:
- None (Task 3 is independent)

**Blocks These Tasks**:
- Task 4 (secret registry will use hardened hooks)

### Rollback Procedure

```bash
# Restore backup hook
cp .git/hooks/pre-commit.backup .git/hooks/pre-commit

# Verify old behavior
touch test
chmod 644 test
git add test
git commit -m "test"  # Should warn but allow

# Clean up
git reset HEAD~1
rm test
```

### Common Pitfalls

**Pitfall 1: Hook exits 0 instead of 1**
- **Issue**: Changed message but forgot to change exit code
- **Detection**: Commits still succeed despite error message
- **Fix**: Ensure `exit 1` after error message

**Pitfall 2: Hook blocks valid files**
- **Issue**: Permission check too strict, blocks legitimate files
- **Detection**: Can't commit even with correct permissions
- **Fix**: Verify permission check logic, add file type filtering

**Pitfall 3: User doesn't know how to bypass**
- **Issue**: Legitimate need to bypass but documentation unclear
- **Detection**: User asks "how do I commit anyway?"
- **Fix**: Clear documentation of `--no-verify` in error message

### Time Breakdown

- Update hook exit codes: 20 minutes
- Improve error messages: 15 minutes
- Create test script: 20 minutes
- Documentation: 10 minutes
- Testing and validation: 10 minutes

**Total**: 1 hour

---

## Task 4: Centralize Secret Path Registry (~3 hours)

### Context (Why This Exists)

Git hooks currently hardcode credential file paths like this:
```bash
# In pre-commit hook
check_file ~/.aws/credentials
check_file ~/.db/oracle/prod
check_file ~/.tokens/github_token
# ... 10+ more hardcoded paths
```

**Problems**:
1. **Duplication**: Same paths in multiple hooks (pre-commit, pre-push)
2. **Maintenance**: Add new secret file → must update multiple locations
3. **Incompleteness**: Easy to forget to add new credential files
4. **No audit**: No single place showing "these are ALL our secrets"

**Why It Matters**:
- **Phase 2**: Machine detection needs to know where secrets are
- **Phase 4**: Permission audit needs complete inventory
- **Phase 5**: Security documentation needs comprehensive list
- **Future**: Any security tooling needs centralized registry

### Current State (What's Broken)

**Scattered Paths**:
```bash
# In .git/hooks/pre-commit
files=(
  "$HOME/.aws/credentials"
  "$HOME/.db/oracle/prod"
  # ... more paths
)

# In .git/hooks/pre-push (duplicate list!)
files=(
  "$HOME/.aws/credentials"
  "$HOME/.db/oracle/prod"
  # ... same paths again
)

# In scripts/audit-permissions.sh (yet another copy!)
files=(
  "$HOME/.aws/credentials"
  # ... same paths again
)
```

**Pain Points**:
- Add new credential file → must remember to update 3+ places
- Miss one location → security hole
- No way to validate "did I register this secret?"
- No documentation of what files contain secrets

### Target State (What Success Looks Like)

**Centralized Registry**:
```nix
# lib/secrets-registry.nix
{
  # Single source of truth for ALL secret paths
  secretPaths = [
    "~/.aws/credentials"
    "~/.db/oracle/prod"
    "~/.db/oracle/dev"
    "~/.tokens/github_token"
    "~/.tokens/gitlab_token"
    ".secrets/credentials.env"
    # ... complete inventory
  ];

  # Organized by type
  secretsByType = {
    aws = [ "~/.aws/credentials" ];
    database = [ "~/.db/oracle/prod" "~/.db/oracle/dev" ];
    tokens = [ "~/.tokens/github_token" "~/.tokens/gitlab_token" ];
    general = [ ".secrets/credentials.env" ];
  };
}
```

**Usage in Hooks**:
```bash
# In git hooks
SECRET_PATHS=$(nix eval .#secretPaths --json | jq -r '.[]')
for path in $SECRET_PATHS; do
  check_file "$path"
done
```

**Measurable Outcomes**:
- Single file defines all secret paths
- Hooks consume registry instead of hardcoding
- Validation ensures all paths actually exist
- Documentation shows complete inventory

**Success Criteria**:
- [ ] lib/secrets-registry.nix created with all paths
- [ ] Git hooks updated to use registry
- [ ] Validation function ensures paths exist
- [ ] Helper functions for registry queries
- [ ] Documentation of registry usage
- [ ] All tests pass

### Files to Edit (Exact Paths)

**Will Create**:
- `lib/secrets-registry.nix` - Centralized secret paths

**Will Edit**:
- `.git/hooks/pre-commit` - Use registry instead of hardcoded paths
- `.git/hooks/pre-push` - Use registry instead of hardcoded paths
- `scripts/audit-permissions.sh` (if exists) - Use registry

**Will Reference**:
- `flake.nix` - Export secretPaths for scripts to access

### Implementation Steps (Ultra-Detailed Checklist)

#### Step 1: Inventory Current Secret Paths (30 minutes)

1. **Find all credential references**:
   ```bash
   rg "\.aws/credentials|\.db/|\.tokens/|\.secrets/|\.credentials/" . > /tmp/secret-refs.txt
   ```

2. **Extract unique paths**:
   ```bash
   grep -o '\$HOME/[^"]*\|~/[^"]*\|\.secrets/[^"]*' /tmp/secret-refs.txt | sort -u > /tmp/secret-paths.txt
   cat /tmp/secret-paths.txt
   ```

3. **Verify paths exist on this machine**:
   ```bash
   while IFS= read -r path; do
     # Expand tilde
     expanded="${path/#\~/$HOME}"

     if [ -e "$expanded" ]; then
       echo "EXISTS: $path"
     else
       echo "MISSING: $path (register anyway, might exist on other machine)"
     fi
   done < /tmp/secret-paths.txt > /tmp/path-status.txt

   cat /tmp/path-status.txt
   ```

4. **Organize by type**:
   ```bash
   echo "AWS:" > /tmp/secrets-organized.txt
   grep "aws" /tmp/secret-paths.txt >> /tmp/secrets-organized.txt
   echo "" >> /tmp/secrets-organized.txt
   echo "Database:" >> /tmp/secrets-organized.txt
   grep "\.db/" /tmp/secret-paths.txt >> /tmp/secrets-organized.txt
   echo "" >> /tmp/secrets-organized.txt
   echo "Tokens:" >> /tmp/secrets-organized.txt
   grep "\.tokens/" /tmp/secret-paths.txt >> /tmp/secrets-organized.txt
   echo "" >> /tmp/secrets-organized.txt
   echo "General:" >> /tmp/secrets-organized.txt
   grep "\.secrets/\|\.credentials/" /tmp/secret-paths.txt >> /tmp/secrets-organized.txt

   cat /tmp/secrets-organized.txt
   ```

#### Step 2: Create Registry File (45 minutes)

1. **Create registry file**:
   ```bash
   code lib/secrets-registry.nix
   ```

2. **Write comprehensive registry**:
   ```nix
   # lib/secrets-registry.nix
   #
   # Centralized Secret Path Registry
   #
   # This file is the SINGLE SOURCE OF TRUTH for all credential file locations.
   # All security tooling (git hooks, audits, backups) should reference this registry.
   #
   # When adding a new credential file:
   # 1. Add path to appropriate category below
   # 2. Run: nix flake check (validates registry)
   # 3. Test git hooks pick it up: chmod 644 <file> && git add <file> && git commit
   #
   { lib }:

   let
     # Home directory (will be expanded at runtime)
     home = "$HOME";

   in rec {
     # ─────────────────────────────────────────────────
     # ALL SECRET PATHS (Complete Inventory)
     # ─────────────────────────────────────────────────

     secretPaths = [
       # AWS
       "${home}/.aws/credentials"

       # Database connections
       "${home}/.db/oracle/prod"
       "${home}/.db/oracle/dev"
       "${home}/.db/postgres/prod"

       # API tokens
       "${home}/.tokens/github_token"
       "${home}/.tokens/gitlab_token"
       "${home}/.tokens/docker_token"

       # General credentials
       ".secrets/credentials.env"
       ".credentials/general"

       # SSH keys (private only, .pub is okay)
       "${home}/.ssh/id_rsa"
       "${home}/.ssh/id_ed25519"

       # User data secrets
       "user-data/secrets"
     ];

     # ─────────────────────────────────────────────────
     # ORGANIZED BY TYPE (For Reporting/Auditing)
     # ─────────────────────────────────────────────────

     secretsByType = {
       aws = [
         "${home}/.aws/credentials"
       ];

       database = [
         "${home}/.db/oracle/prod"
         "${home}/.db/oracle/dev"
         "${home}/.db/postgres/prod"
       ];

       tokens = [
         "${home}/.tokens/github_token"
         "${home}/.tokens/gitlab_token"
         "${home}/.tokens/docker_token"
       ];

       ssh = [
         "${home}/.ssh/id_rsa"
         "${home}/.ssh/id_ed25519"
       ];

       general = [
         ".secrets/credentials.env"
         ".credentials/general"
         "user-data/secrets"
       ];
     };

     # ─────────────────────────────────────────────────
     # HELPER FUNCTIONS
     # ─────────────────────────────────────────────────

     # Get all paths as a flat list
     getAllPaths = secretPaths;

     # Get paths by type
     getPathsByType = type: secretsByType.${type} or [];

     # Get all types
     getTypes = builtins.attrNames secretsByType;

     # Count total secrets
     getTotalCount = builtins.length secretPaths;

     # Validate no duplicates in registry
     validateNoDuplicates =
       let
         sorted = builtins.sort (a: b: a < b) secretPaths;
         findDups = list:
           if list == [] || builtins.length list == 1 then []
           else if builtins.head list == builtins.head (builtins.tail list)
           then [ (builtins.head list) ] ++ findDups (builtins.tail list)
           else findDups (builtins.tail list);
       in
         assert (findDups sorted == []) || throw "Duplicate paths in registry: ${builtins.toJSON (findDups sorted)}";
         true;
   }
   ```

3. **Add to lib/default.nix**:
   ```bash
   code lib/default.nix
   ```

   Add import:
   ```nix
   secretsRegistry = import ./secrets-registry.nix { inherit lib; };
   ```

4. **Export from flake.nix**:
   ```bash
   code flake.nix
   ```

   Add to outputs:
   ```nix
   # In outputs section
   secretPaths = myLib.secretsRegistry.secretPaths;
   secretsByType = myLib.secretsRegistry.secretsByType;
   ```

#### Step 3: Update Git Hooks to Use Registry (45 minutes)

1. **Update pre-commit hook**:
   ```bash
   code .git/hooks/pre-commit
   ```

   Replace hardcoded paths:
   ```bash
   # OLD: Hardcoded paths
   # CREDENTIAL_FILES=(
   #   "$HOME/.aws/credentials"
   #   "$HOME/.db/oracle/prod"
   #   # ... more
   # )

   # NEW: Load from registry
   if command -v nix &> /dev/null && [ -f flake.nix ]; then
     # Get paths from centralized registry
     mapfile -t CREDENTIAL_FILES < <(
       nix eval .#secretPaths --json 2>/dev/null | \
       jq -r '.[]' | \
       sed "s|\$HOME|$HOME|g"
     )

     if [ ${#CREDENTIAL_FILES[@]} -eq 0 ]; then
       echo "⚠️  Warning: Could not load secret paths from registry"
       echo "   Falling back to basic checks"
       CREDENTIAL_FILES=(
         "$HOME/.aws/credentials"
         "$HOME/.db"
         "$HOME/.tokens"
       )
     fi
   else
     # Fallback if Nix not available
     CREDENTIAL_FILES=(
       "$HOME/.aws/credentials"
       "$HOME/.db"
       "$HOME/.tokens"
     )
   fi

   echo "🔐 Checking ${#CREDENTIAL_FILES[@]} credential files..."
   ```

2. **Update pre-push hook** (if exists):
   ```bash
   code .git/hooks/pre-push
   ```

   Apply same registry loading logic.

#### Step 4: Create Validation Function (30 minutes)

1. **Add validation to registry**:
   ```nix
   # In lib/secrets-registry.nix, add function:

   # Check if registered paths actually exist
   validatePathsExist = pkgs:
     let
       checkPath = path:
         let
           expanded = lib.replaceStrings ["$HOME"] [builtins.getEnv "HOME"] path;
         in
           builtins.pathExists expanded;

       missingPaths = builtins.filter (p: !(checkPath p)) secretPaths;
     in
       if missingPaths != []
       then builtins.trace "Missing secret paths: ${builtins.toJSON missingPaths}" false
       else true;
   ```

2. **Create validation script**:
   ```bash
   code scripts/validate-secret-registry.sh
   ```

   ```bash
   #!/usr/bin/env bash
   # Validate secret registry completeness

   echo "🔐 Validating Secret Registry"
   echo "============================="
   echo ""

   # Get paths from registry
   paths=$(nix eval .#secretPaths --json | jq -r '.[]' | sed "s|\$HOME|$HOME|g")
   total=$(echo "$paths" | wc -l)

   echo "📋 Registered paths: $total"
   echo ""

   # Check each path
   missing=0
   while IFS= read -r path; do
     if [ -e "$path" ] || [ -e "$(dirname "$path")" ]; then
       echo "  ✅ $path"
     else
       echo "  ⚠️  $path (not found - might exist on other machine)"
       ((missing++))
     fi
   done <<< "$paths"

   echo ""
   if [ $missing -eq 0 ]; then
     echo "✅ All registered paths valid"
   else
     echo "⚠️  $missing path(s) not found on this machine"
     echo "   (This is okay if paths exist on other machines)"
   fi
   ```

3. **Make executable**:
   ```bash
   chmod +x scripts/validate-secret-registry.sh
   ```

#### Step 5: Document Registry Usage (30 minutes)

1. **Create registry documentation**:
   ```bash
   code docs/architecture/secret-registry.md
   ```

   ```markdown
   # Secret Path Registry

   ## Overview

   The **Secret Path Registry** (`lib/secrets-registry.nix`) is the single source of truth for all credential file locations in this repository.

   ## Why It Exists

   **Problem**: Credential paths were hardcoded in multiple places (git hooks, audit scripts, backup tools), leading to:
   - Duplication and maintenance burden
   - Incomplete coverage (easy to forget files)
   - No audit trail of all secrets

   **Solution**: Centralized registry that all security tooling references.

   ## Structure

   ```nix
   {
     secretPaths = [ /* flat list of all paths */ ];
     secretsByType = { /* organized by type */ };
     getAllPaths = /* helper function */;
     getPathsByType = /* helper function */;
   }
   ```

   ## Adding New Secret Files

   When you add a new credential file:

   1. **Add to registry**:
      ```bash
      code lib/secrets-registry.nix
      # Add path to appropriate category
      ```

   2. **Validate**:
      ```bash
      nix flake check
      ./scripts/validate-secret-registry.sh
      ```

   3. **Test git hooks pick it up**:
      ```bash
      chmod 644 <new-file>
      git add <new-file>
      git commit -m "test"
      # Should block due to insecure permissions
      chmod 600 <new-file>
      ```

   ## Querying the Registry

   **From Nix**:
   ```nix
   myLib.secretsRegistry.getAllPaths
   myLib.secretsRegistry.getPathsByType "aws"
   ```

   **From shell scripts**:
   ```bash
   # Get all paths
   nix eval .#secretPaths --json | jq -r '.[]'

   # Get by type
   nix eval .#secretsByType.aws --json | jq -r '.[]'
   ```

   ## Used By

   - Git hooks (pre-commit, pre-push)
   - Permission audit script
   - Backup tools
   - Security documentation
   - (Future) Any credential management tooling
   ```

2. **Update main documentation references**:
   ```bash
   # Add link in docs/guides/security.md
   code docs/guides/security.md
   # Add: See [Secret Registry](../architecture/secret-registry.md) for complete inventory
   ```

### Testing Strategy (How to Validate)

**Test 1: Registry Loads Successfully**
```bash
nix eval .#secretPaths --json
# Expected: JSON array of paths
```

**Test 2: Registry Has Expected Count**
```bash
nix eval .#secretPaths --json | jq 'length'
# Expected: 10+ paths (adjust based on actual count)
```

**Test 3: Git Hooks Use Registry**
```bash
# Create new file
touch test-secret
chmod 644 test-secret
git add test-secret

# Commit should be blocked
git commit -m "test"
# Expected: Blocked with permissions error

# Clean up
git restore --staged test-secret
rm test-secret
```

**Test 4: Validation Script Works**
```bash
./scripts/validate-secret-registry.sh
# Expected: Shows all paths with ✅ or ⚠️
```

**Test 5: No Duplicates in Registry**
```bash
nix flake check
# Expected: No errors about duplicates
```

### Success Criteria (Definition of Done)

- [ ] lib/secrets-registry.nix created
- [ ] All current secret paths registered
- [ ] Paths organized by type (aws, database, tokens, etc.)
- [ ] Helper functions implemented
- [ ] Registry exported from flake.nix
- [ ] Git hooks updated to use registry
- [ ] Validation script created
- [ ] Documentation created
- [ ] All tests pass
- [ ] Changes committed

### Dependencies

**Requires Before Starting**:
- Task 3 complete (need hardened hooks to update)

**Blocks These Tasks**:
- Phase 2 machine detection (uses registry)
- Phase 4 permission audit (uses registry)

### Rollback Procedure

```bash
# Restore hooks
git restore .git/hooks/pre-commit

# Remove registry
git restore lib/secrets-registry.nix lib/default.nix

# Remove scripts
git restore scripts/validate-secret-registry.sh

# Remove docs
git restore docs/architecture/secret-registry.md
```

### Common Pitfalls

**Pitfall 1: Path expansion timing**
- **Issue**: `$HOME` expanded at wrong time
- **Solution**: Keep as `"$HOME"` in registry, expand in consumers
- **Prevention**: Test with actual file paths

**Pitfall 2: Registry out of sync**
- **Issue**: Add secret file but forget to register
- **Solution**: Make registry validation part of CI
- **Prevention**: Document process clearly

**Pitfall 3: Nix evaluation too slow**
- **Issue**: Loading registry adds latency to git commits
- **Solution**: Cache result, fallback to hardcoded list if slow
- **Prevention**: Optimize registry structure

### Time Breakdown

- Inventory current paths: 30 minutes
- Create registry file: 45 minutes
- Update git hooks: 45 minutes
- Create validation: 30 minutes
- Documentation: 30 minutes
- Testing: 20 minutes

**Total**: 3 hours

---

## Phase 1 Completion Checklist

### Before Merging to Main

- [ ] All 4 tasks completed
- [ ] All task success criteria met
- [ ] Phase validation checkpoint passed
- [ ] No regressions introduced
- [ ] Documentation updated
- [ ] Rollback tested

### Validation Checkpoint

Run this comprehensive validation:

```bash
# Task 1: No duplicates
echo "Checking for duplicates..."
rg "packages = with pkgs;" -A 5 | sort | uniq -d  # Should be empty
rg "alias \w+=" home/ | sort | uniq -d           # Should be empty

# Task 2: Links valid
echo "Checking documentation links..."
./scripts/check-doc-links.sh  # Should pass

# Task 3: Hooks blocking
echo "Testing git hooks..."
./scripts/test-git-hooks.sh  # Should pass

# Task 4: Registry working
echo "Validating secret registry..."
./scripts/validate-secret-registry.sh  # Should show all paths

# Full rebuild
echo "Testing full rebuild..."
nix-rebuild  # Should succeed

echo ""
echo "✅ Phase 1 validation complete!"
```

### Final Steps

1. **Review all changes**:
   ```bash
   git log feature/phase-1-foundation --oneline
   git diff main...feature/phase-1-foundation
   ```

2. **Create phase summary**:
   ```bash
   code claudedocs/planning/phase-1-summary.md
   ```

   Document:
   - What was completed
   - Time taken per task
   - Issues encountered
   - Lessons learned
   - Recommendations for Phase 2

3. **Merge to main**:
   ```bash
   git checkout main
   git merge --no-ff feature/phase-1-foundation
   git push
   ```

4. **Celebrate** 🎉:
   - Foundation is clean
   - Documentation is reliable
   - Security is enforced
   - Secrets are centralized
   - Ready for Phase 2!

---

**End of Phase 1 Checklist**

*Next: [Phase 2: Core Infrastructure](MASTER-EXECUTION-PLAN.md#phase-2-core-infrastructure)*
