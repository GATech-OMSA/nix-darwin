# AWS Helper System - Enhanced Multi-Role Support

## Overview

The enhanced AWS helper system now supports **multiple IAM roles per environment**, allowing you to have different permission levels for different tasks.

---

## Key Features

✅ **Multiple profiles per environment** - e.g., `ti-dev` (read-only) and `ti-dev-developer` (write access)
✅ **Dynamic alias generation** - Creates shortcuts like `tidev`, `tidev-developer`
✅ **Flexible schema** - String or object values, backward compatible
✅ **Role-based access** - Support (read-only), developer, admin, custom roles
✅ **Enhanced discovery** - `awslist` groups by project, `awswhere` does reverse lookup
✅ **Session management** - `awscheck` shows status of all profiles
✅ **Writable config** - `~/.aws/config` is editable for temporary testing (regenerated on rebuild)

---

## Schema Reference

### Basic Format (String - Support Role Only)

```json
{
  "project-name": {
    "alias": "proj",
    "accounts": {
      "prod": "123456789012"
    }
  }
}
```

**Generates**:
- Profile: `project-name-prod` (support role)
- Alias: `projprod` → `awsuse project-name prod`

---

### Enhanced Format (Object - Multiple Roles)

```json
{
  "tririga-integrations": {
    "alias": "ti",
    "description": "TRIRIGA integrations platform",
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
      },
      "qa": "710271912324",
      "prod": "911167889615"
    }
  }
}
```

**Generates**:

**Profiles:**
- `ti-dev` (support role, read-only)
- `ti-dev-developer` (developer role, write access)
- `ti-sbx` (support role)
- `ti-sbx-developer` (developer role)
- `ti-sbx-admin` (admin role)
- `ti-qa` (support only)
- `ti-prod` (support only)

**Aliases:**
- `tidev` → `awsuse ti dev` (support)
- `tidev-developer` → `awsuse ti dev developer`
- `tisbx` → `awsuse ti sbx`
- `tisbx-developer` → `awsuse ti sbx developer`
- `tisbx-admin` → `awsuse ti sbx admin`
- `tiqa` → `awsuse ti qa`
- `tiprod` → `awsuse ti prod`

---

## Schema Fields

### Project Level

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `alias` | string | ✅ Yes | Short name for aliases (e.g., "ti" for tririga-integrations) |
| `description` | string | ❌ No | Human-readable description |
| `default_role` | string | ❌ No | Default IAM role (default: "support") |
| `default_region` | string | ❌ No | Default AWS region (default: "us-east-1") |
| `accounts` | object | ✅ Yes | Environment definitions |

### Account Level (Per Environment)

**String Format** (simple):
```json
"prod": "123456789012"
```

