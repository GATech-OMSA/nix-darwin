# AWS Accounts Configuration (Work Profile)

## Overview

The work profile uses AWS SSO for multi-account access. Account configuration is managed through `~/.aws/accounts.json`, which can be encrypted via SOPS.

## Setup Options

### Option 1: Unencrypted (Quick Start)

```bash
# Copy template
cp nix-config/home/_profiles/work/accounts.json.template ~/.aws/accounts.json

# Edit with your account IDs
code ~/.aws/accounts.json

# Use immediately (no rebuild needed)
awslist
```

### Option 2: Encrypted via SOPS (Recommended for Production)

**Step 1: Add to secrets.yaml**

```bash
# Edit your work machine's secrets
edit-secrets

# Add this field (copy from accounts.json.template, fill in real IDs):
aws_accounts: |
  {
    "work-domain": {
      "description": "Work AWS Organization",
      "default_role": "support",
      "accounts": {
        "dev": {
          "id": "123456789012",
          "region": "us-east-1",
          "additional_roles": ["developer", "poweruser"]
        },
        ...
      }
    }
  }
```

**Step 2: Rebuild to deploy**

```bash
nix-rebuild && exec zsh
```

**Step 3: Verify deployment**

```bash
cat ~/.aws/accounts.json  # Should show decrypted content
awslist                    # Should show your profiles
```

## Account Structure

### Simple Format (String)
```json
"accounts": {
  "dev": "123456789012",
  "qa": "234567890123"
}
```

### Extended Format (Object with Additional Roles)
```json
"accounts": {
  "dev": {
    "id": "123456789012",
    "region": "us-east-1",
    "additional_roles": ["developer", "poweruser"]
  }
}
```

**Extended format creates multiple profiles:**
- `project-dev` (default role: support)
- `project-dev-developer` (developer role)
- `project-dev-poweruser` (poweruser role)

## Usage

### Profile Switching
```bash
# Use project alias + environment
awsuse ti sbx                  # tririga-integrations sbx (support role)
awsuse ti sbx developer        # tririga-integrations sbx (developer role)
awsuse ps dev                  # paging-solution dev

# Generated aliases (auto-created from accounts.json)
tidev                          # tririga-integrations dev
tisbx                          # tririga-integrations sbx
psdev                          # paging-solution dev
```

### SSO Login
```bash
awslogin ti sbx                # Login + switch profile
```

### Profile Information
```bash
awswho                         # Show current profile
awslist                        # List all profiles
awswhere ti                    # Show tririga-integrations profiles
awscheck                       # Verify SSO session validity
```

## Integration with ~/.aws/config

Your `~/.aws/config` is auto-generated from this file via `nix-config/home/_profiles/_template/programs/aws.nix`.

**Generated profiles match accounts.json structure:**
```ini
[profile tririga-integrations-sbx]
sso_session = sso-east-1
sso_account_id = 456789012345
sso_role_name = support
region = us-east-1

[profile tririga-integrations-sbx-developer]
sso_session = sso-east-1
sso_account_id = 456789012345
sso_role_name = developer
region = us-east-1
```

## Comparison with Personal Profile

| Feature | Personal Profile | Work Profile |
|---------|------------------|--------------|
| **Auth Method** | IAM access keys | AWS SSO |
| **Config File** | `~/.aws/config` (regions) | `~/.aws/config` (SSO + regions) |
| **Credentials** | `~/.aws/credentials` (encrypted) | SSO session tokens |
| **Accounts** | Single personal account | Multiple org accounts |
| **Profile Source** | Static config | `accounts.json` + auto-generation |

## Security Notes

**If using encrypted approach:**
- ✅ Account IDs encrypted in secrets.yaml
- ✅ Deployed to `~/.aws/accounts.json` on rebuild
- ✅ File protected with 600 permissions
- ✅ Never committed to version control

**If using unencrypted approach:**
- ⚠️ `~/.aws/accounts.json` is gitignored
- ⚠️ Account IDs are not secret, but keep them private
- ✅ No credentials stored (SSO handles that)

## Troubleshooting

**Profiles not showing up:**
```bash
awslist                        # Verify accounts.json loaded
cat ~/.aws/accounts.json       # Check file exists and has content
```

**SSO login failing:**
```bash
aws sso login --profile work-domain  # Test base SSO session
awscheck                              # Verify session validity
```

**Config/accounts mismatch:**
```bash
nix-rebuild                    # Regenerate ~/.aws/config from accounts.json
```
