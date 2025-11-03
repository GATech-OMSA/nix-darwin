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

  # ==================================================
  # AWS UNIVERSAL COMMAND GENERATOR
  # ==================================================
  # Generate universal AWS profile switching command with role support
  #
  # Pattern: awsuse <project> <env> [role]
  # Default role: support
  # Available roles: support, developer, data-engineer, data-scientist
  #
  # Corporate policy:
  #   - developer role: only available in sbx environment
  #   - support role: available in all environments (default)
  #   - specialized roles (data-engineer, data-scientist): some projects only
  #
  # Usage:
  #   mkAwsUniversalCommand {
  #     projects = [
  #       { name = "tririga-integrations"; short = "ti";
  #         environments = ["dev" "sbx" "qa" "prod"];
  #         roles = ["support" "developer" "data-engineer"]; }
  #       { name = "hr-system"; short = "hr";
  #         environments = ["qa" "prod"];
  #         roles = ["support"]; }
  #     ];
  #   }
  #
  # Generated function: awsuse <project> <env> [role]
  # Examples:
  #   awsuse tririga-integrations dev         → ti-dev-support
  #   awsuse tririga-integrations sbx developer → ti-sbx-developer
  #   awsuse ti qa                            → ti-qa-support (short name)
  #
  mkAwsUniversalCommand = { projects }:
    let
      # Generate project lookup map for short names
      projectLookup = lib.concatMapStringsSep "\n" (proj: ''
        "${proj.short}") echo "${proj.name}" ;;
      '') projects;

      # Generate project-environment validation
      projectValidation = lib.concatMapStringsSep "\n" (proj: ''
        "${proj.name}")
          valid_envs="${lib.concatStringsSep " " proj.environments}"
          valid_roles="${lib.concatStringsSep " " proj.roles}"
          ;;
      '') projects;
    in
    ''
      function awsuse() {
        local project="$1"
        local env="$2"
        local role="''${3:-support}"

        # Show usage if no args
        if [ -z "$project" ] || [ -z "$env" ]; then
          echo "Usage: awsuse <project> <env> [role]"
          echo ""
          echo "Projects:"
          ${lib.concatMapStringsSep "\n" (proj: ''
          echo "  ${proj.name} (${proj.short})"
          echo "    Environments: ${lib.concatStringsSep ", " proj.environments}"
          echo "    Roles: ${lib.concatStringsSep ", " proj.roles}"
          '') projects}
          echo ""
          echo "Examples:"
          echo "  awsuse tririga-integrations dev"
          echo "  awsuse ti sbx developer"
          echo "  awsuse hr-system prod"
          return 1
        fi

        # Expand short project names
        case "$project" in
          ${projectLookup}
          *) ;; # Use as-is if not a short name
        esac

        # Validate project-environment-role combination
        local valid_envs=""
        local valid_roles=""

        case "$project" in
          ${projectValidation}
          *)
            echo "❌ Unknown project: $project"
            echo "💡 Run 'awsuse' without arguments to see available projects"
            return 1
            ;;
        esac

        # Validate environment
        if ! echo "$valid_envs" | grep -qw "$env"; then
          echo "❌ Invalid environment '$env' for project '$project'"
          echo "Available: $valid_envs"
          return 1
        fi

        # Validate role
        if ! echo "$valid_roles" | grep -qw "$role"; then
          echo "❌ Invalid role '$role' for project '$project'"
          echo "Available: $valid_roles"
          return 1
        fi

        # Corporate policy: developer role only in sbx
        if [ "$role" = "developer" ] && [ "$env" != "sbx" ]; then
          echo "⚠️  Corporate policy: developer role only available in sbx environment"
          echo "Using support role for $env environment"
          role="support"
        fi

        # Construct profile name
        local profile="''${project}-''${env}-''${role}"

        # Check if profile exists in AWS config
        if ! grep -q "\\[profile $profile\\]" ~/.aws/config 2>/dev/null; then
          echo "❌ Profile not found in ~/.aws/config: $profile"
          echo ""
          echo "💡 Did you mean to login first?"
          echo "   awslogin $project $env $role"
          return 1
        fi

        # Set AWS_PROFILE
        export AWS_PROFILE="$profile"

        # Save profile for next shell session
        echo "$profile" > ~/.aws/.last_profile

        # Show confirmation
        echo "✅ AWS Profile set: $profile"
        echo "💡 Profile will auto-restore in new shells"
        echo "💡 Run 'awswho' to see profile details"
      }
    '';

  # ==================================================
  # AWS SSO LOGIN GENERATOR
  # ==================================================
  # Generate AWS SSO login command with automatic profile setting
  #
  # Pattern: awslogin <project> <env> [role]
  # Performs SSO login AND sets AWS_PROFILE automatically
  #
  # Usage: Same project configuration as mkAwsUniversalCommand
  #
  # Generated function: awslogin <project> <env> [role]
  # Examples:
  #   awslogin tririga-integrations dev
  #   awslogin ti sbx developer
  #
  mkAwsSsoLogin = { projects }:
    let
      projectLookup = lib.concatMapStringsSep "\n" (proj: ''
        "${proj.short}") echo "${proj.name}" ;;
      '') projects;

      projectValidation = lib.concatMapStringsSep "\n" (proj: ''
        "${proj.name}")
          valid_envs="${lib.concatStringsSep " " proj.environments}"
          valid_roles="${lib.concatStringsSep " " proj.roles}"
          ;;
      '') projects;
    in
    ''
      function awslogin() {
        local project="$1"
        local env="$2"
        local role="''${3:-support}"

        # Show usage if no args
        if [ -z "$project" ] || [ -z "$env" ]; then
          echo "Usage: awslogin <project> <env> [role]"
          echo "💡 Tip: Run 'awsuse' to see available projects"
          return 1
        fi

        # Expand short project names
        case "$project" in
          ${projectLookup}
          *) ;;
        esac

        # Validate (same logic as awsuse)
        local valid_envs=""
        local valid_roles=""

        case "$project" in
          ${projectValidation}
          *)
            echo "❌ Unknown project: $project"
            return 1
            ;;
        esac

        if ! echo "$valid_envs" | grep -qw "$env"; then
          echo "❌ Invalid environment '$env' for project '$project'"
          echo "Available: $valid_envs"
          return 1
        fi

        if ! echo "$valid_roles" | grep -qw "$role"; then
          echo "❌ Invalid role '$role' for project '$project'"
          echo "Available: $valid_roles"
          return 1
        fi

        # Corporate policy: developer role only in sbx
        if [ "$role" = "developer" ] && [ "$env" != "sbx" ]; then
          echo "⚠️  Corporate policy: developer role only available in sbx environment"
          echo "Using support role for $env environment"
          role="support"
        fi

        # Construct profile name
        local profile="''${project}-''${env}-''${role}"

        # Perform SSO login
        echo "🔐 Logging into AWS SSO: $profile"
        aws sso login --profile "$profile"

        if [ $? -eq 0 ]; then
          # Set AWS_PROFILE after successful login
          export AWS_PROFILE="$profile"
          echo "$profile" > ~/.aws/.last_profile

          echo "✅ SSO login successful"
          echo "✅ AWS Profile set: $profile"
          echo "💡 Profile persisted for next session"
        else
          echo "❌ SSO login failed"
          return 1
        fi
      }
    '';

  # ==================================================
  # AWS INFO COMMANDS GENERATOR
  # ==================================================
  # Generate AWS profile information commands
  #
  # Generated functions:
  #   awswho   - Show current profile and session details
  #   awslist  - List all available profiles from ~/.aws/config
  #
  mkAwsInfoCommands = ''
    function awswho() {
      if [ -z "$AWS_PROFILE" ]; then
        echo "❌ No AWS profile set"
        echo "💡 Run: awsuse <project> <env> [role]"
        echo "💡 Or: awslogin <project> <env> [role]"
        return 1
      fi

      echo "📋 Current AWS Profile: $AWS_PROFILE"
      echo ""

      # Show profile details from config
      if grep -q "\[profile $AWS_PROFILE\]" ~/.aws/config 2>/dev/null; then
        echo "Profile configuration:"
        awk "/\[profile $AWS_PROFILE\]/,/^\[/" ~/.aws/config | grep -v "^\[" | grep -v "^$" | sed 's/^/  /'
      fi

      echo ""
      echo "Session info:"
      aws sts get-caller-identity 2>/dev/null || echo "  (not logged in or session expired)"
      echo ""
      echo "💡 Run 'awslist' to see all profiles"
    }

    function awslist() {
      echo "📋 Available AWS Profiles:"
      echo ""

      if [ ! -f ~/.aws/config ]; then
        echo "❌ No AWS config file found at ~/.aws/config"
        return 1
      fi

      # Extract and format profile names
      grep "^\[profile " ~/.aws/config | sed 's/\[profile /  /' | sed 's/\]//' | sort

      echo ""
      echo "Usage: awsuse <project> <env> [role]"
      echo "   Or: awslogin <project> <env> [role]"
      echo ""

      if [ -n "$AWS_PROFILE" ]; then
        echo "Current profile: $AWS_PROFILE ✅"
      else
        echo "No profile currently set"
      fi
    }
  '';

  # ==================================================
  # AWS PROFILE AUTO-RESTORE
  # ==================================================
  # Generate shell initialization code to auto-restore last AWS profile
  #
  # Add this to zsh initExtra to restore AWS_PROFILE on shell start
  #
  mkAwsProfileAutoRestore = ''
    # Auto-restore last AWS profile
    if [ -f ~/.aws/.last_profile ]; then
      export AWS_PROFILE="$(cat ~/.aws/.last_profile)"
      if [ -n "$AWS_PROFILE" ]; then
        echo "🔄 Restored AWS Profile: $AWS_PROFILE"
        echo "💡 Run 'awswho' for details or 'awsuse' to switch"
      fi
    fi
  '';
}
