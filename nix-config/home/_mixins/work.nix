{ config, pkgs, lib, myLib, ... }:

# Work Configuration
#
# Work machine-specific configuration (MACHINE_MODE="work").
# Includes AWS helpers, database connectors, project shortcuts, and curated tool menus
# for data engineering, cloud architecture, AI/ML, and system design.
# Commented sections are work-related tools for enterprise projects.

{
  # AWS CLI configuration with corporate CA bundle
  programs.aws = {
    caBundle = "~/.config/certs/cacert.pem";
  };

  # Work-specific packages moved to _profiles/work/packages.nix
  # This keeps mixins focused on behavior (functions, aliases, env vars)
  # and profiles focused on packages (tools, CLI utilities)

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
    # Project directory shortcuts - DEPRECATED: Use zoxide (z <project>)
  };

  # Work-specific shell functions
  programs.zsh.initContent = ''
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
    # AWS HELPER FUNCTIONS
    # ==================================================
    # AWS functions read from ~/.aws/accounts.json for project configuration.
    #
    # Usage:
    #   awsuse <project|alias> <env> [role]
    #   awslogin <project|alias> <env> [role]
    #   awswho, awslist, awswhere, awscheck
    #
    # Examples:
    #   awsuse ti sbx                # tririga-integrations sbx (support role)
    #   awsuse ti sbx developer      # tririga-integrations sbx (developer role)
    #   awslogin ps dev              # paging-solution dev + SSO login
    #
    # Generated aliases from accounts.json:
    #   tidev, tisbx, tiqa, tiprod, tidev-developer, tisbx-developer, etc.

    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}
    ${myLib.aws.mkAwsSearchCommands}
    ${myLib.aws.mkAwsProfileAutoRestore}

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
