# Changelog

All notable changes to this nix-darwin configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] - 2025-11-10

### 🔐 Secret Management v2.0 - Enhanced Scanning & Lifecycle Tools

Major enhancement to secret management system with comprehensive scanning, smart deduplication, and complete lifecycle tooling.

### ✨ Added

- **Enhanced Secret Scanning System** - Comprehensive detection and smart merge
  - 8 scanning categories: AWS, SSH, GPG, Databases, Tokens, TLS, Environment, Custom paths
  - Smart deduplication (prevents duplicate entries by name+path matching)
  - Fixed .env* wildcard bug (now correctly matches .env.local, .env.production, etc.)
  - Dry-run mode with change preview before applying
  - Detailed reporting (new secrets, duplicates skipped, categories scanned)

- **Secret Lifecycle Scripts** - Complete management toolchain
  - `scripts/rescan-secrets.sh` - Scan and update secrets.yaml with new findings
  - `scripts/edit-secrets.sh` - SOPS editor with validation and backup
  - `scripts/view-secrets.sh` - Decrypted secret viewer (read-only)
  - `scripts/backup-secrets.sh` - Automated encrypted backups with rotation
  - All scripts include help text (`--help` flag)

- **Shell Aliases for Convenience** - Quick access commands
  - `rescan-secrets` - Run secret scanner
  - `edit-secrets` - Edit encrypted secrets
  - `view-secrets` - View decrypted secrets
  - `backup-secrets` - Backup secrets to encrypted archive

- **Documentation Improvements**
  - Created `docs/secrets.md` - Comprehensive secret management guide
  - Restored workflow guides: CLEAN-SETUP-STEPS.md, DEVELOPMENT-WORKFLOW.md, project-workflow.md
  - Created `docs/work/aws/` directory with 4 AWS reference guides:
    - AWS-CONFIG-STATUS.md (current configuration state)
    - AWS-IMPLEMENTATION-SUMMARY.md (feature implementation details)
    - AWS-MULTI-ROLE.md (multi-account SSO guide)
    - AWS-QUICK-REF.md (daily command reference)

### 🔧 Changed

- **Script Organization** - Flattened secret scripts to root scripts/ directory
  - Moved from `scripts/secrets/` to `scripts/` for easier discovery
  - Updated CLAUDE.md with new script locations
  - Consistent naming pattern: `{action}-secrets.sh`

- **configure.sh Integration** - Enhanced setup wizard
  - Integrated rescan-secrets.sh functionality
  - Improved secret detection during initial setup
  - Better validation and error handling
  - Clearer user guidance during configuration

### 🐛 Fixed

- **Wildcard Pattern Bug** - .env* pattern now works correctly
  - Previously matched only literal `.env*` filename
  - Now correctly matches `.env.local`, `.env.production`, `.env.test`, etc.
  - Uses proper glob expansion in scan logic

- **Duplicate Secret Prevention** - Smart deduplication logic
  - Checks both secret name and file path before adding
  - Prevents accidental duplicate entries during rescans
  - Reports skipped duplicates for transparency

- **Gitignore for Secret Backups** - Added patterns to ignore backup files
  - `secrets.yaml.backup-*` - Direct backups
  - `**/secrets.yaml.backup-*` - Nested backup files
  - Prevents accidental commits of backup files

### 📚 Documentation

- Updated CLAUDE.md with secret management workflow
- Created comprehensive docs/secrets.md guide
- Restored and organized workflow guides in claudedocs/
- Created AWS-specific reference documentation in docs/work/aws/

### 📊 Statistics

- **Commits**: 6 commits on feature/secret-management-v2 branch
- **Files Changed**: 17 files
- **Lines Added**: +3,787
- **Lines Removed**: -49
- **Development Time**: ~6.25 hours (9 tasks completed)
- **Testing**: Validated on personal machine ✅

---

## [2.0.0] - 2025-11-10

### 🎯 Major Release: Profile-Based Architecture & Username-Agnostic Configuration

This release represents a complete architectural overhaul introducing profile-based behavior separation and username-agnostic configuration. The system is now portable across machines and users while maintaining full functionality.

### ✨ Added

- **Profile System Architecture** - Self-contained profile-based behavior
  - Created `nix-config/home/_profiles/` structure (personal, work, minimal, _template)
  - Profile selection via `config/machine-config.nix` `profileName` field
  - Personal profile: Full personal tooling, aliases, and development setup
  - Work profile: AWS SSO multi-account, work-specific tools, corporate settings
  - Minimal profile: Bare-bones troubleshooting configuration
  - Template profile: Shared base programs and shell configs

