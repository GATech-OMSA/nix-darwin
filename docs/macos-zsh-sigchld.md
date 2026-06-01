# macOS 15+ zsh SIGCHLD-loss Race — Diagnosis & Fix Patterns

**Symptom:** zsh hangs at the prompt after `exec zsh` (`restart` alias) on macOS 15.x+. Stack ends in `__sigsuspend`. Reproducible at ~5–100% rate depending on what runs at init.

**Root cause:** zsh's child-wait paths assume the SIGCHLD handler will fire after the child exits. On macOS 15+, the child can exit, the SIGCHLD can arrive, the handler can run and consume it, and *then* the parent enters `sigsuspend` — waiting forever for a signal that already came and went. Affects:
- `waitforpid` — used by `$(cmd)` command-substitution
- `waitjobs` — used by foreground commands with redirect (`cmd > file`)

Both paths call `signal_suspend(SIGCHLD)`. Both can lose the wakeup.

---

## Diagnosis playbook

### 1. Reproduce with `expect`

Save as `/tmp/stress-restart.exp`, runs N `exec zsh` cycles and reports which iteration hangs:

```tcl
#!/usr/bin/expect -f
set timeout 12
set N 8
spawn -noecho /bin/zsh -i
for {set i 0} {$i < $N} {incr i} {
  expect {
    "?2004h" { }
    timeout { puts "iter=$i HANG_NO_PROMPT"; exit 1 }
    eof { puts "iter=$i EOF"; exit 2 }
  }
  send "echo READY-$i; exec zsh\r"
  expect {
    -re "READY-$i" { }
    timeout { puts "iter=$i HANG_NO_READY"; exit 3 }
  }
}
expect "?2004h"; send "exit\r"; expect eof
puts "ALL $N RESTARTS COMPLETED"
```

`?2004h` is the bracketed-paste-enable terminal sequence emitted by zsh after each prompt — a reliable post-prompt sentinel.

Wrap in a loop to measure hang rate:

```bash
pass=0; fail=0
for run in $(seq 1 30); do
  out=$(/usr/bin/expect -f /tmp/stress-restart.exp 2>&1 | tail -1)
  [[ "$out" == *"COMPLETED"* ]] && pass=$((pass+1)) || fail=$((fail+1))
done
echo "$pass / 30 clean ($((pass*100/30))%)"
```

### 2. Sample a hung shell

In a separate terminal, get the C call stack of the hung pid:

```bash
/usr/bin/sample <pid> 1 100 2>/dev/null | grep -E "waitforpid|waitjobs|getoutput|prefork|run_init_scripts|source|callhookfunc|execlist|signal_suspend|sigsuspend"
```

The two diagnostic patterns:

```
run_init_scripts → source → execlist → ... → prefork → getoutput → waitforpid → signal_suspend → __sigsuspend
```
A `$()` racing during shell init.

```
run_init_scripts → source → execlist x4 → waitjobs → signal_suspend → __sigsuspend
```
A foreground `cmd > file` racing during shell init.

```
callhookfunc → execlist → ... → prefork → getoutput → waitforpid → signal_suspend
```
A `$()` racing inside a precmd/preexec/chpwd hook (fires before first prompt).

### 3. Identify the racy site

```bash
/usr/sbin/lsof -p <pid> | grep -E "PIPE|REG.*\.zsh"
```

- A PIPE pair (3↔4 with same address pair) → `$()` or pipeline is active
- The most-recently-opened `REG ... .zsh` (or `.zwc`) file is what zsh is currently sourcing

Match the file against zsh init order (in `~/.zshrc`):
1. `/etc/zshenv` → `/etc/zshrc` → user `~/.zshenv` → `~/.zshrc`
2. Inside `~/.zshrc`: `source` calls in order

Then `grep -nE '\$\(' <file>` in the suspect file and find the top-level (non-function) `$()` or foreground command.

### 4. Confirm with `set -x` trace (optional)

For init-time hangs you can capture the LAST executed line:

```bash
ZSH_XTRACE_PREFIX="+%N:%i> " /bin/zsh -ix -c exit 2>/tmp/trace.log
tail -20 /tmp/trace.log  # last lines before hang
```

