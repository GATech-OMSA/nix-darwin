# Bootstrap/Config/Activate Workflow Test & Analysis

**Date**: 2025-11-09
**Status**: Analysis Complete - Ready for Testing
**Purpose**: Verify the complete setup.sh workflow for new users

---

## Workflow Overview

The setup.sh script handles 4 main scenarios:

1. **Fresh Setup** - New machine, no existing config
2. **Migrate** - Moving from another Mac (has local secrets)
3. **Restore** - Fork/clone with encrypted secrets
4. **Reconfigure** - Update existing machine config

---

## How It Works

### Entry Point: `./setup.sh`

**Flow**:
```bash
setup.sh
  ├─> check_prerequisites() - Verify Nix, git, etc.
  ├─> detect_environment() - Scan for configs/secrets
  └─> route_to_flow() - Choose appropriate workflow
      ├─> flow_fresh() - No configs, no secrets
      ├─> flow_migrate() - Has local secrets
      ├─> flow_restore() - Has encrypted secrets
      └─> flow_reconfigure() - Has machine-config.nix
```

### Detection Logic

**Files Checked**:
- `config/machine-config.nix` - If exists → reconfigure flow
- `hosts/*/secrets.yaml` - If exists → restore flow
- `~/.aws/credentials`, `~/.db/*`, etc. - If exists → migrate flow
- None of above → fresh flow

---

## Step-by-Step: Fresh Setup

### Phase 1: Gather User Info

**Function**: `gather_user_info()`

**Detects from system**:
- Username: `$(whoami)` → jimmy
- Email: `git config --global user.email`
- Full name: `git config --global user.name`
- Hostname: `$(hostname)` → mbp-jimmy

**User prompt**:
```
📋 Detected from your system:
Username:       jimmy           ✓
Email:          jimmy@example.com  ✓
Full name:      Jimmy User      ✓
Hostname:       mbp-jimmy       ✓

Options:
  [k] Keep detected values (fastest - just press Enter)
  [c] Customize specific values

Choice [k/c] (default: k): _
```

**Fast path** (press Enter):
- Uses all detected values
- Only prompts if email/name missing

**Custom path** (type 'c'):
- Selectively change each field
- Shows impact warnings (e.g., username change affects home directory)

**Result variables**:
- `$USERNAME` = "jimmy"
- `$EMAIL` = "jimmy@example.com"
- `$FULL_NAME` = "Jimmy User"
- `$MACHINE_ID` = "mbp-jimmy-2021" (will prompt to customize)

---

### Phase 2: Machine Configuration

**Function**: `configure_machine()`

**Creates**:

**File 1**: `config/user-config.nix`
```nix
{
  username = "jimmy";
  fullName = "Jimmy User";
  email = "jimmy@example.com";
}
```

**File 2**: `config/machine-config.nix`
```nix
{
  machineId = "mbp-jimmy-2021";
  machineType = "personal";  # or "work"
  description = "Jimmy's personal MacBook Pro";
  expectedHostname = "mbp-jimmy";
  mixins = [ "personal" "dev" ];
  system = "aarch64-darwin";
}
```

**File 3**: `hosts/mbp-jimmy-2021/default.nix`
- Copied from `hosts/_template/default.nix`
- Customized with machine description

---

### Phase 3: Secrets Setup (if applicable)

**Migrating local secrets**:

1. **Scan for secrets**:
```bash
~/.aws/credentials
~/.db/*
~/.tokens/*
user-data/app-configs/*/credentials
```

2. **User selection**:
```
Found local secrets:
  1) ~/.aws/credentials
  2) ~/.db/production.db
  3) ~/.tokens/github

Select secrets to encrypt [1,2,3 or 'all']: _
```

3. **SOPS encryption**:
```bash
# Generate age key (if doesn't exist)
age-keygen -o ~/.config/sops/age/keys.txt

# Extract public key
AGE_PUBLIC_KEY=$(age-keygen -y ~/.config/sops/age/keys.txt)

# Create secrets.yaml
cat > hosts/$MACHINE_ID/secrets.yaml <<EOF
aws_credentials: |
  [default]
  aws_access_key_id = ...
  aws_secret_access_key = ...
zsh_secrets: |
  export API_KEY="..."
sops:
  age:
    - recipient: $AGE_PUBLIC_KEY
EOF

# Encrypt in place
sops -e -i hosts/$MACHINE_ID/secrets.yaml
```

4. **Configure SOPS in Nix**:
- Updates `hosts/$MACHINE_ID/secrets-personal.nix`
- Sets up decryption targets

---

## Integration with Flake

### How flake.nix Uses Config Files

**Line 54-62**:
```nix
userConfig =
  if builtins.pathExists ./config/user-config.nix
  then import ./config/user-config.nix
  else throw ''
    config/user-config.nix not found!

    Run the configuration script first:
      ./configure.sh
  '';
```

**Line 64-72**:
```nix
machineConfig =
  if builtins.pathExists ./config/machine-config.nix
  then import ./config/machine-config.nix
  else throw ''
    config/machine-config.nix not found!

    Run the configuration script first:
      ./configure.sh
  '';
```