- **Username-Agnostic Configuration** - Portable configuration system
  - Created `config/user-config.nix` (username, fullName, email) - gitignored
  - Created `config/machine-config.nix` (machineId, machineType, profileName) - gitignored
  - Flake.nix reads configs via `builtins.getEnv "FLAKE_ROOT"` + `--impure` flag
  - All personal data moved to gitignored config files
  - Repository now shareable without privacy concerns

- **Three-Script Setup Workflow** - Improved installation experience
  - `bootstrap.sh`: Install prerequisites (Nix, nix-darwin, SOPS, age)
  - `configure.sh`: Interactive configuration wizard
    - Generates `config/user-config.nix` and `config/machine-config.nix`
    - Creates host directory with secrets templates
    - Scans for existing secrets (AWS credentials, SSH keys, env files)
    - Reviews generated configuration before proceeding
    - Homebrew detection and prompting
  - `activate.sh`: Build and activate system
    - Validates config files exist
    - Handles secret encryption (plaintext → SOPS encrypted)
    - Checks for placeholder values before encryption
    - Runs `darwin-rebuild switch --flake . --impure`
    - Post-activation guidance

- **AWS Work Profile Enhancements** - SSO multi-account support
  - Created `nix-config/home/_profiles/work/accounts.json.template`
    - Template for AWS SSO account-to-profile mapping
    - Supports multiple AWS accounts with role-based access
    - Generates `~/.aws/accounts.json` for awscli-login
  - Created `nix-config/home/_profiles/work/README-accounts.md`
    - Comprehensive setup guide for encrypted/unencrypted approaches
    - awscli-login SSO integration documentation
  - Added `edit-aws-map` function in `work/aliases.nix`
    - Opens SOPS editor for `aws_accounts` field in secrets.yaml
    - Manages account mapping without manual SOPS commands
    - Includes inline documentation and usage guidance
  - Added `aws_accounts` SOPS secret definition in `secrets-work.nix`
    - Deploys to `~/.aws/accounts.json` with correct permissions

- **Secret Management Templates** - Profile-specific secret structures
  - Created `nix-config/hosts/_template/secrets-personal.nix`
    - Personal SSH keys, git signing keys, env files, tokens
    - Commented template showing structure and examples
  - Created `nix-config/hosts/_template/secrets-work.nix`
    - AWS credentials, corporate SSH keys, database passwords
    - AWS account mapping (`aws_accounts` field)
    - VPN configurations, work-specific secrets
  - Age encryption with automatic key setup in `configure.sh`

- **Configuration Improvements** (from IMPROVEMENTS-INCLUDED.md)
  - #1: Removed alias duplication (learning/ollama aliases consolidated)
  - #2: Per-profile starship configuration support (implementation deferred to backlog)
  - #3: Fixed missing `algo` alias in personal profile
  - #4: Machine detection migration (partial - cleanup deferred to backlog)

### 🔧 Changed

- **Configuration File Structure** (BREAKING)
  - `config/` directory now gitignored (was tracked)
  - User configuration moved from hardcoded values to `config/user-config.nix`
  - Machine configuration moved from `hosts/*/default.nix` to `config/machine-config.nix`
  - Flake.nix requires `FLAKE_ROOT` environment variable for config discovery
  - All `darwin-rebuild` commands now require `--impure` flag

- **Home Configuration Organization**
  - Moved shared configs to `nix-config/home/_profiles/_template/`
  - Profile-specific overrides in `personal/`, `work/`, `minimal/` directories
  - Base programs (programs/), shell (shell/), development (development/) in template
  - Profile dirs contain only overrides and additions (aliases.nix, packages.nix, etc.)

- **Setup Script Split** (from monolithic setup.sh)
  - `bootstrap.sh`: Prerequisites only (Nix, nix-darwin, SOPS, age)
  - `configure.sh`: Configuration generation and validation (was setup.sh core)
  - `activate.sh`: System build and activation (was end of setup.sh)
  - Better separation of concerns and error handling

- **Machine Detection Refactoring**
  - Primary: `config/machine-config.nix` `machineType` field
  - Deprecated: hostname-based detection (still exists, marked for removal)
  - New pattern: `myLib.selectByMachine machineType { personal = X; work = Y; }`
  - Old pattern: `if hostname == "mbp-jimmy"` (deprecated, in backlog for cleanup)

### 🗑️ Removed

