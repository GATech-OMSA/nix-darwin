# AWS Multi-Role Implementation - Summary

## Changes Implemented ✅

### 1. **Enhanced `lib/aws-helpers.nix`**

#### **New Features:**

**`mkAwsAccountHelper`** - Updated functions:
- ✅ `awsuse` now accepts optional `[role]` parameter
- ✅ Supports both string and object account values
- ✅ Automatically reads `default_role` from project config
- ✅ Constructs profile names: `project-env` (support) or `project-env-role`
- ✅ Better error messages with role information

**`mkAwsAliasesFromJson`** - Enhanced alias generation:
- ✅ Creates default alias (support role): `tidev`
- ✅ Creates role-specific aliases: `tidev-developer`, `tisbx-admin`
- ✅ Reads `additional_roles` from account objects
- ✅ Handles mixed string/object account values

**New Info Commands:**
- ✅ **`awslist`** - Groups profiles by project, shows roles
- ✅ **`awswhere`** - Reverse lookup by account ID
- ✅ **`awscheck`** - Check SSO session status for all profiles
- ✅ **`awswho`** - Enhanced to show role information

#### **Deprecated (but kept for compatibility):**
- `mkAwsProfileAliases` - Generic `awsdev` aliases (ambiguous in multi-project setups)
- `mkAwsProjectAliases` - Generic project aliases
- `mkAwsProfileAliasesWithPrefix` - Superseded by JSON approach
- `mkAwsUniversalCommand` - Legacy manual configuration

---

### 2. **Enhanced `home/_profiles/_template/programs/aws.nix`**

#### **Updated `generateSsoProfiles` Function:**
- ✅ Parses both string and object account values
- ✅ Reads `default_role` from project (defaults to "support")
- ✅ Reads `default_region` from project (defaults to "us-east-1")
- ✅ Creates multiple profiles when `additional_roles` specified
- ✅ Handles region overrides per environment
- ✅ Support role uses `project-env` format (backward compatible)
- ✅ Other roles use `project-env-role` format

**Example Generated Profiles:**

From this JSON:
```json
{
  "dev": {
    "id": "123456789012",
    "additional_roles": ["developer"]
  }
}
```

Generates these profiles:
```
[profile ti-dev]
sso_role_name = support

[profile ti-dev-developer]
sso_role_name = developer
```

---

### 3. **Documentation Created**

#### **`claudeclaudedocs/AWS-MULTI-ROLE.md`**
Comprehensive guide covering:
- Schema reference (string vs object formats)
- Usage examples
- Migration guide from current setup
- Best practices
- Troubleshooting
- Functions reference

#### **`.aws/accounts.json.example`**
Example configuration showing:
- String format (support only)
- Object format with additional roles
- Multiple projects
- Region overrides

---

## Schema Reference

### Simple Format (String - Support Only)

```json
{
  "project": {
    "alias": "proj",
    "accounts": {
      "prod": "123456789012"
    }
  }
}
```

**Generates:**
- Profile: `project-prod` (support)
- Alias: `projprod`

---

### Enhanced Format (Object - Multiple Roles)

```json
{
  "tririga-integrations": {
    "alias": "ti",
    "default_role": "support",
    "default_region": "us-east-1",
    "accounts": {
      "dev": {
        "id": "779846812095",
        "additional_roles": ["developer"],
        "region": "us-east-1"
      },
      "sbx": {
        "id": "054037098480",
        "additional_roles": ["developer", "admin"]
      }
    }
  }
}
```

**Generates:**
- Profiles: `ti-dev`, `ti-dev-developer`, `ti-sbx`, `ti-sbx-developer`, `ti-sbx-admin`
- Aliases: `tidev`, `tidev-developer`, `tisbx`, `tisbx-developer`, `tisbx-admin`

---

## Usage Examples

### Basic Usage

```bash
# Use default (support) role
tidev
# or
awsuse ti dev

# Use developer role
tidev-developer
# or
awsuse ti dev developer

# Login with specific role
awslogin ti dev developer
```

### Discovery & Management

