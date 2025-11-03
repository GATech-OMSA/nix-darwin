{ config, pkgs, lib, ... }:

{
  # Work machine-specific configuration

  # Work-specific packages
  home.packages = with pkgs; [
    # ODBC drivers and database clients
    unixODBC           # ODBC driver manager
    freetds            # ODBC for SQL Server
    postgresql_16      # PostgreSQL client + libpq

    # Database CLI tools
    pgcli              # PostgreSQL CLI with auto-completion
    # mycli            # MySQL/MariaDB CLI (uncomment if needed)
  ];

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "work";
    # AWS_PROFILE - Auto-restored from ~/.aws/.last_profile on shell start
    # Managed by: awsuse <project> <env> [role]
    # Examples:
    #   awsuse tririga-integrations dev
    #   awsuse ti sbx developer
    #   awslogin hr qa

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

    # ==================================================
    # AWS UNIVERSAL COMMAND SYSTEM
    # ==================================================
    # Pattern: awsuse <project> <env> [role]
    # Examples:
    #   awsuse tririga-integrations dev        → ti-dev-support
    #   awsuse ti sbx developer                → ti-sbx-developer
    #   awslogin hr qa                         → hr-qa-support + SSO login
    #
    # Commands: awsuse, awslogin, awswho, awslist
    # Profile auto-restores on shell start from ~/.aws/.last_profile

    ${myLib.aws.mkAwsUniversalCommand {
      projects = [
        {
          name = "tririga-integrations";
          short = "ti";
          environments = [ "dev" "sbx" "qa" "prod" ];
          roles = [ "support" "developer" "data-engineer" ];
        }
        {
          name = "hr-system";
          short = "hr";
          environments = [ "qa" "prod" ];
          roles = [ "support" "data-engineer" ];
        }
        {
          name = "workforce-hub";
          short = "wfh";
          environments = [ "dev" "sbx" "qa" "prod" ];
          roles = [ "support" "developer" ];
        }
        # Add more projects as needed:
        # {
        #   name = "project-name";
        #   short = "proj";
        #   environments = [ "dev" "qa" "prod" ];
        #   roles = [ "support" ];
        # }
      ];
    }}

    ${myLib.aws.mkAwsSsoLogin {
      projects = [
        {
          name = "tririga-integrations";
          short = "ti";
          environments = [ "dev" "sbx" "qa" "prod" ];
          roles = [ "support" "developer" "data-engineer" ];
        }
        {
          name = "hr-system";
          short = "hr";
          environments = [ "qa" "prod" ];
          roles = [ "support" "data-engineer" ];
        }
        {
          name = "workforce-hub";
          short = "wfh";
          environments = [ "dev" "sbx" "qa" "prod" ];
          roles = [ "support" "developer" ];
        }
      ];
    }}

    ${myLib.aws.mkAwsInfoCommands}

    # ==================================================
    # DATABASE INSTANCE CONNECTORS (Environment Variables)
    # ==================================================
    # Pattern: dbconnect-<instance> <env>
    # Examples:
    #   dbconnect-ti dev         → Tririga Oracle (dev)
    #   dbconnect-hrdb prod      → HR SQL Server (prod)
    #   dbconnect-payroll qa     → Payroll PostgreSQL (qa)
    #
    # Credentials: Loaded from ~/.secrets/credentials.env.enc
    # Rotation: edit-credentials → save → exec zsh (NO nix rebuild!)
    #
    # Required env vars (example for TI prod):
    #   TI_PROD_USERNAME, TI_PROD_PASSWORD, TI_PROD_HOST,
    #   TI_PROD_PORT, TI_PROD_SERVICE

    ${myLib.database.mkDatabaseInstances [
      # Tririga Oracle Database (multiple environments)
      {
        instance = "ti";
        type = "oracle";
        environments = [ "dev" "qa" "prod" ];
        description = "Tririga Oracle Database";
      }

      # HR Database - SQL Server (prod only)
      {
        instance = "hrdb";
        type = "mssql";
        environments = [ "prod" ];
        description = "HR SQL Server Database";
      }

      # PeopleSoft Oracle (dev, qa, prod)
      {
        instance = "ps";
        type = "oracle";
        environments = [ "dev" "qa" "prod" ];
        description = "PeopleSoft Oracle Database";
      }

      # ODS - SQL Server (qa, prod)
      {
        instance = "ods";
        type = "mssql";
        environments = [ "qa" "prod" ];
        description = "Operational Data Store (ODS)";
      }

      # Data Warehouse - SQL Server
      {
        instance = "dw";
        type = "mssql";
        environments = [ "prod" ];
        description = "Data Warehouse";
      }

      # Payroll PostgreSQL (uses LAN credentials)
      {
        instance = "payroll";
        type = "postgres";
        environments = [ "qa" "prod" ];
        description = "Payroll PostgreSQL Database";
      }

      # Add more database instances as needed:
      # {
      #   instance = "your-db-name";
      #   type = "oracle|mssql|postgres|mysql";
      #   environments = [ "dev" "qa" "prod" ];
      #   description = "Your Database Description";
      # }
    ]}

    ${myLib.database.mkInstanceList [
      { instance = "ti"; type = "oracle"; environments = [ "dev" "qa" "prod" ]; description = "Tririga"; }
      { instance = "hrdb"; type = "mssql"; environments = [ "prod" ]; description = "HR Database"; }
      { instance = "ps"; type = "oracle"; environments = [ "dev" "qa" "prod" ]; description = "PeopleSoft"; }
      { instance = "ods"; type = "mssql"; environments = [ "qa" "prod" ]; description = "ODS"; }
      { instance = "dw"; type = "mssql"; environments = [ "prod" ]; description = "Data Warehouse"; }
      { instance = "payroll"; type = "postgres"; environments = [ "qa" "prod" ]; description = "Payroll"; }
    ]}

    # ==================================================
    # TOKEN HELPERS (File-based - kept for tokens)
    # ==================================================
    # Usage: git-token, terraform-token, jira-token
    # Tokens managed via sops-nix in secrets.yaml
    # Includes: File permission validation (600)

    ${myLib.database.mkTokenHelpers [
      {
        name = "git";
        description = "Git token";
        file = "git_token";
      }
      {
        name = "terraform";
        description = "HCP Terraform token";
        file = "hcp_terraform_token";
      }
      {
        name = "jira";
        description = "Jira API token";
        file = "jira_api_token";
      }
    ]}
  '';
}
