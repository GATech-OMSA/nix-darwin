# Generated Configs Directory

This directory contains **user-specific configuration templates** that are **gitignored** to allow personalization without affecting the main repository.

## Purpose

The `generated/` directory solves the problem of **work profile portability**:

- ✅ Templates are tracked in git (`.template` files)
- ✅ Your customized files are gitignored (not committed)
- ✅ Easy to share and migrate between machines
- ✅ No hardcoded usernames or personal info in main repo

---

## Available Templates

### 1. work.nix.template

**Purpose**: Work machine configuration template

**Contains**:
- AWS CLI configuration (corporate CA bundle)
- Work-specific packages (ODBC drivers, database clients)
- Project directory shortcuts
- Database instance connectors
- Custom shell functions
- Token helpers

**Usage**:

```bash
# Copy template to your personal work config
cp home/_mixins/generated/work.nix.template home/_mixins/generated/work-<username>.nix

# Example:
cp home/_mixins/generated/work.nix.template home/_mixins/generated/work-john.nix

# Customize your file
code home/_mixins/generated/work-john.nix

# Update flake.nix to import your file instead of the default work.nix
# Replace:   ./home/_mixins/work.nix
# With:      ./home/_mixins/generated/work-john.nix

# Rebuild to apply changes
nix-rebuild
```

---

### 2. accounts.json.template

**Purpose**: AWS multi-role configuration template

**Contains**:
- Example AWS account structures
- Work domain configuration
- Multi-environment project examples
- Personal AWS account example
- Field definitions and usage examples

**Usage**:

```bash
# Copy template to AWS config directory
cp home/_mixins/generated/accounts.json.template ~/.aws/accounts.json

# Edit with your actual AWS account IDs and projects
code ~/.aws/accounts.json

# Verify configuration loaded correctly
exec zsh
awslist

# Generated aliases will be available:
# mpdev    - awsuse my-project dev
# mpqa     - awsuse my-project qa
# mpprod   - awsuse my-project prod
```

**Note**: This file is separate from the Nix configuration. Changes don't require `nix-rebuild`, just `exec zsh` to reload shell.

---

## Quick Start Guide

### For New Users

1. **Copy the work.nix template**:
   ```bash
   cp home/_mixins/generated/work.nix.template home/_mixins/generated/work-$(whoami).nix
   ```

2. **Customize your work config**:
   - Add your project directory shortcuts (line 91+)
   - Add your database instances (line 160+)
   - Add your work-specific packages (line 51+)
   - Add any custom functions you need

3. **Update flake.nix**:
   ```bash
   # Edit flake.nix
   code flake.nix

   # Find the work.nix import and replace with your file:
   # ./home/_mixins/work.nix  →  ./home/_mixins/generated/work-$(whoami).nix
   ```

4. **Create AWS accounts.json** (optional):
   ```bash
   cp home/_mixins/generated/accounts.json.template ~/.aws/accounts.json
   code ~/.aws/accounts.json
   ```

5. **Rebuild and test**:
   ```bash
   nix-rebuild
   exec zsh
   ```

---

### For Migrating from Current Setup

If you're migrating from an existing `work.nix`:

1. **Backup your current work.nix**:
   ```bash
   cp home/_mixins/work.nix home/_mixins/work.nix.backup
   ```