- **Personal Identifiers from Repository**
  - Removed hardcoded "jimmy", "jain", "jimmie", "example-corp" from tracked files
  - Removed personal directory paths (mbp-jimmy, mbp-work, home/jimmy) from git
  - All personal data now in gitignored `config/` directory

- **Hardcoded Fallbacks in flake.nix**
  - Removed default username, email, machineType fallbacks
  - Forces explicit configuration via config files
  - Prevents accidental builds with incorrect configuration

### 📚 Documentation

- **Updated CLAUDE.md** - Comprehensive AI assistant instructions
  - Rule #6: Profile system behavior and switching documentation
  - Critical instructions updated for new architecture
  - Architecture snapshot reflects profile-based structure
  - Files-to-edit reference updated for profile system

- **Project Planning Documentation**
  - `claudedocs/planning/projects/git-privacy/` - 95% complete (16/17 tasks)
  - `claudedocs/planning/projects/profile-migration/` - 75% complete
  - `claudedocs/planning/ACTIVE.md` - Updated project status tracking
  - `claudedocs/planning/BACKLOG.md` - 6 new items for remaining work

- **Documentation Status Note**
  - Documentation moved to `.temp/docs/` during reorganization
  - Restoration and updates deferred to future backlog item
  - CLAUDE.md remains authoritative source during transition

### ⚠️ Breaking Changes

1. **Configuration Files Required** - System will not build without:
   - `config/user-config.nix` (username, fullName, email)
   - `config/machine-config.nix` (machineId, machineType, profileName)
   - Run `./scripts/configure.sh` to generate these files

2. **Impure Build Flag Required** - All builds now require `--impure`:
   ```bash
   darwin-rebuild switch --flake . --impure
   ```
   Use the provided aliases instead:
   ```bash
   nix-rebuild      # Wrapper for darwin-rebuild with --impure
   ```

3. **FLAKE_ROOT Environment Variable** - Required for config discovery:
   ```bash
   export FLAKE_ROOT="$PWD"
   sudo FLAKE_ROOT="$FLAKE_ROOT" darwin-rebuild switch --flake . --impure
   ```
   Helper scripts (`configure.sh`, `activate.sh`) handle this automatically.

4. **Profile Selection** - Machine behavior determined by `config/machine-config.nix`:
   ```nix
   {
     machineId = "macbook-pro-m1";
     machineType = "personal";  # or "work" or "minimal"
     profileName = "personal";  # Must match machineType for now
     # ...
   }
   ```

### 🐛 Known Issues & Workarounds

1. **machineType vs profileName Inconsistency**
   - Current: `config/machine-config.nix` uses `machineType`, `flake.nix` reads `profileName`
   - Workaround: Set both fields to same value ("personal" or "work")
   - Fix: Backlog item to standardize on `profileName` everywhere

2. **Deprecated Machine Detection Functions**
   - Old functions (getMachineType, isPersonal, isWork) still exist
   - Will be removed in future release after migration complete
   - New code should use `machineType` from config directly

3. **Starship Configs Not Differentiated**
   - Personal and work profiles currently use same starship prompt
   - Enhancement deferred to backlog (user decision needed)

### 🚀 Migration Guide

**For Existing Users:**

1. **Backup Current Configuration**:
   ```bash
   git add -A
   git commit -m "backup: Save state before v2.0.0 migration"
   ```

2. **Merge or Pull v2.0.0**:
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Run Configuration Wizard**:
   ```bash
   ./scripts/configure.sh
   ```
   - Enter your username, full name, email
   - Select machine type (personal/work/minimal)
   - Review and edit secrets templates
   - Answer Homebrew prompt

4. **Activate New Configuration**:
   ```bash
   ./scripts/activate.sh
   ```

5. **Verify System**:
   ```bash
   health-check           # Run system health check
   echo $ACTIVE_PROFILE   # Should show your profile
   which git starship fzf # Verify packages
   alias | grep git       # Test aliases
   ```

**For New Users:**

1. Clone repository
2. Run `./scripts/bootstrap.sh` (installs prerequisites)
3. Run `./scripts/configure.sh` (generates configs)
4. Run `./scripts/activate.sh` (builds system)

### 📊 Statistics

- **Commits**: 25 commits on feature/git-privacy-complete branch
- **Files Changed**: 67+ files
- **Lines Changed**: 21,387+ lines
- **Development Time**: ~10 hours (182 min core work + testing + documentation)
- **Testing**: Complete on both personal and work machines
- **Stability**: Production ready, fully tested

### 🎉 Acknowledgments

