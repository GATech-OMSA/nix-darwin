# AWS Accounts Schema Reference

**Complete documentation for `user-data/aws/accounts.json` configuration**

---

## Overview

The `accounts.json` file provides a centralized, declarative way to manage AWS multi-account access with role-based permissions. This schema enables automatic generation of AWS CLI profiles and shell functions for seamless account switching.

**Key Benefits:**
- **Single Source of Truth** - Define all accounts and roles once
- **Automatic Generation** - Shell functions and AWS profiles generated automatically
- **Type Safety** - Schema validation prevents configuration errors
- **Role Standardization** - Consistent role naming across accounts
- **Easy Updates** - Add/modify accounts without touching Nix configuration

---

## Schema Structure

```json
{
  "projects": {
    "project-name": {
      "accounts": {
        "account-name": {
          "id": "123456789012",
          "roles": ["role1", "role2"],
          "aliases": {
            "short-name": "role-name"
          }
        }
      }
    }
  }
}
```

---

## Field Definitions

### Top Level

| Field      | Type   | Required | Description                          |
|------------|--------|----------|--------------------------------------|
| `projects` | object | ✅       | Container for all project definitions |

### Project Level

| Field      | Type   | Required | Description                              |
|------------|--------|----------|------------------------------------------|
| `accounts` | object | ✅       | Container for account definitions        |

**Key:** Project name (string, lowercase-with-hyphens recommended)

### Account Level

| Field     | Type          | Required | Description                                  |
|-----------|---------------|----------|----------------------------------------------|
| `id`      | string        | ✅       | 12-digit AWS account ID                      |
| `roles`   | array[string] | ✅       | List of IAM roles available in this account  |
| `aliases` | object        | ❌       | Short name mappings for roles                |

**Key:** Account name (string, lowercase-with-hyphens recommended)

### Aliases Object

| Field      | Type   | Required | Description                |
|------------|--------|----------|----------------------------|
| `short-name` | string | ❌       | Short alias for quick access |

**Key:** Alias name (string)
**Value:** Role name from `roles` array

---

## Configuration Examples

### Minimal Configuration

Single project, single account, single role:

```json
{
  "projects": {
    "my-project": {
      "accounts": {
        "production": {
          "id": "123456789012",
          "roles": ["ReadOnly"]
        }
      }
    }
  }
}
```

**Generated:**
- Profile: `my-project-production-readonly`
- Function: `aws-my-project-production-readonly`

### Typical Configuration

Multiple accounts with standard roles:

```json
{
  "projects": {
    "acme-corp": {
      "accounts": {
        "dev": {
          "id": "111111111111",
          "roles": ["Developer", "ReadOnly"]
        },
        "staging": {
          "id": "222222222222",
          "roles": ["Developer", "ReadOnly"]
        },
        "prod": {
          "id": "333333333333",
          "roles": ["ReadOnly", "Support"]
        }
      }
    }
  }
}
```

**Generated:**
- 6 profiles (dev×2, staging×2, prod×2)
- 6 shell functions with standardized naming

### Complex Configuration

Multiple projects with aliases:

```json
{
  "projects": {
    "platform": {
      "accounts": {
        "shared-services": {
          "id": "444444444444",
          "roles": ["NetworkAdmin", "SecurityAuditor", "ReadOnly"],
          "aliases": {
            "net": "NetworkAdmin",
            "sec": "SecurityAuditor",
            "ro": "ReadOnly"
          }
        },
        "production": {
          "id": "555555555555",
          "roles": ["Developer", "Support", "ReadOnly"],
          "aliases": {
            "dev": "Developer",
            "sup": "Support"
          }
        }
      }
    },
    "data-platform": {
      "accounts": {
        "analytics": {
          "id": "666666666666",
          "roles": ["DataEngineer", "DataScientist", "ReadOnly"]
        }
      }
    }
  }
}
```

**Generated:**
- 9 profiles across 2 projects
- Aliases create additional convenience functions
- `aws-platform-shared-services-net` → `aws-platform-shared-services-networkadmin`

---

## Role Types and Best Practices

### Standard AWS Roles

| Role Type        | Purpose                          | Typical Permissions         |
|------------------|----------------------------------|-----------------------------|
| `ReadOnly`       | View-only access                 | Read EC2, S3, CloudWatch    |
| `Developer`      | Development and testing          | Create/modify resources     |
| `Support`        | Production support               | Limited write, full read    |
| `PowerUser`      | Advanced operations              | Most services, no IAM       |
| `Administrator`  | Full account access              | All permissions             |

### Custom Roles

You can define any role name that exists in your AWS accounts:

