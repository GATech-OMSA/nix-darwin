# Centralized Secret Path Registry
#
# Single source of truth for all credential and secret file locations.
# Used by:
# - Git hooks (pre-commit, pre-push)
# - Validation scripts
# - Backup/restore scripts
# - Security audits
#
# This registry ensures consistent security checks across the codebase.

{ lib }:

let
  # Base paths for secret directories
  homeDir = "\${HOME}";

  # Individual credential files
  individualFiles = [
    "${homeDir}/.aws/credentials"
    "${homeDir}/.secrets/credentials.env"
    "${homeDir}/.secrets/credentials.env.enc"
  ];

  # SSH keys (both personal and work)
  sshFiles = [
    "${homeDir}/.ssh/id_ed25519"
    "${homeDir}/.ssh/id_ed25519.pub"
    "${homeDir}/.ssh/id_ed25519_work"
    "${homeDir}/.ssh/id_ed25519_work.pub"
    "${homeDir}/.ssh/known_hosts"
  ];

  # Database connection files (pattern: ~/.db/{database_type}/{environment})
  databaseFiles = [
    # Oracle
    "${homeDir}/.db/oracle/prod"
    "${homeDir}/.db/oracle/dev"
    "${homeDir}/.db/oracle/qa"
    "${homeDir}/.db/oracle/test"

    # MSSQL
    "${homeDir}/.db/mssql/prod"
    "${homeDir}/.db/mssql/dev"
    "${homeDir}/.db/mssql/qa"
    "${homeDir}/.db/mssql/test"

    # PostgreSQL
    "${homeDir}/.db/postgres/prod"
    "${homeDir}/.db/postgres/dev"
    "${homeDir}/.db/postgres/qa"
    "${homeDir}/.db/postgres/test"

    # Oracle PS
    "${homeDir}/.db/oracle-ps/prod"
    "${homeDir}/.db/oracle-ps/dev"
    "${homeDir}/.db/oracle-ps/qa"
    "${homeDir}/.db/oracle-ps/test"

    # ODS
    "${homeDir}/.db/ods/prod"
    "${homeDir}/.db/ods/dev"
    "${homeDir}/.db/ods/qa"
    "${homeDir}/.db/ods/test"

    # DW
    "${homeDir}/.db/dw/prod"
    "${homeDir}/.db/dw/dev"
    "${homeDir}/.db/dw/qa"
    "${homeDir}/.db/dw/test"
  ];

  # API tokens and service credentials
  tokenFiles = [
    "${homeDir}/.tokens/git_token"
    "${homeDir}/.tokens/hcp_terraform_token"
    "${homeDir}/.tokens/jira_api_token"
    "${homeDir}/.tokens/confluence_token"
  ];

  # Service credentials
  credentialFiles = [
    "${homeDir}/.credentials/servicenow"
    "${homeDir}/.credentials/vpn"
  ];

  # AWS-specific files
  awsFiles = [
    "${homeDir}/.aws/credentials"
    "${homeDir}/.aws/config"
    "${homeDir}/.aws/accounts.json"
    "${homeDir}/.aws/.last_profile"
  ];

  # Glob patterns for directory-based secrets
  # Used in git hooks and validation scripts
  secretPatterns = [
    "${homeDir}/.db/*"
    "${homeDir}/.tokens/*"
    "${homeDir}/.credentials/*"
    "${homeDir}/.secrets/*"
  ];

  # Repository-specific secret paths (relative to repo root)
  repoSecrets = [
    "user-data/secrets/*"
    "hosts/*/secrets.yaml"
  ];

  # Organized by type (for selective access)
  secretsByType = {
    aws = awsFiles;
    database = databaseFiles;
    tokens = tokenFiles;
    ssh = sshFiles;
    credentials = credentialFiles;
    general = individualFiles;
  };

in {
  # Flat list of all secret paths (for simple iteration)
  secretPaths = lib.lists.unique (
    individualFiles
    ++ sshFiles
    ++ databaseFiles
    ++ tokenFiles
    ++ credentialFiles
    ++ awsFiles
  );

  # Organized by type (for selective access)
  inherit secretsByType;

  # Glob patterns for directory-based validation
  secretGlobPatterns = secretPatterns;

  # Repository-specific paths (not absolute paths)
  repositorySecrets = repoSecrets;

  # Helper functions
  helpers = {
    # Get all paths as a flat list
    getAllPaths = lib.lists.unique (
      individualFiles
      ++ sshFiles
      ++ databaseFiles
      ++ tokenFiles
      ++ credentialFiles
      ++ awsFiles
    );

    # Get paths by type
    getPathsByType = type: secretsByType.${type} or [];

    # Get all types
    getAllTypes = builtins.attrNames secretsByType;

    # Validate no duplicates (called during build)
    validateNoDuplicates = let
      allPaths = individualFiles ++ sshFiles ++ databaseFiles ++ tokenFiles ++ credentialFiles ++ awsFiles;
      uniquePaths = lib.lists.unique allPaths;
    in
      if builtins.length allPaths != builtins.length uniquePaths
      then throw "ERROR: Duplicate paths found in secrets registry!"
      else true;

    # Get count by type
    getCountByType = type: builtins.length (secretsByType.${type} or []);

    # Get total count
    getTotalCount = builtins.length (lib.lists.unique (
      individualFiles
      ++ sshFiles
      ++ databaseFiles
      ++ tokenFiles
      ++ credentialFiles
      ++ awsFiles
    ));
  };

  # Statistics
  stats = {
    totalPaths = builtins.length (lib.lists.unique (
      individualFiles
      ++ sshFiles
      ++ databaseFiles
      ++ tokenFiles
      ++ credentialFiles
      ++ awsFiles
    ));

    byType = builtins.mapAttrs (name: paths: builtins.length paths) secretsByType;

    totalPatterns = builtins.length secretPatterns;
    totalRepoSecrets = builtins.length repoSecrets;
  };

  # Metadata
  meta = {
    description = "Centralized secret path registry";
    maintainer = "jimmy";
    version = "1.0.0";
    lastUpdated = "2025-11-06";
  };
}
