# home/_profiles/personal/aws.nix
#
# AWS configuration for personal profile
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
  #   awsuse pi dev                # personal-infra dev (developer role)
  #   awsuse pi dev admin          # personal-infra dev (admin role)
  #   awslogin sp dev              # side-project dev + SSO login
  #
  # Generated aliases from accounts.json:
  #   pidev, spdev, ssdev, ssstaging, ssprod, pidev-admin, etc.

  programs.zsh.initContent = lib.mkAfter ''
    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}
    ${myLib.aws.mkAwsSearchCommands}
    ${myLib.aws.mkAwsProfileAutoRestore}
  '';
}
