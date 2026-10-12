# mac-14 — Homebrew-only work machine

A small, self-contained setup for a second work Mac. **No Nix.** Everything is
Homebrew plus a few dotfiles, all in this directory. Nothing outside
`machines/mac-14/` is used.

## What you get

- **Claude Code** (cask `claude-code@latest`) and Ghostty
- **Prompt and shell:** starship, atuin (ctrl-r history search), zoxide (`z`, `zi`),
  fzf (ctrl-t, alt-c), direnv, zsh-autosuggestions, fast-syntax-highlighting
- **Faster search / modern CLI:** ripgrep, fd, bat, eza, delta, sd, dust, duf, btop, jq, yq
- git, git-lfs, gh, node@22
- npm 14-day release quarantine (`min-release-age=14`), no Homebrew auto-update

## Setup on the new machine

The setup links files from this directory, so it must live somewhere permanent.
Cloning the whole repo brings your personal Nix config and encrypted secrets onto a
work machine. To copy only this directory instead, run on your personal Mac:

```bash
git archive work/mac-14 machines/mac-14 | tar -x -C /tmp && scp -r /tmp/machines/mac-14 <new-mac>:~/mac-14
```

Then on the new machine:

```bash
GIT_NAME="Your Name" GIT_EMAIL="you@work.example" ~/mac-14/bootstrap.sh
exec zsh
```

`bootstrap.sh` is idempotent. Flags: `--no-brew` (skip `brew bundle`),
`--init-only` (only regenerate the shell init files).

## What bootstrap does

1. `brew bundle` with `Brewfile`
2. Symlinks `starship.toml`, `atuin/config.toml`, and `zshrc` into `~/.config/`;
   creates `~/.npmrc` only if absent (an existing one is never replaced)
3. Adds a managed `# >>> mac-14 >>>` block to `~/.zshrc` (nothing else in it is touched)
4. Includes `config/gitconfig` from your global git config; sets identity only if
   none exists
5. Generates `~/.cache/mac-14/init/*.zsh` (starship, zoxide, atuin, direnv, fzf and the
   two plugins) and patches the lines that fork at shell start

**Re-run it after `brew upgrade`**, because the init scripts are generated from the
installed tool versions. If an upstream change makes a patch stop matching, bootstrap
exits with an error rather than leaving a racy init file.

## Why the init files are generated

macOS 15+ can lose a SIGCHLD in zsh when a child exits before the parent waits, which
hangs the shell forever. Any `$(cmd)` or `cmd > file` at the top level of shell init can
trigger it. The usual `eval "$(tool init zsh)"` lines are exactly that, so the init is
generated once and patched, and `zsh/zshrc` only sources files. This mirrors the Nix
setup (`docs/macos-zsh-sigchld.md`). **Do not add `$(...)` at the top level of
`zsh/zshrc`.**

## Corporate proxy / CA bundle / secrets

Machine-specific values stay out of git: put them in `~/.zshrc.local` (sourced near the end
of `zshrc`), for example:

```zsh
export SSL_CERT_FILE="$HOME/.config/certs/cacert.pem"
export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"
export AWS_CA_BUNDLE="$SSL_CERT_FILE"
```

For a private npm registry, add `registry=` and `cafile=` lines to `~/.npmrc`.

## Updating

```bash
mac14-update      # brew update && brew upgrade && brew upgrade --cask --greedy
~/mac-14/bootstrap.sh --no-brew
```

## Not ported from the Nix setup

AWS SSO helpers, SOPS secrets, nh/darwin-rebuild aliases, the lazy-loaded function
libraries, dynamic starship light/dark palette, system defaults (Dock, firewall), and
CVE scanning. Rollback is `brew` only (no generations).

## Undo

Delete the `# >>> mac-14 >>>` block from `~/.zshrc`, remove `~/.config/mac-14`,
`~/.cache/mac-14`, and the `include.path` line from `~/.gitconfig`. Backups of any
file bootstrap replaced are next to it as `*.pre-mac-14`.
