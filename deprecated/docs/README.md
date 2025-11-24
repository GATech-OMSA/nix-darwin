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

---

## For Current Documentation

Please refer to:
- **Main docs:** `docs/` directory
- **User guides:** `docs/installation.md`, `docs/troubleshooting.md`, `docs/AWS-AND-SECRETS-WORKFLOW.md`
- **AI assistant guides:** `claudedocs/guides/`
- **Architecture decisions:** `docs/architecture/decisions/` (ADRs)

---

**Last Updated:** November 2025
