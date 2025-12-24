# ADR-007: CLI Tool Selection

**Status**: Accepted
**Date**: 2024-12-22
**Author**: System Architecture

## Context

The nix-darwin configuration requires a curated set of CLI tools that:

- Replace outdated Unix utilities with modern, faster alternatives
- Provide consistent experience across personal and work machines
- Are available in nixpkgs for reproducible installation
- Improve developer productivity without bloat

### Requirements

1. **Modern**: Tools should be actively maintained (2024-2025 releases)
2. **Fast**: Rust/Go implementations preferred over shell scripts
3. **Ergonomic**: Better defaults, colorized output, intuitive flags
4. **Available**: Must be in nixpkgs (no manual installation)
5. **Additive**: New tools complement, not replace working solutions

### Assessment Methodology

Tools were evaluated against current best-in-class alternatives using:
- Community adoption and maintenance activity
- Performance benchmarks (where applicable)
- nixpkgs availability and version currency
- Integration with existing shell/editor setup

## Decision

### Retain (Already Optimal)

These tools are best-in-class - no changes needed:

| Category | Tool | Rationale |
|----------|------|-----------|
| Search | ripgrep (rg) | Fastest grep replacement |
| Find | fd | Intuitive find replacement |
| Cat | bat | Syntax highlighting, git integration |
| Ls | eza | Icons, git status, tree view |
| Du | dust | Visual disk usage |
| Df | duf | Colorized disk free |
| Top | btop | Beautiful system monitor |
| Sed | sd | Intuitive regex replacement |
| Diff | delta | Git diff with syntax highlighting |
| Ps | procs | Colorized process list |
| Navigation | zoxide | Frecency-based cd |
| Fuzzy | fzf | Universal fuzzy finder |
| Prompt | starship | Cross-shell, fast, customizable |
| File Manager | yazi | Fastest TUI file manager |
| Git TUI | lazygit | Best git TUI |
| Docker TUI | lazydocker | Best docker TUI |
| K8s TUI | k9s | Best kubernetes TUI |
| JSON | jq + yq | Standard data processing |
| HTTP | xh | Faster httpie alternative |
| Task Runner | just | Simple command runner |
| Benchmark | hyperfine | CLI benchmarking |
| Python | uv + ruff | Modern Python tooling |
| Secrets | SOPS + age | Encryption at rest |

### Add (New Tools)

**Priority 1: High Impact**

| Tool | Purpose | Why |
|------|---------|-----|
| **nh** | Nix helper CLI | Better darwin-rebuild UX, package diffs, colored output |
| **atuin** | Shell history | SQLite storage, fuzzy search, filter by exit code/directory |
| **gitleaks** | Secret scanning | Prevent accidental credential commits |
| **stern** | K8s log tailing | Multi-pod logs with colors |
| **kubectx** | K8s context switch | Fast context/namespace switching (includes kubens) |

**Priority 2: Productivity**

| Tool | Purpose | Why |
|------|---------|-----|
| **usql** | Universal SQL client | Single tool for 40+ databases |
| **ghostty** | Terminal emulator | GPU-accelerated, native macOS (alongside iTerm2) |
| **difftastic** | Syntax-aware diff | Understands code structure (alongside delta) |
| **glow** | Markdown viewer | Render READMEs in terminal |
| **navi** | Command cheatsheet | Interactive, better than tldr for complex commands |
| **mdbook** | Documentation | Fast docs generator (Rust) |

**Priority 3: Experimental**

| Tool | Purpose | Why |
|------|---------|-----|
| **zellij** | Multiplexer | Modern alternative (alongside tmux) |
| **helix** | Modal editor | Zero-config, fast (alongside vim/neovim) |

### Not Added (Considered but Rejected)

| Tool | Reason |
|------|--------|
| **mods** | AI pipe tool - interesting but not essential yet |
| **fish/nushell** | zsh ecosystem too valuable to abandon |
| **antidote/zinit** | OMZ works, shell optimization achieved via fast-syntax-highlighting |

## Consequences

### Positive

1. **12 new tools** integrated into nix-darwin packages.nix
2. **nh integration** in rebuild.sh with --legacy fallback
3. **atuin configuration** via home-manager with fuzzy search defaults
4. **ghostty** added to Homebrew casks
5. **Shell startup optimized** to 0.08s warm / 0.86s cold (via fast-syntax-highlighting, not OMZ removal)

### Implementation

Tools installed in:
- `nix-config/modules/shared/packages.nix` - CLI tools
- `nix-config/home/_mixins/base.nix` - atuin home-manager config
- `nix-config/modules/darwin/homebrew.nix` - ghostty cask
- `scripts/maintenance/rebuild.sh` - nh integration

### Package Versions (December 2025)

```
atuin-18.10.0      nh-4.2.0
gitleaks-8.30.0    zellij-0.43.1
stern-1.33.1       helix-25.07.1
kubectx-0.9.5      navi-2.24.0
usql-0.20.0        glow-2.1.1
difftastic         mdbook-0.4.52
ghostty-1.2.3
```

## Future Considerations

1. **Shell optimization Phase 2**: Consider removing OMZ entirely if startup time regresses
2. **mods/aichat**: Evaluate AI pipe tools as they mature
3. **Tool consolidation**: Periodically review for unused tools

## References

- Analysis performed: December 2025
- Validated against nixpkgs-unstable
- See `docs/guides/CLI-TOOLS-GUIDE.md` for usage documentation
