# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) documenting significant architectural decisions made in the nix-darwin configuration.

## What is an ADR?

An Architecture Decision Record captures an important architectural decision along with its context and consequences. ADRs help maintain institutional knowledge and explain why certain approaches were chosen.

## ADR Format

Each ADR follows this structure:

- **Title**: Brief description of the decision
- **Status**: Proposed | Accepted | Deprecated | Superseded
- **Date**: When the decision was made
- **Context**: What forces are at play (technical, political, social, project)
- **Decision**: What we decided to do
- **Consequences**: What becomes easier or harder as a result
- **Alternatives**: What other options were considered

## Index of ADRs

### Security & Credentials

- **[ADR-001: Machine Detection Strategy](ADR-001-machine-detection-strategy.md)** - Hostname-based machine type detection
- **[ADR-002: Secret Management Consolidation](ADR-002-secret-management-consolidation.md)** - Unified secrets in hosts/*/secrets.yaml
- **[ADR-003: Git Hooks Enforcement](ADR-003-git-hooks-enforcement.md)** - Pre-commit/pre-push security validation

### Configuration Architecture

- **[ADR-004: User vs Machine Config Separation](ADR-004-user-vs-machine-config-separation.md)** - Mixin system for machine-specific configuration
- **[ADR-005: Health Check Architecture](ADR-005-health-check-architecture.md)** - System validation and diagnostic tooling

### Quality & Testing

- **[ADR-006: Test Framework Selection](ADR-006-test-framework-selection.md)** - Nix-based testing with bats integration
- **[ADR-007: Warning System Design](ADR-007-warning-system-design.md)** - Non-blocking warnings vs errors
- **[ADR-008: Permission Audit Automation](ADR-008-permission-audit-automation.md)** - Automated credential permission validation

## Creating New ADRs

When making significant architectural decisions:

1. Copy the template structure from an existing ADR
2. Number sequentially (ADR-009, ADR-010, etc.)
3. Use descriptive kebab-case filenames
4. Update this README index
5. Reference ADRs in relevant documentation

## ADR Lifecycle

- **Proposed**: Decision under consideration
- **Accepted**: Decision approved and implemented
- **Deprecated**: No longer relevant but kept for historical context
- **Superseded**: Replaced by a newer ADR (reference the new ADR number)

## References

- [ADR Documentation](https://adr.github.io/)
- [Architecture Overview](../overview.md)
- [Architecture Reference](../reference.md)
