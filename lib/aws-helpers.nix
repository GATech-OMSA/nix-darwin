{ lib }:

rec {
  # ==================================================
  # AWS PROFILE ALIAS GENERATOR
  # ==================================================
  # Generate AWS profile switching aliases for quick environment switching
  #
  # Usage:
  #   mkAwsProfileAliases {
  #     project = "tririga-integrations";
  #     environments = [ "dev" "sbx" "qa" "prod" ];
  #   }
  #
  # Generated aliases:
  #   awsdev   → awsuse tririga-integrations-dev
  #   awssbx   → awsuse tririga-integrations-sbx
  #   awsqa    → awsuse tririga-integrations-qa
  #   awsprod  → awsuse tririga-integrations-prod
  #
  mkAwsProfileAliases = { project, environments }:
    lib.listToAttrs (map (env: {
      name = "aws${env}";
      value = "awsuse ${project}-${env}";
    }) environments);

  # ==================================================
  # MULTIPLE AWS PROJECT ALIASES
  # ==================================================
  # Generate AWS profile aliases for multiple projects
  #
  # Usage:
  #   mkAwsProjectAliases [
  #     { project = "tririga-integrations"; environments = [ "dev" "sbx" "qa" "prod" ]; }
  #     { project = "project2"; environments = [ "dev" "prod" ]; }
  #   ]
  #
  # Generated aliases:
  #   awsdev   → awsuse tririga-integrations-dev
  #   awssbx   → awsuse tririga-integrations-sbx
  #   awsqa    → awsuse tririga-integrations-qa
  #   awsprod  → awsuse tririga-integrations-prod
  #   awsp2dev → awsuse project2-dev
  #   awsp2prod → awsuse project2-prod
  #
  # Note: For multiple projects, use unique prefixes to avoid conflicts
  #
  mkAwsProjectAliases = projects:
    lib.foldl' (acc: proj: acc // (mkAwsProfileAliases proj)) {} projects;

  # ==================================================
  # AWS PROFILE ALIAS GENERATOR (with prefix)
  # ==================================================
  # Generate AWS profile switching aliases with custom prefix
  #
  # Usage:
  #   mkAwsProfileAliasesWithPrefix {
  #     prefix = "ti";  # tririga-integrations
  #     project = "tririga-integrations";
  #     environments = [ "dev" "sbx" "qa" "prod" ];
  #   }
  #
  # Generated aliases:
  #   tidev   → awsuse tririga-integrations-dev
  #   tisbx   → awsuse tririga-integrations-sbx
  #   tiqa    → awsuse tririga-integrations-qa
  #   tiprod  → awsuse tririga-integrations-prod
  #
  mkAwsProfileAliasesWithPrefix = { prefix, project, environments }:
    lib.listToAttrs (map (env: {
      name = "${prefix}${env}";
      value = "awsuse ${project}-${env}";
    }) environments);
}