```json
{
  "roles": [
    "DataEngineer",
    "MLOpsEngineer",
    "SecurityAuditor",
    "NetworkAdmin",
    "BillingAdmin"
  ]
}
```

**Requirements:**
- Role must exist in the AWS account
- Role name must match exactly (case-sensitive)
- Role must have trust relationship with source account

### Role Naming Conventions

**Recommended patterns:**

- **Standard roles:** PascalCase (e.g., `ReadOnly`, `PowerUser`)
- **Custom roles:** PascalCase with domain prefix (e.g., `DataEngineer`, `MLOpsAdmin`)
- **Service roles:** Include service name (e.g., `EKSAdmin`, `RDSOperator`)

**Avoid:**
- Special characters (except hyphens in account names)
- Spaces in role names
- Overly long names (>30 characters)

---

## Validation Requirements

### Schema Validation

**Account ID:**
- ✅ Must be exactly 12 digits
- ✅ Must be numeric string
- ❌ No leading zeros removed
- ❌ No spaces or hyphens

```json
{
  "id": "123456789012"  // ✅ Correct
  "id": "12345678901"   // ❌ Too short
  "id": 123456789012    // ❌ Number (should be string)
}
```

**Roles Array:**
- ✅ Must be array of strings
- ✅ At least one role required
- ✅ Duplicate roles allowed (but unnecessary)
- ❌ Empty array not allowed

```json
{
  "roles": ["ReadOnly", "Developer"]  // ✅ Correct
  "roles": []                         // ❌ Empty
  "roles": "ReadOnly"                 // ❌ String (should be array)
}
```

**Aliases:**
- ✅ Must map to role in `roles` array
- ✅ Short names can be any valid string
- ❌ Cannot reference non-existent roles

```json
{
  "roles": ["Developer", "ReadOnly"],
  "aliases": {
    "dev": "Developer",     // ✅ Valid
    "admin": "Administrator" // ❌ Role not in roles array
  }
}
```

### Naming Validation

**Project names:**
- Lowercase recommended
- Use hyphens for word separation
- Avoid spaces and special characters

**Account names:**
- Lowercase recommended
- Common patterns: `dev`, `staging`, `prod`, `shared-services`
- Keep concise but descriptive

**Role names:**
- PascalCase recommended
- Must match AWS IAM role exactly
- Case-sensitive

---

## Generated Output

### AWS CLI Profiles

Generated in `~/.aws/config`:

```ini
[profile project-account-role]
sso_start_url = https://your-domain.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = RoleName
region = us-west-2
output = json
```

**Naming pattern:** `{project}-{account}-{role}` (all lowercase)

### Shell Functions

Generated in Nix configuration:

```bash
# Standard function
aws-project-account-role() {
  export AWS_PROFILE="project-account-role"
  echo "✅ AWS Profile: project-account-role (Account: account, Role: RoleName)"
}

# Alias function (if defined)
aws-project-account-shortname() {
  aws-project-account-fullrolename
}
```

### Usage Examples

```bash
# List all AWS functions
awslist

# Switch to profile
aws-platform-prod-readonly
# ✅ AWS Profile: platform-prod-readonly (Account: prod, Role: ReadOnly)

# Use alias
aws-platform-prod-ro  # Same as aws-platform-prod-readonly

# Check current profile
awswho
# Current AWS Profile: platform-prod-readonly
# Account: 555555555555
# Role: ReadOnly

# Run AWS commands
aws s3 ls
aws ec2 describe-instances
```

---

## Migration Guide

### From Manual Configuration

**Old approach** (manual AWS config editing):

1. Edit `~/.aws/config` directly
2. Create shell functions in Nix
3. Update both when adding accounts

**New approach** (schema-based):

1. Define in `accounts.json` once
2. Automatic profile generation
3. Automatic function generation

### Migration Steps

**Step 1:** Create `user-data/aws/accounts.json`:

```bash
cd ~/nix-darwin/user-data/aws
touch accounts.json
```

**Step 2:** Extract existing accounts from `~/.aws/config`:

Look for patterns like:
```ini
[profile my-profile]
sso_account_id = 123456789012
sso_role_name = Developer
```

**Step 3:** Convert to schema format:

```json
{
  "projects": {
    "project-name": {
      "accounts": {
        "account-name": {
          "id": "123456789012",
          "roles": ["Developer"]
        }
      }
    }
  }
}
```

**Step 4:** Remove manual functions from Nix:

Delete any `aws-*` function definitions in Nix files.

**Step 5:** Rebuild:

```bash
nix-rebuild
```

**Step 6:** Verify:

```bash
awslist  # Should show all generated functions
```

