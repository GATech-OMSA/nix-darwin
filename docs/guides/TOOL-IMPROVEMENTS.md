# Tool Improvements Analysis

**Date:** December 2025
**Status:** ✅ Implementation Complete

Comprehensive analysis of CLI tools, shell configuration, and development environment improvements for nix-darwin.

---

## Executive Summary

Current stack is in the top 10% of modern CLI setups. Improvements implemented:
1. ✅ **Added nh** - Modern nix-darwin rebuild with better UX, package diffs
2. ✅ **Added missing essentials** - atuin, gitleaks, stern, kubectx, usql
3. ✅ **Added productivity tools** - difftastic, glow, navi, mdbook
4. ✅ **Modernized terminals** - Added Ghostty alongside iTerm2
5. ✅ **Expanded multiplexers** - Added Zellij alongside tmux
6. ✅ **Added helix** - Fast modal editor alternative
7. 🔜 **Shell startup optimization** - Currently 1.7s cold start (target: <0.5s) - Future work

---

## Current State Assessment

| Metric | Value | Status |
|--------|-------|--------|
| Shell startup (cold) | **1.74s** | Needs improvement |
| Shell startup (warm) | **0.36s** | Acceptable |
| Oh-My-Zsh plugins | 13 | Heavy (potential removal) |
| Modern CLI tools | Excellent | Keep |
| Navigation (zoxide/fzf) | Optimal | Keep |

### What's Already Optimal

These tools are the best in class - no changes needed:

| Category | Tool | Status |
|----------|------|--------|
| Search | ripgrep (rg) | Best grep replacement |
| Find | fd | Best find replacement |
| Cat | bat | Best cat replacement |
| Ls | eza | Best ls replacement |
| Du | dust | Best du replacement |
| Df | duf | Best df replacement |
| Top | btop | Best system monitor |
| Sed | sd | Best sed replacement |
| Diff | delta | Best git diff pager |
| Ps | procs | Best ps replacement |
| Navigation | zoxide | Best cd replacement |
| Fuzzy | fzf | Best fuzzy finder |
| Prompt | starship | Best cross-shell prompt |
| File Manager | yazi | Best TUI file manager |
| Git TUI | lazygit | Best git TUI |
| Docker TUI | lazydocker | Best docker TUI |
| K8s TUI | k9s | Best kubernetes TUI |
| JSON | jq + yq | Standard tools |
| HTTP | xh | Best httpie alternative |
| Task Runner | just | Perfect balance |
| Benchmark | hyperfine | Best CLI benchmarking |
| Python | uv + ruff | Cutting-edge tooling |
| Secrets | SOPS + age | Modern encryption |

---

## Recommended Improvements

### Priority 1: Must-Have (High Impact)

| Tool | Purpose | Replaces | Why |
|------|---------|----------|-----|
| **nh** | Nix helper CLI | darwin-rebuild wrapper | Better UX, faster, visualizes diffs |
| **atuin** | Shell history | Ctrl+R | SQLite history, sync, filter by exit code |
| **gitleaks** | Secret scanning | (new) | Prevent accidental secret commits |
| **stern** | K8s log tailing | kubectl logs | Multi-pod logs with colors |
| **kubectx** | K8s context switch | manual kubectl | Fast context/namespace switching |

### Priority 2: Should-Have (Strong Productivity)

| Tool | Purpose | Replaces | Why |
|------|---------|----------|-----|
| **usql** | Universal SQL | pgcli | Single tool for PG, MySQL, SQLite, MSSQL |
| **ghostty** | Terminal emulator | (alongside iTerm2) | Faster, native macOS, modern |
| **difftastic** | Syntax-aware diff | (alongside delta) | Understands code structure |
| **glow** | Markdown viewer | (new) | Read READMEs in terminal |
| **navi** | Command builder | tldr | Interactive cheatsheet |
| **mdbook** | Documentation | (new) | Fast docs generator |

### Priority 3: Nice-to-Have (Experimental)

| Tool | Purpose | Replaces | Why |
|------|---------|----------|-----|
| **zellij** | Multiplexer | (alongside tmux) | Modern, better UX |
| **helix** | Modal editor | (alongside vim) | Zero-config, fast |
| **mods** | AI pipe | (new) | Unix-style AI (`cat file \| mods "explain"`) |

---

## Shell Optimization Plan

### Current Oh-My-Zsh Plugins

```
git, docker, docker-compose, terraform, kubectl, aws,
dirhistory, sudo, extract, copypath, copyfile,
colored-man-pages, safe-paste
```

### Migration Strategy

**Keep (inline as functions):**
- `sudo` - Double ESC to prefix sudo
- `extract` - Universal archive extraction

**Remove (use native completions from Nix):**
- `git` - Just aliases, completions from Nix
- `docker`, `docker-compose` - Completions from Nix
- `terraform`, `kubectl`, `aws` - Completions from Nix
- `dirhistory` - Rarely used
- `copypath`, `copyfile` - Already have `copy` alias
- `colored-man-pages` - Use bat integration
- `safe-paste` - Modern terminals handle this

### Expected Improvement

| State | Startup Time |
|-------|--------------|
| Current (OMZ) | 1.74s cold |
| After optimization | <0.5s cold |

---

## Package Availability (nixpkgs)

All recommended tools are available:

```
atuin-18.10.0      ✓
gitleaks-8.30.0    ✓
stern-1.33.1       ✓
kubectx-0.9.5      ✓
usql-0.20.0        ✓
nh-4.2.0           ✓
zellij-0.43.1      ✓
helix-25.07.1      ✓
navi-2.24.0        ✓
glow-2.1.1         ✓
mdbook-0.4.52      ✓
ghostty-1.2.3      ✓
difftastic         ✓
```

---

## Implementation Order

1. **Phase 1: Try nh** ✅ Complete
   - Installed nh to packages.nix
   - Updated rebuild.sh to use nh by default (--legacy fallback)
   - Added nh aliases (nh-switch, nh-build, nh-clean, nh-search)

2. **Phase 2: Must-Have Tools** ✅ Complete
   - Added atuin, gitleaks, stern, kubectx to packages.nix
   - Configured atuin home-manager module in base.nix

3. **Phase 3: Should-Have Tools** ✅ Complete
   - Added usql, difftastic, glow, navi, mdbook to packages.nix
   - Added ghostty to homebrew casks (alongside iTerm2)

4. **Phase 4: Nice-to-Have** ✅ Complete
   - Added zellij (alongside tmux)
   - Added helix (alongside vim/neovim)

5. **Phase 5: Shell Optimization** 🔜 Future
   - Remove OMZ
   - Migrate to native zsh + antidote
   - Inline essential functions
   - Target: <0.5s cold start

---

## References

- Analysis performed: December 2025
- Validated with Gemini 3 Pro (ultrathink mode)
- Based on current nixpkgs versions