---

## Fix patterns

### Safe operations (use these freely at init)

| Pattern | Why safe |
|---|---|
| `$(<file)` | zsh special form, no fork |
| `${var:h}` (head modifier) | parameter expansion, no fork |
| `${(k)assoc_array}` | parameter expansion of associative-array keys, no fork |
| `${(kF)assoc}` | keys joined by newlines, no fork |
| `read -r var < file` | builtin, no fork |
| `[[ -d "$dir" ]]` / `[[ -f "$file" ]]` | builtin test |
| `print -r -- "$str"` | builtin output |
| `bindkey '^I' > file` | builtin redirect, no fork (the builtin handles the redirect itself) |
| `( cmd & ) &!` | backgrounded + disowned, parent never waits |

### Unsafe operations (avoid at init / in hooks)

| Pattern | Replace with |
|---|---|
| `$(cat file)` | `$(<file)` |
| `$(dirname "$f")` | `${f:h}` |
| `$(basename "$f")` | `${f:t}` |
| `$(uname -a)` test | `$OSTYPE` parameter test |
| `$(builtin zle -la)` | `${(kF)widgets}` (needs `zmodload zsh/parameter`) |
| `cat $cache_file` (print contents) | `print -r -- "$(<$cache_file)"` |
| `cmd > file` at top-level | pre-compute at build time, embed as literal |
| Unconditional `mkdir -p "$dir"` | `[[ -d "$dir" ]] \|\| mkdir -p "$dir"` |

### Build-time patching of third-party zsh plugins

Pattern via `pkgs.runCommand` — patch the upstream source, verify, fail build on drift:

```nix
fixedPlugin = pkgs.runCommand "plugin-patched" {} ''
  cp -r ${pkgs.upstream-plugin} $out
  chmod -R +w $out
  ${pkgs.gnused}/bin/sed -i \
    's|RACY_PATTERN|SAFE_REPLACEMENT|' \
    $out/path/to/file.zsh

  # Build fails if upstream changes the pattern
  if /usr/bin/grep -qF 'RACY_PATTERN' $out/path/to/file.zsh; then
    echo "ERROR: sed patch did not match — upstream changed" >&2
    exit 1
  fi
'';
```

Then source `${fixedPlugin}/...` in zshrc instead of `${pkgs.upstream-plugin}/...`.

**Sandbox gotcha:** `pkgs.runCommand` sandbox doesn't have `/bin/cp` — use plain `cp`.

### Patching Home Manager-emitted zshrc lines

HM emits some racy lines (e.g. `mkdir -p "$(dirname "$HISTFILE")"`) with no opt-out. Override at the merged-zshrc text level — no circularity since the source is `initContent`, not the file's own text:

```nix
home.file.".zshrc".text = lib.mkForce (
  builtins.replaceStrings
    [ ''mkdir -p "$(dirname "$HISTFILE")"'' ]
    [ ''[[ -d "''${HISTFILE:h}" ]] || /bin/mkdir -p "''${HISTFILE:h}"'' ]
    config.programs.zsh.initContent
);
```

### First-precmd skip pattern

For hooks that MUST fork (direnv, starship), the first invocation fires during the shell-start window — the highest-risk moment for the SIGCHLD race. Skip it; inherit parent's state:

```zsh
typeset -g __HOOK_PRIMED=
_my_hook() {
  if [[ -z "$__HOOK_PRIMED" ]]; then
    __HOOK_PRIMED=1
    return 0
  fi
  # racy fork goes here — runs only on 2nd+ invocations
  some_command > "$file"
  ...
}
```

For starship, also set a static `STARSHIP_LEFT` placeholder so the first prompt has visible content. The real prompt appears on the second precmd (after Enter or any keypress).

### Pre-populate env vars to skip third-party fork guards

Many third-party plugins gate forks behind `if [[ -z $VAR ]]` checks. Pre-set `$VAR` in zshrc *before* sourcing the plugin:

