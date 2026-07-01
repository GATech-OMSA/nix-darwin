# Library Functions

> ⚠️ **This README is stale** (2026-07-01): it documents ~14 helpers that were
> removed during the `c85cf20` secrets/AWS/setup simplification. **Trust
> `default.nix` as the source of truth** — only ~10 helpers actually exist:
> `selectByProfile`, `mkProfileSessionVars`, `msg`, `mkLazyCompletion`,
> `mkNavigationAliases`, `secrets`, `aws.*`, `reload.*`, `go.proxyVars`,
> `isWorkProfile`. A full rewrite is tracked as `perf-dedup #002`.

This directory contains reusable Nix helper functions and utilities used across your nix-darwin configuration.

## Purpose

Centralize common logic and reduce code duplication. This library provides 30+ functions organized into 10 categories covering machine type detection, shell function generation, navigation, status messages, and more.

## Quick Start

All functions are available through `myLib` parameter in your modules:

```nix
{ config, pkgs, myLib, hostname, ... }:

{
  # Use any library function
  programs.git.userEmail = myLib.selectByMachine hostname {
    personal = "personal@email.com";
    work = "work@email.com";
  };
}
```

---

## Function Reference

### Profile Helpers

Select values based on profile (personal/work/minimal).

#### `isPersonalProfile` / `isWorkProfile`

Boolean checks for profile.

```nix
if myLib.isPersonalProfile profileName then "personal-config" else "work-config"
```

#### `selectByProfile`

Select value based on profile (most useful!).

```nix
gitEmail = myLib.selectByProfile profileName {
  personal = "jimmy-jain@users.noreply.github.com";
  work = "user@example.com";
  default = "fallback@email.com";  # optional
};
```

**Real usage:** See `_template/programs/aws.nix` and `modules/darwin/system.nix`

#### `importIf` / `importIfPersonal` / `importIfWork`

Conditionally import modules.

```nix
imports = [
  ./base.nix
]
++ myLib.importIfPersonal hostname ./personal.nix
++ myLib.importIfWork hostname ./work.nix;
```

**Real usage:** See `home/jimmy/default.nix:51-52`

---

### Shell Function Generators

Generate consistent shell functions with error handling.

#### `mkUpdateFunction`

Create update function with error handling and status messages.

```nix
myLib.mkUpdateFunction {
  name = "update-custom";
  command = "custom-tool update";
  description = "Updating custom tool";
}
```

Generates:

```bash
function update-custom() {
  echo "🔄 Updating custom tool..."
  local errors=0
  if custom-tool update; then
    echo "  ✅ update-custom completed"
  else
    echo "  ❌ update-custom failed" >&2
    ((errors++))
  fi
  return $errors
}
```

---

### Navigation & Aliases

#### `mkNavigationAliases`

Generate directory navigation aliases (eliminates 20+ manual aliases).

```nix
programs.zsh.shellAliases = myLib.mkNavigationAliases "$HOME/Dev" {
  proj1 = "project1";
  learning = "learning";
  aiml = "ai-ml";
};
# Results in:
# { proj1 = "cd $HOME/Dev/project1"; learning = "cd $HOME/Dev/learning"; ... }
```

---

### Status Messages

Consistent emoji-prefixed status messages for shell scripts.

#### `msg.*`

```nix
${myLib.msg.success "Build completed"}     # ✅ Build completed
${myLib.msg.error "Build failed"}          # ❌ Build failed (to stderr)
${myLib.msg.warning "Deprecated"}          # ⚠️  Deprecated
${myLib.msg.info "Processing"}             # ℹ️  Processing
${myLib.msg.loading "Updating"}            # 🔄 Updating...
${myLib.msg.rocket "Launching"}            # 🚀 Launching
${myLib.msg.package "Installing"}          # 📦 Installing
${myLib.msg.pin "Location"}                # 📍 Location
```

Eliminates 40+ inconsistent echo statements across codebase.

---

### Command Helpers

#### `mkCommandCheck`

Check if command exists and execute conditional code.

