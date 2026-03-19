# python.zsh
# Python and Micromamba helper functions
# Extracted from zsh.nix for maintainability

# ============================================
# UV PYTHON HELPERS
# ============================================

function uv-new() {
  if [ -z "$1" ]; then
    echo "Usage: uv-new <project-name>"
    return 1
  fi
  uv init "$1" || return 1
  cd "$1" || { echo "✗ Failed to cd into $1"; return 1; }
  uv venv
  source .venv/bin/activate
  echo "✓ UV project created and activated: $1"
}

function uv-venv() {
  uv venv
  source .venv/bin/activate
  echo "✓ UV virtual environment created and activated"
}

function activate() {
  if [ -f .venv/bin/activate ]; then
    source .venv/bin/activate
    echo "✓ Activated .venv"
  elif [ -f venv/bin/activate ]; then
    source venv/bin/activate
    echo "✓ Activated venv"
  else
    echo "✗ No virtual environment found in current directory"
  fi
}

# ============================================
# MICROMAMBA CONVENIENCE FUNCTIONS
# ============================================

# Activate micromamba environment
function m-act() {
  if [ -z "$1" ]; then
    echo "Usage: m-act <environment-name>"
    echo ""
    echo "Available environments:"
    micromamba env list
  else
    micromamba activate "$1"
  fi
}

# Deactivate micromamba environment
function m-deact() {
  micromamba deactivate
}

# Create micromamba environment
# Usage: m-mkenv <name> [python-version] [packages...]
# Examples:
#   m-mkenv myenv                    # Python 3.13 (default)
#   m-mkenv myenv 3.12               # Python 3.12
#   m-mkenv myenv 3.13 pandas numpy  # With packages
function m-mkenv() {
  if [ -z "$1" ]; then
    echo "Usage: m-mkenv <name> [python-version] [packages...]"
    echo ""
    echo "Examples:"
    echo "  m-mkenv myenv                    # Python 3.13 (default)"
    echo "  m-mkenv myenv 3.12               # Python 3.12"
    echo "  m-mkenv myenv 3.13 pandas numpy  # With packages"
    return 1
  fi

  local name="$1"
  local python_version="3.13"
  local packages=""

  # Check if second argument is a Python version (starts with 3.)
  if [ -n "$2" ] && [[ "$2" =~ ^3\.[0-9]+$ ]]; then
    python_version="$2"
    shift 2
    packages="$@"
  else
    shift
    packages="$@"
  fi

  echo "Creating environment '$name' with Python $python_version..."
  if [ -n "$packages" ]; then
    echo "Installing packages: $packages"
    micromamba create -n "$name" python="$python_version" ${=packages} -y
  else
    micromamba create -n "$name" python="$python_version" -y
  fi
}

# Remove micromamba environment
function m-rmenv() {
  if [ -z "$1" ]; then
    echo "Usage: m-rmenv <environment-name>"
    echo ""
    echo "Available environments:"
    micromamba env list
  else
    echo "Removing environment '$1'..."
    micromamba env remove -n "$1" -y
  fi
}

# ============================================
# PYTHON ENVIRONMENT INFO
# ============================================

function pyenv-info() {
  echo "→ Python Environment Information"
  echo "=================================="

  if [ -n "$VIRTUAL_ENV" ]; then
    echo "Virtual Env: $VIRTUAL_ENV"
  elif [ -n "$CONDA_PREFIX" ]; then
    echo "Conda Env: $CONDA_PREFIX"
  else
    echo "No virtual environment active"
  fi
  echo ""

  echo "Python: $(which python 2>/dev/null || echo 'not found')"
  command -v python &>/dev/null && python --version
  echo ""

  echo "pip: $(which pip 2>/dev/null || echo 'not found')"
  command -v pip &>/dev/null && pip --version
  echo ""

  echo "UV: $(which uv 2>/dev/null || echo 'not found')"
  command -v uv &>/dev/null && uv --version
}
