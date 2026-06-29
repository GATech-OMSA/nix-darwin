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