```nix
initExtra = myLib.mkCommandCheck {
  command = "docker";
  onSuccess = "docker ps";
  onFailure = "echo Docker not installed";
};
```

Eliminates 28+ `command -v ... &> /dev/null` patterns.

#### `mkFunctionWithArgs`

Generate function with automatic argument validation.

```nix
myLib.mkFunctionWithArgs {
  name = "deploy";
  requiredArgs = 2;
  usage = "<environment> <version>";
  body = ''
    echo "Deploying $2 to $1"
    # ... deployment logic
  '';
}
```

Generates:

```bash
function deploy() {
  if [ -z "$1" ]; then
    echo "Usage: deploy <environment> <version>"
    return 1
  fi
  if [ -z "$2" ]; then
    echo "Usage: deploy <environment> <version>"
    return 1
  fi
  echo "Deploying $2 to $1"
  # ...
}
```

Eliminates 19+ manual argument checks.

---

### Package Management

#### `mkConditionalPackages`

Include packages based on condition.

```nix
home.packages = myLib.mkConditionalPackages {
  condition = myLib.isWork hostname;
  packages = [ pkgs.kubectl pkgs.awscli2 ];
};
```

#### `mkPackageGroups`

Manage multiple package groups with enable/disable flags.

```nix
home.packages = myLib.mkPackageGroups {
  devTools = {
    enabled = true;
    packages = [ "git" "vim" "tmux" ];
  };
  infrastructure = {
    enabled = false;  # Easily toggle entire groups
    packages = [ "terraform" "ansible" "packer" ];
  };
  dataTools = {
    enabled = myLib.isWork hostname;  # Conditional on machine type
    packages = [ "postgresql" "redis" "sqlite" ];
  };
} pkgs;
```

Much cleaner than commenting/uncommenting individual packages!

---

### File Helpers

#### `mkSourceIfExists`

Source file only if it exists (safe sourcing).

```nix
initExtra = myLib.mkSourceIfExists "~/.zsh_local";
```

#### `mkSourcePlugins`

Source multiple plugin files safely.

```nix
initExtra = myLib.mkSourcePlugins [
  { path = "~/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; }
  { path = "~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; }
];
```

Eliminates 5+ manual `[ -f ... ] && source ...` checks.

---

### Environment Variables

#### `mkEnvVars`

Create environment variable set (ensures all values are strings).

```nix
home.sessionVariables = myLib.mkEnvVars {
  EDITOR = "vim";
  PAGER = "less";
  DEBUG = true;  # Converted to "true"
};
```

#### `mergeEnvVars`

Merge multiple environment variable sets.

```nix
home.sessionVariables = myLib.mergeEnvVars [
  baseVars
  machineVars
  userVars
];
```

---

### Configuration Helpers

#### `mergeConfigs`

Merge multiple configuration objects.

```nix
myConfig = myLib.mergeConfigs [
  baseConfig
  personalConfig
  projectConfig
];
```

#### `mkStarshipPreset`

Generate Starship preset configuration.

```nix
home.file.".config/starship.toml".source =
  myLib.mkStarshipPreset "catppuccin-powerline" pkgs;
```

**Real usage:** See `home/_mixins/base.nix:58-61`

---

---

## Usage Patterns

### Pattern 1: Machine-Specific Configuration

```nix
{ myLib, hostname, ... }:

{
  programs.git.userEmail = myLib.selectByMachine hostname {
    personal = "personal@email.com";
    work = "work@email.com";
  };

  home.packages = myLib.mkConditionalPackages {
    condition = myLib.isWork hostname;
    packages = [ pkgs.kubectl pkgs.terraform ];
  };
}
```

### Pattern 2: Navigation Shortcuts

```nix
{ myLib, ... }:

{
  programs.zsh.shellAliases =
    myLib.mkNavigationAliases "$HOME/Dev" {
      proj1 = "project1";
      proj2 = "project2";
      learning = "learning";
    } // myLib.mkNavigationAliases "$HOME/Documents" {
      docs = ".";
      notes = "Notes";
    };
}
```

