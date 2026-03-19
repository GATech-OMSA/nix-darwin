# AWS CLI Configuration
#
# Generates ~/.aws/config with SSO session + default section.
# Individual account profiles are created on-demand by awslogin at runtime.
# Shell functions (awsuse, awslogin, awswho, etc.) read ~/.aws/accounts.json directly.

{ config, pkgs, lib, hostname, myLib, profileName, userConfig, ... }:

let
  # CA bundle path for corporate certificates (work machines only)
  # AWS CLI expands ~ but not $HOME in config files
  caBundle = if profileName == "work" then "~/.config/certs/cacert.pem" else null;
  caBundleConfig = if caBundle != null then ''ca-bundle = ${caBundle}'' else "";

  # AWS SSO configuration from user-config.nix
  awsSso = userConfig.awsSso or { enabled = false; };
  ssoEnabled = (awsSso.enabled or false) && (awsSso.startUrl or "") != "";
  ssoRegion = awsSso.region or "us-east-1";
  ssoSessionName = if profileName == "work" then "sso-work" else "sso-personal";

  # SSO-enabled config (just session + default — profiles created by awslogin)
  ssoConfig = ''
    [default]
    region = us-east-1
    output = json
    ${caBundleConfig}

    [sso-session ${ssoSessionName}]
    sso_start_url = ${awsSso.startUrl}
    sso_region = ${ssoRegion}
    sso_registration_scopes = sso:account:access
    output = json
    region = ${ssoRegion}
    duration_seconds = 57600
    ${caBundleConfig}
  '';

  # Fallback when SSO is not configured
  fallbackConfig = ''
    [default]
    region = us-east-1
    output = json
    ${caBundleConfig}

    # SSO not configured - set awsSso in config/user-config.nix
  '';

  awsConfig = if ssoEnabled then ssoConfig else fallbackConfig;
in
{
  # ==================================================
  # AWS CONFIG FILE
  # ==================================================
  # Writable file (not symlink) so awslogin can append profiles at runtime

  home.activation.aws-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.aws

    config_file="$HOME/.aws/config"
    config_content='${awsConfig}'

    # Remove symlink if it exists (from old config)
    if [[ -L "$config_file" ]]; then
      $DRY_RUN_CMD rm "$config_file"
    fi

    # Update only if different or doesn't exist
    if [[ ! -f "$config_file" ]] || ! echo "$config_content" | $DRY_RUN_CMD diff -q - "$config_file" >/dev/null 2>&1; then
      # Backup existing config before overwriting
      if [[ -f "$config_file" ]]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.aws/backup"
        $DRY_RUN_CMD /bin/cp "$config_file" "$HOME/.aws/backup/config-$(date +%Y%m%d-%H%M%S)"
      fi
      $DRY_RUN_CMD echo "$config_content" > "$config_file"
      $DRY_RUN_CMD chmod 644 "$config_file"
      echo "Updated writable ~/.aws/config"
    fi
  '';

  # ==================================================
  # AWS SHELL FUNCTIONS
  # ==================================================
  # Inject all AWS helper functions into zsh (reads accounts.json at runtime)

  programs.zsh.initContent = lib.mkAfter ''
    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}
    ${myLib.aws.mkAwsSearchCommands}
    ${myLib.aws.mkAwsProfileAutoRestore}
  '';
}
