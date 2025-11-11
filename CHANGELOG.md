# Changelog

All notable changes to this nix-darwin configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
