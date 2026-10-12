#!/usr/bin/env bash
#
# bootstrap.sh - Set up the Homebrew-only work machine (no Nix)
#
# Idempotent. Installs the Brewfile, links dotfiles from this directory, and
# generates the patched shell-init files under ~/.cache/mac-14/init/ that
# zsh/zshrc sources. Re-run after `brew upgrade` (tool init scripts are
# regenerated and re-patched) or after editing anything in this directory.
#
# Usage:
#   machines/mac-14/bootstrap.sh              # full setup
#   machines/mac-14/bootstrap.sh --no-brew    # skip `brew bundle` (tools already installed)
#   machines/mac-14/bootstrap.sh --init-only  # only regenerate init files (implies --no-brew)
#
# Env:
#   GIT_NAME / GIT_EMAIL  used to set git identity if none is configured yet
#   MAC14_INIT_DIR        generated-init location (default ~/.cache/mac-14/init); the
#                         directory is deleted and recreated on every run
#   MAC14_PLUGIN_PREFIX   where to find share/zsh-autosuggestions etc. (default: brew
#                         prefix; override for tests)

set -euo pipefail

# ============================================
# Setup
# ============================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_DIR="${MAC14_INIT_DIR:-$HOME/.cache/mac-14/init}"
CONF_DIR="$HOME/.config/mac-14"

# bash 5.2 treats `&` in ${var//pat/rep} replacements specially; our replacements
# contain `&&`. No-op on bash 3.2 (macOS /bin/bash).
shopt -u patsub_replacement 2>/dev/null || true

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
info()    { printf '%s==>%s %s\n' "$BLUE" "$NC" "$*"; }
success() { printf '%s ok%s %s\n' "$GREEN" "$NC" "$*"; }
warning() { printf '%swarn%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
error()   { printf '%serror%s %s\n' "$RED" "$NC" "$*" >&2; }

DO_BREW=1
for arg in "$@"; do
  case "$arg" in
    --no-brew)   DO_BREW=0 ;;
    --init-only) DO_BREW=0; INIT_ONLY=1 ;;
    -h|--help)   sed -n '2,22p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) error "unknown argument: $arg"; exit 2 ;;
  esac
done
INIT_ONLY="${INIT_ONLY:-0}"

# ============================================
# Helpers
# ============================================

# link <src> <dst>: symlink, backing up a pre-existing regular file once.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$dst.pre-mac-14"
    warning "backed up existing $dst -> $dst.pre-mac-14"
  fi
  ln -s "$src" "$dst"
  success "linked $dst"
}

# subst_fixed <file> <literal-pattern> <replacement>: replace every occurrence.
# Pure bash so no sed-escaping or BSD/GNU differences; replacement is literal.
subst_fixed() {
  local file="$1" pat="$2" rep="$3" line
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s\n' "${line//"$pat"/$rep}"
  done < "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

# replace_line <file> <ERE> <replacement-line>: replace whole lines matching the ERE.
replace_line() {
  local file="$1" re="$2" rep="$3" line
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $re ]]; then printf '%s\n' "$rep"; else printf '%s\n' "$line"; fi
  done < "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

# must_not_contain <file> <literal>: fail if a racy pattern survived patching.
# Mirrors the nix build's verify step: if upstream changes the line, the patch no
# longer matches and we must find out here, not via a wedged shell later.
must_not_contain() {
  if grep -qF -- "$2" "$1"; then
    error "$(basename "$1"): patch did not apply (upstream changed?): $2"
    exit 1
  fi
}

# ============================================
# Homebrew
# ============================================

if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  BREW=/usr/local/bin/brew
else
  BREW="$(command -v brew || true)"
fi
if [[ -z "$BREW" ]]; then
  error "Homebrew not found. Install it first: https://brew.sh"
  exit 1
fi
PREFIX="$("$BREW" --prefix)"
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSECURE_REDIRECT=1
export PATH="$PREFIX/bin:$PREFIX/sbin:$PATH"

