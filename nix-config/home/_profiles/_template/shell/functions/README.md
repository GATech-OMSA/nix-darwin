# Shell Function Modules

Extracted shell functions for maintainability. All six files are **lazy-loaded**
by `zsh.nix`: the file is written to the Nix store (`pkgs.writeText`) and sourced
on first use via a thin wrapper, so its body parses only when a function in it is
actually called — not at shell startup. This defers ~1040 lines of rarely-used
function parsing off the interactive-init path.

## Files

| File | Description | Lines |
|------|-------------|-------|
| `core.zsh` | Utility functions (mkcd, find-alias, backup, sysinfo, warn/confirm/risky/critical, note, …) | 202 |
| `python.zsh` | Python/uv helpers (uv-new, uv-venv, activate, pyenv-info) | 66 |
| `aws-completion.zsh` | `_aws_helper_completion` — zsh tab-completion for `awsuse`/`awslogin` (reads `~/.aws/accounts.json` via jq) | 91 |
| `cleanup.zsh` | Tiered cleanup system (safe→quick→standard→dev→aggressive) | 373 |
| `update.zsh` | System update functions (nix, brew, mamba, vscode, mas) | 272 |
| `credentials-mgmt.zsh` | Workspace backup/restore/sync | 33 |

## Lazy-load pattern (see `zsh.nix` for the live copies)

Each module gets a `let` binding + an init-time loader stub + one wrapper per
public function:

```nix
# in the let block
lazyCore = pkgs.writeText "core.zsh" (builtins.readFile ./functions/core.zsh);

# in initContent
__lazy_load_core() {
  unfunction mkcd find-alias ... __lazy_load_core 2>/dev/null
  source ${lazyCore}
}
mkcd() { __lazy_load_core; mkcd "$@"; }
find-alias() { __lazy_load_core; find-alias "$@"; }
# ...one wrapper per public function
```

First call of any wrapper sources the file (which redefines the names with the
real implementations) and forwards the arguments. Subsequent calls go straight
to the real function.

`aws-completion.zsh` is a special case: `compdef _aws_helper_completion awsuse
awslogin` runs inline at init (completion must be registered up front), while the
88-line `_aws_helper_completion` body is stubbed to source itself on first tab.

## Notes

- Files use `$HOME` / `~/...` (shell-native), not `${nixDarwinDir}`.
- `confirm` (from `core.zsh`) is called by `cleanup.zsh` functions at runtime —
  nested lazy-loading handles this: the `confirm` wrapper triggers `core.zsh`'s
  load on first use. No init-time dependency.
- Sourcing is a zsh builtin (no fork); these files define only functions (+ the
  one `compdef` in `aws-completion.zsh`), so lazy-loading is SIGCHLD-safe.