```zsh
# Before sourcing atuin.zsh:
zmodload zsh/datetime
[[ -z "${ATUIN_SESSION:-}" ]] && export ATUIN_SESSION="${EPOCHREALTIME//.}-$$"
export ATUIN_SHLVL=$SHLVL  # critical — atuin checks both
source .../atuin.zsh
```

The plugin's `if [[ -z $ATUIN_SESSION || $ATUIN_SHLVL != $SHLVL ]]; then atuin uuid` branch is now skipped.

### Pre-compute at build time

For values that don't depend on runtime state (e.g. `starship prompt --continuation`), capture the output during the Nix build and embed as a literal:

```nix
starship_cont=$(${pkgs.starship}/bin/starship prompt --continuation 2>/dev/null)
${pkgs.gnused}/bin/sed -i "s|^PROMPT2=\".*\"|PROMPT2=\"$starship_cont\"|" $out/starship.zsh
```

---

## Nix indented-string escape gotchas

These bit me repeatedly while writing the patches:

- `''${...}` → literal `${...}` in the output (escapes Nix interpolation)
- `''$` → literal `$`
- `''` followed by `'` → `''` literal (escape the apostrophe)
- `'''` is parsed greedily as `''` + `'` — be careful in sed expressions
- `${pkgs.foo}/bin/foo` → Nix-interpolated to a store path (intentional)

Inside a sed `s|...|...|` expression in a Nix indented string, the LHS and RHS need careful escaping:
- Shell `$$` (PID) → `\$\$` (escape both for sed, then they pass through)
- Literal `$VAR` for shell → `\$VAR`
- `${VAR}` for shell → `''${VAR}` (Nix escape) then `\1` etc.

When in doubt, write the sed in a separate `pkgs.writeShellScript` and call it.

---

## Catalog of fixes applied (this repo)

All in `nix-config/home/_profiles/_template/shell/zsh.nix` (+ one in `nix-config/lib/aws-helpers.nix`):

| Site | Was | Fix |
|---|---|---|
| atuin.zsh | `export ATUIN_SESSION=$(atuin uuid)` | pre-populate `ATUIN_SHLVL=$SHLVL` + build-time sed to file-redirect |
| starship.zsh | `PROMPT2="$(starship prompt --continuation)"` | pre-computed at build time, literal embedded |
| fast-syntax-highlighting | `if [[ $(uname -a) = (#i)*darwin* ]]` | `if [[ $OSTYPE = darwin* ]]` |
| fzf.zsh | `binding=$(bindkey '^I')` | `bindkey '^I' > file; binding=$(<file)` |
| HM-emitted zshrc | `mkdir -p "$(dirname "$HISTFILE")"` | `replaceStrings` override on `home.file.".zshrc".text` → `${HISTFILE:h}` |
| AWS auto-restore | `$(cat ~/.aws/.last_profile)` | `$(<~/.aws/.last_profile)` |
| Welcome cache | `/bin/cat "$_wf"` | `print -r -- "$(<$_wf)"` |
| 3× cache mkdirs | unconditional `/bin/mkdir -p` | `[[ -d ]] \|\|` gate |
| `__starship_render` init call | called once at zshrc end | removed; precmd hook fires it before first prompt |
| zsh-autosuggestions | `$(builtin zle -la)` in precmd hook | build-time sed to `${(kF)widgets}` |
| `_direnv_hook` first call | runs at first precmd | `__DIRENV_HOOK_PRIMED` guard; skip first |
| `__starship_render` first call | runs at first precmd | `__STARSHIP_RENDER_PRIMED` guard; static placeholder for first prompt |

**Result:** 100% → 0% per-restart hang rate (480/480 restarts succeed across 60 stress runs of 8 restarts each, plus 0 hangs in 8-way parallel stress).

---

## When to use this doc

- Shell hangs at prompt after `exec zsh` or new terminal opens
- `darwin-rebuild` succeeds but new shells get stuck
- Adding a new tool to zsh init (atuin, direnv, starship, fzf, etc.) — audit it for top-level `$()` first
- Upgrading a third-party zsh plugin — re-verify the build-time patches still match (build will fail with `ERROR: sed patch did not match` if upstream renamed the line)
