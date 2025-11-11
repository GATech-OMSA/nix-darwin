# CLAUDE.md

**AI Assistant Instructions for Nix-Darwin Repository**

---

## Overview

This is a **nix-darwin** configuration repository providing declarative macOS system configuration using Nix + Home Manager. It manages system packages, application configurations, secrets, and supports multiple machines (personal + work).

**One command rebuilds the entire system:** `darwin-rebuild switch --flake .`

---

## Best Practices for CLAUDE.md

This file follows industry best practices for AI assistant instruction files:

**Size & Token Efficiency:**
- Target: <50KB file size, <8,000 tokens
- Current: ~20KB, ~2,500 tokens ✅
- Every line processed with every message - conciseness critical

**Writing Style:**
- Write FOR AI, not FOR humans
- Be directive ("Always do X") not explanatory ("This helps because...")
- Show examples instead of explaining concepts
- Compress where possible without losing clarity

**Content Organization:**
- Link to docs instead of duplicating content
- Update when: New features, major fixes, architecture changes
- Keep as single source of truth for AI behavior

---

## Comprehensive Documentation

This repository includes **19 well-organized documentation files**. **Always refer users to the appropriate documentation** rather than explaining everything inline.

### Documentation Hub

**[docs/index.md](docs/index.md)** - Complete documentation index

### Start Here