### Pattern 3: Conditional Package Groups

```nix
{ myLib, hostname, ... }:

{
  home.packages = myLib.mkPackageGroups {
    core = {
      enabled = true;
      packages = [ "git" "vim" "curl" ];
    };
    development = {
      enabled = myLib.isPersonal hostname;
      packages = [ "docker" "kubectl" "terraform" ];
    };
    work = {
      enabled = myLib.isWork hostname;
      packages = [ "awscli2" "azure-cli" ];
    };
  } pkgs;
}
```

---

## Impact

Using these library functions across your configuration:

| Metric             | Before           | After             | Improvement            |
| ------------------ | ---------------- | ----------------- | ---------------------- |
| Hostname checks    | 10+ scattered    | 1 centralized     | Single source of truth |
| Navigation aliases | 20+ manual       | Generated         | DRY principle          |
| Status messages    | 40+ inconsistent | Standardized      | Consistent UX          |
| Command checks     | 28+ repeated     | Reusable function | Maintainability        |
| Package groups     | Commented blocks | Toggle flags      | Easy management        |

---

## Best Practices

1. **Use machine type helpers** - Replace all hostname checks with `myLib.selectByMachine`
2. **Generate navigation aliases** - Don't manually write `cd` aliases
3. **Consistent status messages** - Use `myLib.msg.*` in shell functions
4. **Leverage package groups** - Toggle groups instead of commenting packages
5. **Document usage** - Add comments showing which lib function is being used

---

## Real Examples in This Repo

Functions already in use:

- **`selectByMachine`** - `home/jimmy/programs/git.nix:5`, `aws.nix:82`
- **`importIfPersonal/Work`** - `home/jimmy/default.nix:51-52`
- **`mkStarshipPreset`** - `home/_mixins/base.nix:58-61`

See `lib/default.nix` for complete function implementations with inline documentation.

---

## See Also

