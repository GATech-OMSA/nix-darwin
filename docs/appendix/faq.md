# Comprehensive FAQ & Reference

**Questions, definitions, resources, and changelog**

[← Back to Index](../index.md)

---

## Overview

This comprehensive reference consolidates frequently asked questions, terminology definitions, external resources, and version history into a single document for easy reference.

---

## Table of Contents

### Part 1: Frequently Asked Questions

1. [General Questions](#general-questions)
2. [Installation & Setup](#installation--setup)
3. [Usage Questions](#usage-questions)
4. [Configuration Questions](#configuration-questions)
5. [Python Questions](#python-questions)
6. [Git Questions](#git-questions)
7. [Troubleshooting Questions](#troubleshooting-questions)
8. [Advanced Questions](#advanced-questions)
9. [Performance Questions](#performance-questions)
10. [Security Questions](#security-questions)
11. [Workflow Questions](#workflow-questions)
12. [Comparison Questions](#comparison-questions)
13. [Getting Help](#getting-help)
14. [Quick Answers](#quick-answers)

### Part 2: Glossary

1. [A-Z Terms](#glossary-a-z-terms)
2. [Acronyms](#acronyms)
3. [Command Prefixes](#command-prefixes)
4. [File Extensions](#file-extensions)
5. [Nix-Specific Terms](#nix-specific-terms)
6. [Git Terms](#git-terms)
7. [Shell Terms](#shell-terms)
8. [Python Terms](#python-terms)
9. [AWS Terms](#aws-terms)
10. [macOS Terms](#macos-terms)
11. [Development Terms](#development-terms)

### Part 3: Resources

1. [Official Nix Resources](#official-nix-resources)
2. [Learning Nix](#learning-nix)
3. [Community](#community)
4. [Tools Documentation](#tools-documentation)
5. [Development Tools](#development-tools-resources)
6. [Infrastructure Tools](#infrastructure-tools)
7. [Cloud Services](#cloud-services)
8. [AI/ML Tools](#aiml-tools)
9. [Configuration Management](#configuration-management-tools)
10. [Useful Commands](#useful-commands)

### Part 4: Changelog

1. [Version 2.0](#version-20---2025-01-02)
2. [Version 1.0](#version-10---2024-12-15)
3. [Pre-release](#pre-release---2024-11-01)
4. [Migration Guides](#migration-guides)
5. [Version History Summary](#version-history-summary)

---

# Part 1: Frequently Asked Questions

## General Questions

### What is Nix-Darwin?

Nix-Darwin is a tool that brings the power of Nix package management to macOS. It allows you to:

- Declaratively configure your system
- Manage packages reproducibly
- Roll back changes atomically
- Share configurations across machines

Think of it as "NixOS for macOS" - but working alongside macOS rather than replacing it.

**Key features:**

- Declarative configuration (describe what you want, not how to get there)
- Atomic updates (all or nothing, no partial states)
- Rollback capability (instant undo)
- Reproducible (same config = same result)

### Why use Nix-Darwin instead of just Homebrew?

**Nix-Darwin advantages:**

- **Reproducible**: Exact same environment every time
- **Rollback**: Instant undo if something breaks
- **Declarative**: Configuration is documentation
- **Version Control**: All changes tracked in git
- **Multi-Machine**: Easy sync across machines

**Homebrew advantages:**

- **Simple**: Easy to learn and use
- **GUI apps**: Better macOS integration for applications
- **Popular**: Large community and package selection

**This setup uses both:**

- Nix for CLI tools (reproducible, fast, version-controlled)
- Homebrew for GUI apps (better macOS integration)

See [Comparison Guide](../architecture/overview.md) for details.

### Is this worth the learning curve?

**Yes, if you:**

- Manage multiple machines (personal + work)
- Value reproducibility and consistency
- Want to track all system changes in git
- Are comfortable with declarative tools
- Need professional development setup
- Enjoy learning new technologies
- Want atomic rollbacks

**Maybe not, if you:**

- Only have one machine
- Want quick-and-easy solutions
- Don't need advanced features
- Prefer imperative management (brew install, apt install)
- Don't want to learn Nix language
- Are satisfied with current setup

**The tradeoff:**

- Higher initial learning curve
- More powerful and maintainable
- Better long-term investment

---

## Installation & Setup

### How long does installation take?

**Initial setup:** 30-60 minutes

- Install Nix: 5 minutes
- Clone repo: 1 minute
- First build: 15-30 minutes (downloads everything)
- Post-setup: 10-20 minutes (Oh-My-Zsh, plugins)

**Subsequent rebuilds:** 1-3 minutes (uses cache)

**Breakdown:**

1. Install Nix: Fast
2. Clone repository: Fast
3. First `nix-rebuild`: Slow (downloads all packages)
4. Install Oh-My-Zsh: 2-3 minutes
5. Install plugins: 2-3 minutes
6. Configure apps: 5-10 minutes

### Do I need to reinstall macOS?

**No!** Nix-Darwin works alongside macOS. It doesn't replace your OS.

**What it does:**

- Installs packages in `/nix/` directory
- Manages dotfiles in your home directory
- Configures system defaults via macOS APIs
- Works with existing applications

**What it doesn't do:**

- Replace macOS system files
- Require OS reinstallation
- Break existing applications
- Delete your data

### Can I try this without affecting my current setup?

**Yes!** You can:

1. **Test on a VM or spare Mac first**
2. **Keep backups of your dotfiles**
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.gitconfig ~/.gitconfig.backup
   ```
3. **Rollback anytime with `nix-rollback`**
4. **Uninstall Nix completely if needed**

**Safe testing approach:**

- Backup current dotfiles
- Clone repository
- Test rebuild
- If issues, rollback or uninstall
- Your data is safe

### What if I want to uninstall?

```bash
# Uninstall Nix-Darwin
sudo /nix/nix-installer uninstall

# Remove Nix completely
sudo rm -rf /nix

# Restore backups
cp ~/.zshrc.backup ~/.zshrc
cp ~/.gitconfig.backup ~/.gitconfig

# Remove repository
rm -rf ~/nix-darwin
```

See [Troubleshooting](../guides/troubleshooting.md#emergency-recovery) for complete uninstall guide.

**Note:** Uninstalling removes Nix but doesn't affect your personal files or other applications.

---

## Usage Questions

### How do I add a new package?

**For CLI tools:**

```bash
# 1. Search for package
nix search nixpkgs <package-name>

# 2. Edit packages.nix
nixconf

# 3. Add to environment.systemPackages
# environment.systemPackages = with pkgs; [
#   neofetch  # Add here
# ];

# 4. Rebuild
nix-rebuild

# 5. Test
which neofetch
neofetch
```

**For GUI apps:**

```bash
# 1. Search Homebrew
brew search <app-name>

# 2. Edit homebrew.nix
nixconf

# 3. Add to casks
# homebrew.casks = [
#   "notion"  # Add here
# ];

# 4. Rebuild
nix-rebuild

# 5. App appears in Applications folder
```

See [Adding Packages](../guides/usage.md#adding-packages).

### How do I add an alias?

```bash
# For shell aliases
zshconf
# Add to shellAliases:
# myalias = "command";
nix-rebuild
exec zsh

# For git aliases
gitconf
# Add to programs.git.aliases:
# myalias = "git-command";
nix-rebuild
exec zsh

# Test
myalias
g myalias  # for git aliases
```

See [Adding Aliases](../guides/usage.md#adding-aliases).

### Why do git aliases use `g` prefix?

All git commands use `g <command>` pattern:

- `g s` instead of `git status`
- `g co main` instead of `git checkout main`
- `g aa` instead of `git add --all`

**Advantages:**

- **Shorter** than typing `git` (saves 2 characters)
- **Access to 60+ aliases** (vs 20 without prefix)
- **Single source of truth** (all in git.nix)
- **Clean architecture** (no duplicate aliases)
- **Consistent pattern** (g + two letters usually)

**Example workflow:**

```bash
g s          # Status
g aa         # Add all
g cm "msg"   # Commit
g ps         # Push
```

See [Git Reference](../reference/shell.md#git).

### How do I update packages?

```bash
# Update everything (recommended)
update-all

# Just Nix packages
update-nix

# Just Homebrew
update-brew
```

**What gets updated:**

- `update-nix`: Flake inputs, Nix packages
- `update-brew`: Homebrew formulae and casks
- `update-all`: Everything above + system

**Frequency:**

- Weekly: `update-nix`
- Monthly: `update-all`

See [Update Guide](../guides/usage.md#updates).

### Something broke after rebuild. How do I fix it?

```bash
# Instant rollback (recommended)
nix-rollback

# Restart shell
exec zsh

# Fix the issue in config
nixconf

# Try again
nix-rebuild
```

**Other recovery options:**

```bash
# Option 2: Revert git commit
g log
g revert <commit-hash>
nix-rebuild

# Option 3: Return to tagged version
g co v2.0
nix-rebuild

# Option 4: Check what changed
darwin-rebuild --list-generations
```

See [Rollback Guide](../guides/backup-and-recovery.md#rollback).

---

## Configuration Questions

### Where are my dotfiles?

**Generated by Nix (don't edit directly!):**

- `~/.zshrc` - From `home/jimmy/shell/zsh.nix`
- `~/.config/git/config` - From `home/jimmy/programs/git.nix`
- `~/.config/starship.toml` - From `home/_mixins/base.nix`

**Source files (edit these!):**

- `home/jimmy/shell/zsh.nix` - Zsh configuration
- `home/jimmy/programs/git.nix` - Git configuration
- `home/_mixins/base.nix` - Starship prompt

**Workflow:**

1. Edit source file (e.g., `zsh.nix`)
2. Rebuild: `nix-rebuild`
3. Restart shell: `exec zsh`
4. Changes applied to generated files

### How do I edit my configuration?

**Quick access shortcuts:**

```bash
nixconf      # Open entire nix-darwin folder in VS Code
gitconf      # Edit git.nix
zshconf      # Edit zsh.nix
vscodeconf   # Edit vscode.nix
awsconf      # Edit AWS config
```

**Then rebuild:**

```bash
nix-rebuild
exec zsh  # If shell config changed
```

**Standard workflow:**

1. Use shortcut to open config
2. Make changes
3. Save file
4. Rebuild
5. Test changes
6. Commit if working

### What's the difference between system and user packages?

**System packages** (`modules/shared/packages.nix`):

- Available to all users on the machine
- Requires root privileges to modify
- System-wide tools (git, curl, etc.)
- Installed at system level

**User packages** (`home/jimmy/default.nix`):

- Only for your user account
- No root privileges needed
- User-specific tools
- Installed in user profile

**When to use:**

- **System:** Core utilities, shared tools
- **User:** Personal preferences, user-specific tools

**Example:**

```nix
# System (modules/shared/packages.nix)
environment.systemPackages = with pkgs; [
  git  # Everyone needs git
];

# User (home/jimmy/default.nix)
home.packages = with pkgs; [
  neofetch  # Just for me
];
```

### How do personal and work Macs differ?

**Determined by hostname:**

- `mbp-jimmy` → Loads `personal.nix` mixin
- `mbp-work` → Loads `work.nix` mixin

**Different settings:**

| Setting      | Personal (mbp-jimmy) | Work (mbp-work)            |
| ------------ | -------------------- | -------------------------- |
| MACHINE_MODE | home                 | work                       |
| AWS_PROFILE  | personal             | example-corp                |
| Git email    | personal email       | work email                 |
| Functions    | Standard             | AWS SSO (awslogin, awswho) |
| Shortcuts    | Personal projects    | Work projects              |

**How it works:**

```nix
# In flake.nix
if hostname == "mbp-jimmy" then
  load personal.nix
else if hostname == "mbp-work" then
  load work.nix
```

See [Multi-Machine Guide](../guides/learning.md#multi-machine-setup).

---

## Python Questions

### How does Python virtual environment auto-activation work?

The shell automatically detects when you `cd` into a directory with:

- `pyproject.toml` + `.venv/` (UV projects)
- `.venv/`, `venv/`, or `env/` directories

**Auto-activation process:**

```bash
cd ~/Dev/my-project
# 🐍 Activated UV virtual environment: .venv

# Venv is now active automatically!
python --version  # Uses venv Python
which python      # Shows venv path
```

**How it works:**

1. `chpwd` hook runs on directory change
2. Checks for virtual environment markers
3. Activates if found
4. Shows visual feedback
5. Deactivates when leaving directory

See [Python Reference](../reference/languages.md#python#auto-activation).

### Can I use pip instead of UV?

**Yes**, but UV is recommended:

- **Much faster** (10-100x faster than pip)
- **Better dependency resolution** (handles conflicts better)
- **Modern Python tooling** (project management built-in)
- **Compatible** (works with existing requirements.txt)

**You can still use pip:**

```bash
# In activated venv
pip install package

# UV can use pip under the hood
uv pip install package  # Uses UV's fast implementation
```

**Best practice:**

- Use UV for new projects
- Use pip for legacy projects
- Both work fine

### How do I use Micromamba?

```bash
# Activate base environment
base

# Or full command
micromamba activate base

# Create new environment
micromamba create -n myenv python=3.11

# Install packages
micromamba install -n myenv numpy pandas

# Activate environment
micromamba activate myenv

# Deactivate
micromamba deactivate
```

**When to use:**

- Data science projects (NumPy, Pandas, SciPy)
- Need conda packages
- Complex dependencies
- Scientific computing

**UV vs Micromamba:**

- **UV:** Fast, modern, pure Python
- **Micromamba:** Conda-compatible, scientific packages

See [Python Reference](../reference/languages.md#python#micromamba).

---

## Git Questions

### Why are my git aliases not working?

**Common issues:**

1. **Forgot `g` prefix:**

   ```bash
   # Wrong
   recent

   # Right
   g recent
   ```

2. **Shell not restarted:**

   ```bash
   exec zsh
   ```

3. **Config not rebuilt:**

   ```bash
   nix-rebuild
   exec zsh
   ```

4. **Typo in alias name:**
   ```bash
   # Check available aliases
   g aliases
   ```

**Troubleshooting steps:**

1. Verify alias exists: `g aliases | grep <alias>`
2. Check git config: `g config --list | grep alias`
3. Rebuild: `nix-rebuild`
4. Restart shell: `exec zsh`
5. Test again

### How do I see all git aliases?

```bash
# Show all aliases
g config --list | grep alias

# Or use alias
g aliases

# Search for specific alias
g aliases | grep status

# Show git config location
g config --list --show-origin | grep alias
```

**Output example:**

```
alias.s=status -s
alias.st=status
alias.aa=add --all
alias.cm=commit -m
...
```

See [Git Reference](../reference/shell.md#git).

### Can I use my own git aliases?

**Yes!** Add to `home/jimmy/programs/git.nix`:

```nix
programs.git.aliases = {
  # Your custom aliases
  myalias = "your-command";
  custom = "log --graph --pretty=format:'%h - %s'";

  # Override existing aliases
  s = "status";  # Different from default
};
```

**After adding:**

```bash
nix-rebuild
exec zsh
g myalias  # Use your alias
```

**Best practices:**

- Use descriptive names
- Comment complex aliases
- Test before committing
- Don't override useful defaults without reason

---

## Troubleshooting Questions

### Build fails with "attribute missing"

**Cause:** Package name is wrong or not in nixpkgs.

**Solution:**

```bash
# Search for correct name
nix search nixpkgs <package>

# Example
nix search nixpkgs ripgrep
# Shows: legacyPackages.aarch64-darwin.ripgrep

# Fix in config
nixconf
# Change to correct package name

# Rebuild
nix-rebuild
```

**Common mistakes:**

- Wrong package name (ripgrep vs rg)
- Package not in nixpkgs
- Typo in package name
- Using Homebrew name instead of Nix name

### "command not found" after rebuild

**Solutions:**

1. **Restart shell:**

   ```bash
   exec zsh
   ```

2. **Check PATH:**

   ```bash
   echo $PATH
   # Should include /nix/store paths
   ```

3. **Verify package installed:**

   ```bash
   which <command>
   nix-env -q  # List installed packages
   ```

4. **Check spelling:**
   ```bash
   # Maybe it's a different command
   ls /nix/store | grep <command>
   ```

**If still not working:**

- Verify package in config file
- Rebuild: `nix-rebuild`
- Check for typos
- Search nixpkgs: `nix search nixpkgs <command>`

### Prompt looks wrong

**Cause:** Font not set correctly or Nerd Font not installed.

**Solution:**

1. **Install Nerd Font (should be automatic):**

   ```bash
   # Verify fonts installed
   ls ~/Library/Fonts | grep -i nerd
   ```

2. **Configure terminal to use Nerd Font:**

   - **iTerm2:** Preferences → Profiles → Text
   - Font: MesloLGM Nerd Font, 13pt
   - **Terminal.app:** Preferences → Profiles → Font
   - Select MesloLGM Nerd Font

3. **Restart terminal:**
   - Close and reopen terminal
   - Test prompt appears correctly

**What you should see:**

- Git branch icon
- Directory icons
- Status symbols
- Clean formatting

### Changes not applied after rebuild

**Try:**

```bash
# 1. Rebuild
nix-rebuild

# 2. Restart shell
exec zsh

# 3. If still not working, reboot (for some macOS settings)
sudo reboot
```

**What requires what:**

- **Packages:** Rebuild only
- **Shell config:** Rebuild + restart shell
- **System settings:** Rebuild + reboot
- **GUI apps:** Rebuild (app update on next launch)

**Troubleshooting:**

1. Verify config file saved
2. Check for syntax errors
3. Read rebuild output for errors
4. Test in new shell session

---

## Advanced Questions

### Can I use this on Linux?

This configuration is **macOS-specific** (uses Nix-Darwin).

**For Linux:**

- Use **NixOS** (full Linux distro)
- Or **Home Manager** standalone (just user config)
- Or adapt this config (remove Darwin-specific parts)

**What's macOS-specific:**

- Nix-Darwin modules (modules/darwin/)
- Homebrew configuration
- macOS system defaults
- Some applications

**What's portable:**

- Home Manager config (home/jimmy/)
- Nix packages
- Shell configuration
- Git configuration

### Can I pin package versions?

**Yes**, via flake.lock:

```bash
# Lock current versions (done automatically on first build)
nix flake update

# Pin specific package version (advanced)
# In flake.nix, override package:
nixpkgs.overlays = [
  (final: prev: {
    python311 = prev.python311.overrideAttrs (old: {
      version = "3.11.5";  # Pin specific version
    });
  })
];
```

**Simpler approach:**

- `flake.lock` already pins all versions
- Don't update unless you want newer versions
- Use `nix flake update` to update all at once

### How do I override a package?

**Advanced:** Use Nix overlays in `flake.nix`:

```nix
nixpkgs.overlays = [
  (final: prev: {
    # Override package
    mypackage = prev.mypackage.override {
      enableFeature = true;
    };

    # Override attributes
    python311 = prev.python311.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [ "--enable-optimizations" ];
    });
  })
];
```

**When to use:**

- Enable/disable package features
- Change build options
- Pin specific versions
- Add patches

**Documentation:**

- Nixpkgs manual: https://nixos.org/manual/nixpkgs/stable/#chap-overrides

### Can I use Nix on multiple users?

**Yes**, but this config is single-user focused.

**For multi-user:**

- Separate user configs in `home/` directory
- Each user has their own `home/<username>/` folder
- Shared system packages in `modules/`

**Example structure:**

```
home/
├── jimmy/
│   └── default.nix
├── alice/
│   └── default.nix
└── bob/
    └── default.nix
```

---

## Performance Questions

### Why is first build so slow?

**Cause:** Downloading all packages for first time.

**Typical time:** 15-30 minutes

**What's happening:**

- Downloading nixpkgs
- Building/downloading all packages
- Setting up environment
- Installing applications

**After first build:** Rebuilds are 1-3 minutes (uses cache).

**Speed it up:**

- Use fast internet connection
- Enable binary cache (automatic)
- Don't add too many packages at once

### How do I speed up rebuilds?

1. **Use Nix binary cache** (automatic)

   - Pre-built packages downloaded instead of compiled
   - Much faster than building from source

2. **Clean old generations:**

   ```bash
   nix-clean
   ```

3. **Don't change many packages at once**

   - Add 1-2 packages at a time
   - Rebuild faster, easier to debug

4. **Keep flake inputs updated:**
   ```bash
   update-nix  # Weekly
   ```

**Expected rebuild times:**

- No changes: ~10 seconds
- Few packages: ~1 minute
- Many packages: ~3-5 minutes

### How much disk space does this use?

**Typical usage:**

- **Nix store:** 5-8 GB
- **Build cache:** 2-3 GB
- **Total:** ~10 GB

**Clean up:**

```bash
# Check disk space
duf

# Check what's using space
dust /nix

# Clean old generations
nix-collect-garbage -d
nix-clean

# Optimize store (deduplicate)
nix-store --optimise
```

**Disk space thresholds:**

- Normal: 5-15 GB
- High: 15-25 GB (consider cleaning)
- Very high: >25 GB (clean up!)

---

## Security Questions

### Where do I put secrets?

**NEVER in nix config!**

**Use these files (gitignored):**

- `~/.zsh_secrets` (sourced automatically)
- `~/.aws/credentials`
- `~/.ssh/id_ed25519` (private keys)
- `~/.env` files

**Example ~/.zsh_secrets:**

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
```

**This file is:**

- Automatically sourced by zsh
- In .gitignore (won't be committed)
- Secure (only you can read it)

See [Secrets Guide](../guides/secrets.md).

### Is my configuration safe to make public?

**Yes, IF:**

- No secrets in config
- No API keys
- No passwords
- No private tokens
- No personal information you want private

**Check before committing:**

```bash
# Review all changes
g d

# Search for potential secrets
rg -i "api[_-]?key|secret|password|token" --type nix

# If found, remove them!
```

**Safe to share:**

- Package lists
- Aliases
- System settings
- Public email addresses

**Never share:**

- API keys
- Passwords
- Private tokens
- AWS credentials

### How do I rotate credentials?

**Regularly rotate:**

- **API keys** (quarterly)
- **AWS credentials** (monthly)
- **SSH keys** (yearly)
- **GitHub tokens** (as needed)

**Rotation workflow:**

```bash
# 1. Generate new credentials
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Update services (GitHub, AWS, etc.)

# 3. Update local files
# Edit ~/.zsh_secrets
# Edit ~/.aws/credentials

# 4. Test new credentials
ssh -T git@github.com
aws sts get-caller-identity

# 5. Revoke old credentials

# 6. Backup new credentials securely
```

See [Secrets Guide](../guides/secrets.md#best-practices).

---

## Workflow Questions

### How do I sync between personal and work Mac?

**Same repository, different configs:**

1. **Make changes on one Mac:**

   ```bash
   nixconf
   # Make changes
   nix-rebuild
   # Test
   g aa
   g cm "Add feature"
   g ps
   ```

2. **Update other Mac:**
   ```bash
   g pl
   nix-rebuild
   exec zsh
   ```

**Workflow:**

- Edit on either machine
- Commit and push
- Pull on other machine
- Rebuild
- Machine-specific settings handled by mixins

See [Multi-Machine Guide](../guides/learning.md#multi-machine-setup).

### Can I test changes without committing?

**Yes:**

```bash
# Make changes
nixconf

# Test (don't commit)
nix-rebuild
exec zsh

# Test your changes

# If good, commit
g aa
g cm "Add feature"

# If bad, rollback
nix-rollback
g restore .
```

**Or use stash:**

```bash
# Stash changes
g stash

# Try something else

# Restore changes
g stash pop
```

### How do I experiment safely?

**Use branches:**

```bash
# Create experiment branch
g cob experiment/feature

# Make changes
nixconf
nix-rebuild

# Test thoroughly

# If works:
g co main
g merge experiment/feature
g ps

# If doesn't work:
g co main
g branch -D experiment/feature
```

**Experiment workflow:**

1. Create branch
2. Make changes
3. Test
4. Merge if good, delete if bad
5. Main branch stays clean

---

## Comparison Questions

### Nix-Darwin vs Ansible?

| Feature            | Nix-Darwin            | Ansible                   |
| ------------------ | --------------------- | ------------------------- |
| **Declarative**    | Truly declarative     | Mostly declarative        |
| **Rollback**       | Atomic, instant       | Manual, complex           |
| **Speed**          | Fast (binary cache)   | Slower (runs tasks)       |
| **Purpose**        | Systems configuration | Automation, orchestration |
| **Learning curve** | Steep                 | Moderate                  |
| **Community**      | Growing               | Large, established        |
| **Language**       | Nix                   | YAML + Jinja2             |

**Nix-Darwin advantages:**

- Atomic rollback
- Truly reproducible
- Package management built-in
- Faster execution

**Ansible advantages:**

- Industry standard
- Larger community
- Better for servers/fleets
- More resources available

See [Comparison](../architecture/overview.md#vs-ansible).

### Nix-Darwin vs Chezmoi?

| Feature            | Nix-Darwin         | Chezmoi            |
| ------------------ | ------------------ | ------------------ |
| **Scope**          | Complete system    | Dotfiles only      |
| **Packages**       | ✅ Yes             | ❌ No              |
| **Rollback**       | ✅ Atomic          | ❌ No              |
| **Learning curve** | Steep              | Easy               |
| **Purpose**        | Full system config | Dotfile management |

**Nix-Darwin:**

- Complete system management
- Packages + dotfiles + settings
- Rollback support
- More complex

**Chezmoi:**

- Dotfiles only
- Simpler to use
- No package management
- Easier to learn

**Use both?** Yes, some people use Chezmoi for dotfiles and Nix for packages.

See [Comparison](../architecture/overview.md#vs-chezmoi).

---

## Getting Help

### Where can I learn more?

**This Documentation:**

- [Getting Started](../guides/installation.md)
- [Daily Usage](../guides/usage.md)
- [Configuration](../guides/usage.md)
- [Troubleshooting](../guides/troubleshooting.md)

**External Resources:**

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix-Darwin GitHub](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Discourse](https://discourse.nixos.org/)

### How do I report issues?

**For this config:**

1. Check [Troubleshooting](../guides/troubleshooting.md)
2. Review this FAQ
3. Search existing issues
4. Open GitHub issue with:
   - Description of problem
   - Steps to reproduce
   - Error messages
   - System information

**For Nix-Darwin:**

- [Nix-Darwin Issues](https://github.com/LnL7/nix-darwin/issues)

**For packages:**

- [Nixpkgs Issues](https://github.com/NixOS/nixpkgs/issues)

---

## Quick Answers

### Can I use this with...

| Tool       | Answer | Notes                      |
| ---------- | ------ | -------------------------- |
| Docker     | ✅ Yes | via Homebrew cask          |
| VS Code    | ✅ Yes | configured in vscode.nix   |
| Homebrew   | ✅ Yes | integrated in homebrew.nix |
| Python     | ✅ Yes | UV + Micromamba setup      |
| Node.js    | ✅ Yes | via Nix packages           |
| AWS        | ✅ Yes | CLI + SSO configured       |
| Kubernetes | ✅ Yes | kubectl + k9s              |
| Terraform  | ✅ Yes | via Nix packages           |

### Does this support...

| Feature          | Answer     | Notes                  |
| ---------------- | ---------- | ---------------------- |
| Apple Silicon    | ✅ Yes     | M1/M2/M3 supported     |
| Intel Mac        | ✅ Yes     | x86_64 supported       |
| Multiple users   | ⚠️ Partial | Single-user focused    |
| Linux            | ❌ No      | macOS only (use NixOS) |
| Windows          | ❌ No      | macOS only             |
| Virtual machines | ✅ Yes     | Works in VMs           |

---

## Still Have Questions?

1. **Check documentation:** [Index](../index.md)
2. **Search this FAQ** (Cmd+F)
3. **Read troubleshooting:** [Troubleshooting](../guides/troubleshooting.md)
4. **Check resources:** [Resources section below](#official-nix-resources)
5. **Ask community:** [NixOS Discourse](https://discourse.nixos.org/)
6. **Open an issue** on GitHub

---

# Part 2: Glossary

## Glossary A-Z Terms

### A

**Alias**
A shortcut command that expands to a longer command. Example: `ll` expands to `eza -la --git --icons`.

**Apple Silicon**
Apple's ARM-based processors (M1, M2, M3, M4, etc.) used in modern Macs since 2020.

**Auto-Activation**
Feature that automatically activates Python virtual environments when entering project directories.

**AWS SSO**
AWS Single Sign-On - authentication method for AWS that uses temporary credentials instead of long-lived access keys.

### B

**Base Mixin**
Configuration file (`home/_mixins/base.nix`) containing settings common to all machines.

**Bash**
Unix shell - predecessor to Zsh. Still widely used but Zsh is default on macOS since Catalina.

**Binary Cache**
Pre-built packages stored by Nix to avoid compiling from source. Makes installations much faster.

**Brewfile**
Homebrew's configuration file listing packages and casks (not used in this setup - we use Nix instead).

### C

**Cask**
Homebrew term for macOS GUI applications (e.g., "visual-studio-code" is a cask, "git" is a brew).

**Channel**
Nix term for package repository version. This setup uses "nixpkgs-unstable" channel for latest packages.

**CLI**
Command Line Interface - text-based interface for interacting with programs.

### D

**Darwin**
Apple's name for the Unix core of macOS. Hence "Nix-Darwin" = Nix for macOS.

**Declarative**
Configuration style where you describe the desired end state, rather than steps to achieve it.

**Derivation**
Nix term for a build recipe that describes how to build a package.

**Dotfile**
Configuration file with name starting with `.` (like `.zshrc`, `.gitconfig`). Usually hidden in file browsers.

### E

**Environment Variable**
Variable available to all processes in a shell session. Example: `$HOME`, `$PATH`, `$EDITOR`.

**Eza**
Modern replacement for `ls` with colors, icons, and better defaults.

### F

**Flake**
Modern Nix feature for reproducible, composable projects. This repo uses flakes.

**flake.lock**
Lock file that pins exact versions of all Nix dependencies for reproducibility.

**flake.nix**
Main configuration file for a Nix flake, defining inputs and outputs.

**fzf**
Fuzzy finder - interactive search tool for command history, files, and more.

### G

**Generation**
Snapshot of system configuration in Nix. Can rollback to previous generations.

**Git Alias**
Shortcut for git commands defined in git config. Example: `co` for `checkout`.

**GUI**
Graphical User Interface - applications with visual interface (vs CLI).

### H

**Home Manager**
Nix tool for managing user-level configuration (dotfiles, applications, settings).

**Homebrew**
macOS package manager. This setup uses it alongside Nix for GUI apps.

### I

**Imperative**
Configuration style where you specify steps to take, not final state (opposite of declarative).

**initExtra**
Home Manager option for adding custom shell initialization code.

### K

**kubectl**
Command-line tool for Kubernetes. Aliased to `k` in this setup.

**k9s**
Terminal UI for Kubernetes clusters.

### L

**Lock File**
See **flake.lock**.

### M

**Machine Mode**
Environment variable (`$MACHINE_MODE`) that identifies machine type: "home" or "work".

**MAS**
Mac App Store command-line interface for installing App Store apps.

**Micromamba**
Lightweight, fast replacement for Conda - Python environment manager.

**Mixin**
Modular configuration file that can be included in system config. Used for machine-specific settings.

### N

**Nerd Font**
Font with extra icons and glyphs for terminal prompts (like Starship). Required for proper prompt display.

**Nix**
Purely functional package manager and build system.

**Nix-Darwin**
Tool that brings Nix package management to macOS with system configuration.

**Nix Store**
Directory (`/nix/store/`) where all Nix packages are stored immutably.

**nixpkgs**
The Nix package repository - largest package repo in existence (80,000+ packages).

**NixOS**
Linux distribution built around Nix. Nix-Darwin brings similar concepts to macOS.

### O

**Oh-My-Zsh**
Zsh framework with plugins, themes, and helpers.

**Ollama**
Tool for running Large Language Models (LLMs) locally.

### P

**Package Manager**
Tool for installing and managing software (Nix, Homebrew, apt, yum, etc.).

**PATH**
Environment variable listing directories where shell looks for executable commands.

**Profile**
Set of packages and configurations installed together in Nix.

### R

**Rebuild**
Process of applying configuration changes. Command: `nix-rebuild` or `darwin-rebuild switch`.

**Reproducible**
Property where same configuration produces same result every time, anywhere.

**Rollback**
Reverting to previous system configuration. Command: `nix-rollback`.

**Ripgrep (rg)**
Fast grep replacement written in Rust. Used for searching file contents.

### S

**Session Variable**
Environment variable that persists for entire shell session.

**Shell**
Command-line interpreter (Zsh, Bash, Fish, etc.). Interface between user and operating system.

**Shell Alias**
See **Alias**.

**SSO**
See **AWS SSO**.

**Starship**
Fast, customizable shell prompt written in Rust. Shows git status, directory, language versions, etc.

**State Version**
Home Manager setting that must never change after initial installation. Ensures compatibility.

**Symlink**
Symbolic link - file that points to another file.

**System Packages**
Packages installed system-wide (vs user-level), available to all users.

### T

**Terraform**
Infrastructure as Code tool for cloud resources.

**TOML**
Configuration file format (Tom's Obvious, Minimal Language) used by Starship and other tools.

### U

**UV**
Modern Python package manager written in Rust - much faster than pip.

**Unstable Channel**
Bleeding-edge Nix packages (vs stable). This setup uses unstable for latest versions.

### V

**Virtual Environment (venv)**
Isolated Python environment with its own packages.

**VS Code**
Visual Studio Code - Microsoft's code editor. Configured via vscode.nix.

### Z

**Zsh**
Z Shell - modern Unix shell, default on macOS. More powerful than Bash.

**.zshrc**
Zsh configuration file. Generated by Home Manager in this setup (don't edit directly!).

---

## Acronyms

| Acronym | Full Term                           | Description                |
| ------- | ----------------------------------- | -------------------------- |
| AWS     | Amazon Web Services                 | Cloud computing platform   |
| CLI     | Command Line Interface              | Text-based interface       |
| GPU     | Graphics Processing Unit            | Hardware accelerator       |
| GUI     | Graphical User Interface            | Visual interface           |
| IDE     | Integrated Development Environment  | Code editor with features  |
| LLM     | Large Language Model                | AI text model              |
| LSP     | Language Server Protocol            | Editor language features   |
| MAS     | Mac App Store                       | Apple's app store CLI      |
| ML      | Machine Learning                    | AI technique               |
| OS      | Operating System                    | System software            |
| PATH    | Program search path                 | Where shell finds commands |
| SSH     | Secure Shell                        | Remote access protocol     |
| SSO     | Single Sign-On                      | Authentication method      |
| UI      | User Interface                      | How users interact         |
| URL     | Uniform Resource Locator            | Web address                |
| UV      | Ultra-fast (Python package manager) | Rust-based Python tool     |
| VM      | Virtual Machine                     | Virtualized computer       |
| VPN     | Virtual Private Network             | Secure network connection  |
| VSCode  | Visual Studio Code                  | Microsoft's code editor    |

---

## Command Prefixes

| Prefix | Meaning              | Example                    |
| ------ | -------------------- | -------------------------- |
| `g`    | Git command          | `g s` = git status         |
| `~`    | Home directory       | `~/Dev` = /Users/jimmy/Dev |
| `$`    | Environment variable | `$HOME` = home directory   |
| `.`    | Current directory    | `./script.sh`              |
| `..`   | Parent directory     | `cd ..`                    |
| `-`    | Previous directory   | `cd -`                     |
| `/`    | Root directory       | `/nix/store`               |

---

## File Extensions

| Extension | Type                   | Description                |
| --------- | ---------------------- | -------------------------- |
| `.nix`    | Nix configuration file | Nix language               |
| `.lock`   | Lock file              | flake.lock dependency pins |
| `.md`     | Markdown documentation | Human-readable docs        |
| `.sh`     | Shell script           | Bash/Zsh script            |
| `.zsh`    | Zsh script             | Zsh-specific script        |
| `.py`     | Python file            | Python source code         |
| `.toml`   | TOML configuration     | Starship, UV config        |
| `.json`   | JSON data file         | Structured data            |
| `.yaml`   | YAML configuration     | Config files               |

---

## Nix-Specific Terms

**Derivation**
Build recipe describing how to build a package.

**Expression**
Nix language code describing a package or configuration.

**Flake**
Modern Nix project format with inputs, outputs, and lock file.

**Generation**
Immutable snapshot of system state. Can switch between generations.

**Input**
External dependency in a flake (nixpkgs, nix-darwin, home-manager, etc.).

**Output**
What a flake provides (system configurations, packages, development shells, etc.).

**Override**
Customizing a package's build inputs or parameters.

**Profile**
Named collection of packages and settings.

**Store**
Directory (`/nix/store/`) containing all built packages immutably.

---

## Git Terms

**Branch**
Parallel version of code for working on features independently.

**Commit**
Snapshot of code changes with message describing them.

**Hash**
Unique identifier for commits, files, etc. (SHA-1).

**HEAD**
Pointer to current commit in git.

**Merge**
Combining changes from different branches.

**Pull**
Fetching and merging changes from remote repository.

**Push**
Sending local commits to remote repository.

**Remote**
Repository hosted on service like GitHub.

**Revert**
Creating new commit that undoes previous commit.

**Tag**
Named reference to specific commit (for releases, stable versions, etc.).

---

## Shell Terms

**Alias**
Command shortcut (e.g., `ll` → `eza -la`).

**Environment Variable**
Named value available to shell and programs.

**Function**
Reusable shell code that can take parameters.

**Init Script**
Code run when shell starts (`.zshrc`).

**PATH**
List of directories searched for executable commands.

**Prompt**
Text displayed before command input (customized by Starship).

**Shell**
Command-line interpreter (Zsh, Bash, etc.).

---

## Python Terms

**Conda**
Python environment and package manager.

**Micromamba**
Lightweight, fast Conda alternative.

**pip**
Python package installer (slower than UV).

**pyproject.toml**
Modern Python project configuration file (PEP 518).

**UV**
Ultra-fast Python package manager and project manager.

**Virtual Environment (venv)**
Isolated Python environment with its own packages.

---

## AWS Terms

**Access Key**
Long-lived credentials for AWS (less secure than SSO).

**CLI**
AWS Command Line Interface tool.

**Credentials**
Authentication information for AWS.

**Profile**
Named set of AWS configuration and credentials.

**Region**
AWS geographical location (us-east-1, us-west-2, etc.).

**SSO**
Single Sign-On - secure, temporary authentication method.

---

## macOS Terms

**Cask**
Homebrew term for GUI application.

**Finder**
macOS file browser application.

**Homebrew**
Package manager for macOS.

**iTerm2**
Advanced terminal emulator for macOS.

**Spotlight**
macOS system-wide search (Cmd+Space).

---

## Development Terms

**Docker**
Containerization platform for running isolated applications.

**IDE**
Integrated Development Environment (like VS Code).

**Kubernetes (k8s)**
Container orchestration platform.

**LSP**
Language Server Protocol - provides editor features like autocomplete.

**Terraform**
Infrastructure as Code tool.

---

# Part 3: Resources

## Official Nix Resources

### Nix Package Manager

- **Website:** https://nixos.org/
- **Manual:** https://nixos.org/manual/nix/stable/
- **Package Search:** https://search.nixos.org/packages
- **Options Search:** https://search.nixos.org/options

### Nix-Darwin

- **GitHub:** https://github.com/LnL7/nix-darwin
- **Manual:** https://daiderd.com/nix-darwin/manual/
- **Options:** https://daiderd.com/nix-darwin/manual/index.html#sec-options

### Home Manager

- **GitHub:** https://github.com/nix-community/home-manager
- **Manual:** https://nix-community.github.io/home-manager/
- **Options:** https://nix-community.github.io/home-manager/options.xhtml
- **Release Notes:** https://nix-community.github.io/home-manager/release-notes.xhtml

---

## Learning Nix

### Tutorials

**Nix Pills**

- https://nixos.org/guides/nix-pills/
- Deep dive into Nix concepts
- Best for understanding fundamentals

**Zero to Nix**

- https://zero-to-nix.com/
- Beginner-friendly introduction
- Quick start guides

**Nix.dev**

- https://nix.dev/
- Official learning resource
- Tutorials and guides

### Videos

- **Jon Ringer - Nix Flakes:** https://www.youtube.com/watch?v=K54KKAx2wNc
- **Burke Libbey - Nix Fundamentals:** https://www.youtube.com/watch?v=m4sv2M9jRLg

### Books

- **NixOS & Flakes Book:** https://nixos-and-flakes.thiscute.world/

---

## Community

### Forums & Discussion

**NixOS Discourse**

- https://discourse.nixos.org/
- Official forum
- Questions, discussions, announcements

**Nix Reddit**

- https://www.reddit.com/r/NixOS/
- Community discussions
- Tips and tricks

**Nix Matrix Chat**

- https://matrix.to/#/#nix:nixos.org
- Real-time chat
- Help and support

---

## Tools Documentation

### Shell & Terminal

**Zsh**

- Website: https://www.zsh.org/
- Manual: https://zsh.sourceforge.io/Doc/
- Guide: https://github.com/hmml/awesome-zsh

**Oh-My-Zsh**

- GitHub: https://github.com/ohmyzsh/ohmyzsh
- Wiki: https://github.com/ohmyzsh/ohmyzsh/wiki
- Plugins: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins

**Starship**

- Website: https://starship.rs/
- Configuration: https://starship.rs/config/
- Presets: https://starship.rs/presets/

### Modern CLI Tools

- **bat:** https://github.com/sharkdp/bat (Better cat)
- **eza:** https://github.com/eza-community/eza (Modern ls)
- **ripgrep:** https://github.com/BurntSushi/ripgrep (Fast grep)
- **fd:** https://github.com/sharkdp/fd (Fast find)
- **fzf:** https://github.com/junegunn/fzf (Fuzzy finder)
- **btop:** https://github.com/aristocratos/btop (Resource monitor)

---

## Development Tools Resources

### Python

**UV**

- GitHub: https://github.com/astral-sh/uv
- Docs: https://docs.astral.sh/uv/

**Micromamba**

- GitHub: https://github.com/mamba-org/mamba
- Docs: https://mamba.readthedocs.io/

**Ruff**

- GitHub: https://github.com/astral-sh/ruff
- Docs: https://docs.astral.sh/ruff/

### Git

**Git Documentation**

- Website: https://git-scm.com/
- Book: https://git-scm.com/book/en/v2
- Reference: https://git-scm.com/docs

**GitHub CLI**

- GitHub: https://github.com/cli/cli
- Manual: https://cli.github.com/manual/

### VS Code

**VS Code**

- Website: https://code.visualstudio.com/
- Docs: https://code.visualstudio.com/docs
- Extensions: https://marketplace.visualstudio.com/vscode

---

## Infrastructure Tools

### Docker

- Website: https://www.docker.com/
- Docs: https://docs.docker.com/
- Hub: https://hub.docker.com/

### Kubernetes

**kubectl**

- Docs: https://kubernetes.io/docs/reference/kubectl/
- Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

**k9s**

- GitHub: https://github.com/derailed/k9s

### Terraform

- Website: https://www.terraform.io/
- Docs: https://www.terraform.io/docs
- Registry: https://registry.terraform.io/

---

## Cloud Services

### AWS

**AWS CLI**

- Docs: https://docs.aws.amazon.com/cli/
- Reference: https://awscli.amazonaws.com/v2/documentation/api/latest/index.html

**AWS SSO**

- Guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html

---

## AI/ML Tools

### Ollama

- Website: https://ollama.ai/
- GitHub: https://github.com/ollama/ollama
- Models: https://ollama.ai/library

---

## Configuration Management Tools

### Alternative Tools

**Chezmoi**

- Website: https://www.chezmoi.io/
- GitHub: https://github.com/twpayne/chezmoi

**GNU Stow**

- Website: https://www.gnu.org/software/stow/
- Manual: https://www.gnu.org/software/stow/manual/

**Ansible**

- Website: https://www.ansible.com/
- Docs: https://docs.ansible.com/

---

## Useful Commands

### Quick Package Search

```bash
# Search nixpkgs
nix search nixpkgs <package>

# Browse packages online
open https://search.nixos.org/packages

# Search Homebrew
brew search <package>
```

### Quick Documentation

```bash
# Nix manual
nix --help
man nix

# Git manual
man git
git help <command>

# Tool documentation
<tool> --help
```

---

# Part 4: Changelog

## Version 2.0 - 2025-01-02

### Major Changes

**Documentation Overhaul**

- Complete documentation restructure with 40+ comprehensive guides
- New sections: Getting Started, Guides, Architecture, Recipes, Appendix
- Cross-referenced documentation with practical examples
- Added FAQ, Glossary, and Resources

**Git Workflow Consolidation**

- Moved all git aliases to unified `g` prefix pattern
- Removed duplicate shell git aliases (gs, gd, etc.)
- Single source of truth: 60+ git aliases in git.nix
- Fixed config shortcuts (gitconf, awsconf, etc.)

**Python Auto-Activation**

- Automatic virtual environment activation on cd
- Supports UV projects (pyproject.toml + .venv)
- Supports standard venvs (.venv/, venv/, env/)
- Visual feedback when activating/deactivating

**AI/ML Development**

- Added Ollama for local LLM execution
- Integrated AI/ML tools and packages
- LLM shortcuts (llama3, codellama, etc.)
- AI development aliases

### Added

**New Tools**

- UV (ultra-fast Python package manager)
- Ollama (local LLM execution)
- Modern CLI tools (bat, eza, ripgrep, fd, dust, duf, btop)
- Claude Code via Homebrew

**New Aliases**

- Python development: uv-new, uv-add, base, test, lint, format
- System shortcuts: update-all, update-nix, update-brew
- Modern tools: ll (eza), cat (bat)
- AWS functions: awslogin, awswho (work Mac)

**New Documentation**

- 16 reference documents (all tools and systems)
- 4 getting-started guides
- 6 user guides
- 5 architecture documents
- 5 practical recipes
- 4 appendix documents

### Changed

**Git Configuration**

- All git commands now use `g` prefix
- Example: `g s` instead of `gs`
- Access to full 60+ git alias suite
- Config shortcuts now use `code` directly

**Shell Configuration**

- Cleaned up duplicate git aliases
- Better organization with clear sections
- Improved comments and documentation
- Machine mode display (home vs work)

**Prompt**

- Changed MACHINE_MODE display from emoji to text
- "🏠 PERSONAL" → "home"
- "💼 WORK" → "work"
- Cleaner, more professional appearance

### Fixed

- Config shortcuts not working (gitconf, awsconf, etc.)
- Duplicate git aliases between zsh.nix and git.nix
- Zsh plugin loading issues
- Python virtual environment detection
- Starship prompt configuration location documented correctly

---

## Version 1.0 - 2024-12-15

### Initial Release

**Core System**

- Nix-Darwin configuration for macOS
- Home Manager integration
- Multi-machine support (personal and work Macs)
- Mixin architecture for machine-specific configuration

**Package Management**

- Nix for CLI tools
- Homebrew integration for GUI apps
- Mac App Store integration
- Font management (Nerd Fonts)

**Shell Configuration**

- Zsh as default shell
- Oh-My-Zsh integration
- Starship prompt
- 100+ shell aliases
- fzf for fuzzy finding

**Git Configuration**

- Comprehensive git aliases (60+)
- Git user configuration
- Default branch and settings
- SSH and GPG support

**Python Development**

- Python 3.11 default
- Micromamba for conda environments
- Virtual environment support
- Jupyter Lab integration

**Development Tools**

- VS Code configuration
- Docker support
- Node.js setup
- AWS CLI with SSO

**System Settings**

- macOS defaults (Dock, Finder, etc.)
- Security settings
- Keyboard and trackpad configuration
- Screen capture settings

**Documentation**

- README with setup instructions
- CLAUDE.md for AI assistant
- Basic usage documentation

---

## Pre-release - 2024-11-01

### Initial Setup

- Repository structure created
- Basic Nix-Darwin configuration
- Flake-based setup
- Personal Mac configuration

---

## Migration Guides

### From 1.0 to 2.0

**Breaking Changes:**

- Git aliases now require `g` prefix
- Old shell git aliases removed (gs, gd, ga, etc.)
- Config shortcuts changed from `$EDITOR` to `code`

**Migration Steps:**

1. **Update git aliases:**

   ```bash
   # Old:
   gs
   gd
   ga

   # New:
   g s
   g d
   g aa
   ```

2. **Pull latest changes:**

   ```bash
   cd ~/nix-darwin
   g pl
   ```

3. **Rebuild:**

   ```bash
   nix-rebuild
   exec zsh
   ```

4. **Test:**
   ```bash
   g s         # Test git
   gitconf     # Test config shortcuts
   echo $MACHINE_MODE  # Should show "home" or "work"
   ```

**Benefits of Upgrading:**

- Access to all 60+ git aliases
- Better documentation (40+ guides)
- Python auto-activation
- Modern CLI tools
- AI/ML development support

---

## Version History Summary

| Version     | Date       | Highlights                                                                       |
| ----------- | ---------- | -------------------------------------------------------------------------------- |
| **2.0**     | 2025-01-02 | Documentation overhaul, git consolidation, Python auto-activation, AI/ML support |
| **1.0**     | 2024-12-15 | Initial stable release with Nix-Darwin, Home Manager, multi-machine support      |
| Pre-release | 2024-11-01 | Initial repository structure                                                     |

---

## Related Documentation

- **[Installation Guide](../guides/installation.md)** - Fresh setup
- **[Migration Guide](../guides/installation.md)** - Moving from other systems
- **[Troubleshooting](../guides/troubleshooting.md)** - Common issues
- **[Architecture Overview](../architecture/overview.md)** - System design

---

**Comprehensive reference for all your nix-darwin questions, terms, resources, and version history!**
