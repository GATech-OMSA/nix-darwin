# Phase 2: Profile Structure Creation - Profile Migration

**Duration**: ~8 hours
**Prerequisites**: Phase 1 complete
**Risk Level**: Medium (structural changes, requires careful testing)

---

## Overview

Phase 2 creates the new profile-based directory structure and migrates existing functionality from mixins to profiles. This phase establishes the foundation for profile-based architecture without changing the flake.nix entry point yet.

---

## Directory Structure Design

```
home/
├── _profiles/              # NEW: Profile-based configurations
│   ├── personal/
│   │   ├── default.nix     # Profile entry point
│   │   ├── packages.nix    # Profile-specific packages
│   │   ├── aliases.nix     # Profile-specific aliases
│   │   ├── starship.toml   # Personal prompt theme
│   │   └── programs/       # Profile-specific program configs
│   │       ├── git.nix
│   │       ├── vscode.nix
│   │       └── zsh.nix
│   │
│   ├── work/
│   │   ├── default.nix     # Profile entry point
│   │   ├── packages.nix    # Work-specific packages
│   │   ├── aliases.nix     # Work-specific aliases
│   │   ├── starship.toml   # Work prompt theme
│   │   ├── aws.nix         # AWS configuration
│   │   ├── database.nix    # Database instances
│   │   └── programs/       # Profile-specific program configs
│   │
│   ├── minimal/
│   │   ├── default.nix     # Minimal profile
│   │   ├── packages.nix    # Bare minimum packages
│   │   └── aliases.nix     # Essential aliases only
│   │
│   └── _template/          # Shared base (replaces home/_template)
│       ├── programs/       # Base program configs
│       └── shell/          # Base shell configs
│
├── _mixins/                # KEEP: For backward compatibility during transition
│   └── (existing files)
│
└── jimmy/                  # KEEP: User-specific but profile-agnostic
    └── (existing files)
```

---

## Tasks

### Task 2.1: Create Profile Directory Structure
**Effort**: 30 minutes
**Priority**: Critical
**Risk**: Low

**Action**:
```bash
# 1. Create profile directories
mkdir -p home/_profiles/{personal,work,minimal,_template}
mkdir -p home/_profiles/personal/programs
mkdir -p home/_profiles/work/programs
mkdir -p home/_profiles/minimal/programs
mkdir -p home/_profiles/_template/{programs,shell}

# 2. Add .gitkeep files
touch home/_profiles/personal/programs/.gitkeep
touch home/_profiles/work/programs/.gitkeep
touch home/_profiles/minimal/programs/.gitkeep

# 3. Verify structure
tree home/_profiles/ -L 2
```

**Acceptance Criteria**:
- [ ] All profile directories created
- [ ] Subdirectories for programs created
- [ ] Structure matches design diagram
- [ ] Git tracks directories (.gitkeep files)

---

### Task 2.2: Create Personal Profile Template
**Effort**: 2 hours
**Priority**: Critical
**Risk**: Medium

**Problem**: Need to migrate content from `home/_mixins/personal.nix` to profile structure

**Current State**: personal.nix has:
- 7 packages (learning-specific)
- 18 aliases (learning, ollama, personal projects)
- Session variables
- Integration with base.nix and dev.nix

