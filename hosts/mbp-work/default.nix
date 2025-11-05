{ config, pkgs, username, hostname, ... }:

{
  # Host-specific configuration for work MacBook M3
  networking = {
    hostName = hostname;
    computerName = "Work MacBook Pro";
    localHostName = hostname;
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Set primary user
  system.primaryUser = username;

  # Homebrew configuration for work Mac
  # Allow toggle: true to use Homebrew, false to disable
  homebrew.enable = false;

  # ============================================
  # SECRETS MANAGEMENT (sops-nix)
  # ============================================
  # Secrets are encrypted in hosts/mbp-work/secrets.yaml
  # To edit secrets: edit-secrets (uses your age key)
  # Secrets auto-decrypt on rebuild and are placed in /run/secrets/

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    secrets = {
      # SSH Keys
      work_ssh_private_key = {
        path = "/Users/${username}/.ssh/id_ed25519_work";
        owner = username;
        mode = "0600";
      };

      work_ssh_public_key = {
        path = "/Users/${username}/.ssh/id_ed25519_work.pub";
        owner = username;
        mode = "0644";
      };

      # Database Credentials - Multi-Environment
      # Pattern: ~/.db/{database_type}/{environment}
      # Environments: prod, dev, qa, test

      # PRODUCTION Databases
      oracle_prod_connection = {
        path = "/Users/${username}/.db/oracle/prod";
        owner = username;
        mode = "0600";
      };

      mssql_prod_connection = {
        path = "/Users/${username}/.db/mssql/prod";
        owner = username;
        mode = "0600";
      };

      postgres_prod_connection = {
        path = "/Users/${username}/.db/postgres/prod";
        owner = username;
        mode = "0600";
      };

      oracle_ps_prod_connection = {
        path = "/Users/${username}/.db/oracle-ps/prod";
        owner = username;
        mode = "0600";
      };

      ods_prod_connection = {
        path = "/Users/${username}/.db/ods/prod";
        owner = username;
        mode = "0600";
      };

      dw_prod_connection = {
        path = "/Users/${username}/.db/dw/prod";
        owner = username;
        mode = "0600";
      };

      # DEVELOPMENT Databases
      oracle_dev_connection = {
        path = "/Users/${username}/.db/oracle/dev";
        owner = username;
        mode = "0600";
      };

      mssql_dev_connection = {
        path = "/Users/${username}/.db/mssql/dev";
        owner = username;
        mode = "0600";
      };

      postgres_dev_connection = {
        path = "/Users/${username}/.db/postgres/dev";
        owner = username;
        mode = "0600";
      };

      oracle_ps_dev_connection = {
        path = "/Users/${username}/.db/oracle-ps/dev";
        owner = username;
        mode = "0600";
      };

      ods_dev_connection = {
        path = "/Users/${username}/.db/ods/dev";
        owner = username;
        mode = "0600";
      };

      dw_dev_connection = {
        path = "/Users/${username}/.db/dw/dev";
        owner = username;
        mode = "0600";
      };

      # QA Databases
      oracle_qa_connection = {
        path = "/Users/${username}/.db/oracle/qa";
        owner = username;
        mode = "0600";
      };

      mssql_qa_connection = {
        path = "/Users/${username}/.db/mssql/qa";
        owner = username;
        mode = "0600";
      };

      postgres_qa_connection = {
        path = "/Users/${username}/.db/postgres/qa";
        owner = username;
        mode = "0600";
      };

      oracle_ps_qa_connection = {
        path = "/Users/${username}/.db/oracle-ps/qa";
        owner = username;
        mode = "0600";
      };

      ods_qa_connection = {
        path = "/Users/${username}/.db/ods/qa";
        owner = username;
        mode = "0600";
      };

      dw_qa_connection = {
        path = "/Users/${username}/.db/dw/qa";
        owner = username;
        mode = "0600";
      };

      # TEST Databases
      oracle_test_connection = {
        path = "/Users/${username}/.db/oracle/test";
        owner = username;
        mode = "0600";
      };

      mssql_test_connection = {
        path = "/Users/${username}/.db/mssql/test";
        owner = username;
        mode = "0600";
      };

      postgres_test_connection = {
        path = "/Users/${username}/.db/postgres/test";
        owner = username;
        mode = "0600";
      };

      oracle_ps_test_connection = {
        path = "/Users/${username}/.db/oracle-ps/test";
        owner = username;
        mode = "0600";
      };

      ods_test_connection = {
        path = "/Users/${username}/.db/ods/test";
        owner = username;
        mode = "0600";
      };

      dw_test_connection = {
        path = "/Users/${username}/.db/dw/test";
        owner = username;
        mode = "0600";
      };

      # API Tokens
      git_token = {
        path = "/Users/${username}/.tokens/git_token";
        owner = username;
        mode = "0600";
      };

      hcp_terraform_token = {
        path = "/Users/${username}/.tokens/hcp_terraform_token";
        owner = username;
        mode = "0600";
      };

      jira_api_token = {
        path = "/Users/${username}/.tokens/jira_api_token";
        owner = username;
        mode = "0600";
      };

      # Additional secrets (add as needed)
      confluence_token = {
        path = "/Users/${username}/.tokens/confluence_token";
        owner = username;
        mode = "0600";
      };

      servicenow_credentials = {
        path = "/Users/${username}/.credentials/servicenow";
        owner = username;
        mode = "0600";
      };

      vpn_credentials = {
        path = "/Users/${username}/.credentials/vpn";
        owner = username;
        mode = "0600";
      };
    };
  };

  # System state version
  system.stateVersion = 5;
}
