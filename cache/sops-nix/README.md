# sops-nix Binary Cache

Pre-built `sops-install-secrets` binary for machines behind corporate proxies.

## Problem

The sops-nix module builds `sops-install-secrets` from Go source, which requires
downloading modules from `proxy.golang.org`. Corporate proxies block this:

```
Get "https://proxy.golang.org/...": read tcp ...: connection reset by peer
```

The full build closure is ~1.5 GB (Go compiler, LLVM, etc.). This directory caches
just the compiled binary (~14 MB compressed) so proxied machines can skip the build.

## Setup (one-time per machine)

### On an unrestricted machine (e.g., personal laptop)

```bash
# Build and compress the binary
./cache/sops-nix/export.sh

# Commit and push
git add cache/sops-nix/sops-install-secrets.gz
git commit -m "chore: cache sops-install-secrets binary"
git push
```

### On the proxied machine (e.g., work laptop)

```bash
# Pull the repo (or clone fresh)
git pull

# Import the binary to ~/.local/bin/
./cache/sops-nix/import.sh

# Rebuild — sops-nix will use the cached binary
nix-rebuild && exec zsh
```

## How it works

1. `export.sh` builds `sops-install-secrets` via Nix and compresses the binary
2. `import.sh` extracts it to `~/.local/bin/sops-install-secrets`
3. The overlay (`nix-config/overlays/default.nix`) detects the binary at that path
   and wraps it as a Nix derivation, skipping the Go build entirely

### Resolution order in the overlay

| Priority | Method | When used |
|----------|--------|-----------|
| 1 | Pre-built binary at `~/.local/bin/` | After running `import.sh` |
| 2 | Corporate Go proxy | When `proxies.go.enabled = true` in `user-config.nix` |
| 3 | Build from source | Default (requires `proxy.golang.org` access) |

## Updating

After updating the sops-nix flake input, re-export on the unrestricted machine:

```bash
nix flake update sops-nix
./cache/sops-nix/export.sh
git add cache/sops-nix/sops-install-secrets.gz
git commit -m "chore: update sops-install-secrets binary"
```

## Notes

- Architecture-specific: current binary is `aarch64-darwin` (Apple Silicon)
- The binary at `~/.local/bin/` survives `nix-collect-garbage`
- If you delete the binary, re-run `import.sh` before rebuilding
