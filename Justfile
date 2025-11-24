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

# Build and switch to the configuration
switch:
    @echo "🚀 Rebuilding system..."
    darwin-rebuild switch --flake .

# Build only (don't switch)
build:
    @echo "🏗️  Building system (no switch)..."
    darwin-rebuild build --flake .

# Rollback to previous generation
rollback:
    @echo "⏪ Rolling back..."
    ./scripts/maintenance/rollback.sh

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
    ./scripts/maintenance/cleanup.sh

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

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Generate documentation (if available)
docs:
    @echo "📚 Generating documentation..."
    # Placeholder for future doc generation
    @echo "See docs/README.md"
