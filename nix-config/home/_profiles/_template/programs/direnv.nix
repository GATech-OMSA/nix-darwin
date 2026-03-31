{ config, pkgs, lib, ... }:

{
  # direnv configuration with nix-direnv
  # Essential for fast Nix development workflows

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # nix-direnv: 20x faster than regular direnv!
    nix-direnv.enable = true;
  };

  # direnv configuration file
  home.file.".config/direnv/direnv.toml".text = ''
    [global]
    # Supply chain protection: don't auto-load .env files from cloned repos
    load_dotenv = false
    strict_env = true

    # No blanket whitelist — run `direnv allow` per-project after reviewing .envrc
    # This prevents malicious repos from auto-executing code on cd
  '';

  # Custom direnv layouts for Python development
  # Provides: use uv, use venv
  home.file.".config/direnv/direnvrc".text = ''
    # use uv - Create and activate UV virtual environment
    # Usage in .envrc:
    #   use uv              # Uses default Python
    #   use uv 3.12         # Uses Python 3.12
    use_uv() {
      local python_version="''${1:-}"

      # Create .venv if it doesn't exist
      if [[ ! -d .venv ]]; then
        if [[ -n "$python_version" ]]; then
          log_status "Creating .venv with Python $python_version"
          uv venv --python "$python_version"
        else
          log_status "Creating .venv"
          uv venv
        fi
      fi

      # Activate the venv
      source .venv/bin/activate

      # Install dependencies if pyproject.toml exists
      if [[ -f pyproject.toml ]]; then
        log_status "Syncing dependencies from pyproject.toml"
        uv sync --quiet
      fi
    }

    # use venv - Activate existing virtual environment
    # Usage in .envrc:
    #   use venv            # Looks for .venv or venv
    #   use venv myenv      # Uses specific directory
    use_venv() {
      local venv_path="''${1:-.venv}"

      if [[ -d "$venv_path" ]]; then
        source "$venv_path/bin/activate"
      elif [[ -d "venv" ]]; then
        source venv/bin/activate
      else
        log_error "No virtual environment found"
        return 1
      fi
    }
  '';
}
