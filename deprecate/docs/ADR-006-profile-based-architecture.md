# ADR-006: Profile-Based Architecture (v2.0.0)

**Status**: Accepted
**Date**: 2024-11-10
**Author**: System Architecture
**Version**: v2.0.0

---

## Context

nix-darwin v1.x used hostname-based machine detection (ADR-001) with mixins for personal/work behavior. While functional, this approach had limitations:

**Problems with v1.x**:
- **Tight coupling**: Hostname changes broke configuration
- **No portability**: Configuration tied to specific machine names
- **Poor testing**: Couldn't test "work mode" on personal machine
- **Manual flake edits**: Each new machine required flake.nix changes
- **User identity mixed**: Username, email hardcoded in multiple files

**Requirements for v2.0.0**:
1. **Portability**: Configuration works on any machine after setup
2. **User/Machine Separation**: User identity separate from machine identity
3. **Profile Flexibility**: Easy switching between personal/work/minimal profiles
4. **Gitignored Configs**: Machine-specific settings not in repository
5. **Backward Compatibility**: Migration path from v1.x
6. **Testing Support**: Ability to test different profiles easily

---

## Decision

Implement a **profile-based architecture** with gitignored configuration files for user and machine identity.

### Core Components

#### 1. User Configuration (Gitignored)

**File**: `config/user-config.nix`

```nix
{
  username = "jimmy";
  fullName = "Jimmy User";
  email = "jimmy@example.com";
}
```

**Purpose**:
- User identity separate from machine
- Portable across all machines
- Single source for user-specific values

#### 2. Machine Configuration (Gitignored)

**File**: `config/machine-config.nix`

```nix
{
  machineId = "mbp-personal-001";
  profileName = "personal";  # personal, work, or minimal
  description = "Personal MacBook Pro M1";
}
```

**Purpose**:
- Machine identity independent of hostname
- Profile selection per machine
- Machine-specific metadata

#### 3. Profile System

**Profiles**: `home/_profiles/{personal,work,minimal}/`

Each profile defines complete behavior:
- Shell aliases
- Git configuration
- Development tools
- AWS configuration (work only)
- Database tools (work only)

**Profile Selection**:
```nix
# flake.nix reads config/machine-config.nix
let
  machineConfig = import ./config/machine-config.nix;
  profileName = machineConfig.profileName;
in
  # Load appropriate profile
  ./home/_profiles/${profileName}/
```

#### 4. Template System

**Location**: `home/_profiles/_template/`

Shared programs and shell configs used by all profiles:
- Git (profile customizes email)
- VS Code (profile customizes extensions)
- Shell (profile adds aliases)

**Inheritance**:
```
_template/             # Base configurations
├── programs/
│   ├── git.nix       # Base git config
│   └── vscode.nix    # Base VS Code
└── shell/
    └── zsh.nix       # Base shell config

personal/             # Extends template
├── default.nix       # Imports template + personal additions
└── aliases.nix       # Personal-specific aliases

work/                 # Extends template
├── default.nix       # Imports template + work additions
├── aliases.nix       # Work-specific aliases
└── aws.nix          # Work-only AWS config
```

### Configuration Flow

```
1. User runs: ./scripts/configure.sh
   ↓
2. Script generates:
   - config/user-config.nix (from prompts)
   - config/machine-config.nix (from prompts)
   ↓
3. User runs: ./scripts/activate.sh
   ↓
4. flake.nix reads:
   - config/user-config.nix → User identity
   - config/machine-config.nix → Profile selection
   ↓
5. System loads:
   - home/_profiles/${profileName}/
   - Appropriate mixins and modules
   ↓
6. Result: Fully configured system for selected profile
```

### Environment Variables

Each profile exports identifying variables:

```bash
# Personal profile
export ACTIVE_PROFILE=personal
export MACHINE_MODE=home

# Work profile
export ACTIVE_PROFILE=work
export MACHINE_MODE=work

# Minimal profile
export ACTIVE_PROFILE=minimal
export MACHINE_MODE=minimal
```

**Usage**:
```bash
echo $ACTIVE_PROFILE  # Check current profile
if [ "$MACHINE_MODE" = "work" ]; then
  # Work-specific logic
fi
```

---

## Consequences

### Positive

✅ **Portability**: Configuration works on any machine (just run configure.sh)
✅ **Clean Separation**: User identity vs machine identity vs profile behavior
✅ **Easy Testing**: Switch profiles with `scripts/profiles/switch-profile.sh`
✅ **Git-Friendly**: No machine-specific values in repository
✅ **Simpler Flake**: No hostname conditionals in flake.nix
✅ **Better UX**: Guided setup with configure.sh
✅ **Flexible**: Add new profiles without flake changes
✅ **Documented**: ACTIVE_PROFILE makes debugging obvious

### Negative

⚠️ **Requires --impure**: Nix needs --impure flag to read gitignored files
⚠️ **Setup Step**: Must run configure.sh before first build
⚠️ **FLAKE_ROOT Required**: Must set FLAKE_ROOT for config file location
⚠️ **Breaking Change**: v1.x configs need migration

