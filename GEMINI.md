# GEMINI.md - AI Assistant Context for nix-darwin

## Project Overview

This is a **nix-darwin** configuration repository for macOS. It uses **Nix Flakes** to declaratively manage the system, including:

*   **System Settings:** macOS defaults (Dock, Finder, etc.) via `nix-darwin`.
*   **User Environment:** Shell (Zsh), Git, editors (VS Code), and CLI tools via **Home Manager**.
*   **Secrets:** Encrypted management via **sops-nix**.
*   **Profiles:** Logic to switch between `personal`, `work`, and `minimal` configurations.

**Core Command:** `darwin-rebuild switch --flake .` (or alias `nix-rebuild`)

---

## Architecture

### Key Directories

*   `flake.nix`: Entry point. Defines inputs (nixpkgs, home-manager) and outputs.
*   `config/`: **Gitignored**. Contains local state:
    *   `machine-config.nix`: Defines `machineId` and `profileName`.
    *   `user-config.nix`: Defines `username` and `email`.
*   `nix-config/`: Main configuration source.
    *   `hosts/`: Machine-specific settings (secrets, specific hardware tweaks).
    *   `home/_profiles/`: Profile logic (`personal`, `work`, `minimal`).
    *   `home/_template/`: Shared base configuration for all users.
    *   `modules/`: System-level modules (shared and Darwin-specific).
    *   `lib/`: Custom helper functions (`myLib`).
*   `scripts/`: Utility scripts for maintenance, secrets, and setup.

### Profile System

Configuration adapts based on `profileName` in `config/machine-config.nix`:
*   **Personal:** Full suite of personal tools, personal Git identity.
*   **Work:** Work-specific tools, work Git identity, potential restrictions.
*   **Minimal:** Barebones setup for troubleshooting.

---

## Common Tasks & Workflows

### 1. Rebuilding the System

**Always rebuild** after changing `.nix` files to apply changes.

```bash
just switch
# OR
darwin-rebuild switch --flake .
```

### 2. Adding Packages

*   **System-wide (GUI apps, services):** Edit `nix-config/modules/shared/packages.nix` or `nix-config/modules/darwin/homebrew.nix` (for Casks).
*   **User-specific (CLI tools):** Edit `nix-config/home/_profiles/_template/default.nix` (or specific profile/module files).

### 3. Managing Secrets

Secrets are encrypted with `sops`. **Never edit `secrets.yaml` manually without sops.**

*   **Edit Secrets:** `just secrets-edit` (or `secrets-edit`).
*   **Add New Secret:** Add to `secrets.yaml`, then reference in `nix-config/hosts/<host>/secrets-*.nix`.
*   **Verification:** `secrets-status` to check encryption.

### 4. Updates

*   `just update`: Update Flake inputs (nixpkgs) and Homebrew.
*   `just update-nix`: Update only Nix inputs.
*   `update-dev`: Quick update for development environment.

### 5. Shell & Aliases

*   **Shell Config:** Managed in `nix-config/home/_profiles/_template/shell/zsh.nix`.
*   **Aliases:** Add to `shellAliases` set in `zsh.nix`.

### 6. Validation & Testing

*   `just test`: Run integration tests.
*   `just health`: Run health checks.
*   `just check`: Verify flake syntax.
*   **Flake Apps:** You can also run scripts directly via Nix:
    *   `nix run .#health`
    *   `nix run .#audit`
    *   `nix run .#test`


## Development Guidelines

1.  **Conventions:** Match existing coding style. Use `let ... in` blocks for local variables.
2.  **Helpers:** Utilize `myLib` functions (e.g., `myLib.isWork`) instead of raw logic where possible.
3.  **Safety:**
    *   **Never** commit `secrets/secrets.yaml` unencrypted (Git hooks should prevent this).
    *   **Never** commit files in `config/` (they are gitignored).
4.  **Testing:**
    *   Use `nix check` to verify flake outputs.
    *   Use `nix-rebuild --dry-run` (or `build`) to test without switching.

## Key Script Locations

*   `scripts/maintenance/`: Health checks (`health-check.sh`), cleanup (`cleanup.sh`).
*   `scripts/secrets/`: Secret management (`edit-secrets.sh`, `audit-secrets.sh`).
*   `scripts/setup/`: Bootstrapping and installation.

---

## Troubleshooting

*   **Rollback:** `nix-rollback` (reverts to previous generation).
*   **Debug:** `darwin-rebuild switch --flake . --show-trace` (for detailed error logs).
*   **Health:** `nix-health` (checks common issues).

---

## Documentation

**Status:** ✅ Consolidation complete (November 2025) - 17 active guides

### Essential User Documentation (docs/)
*   **Installation:** `docs/installation.md` - v2.0.0 three-script workflow (bootstrap, configure, activate)
*   **Troubleshooting:** `docs/troubleshooting.md` - Profile system issues and fixes
*   **Secrets:** `docs/secrets.md` - SOPS encryption with age
*   **AWS & Secrets:** `docs/AWS-AND-SECRETS-WORKFLOW.md` - Complete workflow with hot reload
*   **Backup & Recovery:** `docs/backup-and-recovery.md` - Disaster recovery procedures

### AWS Reference (docs/work/aws/)
*   **AWS Multi-Role:** Multi-account SSO configuration patterns
*   **AWS Quick Reference:** Daily commands and shortcuts
*   **AWS Implementation:** Technical implementation details
*   **AWS Config Status (2025-11-06):** Historical validation snapshot

### AI Development Documentation (claudedocs/guides/)
*   **Development Workflow:** Complete project management and task tracking
*   **Alias Philosophy:** Five-tier alias naming system and safety guidelines

### Deprecated Documentation (deprecated/docs/)
*   Archived guides preserved with clear deprecation notes in `deprecated/docs/README.md`
*   Includes: QUICK-REFERENCE.md, project-workflow.md, CLEAN-SETUP-STEPS.md, learning/

**Key Improvements:**
*   Reduced from 21 → 17 active guides (-19%)
*   Zero redundancies - each guide has unique purpose
*   Clear separation: User docs (docs/) vs AI docs (claudedocs/)
*   Historical preservation in deprecated/docs/

See `docs/DOCS-REVIEW.md` for complete consolidation results.
