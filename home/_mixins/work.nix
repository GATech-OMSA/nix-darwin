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

    # Quick access to last-used profile
    awslast = "export AWS_PROFILE=$(cat ~/.aws/.last_profile 2>/dev/null || echo 'default') && echo '🔄 Restored AWS profile:' $AWS_PROFILE";
  } // (myLib.aws.mkAwsProfileAliases {
    # AWS SSO - Quick profile switching (generated)
    # Pattern: tririga-integrations-{env}
    project = "tririga-integrations";
    environments = [ "dev" "sbx" "qa" "prod" ];
  });

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
    # DATABASE CONNECTION HELPERS (Generated)
    # ==================================================
    # Pattern: ~/.db/{database_type}/{environment}
    # Usage: dbconnect-oracle prod|dev|qa|test
    # Available: dbconnect-{oracle|mssql|postgres|oracle-ps|ods|dw}
    # Includes: File permission validation (600)

    ${myLib.database.mkDatabaseConnectors [
      {
        name = "oracle";
        command = "sqlplus \${USERNAME}/\${PASSWORD}@\${HOST}:\${PORT}/\${SERVICE_NAME}";
        description = "Oracle";
      }
      {
        name = "mssql";
        command = "sqlcmd -S \${SERVER} -d \${DATABASE} -U \${USERNAME} -P \${PASSWORD}";
        description = "SQL Server";
      }
      {
        name = "postgres";
        command = "PGPASSWORD=\${PASSWORD} psql -h \${HOST} -p \${PORT} -U \${USERNAME} -d \${DATABASE}";
        description = "PostgreSQL";
      }
      {
        name = "oracle-ps";
        command = "sqlplus \${USERNAME}/\${PASSWORD}@\${HOST}:\${PORT}/\${SERVICE_NAME}";
        description = "Oracle PeopleSoft";
      }
      {
        name = "ods";
        command = "sqlcmd -S \${SERVER} -d \${DATABASE} -U \${USERNAME} -P \${PASSWORD}";
        description = "ODS";
      }
      {
        name = "dw";
        command = "sqlcmd -S \${SERVER} -d \${DATABASE} -U \${USERNAME} -P \${PASSWORD}";
        description = "Data Warehouse";
      }
    ]}

    ${myLib.database.mkDatabaseList [
      { name = "oracle"; label = "Oracle"; }
      { name = "mssql"; label = "SQL Server"; }
      { name = "postgres"; label = "PostgreSQL"; }
      { name = "oracle-ps"; label = "Oracle PeopleSoft"; }
      { name = "ods"; label = "ODS"; }
      { name = "dw"; label = "Data Warehouse"; }
    ]}

    # ==================================================
    # TOKEN HELPERS (Generated)
    # ==================================================
    # Usage: git-token, terraform-token, jira-token
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
