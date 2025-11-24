# home/_profiles/work/aws.nix
#
# AWS configuration for work profile
# - AWS helper functions for multi-account SSO workflows
# - Integrates with lib/aws-helpers.nix for project-based account management

{ config, pkgs, lib, myLib, ... }:

{
  # ==================================================
  # AWS HELPER FUNCTIONS
  # ==================================================
  # AWS functions read from ~/.aws/accounts.json for project configuration.
  #
  # Usage:
  #   awsuse <project|alias> <env> [role]
  #   awslogin <project|alias> <env> [role]
  #   awswho, awslist, awswhere, awscheck
  #
  # Examples:
  #   awsuse ti sbx                # tririga-integrations sbx (support role)
  #   awsuse ti sbx developer      # tririga-integrations sbx (developer role)
  #   awslogin ps dev              # paging-solution dev + SSO login
  #
  # Generated aliases from accounts.json:
  #   tidev, tisbx, tiqa, tiprod, tidev-developer, tisbx-developer, etc.

  programs.zsh.initContent = lib.mkAfter ''
    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}
    ${myLib.aws.mkAwsSearchCommands}
    ${myLib.aws.mkAwsProfileAutoRestore}
  '';
}
