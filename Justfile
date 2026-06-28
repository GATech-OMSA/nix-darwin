# Justfile for Nix-Darwin Configuration
#
# Usage:
#   just <command> [args]
#
# Run 'just' to see list of commands

set shell := ["bash", "-c"]

# List all available commands
default:
    @just --list

# ============================================================================
# SYSTEM MANAGEMENT
# ============================================================================

# Build and switch to the configuration (uses smart rebuild with pre-flight checks)
switch:
    ./scripts/maintenance/rebuild.sh

# Build only (don't switch) — validates the config compiles
build:
    #!/usr/bin/env bash
    MACHINE_ID=$(nix eval --raw --file config/machine-config.nix machineId 2>/dev/null || echo "default")
    echo "Building system for $MACHINE_ID (no switch)..."
    nix build ".#darwinConfigurations.$MACHINE_ID.system" --impure

# Rollback to previous generation
rollback:
    @echo "⏪ Rolling back..."
    ./scripts/maintenance/rebuild.sh --rollback

# Show system health
health:
    @echo "🏥 Checking system health..."
    ./scripts/maintenance/health-check.sh

# ============================================================================
# UPDATES
# ============================================================================

# Update everything (Nix + Homebrew)
update:
    @echo "🔄 Updating everything..."
    @nix flake update
    @if command -v brew >/dev/null; then brew update && brew upgrade; fi
    @echo "✅ Update complete. Run 'just switch' to apply Nix changes."

# Update only Nix inputs
update-nix:
    @echo "❄️  Updating Nix inputs..."
    nix flake update

# ============================================================================
# MAINTENANCE
# ============================================================================

# Clean up garbage (old generations)
cleanup:
    @echo "🧹 Cleaning up garbage..."
    ./scripts/maintenance/system-cleanup.sh

# Audit permissions
audit:
    @echo "🔍 Auditing permissions..."
    ./scripts/validation/audit-permissions.sh

# ============================================================================
# SECRETS
# ============================================================================

# Edit secrets for the current machine
secrets-edit:
    @echo "🔐 Editing secrets..."
    ./scripts/secrets/edit-secrets.sh

# View secrets (decrypted)
secrets-view:
    @echo "👀 Viewing secrets..."
    ./scripts/secrets/view-secrets.sh

# Rescan for new secrets
secrets-rescan:
    @echo "📡 Rescanning for secrets..."
    ./scripts/secrets/rescan-secrets.sh

# Audit secrets
secrets-audit:
    @echo "🛡️  Auditing secrets..."
    ./scripts/secrets/audit-secrets.sh

# ============================================================================
# TESTING & VALIDATION
# ============================================================================

# Run all tests
test:
    @echo "🧪 Running all tests..."
    ./tests/run-all-tests.sh

# Run CI tests (quick, strict)
test-ci:
    @echo "🤖 Running CI tests..."
    ./tests/run-all-tests.sh --ci

# Check flake syntax and structure
check:
    @echo "✅ Checking flake..."
    nix flake check

# Benchmark zsh interactive startup (TTY-driven). Reports p50/p95 ms.
bench-shell *ARGS:
    @./scripts/maintenance/bench-shell.sh {{ARGS}}

# Check shell startup latency against the committed budget (warn-only).
perf-check *ARGS:
    @./scripts/maintenance/check-shell-perf.sh {{ARGS}}

# Re-baseline the shell startup budget from a fresh measurement on THIS machine.
perf-calibrate:
    @./scripts/maintenance/check-shell-perf.sh --calibrate

# Scan the live system closure for known CVEs (vulnix) + brew cask drift.
# Prefers the packaged `security-scan` (vulnix bundled); falls back to the repo
# script (which uses `nix run nixpkgs#vulnix` when vulnix isn't on PATH).
# if/else (not `A && B || C`) so a non-zero scan exit isn't mistaken for
# "tool absent" and re-run via the fallback.
security-scan *ARGS:
    @if command -v security-scan >/dev/null 2>&1; then security-scan {{ARGS}}; else ./scripts/validation/scan-vulnerabilities.sh {{ARGS}}; fi

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Generate documentation (if available)
docs:
    @echo "📚 Generating documentation..."
    # Placeholder for future doc generation
    @echo "See docs/README.md"

# Regenerate the installed-apps section of docs/app-recommendations.md
# from nix-config/modules/darwin/homebrew.nix.
docs-apps:
    ./scripts/docs/sync-app-recommendations.sh

# Verify docs/app-recommendations.md is in sync with homebrew.nix.
# Used by the pre-commit hook to detect drift.
docs-apps-check:
    ./scripts/docs/sync-app-recommendations.sh --check