This release completes the vision of a truly portable, privacy-respecting nix-darwin configuration that can be shared publicly while maintaining personal secrets. The profile-based architecture enables seamless switching between personal and work contexts without configuration conflicts.

---

## [Unreleased] - 2025-11-06

### Added
- **Home Manager Cache Bug Documentation** - Critical troubleshooting guide
  - Created `claudedocs/troubleshooting/HOME-MANAGER-CACHE-BUG.md`
  - Documents bug where `darwin-rebuild` doesn't trigger home-manager regeneration
  - Provides working workaround with `nix build --impure` activation package
  - Added convenient aliases: `nix-rebuild-force`, `home-rebuild-force`
  - Includes verification steps and when to use force rebuild

- **Planning Directory** - Comprehensive task tracking system for future improvements
  - `claudedocs/planning/future-enhancements.md` - 4 system robustness tasks
  - `claudedocs/planning/documentation.md` - 5 documentation improvements
  - `claudedocs/planning/aws-improvements.md` - 3 AWS tooling enhancements
  - `claudedocs/planning/testing.md` - 3 testing/validation tasks
  - `claudedocs/planning/quick-wins.md` - Tasks organized by time investment
  - `claudedocs/planning/PROGRESS.md` - Progress tracking with statistics
  - Total: 16 actionable improvement tasks (~22 hours estimated)
  - Organized as product backlog with sprint planning

- **Oh-My-Zsh Toggle Flag** - `enableOhMyZsh` flag in `zsh.nix`
  - Set to `true` to enable Oh-My-Zsh plugins
  - Set to `false` to disable (uses pure Starship)
  - Keeps empty theme to allow Starship prompt

- **CA Bundle Configuration** - Corporate certificate support
  - Moved CA bundle path to `work.nix` mixin
  - Configurable via `programs.aws.caBundle`
  - Applied conditionally only on work machine

### Changed
- **AWS Helper Architecture** (BREAKING FIX)
  - Moved AWS helper functions from `zsh.nix` to `work.nix`
  - Now properly work-machine specific (not loaded on personal)
  - Removed duplicate/conflicting AWS helpers from `work.nix`
  - Single source of truth: functions read from `accounts.json`
  - **Fixed**: Alias resolution (`awsuse ti sbx` now works)
  - **Fixed**: Profile naming consistency (`project-env` or `project-env-role`)

- **Oh-My-Zsh Plugin Configuration** - Cleaned up plugin conflicts
  - Removed 'z' plugin (conflicts with zoxide, which is faster)
  - Removed duplicate function definitions (mkcd, kill-port, gcl, sysinfo)
  - Removed conflicting extract alias and custom function
  - Oh-My-Zsh extract plugin now works without conflicts
  - Added explanatory comments for future reference

- **Homebrew Configuration** - Fixed deprecated cask names
  - Moved `gemini-cli` from casks to brews (CLI tool, not GUI app)
  - Fixed `docker` → `docker-desktop` (official name)
  - Fixed `ollama` → `ollama-app` (official name)
  - Verified all 24 casks and 3 brews are correctly categorized
  - Eliminates homebrew warnings during rebuild

- **Dependency Updates** - Updated to latest versions
  - home-manager: 2025-11-01 → 2025-11-06
  - nix-darwin: 2025-11-01 → 2025-11-05
  - nixpkgs: 2025-10-31 → 2025-11-05

- **Git Hooks SOPS Detection** - Enhanced encryption validation
  - Now detects both SOPS binary format AND YAML format
  - Checks for `sops:` metadata section
  - Checks for `ENC[AES256_GCM` encrypted values
  - Checks for `mac:` field in YAML format
  - Applied to both pre-commit and pre-push hooks

### Fixed
- **Oh-My-Zsh Z Plugin Conflict** - Removed z plugin that conflicts with zoxide
- **Extract Plugin Parse Error** - Removed conflicting extract definitions
- **Homebrew Warnings** - Fixed deprecated docker and ollama cask names
- **Gemini-CLI Installation** - Moved to correct brew formula section
- **AWS Alias Resolution** - `awsuse ti sbx` now correctly resolves aliases
- **AWS Login Profile Naming** - `awslogin` uses correct profile names
- **SOPS YAML False Positives** - Git hooks no longer reject valid SOPS YAML files
- **CA Bundle Hardcoding** - Corporate certificates now configurable per machine

### Documentation
- Created `ROOT-CAUSE-ANALYSIS.md` - Comprehensive root cause analysis
- Created `CHANGELOG.md` - This file, tracking all changes
- Enhanced inline documentation for AWS helper functions

