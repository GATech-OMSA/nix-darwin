{ config, pkgs, lib, hostname, myLib, ... }:

let
  # CA bundle path for corporate certificates (work machines only)
  # Pass via config.programs.aws.caBundle from work.nix
  caBundle = config.programs.aws.caBundle or null;
  caBundleConfig = if caBundle != null then ''ca-bundle = "${caBundle}"'' else "";

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

  # Generate SSO profiles from accounts.json
  # Supports both string and object account values
  # Creates multiple profiles when additional_roles are specified
  generateSsoProfiles =
    let
      # Read accounts.json from user's home (must exist at runtime)
      # Note: File must be tracked in repo or use absolute path with impureMode
      accountsPath = ../../../.aws/accounts.json;  # Relative to this file
      accounts = if builtins.pathExists accountsPath
                then builtins.fromJSON (builtins.readFile accountsPath)
                else {};

      # Create a single profile
      mkProfile = project: env: accountData: role:
        let
          accountId = if builtins.isString accountData then accountData else accountData.id;
          region = if builtins.isString accountData then "us-east-1" else (accountData.region or "us-east-1");
          # Support role doesn't add suffix for backward compatibility
          profileName = if role == "support" then "${project}-${env}" else "${project}-${env}-${role}";
        in ''
        [profile ${profileName}]
        sso_session = sso-east-1
        sso_account_id = ${accountId}
        sso_role_name = ${role}
        region = ${region}
        output = json
        ${caBundleConfig}
      '';

      # Generate profiles for one environment (default + additional roles)
      mkEnvProfiles = project: data: env:
        let
          accountData = data.accounts.${env};
          defaultRole = data.default_role or "support";

          # Get additional roles if account is an object
          additionalRoles = if builtins.isString accountData then []
                           else if builtins.hasAttr "additional_roles" accountData
                           then accountData.additional_roles
                           else [];

          # Create default profile
          defaultProfile = mkProfile project env accountData defaultRole;

          # Create additional role profiles
          roleProfiles = map (role: mkProfile project env accountData role) additionalRoles;
        in
        lib.concatStringsSep "\n\n" ([ defaultProfile ] ++ roleProfiles);

      # Generate all profiles for a project
      projectProfiles = project: data:
        let
          envs = builtins.attrNames data.accounts;
          profiles = map (env: mkEnvProfiles project data env) envs;
        in
        lib.concatStringsSep "\n\n" profiles;
    in
    lib.concatStringsSep "\n\n" (lib.mapAttrsToList projectProfiles accounts);

  # Work machine AWS config (AWS SSO)
  workConfig = ''
    [default]
    region = us-east-1
    output = json
    ${caBundleConfig}

    # SSO Session Configuration
    [sso-session sso-east-1]
    sso_start_url = https://d-906751770e.awsapps.com/start/
    sso_region = us-east-1
    sso_registration_scopes = sso:account:access
    output = json
    region = us-east-1
    duration_seconds = 57600
    ${caBundleConfig}

  '' + generateSsoProfiles;
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
  # Work machine: Use AWS SSO (`aws sso login --profile example-corp`)
  #
  # To configure:
  # 1. Personal: `aws configure --profile personal` then add to ~/.zsh_secrets:
  #    export AWS_ACCESS_KEY_ID="..."
  #    export AWS_SECRET_ACCESS_KEY="..."
  #
  # 2. Work: Update SSO URLs/IDs above, then run:
  #    aws sso login --profile profile-name
}
