# Shell Function Modules

Extracted shell functions for maintainability. These files can be included in zsh.nix using `builtins.readFile`.

## Files

| File | Description | Lines |
|------|-------------|-------|
| `core.zsh` | Utility functions (mkcd, backup, warn, confirm) | ~130 |
| `cleanup.zsh` | Tiered cleanup system (safe→quick→standard→dev→aggressive) | ~350 |
| `update.zsh` | System update functions (nix, brew, mamba, vscode, mas) | ~220 |
| `python.zsh` | Python/UV/micromamba helpers | ~120 |
| `credentials-mgmt.zsh` | Secrets management (edit-secrets, backup-workspace) | ~200 |

## Usage

To use these files in `zsh.nix`, add to `initContent`:

```nix
initContent = lib.mkMerge [
  # ... existing config ...

  ''
    ${builtins.readFile ./functions/core.zsh}
    ${builtins.readFile ./functions/cleanup.zsh}
    ${builtins.readFile ./functions/update.zsh}
    ${builtins.readFile ./functions/python.zsh}
    ${builtins.readFile ./functions/credentials-mgmt.zsh}
  ''
];
```

## Migration Status

**Current**: Functions are defined inline in `zsh.nix` (~3200 lines)
**Target**: Functions loaded from external files (~1000 lines total)
**Status**: Files extracted, awaiting integration

## Notes

- Files use `$HOME/nix-darwin` instead of `${nixDarwinDir}` (shell-native)
- `machineId` is read from config at runtime via `__get_machine_id()`
- `confirm` function (from core.zsh) is used by cleanup functions
