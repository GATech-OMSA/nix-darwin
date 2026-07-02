{ lib }:

rec {
  # ==================================================
  # AWS SHELL FUNCTIONS
  # ==================================================
  # All functions generate shell code that reads ~/.aws/accounts.json at RUNTIME.
  # No build-time file reading — edit accounts.json and functions work immediately.

  # Generate AWS helper functions using accounts.json
  mkAwsAccountHelper = ''
      function awsuse() {
        local project="''${1:-}"
        local env="''${2:-}"
        local role="''${3:-}"

        if [[ -z "$project" || -z "$env" ]]; then
          echo "   Usage: awsuse <project|alias> <env> [role]"
          echo ""
          echo "Available accounts:"
          jq -r 'to_entries[] | "  \(.key) (\(.value.alias // "-")): \(.value.accounts | keys | join(", "))"' ~/.aws/accounts.json 2>/dev/null
          return 1
        fi

        if [ ! -f ~/.aws/accounts.json ]; then
          echo "✗No accounts.json found at ~/.aws/accounts.json"
          return 1
        fi

        # Expand role abbreviations to full names
        case "$role" in
          dev) role="developer" ;;
          ds) role="data-scientist" ;;
          de) role="data-engineer" ;;
          da) role="data-analyst" ;;
        esac

        # Resolve alias to project name
        local resolved_project=$(jq -r --arg input "$project" 'to_entries[] | select(.key == $input or (.value.alias // "") == $input) | .key' ~/.aws/accounts.json)

        if [[ -z "$resolved_project" ]]; then
          echo "✗Project not found: $project"
          return 1
        fi

        # Get account data (can be string or object)
        local account_data=$(jq -r --arg proj "$resolved_project" --arg env "$env" '.[$proj].accounts[$env] // empty' ~/.aws/accounts.json)

        if [[ -z "$account_data" ]]; then
          echo "✗Account not found: $resolved_project/$env"
          echo "Available for $resolved_project:" $(jq -r --arg proj "$resolved_project" '.[$proj].accounts | keys | join(", ")' ~/.aws/accounts.json)
          return 1
        fi

        # Extract account ID (works for both string and object)
        local account_id=$(echo "$account_data" | jq -r 'if type == "string" then . else .id end' 2>/dev/null || echo "$account_data")

        # Determine role (default from accounts.json)
        if [[ -z "$role" ]]; then
          role=$(jq -r --arg proj "$resolved_project" '.[$proj].default_role // "support"' ~/.aws/accounts.json)
        fi

        # Construct profile name (default role omits suffix for backward compat)
        local default_role=$(jq -r --arg proj "$resolved_project" '.[$proj].default_role // "support"' ~/.aws/accounts.json)
        local profile
        if [[ "$role" == "$default_role" ]]; then
          profile="''${resolved_project}-''${env}"
        else
          profile="''${resolved_project}-''${env}-''${role}"
        fi

        # Check if profile exists
        if ! grep -q "\\[profile $profile\\]" ~/.aws/config 2>/dev/null; then
          echo "✗Profile not configured: $profile"
          echo "   Run: awslogin $project $env $role"
          return 1
        fi

        export AWS_PROFILE="$profile"
        echo "$profile" > ~/.aws/.last_profile
        echo "✓ Switched to: $profile"
        echo "   Account: $account_id"
        echo "   Role: $role"
      }

      function awslogin() {
        local project="''${1:-}"
        local env="''${2:-}"
        local role="''${3:-}"

        if [[ -z "$project" || -z "$env" ]]; then
          echo "   Usage: awslogin <project|alias> <env> [role]"
          return 1
        fi

        if [ ! -f ~/.aws/accounts.json ]; then
          echo "✗No accounts.json found at ~/.aws/accounts.json"
          return 1
        fi

        # Resolve alias to project name
        local resolved_project=$(jq -r --arg input "$project" 'to_entries[] | select(.key == $input or (.value.alias // "") == $input) | .key' ~/.aws/accounts.json)

        if [[ -z "$resolved_project" ]]; then
          echo "✗Project not found: $project"
          return 1
        fi

        # Expand role abbreviations to full names
        case "$role" in
          dev) role="developer" ;;
          ds) role="data-scientist" ;;
          de) role="data-engineer" ;;
          da) role="data-analyst" ;;
        esac

        # Determine role
        local default_role=$(jq -r --arg proj "$resolved_project" '.[$proj].default_role // "support"' ~/.aws/accounts.json)
        if [[ -z "$role" ]]; then
          role="$default_role"
        fi

        # Construct profile name (same logic as awsuse)
        local profile
        if [[ "$role" == "$default_role" ]]; then
          profile="''${resolved_project}-''${env}"
        else
          profile="''${resolved_project}-''${env}-''${role}"
        fi

        # Check if profile exists, if not create it dynamically
        if ! grep -q "^\[profile $profile\]" ~/.aws/config 2>/dev/null; then
          echo "→ Profile not found, creating dynamically..."

          # Get account info from accounts.json
          local account_data=$(jq -r --arg proj "$resolved_project" --arg env "$env" '.[$proj].accounts[$env]' ~/.aws/accounts.json)
          if [[ -z "$account_data" || "$account_data" == "null" ]]; then
            echo "✗Environment not found: $resolved_project/$env"
            return 1
          fi

          # Extract account ID (works for both string and object format)
          local account_id=$(echo "$account_data" | jq -r 'if type == "string" then . else .id end')
          local region=$(echo "$account_data" | jq -r 'if type == "object" then (.region // "us-east-1") else "us-east-1" end')

          # Validate account ID format
          if [[ ! "$account_id" =~ ^[0-9]{12}$ ]]; then
            echo "✗Invalid account ID format: $account_id"
            return 1
          fi

          # Get SSO session name from existing config
          local sso_session=$(grep -m1 "^\[sso-session" ~/.aws/config 2>/dev/null | sed 's/\[sso-session \(.*\)\]/\1/')
          if [[ -z "$sso_session" ]]; then
            echo "✗No SSO session found in ~/.aws/config"
            echo "   Run: nix-rebuild (to set up SSO session first)"
            return 1
          fi

          # Append new profile to config
          cat >> ~/.aws/config <<EOF