**Action**:
```bash
# 1. Create home/_profiles/personal/default.nix
cat > home/_profiles/personal/default.nix << 'EOF'
# home/_profiles/personal/default.nix
#
# Personal profile configuration
# For: Learning, personal projects, hobby development

{ config, pkgs, lib, myLib, hostname, ... }:

{
  imports = [
    ../template/programs  # Base program configs
    ../template/shell     # Base shell configs
    ./packages.nix        # Personal packages
    ./aliases.nix         # Personal aliases
    ./programs            # Personal program overrides
  ];

  # Personal-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "home";
    WORKSPACE = "$HOME/Dev";
  };

  # Starship prompt (personal theme)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
EOF

# 2. Create home/_profiles/personal/packages.nix
# Migrate from personal.nix lines 14-50
cat > home/_profiles/personal/packages.nix << 'EOF'
# home/_profiles/personal/packages.nix
#
# Packages specific to personal profile

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Learning & Education
    jupyter         # Interactive notebooks
    obsidian        # Knowledge management

    # Personal Development
    # (migrated from personal.nix)
  ];
}
EOF

# 3. Create home/_profiles/personal/aliases.nix
# Migrate from personal.nix lines 68-110
cat > home/_profiles/personal/aliases.nix << 'EOF'
# home/_profiles/personal/aliases.nix
#
# Aliases specific to personal profile

{ config, lib, myLib, ... }:

{
  programs.zsh.shellAliases = {
    # Learning directories (from personal.nix)
    learning = "cd ~/learning";
    aiml = "cd ~/learning/ai-ml";
    algo = "cd ~/Dev/algorithms";  # Fixed: was missing
    courses = "cd ~/learning/courses";
    experiments = "cd ~/learning/experiments";
    oss = "cd ~/Dev/oss-contributions";

    # Ollama (from personal.nix)
    ollama-start = "ollama serve";
    models = "ollama list";
    llama3 = "ollama run llama3";
    codellama = "ollama run codellama";
  };
}
EOF

# 4. Copy personal starship theme
cp home/_mixins/starship.toml home/_profiles/personal/starship.toml

# 5. Test build (doesn't activate yet, just validates syntax)
nix-instantiate --eval --expr '(import ./home/_profiles/personal/default.nix { inherit (import <nixpkgs> {}) pkgs lib; myLib = {}; hostname = "test"; config = {}; }).imports'
```

**Acceptance Criteria**:
- [ ] personal/default.nix created with proper imports
- [ ] personal/packages.nix has all personal packages
- [ ] personal/aliases.nix has all personal aliases (including algo)
- [ ] personal/starship.toml copied
- [ ] Nix syntax validates
- [ ] No functionality lost from personal.nix

**Validation**:
```bash
# Check all personal aliases present
rg "learning|aiml|algo|courses|experiments|oss|ollama" \
  home/_profiles/personal/aliases.nix | wc -l  # Should be 10

# Check package count matches
rg "pkgs\." home/_profiles/personal/packages.nix | wc -l  # Should match personal.nix
```

---

### Task 2.3: Create Work Profile Template
**Effort**: 3 hours
**Priority**: Critical
**Risk**: High (complex AWS/database integration)

**Problem**: Need to migrate complex work.nix (445 lines) to profile structure while preserving AWS multi-role and database connectivity

**Current State**: work.nix has:
- 20+ work-specific packages
- AWS multi-role system integration
- 6 database instance connectors
- Work-specific aliases and functions
- Complex zsh initContent with helper integration