```bash
# List all accounts and roles
awslist

# Find account by ID
awswhere 779846812095

# Check session status
awscheck

# Show current profile
awswho
```

---

## Migration Path

### Your Current Setup

No changes needed! Your current `accounts.json` works as-is:

```json
{
  "tririga-integrations": {
    "alias": "ti",
    "accounts": {
      "dev": "779846812095"
    }
  }
}
```

This continues to work identically:
- Profile: `ti-dev` (support)
- Alias: `tidev`

### To Add Developer Role

Update specific environments:

```json
{
  "tririga-integrations": {
    "alias": "ti",
    "accounts": {
      "dev": {
        "id": "779846812095",
        "additional_roles": ["developer"]
      },
      "prod": "911167889615"  // Keep prod as support only
    }
  }
}
```

After rebuild:
- `ti-dev` (support) - works as before
- `ti-dev-developer` (new!) - developer access
- `ti-prod` (support) - unchanged, safest for prod

---

## Testing Plan

### 1. **Test Current Config (No Changes)**

```bash
# Rebuild
darwin-rebuild switch --flake .#mbp-work

# Test existing aliases
tidev
awswho

# Should work identically to before
```

### 2. **Test Enhanced Config (Add Roles)**

Update `~/.aws/accounts.json`:
```json
{
  "tririga-integrations": {
    "alias": "ti",
    "default_role": "support",
    "accounts": {
      "dev": {
        "id": "779846812095",
        "additional_roles": ["developer"]
      },
      "sbx": "054037098480"
    }
  }
}
```

```bash
# Rebuild
darwin-rebuild switch --flake .#mbp-work

# Check generated profiles
cat ~/.aws/config | grep "profile ti-"

# Should see:
# [profile ti-dev]
# [profile ti-dev-developer]
# [profile ti-sbx]

# Test aliases
alias | grep ti
# Should see:
# tidev='awsuse tririga-integrations dev'
# tidev-developer='awsuse tririga-integrations dev developer'
# tisbx='awsuse tririga-integrations sbx'

# Test functions
tidev
awswho
# Shows ti-dev (support role)

tidev-developer
awswho
# Shows ti-dev-developer (developer role)
```

### 3. **Test New Functions**

```bash
# List all accounts
awslist

# Reverse lookup
awswhere 779846812095

# Check sessions
awscheck

# Login with role
awslogin ti dev developer
```

---

## Benefits

### ✅ **Backward Compatible**
- Existing configs work unchanged
- String format still supported
- Existing aliases continue to work

### ✅ **Flexible**
- Mix string and object formats
- Add roles only where needed
- Override region per environment

### ✅ **Safe by Default**
- Support role is always default
- Prod can be kept as support-only
- Explicit role selection for writes

### ✅ **Better UX**
- Project-specific aliases (no `awsdev` confusion)
- Enhanced discovery (`awslist`, `awswhere`)
- Session management (`awscheck`)
- Clear role indication in output

### ✅ **Maintainable**
- Single source of truth (accounts.json)
- No Nix changes for new projects
- Self-documenting configuration

---

## Next Steps

1. **Review changes** in this diff
2. **Rebuild** to test current config unchanged
3. **Optional**: Update `~/.aws/accounts.json` to add developer roles where needed
4. **Rebuild again** to test enhanced config
5. **Test new functions** (`awslist`, `awswhere`, `awscheck`)
6. **Review documentation** in `claudedocs/AWS-MULTI-ROLE.md`

---

## Files Changed

- ✅ `lib/aws-helpers.nix` - Core functions with role support
- ✅ `home/_profiles/_template/programs/aws.nix` - Profile generation
- ✅ `claudedocs/AWS-MULTI-ROLE.md` - New documentation
- ✅ `.aws/accounts.json.example` - Example configuration
- ⏳ `docs/reference/infrastructure.md` - Needs update (remove generic aliases docs)

---

## Questions?

- See `claudedocs/AWS-MULTI-ROLE.md` for comprehensive guide
- Check `.aws/accounts.json.example` for configuration examples
- Test incrementally: first with unchanged config, then with roles added
