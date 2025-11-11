# Configuration Examples

**Real-world nix-darwin setup patterns for different use cases**

This guide shows practical configuration patterns extracted from production setups. Each example demonstrates key architectural decisions, common tradeoffs, and migration paths.

---

## Quick Navigation

- [Minimal Personal Setup](#minimal-personal-setup) - Bare bones personal Mac
- [Work/Enterprise Setup](#workenterprise-setup) - Corporate environment with security
- [Multi-User Household](#multi-user-household) - Shared Mac with multiple users
- [Development Workstation](#development-workstation) - Heavy development focus

---

## Overview

**Purpose**: These examples teach configuration patterns through real implementations, not just listing options.

**What's Included**:
- Target audience and use case
- Key architectural decisions and tradeoffs
- Minimal working configurations
- Common customizations
- Migration paths from existing setups

**What's NOT Included**:
- Exhaustive option listings (see official docs)
- Copy-paste configs without explanation
- One-size-fits-all templates

---

## Minimal Personal Setup

**Target Audience**: Personal Mac users wanting declarative system management without complexity

**Use Case**: Single-user personal Mac with basic development tools, GUI apps, and secrets management.

### Key Characteristics

✅ **What's Included**:
- Essential GUI apps via Homebrew
- Basic development tools (git, python, node)
- Encrypted secrets (SSH keys, AWS credentials)
- Shell customization (zsh + starship)
- Automatic system updates

❌ **What's NOT Included**:
- Complex database tooling
- Multi-environment AWS configurations
- Corporate security requirements
- Heavy development language stacks

### Architecture Decisions

**1. Homebrew for GUI Apps**
```nix
# hosts/mbp-personal/default.nix
homebrew.enable = true;  # ← Use Homebrew for GUI apps
```

**Why**: Nix doesn't package all macOS GUI apps well. Homebrew handles updates automatically.

**Tradeoff**: Less declarative (Homebrew state not in flake.lock), but more practical.

**Alternative**: Pure Nix with `home.packages` (more declarative, fewer apps available).

---

**2. SOPS for Secrets**
```nix
# hosts/mbp-personal/default.nix
sops = {
  age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
  defaultSopsFile = ./secrets.yaml;

  secrets = {
    # Minimal secret set
    zsh_secrets = { path = "/Users/${username}/.zsh_secrets"; mode = "0600"; };
    ssh_private_key = { path = "/Users/${username}/.ssh/id_ed25519"; mode = "0600"; };
    aws_credentials = { path = "/Users/${username}/.aws/credentials"; mode = "0600"; };
  };
};
```

**Why**: Encrypted secrets in git without exposing sensitive data.

**Tradeoff**: Requires age key setup, but secrets are portable and encrypted.

**Alternative**: Manual secret management (simpler, less secure).

---

**3. Mixin System for Modularity**
```nix
# flake.nix
darwinConfigurations."mbp-personal" = mkDarwinSystem {
  hostname = "mbp-personal";
  username = "yourname";
  mixins = [ "base" "personal" ];  # ← Minimal mixins
};
```

**Why**: Separates base config (common to all machines) from personal-specific settings.

**Tradeoff**: Slightly more complex than single file, but scales better.

---

### Minimal File Structure

```
nix-darwin/
├── flake.nix                    # System definition
├── hosts/
│   └── mbp-personal/
│       ├── default.nix          # Host config (networking, secrets)
│       └── secrets.yaml         # Encrypted secrets (SOPS)
├── modules/
│   ├── darwin/
│   │   ├── default.nix          # macOS system settings
│   │   └── homebrew.nix         # GUI apps (VS Code, Chrome, etc.)
│   └── shared/
│       └── packages.nix         # CLI tools (git, curl, etc.)
└── home/
    ├── yourname/
    │   ├── default.nix          # Home Manager entry point
    │   ├── shell/
    │   │   └── zsh.nix          # Shell config + aliases
    │   └── programs/
    │       ├── git.nix          # Git config + aliases
    │       └── starship.nix     # Prompt theme
    └── _mixins/
        ├── base.nix             # Common to all machines
        └── personal.nix         # Personal-specific (MACHINE_MODE=home)
```

---

### Essential Packages

**CLI Tools** (`modules/shared/packages.nix`):
```nix
environment.systemPackages = with pkgs; [
  # Version control
  git
  gh              # GitHub CLI

  # Shell utilities
  curl
  wget
  jq              # JSON processor
  ripgrep         # Fast grep
  fd              # Fast find
  bat             # Better cat
  eza             # Better ls

  # Development
  python313
  nodejs_22
  uv              # Fast Python package manager

  # System utilities
  htop
  neofetch
  tree
];
```

**GUI Apps** (`modules/darwin/homebrew.nix`):
```nix
homebrew = {
  enable = true;

  # Taps (third-party repositories)
  taps = [
    "homebrew/cask"
    "homebrew/cask-fonts"
  ];

  # GUI applications
  casks = [
    # Browser & communication
    "google-chrome"
    "slack"
    "zoom"

    # Development
    "visual-studio-code"
    "iterm2"
    "docker"

    # Utilities
    "rectangle"       # Window management
    "alfred"          # Spotlight alternative
    "1password"       # Password manager
  ];

  # Mac App Store apps (optional)
  masApps = {
    "Xcode" = 497799835;
  };
};
```

---

### Common Customizations

**1. Add Shell Aliases**

Edit `home/yourname/shell/zsh.nix`:
```nix
programs.zsh.shellAliases = {
  # Git shortcuts
  gs = "git status -s";
  ga = "git add";
  gc = "git commit -m";
  gp = "git push";

  # Directory shortcuts
  dev = "cd ~/Dev";
  projects = "cd ~/Dev/projects";

  # System shortcuts
  rebuild = "darwin-rebuild switch --flake ~/nix-darwin";
  update = "nix flake update ~/nix-darwin";
};
```

**2. Add Python Development**

Edit `home/yourname/development/python.nix`:
```nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    python313
    uv                    # Fast package/venv manager
    micromamba            # Conda alternative (optional)
  ];

  # Auto-activate venv on cd
  programs.zsh.initExtra = ''
    # Activate .venv if it exists
    if [[ -d .venv ]] && [[ -z "$VIRTUAL_ENV" ]]; then
      source .venv/bin/activate
    fi
  '';
}
```

**3. Add VS Code Extensions**

Edit `home/yourname/programs/vscode.nix`:
```nix
programs.vscode = {
  enable = true;
  extensions = with pkgs.vscode-extensions; [
    # Language support
    ms-python.python
    ms-vscode.cpptools
    golang.go

    # Utilities
    eamodio.gitlens
    esbenp.prettier-vscode
    dbaeumer.vscode-eslint
  ];
};
```

---

### Migration from Manual Setup

**From Homebrew-only setup**:

1. **Inventory current apps**:
   ```bash
   brew list --cask > ~/current-apps.txt
   ```

2. **Create minimal `flake.nix`** (use template from `hosts/_template/`)

3. **Add apps to `homebrew.nix`**:
   ```nix
   casks = [
     # Copy from current-apps.txt
   ];
   ```

4. **Build without switching**:
   ```bash
   darwin-rebuild build --flake ~/nix-darwin
   ```

5. **Switch when ready**:
   ```bash
   darwin-rebuild switch --flake ~/nix-darwin
   ```

**From dotfiles setup**:

1. **Copy existing configs**: `~/.zshrc`, `~/.gitconfig`, etc.
2. **Convert to Nix incrementally**: Start with shell, then git, then packages
3. **Keep both during transition**: Nix configs override dotfiles
4. **Delete dotfiles after validation**: Nix now manages everything

---

## Work/Enterprise Setup

**Target Audience**: Corporate Mac users with security requirements, VPN, and database access

**Use Case**: Work Mac with corporate security policies, multi-database access, AWS multi-account, and compliance requirements.

### Key Characteristics

✅ **What's Included**:
- Corporate certificate bundles
- Multi-environment database connections
- AWS multi-account/multi-role support
- Encrypted secrets for credentials
- ODBC drivers and database clients
- Corporate VPN and proxy support

❌ **What's NOT Included**:
- Personal productivity apps
- Gaming or entertainment software
- Personal AWS accounts
- Non-work development projects

### Architecture Decisions

**1. Disable Homebrew (Security Policy)**
```nix
# hosts/mbp-work/default.nix
homebrew.enable = false;  # ← Corporate security: no third-party packages
```

**Why**: Corporate security requires all software from approved sources (Nix, IT-provided installers).

**Tradeoff**: Fewer GUI apps available, but compliant with security policy.

**Workaround**: Use Nix-packaged alternatives or request IT-approved installers.

---

**2. Database Connection Management**
```nix
# home/_mixins/work.nix
programs.zsh.initContent = ''
  ${myLib.database.mkDatabaseInstances [
    {
      instance = "ti";              # Tririga
      type = "oracle";
      environments = [ "dev" "qa" "prod" ];
      description = "Tririga Oracle Database";
    }
    {
      instance = "hrdb";            # HR Database
      type = "mssql";
      environments = [ "prod" ];
      description = "HR SQL Server";
    }
    # Add more databases as needed
  ]}
'';
```

**Why**: Standardized database connection functions across multiple environments.

**Usage**: `dbconnect-ti dev`, `dbconnect-hrdb prod`

**Tradeoff**: Requires environment variables in encrypted credentials file, but connections are consistent.

---

**3. AWS Multi-Account Management**
```nix
# home/_mixins/work.nix
programs.zsh.initContent = ''
  ${myLib.aws.mkAwsAccountHelper}    # awsuse, awslogin
  ${myLib.aws.mkAwsInfoCommands}     # awswho, awslist, awswhere
  ${myLib.aws.mkAwsProfileAutoRestore}  # Restore last profile on shell start
'';
```

**Why**: Multiple AWS accounts (dev, sbx, qa, prod) with multiple roles (developer, support) per account.

**Configuration**: `~/.aws/accounts.json` (outside Nix, allows runtime updates)

**Usage**:
```bash
awsuse ti sbx developer     # Switch to Tririga sandbox developer role
awslogin ps prod            # Login to Paging Solution production
awswho                      # Show current profile
```

**See**: [AWS Multi-Role Guide](../../claudedocs/reference/aws/AWS-MULTI-ROLE.md) for complete setup.

---

**4. Corporate CA Bundle**
```nix
# home/_mixins/work.nix
programs.aws = {
  caBundle = "~/.config/certs/cacert.pem";  # ← Corporate root CA
};
```

**Why**: Corporate proxy injects CA certificate for SSL inspection.

**Setup**: Export CA from Keychain, place in `~/.config/certs/`

**Tradeoff**: Required for corporate network, but not portable to other networks.

---

### Work-Specific File Structure

```
nix-darwin/
├── flake.nix
├── hosts/
│   └── mbp-work/
│       ├── default.nix          # Work-specific secrets (commented)
│       └── secrets.yaml         # Encrypted work secrets (SOPS)
├── home/
│   ├── username/
│   │   ├── shell/zsh.nix        # Shell with work functions
│   │   └── programs/
│   │       └── git.nix          # Work email configured here
│   └── _mixins/
│       ├── base.nix             # Common
│       ├── dev.nix              # Dev tools
│       └── work.nix             # Work-specific (MACHINE_MODE=work)
└── user-data/                   # Outside git (runtime configs)
    ├── aws/
    │   └── accounts.json        # AWS account definitions
    └── secrets/
        └── credentials.env.enc  # Database credentials (encrypted)
```

---

### Work-Specific Packages

**Database Clients** (`home/_mixins/work.nix`):
```nix
home.packages = with pkgs; [
  # ODBC drivers
  unixODBC           # ODBC driver manager
  freetds            # SQL Server ODBC driver
  postgresql_16      # PostgreSQL client + libpq

  # Database CLIs
  pgcli              # PostgreSQL CLI with autocomplete
  sqlcmd             # SQL Server CLI (if available)

  # Connection utilities
  dbeaver            # GUI database client (optional)
];
```

**Security Tools**:
```nix
home.packages = with pkgs; [
  # Certificate management
  openssl
  age                # Encryption for SOPS

  # VPN/networking
  openvpn            # If corporate VPN uses OpenVPN

  # Compliance
  gnupg              # GPG for signing
];
```

---

### Common Work Customizations

**1. Database Connection Shortcuts**

Add to `home/_mixins/work.nix`:
```nix
programs.zsh.shellAliases = {
  # Quick database connects
  tidev = "dbconnect-ti dev";
  tiprod = "dbconnect-ti prod";
  hrprod = "dbconnect-hrdb prod";
};
```

**2. Project Directory Navigation**

Add to `home/_mixins/work.nix`:
```nix
programs.zsh.shellAliases = {
  # Project shortcuts
  fti = "cd ~/Dev/tririga";
  fhr = "cd ~/Dev/hr-systems";
  fwfh = "cd ~/Dev/workforce-hub";
};
```

**3. AWS Account Aliases**

Edit `user-data/aws/accounts.json`:
```json
{
  "projects": {
    "tririga-integrations": {
      "aliases": {
        "ti": "tririga-integrations"
      },
      "accounts": {
        "sbx": { "id": "123456789012", "roles": ["developer", "support"] },
        "dev": { "id": "234567890123", "roles": ["developer", "support"] },
        "qa": { "id": "345678901234", "roles": ["developer", "support"] },
        "prod": { "id": "456789012345", "roles": ["support"] }
      }
    }
  }
}
```

**Usage**: `awsuse ti sbx` (alias) instead of `awsuse tririga-integrations sbx`

---

### Security Considerations

**1. Secrets Management**

⚠️ **SOPS Disabled in Work Example** (commented out in `hosts/mbp-work/default.nix`)

**Why**: Corporate proxy blocks Go module downloads required by sops-nix.

**Workaround**: Use encrypted credentials file outside Nix:
```bash
# Encrypt credentials
sops -e user-data/secrets/credentials.env > user-data/secrets/credentials.env.enc

# Edit credentials (auto-decrypts)
edit-credentials

# Load in shell
source <(sops -d user-data/secrets/credentials.env.enc)
```

**Alternative**: Use corporate secrets manager (Vault, AWS Secrets Manager, etc.)

---

**2. File Permissions**

Git hooks automatically validate:
```bash
chmod 600 ~/.db/*           # Database connection files
chmod 600 ~/.tokens/*       # API tokens
chmod 600 ~/.aws/credentials
```

**Pre-commit hook blocks** if permissions are insecure.

---

**3. Credential Rotation**

**Database credentials**:
```bash
edit-credentials            # Edit encrypted file
# Update passwords
exec zsh                    # Reload (no rebuild needed!)
```

**AWS credentials**:
```bash
awslogin <project> <env>    # Re-authenticate with SSO
```

**API tokens**:
```bash
edit-secrets                # Edit SOPS-encrypted secrets.yaml
nix-rebuild                 # Apply changes
```

---

### Migration from Manual Work Setup

**From manual corporate setup**:

1. **Audit current tools**:
   ```bash
   which sqlcmd pgcli aws python
   # Document all database clients, AWS profiles, etc.
   ```

2. **Extract database credentials** (if scattered):
   ```bash
   # Consolidate into user-data/secrets/credentials.env
   # Pattern: INSTANCE_ENV_FIELD (e.g., TI_PROD_USERNAME)
   ```

3. **Export AWS profiles**:
   ```bash
   # Extract from ~/.aws/config
   # Convert to accounts.json format
   ```

4. **Build test environment**:
   ```bash
   darwin-rebuild build --flake ~/nix-darwin#mbp-work
   ```

5. **Validate database connections**:
   ```bash
   dbconnect-ti dev
   dbconnect-hrdb prod
   ```

6. **Validate AWS access**:
   ```bash
   awsuse ti sbx
   aws s3 ls  # Test access
   ```

7. **Switch when validated**:
   ```bash
   darwin-rebuild switch --flake ~/nix-darwin#mbp-work
   ```

---

## Multi-User Household

**Target Audience**: Shared Mac with multiple family members or roommates

**Use Case**: Single Mac used by multiple people with separate configurations and secrets.

### Key Characteristics

✅ **What's Included**:
- Per-user home directories
- Separate secrets per user
- Shared system packages
- User-specific aliases and settings
- Fast user switching support

❌ **What's NOT Included**:
- Complex permission boundaries (use macOS user accounts for that)
- Enterprise multi-tenancy
- User isolation beyond macOS defaults

### Architecture Decisions

**1. Multiple Home Manager Configurations**
```nix
# flake.nix
darwinConfigurations."family-mac" = nix-darwin.lib.darwinSystem {
  modules = [
    home-manager.darwinModules.home-manager
    {
      home-manager.users = {
        alice = import ./home/alice;
        bob = import ./home/bob;
        charlie = import ./home/charlie;
      };
    }
  ];
};
```

**Why**: Each user gets independent home configuration (shell, git, packages).

**Tradeoff**: More config files, but true separation.

---

**2. Shared System Packages**
```nix
# modules/shared/packages.nix
environment.systemPackages = with pkgs; [
  # Shared CLI tools (all users)
  git
  curl
  wget
  htop

  # No user-specific tools here
];
```

**Why**: Common tools available to all users, user-specific tools in `home/<user>/`.

---

**3. Per-User Secrets**
```nix
# hosts/family-mac/default.nix
sops.secrets = {
  alice_ssh_key = { path = "/Users/alice/.ssh/id_ed25519"; owner = "alice"; };
  bob_ssh_key = { path = "/Users/bob/.ssh/id_ed25519"; owner = "bob"; };
  charlie_ssh_key = { path = "/Users/charlie/.ssh/id_ed25519"; owner = "charlie"; };
};
```

**Why**: Each user's secrets encrypted separately, owned by their user account.

---

### Multi-User File Structure

```
nix-darwin/
├── flake.nix                    # Defines all users
├── hosts/
│   └── family-mac/
│       ├── default.nix          # Shared system config
│       └── secrets.yaml         # All users' secrets (SOPS)
├── modules/
│   ├── darwin/                  # Shared macOS settings
│   └── shared/
│       └── packages.nix         # Shared CLI tools only
└── home/
    ├── alice/
    │   ├── default.nix
    │   ├── shell/zsh.nix        # Alice's shell config
    │   └── programs/git.nix     # Alice's git (email, etc.)
    ├── bob/
    │   ├── default.nix
    │   ├── shell/zsh.nix        # Bob's shell config
    │   └── programs/git.nix     # Bob's git
    └── charlie/
        ├── default.nix
        ├── shell/zsh.nix        # Charlie's shell config
        └── programs/git.nix     # Charlie's git
```

---

### Per-User Configuration Examples

**Alice (Developer)**:
```nix
# home/alice/default.nix
{ config, pkgs, ... }:

{
  home = {
    username = "alice";
    homeDirectory = "/Users/alice";
    stateVersion = "24.05";

    packages = with pkgs; [
      # Alice's development tools
      python313
      nodejs_22
      vscode
    ];
  };

  programs.git = {
    enable = true;
    userName = "Alice Smith";
    userEmail = "alice@example.com";
  };

  programs.zsh.shellAliases = {
    dev = "cd ~/Dev";
    projects = "cd ~/Dev/projects";
  };
}
```

**Bob (Designer)**:
```nix
# home/bob/default.nix
{ config, pkgs, ... }:

{
  home = {
    username = "bob";
    homeDirectory = "/Users/bob";
    stateVersion = "24.05";

    packages = with pkgs; [
      # Bob's design tools
      imagemagick
      ffmpeg
    ];
  };

  programs.git = {
    enable = true;
    userName = "Bob Jones";
    userEmail = "bob@example.com";
  };

  programs.zsh.shellAliases = {
    designs = "cd ~/Designs";
    portfolio = "cd ~/Designs/portfolio";
  };
}
```

---

### Common Multi-User Customizations

**1. User-Specific Homebrew Casks**

Homebrew casks are system-wide, but you can conditionally install per user:

```nix
# modules/darwin/homebrew.nix
{ config, lib, username, ... }:

{
  homebrew = {
    enable = true;

    casks = [
      # Shared apps (all users)
      "google-chrome"
      "slack"
    ] ++ lib.optionals (username == "alice") [
      # Alice-specific apps
      "visual-studio-code"
      "docker"
    ] ++ lib.optionals (username == "bob") [
      # Bob-specific apps
      "figma"
      "adobe-creative-cloud"
    ];
  };
}
```

**Note**: This requires rebuilding per user. Alternative: Use Homebrew directly for user-specific apps.

---

**2. Shared Project Directories**

Create shared workspace:
```bash
sudo mkdir -p /Users/Shared/Projects
sudo chmod 775 /Users/Shared/Projects
sudo chown -R :staff /Users/Shared/Projects
```

Add aliases for each user:
```nix
programs.zsh.shellAliases = {
  shared = "cd /Users/Shared/Projects";
};
```

---

### Migration from Single-User Setup

**From single-user to multi-user**:

1. **Backup existing config**:
   ```bash
   cp -r ~/nix-darwin ~/nix-darwin-backup
   ```

2. **Create user directories**:
   ```bash
   mkdir -p home/{alice,bob,charlie}
   ```

3. **Split existing `home/` into per-user**:
   - Copy `home/jimmy/` to each user
   - Update username, email, and user-specific settings

4. **Update `flake.nix`**:
   ```nix
   home-manager.users = {
     alice = import ./home/alice;
     bob = import ./home/bob;
     charlie = import ./home/charlie;
   };
   ```

5. **Move user-specific packages** from `modules/shared/packages.nix` to `home/<user>/default.nix`

6. **Split secrets** in `secrets.yaml`:
   ```yaml
   alice_ssh_key: |
     -----BEGIN OPENSSH PRIVATE KEY-----
     ...
   bob_ssh_key: |
     -----BEGIN OPENSSH PRIVATE KEY-----
     ...
   ```

7. **Test per user**:
   ```bash
   # Switch to alice's session
   darwin-rebuild switch --flake ~/nix-darwin

   # Verify alice's config active
   echo $HOME  # Should be /Users/alice
   ```

---

## Development Workstation

**Target Audience**: Software engineers with heavy development tooling needs

**Use Case**: Development-focused Mac with multiple language runtimes, databases, containers, and toolchains.

### Key Characteristics

✅ **What's Included**:
- Multiple language runtimes (Python, Node.js, Go, Rust)
- Local development databases (PostgreSQL, Redis)
- Container orchestration (Docker, Kubernetes)
- Advanced shell tools and workflows
- Development environment management

❌ **What's NOT Included**:
- Production deployment tooling
- Work-specific corporate tools
- Non-development applications

### Architecture Decisions

**1. Multiple Language Runtimes**
```nix
# home/dev/development/
home.packages = with pkgs; [
  # Python
  python313
  python312
  uv                    # Fast venv manager
  micromamba            # Conda environments

  # JavaScript/TypeScript
  nodejs_22
  nodejs_20             # LTS
  bun                   # Fast runtime
  deno                  # Alternative runtime

  # Go
  go_1_22

  # Rust
  rustc
  cargo

  # JVM
  jdk21
  gradle
  maven
];
```

**Why**: Multiple runtime versions for project compatibility.

**Tradeoff**: Disk space for multiple versions, but flexibility for any project.

---

**2. Development Databases**
```nix
# Use Homebrew services for local databases
homebrew.casks = [
  "postgresql@16"
  "redis"
  "mongodb-community"
];

# Or use Docker Compose
# See: https://github.com/docker/awesome-compose
```

**Why**: Local databases for development, no cloud dependencies.

**Tradeoff**: Resource usage, but faster development cycle.

---

**3. Container Tooling**
```nix
home.packages = with pkgs; [
  docker
  docker-compose
  kubectl
  k9s              # Kubernetes TUI
  helm
  skaffold         # Local Kubernetes dev
];
```

**Why**: Modern development uses containers extensively.

---

### Development-Specific File Structure

```
nix-darwin/
├── flake.nix
├── hosts/
│   └── dev-workstation/
│       ├── default.nix
│       └── secrets.yaml         # API keys, GitHub tokens
├── home/
│   └── dev/
│       ├── default.nix
│       ├── development/
│       │   ├── python.nix       # Python tools + auto-venv
│       │   ├── node.nix         # Node.js + global packages
│       │   ├── go.nix           # Go tooling
│       │   └── rust.nix         # Rust toolchain
│       ├── shell/
│       │   └── zsh.nix          # Dev-focused aliases
│       └── programs/
│           ├── git.nix          # Git config + hooks
│           ├── vscode.nix       # VS Code + extensions
│           └── tmux.nix         # Terminal multiplexer
└── _mixins/
    ├── base.nix
    └── dev.nix                  # Development mixin
```

---

### Development Tools

**Python Development** (`home/dev/development/python.nix`):
```nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    python313
    uv                    # Fast package manager
    micromamba            # Conda alternative
    pyright               # Type checker
    ruff                  # Fast linter
  ];

  # Auto-activate venv on directory change
  programs.zsh.initExtra = ''
    # Activate virtual environment automatically
    function auto_venv() {
      if [[ -d .venv ]] && [[ -z "$VIRTUAL_ENV" ]]; then
        echo "🐍 Activating virtual environment: .venv"
        source .venv/bin/activate
      fi
    }

    # Run on directory change
    chpwd_functions+=(auto_venv)

    # Run on shell start
    auto_venv
  '';
}
```

**Node.js Development** (`home/dev/development/node.nix`):
```nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    pnpm                  # Fast package manager
    typescript
    eslint_d              # Fast linter daemon
  ];

  # Global npm packages
  home.file.".npmrc".text = ''
    prefix=$HOME/.npm-global
  '';

  programs.zsh.sessionVariables = {
    PATH = "$HOME/.npm-global/bin:$PATH";
  };
}
```

**Go Development** (`home/dev/development/go.nix`):
```nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    go_1_22
    golangci-lint         # Linter
    delve                 # Debugger
    gopls                 # Language server
  ];

  programs.zsh.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };

  programs.zsh.shellAliases = {
    got = "go test ./...";
    gob = "go build";
    gor = "go run .";
  };
}
```

---

### Development Workflow Enhancements

**1. Project Templates**

Add project scaffolding functions:
```nix
programs.zsh.initExtra = ''
  # Scaffold new Python project
  function new-py() {
    local name=$1
    mkdir -p $name/{src,tests}
    cd $name
    uv venv
    source .venv/bin/activate
    uv pip install pytest black ruff
    echo "Python project $name created!"
  }

  # Scaffold new Node project
  function new-js() {
    local name=$1
    mkdir -p $name
    cd $name
    pnpm init
    pnpm add -D typescript @types/node eslint prettier
    echo "Node.js project $name created!"
  }
'';
```

---

**2. Development Aliases**

Add to `home/dev/shell/zsh.nix`:
```nix
programs.zsh.shellAliases = {
  # Docker shortcuts
  dps = "docker ps";
  dcu = "docker-compose up -d";
  dcd = "docker-compose down";
  dcl = "docker-compose logs -f";

  # Kubernetes shortcuts
  k = "kubectl";
  kgp = "kubectl get pods";
  kgs = "kubectl get services";
  kdp = "kubectl describe pod";

  # Git worktree shortcuts
  gwl = "git worktree list";
  gwa = "git worktree add";
  gwr = "git worktree remove";

  # Testing shortcuts
  t = "pytest";                    # Python
  jt = "jest";                     # JavaScript
  got = "go test ./...";           # Go
  ct = "cargo test";               # Rust
};
```

---

**3. VS Code Extensions for Development**

Add to `home/dev/programs/vscode.nix`:
```nix
programs.vscode = {
  enable = true;
  extensions = with pkgs.vscode-extensions; [
    # Language support
    ms-python.python
    ms-python.vscode-pylance
    ms-vscode.cpptools
    golang.go
    rust-lang.rust-analyzer

    # Web development
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    bradlc.vscode-tailwindcss

    # Containers & Cloud
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools

    # Utilities
    eamodio.gitlens
    github.copilot
    vscodevim.vim
  ];

  userSettings = {
    "editor.formatOnSave" = true;
    "python.linting.enabled" = true;
    "python.linting.ruffEnabled" = true;
    "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[python]"."editor.defaultFormatter" = "ms-python.python";
  };
};
```

---

### Local Development Infrastructure

**Docker Compose for Services**:

Create `~/Dev/.infrastructure/docker-compose.yml`:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: dev
      POSTGRES_USER: dev
      POSTGRES_DB: dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  mongodb:
    image: mongo:7
    environment:
      MONGO_INITDB_ROOT_USERNAME: dev
      MONGO_INITDB_ROOT_PASSWORD: dev
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

volumes:
  postgres_data:
  mongo_data:
```

**Add alias**:
```nix
programs.zsh.shellAliases = {
  dev-services = "docker-compose -f ~/Dev/.infrastructure/docker-compose.yml";
  dev-up = "dev-services up -d";
  dev-down = "dev-services down";
  dev-logs = "dev-services logs -f";
};
```

---

### Migration from Development-Heavy Setup

**From manual development setup**:

1. **Audit installed tools**:
   ```bash
   # List all language runtimes
   which python python3 node npm go cargo rustc
   python --version
   node --version
   go version
   ```

2. **Document global packages**:
   ```bash
   pip list --user > ~/python-packages.txt
   npm list -g --depth=0 > ~/npm-packages.txt
   ```

3. **Export VS Code extensions**:
   ```bash
   code --list-extensions > ~/vscode-extensions.txt
   ```

4. **Create Nix config** with equivalent packages

5. **Test in isolated directory**:
   ```bash
   mkdir -p ~/test-nix-dev
   cd ~/test-nix-dev
   # Clone sample project
   # Verify tools work
   ```

6. **Switch when validated**:
   ```bash
   darwin-rebuild switch --flake ~/nix-darwin
   ```

7. **Clean up old installs** (optional):
   ```bash
   # Uninstall Homebrew Python, Node, etc.
   # Remove ~/.pyenv, ~/.nvm, etc.
   ```

---

## Comparison Matrix

| Feature | Minimal Personal | Work/Enterprise | Multi-User | Dev Workstation |
|---------|------------------|-----------------|------------|-----------------|
| **Homebrew** | ✅ Enabled | ❌ Disabled | ✅ Enabled | ✅ Enabled |
| **SOPS Secrets** | ✅ Basic | ⚠️ Commented | ✅ Per-user | ✅ API Keys |
| **AWS Multi-Role** | ❌ Single | ✅ Complex | ❌ N/A | ⚠️ Optional |
| **Database Tools** | ❌ None | ✅ ODBC + CLI | ❌ None | ✅ Local DBs |
| **Language Runtimes** | ⚠️ Basic | ⚠️ Work-specific | ⚠️ Per-user | ✅ Multiple |
| **Container Tools** | ❌ None | ⚠️ Optional | ❌ None | ✅ Full Stack |
| **Complexity** | 🟢 Low | 🔴 High | 🟡 Medium | 🟡 Medium |
| **Setup Time** | 1-2 hours | 4-6 hours | 2-3 hours | 3-4 hours |

---

## Next Steps

**After choosing an example**:

1. **Review example configuration** matching your use case
2. **Understand architectural decisions** and tradeoffs
3. **Start with minimal version** (fewer packages, simpler secrets)
4. **Build iteratively** (add features as needed)
5. **Refer to detailed guides**:
   - [Installation Guide](installation.md) - Setup process
   - [Usage Guide](usage.md) - Daily operations
   - [Secrets Guide](secrets.md) - SOPS configuration
   - [Architecture Overview](../architecture/overview.md) - System design

**Need help?**
- [Troubleshooting Guide](troubleshooting.md) - Common issues
- [FAQ](../appendix/faq.md) - Frequently asked questions

---

**Version**: 1.0.0
**Last Updated**: 2025-11-07
**Status**: Complete ✅