---

## [1.1.0] - 2025-11-05

### Fixed
- **Home Manager Activation** - Critical permission fix
  - Added system activation script to fix `~/.local/state` ownership
  - Prevents permission denied errors during Home Manager activation
  - Fixes silent failure where dotfiles weren't symlinked
  - See `ROOT-CAUSE-ANALYSIS.md` for details

### Changed
- **Shell Configuration** - Updated zsh and git configurations
- **Gitignore** - Added Planning directory and Claude files

---

## [1.0.5] - 2025-11-04

### Added
- **App Launchers** - Intuitive application launching system
  - Quick access to frequently used applications
  - Workflow shortcuts for common tasks

---

## [1.0.4] - 2025-11-03

### Added
- **Enterprise Credential Management** - Comprehensive secrets system
  - SOPS-encrypted secrets with age keys
  - Multi-environment credential support
  - Database connection management (Oracle, SQL Server, PostgreSQL)
  - Token management for Git, Terraform, Jira
  - File-based credential helpers with permission validation

- **Productivity Improvements** - Complete shell enhancement
  - 100+ zsh aliases (system, git, docker, python, etc.)
  - 60+ git aliases with `g` prefix pattern
  - Modern CLI tools (bat, eza, ripgrep, fd, etc.)
  - Starship prompt with custom configuration
  - Oh-My-Zsh integration with useful plugins

- **Work Mac Configuration** - Enterprise environment support
  - Multi-project AWS SSO integration
  - Database instance connectors
  - Corporate certificate management
  - Work-specific packages and tools

### Changed
- **VS Code Settings** - Made user-editable with sync system
  - Settings managed in `user-data/app-configs/vscode/`
  - `sync-user-data` function to save/restore settings
  - Extensions still managed declaratively in Nix

- **Git Hooks** - Automatic installation and validation
  - Pre-commit hook for secrets validation
  - Pre-push hook for final security checks
  - Automatic permission validation (600 for credentials)
  - SOPS encryption verification

### Documentation
- Added comprehensive guides (40+ documentation files)
- Organized into guides, reference, architecture, appendix
- Created FAQ with 100+ questions
- Added troubleshooting guide

---

## [1.0.0] - 2025-11-03

Initial release of nix-darwin configuration.

### Added
- **Core System** - nix-darwin with Home Manager integration
  - Determinate Nix installer support
  - Multi-machine support (personal + work)
  - Mixin system for machine-specific configuration

- **Base Configuration**
  - macOS system defaults (Dock, Finder, etc.)
  - Starship prompt
  - Basic shell configuration (zsh)
  - Git configuration

- **Package Management**
  - System packages via Nix
  - GUI applications via Homebrew
  - Python with UV and Micromamba
  - Node.js with modern tooling

- **Development Environment**
  - VS Code with extensions
  - Python development setup
  - Node.js development setup
  - AI/ML tools

- **Security**
  - SOPS encrypted secrets
  - Age key management
  - Git hooks for credential protection

- **Documentation**
  - Installation guide
  - Usage guide
  - Architecture documentation
  - Quick reference

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| Unreleased | 2025-11-06 | AWS helpers fix, CA bundle, Oh-My-Zsh toggle, TODO directory |
| 1.1.0 | 2025-11-05 | Home Manager permission fix |
| 1.0.5 | 2025-11-04 | App launchers and shortcuts |
| 1.0.4 | 2025-11-03 | Enterprise features, productivity tools |
| 1.0.0 | 2025-11-03 | Initial release |

---

## Upgrade Notes

### Unreleased → Next Release

**Breaking Changes:**
- AWS helper functions now only available on work machine
- Personal machine will not have `awsuse`, `awslogin` commands
- If you use AWS on personal machine, manual configuration needed

**Action Required:**
1. Rebuild: `nix-rebuild`
2. Restart shell: `exec zsh`
3. Work machine: Test AWS commands with aliases
4. Personal machine: Verify no AWS functions loaded

**Migration:**
- AWS configuration now in `work.nix` only
- Personal AWS config in `home/jimmy/programs/aws.nix` (simple profile)

### 1.0.0 → 1.1.0

**Action Required:**
1. Rebuild applies automatic permission fix
2. No manual intervention needed
3. Fixes silent Home Manager activation failures

---

## Categories

This changelog uses the following categories:

- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security improvements
- **Documentation** - Documentation changes

---

**Maintained by:** Jimmy
**Repository:** ~/nix-darwin
**Last Updated:** 2025-11-06
