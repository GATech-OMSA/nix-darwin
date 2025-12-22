# aws-completion.zsh
# Zsh completion for AWS helper functions (awsuse, awslogin)
# Reads from ~/.aws/accounts.json using jq

# Define completion function for awsuse and awslogin
_aws_helper_completion() {
  local -a projects
  local -a envs
  local -a roles
  
  # Check if accounts.json exists
  if [[ ! -f ~/.aws/accounts.json ]]; then
    return
  fi

  # Get current command state
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:project:->projects' \
    '2:environment:->envs' \
    '3:role:->roles' \
    && return

  case $state in
    projects)
      # Extract project keys and aliases
      # Format: "project:alias"
      local -a project_list
      project_list=($(jq -r 'to_entries[] | "\(.key):\(.value.alias)"' ~/.aws/accounts.json 2>/dev/null))
      
      # Build completion list
      local -a completions
      for item in "${project_list[@]}"; do
        local key="${item%%:*}"
        local alias="${item##*:}"
        completions+=("$key" "$alias")
      done
      
      _describe 'project' completions
      ;;

    envs)
      # Get the project from the first argument
      local project_arg="${line[1]}"
      
      # Resolve alias to project key if needed
      local project_key=$(jq -r --arg p "$project_arg" 'to_entries[] | select(.key == $p or .value.alias == $p) | .key' ~/.aws/accounts.json 2>/dev/null)
      
      if [[ -n "$project_key" ]]; then
        # Get environments for this project
        local -a env_list
        env_list=($(jq -r --arg p "$project_key" '.[$p].accounts | keys[]' ~/.aws/accounts.json 2>/dev/null))
        _describe 'environment' env_list
      fi
      ;;

    roles)
      # Get project and environment
      local project_arg="${line[1]}"
      local env_arg="${line[2]}"
      
      # Resolve alias to project key
      local project_key=$(jq -r --arg p "$project_arg" 'to_entries[] | select(.key == $p or .value.alias == $p) | .key' ~/.aws/accounts.json 2>/dev/null)
      
      if [[ -n "$project_key" ]]; then
        # Get roles for this specific account/env
        # Default is always "support" (standard access)
        local -a role_list
        role_list=("support")
        
        # Add additional roles if defined
        local extra_roles
        extra_roles=$(jq -r --arg p "$project_key" --arg e "$env_arg" '.[$p].accounts[$e].additional_roles[]' ~/.aws/accounts.json 2>/dev/null)
        
        if [[ -n "$extra_roles" ]]; then
          role_list+=($(echo "$extra_roles"))
        fi
        
        # Add common role aliases
        role_list+=("dev" "admin" "ds" "de" "da")
        
        _describe 'role' role_list
      fi
      ;;
  esac
}

# Register completion for awsuse and awslogin
compdef _aws_helper_completion awsuse awslogin
