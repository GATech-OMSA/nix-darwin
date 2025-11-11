# ADR-001: Machine Detection Strategy

**Status**: Accepted
**Date**: 2024-11-07
**Author**: System Architecture

## Context

The nix-darwin configuration supports multiple machines (personal and work) with different requirements:

- Different AWS configurations (personal vs work accounts)
- Different Git identities (personal vs work email)
- Different package sets (work-specific tools)
- Different secrets management (separate SOPS keys)

We needed a reliable, simple mechanism to determine machine type and apply appropriate configuration.

### Requirements

1. **Deterministic**: Same machine always gets same configuration
2. **Simple**: Easy to understand and debug
3. **Maintainable**: Adding new machines should be straightforward
4. **Fail-safe**: Clear error messages for unconfigured machines
5. **Zero configuration**: No manual environment variables or state files

### Technical Constraints

- Nix evaluation must be pure (no network calls, no mutable state)
- Configuration must work across rebuilds and rollbacks
- Must work in installation scenario (before any config is applied)

## Decision

**Use hostname-based detection with explicit flake outputs.**

Implementation:

```nix
# flake.nix
{
  darwinConfigurations = {
    "mbp-jimmy" = nix-darwin.lib.darwinSystem {
      # personal configuration
    };
    "mbp-work" = nix-darwin.lib.darwinSystem {
      # work configuration
    };
  };
}
```

Each host configuration:
1. Passes `hostname` as a module parameter
2. Uses `myLib.selectByMachine` for conditional logic
3. Imports appropriate mixins (`personal.nix` or `work.nix`)

### Helper Functions

```nix
# lib/machine.nix
selectByMachine = hostname: values:
  if hostname == "mbp-jimmy" then values.personal
  else if hostname == "mbp-work" then values.work
  else throw "Unknown hostname: ${hostname}";

isWork = hostname: hostname == "mbp-work";
isPersonal = hostname: hostname == "mbp-jimmy";
```

## Consequences

### Positive

✅ **Simple and reliable**: Hostname is stable and system-provided
✅ **Explicit configuration**: Each machine has clear flake output
✅ **Type-safe**: Unknown hostnames fail at evaluation time
✅ **No state files**: No `.machine-mode` or environment variables to maintain
✅ **Easy debugging**: `hostname` command shows current machine type
✅ **Scalable**: Adding new machines is just a new flake output
✅ **Rollback-safe**: Works correctly across nix generations

### Negative

⚠️ **Hostname changes break system**: Renaming machine requires flake update
⚠️ **Manual flake edits**: Each new machine requires editing flake.nix
⚠️ **No runtime override**: Cannot test "work mode" on personal machine

### Mitigation

- Document hostname requirements in installation guide
- Provide clear error messages for unknown hostnames
- Keep hostname mapping centralized in flake.nix
- Use helper functions to abstract hostname checks

## Alternatives Considered

### Alternative 1: Environment Variable

```bash
export MACHINE_MODE=work
```

**Rejected because**:
- ❌ Requires manual setup before first rebuild
- ❌ Can be accidentally unset or changed
- ❌ Not pure (Nix evaluation can't read environment)
- ❌ Rollback issues (env var vs nix generation mismatch)

### Alternative 2: State File

```bash
echo "work" > ~/.machine-mode
```

**Rejected because**:
- ❌ Requires file creation before installation
- ❌ Can be deleted or corrupted
- ❌ Not pure (Nix can't read arbitrary files during evaluation)
- ❌ Additional failure mode

### Alternative 3: Git Branch Strategy

```bash
git checkout work-machine
```

**Rejected because**:
- ❌ Complicates version control
- ❌ Merge conflicts between branches
- ❌ Harder to share common updates
- ❌ Confusing mental model

### Alternative 4: Multiple Repositories

Separate repos for personal/work.

**Rejected because**:
- ❌ Duplicate configuration
- ❌ Harder to share improvements
- ❌ Separate update cycles
- ❌ More maintenance burden

### Alternative 5: Network-based Detection

Detect machine type by network (home network vs work VPN).

**Rejected because**:
- ❌ Not pure (Nix can't make network calls)
- ❌ Unreliable (network can change)
- ❌ Doesn't work offline
- ❌ Slow evaluation

## Implementation Notes

### Adding a New Machine

1. Choose a unique hostname (e.g., `mbp-travel`)
2. Add flake output in `flake.nix`:
   ```nix
   "mbp-travel" = nix-darwin.lib.darwinSystem { ... };
   ```
3. Update `lib/machine.nix` helper functions if needed
4. Create host-specific directory: `hosts/mbp-travel/`
5. Install: `sudo nix run nix-darwin -- switch --flake .#mbp-travel`

### Testing Machine-Specific Behavior

Use `selectByMachine` in interactive nix repl:

```bash
nix repl
:lf .
myLib.selectByMachine "mbp-work" { personal = "personal-value"; work = "work-value"; }
# => "work-value"
```

## References

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [nix-darwin Multiple Hosts](https://github.com/LnL7/nix-darwin/wiki/Multiple-Hosts)
- [lib/machine-detection.nix](../../../lib/machine-detection.nix) - Implementation
- [Architecture Overview - Mixin System](../overview.md#mixin-system)
- [Installation Guide - Machine Selection](../../guides/installation.md)

## Revision History

- **2024-11-07**: Initial decision - hostname-based detection