if [[ "$DO_BREW" == 1 ]]; then
  info "brew bundle ($HERE/Brewfile)"
  "$BREW" bundle --file="$HERE/Brewfile"
fi

for tool in starship atuin zoxide direnv fzf; do
  command -v "$tool" >/dev/null || { error "$tool not installed (run without --no-brew/--init-only)"; exit 1; }
done

# ============================================
# Dotfiles
# ============================================

if [[ "$INIT_ONLY" == 0 ]]; then
  info "linking dotfiles"
  link "$HERE/config/starship.toml"      "$HOME/.config/starship.toml"
  link "$HERE/config/atuin/config.toml"  "$HOME/.config/atuin/config.toml"
  link "$HERE/zsh/zshrc"                 "$CONF_DIR/zshrc"

  # ~/.npmrc may hold a corporate registry/CA: never replace it, only create it.
  if [[ -e "$HOME/.npmrc" ]]; then
    warning "~/.npmrc exists; make sure it has: min-release-age=14 (see config/npmrc)"
  else
    link "$HERE/config/npmrc" "$HOME/.npmrc"
  fi

  # Managed block in ~/.zshrc (leaves anything else in the file alone).
  touch "$HOME/.zshrc"
  if ! grep -qF '# >>> mac-14 >>>' "$HOME/.zshrc"; then
    {
      printf '\n# >>> mac-14 >>>\n'
      printf '[[ -r "$HOME/.config/mac-14/zshrc" ]] && source "$HOME/.config/mac-14/zshrc"\n'
      printf '# <<< mac-14 <<<\n'
    } >> "$HOME/.zshrc"
    success "added mac-14 block to ~/.zshrc"
  fi

  # Git: include our shared settings; identity only if not already configured.
  git config --global include.path "$HERE/config/gitconfig"
  if [[ -z "$(git config --global user.email || true)" ]]; then
    if [[ -n "${GIT_NAME:-}" && -n "${GIT_EMAIL:-}" ]]; then
      git config --global user.name "$GIT_NAME"
      git config --global user.email "$GIT_EMAIL"
      success "git identity set from GIT_NAME/GIT_EMAIL"
    else
      warning "no git identity: re-run with GIT_NAME='…' GIT_EMAIL='…' or set it by hand"
    fi
  fi
fi

# ============================================
# Generated shell init (patched for the macOS 15+ SIGCHLD race)
# ============================================

info "generating shell init in $INIT_DIR"
rm -rf "$INIT_DIR"
mkdir -p "$INIT_DIR/plugins"

BIN_STARSHIP="$(command -v starship)"
BIN_ATUIN="$(command -v atuin)"
BIN_DIRENV="$(command -v direnv)"
NODE22="$PREFIX/opt/node@22/bin"

# Absolute tool paths + PATH, so the zshrc never needs `command -v`/`brew --prefix`.
cat > "$INIT_DIR/bins.zsh" <<EOF
# Generated by bootstrap.sh — do not edit.
export HOMEBREW_PREFIX="$PREFIX"
typeset -U path
path=("$PREFIX/bin" "$PREFIX/sbin" "$NODE22" \$HOME/.local/bin \$path)
export PATH
typeset -g __STARSHIP_BIN="$BIN_STARSHIP"
typeset -g __ATUIN_BIN="$BIN_ATUIN"
typeset -g __DIRENV_BIN="$BIN_DIRENV"
EOF

starship init zsh --print-full-init > "$INIT_DIR/starship.zsh" 2>/dev/null \
  || starship init zsh > "$INIT_DIR/starship.zsh"
zoxide init zsh > "$INIT_DIR/zoxide.zsh"
atuin init zsh > "$INIT_DIR/atuin.zsh"
direnv hook zsh > "$INIT_DIR/direnv.zsh"
fzf --zsh > "$INIT_DIR/fzf.zsh"

for f in starship zoxide atuin direnv fzf; do
  [[ -s "$INIT_DIR/$f.zsh" ]] || { error "generated $f.zsh is empty"; exit 1; }
done