**Action**:
```bash
# 1. Create home/_profiles/work/default.nix
cat > home/_profiles/work/default.nix << 'EOF'
# home/_profiles/work/default.nix
#
# Work profile configuration
# For: Corporate development, AWS infrastructure, database connectivity

{ config, pkgs, lib, myLib, hostname, ... }:

{
  imports = [
    ../template/programs  # Base program configs
    ../template/shell     # Base shell configs
    ./packages.nix        # Work-specific packages
    ./aliases.nix         # Work-specific aliases
    ./aws.nix             # AWS configuration
    ./database.nix        # Database instances
    ./programs            # Work program overrides
  ];

  # Work-specific session variables
  home.sessionVariables = {
    MACHINE_MODE = "work";
    WORKSPACE = "$HOME/Work";
  };

  # Starship prompt (work theme)
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };
}
EOF

# 2. Create home/_profiles/work/packages.nix
# Migrate from work.nix lines 10-35
cat > home/_profiles/work/packages.nix << 'EOF'
# home/_profiles/work/packages.nix
#
# Work-specific packages for corporate development

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud & Infrastructure
    awscli2         # AWS CLI
    ssm-session-manager-plugin
    terraform
    kubectl

    # Database Tools
    sqlcmd          # MSSQL client

    # Enterprise Development
    # (migrated from work.nix)
  ];
}
EOF

# 3. Create home/_profiles/work/aws.nix
# This is critical - preserves AWS multi-role system
cat > home/_profiles/work/aws.nix << 'EOF'
# home/_profiles/work/aws.nix
#
# AWS configuration for work profile
# Integrates with lib/aws-helpers.nix for multi-role functionality

{ config, pkgs, lib, myLib, ... }:

{
  # AWS CLI configuration (from programs/aws.nix)
  programs.zsh.initExtra = lib.mkAfter ''
    # AWS Helper Functions (from work.nix lines 200-445)
    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}

    # Auto-restore last AWS profile
    if [ -f ~/.aws/.last_profile ]; then
      export AWS_PROFILE=$(cat ~/.aws/.last_profile)
      echo "🔐 Restored AWS profile: $AWS_PROFILE"
    fi

    # AWS SSO login helper
    function awslogin() {
      local profile="''${1:-$AWS_PROFILE}"
      if [ -z "$profile" ]; then
        echo "❌ No AWS profile specified or set"
        echo "Usage: awslogin [profile-name]"
        return 1
      fi

      echo "🔐 Logging into AWS SSO with profile: $profile"
      aws sso login --profile "$profile"

      if [ $? -eq 0 ]; then
        export AWS_PROFILE="$profile"
        echo "$profile" > ~/.aws/.last_profile
        echo "✅ Successfully logged in to: $profile"
      else
        echo "❌ Login failed for profile: $profile"
      fi
    }

    # AWS profile usage helper
    function awsuse() {
      ${myLib.aws.getAccountHelperImpl}
    }

    # AWS whoami helper
    function awswho() {
      if [ -z "$AWS_PROFILE" ]; then
        echo "❌ No AWS profile set"
        return 1
      fi

      echo "Current AWS Profile: $AWS_PROFILE"
      aws sts get-caller-identity 2>/dev/null || echo "❌ Not logged in or credentials expired"
    }
  '';
}
EOF

# 4. Create home/_profiles/work/database.nix
# Preserves database connectivity system
cat > home/_profiles/work/database.nix << 'EOF'
# home/_profiles/work/database.nix
#
# Database instance connectors for work profile
# Integrates with lib/database-helpers.nix

{ config, pkgs, lib, myLib, ... }:

{
  programs.zsh.initExtra = lib.mkAfter ''
    # Database Instance Connectors (from work.nix)
    ${myLib.database.mkDatabaseInstances [
      {
        instance = "ti";
        type = "oracle";
        environments = ["dev" "qa" "prod"];
        description = "TRIRIGA database";
      }
      {
        instance = "hrdb";
        type = "mssql";
        environments = ["prod"];
        description = "HR database";
      }
      {
        instance = "payroll";
        type = "mssql";
        environments = ["prod"];
        description = "Payroll database";
      }
      {
        instance = "facilities";
        type = "postgres";
        environments = ["dev" "prod"];
        description = "Facilities management database";
      }
      {
        instance = "assets";
        type = "mysql";
        environments = ["dev" "prod"];
        description = "Asset tracking database";
      }
      {
        instance = "reporting";
        type = "postgres";
        environments = ["prod"];
        description = "Reporting database";
      }
    ]}
  '';
}
EOF

# 5. Create home/_profiles/work/aliases.nix
# Work-specific aliases only
cat > home/_profiles/work/aliases.nix << 'EOF'
# home/_profiles/work/aliases.nix
#
# Work-specific aliases and navigation shortcuts

{ config, lib, myLib, ... }:

{
  programs.zsh.shellAliases = {
    # Work project navigation (from work.nix)
    work = "cd ~/Work";
    repos = "cd ~/Work/repositories";
    infra = "cd ~/Work/infrastructure";
    docs = "cd ~/Work/documentation";

    # AWS shortcuts
    aws-login = "awslogin";
    aws-who = "awswho";

    # Database shortcuts
    db-ti-prod = "dbconnect-ti prod";
    db-hrdb = "dbconnect-hrdb prod";
  };
}
EOF

# 6. Create work starship (AWS-prominent)
cat > home/_profiles/work/starship.toml << 'EOF'
# Work profile starship configuration
# Emphasizes AWS profile and account info

format = """
[](#9A348E)\
$os\
$username\
[](bg:#DA627D fg:#9A348E)\
$directory\
[](fg:#DA627D bg:#FCA17D)\
$git_branch\
$git_status\
[](fg:#FCA17D bg:#86BBD8)\
$aws\
[](fg:#86BBD8 bg:#06969A)\
$kubernetes\
$terraform\
[](fg:#06969A bg:#33658A)\
$python\
$nodejs\
[ ](fg:#33658A)\
$character
"""

# AWS segment (more prominent for work)
[aws]
symbol = "  "
style = "bg:#86BBD8 fg:#000000"
format = '[[$symbol($profile )(\($region\)) ](bg:#86BBD8 fg:#000000)]($style)'
disabled = false

# Rest of starship config...
EOF

# 7. Validate syntax
nix-instantiate --eval --expr '(import ./home/_profiles/work/default.nix { inherit (import <nixpkgs> {}) pkgs lib; myLib = {}; hostname = "test"; config = {}; }).imports'
```

