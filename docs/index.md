# Nix Darwin Documentation

**Complete guide to your declarative macOS system configuration**

---

## Start Here

**New to this setup?**

1. **[START-HERE.md](START-HERE.md)** - 📍 **Main entry point** - Read this first!
2. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - ⚡ **One-page cheat sheet** - Print and keep visible

These two documents are your primary resources for daily use.

---

## User Guides

Complete guides for common workflows:

- **[Installation Guide](guides/installation.md)** - Complete setup (consolidates installation, quickstart, first steps, migration, new machine setup)
- **[Usage Guide](guides/usage.md)** - Daily usage, adding packages/aliases, customization, updates (consolidates daily usage, configuration, updates, recipes)
- **[System Health Check](guides/system-health.md)** - Comprehensive validation of system state with scoring and diagnostics
- **[Security Configuration](guides/security.md)** - Security best practices, SOPS encryption, file permissions, git hooks, incident response
- **[Multi-User Setup](guides/multi-user-setup.md)** - Using this config with different usernames, sharing with team/family
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

### Tools
- **[Tools Reference](reference/tools.md)** - VS Code, AI/ML (Ollama), Modern CLI tools (bat, eza, rg, fd), macOS settings

---

## Architecture

Understanding how the system works:

- **[Architecture Overview](architecture/overview.md)** - System architecture, mixin system, how it all fits together
- **[Architecture Reference](architecture/reference.md)** - Complete file structure guide + configuration best practices

---

## Appendix

All-in-one comprehensive reference:

- **[FAQ & Reference](appendix/faq.md)** - FAQ (100+ questions), Glossary (all terms), Resources (external links), Changelog (version history)

---

## Quick Navigation

### I want to...

**Learn the system:**
- New user → [START-HERE.md](START-HERE.md)
- Quick commands → [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Understand architecture → [Architecture Overview](architecture/overview.md)

**Configure things:**
- Add packages → [Usage Guide - Adding Packages](guides/usage.md#adding-packages)
- Add aliases → [Usage Guide - Adding Aliases](guides/usage.md#adding-aliases)
- Manage secrets → [Secrets Guide](guides/secrets.md)

**Solve problems:**
- Something broke → [Troubleshooting](guides/troubleshooting.md)
- Have questions → [FAQ](appendix/faq.md)
- Need rollback → [Backup & Recovery](guides/backup-and-recovery.md)

**Reference lookup:**
- Shell commands → [Shell Reference](reference/shell.md)
- Python setup → [Languages Reference - Python](reference/languages.md#python)
- Git aliases → [Shell Reference - Git](reference/shell.md#git)
- AWS commands → [Infrastructure Reference - AWS](reference/infrastructure.md#aws)

---

## Documentation Structure

This documentation is organized as:

**Entry Points (2 files):**
- START-HERE.md - Comprehensive introduction
- QUICK-REFERENCE.md - Quick command reference

**Guides (7 files):**
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

**Total: 17 well-organized files** (down from 42 original files)

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
