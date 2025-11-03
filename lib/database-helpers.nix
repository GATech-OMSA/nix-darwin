{ lib }:

rec {
  # ==================================================
  # DATABASE CONNECTOR GENERATOR
  # ==================================================
  # Generate database connection function with validation
  #
  # Usage:
  #   mkDatabaseConnector {
  #     name = "oracle";
  #     command = "sqlplus \${USERNAME}/\${PASSWORD}@\${HOST}:\${PORT}/\${SERVICE_NAME}";
  #     description = "Oracle";
  #   }
  #
  # Generated function: dbconnect-oracle [environment]
  # Default environment: prod
  # Available environments: prod, dev, qa, test
  #
  mkDatabaseConnector = { name, command, description }:
    ''
      function dbconnect-${name}() {
        local env="''${1:-prod}"
        local conn_file="$HOME/.db/${name}/''${env}"

        if [ -f "''${conn_file}" ]; then
          # Validate file permissions (should be 600 for security)
          local perms=$(stat -f "%Lp" "''${conn_file}" 2>/dev/null || echo "000")
          if [ "$perms" != "600" ]; then
            echo "⚠️  WARNING: Insecure permissions on ''${conn_file} (current: $perms, expected: 600)"
            echo "   Fix: chmod 600 ''${conn_file}"
            echo ""
          fi

          # Source connection file and connect
          source "''${conn_file}"
          echo "🔌 Connecting to ${description} (''${env})..."
          ${command}
        else
          echo "❌ Error: ${description} connection file not found for environment: ''${env}"
          echo "Expected: ''${conn_file}"
          echo "Available environments: prod, dev, qa, test"
          return 1
        fi
      }
    '';

  # ==================================================
  # MULTIPLE DATABASE CONNECTORS
  # ==================================================
  # Generate multiple database connector functions at once
  #
  # Usage:
  #   mkDatabaseConnectors [
  #     { name = "oracle"; command = "..."; description = "Oracle"; }
  #     { name = "mssql"; command = "..."; description = "SQL Server"; }
  #   ]
  #
  mkDatabaseConnectors = connectors:
    lib.concatMapStringsSep "\n\n" mkDatabaseConnector connectors;

  # ==================================================
  # DATABASE LIST FUNCTION
  # ==================================================
  # Generate dblist function to show all configured databases
  #
  # Usage:
  #   mkDatabaseList [
  #     { name = "oracle"; label = "Oracle"; }
  #     { name = "mssql"; label = "SQL Server"; }
  #   ]
  #
  # Generated function: dblist
  #
  mkDatabaseList = databases:
    ''
      function dblist() {
        echo "📊 Available Database Connections:"
        echo ""
        ${lib.concatMapStringsSep "\n" (db: ''
          echo "${db.label}:"
          ls -1 ~/.db/${db.name}/ 2>/dev/null | sed 's/^/  - ${db.name} /' || echo "  (none configured)"
          echo ""
        '') databases}
        echo "Usage: dbconnect-{type} {environment}"
        echo "Example: dbconnect-oracle dev"
        echo "Example: dbconnect-mssql qa"
      }
    '';

  # ==================================================
  # TOKEN HELPER GENERATOR
  # ==================================================
  # Generate token helper function that copies token to clipboard
  #
  # Usage:
  #   mkTokenHelper {
  #     name = "git";
  #     description = "Git token";
  #     file = "git_token";
  #   }
  #
  # Generated function: git-token
  #
  mkTokenHelper = { name, description, file }:
    ''
      function ${name}-token() {
        local token_file="$HOME/.tokens/${file}"

        if [ -f "$token_file" ]; then
          # Validate file permissions (should be 600 for security)
          local perms=$(stat -f "%Lp" "$token_file" 2>/dev/null || echo "000")
          if [ "$perms" != "600" ]; then
            echo "⚠️  WARNING: Insecure permissions on $token_file (current: $perms, expected: 600)"
            echo "   Fix: chmod 600 $token_file"
            echo ""
          fi

          # Copy to clipboard
          cat "$token_file" | pbcopy
          echo "✅ ${description} copied to clipboard"
        else
          echo "❌ Error: ${description} not found"
          echo "Expected: $token_file (from secrets.yaml)"
          return 1
        fi
      }
    '';

  # ==================================================
  # MULTIPLE TOKEN HELPERS
  # ==================================================
  # Generate multiple token helper functions at once
  #
  # Usage:
  #   mkTokenHelpers [
  #     { name = "git"; description = "Git token"; file = "git_token"; }
  #     { name = "terraform"; description = "HCP Terraform token"; file = "hcp_terraform_token"; }
  #   ]
  #
  mkTokenHelpers = helpers:
    lib.concatMapStringsSep "\n\n" mkTokenHelper helpers;

  # ==================================================
  # DATABASE INSTANCE CONNECTOR (Environment Variables)
  # ==================================================
  # Generate instance-based database connector using environment variables
  # instead of credential files. Better for rotating passwords.
  #
  # Variable naming pattern: <INSTANCE>_<ENV>_<TYPE>
  # Example: TI_PROD_USERNAME, TI_PROD_PASSWORD, TI_PROD_HOST
  #
  # Usage:
  #   mkDatabaseInstance {
  #     instance = "ti";                           # Instance name (lowercase)
  #     type = "oracle";                           # oracle, mssql, postgres, mysql
  #     environments = ["dev" "qa" "prod"];       # Available environments
  #     description = "Tririga Oracle Database";
  #   }
  #
  # Generated function: dbconnect-ti [environment]
  # Default environment: prod
  #
  # Required environment variables (example for TI prod Oracle):
  #   TI_PROD_USERNAME, TI_PROD_PASSWORD, TI_PROD_HOST,
  #   TI_PROD_PORT, TI_PROD_SERVICE
  #
  mkDatabaseInstance = { instance, type, environments, description }:
    let
      # Generate environment-specific connection logic
      mkOracleConnect = ''
        local HOST_VAR="''${ENV_PREFIX}_HOST"
        local PORT_VAR="''${ENV_PREFIX}_PORT"
        local SERVICE_VAR="''${ENV_PREFIX}_SERVICE"

        echo "🔌 Connecting to Oracle: ${instance} ($env)"
        sqlplus "''${!USERNAME_VAR}/''${!PASSWORD_VAR}@''${!HOST_VAR}:''${!PORT_VAR}/''${!SERVICE_VAR}"
      '';

      mkMssqlConnect = ''
        local HOST_VAR="''${ENV_PREFIX}_HOST"
        local PORT_VAR="''${ENV_PREFIX}_PORT"
        local DATABASE_VAR="''${ENV_PREFIX}_DATABASE"

        echo "🔌 Connecting to SQL Server: ${instance} ($env)"
        sqlcmd -S "''${!HOST_VAR},''${!PORT_VAR}" -d "''${!DATABASE_VAR}" \
               -U "''${!USERNAME_VAR}" -P "''${!PASSWORD_VAR}"
      '';

      mkPostgresConnect = ''
        local HOST_VAR="''${ENV_PREFIX}_HOST"
        local PORT_VAR="''${ENV_PREFIX}_PORT"
        local DATABASE_VAR="''${ENV_PREFIX}_DATABASE"

        echo "🔌 Connecting to PostgreSQL: ${instance} ($env)"
        PGPASSWORD="''${!PASSWORD_VAR}" psql -h "''${!HOST_VAR}" -p "''${!PORT_VAR}" \
                                            -U "''${!USERNAME_VAR}" -d "''${!DATABASE_VAR}"
      '';

      mkMysqlConnect = ''
        local HOST_VAR="''${ENV_PREFIX}_HOST"
        local PORT_VAR="''${ENV_PREFIX}_PORT"
        local DATABASE_VAR="''${ENV_PREFIX}_DATABASE"

        echo "🔌 Connecting to MySQL: ${instance} ($env)"
        mysql -h "''${!HOST_VAR}" -P "''${!PORT_VAR}" -u "''${!USERNAME_VAR}" \
              -p"''${!PASSWORD_VAR}" "''${!DATABASE_VAR}"
      '';

      connectionLogic =
        if type == "oracle" then mkOracleConnect
        else if type == "mssql" then mkMssqlConnect
        else if type == "postgres" then mkPostgresConnect
        else if type == "mysql" then mkMysqlConnect
        else throw "Unsupported database type: ${type}";

      envList = lib.concatStringsSep ", " environments;
    in
    ''
      function dbconnect-${instance}() {
        local env="''${1:-prod}"

        # Validate environment
        local valid_envs="${envList}"
        if ! echo "$valid_envs" | grep -qw "$env"; then
          echo "❌ Invalid environment: $env"
          echo "Available: $valid_envs"
          return 1
        fi

        # Convert to uppercase for env var lookup
        local ENV_PREFIX="$(echo ${instance} | tr '[:lower:]' '[:upper:]')_$(echo $env | tr '[:lower:]' '[:upper:]')"

        # Check if credentials are loaded
        local USERNAME_VAR="''${ENV_PREFIX}_USERNAME"
        local PASSWORD_VAR="''${ENV_PREFIX}_PASSWORD"

        if [ -z "''${!USERNAME_VAR}" ] || [ -z "''${!PASSWORD_VAR}" ]; then
          echo "❌ Credentials not found for ''${USERNAME_VAR}"
          echo ""
          echo "💡 Required environment variables:"
          echo "   ''${USERNAME_VAR}"
          echo "   ''${PASSWORD_VAR}"
          echo "   ''${ENV_PREFIX}_HOST"
          echo "   ''${ENV_PREFIX}_PORT"
          ${if type == "oracle" then ''
          echo "   ''${ENV_PREFIX}_SERVICE"
          '' else ''
          echo "   ''${ENV_PREFIX}_DATABASE"
          ''}
          echo ""
          echo "💡 Setup instructions:"
          echo "   1. Run: edit-secrets"
          echo "   2. Add required variables (see template in file)"
          echo "   3. Save and exit"
          echo "   4. Run: exec zsh"
          echo "   5. Try connection again"
          return 1
        fi

        # Connect to database
        ${connectionLogic}
      }
    '';

  # ==================================================
  # MULTIPLE DATABASE INSTANCES
  # ==================================================
  # Generate multiple instance-based database connectors at once
  #
  # Usage:
  #   mkDatabaseInstances [
  #     { instance = "ti"; type = "oracle"; environments = ["dev" "qa" "prod"]; description = "Tririga"; }
  #     { instance = "hrdb"; type = "mssql"; environments = ["prod"]; description = "HR Database"; }
  #   ]
  #
  mkDatabaseInstances = instances:
    lib.concatMapStringsSep "\n\n" mkDatabaseInstance instances;

  # ==================================================
  # INSTANCE LIST FUNCTION
  # ==================================================
  # Generate dblist-instances function to show all configured database instances
  #
  # Usage:
  #   mkInstanceList [
  #     { instance = "ti"; type = "oracle"; environments = ["dev" "qa" "prod"]; description = "Tririga"; }
  #     { instance = "hrdb"; type = "mssql"; environments = ["prod"]; description = "HR DB"; }
  #   ]
  #
  # Generated function: dblist-instances
  #
  mkInstanceList = instances:
    ''
      function dblist-instances() {
        echo "📊 Configured Database Instances:"
        echo ""
        ${lib.concatMapStringsSep "\n" (db: ''
          echo "  ${db.description} (${db.instance}):"
          echo "    Type: ${db.type}"
          echo "    Environments: ${lib.concatStringsSep ", " db.environments}"
          echo "    Command: dbconnect-${db.instance} [${lib.concatStringsSep "|" db.environments}]"
          echo ""
        '') instances}
        echo "💡 Credentials loaded from: ~/.secrets/credentials.env"
        echo "💡 To update credentials: edit-secrets"
      }
    '';
}