**Acceptance Criteria**:
- [ ] work/default.nix created with all imports
- [ ] work/packages.nix has all work packages
- [ ] work/aws.nix preserves AWS multi-role system
- [ ] work/database.nix preserves all 6 database instances
- [ ] work/aliases.nix has work navigation
- [ ] work/starship.toml emphasizes AWS
- [ ] All functions from work.nix preserved
- [ ] Nix syntax validates

**Critical Validation**:
```bash
# Verify AWS functions present
rg "awsuse|awslogin|awswho" home/_profiles/work/aws.nix | wc -l  # Should be 3+

# Verify database instances
rg "mkDatabaseInstances" home/_profiles/work/database.nix -A 20 | \
  rg "instance =" | wc -l  # Should be 6

# Verify work aliases
rg "work|repos|infra|db-" home/_profiles/work/aliases.nix | wc -l  # Should be 7+
```

---

### Task 2.4: Create Minimal Profile Template
**Effort**: 1 hour
**Priority**: Medium
**Risk**: Low

**Purpose**: Bare-minimum profile for troubleshooting or lightweight environments

**Action**:
```bash
# 1. Create home/_profiles/minimal/default.nix
cat > home/_profiles/minimal/default.nix << 'EOF'
# home/_profiles/minimal/default.nix
#
# Minimal profile for troubleshooting and lightweight environments

{ config, pkgs, lib, ... }:

{
  imports = [
    ./packages.nix
    ./aliases.nix
  ];

  # Minimal session variables
  home.sessionVariables = {
    MACHINE_MODE = "minimal";
  };

  # No starship - use basic prompt
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
}
EOF

# 2. Create home/_profiles/minimal/packages.nix
cat > home/_profiles/minimal/packages.nix << 'EOF'
# home/_profiles/minimal/packages.nix
#
# Bare minimum packages for basic functionality

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Essential CLI tools only
    coreutils
    git
    vim
    curl
    wget
  ];
}
EOF

# 3. Create home/_profiles/minimal/aliases.nix
cat > home/_profiles/minimal/aliases.nix << 'EOF'
# home/_profiles/minimal/aliases.nix
#
# Essential aliases only

{ ... }:

{
  programs.zsh.shellAliases = {
    # Basic navigation
    ".." = "cd ..";
    "..." = "cd ../..";

    # Essential git
    g = "git";
    gs = "git status";

    # Rebuild
    rebuild = "darwin-rebuild switch --flake .";
  };
}
EOF

# 4. Validate
nix-instantiate --eval --expr '(import ./home/_profiles/minimal/default.nix { inherit (import <nixpkgs> {}) pkgs lib; config = {}; }).imports'
```