### Migration Path from v1.x

**Migration Steps**:
```bash
# 1. Pull v2.0.0 changes
git pull origin main

# 2. Run configuration wizard
./scripts/configure.sh
# - Enter username, email, fullName
# - Select profile (personal/work/minimal)
# - Machine ID generated automatically

# 3. Activate new configuration
./scripts/activate.sh

# 4. Verify
echo $ACTIVE_PROFILE
nix-rebuild && exec zsh
```

**Backward Compatibility**:
- Hostname-based detection still works (fallback)
- Old mixins preserved for reference
- ADR-001 remains valid for understanding history

---

## Implementation Details

### Directory Structure

```
nix-darwin/
├── config/                          # NEW: Gitignored configs
│   ├── user-config.nix             # User identity
│   ├── machine-config.nix          # Machine + profile selection
│   ├── user-config.nix.template    # Template (committed)
│   └── machine-config.nix.template # Template (committed)
├── home/
│   ├── _profiles/                   # NEW: Profile system
│   │   ├── _template/              # Shared base configs
│   │   │   ├── programs/
│   │   │   └── shell/
│   │   ├── personal/               # Personal profile
│   │   │   ├── default.nix
│   │   │   └── aliases.nix
│   │   ├── work/                   # Work profile
│   │   │   ├── default.nix
│   │   │   ├── aliases.nix
│   │   │   ├── aws.nix
│   │   │   └── database.nix
│   │   └── minimal/                # Minimal profile
│   │       └── default.nix
│   └── jimmy/                      # User-specific (profile-agnostic)
│       ├── programs/
│       ├── shell/
│       └── development/
├── scripts/
│   ├── configure.sh                # NEW: Setup wizard
│   ├── activate.sh                 # NEW: Build & deploy
│   └── switch-profile.sh           # NEW: Profile switcher
└── flake.nix                       # Reads config files dynamically
```

### flake.nix Implementation

```nix
{
  description = "nix-darwin configuration";

  inputs = { /* ... */ };

  outputs = { self, darwin, home-manager, ... }:
  let
    # Read gitignored config files
    userConfig = import ./config/user-config.nix;
    machineConfig = import ./config/machine-config.nix;

    # Common config function
    mkDarwinConfiguration = { system, hostname }:
      darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit userConfig machineConfig;
          profileName = machineConfig.profileName;
        };
        modules = [
          # Load profile-specific config
          ./home/_profiles/${machineConfig.profileName}
          home-manager.darwinModules.home-manager
          {
            users.users.${userConfig.username}.home = "/Users/${userConfig.username}";
            home-manager.users.${userConfig.username} = { /* ... */ };
          }
        ];
      };
  in
  {
    darwinConfigurations = {
      # Single generic configuration
      default = mkDarwinConfiguration {
        system = "aarch64-darwin";
        hostname = builtins.getEnv "HOSTNAME";
      };
    };
  };
}
```

### Profile Configuration Example

**personal/default.nix**:
```nix
{ config, pkgs, userConfig, myLib, ... }:
{
  imports = [
    ../_template/programs
    ../_template/shell
    ./aliases.nix
  ];

  # Personal profile settings
  home.sessionVariables = {
    ACTIVE_PROFILE = "personal";
    MACHINE_MODE = "home";
  };

  programs.git = {
    userEmail = userConfig.email;  # From config/user-config.nix
    userName = userConfig.fullName;
  };

  # Personal-specific packages
  home.packages = with pkgs; [
    # Gaming, personal tools, etc.
  ];
}
```

**work/default.nix**:
```nix
{ config, pkgs, userConfig, myLib, ... }:
{
  imports = [
    ../_template/programs
    ../_template/shell
    ./aliases.nix
    ./aws.nix          # Work-specific AWS config
    ./database.nix     # Work-specific database tools
  ];

  # Work profile settings
  home.sessionVariables = {
    ACTIVE_PROFILE = "work";
    MACHINE_MODE = "work";
  };

  programs.git = {
    userEmail = "jimmy.work@company.com";  # Work email
    userName = userConfig.fullName;
  };

  # Work-specific packages
  home.packages = with pkgs; [
    aws-cli
    postgresql
    mongodb
    # etc.
  ];
}
```

### Configure Script Implementation

**scripts/configure.sh**:
```bash
#!/usr/bin/env bash
# Interactive setup wizard

# 1. Prompt for user info
read -p "Username: " username
read -p "Full Name: " fullName
read -p "Email: " email

# 2. Generate user-config.nix
cat > config/user-config.nix <<EOF
{
  username = "${username}";
  fullName = "${fullName}";
  email = "${email}";
}
EOF

# 3. Prompt for profile
echo "Select profile:"
echo "1) personal - Personal machine"
echo "2) work - Work machine"
echo "3) minimal - Bare-bones (troubleshooting)"
read -p "Choice [1-3]: " choice

case $choice in
  1) profileName="personal" ;;
  2) profileName="work" ;;
  3) profileName="minimal" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

# 4. Generate machine ID
machineId="${profileName}-$(hostname)-$(date +%s)"

# 5. Generate machine-config.nix
cat > config/machine-config.nix <<EOF
{
  machineId = "${machineId}";
  profileName = "${profileName}";
  description = "$(hostname) - ${profileName} profile";
}
EOF

echo "✅ Configuration complete!"
echo "Run: ./scripts/activate.sh"
```