1. **[START-HERE.md](docs/START-HERE.md)** 📍 - Main entry point for all users
2. **[QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** ⚡ - One-page cheat sheet

### Key Documentation Sections

**Guides (6 files)** - Practical, task-oriented:

- **[Installation Guide](docs/guides/installation.md)** - Complete setup (consolidates installation, quickstart, first steps, migration, new machine setup)
- **[Usage Guide](docs/guides/usage.md)** - Daily usage, adding packages/aliases, customization, updates
- **[Backup & Recovery](docs/guides/backup-and-recovery.md)** - Backup strategy, disaster recovery, rollback
- **[Secrets Guide](docs/guides/secrets.md)** - Managing encrypted secrets, adding/updating/rotating
- **[Learning Modern CLI](docs/guides/learning.md)** - Modern CLI tools, multi-machine setup
- **[Troubleshooting](docs/guides/troubleshooting.md)** - Common issues and solutions

**Reference (5 files)** - Exhaustive documentation:

- **[System Reference](docs/reference/system.md)** - Nix-Darwin, Home Manager, helper functions
- **[Shell Reference](docs/reference/shell.md)** - Zsh (100+ aliases), Git (60+ aliases), Starship
- **[Languages Reference](docs/reference/languages.md)** - Python (UV, Micromamba), Node.js
- **[Infrastructure Reference](docs/reference/infrastructure.md)** - AWS, Docker, Kubernetes, Terraform
- **[Tools Reference](docs/reference/tools.md)** - VS Code, AI/ML, Modern CLI, macOS

**Architecture (2 files)** - System design:

- **[Architecture Overview](docs/architecture/overview.md)** - System architecture, mixin system
- **[Architecture Reference](docs/architecture/reference.md)** - File structure + best practices

**Appendix (1 file)** - All-in-one reference:

- **[FAQ & Reference](docs/appendix/faq.md)** - FAQ (100+ questions), Glossary, Resources, Changelog

### Quick Reference Links

When user asks about:

**Getting Started:**
- **New user / getting started** → [START-HERE.md](docs/START-HERE.md)
- **Quick commands** → [QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)
- **Installation** → [Installation Guide](docs/guides/installation.md)

**Daily Usage:**
- **Adding packages** → [Usage Guide - Adding Packages](docs/guides/usage.md#adding-packages)
- **Adding aliases** → [Usage Guide - Adding Aliases](docs/guides/usage.md#adding-aliases)
- **Git aliases** → [Shell Reference - Git](docs/reference/shell.md#git)
- **Shell aliases** → [Shell Reference - Zsh](docs/reference/shell.md#zsh)
- **Python setup** → [Languages Reference - Python](docs/reference/languages.md#python)
- **Secrets** → [Secrets Guide](docs/guides/secrets.md)
- **System health** → [System Health Check Guide](docs/guides/system-health.md)
- **Backup/rollback** → [Backup & Recovery Guide](docs/guides/backup-and-recovery.md)

**AWS (Work Mac):**
- **AWS overview** → [Infrastructure Reference - AWS](docs/reference/infrastructure.md#aws)
- **AWS multi-role system** → [AWS Multi-Role Guide](claudedocs/reference/aws/AWS-MULTI-ROLE.md)
- **AWS daily commands** → [AWS Quick Reference](claudedocs/reference/aws/AWS-QUICK-REF.md)

**Troubleshooting & Reference:**
- **Troubleshooting** → [Troubleshooting Guide](docs/guides/troubleshooting.md)
- **FAQ** → [FAQ & Reference](docs/appendix/faq.md)
- **Architecture** → [Architecture Overview](docs/architecture/overview.md)

**Planning & Development (Maintainers):**
- **Improvement roadmap** → [Phase 5 Execution Plan](claudedocs/planning/PHASE-5-EXECUTION-PLAN.md)
- **Current progress** → [Progress Tracker](claudedocs/planning/PROGRESS.md)
- **Task backlog** → [Backlog](claudedocs/planning/BACKLOG.md)

---

## Common Commands

### Building & Switching

```bash
# Rebuild system
darwin-rebuild switch --flake ~/nix-darwin

# Or use alias
nix-rebuild

# Test build without switching
darwin-rebuild build --flake ~/nix-darwin

# First-time installation
sudo nix run nix-darwin -- switch --flake .#mbp-jimmy
# or for work Mac:
sudo nix run nix-darwin -- switch --flake .#mbp-work
```

### Updates

```bash
update-all     # Update everything
update-nix     # Just Nix packages
update-brew    # Just Homebrew
```

See [Usage Guide - Updates](docs/guides/usage.md#updates) for details.

### Rollback

```bash
# Rollback to previous generation
nix-rollback

# Or manually
darwin-rebuild rollback
```

See [Backup & Recovery Guide - Rollback](docs/guides/backup-and-recovery.md#rollback) for details.

### System Health Check

```bash
# Quick health check
health-check

# Detailed diagnostics
health-check --verbose

# Alternative alias
system-health
```

See [System Health Check Guide](docs/guides/system-health.md) for details.

---

## Architecture Overview

### Directory Structure

```
nix-darwin/
├── flake.nix              # Entry point, defines machines
├── hosts/                 # Machine-specific configs
│   ├── mbp-jimmy/        # Personal Mac
│   └── mbp-work/         # Work Mac
├── modules/
│   ├── darwin/           # macOS system settings
│   └── shared/           # System packages
├── home/
│   ├── jimmy/            # User configurations
│   │   ├── shell/        # Zsh (zsh.nix)
│   │   ├── programs/     # Git, VS Code, etc.
│   │   └── development/  # Python, Node.js, AI/ML
│   └── _mixins/          # Machine-specific configs
│       ├── base.nix      # Common to all machines
│       ├── dev.nix       # Development tools
│       ├── personal.nix  # Personal Mac settings
│       └── work.nix      # Work Mac settings
├── lib/                   # Helper functions (30+ utilities)
├── overlays/              # Package customizations
├── pkgs/                  # Custom package definitions
├── docs/                  # 19 comprehensive guides
└── scripts/               # Helper scripts
```

See [Architecture Overview](docs/architecture/overview.md) for complete details.

### Infrastructure Directories

**lib/** - Reusable helper functions (30+ utilities)

- Machine type detection: `selectByMachine`, `isWork`, `isPersonal`
- Shell generators: `mkUpdateFunction`, `mkScaffoldFunction`
- Navigation: `mkNavigationAliases`
- Status messages: `msg.success`, `msg.error`, etc.
- Package management: `mkPackageGroups`, `mkConditionalPackages`
- See [lib/README.md](lib/README.md) for complete reference

**overlays/** - Package overrides and customizations

- Python version pinning
- Micromamba fix documentation (currently using Homebrew)
- See [overlays/README.md](overlays/README.md)

**pkgs/** - Custom package definitions

- For packages not in nixpkgs
- See [pkgs/README.md](pkgs/README.md)

### Configuration Flow

1. `flake.nix` → Defines machine (mbp-jimmy or mbp-work)
2. `hosts/${hostname}/` → Host-specific settings
3. `modules/` → System-level packages and settings
4. `home/jimmy/` → User-level configuration
5. `home/_mixins/` → Machine-specific settings (personal vs work)

See [Architecture Overview](docs/architecture/overview.md) for complete flow.

### Mixin System

Mixins provide machine-specific configuration:

- **base.nix** - Common to all machines (Starship, common tools)
- **dev.nix** - Development packages
- **personal.nix** - Personal Mac (MACHINE_MODE="home", personal AWS)
- **work.nix** - Work Mac (MACHINE_MODE="work", work AWS, work email)

See [Architecture Overview - Mixin System](docs/architecture/overview.md#mixin-system) for complete details.

---

## Security Features

### Git Hooks

Automatic validation on commit/push:
- ✅ **Secrets encryption** - SOPS binary format validation
- ✅ **File permission checks** - 600 for all credential files
- ✅ **Multi-path validation** - hosts/ + user-data/ secrets
- ✅ **Credential protection** - Blocks staging of .db/, .tokens/, .credentials/

### Protected Credentials

**Never committed to git:**
- `~/.db/*` - Database connection files
- `~/.tokens/*` - API tokens
- `~/.aws/credentials` - AWS credentials
- `user-data/secrets/` - User-specific secrets

All protected via:
1. `.gitignore` - Git tracking prevention
2. Pre-commit hooks - Staging validation
3. Pre-push hooks - Final security check

### Permission Requirements

All credential files must have 600 permissions:

```bash
# Automatically validated by git hooks
chmod 600 ~/.db/oracle/prod
chmod 600 ~/.tokens/git_token
chmod 600 ~/.aws/credentials
```

**Warnings** are shown during commit if permissions are insecure, but commits are allowed (to avoid blocking workflow).

### Secrets Encryption

Secrets in `hosts/*/secrets.yaml` are encrypted with SOPS:

```bash
# Edit encrypted secrets
edit-secrets

# Or manually
sops -e -i hosts/mbp-work/secrets.yaml
```

**Git hooks** automatically validate that secrets files are binary (encrypted), not plaintext.

### Security Validation

```bash
# Pre-commit hook runs automatically:
git commit -m "changes"
# 🔍 Validating secrets and credentials...
#   🛡️  Checking for blocked credential files...
#   🔐 Validating SOPS encryption...
#   🔒 Validating file permissions...
# ✅ All security checks passed

# Can bypass with --no-verify (not recommended):
git commit --no-verify -m "bypass hooks"
```

---

## Important Git Changes (Version 2.0)

### Git Alias Pattern

**All git commands use `g` prefix:**

- `g s` (not `gs`) → git status -s
- `g aa` (not `gaa`) → git add --all
- `g co` (not `gco`) → git checkout
- `g cm "msg"` (not `gcm`) → git commit -m

**Why:**

- Access to 60+ git aliases (not just 20)
- Single source of truth in git.nix
- Clean architecture

See [Shell Reference - Git](docs/reference/shell.md#git) for all aliases.

### Config Shortcuts

All config shortcuts use `code` directly:

- `nixconf` - Open nix-darwin folder
- `gitconf` - Edit git.nix
- `zshconf` - Edit zsh.nix
- `vscodeconf` - Edit vscode.nix (extensions/keybindings only)
- `awsconf` - Edit AWS config

**Note**: VS Code settings are managed in user-data, not Nix. Edit settings in VS Code UI, then run `sync-user-data` to save.

See [Shell Reference - Zsh](docs/reference/shell.md#zsh) for all shortcuts.

---

## Key Files to Edit

| Want to...                 | Edit file                                      |
| -------------------------- | ---------------------------------------------- |
| Add system package         | `modules/shared/packages.nix`                  |
| Add GUI app                | `modules/darwin/homebrew.nix`                  |
| Add shell alias            | `home/jimmy/shell/zsh.nix`                     |
| Add git alias              | `home/jimmy/programs/git.nix`                  |
| Add VS Code extensions     | `home/jimmy/programs/vscode.nix`               |
| Change VS Code settings    | VS Code UI → `sync-user-data` to save to git   |
| Change Python setup  | `home/jimmy/development/python.nix` |
| Add personal setting | `home/_mixins/personal.nix`         |
| Add work setting     | `home/_mixins/work.nix`             |

See [Architecture Reference](docs/architecture/reference.md) for complete guide.

---

## Making Changes

### Standard Workflow

1. **Edit config files:**

   ```bash
   nixconf  # Opens in VS Code
   ```

2. **Rebuild:**

   ```bash
   nix-rebuild
   ```

3. **Restart shell (if needed):**

   ```bash
   exec zsh
   ```

4. **Commit:**
   ```bash
   g aa
   g cm "Description"
   g ps
   ```

See [Usage Guide](docs/guides/usage.md) for complete guide.

### Adding Packages

See [Usage Guide - Adding Packages](docs/guides/usage.md#adding-packages)

### Adding Aliases

See [Usage Guide - Adding Aliases](docs/guides/usage.md#adding-aliases)

---

## Personal vs Work Differentiation

Configuration automatically adjusts based on hostname:

| Setting               | Personal (mbp-jimmy)                | Work (mbp-work)            |
| --------------------- | ----------------------------------- | -------------------------- |
| **Mixin**             | personal.nix                        | work.nix                   |
| **MACHINE_MODE**      | home                                | work                       |
| **AWS_PROFILE**       | personal                            | work-domain                |
| **Git email**         | jimmy-jain@users.noreply.github.com | first.last@work-domain.com |
| **Special functions** | None                                | AWS SSO (awslogin, awswho) |

See [Work Setup Guide](docs/guides/work-setup.md) for complete details.

---

## Python Development

**Multi-tier Python setup:**

1. **System Python** - Python 3.13 via Nix
2. **UV** - Fast project venvs (recommended)
3. **Micromamba** - Conda environments for data science

**Auto-activation:**

- Automatically activates venv when entering directory with `.venv`
- Visual feedback: `🐍 Activated virtual environment: .venv`

See [Languages Reference - Python](docs/reference/languages.md#python) for complete guide.

---

## Important Notes for AI Assistants

### 1. Use Lib Functions for Common Patterns

**Available via `myLib` parameter in modules:**

```nix
{ config, pkgs, myLib, hostname, ... }:
```

**Common patterns to use:**

- **Machine-specific values**: Use `myLib.selectByMachine hostname { personal = X; work = Y; }`
- **Conditional imports**: Use `myLib.importIfPersonal hostname path`
- **Navigation aliases**: Use `myLib.mkNavigationAliases "$HOME/Dev" { ... }`
- **Package groups**: Use `myLib.mkPackageGroups { ... } pkgs`

**Don't manually write:**

- `if hostname == "mbp-work" then... else...` → Use `myLib.selectByMachine`
- Multiple `cd ~/Dev/proj` aliases → Use `myLib.mkNavigationAliases`
- Repeated `command -v ... &> /dev/null` → Use `myLib.mkCommandCheck`

See [lib/README.md](lib/README.md) for complete function reference.

### 2. Always Rebuild After Config Changes

Configuration changes require rebuild to take effect:

```bash
nix-rebuild  # or darwin-rebuild switch --flake ~/nix-darwin
```

### 3. Don't Edit Generated Files

**Never edit these directly** (managed by Nix):

- `~/.zshrc`
- `~/.config/git/config`
- `~/.config/starship.toml`

**Edit source files instead:**

- `home/jimmy/shell/zsh.nix`
- `home/jimmy/programs/git.nix`
- `home/_mixins/base.nix`

### 4. Refer to Documentation

**Instead of explaining inline, link to docs:**

- User asks "How do I add package?" → Link to [Usage Guide - Adding Packages](docs/guides/usage.md#adding-packages)
- User asks "Git aliases don't work" → Link to [Troubleshooting](docs/guides/troubleshooting.md)
- User asks "How does mixin work?" → Link to [Architecture Overview - Mixin System](docs/architecture/overview.md#mixin-system)

### 5. Use Appropriate Tools

When making changes:

- **Read tool** - Read config files
- **Edit tool** - Make precise edits
- **Bash tool** - Run `nix-rebuild`, test commands

### 6. Test Before Committing

Recommended workflow:

1. Read current config
2. Make edit
3. Rebuild: `nix-rebuild`
4. Test the change
5. Commit: `g aa && g cm "..." && g ps`

### 7. Git Commit Messages

**NEVER include AI assistant references in commit messages:**

- ❌ Do NOT add "Generated with Claude Code"
- ❌ Do NOT add "Co-Authored-By: Claude"
- ❌ Do NOT mention any AI assistance in commit messages
- ✅ Write clean, professional commit messages without AI attribution

**Reason:** This is a personal configuration repository. Commit messages should reflect the user's work, not the tools used to create it.

**Example commit message format:**
```bash
git commit -m "Add dark mode support to VS Code configuration"
# NOT: "Add dark mode... 🤖 Generated with Claude Code"
```

### 8. Hostname Matters

System behavior depends on hostname:

- `mbp-jimmy` → personal mixin
- `mbp-work` → work mixin

Check with: `hostname`

### 9. State Versions

**Never change these:**

- `system.stateVersion = 5` (in host configs)
- `home.stateVersion = "24.05"` (in home/jimmy/default.nix)

### 10. Machine-Specific Config

Use mixins for machine-specific settings:

- **Shared** → `base.nix` or `dev.nix`
- **Personal only** → `personal.nix`
- **Work only** → `work.nix`

### 11. Oh-My-Zsh

Cannot be installed via Nix. Must be installed manually:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 12. Zsh Plugins

Custom plugins require manual installation:

```bash
./scripts/install-zsh-plugins.sh
```

### 13. Documentation Updates

**Critical Rule**: Update documentation ONLY for significant changes to maintain signal-to-noise ratio.

**Update Triggers** (significant changes requiring documentation):
- New features or capabilities
- Major bug fixes affecting user workflows
- Architectural decisions or structural changes
- Breaking changes to existing functionality
- New tools, scripts, or validation utilities

**Do NOT Update For** (avoid documentation bloat):
- Minor refactoring or code cleanup
- Cosmetic changes (formatting, typos in comments)
- Internal implementation details
- Dependency version bumps
- Debug sessions or temporary fixes

**Documentation Strategy**:
1. **Enhance Before Creating**: Always prefer updating existing documentation over creating new files
2. **Consolidate**: Merge related small docs into comprehensive guides
3. **Link Over Duplicate**: Reference existing docs rather than repeating information
4. **Keep Concise**: Every sentence must add value; remove outdated content aggressively

**CLAUDE.md Maintenance**:
- **Purpose**: Single source of truth for AI assistant context about the project
- **Target Size**: <50KB file size, <8,000 tokens (currently ~2,500 tokens ✅)
- **Update Frequency**: Only when adding features, major fixes, or architecture changes
- **Review First**: Consult [official best practices](https://docs.claude.com/en/docs/claude-code) before implementing changes
- **Writing Style**: Write FOR AI, not FOR humans (directive, concise, example-driven)
- **Signal Over Noise**: Every line is processed with every message - conciseness is critical

**CLAUDE.md Update Checklist**:
- [ ] Is this a significant change? (feature/major fix/architecture)
- [ ] Can existing section be enhanced instead of adding new?
- [ ] Is information already covered in linked docs?
- [ ] Will this be useful for AI context in 6 months?
- [ ] Have I reviewed official best practices?
- [ ] Is the addition <200 words and example-driven?

**Example - Good Documentation Update**:
```markdown
# Added hostname-independent machine detection
- Edit hosts/machines.nix to add new machines
- Use myLib.isPersonal/isWork instead of hostname checks
```

**Example - Skip Documentation Update**:
```markdown
# Refactored internal helper function names (no user impact)
# Fixed typo in code comment (cosmetic only)
# Bumped package version (dependency maintenance)
```

**Changelog vs Documentation**:
- **Changelog**: Record all changes chronologically (git commits)
- **Documentation**: Curated guide to current system state
- Keep CLAUDE.md as "state of the system", not "history of changes"

### 14. Task Execution Workflow

**MANDATORY: Reference planning docs before starting work**

**Before Any Phase Work:**
1. Read `claudedocs/planning/PROGRESS.md` - check phase status, tasks, dependencies
2. Create feature branch: `git checkout -b feature/phase-X-description`

**During Execution:**
- Mark tasks `in_progress` in PROGRESS.md when starting
- Update completion status in PROGRESS.md immediately after finishing
- Reference task numbers (e.g., "Task 2.1") in commit messages

**After Phase Completion:**
1. Create `claudedocs/completed/phase-X/PHASE-X-COMPLETION-SUMMARY.md`
2. Update PROGRESS.md: Mark phase complete, update metrics
3. Archive detailed task documentation to completed/ directory
4. Run validation checkpoint from PROGRESS.md

**Adding New Tasks:**
1. Add to `claudedocs/planning/BACKLOG.md` with classification and effort
2. Periodic review: prioritize using impact-effort matrix
3. Move prioritized items from BACKLOG.md to PROGRESS.md

**Required Updates:**
- PROGRESS.md: Task status changes (mandatory)
- BACKLOG.md: New ideas and intake (as needed)
- CLAUDE.md: Only if significant (see Section 13)

**PM Agent Usage Pattern:**

When using PM agent for backlog grooming or phase planning:

1. Read PROGRESS.md to identify last planned phase
2. If next phase undefined → Create detailed breakdown (task numbers, hours, deliverables)
3. If next phase already defined → Skip to phase after that
4. Never re-groom already-defined phases

Example: Phase 5 defined (11 tasks) + 1 backlog item → PM agent creates Phase 6 breakdown (NOT re-analyze Phase 5)

---

## Troubleshooting

### Build Fails

```bash
# Show detailed trace
darwin-rebuild switch --flake . --show-trace

# Check flake
nix flake check

# If all else fails
nix-rollback
```

See [Troubleshooting Guide](docs/guides/troubleshooting.md) for complete guide.

### Common Issues

| Issue                  | Solution                       |
| ---------------------- | ------------------------------ |
| Command not found      | `exec zsh`                     |
| Git aliases don't work | Use `g` prefix: `g s` not `gs` |
| Changes not applied    | `nix-rebuild && exec zsh`      |
| Build failed           | `nix-rollback`                 |

See [FAQ](docs/appendix/faq.md) for more.

---

## Quick Command Reference

```bash
# Daily use
nix-rebuild              # Rebuild system
exec zsh                 # Restart shell
nix-rollback            # Undo last rebuild

# Updates
update-all              # Update everything
update-nix              # Just Nix
update-brew             # Just Homebrew

# Config shortcuts
nixconf                 # Open nix-darwin
gitconf                 # Edit git.nix
zshconf                 # Edit zsh.nix

# Git (with g prefix)
g s                     # Status
g aa                    # Add all
g cm "msg"              # Commit
g ps                    # Push
g pl                    # Pull
g recent                # Recent branches
```

---

## Additional Resources

### Official Documentation

- **[Complete Documentation](docs/index.md)** - All 19 guides
- **[FAQ](docs/appendix/faq.md)** - Frequently asked questions

### Planning & Analysis Documents

Located in `claudedocs/` directory (for maintainers and contributors):

**Analysis** (archived):
- **[Comprehensive Analysis](claudedocs/archive/COMPREHENSIVE-ANALYSIS-2025-11-06.md)** - Complete codebase analysis with 39 improvement tasks
- **[Root Cause Analysis](claudedocs/archive/ROOT-CAUSE-ANALYSIS.md)** - Home Manager activation issue resolution

**Planning** (active):
- **[Phase 5 Execution Plan](claudedocs/planning/PHASE-5-EXECUTION-PLAN.md)** - Current phase refinement strategy
- **[Progress Tracker](claudedocs/planning/PROGRESS.md)** - Task completion tracking
- **[Backlog](claudedocs/planning/BACKLOG.md)** - Product backlog view

**Completed Phases** (archived):
- **[Phase 1 Completion](claudedocs/completed/phase-1/PHASE-1-COMPLETION-SUMMARY.md)** - Foundation cleanup summary
- **[Phase 2 Completion](claudedocs/completed/phase-2/PHASE-2-COMPLETION-SUMMARY.md)** - Core infrastructure summary

**AWS Documentation** (reference):
- **[AWS Multi-Role Guide](claudedocs/reference/aws/AWS-MULTI-ROLE.md)** - Enhanced multi-role support (414 lines)
- **[AWS Quick Reference](claudedocs/reference/aws/AWS-QUICK-REF.md)** - Daily command cheat sheet
- **[AWS Config Status](claudedocs/reference/aws/AWS-CONFIG-STATUS.md)** - Configuration health report
- **[AWS Implementation Summary](claudedocs/reference/aws/AWS-IMPLEMENTATION-SUMMARY.md)** - Technical implementation details

**Note**: These planning documents are gitignored and stored locally for development purposes.

---

**Version**: 2.0.0
**Documentation**: Complete with 19 comprehensive guides
**Status**: Production Ready ✅
