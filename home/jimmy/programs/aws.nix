{ config, pkgs, lib, hostname, myLib, ... }:

let
  # Personal machine AWS config
  personalConfig = ''
    [default]
    region = us-east-1
    output = json

    [profile personal]
    region = us-east-1
    output = json
    # Add IAM-based configuration here
    # For credentials, use ~/.zsh_secrets or AWS CLI:
    #   aws configure --profile personal

    # Example: Additional personal profiles
    # [profile personal-dev]
    # region = us-east-1
    # output = json

    # [profile personal-prod]
    # region = us-east-1
    # output = json
  '';

  # Work machine AWS config (AWS SSO)
  workConfig = ''
    [default]
    region = us-east-1
    output = json

    # SSO Session Configuration
    [sso-session work-session]
    sso_start_url = https://work-domain.awsapps.com/start
    sso_region = us-east-1
    sso_registration_scopes = sso:account:access

    # ============================================
    # SSO Profiles - Add your actual profiles here
    # Format: [profile project-env]
    # ============================================

    # Example Profile 1 (replace with your actual profile)
    [profile project1-dev]
    sso_session = work-session
    sso_account_id = 111111111111
    sso_role_name = Developer
    region = us-east-1
    output = json

    # Example Profile 2 (replace with your actual profile)
    [profile project1-prod]
    sso_session = work-session
    sso_account_id = 111111111111
    sso_role_name = ReadOnly
    region = us-east-1
    output = json

    # Example Profile 3 (replace with your actual profile)
    [profile project2-dev]
    sso_session = work-session
    sso_account_id = 111111111111
    sso_role_name = Developer
    region = us-east-1
    output = json

    # Add more profiles following the same pattern:
    # [profile <project>-<env>]
    # sso_session = work-session
    # sso_account_id = <ACCOUNT_ID>
    # sso_role_name = <ROLE_NAME>
    # region = us-east-1
    # output = json
  '';
in
{
  # AWS CLI configuration - Declarative management
  # Manages ~/.aws/config (NOT credentials - those stay in ~/.zsh_secrets)

  # AWS config file - select based on machine type
  home.file.".aws/config".text = myLib.selectByMachine hostname {
    personal = personalConfig;
    work = workConfig;
  };

  # Note: AWS credentials should NEVER be in Nix
  # Personal machine: Use ~/.zsh_secrets or `aws configure`
  # Work machine: Use AWS SSO (`aws sso login --profile work-domain`)
  #
  # To configure:
  # 1. Personal: `aws configure --profile personal` then add to ~/.zsh_secrets:
  #    export AWS_ACCESS_KEY_ID="..."
  #    export AWS_SECRET_ACCESS_KEY="..."
  #
  # 2. Work: Update SSO URLs/IDs above, then run:
  #    aws sso login --profile work-domain
}
