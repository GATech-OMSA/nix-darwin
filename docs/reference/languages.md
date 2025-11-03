# Programming Languages Reference

**Python and Node.js development setup**

[← Back to Index](../index.md)

---

## Table of Contents

- [Python Development](#python-development)
  - [Python Version](#python-version)
  - [Environment Managers](#environment-managers)
  - [UV - Fast Python Package Manager](#uv---fast-python-package-manager)
  - [Micromamba - Conda Environment Manager](#micromamba---conda-environment-manager)
  - [Python Tools](#python-tools)
  - [Code Quality Tools](#code-quality-tools)
  - [Auto-Activation Feature](#auto-activation-feature)
  - [Jupyter & IPython](#jupyter--ipython)
  - [Learning & Interview Prep](#learning--interview-prep)
  - [Environment Info](#environment-info)
  - [Common Workflows](#common-workflows)
  - [Tips & Best Practices](#tips--best-practices)
  - [Troubleshooting](#troubleshooting-python)
- [Node.js Development](#nodejs-development)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Project Setup](#project-setup)
  - [Common Commands](#common-commands)
- [Configuration](#configuration)

---

## Python Development

### Python Version

```bash
# Check Python version
python --version
# Python 3.13.8

# Python aliases
py               # Shortcut for python
ipy              # IPython interactive shell
```

**Installed via Nix:**
- `python313` - Main Python interpreter
- `python313Packages.pip` - Package installer
- `python313Packages.ipython` - Enhanced REPL

---

### Environment Managers

**Quick Comparison:**

| Tool | Best For | Speed | Package Source |
|------|----------|-------|----------------|
| **UV** | Modern Python projects | Fastest | PyPI |
| **Micromamba** | Data science, ML, multi-language | Fast | Conda-forge |
| **venv** | Standard library, simple projects | Slow | PyPI |

---

### UV - Fast Python Package Manager

UV is a blazing fast Python package manager written in Rust. 10-100x faster than pip.

**Aliases:**

| Alias | Command | Description |
|-------|---------|-------------|
| `uv-new` | Function | Create new UV project + venv + activate |
| `uv-venv` | Function | Create and activate venv in current dir |
| `uv-add` | `uv add` | Add dependency to project |
| `uv-sync` | `uv sync` | Sync dependencies from pyproject.toml |
| `uv-run` | `uv run` | Run command in UV environment |

**Functions:**

**Create New UV Project:**

```bash
uv-new myproject
# Creates:
#   ~/Dev/myproject/
#   ├── pyproject.toml
#   ├── .venv/
#   └── src/
# Auto-activates .venv
# Opens VS Code
```

**What it does:**
1. Creates project directory in `~/Dev/myproject`
2. Initializes UV project with `uv init`
3. Creates virtual environment with `uv venv`
4. Activates the environment
5. Opens VS Code

**Create Venv in Current Directory:**

```bash
cd existing-project
uv-venv
# Creates .venv and activates it
```

**Configuration:**

**Environment Variables:**
```bash
UV_PYTHON_PREFERENCE="only-managed"  # Only use UV-managed Python versions
```

**UV Workflow Example:**

```bash
# Start new project
uv-new my-api
# Creates project, venv, activates

# Add dependencies
uv-add fastapi uvicorn pydantic

# Add dev dependencies
uv-add --dev pytest ruff

# Sync dependencies
uv-sync

# Run application
uv-run python src/main.py

# Or just use python (venv is active)
python src/main.py
```

**UV vs pip:**

```bash
# OLD WAY (pip)
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt  # Slow!

# NEW WAY (UV)
uv-venv                           # Fast!
uv-sync                           # 10-100x faster
```

---

### Micromamba - Conda Environment Manager

Micromamba is a fast, minimal conda implementation. Great for data science and ML.

**Installation:**

**Installed via Homebrew** (Nix build broken):
```bash
brew install micromamba
```

**Convenience Functions & Aliases:**

| Function/Alias | Command | Description |
|----------------|---------|-------------|
| `act <env>` | `micromamba activate <env>` | Activate environment |
| `deact` | `micromamba deactivate` | Deactivate environment |
| `mkenv <name> [ver] [pkgs]` | `micromamba create ...` | Create environment (defaults to Python 3.12) |
| `rmenv <env>` | `micromamba env remove -n <env>` | Remove environment |
| `list-envs` | `micromamba env list` | List all environments |
| `lsenv` | `micromamba env list` | List all environments (short) |
| `condalist` | `conda env list` | List conda environments |
| `mambalist` | `mamba env list` | List mamba environments |

**Configuration:**

**~/.condarc** (managed by Nix):
```yaml
channels:
  - conda-forge
  - defaults
channel_priority: flexible
auto_activate_base: false
show_channel_urls: true
```

**Environment Variables:**

```bash
MAMBA_EXE=/opt/homebrew/bin/micromamba
MAMBA_ROOT_PREFIX=~/micromamba
```

**Common Workflows:**

```bash
# Create a new environment
mkenv myenv 3.12          # Create with Python 3.12
mkenv data-science 3.11 pandas numpy  # With packages

# List environments
list-envs  # or: lsenv

# Activate environment
act myenv
# (myenv) appears in prompt

# Install packages in active environment
micromamba install numpy pandas scikit-learn

# Deactivate
deact  # or: micromamba deactivate

# Remove environment
rmenv old-env
```

**When to Use Micromamba vs UV:**

**Use Micromamba for:**
- Data science projects (numpy, pandas, scikit-learn)
- Machine learning (tensorflow, pytorch)
- Multi-language projects (R, Julia, C++)
- Projects with complex binary dependencies

**Use UV for:**
- Modern Python web apps (FastAPI, Django)
- CLI tools
- Pure Python libraries
- When you want maximum speed

---

### Python Tools

**Interactive Tools:**

| Alias | Command | Description |
|-------|---------|-------------|
| `py` | `python` | Python interpreter |
| `ipy` | `ipython` | IPython REPL |
| `jl` | `jupyter lab` | Start Jupyter Lab |
| `jn` | `jupyter notebook` | Start Jupyter Notebook |

**Examples:**

```bash
# Quick Python REPL
py

# Enhanced REPL with autocomplete, syntax highlighting
ipy

# Start Jupyter Lab for notebooks
jl

# Traditional Jupyter Notebook
jn
```

---

### Code Quality Tools

**Ruff - Fast Linter & Formatter**

Ruff is an extremely fast Python linter and formatter written in Rust. Replaces flake8, black, isort, and more.

| Alias | Command | Description |
|-------|---------|-------------|
| `lint` | `ruff check .` | Lint current directory |
| `format` | `ruff format .` | Format code |
| `lint-fix` | `ruff check --fix .` | Lint and auto-fix |

**Examples:**

```bash
# Check code style
lint

# Format all Python files
format

# Lint and auto-fix issues
lint-fix

# Check specific file
ruff check src/main.py

# Format and show what changed
ruff format --diff src/
```

**Ruff Configuration:**

Typically configured in `pyproject.toml`:
```toml
[tool.ruff]
line-length = 100
target-version = "py313"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W"]
ignore = ["E501"]
```

---

### Auto-Activation Feature

**This is the killer feature!**

Virtual environments automatically activate when you `cd` into a project directory.

**How It Works:**

The shell monitors directory changes and looks for:
1. **UV Projects**: `pyproject.toml` + `.venv/`
2. **Standard venvs**: `.venv/`, `venv/`, or `env/` directories

**Supported Directories:**

| Directory | Priority | Description |
|-----------|----------|-------------|
| `.venv` | 1st | Modern standard (UV, venv) |
| `venv` | 2nd | Traditional venv |
| `env` | 3rd | Alternative name |

**Examples:**

```bash
# Navigate to project
cd ~/Dev/myproject
# 🐍 Activated virtual environment: .venv

# The venv is now active!
which python
# /Users/jimmy/Dev/myproject/.venv/bin/python

# Leave directory
cd ..
# (deactivates automatically)

# No need to manually activate/deactivate!
```

**Visual Feedback:**

```bash
# UV project detected
cd myproject
# 🐍 Activated UV virtual environment: .venv

# Standard venv detected
cd legacy-project
# 🐍 Activated virtual environment: venv

# No venv present
cd other-dir
# (no message, no activation)
```

**Activation Priority:**

If multiple venv directories exist (rare), activation priority is:
1. `pyproject.toml` + `.venv` → UV project (highest priority)
2. `.venv` → Modern standard
3. `venv` → Traditional
4. `env` → Alternative

**Manual Activation:**

If you need to manually activate:

```bash
# Standard activation still works
source .venv/bin/activate

# Or use the helper function
activate
# Looks for .venv, venv, or env and activates
```

**Implementation:**

Located in `home/jimmy/shell/zsh.nix:341-381`:

```bash
function auto_activate_venv() {
  # Deactivate any existing virtual environment
  if [ -n "$VIRTUAL_ENV" ]; then
    deactivate 2>/dev/null || true
  fi

  # Check for UV project (pyproject.toml + .venv)
  if [ -f "pyproject.toml" ] && [ -d ".venv" ]; then
    source .venv/bin/activate
    echo "🐍 Activated UV virtual environment: .venv"
    return
  fi

  # Check for .venv, venv, or env
  for venv_dir in .venv venv env; do
    if [ -d "$venv_dir" ]; then
      source "$venv_dir/bin/activate"
      echo "🐍 Activated virtual environment: $venv_dir"
      return
    fi
  done
}

# Hook into directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_activate_venv

# Also check on shell startup
auto_activate_venv
```

---

### Jupyter & IPython

**Jupyter Lab:**

```bash
jl               # Start Jupyter Lab
jl --port 8889   # Use different port
```

**Features:**
- Modern notebook interface
- File browser
- Terminal access
- Multiple notebook tabs
- Extensions support

**Jupyter Notebook:**

```bash
jn               # Start Jupyter Notebook
jn my_notebook.ipynb  # Open specific notebook
```

**Classic notebook interface** - Use if you prefer traditional Jupyter.

**IPython:**

```bash
ipy              # Start IPython REPL
```

**Enhanced Python REPL with:**
- Syntax highlighting
- Tab completion
- Magic commands (`%timeit`, `%run`, etc.)
- Command history
- Inline help with `?`

**IPython Magic Commands:**

```python
%timeit sum(range(100))     # Benchmark code
%run script.py              # Run external script
%load script.py             # Load script into cell
%who                        # List variables
%history                    # Show command history
!ls                         # Run shell commands
```

---

### Learning & Interview Prep

Functions for algorithm practice and system design.

**Algorithm Practice:**

```bash
newalgo two-sum
# Creates:
#   ~/Dev/algorithms/two-sum/
#   ├── solution.py          # Template with test cases
#   ├── test_solution.py     # Pytest setup
#   └── README.md            # Problem description template
# Opens VS Code
```

**Template includes:**
- Problem description format
- Solution skeleton
- Test cases structure
- Complexity analysis section
- Example usage

**System Design Practice:**

```bash
design url-shortener
# Creates:
#   ~/Dev/learning/system-design/url-shortener/
#   ├── README.md            # Full design template
#   ├── architecture.md      # Component details
#   └── diagrams/
#       └── architecture.mmd # Mermaid diagram
# Opens VS Code
```

**Template includes:**
- Functional requirements
- Non-functional requirements
- Scale estimation
- High-level design
- Component design
- Data model
- API design
- Mermaid architecture diagram

**RAG Project Template:**

```bash
newrag my-chatbot
# Creates:
#   ~/Dev/ai-ml/my-chatbot/
#   ├── pyproject.toml       # UV config with RAG deps
#   ├── .venv/               # Created and activated
#   ├── src/main.py          # RAG pipeline skeleton
#   ├── data/                # For datasets
#   ├── notebooks/           # For experiments
#   └── README.md
# Opens VS Code
```

**Includes dependencies:**
- `langchain` - LLM framework
- `chromadb` - Vector database
- `sentence-transformers` - Embeddings
- `openai` - LLM API
- `pytest`, `ipython` - Dev tools

**Algorithm Benchmarking:**

```bash
cd ~/Dev/algorithms/two-sum
bench-algo
# 🔬 Benchmarking solution.py...
# Uses hyperfine for accurate benchmarks
```

**Quick Notes:**

```bash
note "Learned about async/await in Python"
# ✅ Note added to ~/Documents/daily-notes.md
# Format: 2025-01-15 14:30:22: Learned about async/await in Python
```

---

### Environment Info

**Check Current Environment:**

```bash
# Python version
python --version

# Which Python interpreter
which python

# Check if in venv
echo $VIRTUAL_ENV

# Installed packages
pip list

# Check micromamba envs
list-envs
```

**Environment Info Function:**

```bash
pyenv-info
# Displays:
# - Python version
# - Virtual environment status
# - Installed packages count
# - Python executable path
```

---

### Common Workflows

**Start New Python Project (UV):**

```bash
# Create project
uv-new my-api
# Auto-activates .venv, opens VS Code

# Add dependencies
uv-add fastapi uvicorn

# Add dev dependencies
uv-add --dev pytest ruff

# Run app
python src/main.py
```

**Start New Data Science Project (Micromamba):**

```bash
# Create environment
micromamba create -n ds-project python=3.12
micromamba activate ds-project

# Install packages
micromamba install numpy pandas jupyter scikit-learn matplotlib

# Start Jupyter
jl
```

**Code Quality Check:**

```bash
# Lint code
lint

# Format code
format

# Or do both
lint-fix && format
```

**Algorithm Practice Session:**

```bash
# Create new problem
newalgo valid-parentheses

# Solve the problem in solution.py
# ...

# Benchmark solution
bench-algo

# Take notes
note "Solved valid-parentheses using stack approach"
```

---

### Tips & Best Practices

**UV Tips:**

1. **Always use `pyproject.toml`** - UV works best with modern Python projects
2. **Use `uv-sync`** instead of `pip install -r requirements.txt`
3. **Lock dependencies** - UV automatically creates `uv.lock`
4. **Fast installs** - UV caches aggressively, reinstalls are instant

**Micromamba Tips:**

1. **Don't auto-activate base** - Keeps shells clean (`auto_activate_base: false`)
2. **Use environment files** - `environment.yml` for reproducibility
3. **Clean regularly** - `micromamba clean --all`

**Auto-Activation Tips:**

1. **Use `.venv` directory name** - Most common, works with UV, venv, virtualenv
2. **Don't commit .venv** - Add to `.gitignore`
3. **Trust the auto-activation** - No need to manually activate/deactivate
4. **Check activation** - Look for `🐍 Activated...` message when you `cd`

**Code Quality Tips:**

1. **Run `format` before committing** - Keep code consistent
2. **Use `lint-fix`** - Auto-fixes many issues
3. **Configure in `pyproject.toml`** - Project-specific rules
4. **Integrate with VS Code** - Ruff extension available

---

### Troubleshooting (Python)

**Auto-activation not working?**

```bash
# Check if venv exists
ls -la | grep venv

# Manually test function
auto_activate_venv

# Check zsh hooks
echo $chpwd_functions
# Should include: auto_activate_venv
```

**UV not found?**

```bash
# Check installation
which uv

# If missing, rebuild
nix-rebuild
```

**Micromamba not found?**

```bash
# Install via Homebrew
brew install micromamba

# Reload shell
exec zsh
```

**Wrong Python version?**

```bash
# Check which Python
which python

# If in venv, check venv Python
deactivate
which python
# Should be: /nix/store/.../bin/python
```

---

## Node.js Development

### Installation

**Installed via:** `modules/shared/packages.nix`

```nix
environment.systemPackages = with pkgs; [
  nodejs_20
];
```

**Includes:**
- **Node.js 20** - LTS version
- **npm** - Package manager (included)
- No additional configuration needed

---

### Usage

```bash
# Check versions
node --version
# v20.x.x

npm --version
# 10.x.x

# Run JavaScript
node script.js

# Interactive REPL
node
> console.log("Hello")
```

---

### Project Setup

```bash
# Create new project
mkdir my-app
cd my-app
npm init -y

# Install dependencies
npm install express

# Run
node index.js
```

---

### Common Commands

| Command | Description |
|---------|-------------|
| `npm init` | Create package.json |
| `npm install` | Install dependencies |
| `npm install <pkg>` | Add package |
| `npm uninstall <pkg>` | Remove package |
| `npm run <script>` | Run script |
| `npm test` | Run tests |
| `npm start` | Start app |

**Examples:**

```bash
# Initialize project
npm init -y

# Install dependencies
npm install express dotenv

# Install dev dependencies
npm install --save-dev nodemon jest

# Run scripts
npm start
npm test
npm run dev
```

---

## Configuration

### Python Configuration

**Nix Configuration:**

**File:** `home/jimmy/development/python.nix`

```nix
{
  home.packages = with pkgs; [
    python313
    python313Packages.pip
    python313Packages.ipython
    uv
    ruff
  ];

  # Micromamba config
  home.file.".condarc".text = ''
    channels:
      - conda-forge
      - defaults
    channel_priority: flexible
    auto_activate_base: false
    show_channel_urls: true
  '';

  # UV configuration
  home.sessionVariables = {
    UV_PYTHON_PREFERENCE = "only-managed";
  };
}
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix`

**Python aliases** (lines 132-154):
```nix
# Micromamba - Use functions: act, deact, mkenv, rmenv, lsenv
# (See initExtra section for function definitions)

# Virtual environment activation
activate = "source .venv/bin/activate";

# Python tools
py = "python";
ipy = "ipython";
jl = "jupyter lab";
jn = "jupyter notebook";

# UV
uv-add = "uv add";
uv-sync = "uv sync";
uv-run = "uv run";

# Code quality
lint = "ruff check .";
format = "ruff format .";
lint-fix = "ruff check --fix .";

# Environment management
list-envs = "micromamba env list";
```

**Auto-activation function** (lines 341-381) - see [Auto-Activation Feature](#auto-activation-feature)

### Node.js Configuration

Node.js works out of the box. No additional configuration needed.

For more features, consider:
- **pnpm** - Faster package manager
- **yarn** - Alternative package manager
- **nvm** - Node version manager (not needed with Nix)

### Modify Configuration

**Add Python packages:**
```bash
# Edit python.nix
code ~/nix-darwin/home/jimmy/development/python.nix

# Add to home.packages
# Rebuild
nix-rebuild
```

**Add Python aliases:**
```bash
# Edit zsh.nix
code ~/nix-darwin/home/jimmy/shell/zsh.nix

# Find PYTHON & UV ALIASES section
# Add your alias
# Rebuild
nix-rebuild
exec zsh
```

**Modify UV settings:**
```bash
# Edit python.nix
# Add to home.sessionVariables
# Rebuild
nix-rebuild
```

---

## Links

**Python:**
- [UV Documentation](https://github.com/astral-sh/uv)
- [Micromamba Documentation](https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [IPython Documentation](https://ipython.readthedocs.io/)
- [Jupyter Documentation](https://jupyter.org/documentation)

**Node.js:**
- [Node.js Documentation](https://nodejs.org/docs/)
- [npm Documentation](https://docs.npmjs.com/)

**Related Documentation:**
- [Shell Reference](shell.md) - All shell aliases and functions
- [VS Code Reference](vscode.md) - Python extension settings
- [Tools Reference](tools.md) - VS Code and development tools
- [Nix Darwin Reference](nix-darwin.md) - System configuration