2. **Copy to generated/**:
   ```bash
   cp home/_mixins/work.nix home/_mixins/generated/work-$(whoami).nix
   ```

3. **Update flake.nix**:
   - Replace `./home/_mixins/work.nix` with `./home/_mixins/generated/work-$(whoami).nix`

4. **Test**:
   ```bash
   nix-rebuild
   exec zsh
   ```

5. **Optional: Remove old work.nix** (after confirming everything works):
   ```bash
   rm home/_mixins/work.nix.backup
   ```

---

## File Structure

```
home/_mixins/generated/
├── README.md                      ← This file (tracked in git)
├── work.nix.template              ← Template (tracked in git)
├── accounts.json.template         ← Template (tracked in git)
├── work-<username>.nix            ← Your customized file (gitignored)
└── (any other user-specific files)
```

**Tracked in git**:
- `*.template` files
- `README.md`

**Gitignored** (not committed):
- `work-*.nix`
- Any other non-template files

---

## Customization Tips

### Project Directory Shortcuts

```nix
programs.zsh.shellAliases = {
  # Pattern: f<name> = "cd ~/Dev/<project>"
  fapi = "cd ~/Dev/api-service";
  fdocs = "cd ~/Dev/documentation";
  fscripts = "cd ~/Dev/automation-scripts";
};
```

**Usage**: Type `fapi` to jump to `~/Dev/api-service`

---

### Database Instances

```nix
${myLib.database.mkDatabaseInstances [
  {
    instance = "myapp";           # Creates: dbconnect-myapp <env>
    type = "postgres";             # postgres, oracle, mssql, mysql
    environments = [ "dev" "prod" ];  # Available environments
    description = "My App Database";
  }
]}
```

**Usage**: `dbconnect-myapp dev` to connect to myapp dev database

**Prerequisites**: Environment variables in SOPS secrets:
- `MYAPP_DEV_USERNAME`
- `MYAPP_DEV_PASSWORD`
- `MYAPP_DEV_HOST`
- `MYAPP_DEV_PORT`
- `MYAPP_DEV_DATABASE` (or `_SERVICE` for Oracle)

---

### AWS Accounts Configuration

```json
{
  "my-project": {
    "profiles": [
      {
        "name": "my-project-dev",
        "alias": "mp",
        "account_id": "123456789012",
        "env": "dev",
        "role": "PowerUserAccess",
        "region": "us-west-2"
      }
    ]
  }
}
```

**Generated aliases**:
- `mpdev` → `awsuse mp dev`
- `mpdev-developer` → `awsuse mp dev developer`

---

## Troubleshooting

### Template not found

**Problem**: `error: file 'home/_mixins/generated/work-john.nix' not found`

**Solution**:
1. Ensure you copied the template: `cp work.nix.template work-john.nix`
2. Check flake.nix references the correct file path
3. Rebuild: `nix-rebuild`

---

### AWS aliases not working

**Problem**: `awsuse` command not found or aliases like `mpdev` don't exist

**Solution**:
1. Verify `~/.aws/accounts.json` exists and is valid JSON
2. Reload shell: `exec zsh`
3. Check configuration: `awslist`
4. Verify MACHINE_MODE=work: `echo $MACHINE_MODE`

---

### Database connection fails

**Problem**: `dbconnect-mydb dev` fails with "credentials not found"

**Solution**:
1. Ensure secrets are encrypted in SOPS: `edit-secrets`
2. Add required environment variables (see template comments)
3. Rebuild: `nix-rebuild`
4. Reload shell: `exec zsh`
5. Test: `dbconnect-mydb dev`

---

## Migration Checklist

When moving to a new machine:

- [ ] Copy `work-<username>.nix` from old machine (or recreate from template)
- [ ] Copy `~/.aws/accounts.json` from old machine (or recreate from template)
- [ ] Update flake.nix to import your work config
- [ ] Run `nix-rebuild`
- [ ] Reload shell: `exec zsh`
- [ ] Test aliases: `awslist`, `dblist`
- [ ] Verify project shortcuts work

---

## Security Notes

### Files Tracked in Git (Safe)

- `*.template` files - No personal info, safe to share
- `README.md` - Documentation

### Files Gitignored (Personal)

- `work-*.nix` - May contain company-specific project names
- `~/.aws/accounts.json` - Contains AWS account IDs

**Note**: Even gitignored files should NOT contain plaintext credentials. Use SOPS for all secrets.

---

## Further Reading

- **[docs/guides/multi-machine-setup.md](../../docs/guides/multi-machine-setup.md)** - Complete multi-machine setup guide
- **[docs/reference/infrastructure.md](../../docs/reference/infrastructure.md)** - AWS and database documentation
- **[docs/guides/secrets.md](../../docs/guides/secrets.md)** - SOPS secret management guide

---

**Questions?** Check the [FAQ](../../docs/appendix/faq.md) or [Troubleshooting Guide](../../docs/guides/troubleshooting.md)