**Line 79-82**: Extract values for profile system
```nix
profileName = machineConfig.profileName or "personal";
machineId = machineConfig.machineId or "default";
system = machineConfig.system or "aarch64-darwin";
expectedHostname = machineConfig.expectedHostname or machineId;
```

---

## What Needs Testing

### Test 1: Fresh Setup (No Existing Config)

**Setup**:
```bash
cd /tmp
git clone /Users/jimmy/nix-darwin test-fresh
cd test-fresh
rm -rf config/{user,machine}-config.nix .nix-darwin-setup.state
```

**Execute**:
```bash
./setup.sh --fresh --dry-run
```

**Expected**:
- Detects user info from system
- Prompts for confirmation
- Shows what config files would be created
- Does NOT actually write files (dry-run)

**Verification**:
- Output should show detected values
- Should display file creation preview
- No errors or missing functions

---

### Test 2: Config File Generation

**Execute**:
```bash
./setup.sh --configure --force
```

**Expected**:
- Creates `config/user-config.nix`
- Creates `config/machine-config.nix`
- Creates `hosts/$MACHINE_ID/default.nix`

**Verification**:
```bash
# Files should exist
ls -la config/{user,machine}-config.nix

# Should be valid Nix syntax
nix-instantiate --eval --strict --json config/user-config.nix
nix-instantiate --eval --strict --json config/machine-config.nix

# Flake should recognize them
darwin-rebuild build --flake .#$MACHINE_ID --dry-run
```

---

### Test 3: Secrets Scanning

**Setup**:
```bash
# Create fake secrets
mkdir -p ~/.db
echo "secret data" > ~/.db/test.db

mkdir -p ~/.tokens
echo "token123" > ~/.tokens/test
```

**Execute**:
```bash
./setup.sh --migrate --dry-run
```

**Expected**:
- Scans and finds `~/.db/test.db` and `~/.tokens/test`
- Lists discovered secrets
- Shows encryption workflow (dry-run, doesn't execute)

**Verification**:
- Should list both files
- Should show SOPS encryption commands (not execute)
- Should explain where secrets would be stored

---

### Test 4: Profile System Integration

**After config creation**:
```bash
# Build should work
darwin-rebuild build --flake .

# Should use profile from machine-config.nix
grep "profileName" config/machine-config.nix  # Should match active profile

# Environment variables should be set
echo $ACTIVE_PROFILE  # Should match profileName
echo $MACHINE_ID      # Should match machineId
```

---

## Current Status

### ✅ What's Working

1. **Config file templates** - `config/*.nix.template` exist
2. **Flake integration** - Properly reads config files
3. **Profile system** - `home/_profiles/{personal,work,minimal}` structure
4. **Development configs** - Just restored Python 3.13 setup
5. **setup.sh exists** - Has all flow functions implemented

### ❓ What Needs Verification

1. **setup.sh execution** - Never actually run end-to-end
2. **Secrets scanning** - Logic exists but untested
3. **SOPS workflow** - Encryption/decryption integration
4. **Profile activation** - After fresh setup, does profile load correctly?
5. **Error handling** - What happens if user interrupts?
6. **Resume capability** - State file tracking works?

### 🔧 Potential Issues

1. **configure.sh vs setup.sh** - Flake mentions configure.sh but script is setup.sh
2. **Template placeholders** - Need to verify all CHANGE-ME get replaced
3. **Host directory creation** - Does it properly copy from _template?
4. **Git integration** - Should it auto-add config files to .gitignore?

---

## Recommended Testing Plan

### Phase 1: Dry Run Tests (Safe)
```bash
# Test fresh flow
./setup.sh --fresh --dry-run

# Test configure flow
./setup.sh --configure --dry-run

# Test migrate with fake secrets
./setup.sh --migrate --dry-run
```

### Phase 2: Isolated Environment Tests
```bash
# Create test VM or container
# Run actual setup.sh without dry-run
# Verify all files created correctly
# Test darwin-rebuild build
```

### Phase 3: Real Machine Test
```bash
# Use on actual new machine
# Document any UX issues
# Verify secrets encryption works
# Test profile activation
```

---

## Questions to Answer

1. **How do users know to run setup.sh?**
   - Is it in README/installation docs?
   - First-run detection?

2. **What if setup.sh is interrupted?**
   - State file exists but is it reliable?
   - Can user actually resume?

3. **Does secrets scanning catch everything?**
   - What about non-standard locations?
   - VSCode tokens, browser cookies?

4. **Profile switching after setup?**
   - If user wants to change personal → work?
   - Re-run setup.sh or manual edit?

5. **Validation checks?**
   - Does it verify Nix installation?
   - Check for required dependencies?
   - Validate flake syntax before build?

---

## Next Steps

1. ✅ Document current workflow (this file)
2. ⏳ Run dry-run tests to verify no errors
3. ⏳ Test in isolated environment
4. ⏳ Verify secrets scanning
5. ⏳ Test profile activation
6. ⏳ Update docs with findings
7. ⏳ Fix any discovered issues

---

**Created by**: Claude
**For**: Jimmy - nix-darwin verification
**Last updated**: 2025-11-09
