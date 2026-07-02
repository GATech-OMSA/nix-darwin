# Library Functions (`myLib`)

Reusable Nix helpers shared across this nix-darwin configuration. The flake
imports this directory once (`myLib = import ./nix-config/lib { inherit inputs; }`)
and passes it to every module via `specialArgs` / `extraSpecialArgs`.

**Source of truth:** [`default.nix`](default.nix). This README documents what
actually exists there — if the two ever disagree, trust `default.nix`.

## Quick Start

Every module receives `myLib` as an argument:

```nix
{ config, pkgs, myLib, profileName, ... }:

{
  programs.git.userEmail = myLib.selectByProfile profileName {
    personal = "personal@email.com";
    work = "work@email.com";
  };
}
```

Rule of thumb (CLAUDE.md rule 2): machine/profile-specific values go through
these helpers — never hand-rolled `if profileName == "..."` ternaries.

---

## Function Reference

### Profile helpers

#### `selectByProfile profileName { personal = X; work = Y; default = Z; }`

Select a value by active profile. `default` is optional; with no match and no
default it throws, which is the point — a new profile fails loudly at eval
instead of silently misconfiguring.

```nix
gitEmail = myLib.selectByProfile profileName {
  personal = "jimmy-jain@users.noreply.github.com";
  work = "user@example.com";
};
```

**Real usage:** `modules/darwin/system.nix:38`, `modules/darwin/security.nix:10`,
`modules/darwin/packages.nix:152`, `_template/programs/aws.nix`.

#### `isWorkProfile profileName`

Boolean shortcut for `profileName == "work"`. Use for enable/disable toggles
where `selectByProfile` would be overkill.

**Real usage:** `_template/programs/ssh.nix:73`, `_template/programs/node.nix:7`.

#### `mkProfileSessionVars { mode, awsProfile, workspace }`

Builds the standard `home.sessionVariables` block every full profile sets
(`MACHINE_MODE`, `AWS_PROFILE`, `WORKSPACE`), so the profiles only state their
deltas.

```nix
home.sessionVariables = myLib.mkProfileSessionVars {
  mode = "home"; awsProfile = "personal"; workspace = "$HOME/Dev";
};
```

**Real usage:** `_profiles/personal/default.nix:15`, `_profiles/work/default.nix:54`.

### Shell helpers

#### `mkNavigationAliases base { name = "subdir"; ... }`

Generates `cd`-alias attrsets (`name = "cd <base>/<subdir>"`). Keep alias names
bare — the `f`-prefix is reserved for Finder-open (see ALIAS-PHILOSOPHY.md).

```nix
myLib.mkNavigationAliases "$HOME/Dev" { aiml = "ai-ml"; learning = "learning"; }
```

**Real usage:** `_profiles/personal/aliases.nix:8`, `_profiles/work/aliases.nix:13`.

#### `mkLazyCompletion { name, binary, completionCommand }`

Emits a zsh self-replacing wrapper function that generates + caches a CLI's
completion on first use instead of at shell init (startup cost → first-call
cost).

**Real usage:** `_template/shell/zsh.nix:784-795` (kubectl, helm, etc.).

#### `msg.{success,error,warning,info} "text"`

Consistent status-echo snippets for Nix-generated shell code (`error` writes
to stderr). Four variants only — decorative ones were removed as dead code.

**Real usage:** `_template/programs/karabiner.nix` activation script.

### Sub-libraries

#### `aws.*` — [`aws-helpers.nix`](aws-helpers.nix)

Zsh function bodies for the AWS SSO workflow, spliced into
`_template/programs/aws.nix:85-88`:

| Attr | Provides |
|------|----------|
| `mkAwsAccountHelper` | `awsuse` / `awslogin` (SSO login + dynamic profile creation) |
| `mkAwsInfoCommands` | `awswho`, `awsp`, `awslist`, `awswhere` |
| `mkAwsSearchCommands` | `awscheck`, `awsfind`, `awsfilter` |
| `mkAwsProfileAutoRestore` | restores `AWS_PROFILE` from `~/.aws/.last_profile` at init |

#### `reload.*` — [`reload-helpers.nix`](reload-helpers.nix)

Hot-reload zsh functions (`secrets-local`, `zsh-local`, private
`__reload_secret_files`) for testing env/secrets without a rebuild. zsh.nix
splices `reload.mkAllHotReloadFunctions` (the concatenation of all of them).
Full-refresh command is `respin` (= `exec zsh`), defined in zsh.nix itself.

**Real usage:** `_template/shell/zsh.nix:980`.

#### `go.proxyVars goCfg`

Builds the Go proxy env-var set (`GOPROXY`/`GOPRIVATE`/`GOSUMDB`) from
`userConfig.proxies.go`. One value computation shared by three deliberate
emission sites — build sandbox (`modules/darwin/default.nix:92`), sops-nix
build attrs (`overlays/default.nix:55`), work runtime session vars
(`_profiles/work/default.nix:25`). Keep all three; they cover different
execution contexts.

#### `secrets` — secret target registry

Central list of local secret paths this repo manages or audits.
`secrets.pathsByType` (categorized), `secrets.paths` (flattened, deduped),
`secrets.globPatterns`, `secrets.meta`. Paths use `${HOME}` so flake outputs
stay machine-independent.

**Real usage:** exported as flake `outputs.lib.secrets`, consumed by
`scripts/validation/validate-secret-registry.sh` (`nix eval
.#lib.secrets.pathsByType --json`).

---

## Adding a New Helper

1. Add it to `default.nix` (or a new `*-helpers.nix` imported from there),
   following the existing header/section/usage-example comment style.
2. Include a usage example in a comment — files here are exemplars
   (CLAUDE.md rule 4).
3. Document it in this README with at least one real call site.
4. Verify: `nix flake check --no-build` + `just build`.
