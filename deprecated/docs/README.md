# Deprecated Documentation

This directory contains documentation that has been superseded by newer, more comprehensive guides.

## Why These Docs Are Here

These files are kept for historical reference but should not be used as the primary source of information.

---

## Deprecated Files

### quick-reference/QUICK-REFERENCE.md
- **Deprecated:** November 2025
- **Superseded by:** `docs/AWS-AND-SECRETS-WORKFLOW.md`
- **Reason:** AWS-AND-SECRETS-WORKFLOW.md (766 lines) provides comprehensive coverage of all topics that were in QUICK-REFERENCE.md (114 lines), plus much more detail including:
  - Complete AWS SSO workflow for work profile
  - Complete IAM workflow for personal profile
  - Hot reload mechanisms (including new reload-secrets)
  - Secrets management with SOPS
  - Configuration matrix (Nix vs local)
  - Troubleshooting guide
- **Use instead:** See `docs/AWS-AND-SECRETS-WORKFLOW.md` for all secrets, environment, and AWS configuration

### learning/
- **Deprecated:** November 2025
- **Reason:** Personal learning notes (1,479 lines) that should not be in official repository documentation
- **Status:** Also added to `.gitignore` to prevent future personal notes from being committed
- **Note:** These notes are preserved here for historical reference but won't be updated

### project-workflow/project-workflow.md
- **Deprecated:** November 2025
- **Superseded by:** `claudedocs/guides/DEVELOPMENT-WORKFLOW.md`
- **Reason:** DEVELOPMENT-WORKFLOW.md (653 lines) is a comprehensive superset that includes all concepts from project-workflow.md (236 lines) plus:
  - Backlog grooming process
  - Context switching procedures
  - Detailed checklists for each workflow phase
  - Anti-patterns to avoid
  - Best practices
- **Use instead:** See `claudedocs/guides/DEVELOPMENT-WORKFLOW.md` for complete project-based task management workflow

### clean-setup-steps/CLEAN-SETUP-STEPS.md
- **Deprecated:** November 2025
- **Superseded by:** `docs/installation.md`
- **Reason:** This was a transitional work document created during the username-agnostic refactoring. The production-ready installation guide (installation.md, 859 lines) now covers the complete v2.0.0 three-script workflow (bootstrap, configure, activate)
- **Historical Value:** Shows the thinking and design decisions during the username-agnostic machine ID refactoring
- **Use instead:** See `docs/installation.md` for current installation instructions

### doc-consolidation-plan.md
- **Deprecated:** December 2025
- **Reason:** Process artifact describing the plan for the November 2025 documentation cleanup. The work is complete.
- **Status:** Archived for historical record of the consolidation strategy.

### docs-review-nov-2025.md
- **Deprecated:** December 2025
- **Reason:** Process artifact containing the detailed inventory and audit results of the November 2025 documentation review.
- **Status:** Archived for historical record.

---

## For Current Documentation

Please refer to:
- **Main docs:** `docs/` directory
- **User guides:** `docs/installation.md`, `docs/troubleshooting.md`, `docs/AWS-AND-SECRETS-WORKFLOW.md`
- **AI assistant guides:** `claudedocs/guides/`
- **Architecture decisions:** `docs/architecture/decisions/` (ADRs)

---

**Last Updated:** November 2025
