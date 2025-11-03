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
}