### Activate Script

**scripts/activate.sh**:
```bash
#!/usr/bin/env bash
# Build and activate system

# 1. Set FLAKE_ROOT
export FLAKE_ROOT="$PWD"

# 2. Build with --impure flag
darwin-rebuild switch --flake . --impure

# 3. Restart shell
exec zsh
```

### Profile Switcher

**scripts/profiles/switch-profile.sh**:
```bash
#!/usr/bin/env bash
# Switch between profiles

profileName=$1

if [ -z "$profileName" ]; then
  echo "Usage: $0 {personal|work|minimal}"
  exit 1
fi

# 1. Update machine-config.nix
sed -i '' "s/profileName = \".*\"/profileName = \"${profileName}\"/" config/machine-config.nix

# 2. Rebuild
echo "Switching to ${profileName} profile..."
./scripts/activate.sh
```

---

## Usage Examples

### Initial Setup (New Machine)

```bash
# 1. Clone repository
git clone <repo> ~/nix-darwin
cd ~/nix-darwin

# 2. Install dependencies
./scripts/bootstrap.sh

# 3. Configure (interactive)
./scripts/configure.sh
# Enter: username, email, fullName
# Select: personal/work/minimal

# 4. Activate
./scripts/activate.sh

# 5. Verify
echo $ACTIVE_PROFILE  # Should show selected profile
```

### Switch Profiles

```bash
# Switch to work profile
./scripts/profiles/switch-profile.sh work

# Switch to personal profile
./scripts/profiles/switch-profile.sh personal

# Switch to minimal (troubleshooting)
./scripts/profiles/switch-profile.sh minimal
```

### Check Current Profile

```bash
echo $ACTIVE_PROFILE     # personal, work, or minimal
echo $MACHINE_MODE       # home, work, or minimal

# In Nix expression
if config.profileName == "work" then /* ... */ else /* ... */
```

### Test Profile Without Rebuilding

```bash
# Temporarily test different profile behavior
ACTIVE_PROFILE=work zsh
# Work aliases and environment active
exit

# Back to actual profile
echo $ACTIVE_PROFILE  # personal (unchanged)
```

---

## Alternatives Considered

### Alternative 1: Continue Hostname-Based Detection

Keep ADR-001 approach, improve with better helpers.

**Rejected because**:
- ❌ Still tied to hostname
- ❌ No portability
- ❌ Can't test profiles easily
- ❌ User identity mixed with machine identity

### Alternative 2: Environment Variables Only

Use `export PROFILE=work` instead of config files.

**Rejected because**:
- ❌ Not persistent across rebuilds
- ❌ Easy to accidentally unset
- ❌ Rollback issues
- ❌ No separation of user vs machine config

### Alternative 3: Multiple Flake Outputs

Separate flake outputs per profile (like v1.x).

**Rejected because**:
- ❌ Requires hostname knowledge
- ❌ Manual flake.nix edits
- ❌ No dynamic profile switching
- ❌ Doesn't solve portability

### Alternative 4: Single Config File

Combine user + machine config in one file.

**Rejected because**:
- ❌ Mixing concerns (user vs machine)
- ❌ Harder to template
- ❌ Less clear separation
- ✅ **Future consideration** for simplification

---

## Security Considerations

### Gitignored Configs

**Protected**: `config/user-config.nix`, `config/machine-config.nix`

**.gitignore**:
```
# User and machine configs (gitignored)
config/user-config.nix
config/machine-config.nix

# Templates (committed for reference)
!config/*.template
```

### Email Privacy

User email in gitignored config prevents accidental commit of personal email addresses.

### Profile-Specific Secrets

Profiles can define different secret scopes:
- Personal: Personal API keys, personal AWS
- Work: Work credentials, work databases
- Minimal: No secrets (troubleshooting)

---

## Documentation Updates

**New Documentation**:
- [Installation Guide](../../installation.md) - Updated for configure.sh workflow
- [Troubleshooting Guide](../../troubleshooting.md) - Profile-specific issues
- [CLAUDE.md](../../CLAUDE.md) - Profile system instructions

**Updated Guides**:
- Profile switching procedures
- Configuration file generation
- FLAKE_ROOT requirements
- Migration from v1.x

---

## References

- [ADR-001: Machine Detection Strategy](ADR-001-machine-detection-strategy.md) - v1.x approach
- [ADR-004: User vs Machine Config Separation](ADR-004-user-vs-machine-config-separation.md) - Foundation
- [Installation Guide](../../installation.md)
- [Troubleshooting Guide](../../troubleshooting.md)
- [CLAUDE.md](../../CLAUDE.md)

---

## Revision History

- **2024-11-10**: Initial ADR - Profile-based architecture for v2.0.0
