# Library Functions

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

### Machine Type Helpers

Detect and respond to machine type (personal vs work).

#### `machineType`

Determine machine type from hostname.

```nix
myLib.machineType "mbp-jimmy"  # => "personal"
myLib.machineType "mbp-work"   # => "work"
```

#### `isPersonal` / `isWork`

Boolean checks for machine type.

```nix
if myLib.isPersonal hostname then "personal-config" else "work-config"
```

#### `selectByMachine`

Select value based on machine type (most useful!).

```nix
gitEmail = myLib.selectByMachine hostname {
  personal = "jimmy-jain@users.noreply.github.com";
  work = "first.last@work-domain.com";
  default = "fallback@email.com";  # optional
};
```

**Real usage:** See `home/jimmy/programs/git.nix:5` and `aws.nix:82`

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

#### `mkScaffoldFunction`

Create project scaffolding function.

```nix
myLib.mkScaffoldFunction {
  name = "newproject";
  baseDir = "$HOME/Dev";
  description = "Create new project";
  template = ''
    touch README.md
    git init
    echo "# $project_name" > README.md
  '';
}
```

#### `mkTimedFunction`

Wrap function with duration tracking.

```nix
myLib.mkTimedFunction {
  name = "benchmark-task";
  body = "heavy-computation";
}
# Outputs: ⏱️  Duration: 2m 30s
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

### Environment Management

#### `mkEnvManagerFunction`

Generate environment manager function (conda, venv, etc.).

```nix
myLib.mkEnvManagerFunction {
  tool = "micromamba";
  name = "activate-env";
  action = "activate";
  listCommand = "micromamba env list";
}
```

Generates function with usage help and environment listing.

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

#### `mkPackageGroup`

Simple package group from list of names.

```nix
home.packages = myLib.mkPackageGroup ["git" "vim" "curl"] pkgs;
```

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

### Utility Functions

#### `filterAttrs`

Filter attribute set by predicate.

```nix
enabledPackages = myLib.filterAttrs
  (name: pkg: pkg.meta.available or true)
  allPackages;
```

#### `mapAttrValues`

Map function over all attribute values.

```nix
upperCaseVars = myLib.mapAttrValues
  (v: lib.toUpper v)
  myVars;
```

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
