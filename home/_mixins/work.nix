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

    # AWS SSO - Quick profile switching (customize with actual profiles)
    # Pattern: tririga-integrations-{env}
    awsdev = "awsuse tririga-integrations-dev";
    awssbx = "awsuse tririga-integrations-sbx";
    awsqa = "awsuse tririga-integrations-qa";
    awsprod = "awsuse tririga-integrations-prod";

    # Placeholders for additional projects (customize later)
    # awsproject2dev = "awsuse project2-dev";
    # awsproject2prod = "awsuse project2-prod";

    # Quick access to last-used profile
    awslast = "export AWS_PROFILE=$(cat ~/.aws/.last_profile 2>/dev/null || echo 'default') && echo '🔄 Restored AWS profile:' $AWS_PROFILE";
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

    # Database connection helpers - Multi-Environment
    # Pattern: ~/.db/{database_type}/{environment}
    # Usage: dbconnect-oracle prod|dev|qa|test

    function dbconnect-oracle() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/oracle/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to Oracle (''${env})..."
        sqlplus ''${USERNAME}/''${PASSWORD}@''${HOST}:''${PORT}/''${SERVICE_NAME}
      else
        echo "❌ Error: Oracle connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    function dbconnect-mssql() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/mssql/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to SQL Server (''${env})..."
        sqlcmd -S ''${SERVER} -d ''${DATABASE} -U ''${USERNAME} -P ''${PASSWORD}
      else
        echo "❌ Error: SQL Server connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    function dbconnect-postgres() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/postgres/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to PostgreSQL (''${env})..."
        PGPASSWORD=''${PASSWORD} psql -h ''${HOST} -p ''${PORT} -U ''${USERNAME} -d ''${DATABASE}
      else
        echo "❌ Error: PostgreSQL connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    function dbconnect-oracle-ps() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/oracle-ps/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to Oracle PeopleSoft (''${env})..."
        sqlplus ''${USERNAME}/''${PASSWORD}@''${HOST}:''${PORT}/''${SERVICE_NAME}
      else
        echo "❌ Error: Oracle PeopleSoft connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    function dbconnect-ods() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/ods/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to ODS (''${env})..."
        sqlcmd -S ''${SERVER} -d ''${DATABASE} -U ''${USERNAME} -P ''${PASSWORD}
      else
        echo "❌ Error: ODS connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    function dbconnect-dw() {
      local env="''${1:-prod}"
      local conn_file="$HOME/.db/dw/''${env}"

      if [ -f "''${conn_file}" ]; then
        source "''${conn_file}"
        echo "🔌 Connecting to Data Warehouse (''${env})..."
        sqlcmd -S ''${SERVER} -d ''${DATABASE} -U ''${USERNAME} -P ''${PASSWORD}
      else
        echo "❌ Error: Data Warehouse connection file not found for environment: ''${env}"
        echo "Expected: ''${conn_file}"
        echo "Available environments: prod, dev, qa, test"
        return 1
      fi
    }

    # List all available database connections
    function dblist() {
      echo "📊 Available Database Connections:"
      echo ""
      echo "Oracle:"
      ls -1 ~/.db/oracle/ 2>/dev/null | sed 's/^/  - oracle /' || echo "  (none configured)"
      echo ""
      echo "SQL Server:"
      ls -1 ~/.db/mssql/ 2>/dev/null | sed 's/^/  - mssql /' || echo "  (none configured)"
      echo ""
      echo "PostgreSQL:"
      ls -1 ~/.db/postgres/ 2>/dev/null | sed 's/^/  - postgres /' || echo "  (none configured)"
      echo ""
      echo "Oracle PeopleSoft:"
      ls -1 ~/.db/oracle-ps/ 2>/dev/null | sed 's/^/  - oracle-ps /' || echo "  (none configured)"
      echo ""
      echo "ODS:"
      ls -1 ~/.db/ods/ 2>/dev/null | sed 's/^/  - ods /' || echo "  (none configured)"
      echo ""
      echo "Data Warehouse:"
      ls -1 ~/.db/dw/ 2>/dev/null | sed 's/^/  - dw /' || echo "  (none configured)"
      echo ""
      echo "Usage: dbconnect-{type} {environment}"
      echo "Example: dbconnect-oracle dev"
      echo "Example: dbconnect-mssql qa"
    }

    # Token helpers (copy to clipboard)
    function git-token() {
      if [ -f ~/.tokens/git_token ]; then
        cat ~/.tokens/git_token | pbcopy
        echo "✅ Git token copied to clipboard"
      else
        echo "❌ Error: Git token not found"
        echo "Expected: ~/.tokens/git_token (from secrets.yaml)"
        return 1
      fi
    }

    function terraform-token() {
      if [ -f ~/.tokens/hcp_terraform_token ]; then
        cat ~/.tokens/hcp_terraform_token | pbcopy
        echo "✅ HCP Terraform token copied to clipboard"
      else
        echo "❌ Error: HCP Terraform token not found"
        echo "Expected: ~/.tokens/hcp_terraform_token (from secrets.yaml)"
        return 1
      fi
    }

    function jira-token() {
      if [ -f ~/.tokens/jira_api_token ]; then
        cat ~/.tokens/jira_api_token | pbcopy
        echo "✅ Jira API token copied to clipboard"
      else
        echo "❌ Error: Jira API token not found"
        echo "Expected: ~/.tokens/jira_api_token (from secrets.yaml)"
        return 1
      fi
    }
  '';
}
