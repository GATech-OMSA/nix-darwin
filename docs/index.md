# Nix Darwin Documentation

**Complete guide to your declarative macOS system configuration**

---

## Start Here

**New to this setup?**

1. **[START-HERE.md](START-HERE.md)** - 📍 **Main entry point** - Read this first!
2. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - ⚡ **One-page cheat sheet** - Print and keep visible
3. **[QUICK-START-CHECKLIST.md](QUICK-START-CHECKLIST.md)** - ✅ **Day 1 checklist** - 30-45 minute setup

These documents are your primary resources for getting started and daily use.

---

## User Guides

Complete guides for common workflows:

- **[Installation Guide](guides/installation.md)** - Complete setup (consolidates installation, quickstart, first steps, migration, new machine setup)
- **[Usage Guide](guides/usage.md)** - Daily usage, adding packages/aliases, customization, updates (consolidates daily usage, configuration, updates, recipes)
- **[Shell Customization](guides/shell-customization.md)** - Customize Zsh, aliases, functions, prompt (Starship), helper functions
- **[System Health Check](guides/system-health.md)** - Comprehensive validation of system state with scoring and diagnostics
- **[Security Configuration](guides/security.md)** - Security best practices, SOPS encryption, file permissions, git hooks, incident response
- **[Testing Guide](guides/testing.md)** - Test framework, test categories, running tests, writing tests, CI/CD integration
- **[Multi-User Setup](guides/multi-user-setup.md)** - Using this config with different usernames, sharing with team/family
- **[Multi-Machine Setup](guides/multi-machine-setup.md)** - Managing multiple machines with one config, mixin system, syncing changes
- **[Backup & Recovery](guides/backup-and-recovery.md)** - Backup strategy, disaster recovery, pre-rebuild safety, rollback
- **[Secrets Management](guides/secrets.md)** - Managing encrypted secrets with sops-nix, adding/updating/rotating secrets
- **[Learning Modern CLI](guides/learning.md)** - Learn modern CLI tools (z, bat, rg, fd, fzf), multi-machine setup
- **[Troubleshooting](guides/troubleshooting.md)** - Common issues, solutions, emergency recovery

---

## Complete Reference

Comprehensive documentation for all tools and systems:

### System
- **[System Reference](reference/system.md)** - Nix-Darwin, Home Manager, system commands, helper functions

### Shell & Git
- **[Shell Reference](reference/shell.md)** - Zsh (100+ aliases), Git (60+ aliases), Starship prompt

### Languages
- **[Languages Reference](reference/languages.md)** - Python (UV, Micromamba, auto-activation), Node.js

### Infrastructure
- **[Infrastructure Reference](reference/infrastructure.md)** - AWS (CLI, SSO), Docker, Kubernetes, Terraform
- **[AWS Accounts Schema](reference/aws-accounts-schema.md)** - Complete `accounts.json` schema documentation

### Tools
- **[Tools Reference](reference/tools.md)** - VS Code, AI/ML (Ollama), Modern CLI tools (bat, eza, rg, fd), macOS settings

---

## Architecture

Understanding how the system works:

- **[Architecture Overview](architecture/overview.md)** - System architecture, mixin system, how it all fits together
- **[Architecture Reference](architecture/reference.md)** - Complete file structure guide + configuration best practices
- **[Architecture Decision Records](architecture/decisions/)** - Key architectural decisions with context and rationale

---

## Appendix

All-in-one comprehensive reference:

- **[FAQ & Reference](appendix/faq.md)** - FAQ (100+ questions), Glossary (all terms), Resources (external links), Changelog (version history)

---

## Quick Navigation

### I want to...

**Learn the system:**
- New user → [START-HERE.md](START-HERE.md)
- Day 1 setup → [QUICK-START-CHECKLIST.md](QUICK-START-CHECKLIST.md)
- Quick commands → [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Understand architecture → [Architecture Overview](architecture/overview.md)

**Configure things:**
- Add packages → [Usage Guide - Adding Packages](guides/usage.md#adding-packages)
- Add aliases → [Usage Guide - Adding Aliases](guides/usage.md#adding-aliases)
- Customize shell → [Shell Customization](guides/shell-customization.md)
- Manage secrets → [Secrets Guide](guides/secrets.md)
- Set up multiple machines → [Multi-Machine Setup](guides/multi-machine-setup.md)

**Solve problems:**
- Something broke → [Troubleshooting](guides/troubleshooting.md)
- Run tests → [Testing Guide](guides/testing.md)
- Have questions → [FAQ](appendix/faq.md)
- Need rollback → [Backup & Recovery](guides/backup-and-recovery.md)

**Reference lookup:**
- Shell commands → [Shell Reference](reference/shell.md)
- Python setup → [Languages Reference - Python](reference/languages.md#python)
- Git aliases → [Shell Reference - Git](reference/shell.md#git)
- AWS commands → [Infrastructure Reference - AWS](reference/infrastructure.md#aws)
- AWS accounts schema → [AWS Accounts Schema](reference/aws-accounts-schema.md)

---

## Documentation Structure

This documentation is organized as:

**Entry Points (3 files):**
- START-HERE.md - Comprehensive introduction
- QUICK-REFERENCE.md - Quick command reference
- QUICK-START-CHECKLIST.md - Day 1 setup checklist

**Guides (10 files):**
- Practical, task-oriented documentation
- Complete workflows and procedures

**Reference (5 files):**
- Exhaustive documentation of all features
- Organized by topic

**Architecture (2 files):**
- System design and file structure
- Best practices and patterns

**Appendix (1 file):**
- FAQ, Glossary, Resources, Changelog
- All-in-one reference

**Total: 21 well-organized files** (down from 42 original files)

---

## Quick Links

**Most Common Tasks:**
- Rebuild system: `nix-rebuild`
- Update everything: `update-all`
- Rollback: `nix-rollback`
- Edit configuration: `nixconf`
- Check secrets: `secrets-status`
- Backup data: `backup-user-data`

---

## Need Help?

1. **Start with:** [START-HERE.md](START-HERE.md)
2. **Check:** [FAQ](appendix/faq.md)
3. **Troubleshoot:** [Troubleshooting Guide](guides/troubleshooting.md)
4. **Ask AI:** See [CLAUDE.md](../CLAUDE.md) for assistant guidance

---

**Everything you need to master your declarative macOS configuration!**