### Validation Checklist

After migration:

- [ ] All accounts present in `accounts.json`
- [ ] Account IDs are 12-digit strings
- [ ] All roles exist in AWS accounts
- [ ] Aliases point to valid roles
- [ ] `awslist` shows all expected functions
- [ ] `awswho` works correctly
- [ ] Can switch profiles successfully
- [ ] AWS CLI commands work

---

## Advanced Patterns

### Multi-Region Accounts

Define region-specific accounts:

```json
{
  "projects": {
    "global-app": {
      "accounts": {
        "prod-us-east-1": {
          "id": "111111111111",
          "roles": ["Developer"]
        },
        "prod-eu-west-1": {
          "id": "222222222222",
          "roles": ["Developer"]
        }
      }
    }
  }
}
```

### Role Hierarchy

Organize by access level:

```json
{
  "projects": {
    "platform": {
      "accounts": {
        "production": {
          "id": "123456789012",
          "roles": [
            "ReadOnly",        // Tier 1: View only
            "Support",         // Tier 2: Limited write
            "Developer",       // Tier 3: Full development
            "Administrator"    // Tier 4: Full access
          ]
        }
      }
    }
  }
}
```

### Environment-Based Structure

```json
{
  "projects": {
    "app": {
      "accounts": {
        "dev": {
          "id": "111111111111",
          "roles": ["Developer", "ReadOnly"],
          "aliases": { "dev": "Developer" }
        },
        "staging": {
          "id": "222222222222",
          "roles": ["Developer", "ReadOnly"],
          "aliases": { "dev": "Developer" }
        },
        "prod": {
          "id": "333333333333",
          "roles": ["ReadOnly", "Support"],
          "aliases": { "sup": "Support" }
        }
      }
    }
  }
}
```

---

## Troubleshooting

### Common Issues

**Problem:** Generated function not found

```bash
aws-my-project-prod-developer
# zsh: command not found: aws-my-project-prod-developer
```

**Solution:**
1. Check spelling in `accounts.json`
2. Rebuild: `nix-rebuild`
3. Restart shell: `exec zsh`
4. Verify with: `awslist`

---

**Problem:** AWS CLI says role doesn't exist

```bash
aws s3 ls
# Error: Role 'Developer' does not exist
```

**Solution:**
1. Verify role exists in AWS account
2. Check role name matches exactly (case-sensitive)
3. Ensure trust relationship allows assumption
4. Check account ID is correct

---

**Problem:** Profile not working after update

```bash
aws-my-project-prod-readonly
# Old profile behavior
```

**Solution:**
1. Update `accounts.json`
2. Rebuild: `nix-rebuild`
3. AWS CLI will use new profile on next use
4. May need to re-run SSO login: `awslogin`

---

**Problem:** Aliases not working

```bash
aws-platform-prod-ro
# zsh: command not found
```

**Solution:**
1. Check alias defined in `accounts.json`
2. Verify alias points to role in `roles` array
3. Rebuild: `nix-rebuild`
4. Restart shell: `exec zsh`

---

## Best Practices

### Organization

1. **Group by project** - Use projects to organize related accounts
2. **Consistent naming** - Use standard patterns (dev, staging, prod)
3. **Document roles** - Comment complex role hierarchies
4. **Use aliases** - Create short names for frequently used roles

### Security

1. **Least privilege** - Include only roles actually needed
2. **Separate projects** - Don't mix unrelated accounts
3. **Version control** - Keep `accounts.json` in git
4. **Regular audits** - Review and remove unused accounts/roles

### Maintenance

1. **Validate before commit** - Test configuration changes
2. **Document changes** - Note why accounts were added/removed
3. **Standardize roles** - Use consistent role names across accounts
4. **Keep updated** - Remove decommissioned accounts promptly

### Performance

1. **Limit roles per account** - Only include roles you actually use
2. **Avoid duplicate aliases** - Each alias should be unique
3. **Use descriptive names** - Makes functions easier to find
4. **Group related accounts** - Easier to manage in one project

---

## Related Documentation

- **[AWS Multi-Role Guide](../../claudedocs/reference/aws/AWS-MULTI-ROLE.md)** - Complete AWS setup and usage
- **[AWS Quick Reference](../../claudedocs/reference/aws/AWS-QUICK-REF.md)** - Daily command cheat sheet
- **[Infrastructure Reference](./infrastructure.md#aws)** - AWS tools and commands
- **[Work Setup Guide](../guides/work-setup.md)** - Work Mac configuration

---

**Version:** 2.0.0
**Last Updated:** 2025-11-07
**Status:** Production Ready ✅
