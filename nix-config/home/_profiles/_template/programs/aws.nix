{ config, pkgs, lib, hostname, myLib, machineType, userConfig, ... }:

let
  # CA bundle path for corporate certificates (work machines only)
  # Pass via config.programs.aws.caBundle from work.nix
  caBundle = config.programs.aws.caBundle or null;
  caBundleConfig = if caBundle != null then ''ca-bundle = "${caBundle}"'' else "";

  # AWS SSO configuration from user-config.nix (unified for all profiles)
  awsSso = userConfig.awsSso or { enabled = false; };
  ssoEnabled = (awsSso.enabled or false) && (awsSso.startUrl or "") != "";
  ssoRegion = awsSso.region or "us-east-1";
  ssoSessionName = if machineType == "work" then "sso-work" else "sso-personal";

  # Personal machine AWS config
  # Uses SSO if enabled AND startUrl is configured, otherwise falls back to static IAM config
  personalConfig = if ssoEnabled then ''
    [default]
    region = us-east-1
    output = json

    # SSO Session Configuration (Personal)
    [sso-session ${ssoSessionName}]
    sso_start_url = ${awsSso.startUrl}
    sso_region = ${ssoRegion}
    sso_registration_scopes = sso:account:access
    output = json
    region = ${ssoRegion}
    duration_seconds = 57600

  '' + generateSsoProfiles ssoSessionName
  else ''
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
  # Takes ssoSessionName parameter to support different SSO sessions (personal vs work)
  generateSsoProfiles = ssoSessionName:
    let
      # Read accounts.json from repo root (evaluated at build time)
      # Path: 5 levels up from nix-config/home/_profiles/_template/programs/
      accountsPath = ../../../../../.aws/accounts.json;  # Relative to this file
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
        sso_session = ${ssoSessionName}
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
  # Uses same unified awsSso config from user-config.nix
  workConfig = if ssoEnabled then ''
    [default]
    region = us-east-1
    output = json
    ${caBundleConfig}

    # SSO Session Configuration (Work)
    [sso-session ${ssoSessionName}]
    sso_start_url = ${awsSso.startUrl}
    sso_region = ${ssoRegion}
    sso_registration_scopes = sso:account:access
    output = json
    region = ${ssoRegion}
    duration_seconds = 57600
    ${caBundleConfig}

  '' + generateSsoProfiles ssoSessionName
  else ''
    [default]
    region = us-east-1
    output = json
    ${caBundleConfig}

    # SSO not configured - set awsSso in config/user-config.nix
  '';
in
{
  # AWS CLI configuration - Declarative management
  # Manages ~/.aws/config (NOT credentials - those stay in ~/.zsh_secrets)

  # AWS config file - writable (not read-only symlink) for VS Code editing
  # Uses home.activation to create regular file instead of /nix/store symlink
  home.activation.aws-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create .aws directory
    $DRY_RUN_CMD mkdir -p $HOME/.aws

    # Prepare config content (select based on machine type)
    config_file="$HOME/.aws/config"
    config_content='${myLib.selectByMachineType machineType {
      personal = personalConfig;
      work = workConfig;
    }}'

    # Remove symlink if it exists (from old config)
    if [[ -L "$config_file" ]]; then
      $DRY_RUN_CMD rm "$config_file"
    fi

    # Update only if different or doesn't exist
    if [[ ! -f "$config_file" ]] || ! echo "$config_content" | $DRY_RUN_CMD diff -q - "$config_file" >/dev/null 2>&1; then
      $DRY_RUN_CMD echo "$config_content" > "$config_file"
      $DRY_RUN_CMD chmod 644 "$config_file"
      echo "✅ Updated writable ~/.aws/config"
    fi
  '';

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
