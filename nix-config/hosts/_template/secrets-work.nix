# secrets-work.nix
#
# Work machine SOPS secret definitions
# These secrets are auto-decrypted on rebuild and placed in specified paths
# Edit secrets with: edit-secrets
#
# NOTE: SOPS installed via bootstrap.sh (nix-env) due to corporate proxy
# blocking Go modules during build-from-source

{ config, pkgs, username, ... }:

{
  sops = {
    # Path to your age key
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    # Default secrets file for this host
    defaultSopsFile = ./secrets.yaml;

    # Define secrets and where they should be placed
    secrets = {
      # SSH Keys (work-specific)
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

      # Additional work-specific secrets
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
}
