{ lib }:

rec {
  # ==================================================
  # ACCOUNTS.JSON INTEGRATION
  # ==================================================
  loadAccountsJson =
    let accountsPath = "${builtins.getEnv "HOME"}/.aws/accounts.json";
    in if builtins.pathExists accountsPath
       then builtins.fromJSON (builtins.readFile accountsPath)
       else {};

  # Generate AWS helper functions using accounts.json
  mkAwsAccountHelper =
    let accounts = loadAccountsJson;
    in ''
      function awsuse() {
        local project="$1"
        local env="$2"
        local role="$3"

        if [[ -z "$project" || -z "$env" ]]; then
          echo "Usage: awsuse <project|alias> <env> [role]"
          echo ""
          echo "Available accounts:"
          jq -r 'to_entries[] | "  \(.key) (\(.value.alias)): \(.value.accounts | keys | join(", "))"' ~/.aws/accounts.json
          return 1
        fi

        # Resolve alias to project name
        local resolved_project=$(jq -r --arg input "$project" 'to_entries[] | select(.key == $input or .value.alias == $input) | .key' ~/.aws/accounts.json)

        if [[ -z "$resolved_project" ]]; then
          echo "❌ Project not found: $project"
          return 1
        fi

        # Get account data (can be string or object)
        local account_data=$(jq -r --arg proj "$resolved_project" --arg env "$env" '.[$proj].accounts[$env] // empty' ~/.aws/accounts.json)

        if [[ -z "$account_data" ]]; then
          echo "❌ Account not found: $resolved_project/$env"
          echo "Available for $resolved_project:" $(jq -r --arg proj "$resolved_project" '.[$proj].accounts | keys | join(", ")' ~/.aws/accounts.json)
          return 1
        fi

        # Extract account ID (works for both string and object)
        local account_id=$(echo "$account_data" | jq -r 'if type == "string" then . else .id end' 2>/dev/null || echo "$account_data")

        # Determine role (default to support if not specified)
        if [[ -z "$role" ]]; then
          role=$(jq -r --arg proj "$resolved_project" '.[$proj].default_role // "support"' ~/.aws/accounts.json)
        else
          # Resolve role abbreviation to full name
          case "$role" in
            de) role="data-engineer" ;;
            ds) role="data-scientist" ;;
            dev) role="developer" ;;
            sup) role="support" ;;
            ro) role="readonly" ;;
            pw) role="poweruser" ;;
            adm) role="admin" ;;
            # If not abbreviated, use as-is
          esac
        fi

        # Construct profile name (support role doesn't add suffix for backward compatibility)
        local profile
        if [[ "$role" == "support" ]]; then
          profile="''${resolved_project}-''${env}"
        else
          profile="''${resolved_project}-''${env}-''${role}"
        fi

        # Check if profile exists
        if ! grep -q "\\[profile $profile\\]" ~/.aws/config 2>/dev/null; then
          echo "❌ Profile not configured: $profile"
          echo "💡 Run: awslogin $project $env $role"
          return 1
        fi

        export AWS_PROFILE="$profile"
        echo "$profile" > ~/.aws/.last_profile
        echo "✅ Switched to: $profile"
        echo "   Account: $account_id"
        echo "   Role: $role"
      }

      function awslogin() {
        local project="$1"
        local env="$2"
        local role="$3"

        if [[ -z "$project" || -z "$env" ]]; then
          echo "Usage: awslogin <project|alias> <env> [role]"
          return 1
        fi

        # Resolve alias to project name
        local resolved_project=$(jq -r --arg input "$project" 'to_entries[] | select(.key == $input or .value.alias == $input) | .key' ~/.aws/accounts.json)

        # Determine role
        if [[ -z "$role" ]]; then
          role=$(jq -r --arg proj "$resolved_project" '.[$proj].default_role // "support"' ~/.aws/accounts.json)
        else
          # Resolve role abbreviation to full name
          case "$role" in
            de) role="data-engineer" ;;
            ds) role="data-scientist" ;;
            dev) role="developer" ;;
            sup) role="support" ;;
            ro) role="readonly" ;;
            pw) role="poweruser" ;;
            adm) role="admin" ;;
            # If not abbreviated, use as-is
          esac
        fi

        # Construct profile name
        local profile
        if [[ "$role" == "support" ]]; then
          profile="''${resolved_project}-''${env}"
        else
          profile="''${resolved_project}-''${env}-''${role}"
        fi

        echo "🔐 Logging into: $profile"
        aws sso login --profile "$profile"

        if [[ $? -eq 0 ]]; then
          export AWS_PROFILE="$profile"
          echo "$profile" > ~/.aws/.last_profile
          echo "✅ Logged in and switched to: $profile"
        fi
      }
    '';

  # Generate aliases from accounts.json
  # Creates both default (support) and role-specific aliases
  mkAwsAliasesFromJson =
    let
      accounts = loadAccountsJson;

      # Get list of roles for an environment (returns list of role names)
      getRolesForEnv = accountData:
        if builtins.isString accountData then []
        else if builtins.hasAttr "additional_roles" accountData
        then accountData.additional_roles
        else [];

      mkProjectAliases = project: data:
        let
          alias = data.alias;
          envs = builtins.attrNames data.accounts;
          defaultRole = data.default_role or "support";

          # For each environment, create default alias + role-specific aliases
          mkEnvAliases = env:
            let
              accountData = data.accounts.${env};
              additionalRoles = getRolesForEnv accountData;

              # Default alias (support role)
              defaultAlias = {
                name = "${alias}${env}";
                value = "awsuse ${project} ${env}";
              };

              # Additional role aliases
              roleAliases = map (role: {
                name = "${alias}${env}-${role}";
                value = "awsuse ${project} ${env} ${role}";
              }) additionalRoles;
            in
            [ defaultAlias ] ++ roleAliases;

          allAliases = lib.concatMap mkEnvAliases envs;
        in
        lib.listToAttrs allAliases;
    in
    lib.foldl' (acc: name: acc // (mkProjectAliases name accounts.${name})) {} (builtins.attrNames accounts);

  # ==================================================
  # DEPRECATED: Generic AWS Profile Aliases
  # ==================================================
  # These functions create generic aliases like "awsdev" which are ambiguous
  # in multi-project setups. Use mkAwsAliasesFromJson instead, which creates
  # project-specific aliases like "tidev", "psdev", etc.
  #
  # Kept for backwards compatibility but not recommended for new configurations.

  mkAwsProfileAliases = { project, environments }:
    lib.listToAttrs (map (env: {
      name = "aws${env}";
      value = "awsuse ${project}-${env}";
    }) environments);

  mkAwsProjectAliases = projects:
    lib.foldl' (acc: proj: acc // (mkAwsProfileAliases proj)) {} projects;

  mkAwsProfileAliasesWithPrefix = { prefix, project, environments }:
    lib.listToAttrs (map (env: {
      name = "${prefix}${env}";
      value = "awsuse ${project}-${env}";
    }) environments);

  # ==================================================
  # DEPRECATED: AWS Universal Command Generator (Legacy)
  # ==================================================
  # This function is superseded by mkAwsAccountHelper which automatically
  # reads from accounts.json. Kept for backwards compatibility only.
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
  #   awswho    - Show current profile and session details
  #   awslist   - List all available profiles grouped by project
  #   awswhere  - Reverse lookup: find project/env by account ID
  #   awscheck  - Check SSO session status for all profiles
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
      if [ ! -f ~/.aws/accounts.json ]; then
        echo "❌ No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "📋 AWS Accounts (from accounts.json):"
      echo ""

      # Group by project
      jq -r 'to_entries[] |
        "\n\(.key) (\(.value.alias))" +
        (if .value.description then " - \(.value.description)" else "" end) +
        "\n" +
        (
          .value.accounts | to_entries[] |
          "  • \(.key)      (" + (if (.value | type) == "object" then .value.id else .value end | tostring) + ")" +
          (if (.value | type) == "object" and .value.additional_roles then " → \(.value.additional_roles | join(", "))" else "" end)
        )
      ' ~/.aws/accounts.json 2>/dev/null || echo "Error parsing accounts.json"

      echo ""
      if [ -n "$AWS_PROFILE" ]; then
        echo "Current: $AWS_PROFILE ✅"
      else
        echo "No profile currently set"
      fi
      echo ""
      echo "💡 Usage: awsuse <alias> <env> [role]"
      echo "   Examples: tidev, awsuse ps qa, awsuse ti dev developer"
    }

    function awswhere() {
      local account_id="$1"

      if [[ -z "$account_id" ]]; then
        echo "Usage: awswhere <account-id>"
        echo "Example: awswhere 779846812095"
        return 1
      fi

      if [ ! -f ~/.aws/accounts.json ]; then
        echo "❌ No accounts.json found"
        return 1
      fi

      echo "🔍 Searching for account: $account_id"
      echo ""

      local result=$(jq -r --arg id "$account_id" '
        to_entries[] |
        select(
          .value.accounts | to_entries[] |
          (.value == $id or .value.id == $id)
        ) |
        {
          project: .key,
          alias: .value.alias,
          env: (
            .value.accounts | to_entries[] |
            select(.value == $id or .value.id == $id) |
            .key
          ),
          roles: (
            .value.accounts | to_entries[] |
            select(.value == $id or .value.id == $id) |
            if .value.additional_roles then
              ["support"] + .value.additional_roles
            else
              ["support"]
            end
          )
        } |
        "📍 Project: \(.project) (\(.alias))\n   Environment: \(.env)\n   Profiles:\n" +
        (.roles[] | "     • \(.project)-\(.env)" + (if . != "support" then "-\(.)" else "" end) + " (\(.) role)")
      ' ~/.aws/accounts.json)

      if [[ -z "$result" ]]; then
        echo "❌ Account ID not found: $account_id"
        return 1
      fi

      echo "$result"
      echo ""
      echo "💡 Switch: awsuse <alias> <env> [role]"
    }

    function awscheck() {
      echo "🔍 Checking SSO session status..."
      echo ""

      if [ ! -f ~/.aws/config ]; then
        echo "❌ No AWS config found"
        return 1
      fi

      # Get all profiles
      local profiles=$(grep "^\[profile " ~/.aws/config | sed 's/\[profile //' | sed 's/\]//')

      for profile in $profiles; do
        printf "%-30s " "$profile:"
        AWS_PROFILE=$profile aws sts get-caller-identity &>/dev/null
        if [ $? -eq 0 ]; then
          echo "✅ Active"
        else
          echo "❌ Expired/Not logged in"
        fi
      done

      echo ""
      echo "💡 Login: awslogin <project> <env> [role]"
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

  # ==================================================
  # AWS PROFILE SEARCH AND FILTERING
  # ==================================================
  # Search and filter AWS profiles from accounts.json
  #
  # Generated functions:
  #   awsfind <query>            - Fuzzy search profiles by project/env/role
  #   awsfilter <type> <value>   - Filter profiles by type (project/env/role)
  #
  mkAwsSearchCommands = ''
    function awsfind() {
      local query="$1"

      if [[ -z "$query" ]]; then
        echo "Usage: awsfind <search-term>"
        echo ""
        echo "Search profiles by project name, environment, or role"
        echo ""
        echo "Examples:"
        echo "  awsfind ti          # Find all Tririga profiles"
        echo "  awsfind prod        # Find all production profiles"
        echo "  awsfind developer   # Find all developer role profiles"
        return 1
      fi

      if [ ! -f ~/.aws/accounts.json ]; then
        echo "❌ No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "🔍 Searching for: $query"
      echo ""

      # Search across projects, environments, and roles (case-insensitive)
      local found=0
      jq -r --arg q "$(echo $query | tr '[:upper:]' '[:lower:]')" '
        to_entries[] |
        . as $proj |
        (
          # Check if project name or alias matches
          if (($proj.key | ascii_downcase | contains($q)) or
              ($proj.value.alias | ascii_downcase | contains($q))) then
            {
              type: "project",
              project: $proj.key,
              alias: $proj.value.alias,
              matches: (
                $proj.value.accounts | to_entries[] |
                {
                  env: .key,
                  id: (.value.id // .value | tostring),
                  roles: (
                    if .value.additional_roles then
                      ["support"] + .value.additional_roles
                    else
                      ["support"]
                    end
                  )
                }
              )
            }
          # Check if environment matches
          elif ($proj.value.accounts | to_entries[] | .key | ascii_downcase | contains($q)) then
            {
              type: "env",
              project: $proj.key,
              alias: $proj.value.alias,
              matches: [
                $proj.value.accounts | to_entries[] |
                select(.key | ascii_downcase | contains($q)) |
                {
                  env: .key,
                  id: (.value.id // .value | tostring),
                  roles: (
                    if .value.additional_roles then
                      ["support"] + .value.additional_roles
                    else
                      ["support"]
                    end
                  )
                }
              ]
            }
          # Check if any role matches
          elif (
            $proj.value.accounts | to_entries[] |
            (.value.additional_roles // []) | .[] | ascii_downcase | contains($q)
          ) then
            {
              type: "role",
              project: $proj.key,
              alias: $proj.value.alias,
              matches: [
                $proj.value.accounts | to_entries[] |
                select(
                  (.value.additional_roles // []) | .[] | ascii_downcase | contains($q)
                ) |
                {
                  env: .key,
                  id: (.value.id // .value | tostring),
                  roles: (
                    (.value.additional_roles // []) | map(select(ascii_downcase | contains($q)))
                  )
                }
              ]
            }
          else
            empty
          end
        ) |
        if . then
          "📍 \(.project) (\(.alias))" +
          "\n" +
          (
            if (.matches | type == "array") then
              .matches[] |
              "   • \(.env) (Account: \(.id))\n" +
              (.roles[] | "     → \($proj.key)-\(.env)" + (if . != "support" then "-\(.)" else "" end) + " (\(.) role)")
            else
              .matches |
              "   • \(.env) (Account: \(.id))\n" +
              (.roles[] | "     → \($proj.key)-\(.env)" + (if . != "support" then "-\(.)" else "" end) + " (\(.) role)")
            end
          ) +
          "\n"
        else
          empty
        end
      ' ~/.aws/accounts.json 2>/dev/null | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          echo "$line"
          found=1
        fi
      done

      if [[ $found -eq 0 ]]; then
        echo "❌ No profiles found matching: $query"
        echo ""
        echo "💡 Try: awslist (to see all profiles)"
        return 1
      fi

      echo ""
      echo "💡 Switch: awsuse <alias> <env> [role]"
    }

    function awsfilter() {
      local type="$1"
      local value="$2"

      if [[ -z "$type" || -z "$value" ]]; then
        echo "Usage: awsfilter <type> <value>"
        echo ""
        echo "Filter profiles by:"
        echo "  project <name>    - Filter by project name or alias"
        echo "  env <name>        - Filter by environment (dev/sbx/qa/prod)"
        echo "  role <name>       - Filter by role (support/developer/etc)"
        echo ""
        echo "Examples:"
        echo "  awsfilter project ti      # All Tririga profiles"
        echo "  awsfilter env prod        # All production profiles"
        echo "  awsfilter role developer  # All developer role profiles"
        return 1
      fi

      if [ ! -f ~/.aws/accounts.json ]; then
        echo "❌ No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "🔍 Filtering by $type: $value"
      echo ""

      local found=0
      local filter_query

      case "$type" in
        project|proj|p)
          filter_query='.key == $val or .value.alias == $val'
          ;;
        env|environment|e)
          filter_query='.value.accounts | has($val)'
          ;;
        role|r)
          filter_query='
            .value.accounts | to_entries[] |
            (if .value.additional_roles then
              ["support"] + .value.additional_roles
            else
              ["support"]
            end) | contains([$val])
          '
          ;;
        *)
          echo "❌ Invalid filter type: $type"
          echo "   Valid types: project, env, role"
          return 1
          ;;
      esac

      jq -r --arg val "$value" --arg type "$type" '
        to_entries[] |
        select(
          if $type == "project" or $type == "proj" or $type == "p" then
            (.key == $val or .value.alias == $val)
          elif $type == "env" or $type == "environment" or $type == "e" then
            .value.accounts | has($val)
          elif $type == "role" or $type == "r" then
            [
              .value.accounts | to_entries[] |
              (
                if .value.additional_roles then
                  ["support"] + .value.additional_roles
                else
                  ["support"]
                end
              ) | contains([$val])
            ] | any
          else
            false
          end
        ) |
        . as $proj |
        "📍 \(.key) (\(.value.alias))" +
        (if .value.description then " - \(.value.description)" else "" end) +
        "\n" +
        (
          if $type == "env" or $type == "environment" or $type == "e" then
            # Show only matching environment
            .value.accounts | to_entries[] |
            select(.key == $val) |
            "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
            (
              (
                if .value.additional_roles then
                  ["support"] + .value.additional_roles
                else
                  ["support"]
                end
              )[] |
              "     → \($proj.key)-\($val)" + (if . != "support" then "-\(.)" else "" end) + " (\(.) role)"
            )
          elif $type == "role" or $type == "r" then
            # Show only environments with matching role
            [
              .value.accounts | to_entries[] |
              select(
                (
                  if .value.additional_roles then
                    ["support"] + .value.additional_roles
                  else
                    ["support"]
                  end
                ) | contains([$val])
              ) |
              "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
              "     → \($proj.key)-\(.key)" + (if $val != "support" then "-\($val)" else "" end) + " (\($val) role)"
            ] | join("\n")
          else
            # Show all environments for project
            [
              .value.accounts | to_entries[] |
              "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
              (
                (
                  if .value.additional_roles then
                    ["support"] + .value.additional_roles
                  else
                    ["support"]
                  end
                )[] |
                "     → \($proj.key)-\(.key)" + (if . != "support" then "-\(.)" else "" end) + " (\.) role)"
              )
            ] | join("\n")
          end
        ) +
        "\n"
      ' ~/.aws/accounts.json 2>/dev/null | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          echo "$line"
          found=1
        fi
      done

      if [[ $found -eq 0 ]]; then
        echo "❌ No profiles found with $type: $value"
        echo ""
        echo "💡 Try: awslist (to see all profiles)"
        return 1
      fi

      echo ""
      echo "💡 Switch: awsuse <alias> <env> [role]"
    }
  '';
}