**Object Format** (advanced):
```json
"dev": {
  "id": "123456789012",
  "additional_roles": ["developer", "admin"],
  "region": "us-west-2"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | ✅ Yes | AWS account ID |
| `additional_roles` | array | ❌ No | Extra IAM roles to create profiles for |
| `region` | string | ❌ No | AWS region override |

---

## Usage Examples

### Switch to Default Profile (Support Role)

```bash
awsuse ti dev
# ✅ Switched to: ti-dev
#    Account: 779846812095
#    Role: support
```

Or use alias:
```bash
tidev
```

### Switch to Developer Role

```bash
awsuse ti dev developer
# ✅ Switched to: ti-dev-developer
#    Account: 779846812095
#    Role: developer
```

Or use alias:
```bash
tidev-developer
```

### Login to Profile

```bash
awslogin ti dev developer
# 🔐 Logging into: ti-dev-developer
# (Opens browser for SSO)
# ✅ Logged in and switched to: ti-dev-developer
```

### List All Accounts

```bash
awslist
# 📋 AWS Accounts (from accounts.json):
#
# tririga-integrations (ti) - TRIRIGA integrations platform
#   • dev    (779846812095) → developer
#   • sbx    (054037098480) → developer, admin
#   • qa     (710271912324)
#   • prod   (911167889615)
#
# paging-solution (ps)
#   • dev    (908396102221) → developer
#   • sbx    (839573011705)
#   ...
#
# Current: ti-dev ✅
#
# 💡 Usage: awsuse <alias> <env> [role]
```

### Reverse Lookup by Account ID

```bash
awswhere 779846812095
# 🔍 Searching for account: 779846812095
#
# 📍 Project: tririga-integrations (ti)
#    Environment: dev
#    Profiles:
#      • tririga-integrations-dev (support role)
#      • tririga-integrations-dev-developer (developer role)
#
# 💡 Switch: awsuse <alias> <env> [role]
```

### Check Session Status

```bash
awscheck
# 🔍 Checking SSO session status...
#
# ti-dev:                        ✅ Active
# ti-dev-developer:              ✅ Active
# ti-sbx:                        ❌ Expired/Not logged in
# ti-sbx-developer:              ❌ Expired/Not logged in
# ps-dev:                        ✅ Active
# ...
#
# 💡 Login: awslogin <project> <env> [role]
```

### Show Current Profile

```bash
awswho
# 📋 Current AWS Profile: ti-dev-developer
#
# Profile configuration:
#   sso_session = sso-east-1
#   sso_account_id = 779846812095
#   sso_role_name = developer
#   region = us-east-1
#
# Session info:
# {
#   "UserId": "AROAXXXXX:user@example.com",
#   "Account": "779846812095",
#   "Arn": "arn:aws:sts::779846812095:assumed-role/developer/..."
# }
```

---

## Migration Guide

### From Current Setup

Your current `accounts.json`:
```json
{
  "tririga-integrations": {
    "alias": "ti",
    "accounts": {
      "dev": "779846812095",
      "sbx": "054037098480"
    }
  }
}
```

**No changes needed!** This still works. Generates:
- `ti-dev` (support role)
- `ti-sbx` (support role)
- Aliases: `tidev`, `tisbx`

### To Add Developer Role

Update to:
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

**After rebuild**, you'll have:
- `ti-dev` (support, read-only) - existing alias still works
- `ti-dev-developer` (developer, write access) - new profile
- `ti-sbx` (support) - unchanged

---

## Best Practices

### 1. **Support Role for Production**

Always use support (read-only) for production:
```json
{
  "accounts": {
    "prod": "123456789012"  // String = support only
  }
}
```

### 2. **Developer Roles for Non-Prod**

Add developer roles where you need write access:
```json
{
  "accounts": {
    "dev": {
      "id": "123456789012",
      "additional_roles": ["developer"]
    },
    "sbx": {
      "id": "234567890123",
      "additional_roles": ["developer", "admin"]
    }
  }
}
```

### 3. **Use Descriptive Aliases**

Keep aliases short but meaningful:
- ✅ `ti`, `ps`, `sc` (good)
- ❌ `a`, `b`, `c` (too generic)
- ❌ `tririga-integrations` (defeats purpose of alias)

### 4. **Regional Overrides**

Override region when needed:
```json
{
  "dev": {
    "id": "123456789012",
    "region": "us-west-2"
  }
}
```

### 5. **Default to Support**

When in doubt, use support role:
```bash
tidev         # Support role (safe)
awswho        # Verify role before making changes
```

### 6. **Explicit Role for Destructive Operations**

Always specify role for deployments:
```bash
tidev-developer   # Explicit developer role
terraform apply   # Now it's clear you have write access
```

---

## Troubleshooting

### Profile Not Found

```bash
awsuse ti dev developer
# ❌ Profile not configured: ti-dev-developer
# 💡 Run: awslogin ti dev developer
```

**Solution**: Login first or rebuild to generate profile.

### Alias Not Working

Check if additional_roles is set:
```bash
awslist
# Shows which profiles have additional roles
```

Rebuild after updating accounts.json:
```bash
darwin-rebuild switch --flake .#mbp-work
```

### Wrong Role

Check current role:
```bash
awswho
# Shows current profile and role
```

Switch explicitly:
```bash
awsuse ti dev developer
```

---

## Functions Reference

| Function | Purpose | Example |
|----------|---------|---------|
| `awsuse <proj> <env> [role]` | Switch profile | `awsuse ti dev developer` |
| `awslogin <proj> <env> [role]` | SSO login + switch | `awslogin ti dev` |
| `awswho` | Show current profile | `awswho` |
| `awslist` | List all accounts | `awslist` |
| `awswhere <account-id>` | Reverse lookup | `awswhere 779846812095` |
| `awscheck` | Check session status | `awscheck` |

---

## See Also

- [Infrastructure Reference](../../../docs/reference/infrastructure.md) - Full AWS documentation
- [Quick Reference](../../../docs/QUICK-REFERENCE.md) - Command cheat sheet
- [AWS Quick Ref](./AWS-QUICK-REF.md) - Quick command reference
- `.aws/accounts.json.example` - Example configuration
