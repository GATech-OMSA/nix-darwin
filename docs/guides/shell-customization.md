# Shell Customization Guide

**Customize your Zsh shell, aliases, functions, and prompt to match your workflow**

---

## Overview

This guide covers customizing your shell environment in nix-darwin. You'll learn where configuration lives, how to add aliases and functions, customize your prompt, and leverage powerful helper functions from the library system.

**Key Principle**: All shell configuration is declarative - changes require `nix-rebuild` to take effect.

---

## Where Shell Config Lives

### Primary Configuration Files

| File | Purpose | Examples |
|------|---------|----------|
| `home/jimmy/shell/zsh.nix` | Shell aliases, functions, initialization | 100+ shell aliases, update functions |
| `home/jimmy/programs/git.nix` | Git aliases and settings | 60+ git aliases with `g` prefix |
| `home/_mixins/base.nix` | Starship prompt, base tools | Prompt config, zoxide, fzf, bat |

### Helper Functions

The `lib/` directory contains 30+ helper functions that simplify shell configuration:
- Machine type detection (`selectByMachine`)
- Navigation alias generation (`mkNavigationAliases`)
- Shell function templates (`mkUpdateFunction`, `mkFunctionWithArgs`)
- Status messages (`msg.success`, `msg.error`, etc.)

See [lib/README.md](../../lib/README.md) for complete reference.

---

## Adding Shell Aliases

### Basic Pattern

Edit `home/jimmy/shell/zsh.nix` and add to the `shellAliases` section:

```nix
shellAliases = myLib.aws.mkAwsAliasesFromJson // {
  # Your custom aliases
  myalias = "command to run";
  shortcut = "long-command --with-flags";
};
```

### Examples

**Simple shortcuts:**
```nix
# Quick directory access
projects = "cd ~/Dev/projects";
docs = "cd ~/Documents";

# Command shortcuts
ll = "ls -lah";
ports = "lsof -i -P -n | grep LISTEN";
```

**Complex aliases with parameters:**
```nix
# Git shortcuts (use g prefix)
# Already included: g s, g aa, g cm, g ps
# Add your own:
gfp = "git fetch --all --prune";
gcl = "git clone";
```

**Conditional aliases (machine-specific):**
```nix
# Use helper function for machine-specific config
work-vpn = myLib.selectByMachine hostname {
  work = "cisco-anyconnect --connect work-vpn";
  personal = "echo 'VPN only on work machine'";
};
```

### Navigation Aliases

**Don't manually create `cd` aliases!** Use the helper function:

```nix
# Instead of this:
# projects = "cd ~/Dev/projects";
# learning = "cd ~/Dev/learning";
# aiml = "cd ~/Dev/ai-ml";

# Do this:
shellAliases = myLib.mkNavigationAliases "$HOME/Dev" {
  projects = "projects";
  learning = "learning";
  aiml = "ai-ml";
} // {
  # Your other aliases
  reload = "source ~/.zshrc";
};
```

**Benefits**: Eliminates 20+ manual aliases, DRY principle, consistent pattern.

---

## Adding Shell Functions

### Using Helper Functions

**Update functions** (with error handling):

```nix
initExtra = ''
  # Use helper to create update function
  ${myLib.mkUpdateFunction {
    name = "update-custom";
    command = "custom-tool update";
    description = "Updating custom tool";
  }}
'';
```

**Functions with arguments** (automatic validation):

```nix
initExtra = ''
  ${myLib.mkFunctionWithArgs {
    name = "deploy";
    requiredArgs = 2;
    usage = "<environment> <version>";
    body = ''
      echo "Deploying $2 to $1"
      # deployment logic here
    '';
  }}
'';
```

### Manual Functions

For custom logic not covered by helpers:

```nix
initExtra = ''
  # Custom function with manual implementation
  function my-custom-function() {
    if [ -z "$1" ]; then
      echo "Usage: my-custom-function <argument>"
      return 1
    fi

    echo "Processing: $1"
    # Your logic here
  }

  # Database connector with validation
  function connect-db() {
    local env=''${1:-prod}
    local cred_file="$HOME/.db/oracle/$env"

    if [ ! -f "$cred_file" ]; then
      echo "❌ Credentials not found: $cred_file"
      return 1
    fi

    source "$cred_file"
    sqlplus $USERNAME/$PASSWORD@$HOST:$PORT/$SERVICE_NAME
  }
'';
```

### Using Status Messages

Use consistent emoji-prefixed messages:

```nix
initExtra = ''
  function build-project() {
    ${myLib.msg.loading "Building project"}

    if make build; then
      ${myLib.msg.success "Build completed"}
    else
      ${myLib.msg.error "Build failed"}
      return 1
    fi
  }
'';
```

Available: `msg.success`, `msg.error`, `msg.warning`, `msg.info`, `msg.loading`, `msg.rocket`, `msg.package`, `msg.pin`

---

## Customizing the Prompt

### Starship Configuration