**Acceptance Criteria**:
- [ ] minimal/default.nix created
- [ ] minimal/packages.nix has only essentials
- [ ] minimal/aliases.nix has basic shortcuts
- [ ] No complex integrations (AWS, database, etc.)
- [ ] Suitable for troubleshooting

---

### Task 2.5: Move Shared Base to _template
**Effort**: 1.5 hours
**Priority**: High
**Risk**: Medium

**Problem**: Current `home/_template/` contains shared base configs. Should be accessible to all profiles.

**Action**:
```bash
# 1. Move to profiles/_template
cp -r home/_template home/_profiles/_template

# 2. Update imports in profile default.nix files
# (Already done in Tasks 2.2, 2.3, 2.4 above)

# 3. Keep original home/_template for backward compatibility during transition

# 4. Update git.nix, vscode.nix, etc. if needed for profile awareness

# 5. Validate all profiles can import from _template
nix-instantiate --eval --expr '
  let
    pkgs = import <nixpkgs> {};
    lib = pkgs.lib;
    myLib = {};
    hostname = "test";
    config = {};
    checkProfile = profile:
      (import ./home/_profiles/${profile}/default.nix {
        inherit pkgs lib myLib hostname config;
      }).imports;
  in {
    personal = checkProfile "personal";
    work = checkProfile "work";
    minimal = checkProfile "minimal";
  }
'
```

**Acceptance Criteria**:
- [ ] home/_profiles/_template/ created
- [ ] Programs copied to _template/programs/
- [ ] Shell configs copied to _template/shell/
- [ ] All profiles import from _template successfully
- [ ] Original home/_template preserved (for backward compat)

---

## Phase 2 Completion Criteria

**All tasks complete when**:
- [ ] Profile directory structure exists (Task 2.1)
- [ ] Personal profile created and validated (Task 2.2)
- [ ] Work profile created with AWS/DB (Task 2.3)
- [ ] Minimal profile created (Task 2.4)
- [ ] Shared base in _template accessible (Task 2.5)
- [ ] All profiles validate: `nix-instantiate --eval` passes
- [ ] No functionality lost from mixins

**Expected State After Phase 2**:
- Complete profile structure exists
- All existing functionality migrated to profiles
- Profiles are isolated and independent
- Ready for flake.nix integration (Phase 3)

**Rollback Plan**:
```bash
# If issues arise, profiles are not yet active
# System still uses home/_mixins/ (unchanged)
# Simply fix profile issues without affecting active system
```

---

## Testing Checklist

After completing Phase 2:

```bash
# 1. Validate all profile syntax
nix-instantiate --eval home/_profiles/personal/default.nix
nix-instantiate --eval home/_profiles/work/default.nix
nix-instantiate --eval home/_profiles/minimal/default.nix

# 2. Check migrations complete
# Personal aliases
rg "learning|aiml|algo|ollama" home/_profiles/personal/aliases.nix

# Work AWS functions
rg "awsuse|awslogin|awswho" home/_profiles/work/aws.nix

# Work database instances
rg "mkDatabaseInstances" home/_profiles/work/database.nix -A 20

# 3. Verify structure
tree home/_profiles/ -L 2

# 4. System still works (using old mixins)
nix-rebuild  # Should still succeed with old system
exec zsh
health-check
```

---

**Next Phase**: [Phase 3: Flake Integration](PHASE-3-INTEGRATION.md)
