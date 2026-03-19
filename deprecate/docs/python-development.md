# Python Development with UV + Direnv

This guide covers the Python development workflow using UV (fast package manager) and direnv (automatic environment activation).

## Overview

| Tool | Purpose | Speed |
|------|---------|-------|
| **UV** | Python package manager | 10-100x faster than pip |
| **direnv** | Auto-activate environments on `cd` | Instant |

## Quick Start

### New Project

```bash
# Create project
cd ~/Dev
uv init myproject
cd myproject

# Enable auto-activation
echo "use uv" > .envrc

# Done! .venv is created and activated automatically
```

### Existing Project with .venv

```bash
cd existing-project
echo "use venv" > .envrc
# Activates on next cd into directory
```

---

## Direnv Layouts

### `use uv` - Full UV Integration

Creates and manages virtual environments automatically:

```bash
# .envrc
use uv              # Uses default Python (3.13)
use uv 3.12         # Uses specific Python version
```

**What it does:**
1. Creates `.venv` if missing (using `uv venv`)
2. Activates the virtual environment
3. Runs `uv sync` if `pyproject.toml` exists

### `use venv` - Simple Activation

For projects with existing virtual environments:

```bash
# .envrc
use venv            # Looks for .venv or venv/
use venv myenv      # Uses specific directory
```

### `use flake` - Nix Development

For Nix-based projects (already available via nix-direnv):

```bash
# .envrc
use flake           # Loads flake.nix devShell
```

---

## Common Workflows

### Create UV Project

```bash
cd ~/Dev
uv init myproject
cd myproject
echo "use uv" > .envrc

# Add dependencies
uv add requests pandas numpy

# Dependencies auto-sync when you cd back in
```

### Convert Existing Project to UV

```bash
cd existing-project

# If requirements.txt exists
uv init
uv add -r requirements.txt
echo "use uv" > .envrc
```

### Multiple Python Versions

```bash
# Project A with Python 3.12
cd project-a
echo "use uv 3.12" > .envrc

# Project B with Python 3.11
cd project-b
echo "use uv 3.11" > .envrc
```

---

## Manual Functions (Still Available)

For quick one-off operations without .envrc:

| Command | Description |
|---------|-------------|
| `uv-new <name>` | Create new UV project and cd into it |
| `uv-venv` | Create .venv in current directory |
| `activate` | Manually activate .venv or venv |
| `m-act <env>` | Activate micromamba environment |

---

## UV Commands Reference

```bash
# Project management
uv init                    # Initialize new project
uv add <package>           # Add dependency
uv remove <package>        # Remove dependency
uv sync                    # Install from pyproject.toml

# Virtual environments
uv venv                    # Create .venv
uv venv --python 3.12      # Create with specific Python

# Running
uv run python script.py    # Run in project's venv
uv run pytest              # Run tests
```

---

## Configuration

### Trusted Directories

`~/Dev` is whitelisted for auto-allow. Projects there don't need `direnv allow`.

To add more trusted paths, edit `nix-config/home/_profiles/_template/programs/direnv.nix`:

```nix
home.file.".config/direnv/direnv.toml".text = ''
  [whitelist]
  prefix = [ "~/Dev", "~/Work" ]
'';
```

### UV Python Preference

UV is configured to use only Nix-managed Python versions:

```nix
# In python.nix
UV_PYTHON_PREFERENCE = "only-managed";
```

---

## Troubleshooting

### "direnv: error .envrc is blocked"

```bash
direnv allow
# Or move project to ~/Dev (whitelisted)
```

### Wrong Python version

```bash
# Check available versions
uv python list

# Specify in .envrc
echo "use uv 3.12" > .envrc
direnv reload
```

### Dependencies not syncing

```bash
# Force reload
direnv reload

# Or manually sync
uv sync
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `~/.config/direnv/direnvrc` | Custom layouts (use uv, use venv) |
| `~/.config/direnv/direnv.toml` | Direnv settings and whitelist |
| `pyproject.toml` | UV project dependencies |
| `.envrc` | Per-project direnv config |
| `.venv/` | Virtual environment (gitignored) |