[profile $profile]
sso_session = $sso_session
sso_account_id = $account_id
sso_role_name = $role
region = $region
output = json
EOF
          echo "✓ Created profile: $profile"
        fi

        echo "→ Logging into: $profile"
        aws sso login --profile "$profile"

        if [[ $? -eq 0 ]]; then
          export AWS_PROFILE="$profile"
          echo "$profile" > ~/.aws/.last_profile
          echo "✓ Logged in and switched to: $profile"
        fi
      }
    '';

  # ==================================================
  # AWS INFO COMMANDS GENERATOR
  # ==================================================
  mkAwsInfoCommands = ''
    function awswho() {
      if [ -z "''${AWS_PROFILE:-}" ]; then
        echo "✗No AWS profile set"
        echo "   Run: awsuse <project> <env> [role]"
        echo "   Or: awslogin <project> <env> [role]"
        return 1
      fi

      echo "→ Current AWS Profile: ''${AWS_PROFILE}"
      echo ""

      # Show profile details from config
      if grep -q "\[profile ''${AWS_PROFILE}\]" ~/.aws/config 2>/dev/null; then
        echo "Profile configuration:"
        awk "/\[profile ''${AWS_PROFILE}\]/,/^\[/" ~/.aws/config | grep -v "^\[" | grep -v "^$" | sed 's/^/  /'
      fi

      echo ""
      echo "Session info:"
      aws sts get-caller-identity 2>/dev/null || echo "  (not logged in or session expired)"
      echo ""
      echo "   Run 'awslist' to see all profiles"
    }

    # Low-level escape hatch: set/clear AWS_PROFILE by raw name.
    # `awsuse` is the normal switcher (validates against accounts.json);
    # `awsp <name>` sets a raw profile, `awsp` with no arg clears it.
    function awsp() {
      if [ -z "''${1:-}" ]; then
        unset AWS_PROFILE
        echo "→ AWS profile cleared"
      else
        export AWS_PROFILE="$1"
        echo "→ AWS_PROFILE=''${AWS_PROFILE}"
      fi
    }

    function awslist() {
      if [ ! -f ~/.aws/accounts.json ]; then
        echo "✗No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "→ AWS Accounts (from accounts.json):"
      echo ""

      # Group by project (handle missing alias field)
      jq -r 'to_entries[] |
        "\n\(.key) (\(.value.alias // .key))" +
        (if .value.description then " - \(.value.description)" else "" end) +
        "\n" +
        (
          .value.accounts | to_entries[] |
          "  • \(.key)      (" + (if (.value | type) == "object" then .value.id else .value end | tostring) + ")" +
          (if (.value | type) == "object" and .value.additional_roles then " → \(.value.additional_roles | join(", "))" else "" end)
        )
      ' ~/.aws/accounts.json 2>/dev/null || echo "Error parsing accounts.json"

      echo ""
      if [ -n "''${AWS_PROFILE:-}" ]; then
        echo "Current: ''${AWS_PROFILE} (active)"
      else
        echo "No profile currently set"
      fi
      echo ""
      echo "   Usage: awsuse <project|alias> <env> [role]"
    }

    function awswhere() {
      local account_id="''${1:-}"

      if [[ -z "$account_id" ]]; then
        echo "   Usage: awswhere <account-id>"
        echo "Example: awswhere 123456789012"
        return 1
      fi

      if [ ! -f ~/.aws/accounts.json ]; then
        echo "✗No accounts.json found"
        return 1
      fi

      echo "→ Searching for account: $account_id"
      echo ""

      local found=0
      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          echo "$line"
          found=1
        fi
      done < <(jq -r --arg id "$account_id" '
        to_entries[] |
        .key as $project |
        (.value.alias // "") as $alias |
        (.value.default_role // "support") as $default_role |
        .value.accounts | to_entries[] |
        select(
          ((.value | type) == "string" and .value == $id) or
          ((.value | type) == "object" and .value.id == $id)
        ) |
        .key as $env |
        (if (.value | type) == "object" and .value.additional_roles then
          [$default_role] + .value.additional_roles
        else
          [$default_role]
        end) as $roles |
        "→ Project: \($project) (\($alias))",
        "   Environment: \($env)",
        "   Profiles:",
        ($roles[] | "     • \($project)-\($env)" + (if . != $default_role then "-\(.)" else "" end) + " (\(.) role)")
      ' ~/.aws/accounts.json 2>/dev/null)

      if [[ $found -eq 0 ]]; then
        echo "✗Account ID not found: $account_id"
        return 1
      fi

      echo ""
      echo "   Switch: awsuse <project|alias> <env> [role]"
    }

    function awscheck() {
      echo "→ Checking SSO session status..."
      echo ""

      if [ ! -f ~/.aws/config ]; then
        echo "✗No AWS config found"
        return 1
      fi

      # Get all profiles into array
      local -a profiles
      profiles=("''${(@f)$(grep "^\[profile " ~/.aws/config | sed 's/\[profile //;s/\]//')}")

      if [[ ''${#profiles[@]} -eq 0 || -z "''${profiles[1]:-}" ]]; then
        echo "No profiles configured in ~/.aws/config"
        return 0
      fi

      for profile in "''${profiles[@]}"; do
        [[ -z "$profile" ]] && continue
        printf "%-30s " "$profile:"
        if AWS_PROFILE=$profile aws sts get-caller-identity &>/dev/null; then
          echo "✓ Active"
        else
          echo "✗Expired/Not logged in"
        fi
      done

      echo ""
      echo "   Login: awslogin <project> <env> [role]"
    }
  '';

  # ==================================================
  # AWS PROFILE AUTO-RESTORE
  # ==================================================
  mkAwsProfileAutoRestore = ''
    # Auto-restore last AWS profile.
    # Uses zsh's `$(<file)` special form (no fork) instead of `$(cat ...)`
    # — the latter triggers the SIGCHLD waitforpid race on macOS 15+ and
    # wedges the shell during `exec zsh`. See zsh.nix SIGCHLD-race notes.
    if [ -f ~/.aws/.last_profile ]; then
      export AWS_PROFILE="$(<~/.aws/.last_profile)"
      if [ -n "''${AWS_PROFILE:-}" ]; then
        printf '\033[90m aws: %s (restored)\033[0m\n' "''${AWS_PROFILE}"
      fi
    fi
  '';

  # ==================================================
  # AWS PROFILE SEARCH AND FILTERING
  # ==================================================
  mkAwsSearchCommands = ''
    function awsfind() {
      local query="''${1:-}"

      if [[ -z "$query" ]]; then
        echo "   Usage: awsfind <search-term>"
        echo ""
        echo "Search profiles by project name, alias, environment, or role"
        echo ""
        echo "Examples:"
        echo "  awsfind hft         # Find by project name"
        echo "  awsfind gen         # Find by alias"
        echo "  awsfind dev         # Find by environment"
        echo "  awsfind admin       # Find by role"
        return 1
      fi

      if [ ! -f ~/.aws/accounts.json ]; then
        echo "✗No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "→ Searching for: $query"
      echo ""

      local found=0
      local q_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          echo "$line"
          found=1
        fi
      done < <(jq -r --arg q "$q_lower" '
        to_entries[] |
        .key as $project |
        (.value.alias // "") as $alias |
        (.value.default_role // "support") as $default_role |
        (.value.description // "No description") as $desc |
        .value.accounts | to_entries[] |
        .key as $env |
        (if (.value | type) == "object" then .value.id else .value end) as $account_id |
        (if (.value | type) == "object" and .value.additional_roles then
          [$default_role] + .value.additional_roles
        else
          [$default_role]
        end) as $roles |
        select(
          ($project | ascii_downcase | contains($q)) or
          ($alias | ascii_downcase | contains($q)) or
          ($env | ascii_downcase | contains($q)) or
          ($roles | map(ascii_downcase) | any(contains($q)))
        ) |
        "→ \($project) (\($alias)) - \($desc)",
        "   • \($env) (Account: \($account_id))",
        ($roles[] | "     → \($project)-\($env)" + (if . != $default_role then "-\(.)" else "" end) + " (\(.) role)"),
        ""
      ' ~/.aws/accounts.json 2>/dev/null)

      if [[ $found -eq 0 ]]; then
        echo "✗No profiles found matching: $query"
        echo ""
        echo "   Try: awslist (to see all profiles)"
        return 1
      fi

      echo "   Switch: awsuse <project|alias> <env> [role]"
    }

    function awsfilter() {
      local type="''${1:-}"
      local value="''${2:-}"

      if [[ -z "$type" || -z "$value" ]]; then
        echo "   Usage: awsfilter <type> <value>"
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
        echo "✗No accounts.json found at ~/.aws/accounts.json"
        return 1
      fi

      echo "→ Filtering by $type: $value"
      echo ""

      local found=0

      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
          echo "$line"
          found=1
        fi
      done < <(jq -r --arg val "$value" --arg type "$type" '
        to_entries[] |
        . as $proj |
        (.value.default_role // "support") as $default_role |
        select(
          if $type == "project" or $type == "proj" or $type == "p" then
            (.key == $val or (.value.alias // "") == $val)
          elif $type == "env" or $type == "environment" or $type == "e" then
            .value.accounts | has($val)
          elif $type == "role" or $type == "r" then
            [
              .value.accounts | to_entries[] |
              (
                if (.value | type) == "object" and .value.additional_roles then
                  [$default_role] + .value.additional_roles
                else
                  [$default_role]
                end
              ) | contains([$val])
            ] | any
          else
            false
          end
        ) |
        "→ \(.key) (\(.value.alias // .key))" +
        (if .value.description then " - \(.value.description)" else "" end) +
        "\n" +
        (
          if $type == "env" or $type == "environment" or $type == "e" then
            .value.accounts | to_entries[] |
            select(.key == $val) |
            "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
            (
              (
                if (.value | type) == "object" and .value.additional_roles then
                  [$default_role] + .value.additional_roles
                else
                  [$default_role]
                end
              )[] |
              "     → \($proj.key)-\($val)" + (if . != $default_role then "-\(.)" else "" end) + " (\(.) role)"
            )
          elif $type == "role" or $type == "r" then
            [
              .value.accounts | to_entries[] |
              select(
                (
                  if (.value | type) == "object" and .value.additional_roles then
                    [$default_role] + .value.additional_roles
                  else
                    [$default_role]
                  end
                ) | contains([$val])
              ) |
              "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
              "     → \($proj.key)-\(.key)" + (if $val != $default_role then "-\($val)" else "" end) + " (\($val) role)"
            ] | join("\n")
          else
            [
              .value.accounts | to_entries[] |
              "   • \(.key) (Account: \(.value.id // .value | tostring))\n" +
              (
                (
                  if (.value | type) == "object" and .value.additional_roles then
                    [$default_role] + .value.additional_roles
                  else
                    [$default_role]
                  end
                )[] |
                "     → \($proj.key)-\(.key)" + (if . != $default_role then "-\(.)" else "" end) + " (\(.) role)"
              )
            ] | join("\n")
          end
        ) +
        "\n"
      ' ~/.aws/accounts.json 2>/dev/null)

      if [[ $found -eq 0 ]]; then
        echo "✗No profiles found with $type: $value"
        echo ""
        echo "   Try: awslist (to see all profiles)"
        return 1
      fi

      echo ""
      echo "   Switch: awsuse <project|alias> <env> [role]"
    }
  '';
}