The prompt is configured using [Starship](https://starship.rs/) with Catppuccin powerline theme.

**Configuration file**: `home/_mixins/starship.toml`

**Current features**:
- OS and username indicator
- Directory path with truncation
- Git status (branch, changes, ahead/behind)
- AWS profile indicator
- Kubernetes context
- Language versions (Python, Node.js, etc.)
- Conda environment
- Time and command duration

### Customizing Prompt Segments

**Enable/disable segments:**

```toml
# Edit home/_mixins/starship.toml

# Disable AWS indicator
[aws]
disabled = true

# Enable Docker context
[docker_context]
disabled = false
```

**Adjust segment colors** (using Catppuccin palette):

```toml
[directory]
style = "bg:peach fg:crust"  # Change background/foreground
format = "[ $path ]($style)[$read_only]($read_only_style)"
```

**Available colors**: red, peach, yellow, green, teal, sky, sapphire, blue, lavender

**Customize symbols:**

```toml
[git_branch]
symbol = "󰊤 "  # Change git branch symbol

[python]
symbol = ""  # Python icon
format = '[[ $symbol( $version)(\(#$virtualenv\)) ](fg:crust bg:green)]($style)'
```

**Add directory substitutions:**

```toml
[directory.substitutions]
"Documents" = "󰈙 "
"Developer" = "󰲋 "
"my-project" = " "  # Custom project icon
```

### Testing Prompt Changes

After editing `starship.toml`:

```bash
nix-rebuild
exec zsh
```

**Preview changes** without rebuild (temporary):
```bash
# Copy your changes to test
cp ~/nix-darwin/home/_mixins/starship.toml ~/.config/starship.toml
exec zsh
```

**Reference**: [Starship Configuration](https://starship.rs/config/) for all options.

---

## Machine-Specific Configuration

### Using Mixins

Different behavior for personal vs work machines:

**Personal Mac** (`home/_mixins/personal.nix`):
- Personal AWS profiles
- Personal email in git
- MACHINE_MODE="home"

**Work Mac** (`home/_mixins/work.nix`):
- Work AWS profiles, SSO functions
- Work email in git
- MACHINE_MODE="work"
- Database connectors

### Conditional Configuration

**In zsh.nix:**

```nix
shellAliases = {
  # Common aliases for all machines
  c = "clear";
  reload = "source ~/.zshrc";
} // (if myLib.isWork hostname then {
  # Work-only aliases
  vpn = "cisco-anyconnect --connect";
  jira = "open https://work-jira.com";
} else {
  # Personal-only aliases
  blog = "cd ~/Dev/blog && code .";
});
```

**Using selectByMachine** (cleaner):

```nix
editor = myLib.selectByMachine hostname {
  personal = "code";
  work = "code-insiders";
  default = "vim";
};
```

---

## Testing Shell Changes

### Standard Workflow

1. **Edit configuration:**
   ```bash
   nixconf  # Opens VS Code
   # Edit home/jimmy/shell/zsh.nix
   ```

2. **Rebuild system:**
   ```bash
   nix-rebuild
   ```

3. **Restart shell:**
   ```bash
   exec zsh
   ```

4. **Test your changes:**
   ```bash
   # Test alias
   myalias

   # Test function
   my-function arg1 arg2
   ```

### Quick Testing (No Rebuild)

For temporary testing only:

```bash
# Test alias
alias testme="echo 'it works'"
testme

# Test function
function testfn() { echo "Testing $1"; }
testfn hello
```

**Note**: These changes disappear when you restart the shell. Add to `zsh.nix` for persistence.

---

## Common Patterns

### Navigation Shortcuts

```nix
# Use helper for project navigation
shellAliases = myLib.mkNavigationAliases "$HOME/Dev" {
  proj1 = "project-one";
  proj2 = "project-two";
  learning = "learning-resources";
};
```

### Environment Switchers

```nix
initExtra = ''
  function use-python() {
    local version=''${1:-3.13}
    export PATH="$HOME/.local/share/uv/python/$version/bin:$PATH"
    ${myLib.msg.success "Using Python $version"}
  }
'';
```

### Quick File Access

```nix
shellAliases = {
  hosts = "sudo code /etc/hosts";
  sshconf = "code ~/.ssh/config";
  awsconf = "code ~/.aws/config";
};
```

### Status Checkers

```nix
initExtra = ''
  function check-services() {
    ${myLib.msg.info "Checking services"}

    ${myLib.mkCommandCheck {
      command = "docker";
      onSuccess = "echo '✅ Docker running'";
      onFailure = "echo '❌ Docker not running'";
    }}

    ${myLib.mkCommandCheck {
      command = "kubectl";
      onSuccess = "kubectl cluster-info";
      onFailure = "echo '❌ Kubernetes not configured'";
    }}
  }
'';
```

---

## Advanced Customization

### Package Groups Management

Use helper to organize packages by category:

```nix
# In home/jimmy/default.nix
home.packages = myLib.mkPackageGroups {
  core = {
    enabled = true;
    packages = [ "git" "curl" "wget" ];
  };
  development = {
    enabled = true;
    packages = [ "docker" "kubectl" "terraform" ];
  };
  personal = {
    enabled = myLib.isPersonal hostname;
    packages = [ "hugo" "obs-studio" ];
  };
} pkgs;
```

**Benefits**: Toggle entire groups, machine-specific packages, clean organization.

### Environment Variables

```nix
home.sessionVariables = myLib.mkEnvVars {
  EDITOR = "code --wait";
  PAGER = "less -R";
  MACHINE_MODE = myLib.selectByMachine hostname {
    personal = "home";
    work = "work";
  };
};
```

### Source External Files

```nix
initExtra = ''
  # Source file only if exists
  ${myLib.mkSourceIfExists "~/.zsh_local"}

  # Source multiple files
  ${myLib.mkSourcePlugins [
    { path = "~/.oh-my-zsh/custom/plugins/plugin1/plugin1.zsh"; }
    { path = "~/.oh-my-zsh/custom/plugins/plugin2/plugin2.zsh"; }
  ]}
'';
```

---

## Best Practices

### Organization

1. **Group related aliases** - Use comments to organize sections
2. **Use helpers** - Don't duplicate patterns (navigation, updates, checks)
3. **Machine-specific mixins** - Keep personal/work config separate
4. **Document complex functions** - Add comments explaining purpose

### Naming Conventions

1. **Shell aliases** - Short, memorable (e.g., `c`, `reload`, `nixconf`)
2. **Git aliases** - Use `g` prefix (e.g., `g s`, `g cm`, `g ps`)
3. **Functions** - Descriptive names with hyphens (e.g., `update-all`, `connect-db`)
4. **Navigation** - Match directory names (e.g., `projects`, `learning`)

### Testing

1. **Test before committing** - Always rebuild and verify changes work
2. **Start small** - Add one alias/function at a time
3. **Use status messages** - Helpful for debugging functions
4. **Validate functions** - Test with edge cases (missing args, errors)

### Maintenance

1. **Review regularly** - Remove unused aliases/functions
2. **Update documentation** - Keep comments current
3. **Leverage helpers** - Migrate manual patterns to lib functions
4. **Share patterns** - Contribute useful functions to lib/

---

## Troubleshooting

### Changes Not Applied

```bash
# Did you rebuild?
nix-rebuild

# Did you restart shell?
exec zsh

# Check if file was modified
git status
```

### Function Errors

```bash
# Check syntax
zsh -n ~/nix-darwin/home/jimmy/shell/zsh.nix

# Debug with verbose rebuild
nix-rebuild-debug
```

### Alias Conflicts

```bash
# Check if alias already exists
which myalias
alias | grep myalias

# Use unique names or override intentionally
```

### Git Aliases Not Working

Git aliases use `g` prefix: `g s` not `gs`, `g cm` not `gcm`

See [Shell Reference - Git](../reference/shell.md#git) for complete list.

---

## Examples

### Minimal Customization

```nix
# Add a few personal shortcuts
shellAliases = {
  repos = "cd ~/Dev/repos";
  notes = "code ~/Documents/notes";
  weather = "curl wttr.in";
};
```

### Moderate Customization

```nix
# Navigation + functions + machine-specific
shellAliases = myLib.mkNavigationAliases "$HOME/Dev" {
  backend = "backend-services";
  frontend = "frontend-app";
  mobile = "mobile-app";
} // {
  ports = "lsof -i -P -n | grep LISTEN";
  killport = "lsof -ti:$1 | xargs kill -9";
};

initExtra = ''
  function work-on() {
    cd ~/Dev/$1
    code .
    ${myLib.msg.success "Working on $1"}
  }
'';
```

### Advanced Customization

```nix
# Full integration with helpers, machine-specific, complex functions
shellAliases = myLib.mkNavigationAliases "$HOME/Dev" {
  proj1 = "project-one";
  proj2 = "project-two";
} // (myLib.selectByMachine hostname {
  work = {
    vpn = "cisco-anyconnect --connect work-vpn";
    jira = "open https://work-jira.com";
  };
  personal = {
    blog = "cd ~/Dev/blog && code .";
  };
});

initExtra = ''
  ${myLib.mkUpdateFunction {
    name = "update-deps";
    command = "npm update && pip install -U -r requirements.txt";
    description = "Updating project dependencies";
  }}

  ${myLib.mkFunctionWithArgs {
    name = "deploy";
    requiredArgs = 1;
    usage = "<environment>";
    body = ''
      ${myLib.msg.loading "Deploying to $1"}
      ./scripts/deploy.sh $1
      ${myLib.msg.success "Deployed to $1"}
    '';
  }}
'';
```

---

## Related Documentation

- **[Shell Reference](../reference/shell.md)** - Complete list of all 100+ shell aliases and 60+ git aliases
- **[lib/README.md](../../lib/README.md)** - All 30+ helper functions with examples
- **[Usage Guide](usage.md)** - Daily usage patterns and workflows
- **[Architecture Overview](../architecture/overview.md)** - Understanding the mixin system
- **[Starship Documentation](https://starship.rs/)** - Official prompt customization guide

---

**Master your shell environment with declarative configuration!**
