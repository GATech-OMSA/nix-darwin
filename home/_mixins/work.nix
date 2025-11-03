{ config, pkgs, lib, ... }:

{
  # Work machine-specific configuration

  # Work-specific packages
  home.packages = with pkgs; [
    # Add work-specific tools here
  ];

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "work";
    # AWS_PROFILE - Set dynamically using awsuse or awslogin commands
    # Example: awsuse project1-dev

    # ODBC Configuration
    ODBCSYSINI = "/usr/local/etc";
    ODBCINI = "/usr/local/etc/odbc.ini";
  };

  # Work-specific shell aliases
  programs.zsh.shellAliases = {
    # Project directory shortcuts
    scst = "cd ~/Dev/scst";
    ti = "cd ~/Dev/tririga";
    ps-proj = "cd ~/Dev/paging-solution";
    mp = "cd ~/Dev/misc-projects";
    wfhub = "cd ~/Dev/workforce-hub";
    ap = "cd ~/Dev/webMethods/api";
    deploys = "cd ~/Dev/production-deploys";
  };

  # Work-specific shell functions
  programs.zsh.initExtra = ''
    # HRStringCrypter helper
    function crypter() {
      if command -v micromamba &> /dev/null && command -v python &> /dev/null; then
        # Use system Python or activate an environment first with: act <env-name>
        python ~/Dev/misc-projects/HRStringCrypter/run-crypter.py
      else
        echo "❌ Error: Python or micromamba not found"
        echo "Please ensure Python is available (system or activate micromamba environment)"
        return 1
      fi
    }
  '';
}