- [Nixpkgs Lib Reference](https://nixos.org/manual/nixpkgs/stable/#sec-functions-library)
- [Architecture Overview](../docs/architecture/overview.md)
- [overlays/README.md](../overlays/README.md) - Package customization
- [pkgs/README.md](../pkgs/README.md) - Custom packages

---

## Database & Credential Helpers (`database`)

Generate database connection functions and token helpers with file permission validation.

### `mkDatabaseConnector`

Generate database connection function with validation.

**Usage**:
```nix
myLib.database.mkDatabaseConnector {
  name = "oracle";
  command = "sqlplus \${USERNAME}/\${PASSWORD}@\${HOST}:\${PORT}/\${SERVICE_NAME}";
  description = "Oracle";
}
```

**Generated Function**: `dbconnect-oracle [environment]`
**Default Environment**: prod
**Available Environments**: prod, dev, qa, test
**Features**: File permission validation (600), environment variable sourcing

### `mkDatabaseConnectors`

Generate multiple database connector functions at once.

**Usage**:
```nix
myLib.database.mkDatabaseConnectors [
  { name = "oracle"; command = "..."; description = "Oracle"; }
  { name = "mssql"; command = "..."; description = "SQL Server"; }
]
```

### `mkDatabaseList`

Generate `dblist` function to show all configured databases.

**Usage**:
```nix
myLib.database.mkDatabaseList [
  { name = "oracle"; label = "Oracle"; }
  { name = "mssql"; label = "SQL Server"; }
]
```

**Generated Function**: `dblist`

### `mkTokenHelper`

Generate token helper function that copies token to clipboard.

**Usage**:
```nix
myLib.database.mkTokenHelper {
  name = "git";
  description = "Git token";
  file = "git_token";
}
```

**Generated Function**: `git-token`
**Features**: File permission validation (600), clipboard copy

### `mkTokenHelpers`

Generate multiple token helper functions.

**Example Usage in work.nix**:
```nix
${myLib.database.mkTokenHelpers [
  { name = "git"; description = "Git token"; file = "git_token"; }
  { name = "terraform"; description = "HCP Terraform token"; file = "hcp_terraform_token"; }
  { name = "jira"; description = "Jira API token"; file = "jira_api_token"; }
]}
```

**Token Reduction**: 150 lines → 30 lines (80% reduction)

### `mkDatabaseInstance` (NEW - Enterprise)

Generate instance-based database connector using environment variables instead of credential files. **Perfect for rotating passwords.**

**Key Benefits**:
- ✅ No file management required
- ✅ Credential rotation without Nix rebuild (just `exec zsh`)
- ✅ Single encrypted file for all credentials
- ✅ Instance-based organization (not type-based)

**Variable Naming Pattern**: `<INSTANCE>_<ENV>_<TYPE>`

**Usage**:
```nix
myLib.database.mkDatabaseInstance {
  instance = "ti";                           # Instance name (lowercase)
  type = "oracle";                           # oracle, mssql, postgres, mysql
  environments = ["dev" "qa" "prod"];        # Available environments
  description = "Tririga Oracle Database";
}
```

**Generated Function**: `dbconnect-ti [environment]`
**Default Environment**: prod

**Required Environment Variables** (example for TI prod Oracle):
```bash
TI_PROD_USERNAME="ti_prod"
TI_PROD_PASSWORD="rotating-password"
TI_PROD_HOST="prod-oracle.company.com"
TI_PROD_PORT="1521"
TI_PROD_SERVICE="TIPROD"
```

**Credentials Management**:
- Edit: `edit-credentials`
- Reload: `exec zsh` (NO nix rebuild!)
- Stored: `~/.secrets/credentials.env.enc` (encrypted with SOPS)

### `mkDatabaseInstances`

Generate multiple instance-based database connectors at once.

**Usage**:
```nix
myLib.database.mkDatabaseInstances [
  { instance = "ti"; type = "oracle"; environments = ["dev" "qa" "prod"]; description = "Tririga"; }
  { instance = "hrdb"; type = "mssql"; environments = ["prod"]; description = "HR Database"; }
]
```

### `mkInstanceList`

Generate `dblist-instances` function to show all configured database instances.

**Usage**:
```nix
myLib.database.mkInstanceList [
  { instance = "ti"; type = "oracle"; environments = ["dev" "qa" "prod"]; description = "Tririga"; }
]
```

**Generated Function**: `dblist-instances`

---

## AWS Helpers (`aws`)

Generate AWS profile switching aliases for quick environment switching.

### `mkAwsProfileAliases`

Generate AWS profile switching aliases.

**Usage**:
```nix
myLib.aws.mkAwsProfileAliases {
  project = "tririga-integrations";
  environments = [ "dev" "sbx" "qa" "prod" ];
}
```

**Generated Aliases**:
- `awsdev` → `awsuse tririga-integrations-dev`
- `awssbx` → `awsuse tririga-integrations-sbx`
- `awsqa` → `awsuse tririga-integrations-qa`
- `awsprod` → `awsuse tririga-integrations-prod`

### `mkAwsProjectAliases`

Generate AWS profile aliases for multiple projects.

**Usage**:
```nix
myLib.aws.mkAwsProjectAliases [
  { project = "tririga-integrations"; environments = [ "dev" "sbx" "qa" "prod" ]; }
  { project = "project2"; environments = [ "dev" "prod" ]; }
]
```

### `mkAwsProfileAliasesWithPrefix`

Generate AWS profile aliases with custom prefix (for multiple projects).

**Usage**:
```nix
myLib.aws.mkAwsProfileAliasesWithPrefix {
  prefix = "ti";  # tririga-integrations
  project = "tririga-integrations";
  environments = [ "dev" "sbx" "qa" "prod" ];
}
```

**Generated Aliases**: `tidev`, `tisbx`, `tiqa`, `tiprod`

### `mkAwsUniversalCommand` (NEW - Enterprise)

Generate universal AWS profile switching command with role support and profile persistence.

**Key Benefits**:
- ✅ Single command pattern: `awsuse <project> <env> [role]`
- ✅ Short name support: `awsuse ti dev` instead of `awsuse tririga-integrations dev`
- ✅ Profile persistence across shell sessions
- ✅ Corporate policy enforcement (developer role only in sbx)
- ✅ Automatic validation of project/environment/role combinations

**Pattern**: `awsuse <project> <env> [role]`
**Default Role**: support

**Usage**:
```nix
myLib.aws.mkAwsUniversalCommand {
  projects = [
    {
      name = "tririga-integrations";
      short = "ti";
      environments = ["dev" "sbx" "qa" "prod"];
      roles = ["support" "developer" "data-engineer"];
    }
    {
      name = "hr-system";
      short = "hr";
      environments = ["qa" "prod"];
      roles = ["support"];
    }
  ];
}
```

**Generated Function**: `awsuse <project> <env> [role]`

**Examples**:
```bash
awsuse tririga-integrations dev         → ti-dev-support
awsuse ti sbx developer                 → ti-sbx-developer
awsuse hr qa                            → hr-qa-support (short name)
```

**Features**:
- Profile validation against ~/.aws/config
- Auto-save to ~/.aws/.last_profile for session persistence
- Corporate policy: developer role restricted to sbx environment
- Helpful error messages with usage examples

### `mkAwsSsoLogin`

Generate AWS SSO login command with automatic profile setting.

**Pattern**: `awslogin <project> <env> [role]`
**Performs**: SSO login + automatic AWS_PROFILE setting

**Usage**: Same project configuration as `mkAwsUniversalCommand`

**Generated Function**: `awslogin <project> <env> [role]`

**Examples**:
```bash
awslogin tririga-integrations dev
awslogin ti sbx developer
awslogin hr prod
```

**What it does**:
1. Opens browser for SSO authentication
2. Sets AWS_PROFILE environment variable
3. Saves profile to ~/.aws/.last_profile
4. Profile auto-restores on next shell start

### `mkAwsInfoCommands`

Generate AWS profile information commands.

**Generated Functions**:
- `awswho` - Show current profile and session details
- `awslist` - List all available profiles from ~/.aws/config

**Usage**:
```nix
${myLib.aws.mkAwsInfoCommands}
```

**Examples**:
```bash
# Show current profile
awswho
# Output:
# 📋 Current AWS Profile: ti-dev-support
# Profile configuration:
#   sso_session = domain-sso
#   sso_account_id = 123456789012
#   ...

# List all profiles
awslist
# Output:
# 📋 Available AWS Profiles:
#   tririga-integrations-dev-support
#   tririga-integrations-sbx-developer
#   ...
```

### `mkAwsProfileAutoRestore`

Generate shell initialization code to auto-restore last AWS profile on shell start.

**Usage**:
```nix
# Add to zsh initExtra (ALREADY INCLUDED in zsh.nix)
${myLib.aws.mkAwsProfileAutoRestore}
```

**What it does**:
- Reads ~/.aws/.last_profile on shell start
- Sets AWS_PROFILE automatically
- Shows confirmation message

**Output on shell start**:
```
🔄 Restored AWS Profile: ti-dev-support
💡 Run 'awswho' for details or 'awsuse' to switch
```

---

## Mixin Helpers (`mixin`)

Standardize mixin structure for machine-specific configurations.

### `mkMixin`

Create mixin with standard structure.

**Usage**:
```nix
myLib.mixin.mkMixin {
  type = "work";
  packages = [ pkgs.unixODBC ];
  sessionVariables = { MACHINE_MODE = "work"; };
  shellAliases = { ... };
  initExtra = ''...'';
}
```

### `mkConditionalMixinComponents`

Create mixin components that apply conditionally.

**Usage**:
```nix
myLib.mixin.mkConditionalMixinComponents {
  condition = hostname == "mbp-work";
  packages = [ pkgs.work-tool ];
  sessionVariables = { WORK_MODE = "true"; };
}
```

### `mergeMixins`

Merge multiple mixins into a single configuration.

**Usage**:
```nix
myLib.mixin.mergeMixins [
  (mkMixin { type = "base"; ... })
  (mkMixin { type = "dev"; ... })
]
```
