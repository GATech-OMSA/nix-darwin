# Configuration Diff Tool Usage

## Overview

The `config-diff` tool compares nix-darwin configurations between different generations, showing what changed before and after rebuilds.

## Quick Start

```bash
# Compare current vs previous generation
config-diff

# Only show package changes (fast)
config-diff-packages

# Show detailed diffs
config-diff-verbose

# Compare specific generations
config-diff --generations 8 10
```

## Features

- **Package Comparison**: See added/removed packages between generations
- **System Settings**: Detect macOS system setting changes
- **Home Manager**: Track user configuration changes
- **Activation Scripts**: Monitor activation script modifications
- **System Configuration**: Check /etc configuration changes
- **Color-Coded Output**: Green (added), Red (removed), Yellow (modified)

## Usage Examples

### Basic Comparison

```bash
$ config-diff
```

**Output**:
```
╔════════════════════════════════════════════════════════════════╗
║         Nix-Darwin Configuration Diff Tool                    ║
╚════════════════════════════════════════════════════════════════╝

ℹ Comparing generation 9 → 10

═══ 📦 Package Changes ═══

Old generation: 163 packages
New generation: 163 packages

✓ No package changes

═══ ⚙️  System Settings ═══
✓ No system setting changes

═══ 🏠 Home Manager Configuration ═══
✓ No Home Manager changes

═══ 🔧 Activation Scripts ═══
⚠ Activation script changed
  Size: 98366 → 98450 bytes

═══ 📊 Summary ═══
Generation 9 → 10
+ 0 added
- 0 removed
```

### Package-Only Mode

```bash
$ config-diff-packages
```

**Output**:
```
═══ 📦 Package Changes ═══

Old generation: 188 packages
New generation: 163 packages

Added (1):
  + markdown-link-check

Removed (26):
  - bat
  - direnv
  - fzf
  - python3.13
  - starship
  - zoxide
  ...
```

### Specific Generation Comparison

```bash
$ config-diff --generations 1 10
```

Compares generation 1 to generation 10 (useful for tracking changes over time).

### Verbose Mode

```bash
$ config-diff-verbose
```

Shows detailed file-level diffs for all changed components.

## Command Options

| Option | Description |
|--------|-------------|
| `--generations N M` | Compare generation N to generation M |
| `--packages-only` | Only show package differences |
| `--verbose` | Show full diff output |
| `--help` | Show help message |

## Use Cases

### Before Rebuilding

Preview what will change:

```bash
# Make config changes
nixconf

# Check what will change (compare against current)
config-diff

# Rebuild if changes look good
nix-rebuild
```

### After Rebuilding

Verify changes were applied:

```bash
# After rebuild
nix-rebuild

# Check what changed
config-diff
```

### Investigating Issues

Track when problems started:

```bash
# List all generations
darwin-rebuild --list-generations

# Compare working vs broken generation
config-diff --generations 5 8
```

### Tracking Package Changes

Monitor package additions/removals:

```bash
# Quick package overview
config-diff-packages

# Track packages over time
config-diff --generations 1 10 --packages-only
```

## Generation Management

### Listing Generations

```bash
# System generations (managed by Nix)
ls -la /nix/var/nix/profiles/ | grep system

# Current generation
readlink /nix/var/nix/profiles/system
```

### Generation Paths

Each generation is stored at:
```
/nix/var/nix/profiles/system-N-link/
├── sw/bin/           # System packages
├── darwin/           # macOS settings
├── user/             # Home Manager config
├── activate          # Activation script
└── etc/              # System configuration
```

### Rollback After Comparison

If diff shows unwanted changes:

```bash
# Rollback to previous generation
nix-rollback

# Or rollback to specific generation
sudo darwin-rebuild --rollback --switch-generation N
```

## Integration with Workflow

### Pre-Flight Integration (Optional)

Add to `pre-flight-checks.sh` to show diff before rebuild:

```bash
# In pre-flight-checks.sh
echo "📊 Configuration changes:"
~/nix-darwin/scripts/config-diff.sh --packages-only
echo ""
read -p "Continue with rebuild? (y/N) " -n 1 -r
```

### Automated Tracking

Create generation changelog:

```bash
# After each rebuild
config-diff >> ~/nix-darwin/CHANGELOG.txt
```

## Tips

1. **Quick Check**: Use `config-diff-packages` for fast overview
2. **Detailed Analysis**: Use `config-diff-verbose` for full investigation
3. **Historical Tracking**: Compare generation 1 vs current periodically
4. **Before/After**: Run before and after major config changes

## Troubleshooting

### Generation Not Found

```bash
$ config-diff --generations 99 100
✗ Generation 99 not found at /nix/var/nix/profiles/system-99-link
```

**Solution**: List available generations:
```bash
ls /nix/var/nix/profiles/ | grep system
```

### No Previous Generation

```bash
$ config-diff
✗ No previous generation found
```

**Solution**: This happens on first build. Make at least 2 builds before using config-diff.

### Permission Denied

```bash
$ config-diff
Permission denied: /nix/var/nix/profiles/system-1-link
```

**Solution**: Script doesn't require sudo, but paths are system-owned. Ensure read access:
```bash
ls -la /nix/var/nix/profiles/system-1-link
```

## Related Commands

- `nix-rebuild` - Rebuild system
- `nix-rollback` - Rollback to previous generation
- `health-check` - Validate system health
- `pre-flight` - Run pre-flight checks

## Technical Details

### What Gets Compared

1. **Packages** (`sw/bin/`): Binary names in system path
2. **System Settings** (`darwin/`): macOS configuration files
3. **Home Manager** (`user/`): User-level dotfiles and settings
4. **Activation Scripts** (`activate`): System activation logic
5. **System Config** (`etc/`): /etc configuration files

### Diff Algorithm

- **Packages**: `comm` command for sorted list comparison
- **Files**: `diff -r` for directory recursion
- **Scripts**: `diff` for single file comparison

### Performance

- **Fast**: Package-only comparison (~0.1s)
- **Standard**: Full comparison (~0.5s)
- **Verbose**: Full diff with output (~2s)

## Future Enhancements

Potential improvements (not yet implemented):

1. JSON output for automation
2. Git-style `config-diff HEAD~1` syntax
3. Integration with nix flake metadata
4. Graphical diff viewer support
5. Save/load diff reports

---

**Version**: 1.0.0
**Created**: 2025-11-06
**Script**: `scripts/config-diff.sh`
**Aliases**: `config-diff`, `config-diff-packages`, `config-diff-verbose`