# -- starship: top-level PROMPT2="$(starship prompt --continuation)" -> literal
cont="$(starship prompt --continuation 2>/dev/null || printf '❯ ')"
replace_line "$INIT_DIR/starship.zsh" '^PROMPT2="\$\(.*prompt --continuation\)"$' "PROMPT2=\"$cont\""
must_not_contain "$INIT_DIR/starship.zsh" 'prompt --continuation)"'

# -- atuin: per-command `id=$(atuin history start …)` -> per-pid file + read.
# $__ATUIN_HISTORY_START_FILE is defined in zshrc before this file is sourced.
# (ATUIN_SESSION's `$(atuin uuid)` is skipped by pre-populating it in zshrc.)
for var in '$1' '$line'; do
  subst_fixed "$INIT_DIR/atuin.zsh" \
    "id=\$(ATUIN_SHELL=zsh atuin history start --hook -- \"$var\" 2>/dev/null)" \
    "ATUIN_SHELL=zsh \"\$__ATUIN_BIN\" history start --hook -- \"$var\" > \"\$__ATUIN_HISTORY_START_FILE\" 2>/dev/null; id=\"\"; [[ -s \"\$__ATUIN_HISTORY_START_FILE\" ]] && read -r id < \"\$__ATUIN_HISTORY_START_FILE\""
done
must_not_contain "$INIT_DIR/atuin.zsh" 'id=$(ATUIN_SHELL=zsh atuin history start'

# -- fzf: older versions run `binding=$(bindkey '^I')` at source time (absent in
# recent ones; the substitution is then a no-op).
subst_fixed "$INIT_DIR/fzf.zsh" \
  "binding=\$(bindkey '^I')" \
  "bindkey '^I' > \"\${TMPDIR:-/tmp}/.fzf-binding.\$\$\" 2>/dev/null && binding=\"\$(<\${TMPDIR:-/tmp}/.fzf-binding.\$\$)\" && /bin/rm -f \"\${TMPDIR:-/tmp}/.fzf-binding.\$\$\""
must_not_contain "$INIT_DIR/fzf.zsh" "binding=\$(bindkey '^I')"

# -- plugins (copied out of the Cellar so we can patch them)
AUTOSUGGEST_SRC="${MAC14_PLUGIN_PREFIX:-$PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
FSH_SRC="${MAC14_PLUGIN_PREFIX:-$PREFIX}/share/zsh-fast-syntax-highlighting"
if [[ -r "$AUTOSUGGEST_SRC" ]]; then
  cp "$AUTOSUGGEST_SRC" "$INIT_DIR/plugins/zsh-autosuggestions.zsh"
  # `$(builtin zle -la)` forks to list widgets; ${(kF)widgets} reads the same data
  # from the `widgets` parameter without a subshell.
  subst_fixed "$INIT_DIR/plugins/zsh-autosuggestions.zsh" '$(builtin zle -la)' '${(kF)widgets}'
  must_not_contain "$INIT_DIR/plugins/zsh-autosuggestions.zsh" '$(builtin zle -la)'
else
  warning "zsh-autosuggestions not found at $AUTOSUGGEST_SRC (brew bundle?) — skipping"
fi
if [[ -d "$FSH_SRC" ]]; then
  cp -R "$FSH_SRC" "$INIT_DIR/plugins/fast-syntax-highlighting"
  # Top-level `$(uname -a)` at source time -> parameter test.
  subst_fixed "$INIT_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
    'if [[ $(uname -a) = (#i)*darwin* ]]' 'if [[ $OSTYPE = darwin* ]]'
  must_not_contain "$INIT_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
    'if [[ $(uname -a) = (#i)*darwin* ]]'
else
  warning "zsh-fast-syntax-highlighting not found at $FSH_SRC (brew bundle?) — skipping"
fi

# Compile for faster loading
for f in starship zoxide atuin direnv fzf; do
  zsh -c "zcompile $INIT_DIR/$f.zsh"
done

success "done. Open a new terminal or run: exec zsh"
