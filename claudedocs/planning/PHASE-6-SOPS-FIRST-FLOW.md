# Phase 6: SOPS-First Migration Flow

**Critical Principle**: SOPS encryption MUST be set up BEFORE any secrets are handled

---

## Migration Flow Diagram

```
./setup.sh --migrate
        │
        ├─── Step 0: Prerequisites Check
        │    ├─ Check nix-darwin installed
        │    ├─ Check SOPS available
        │    └─ Check age available
        │
        ├─── 🔐 STEP 1: SOPS SETUP (MANDATORY)
        │    │
        │    ├─ 1a. Generate age key
        │    │   ├─ Create ~/.config/sops/age/keys.txt
        │    │   ├─ Display key: age1xyz...abc123
        │    │   └─ Validate key format (AGE-SECRET-KEY)
        │    │
        │    ├─ 1b. Force user confirmation 🚨
        │    │   ├─ Display backup instructions
        │    │   │   • Password manager (1Password, Bitwarden)
        │    │   │   • USB drive (encrypted)
        │    │   │   • Paper backup (secure location)
        │    │   │
        │    │   ├─ Blocking prompt: "Have you saved your key? (yes/no)"
        │    │   └─ Loop until user confirms "yes"
        │    │
        │    ├─ 1c. Verify SOPS working
        │    │   ├─ Test encryption (create dummy file)
        │    │   ├─ Test decryption (verify can decrypt)
        │    │   └─ Clean up test files
        │    │
        │    └─ ✅ SOPS VERIFIED - Proceed to secrets discovery
        │
        ├─── 🔍 STEP 2: SECRETS DISCOVERY
        │    │
        │    ├─ Discover AWS credentials
        │    │   ├─ ~/.aws/credentials
        │    │   └─ ~/.aws/config
        │    │
        │    ├─ Discover SSH keys (private only)
        │    │   ├─ ~/.ssh/id_rsa
        │    │   ├─ ~/.ssh/id_ed25519
        │    │   └─ ~/.ssh/id_ed25519_work
        │    │
        │    ├─ Discover database credentials
        │    │   └─ ~/.db/{type}/{env}/*
        │    │
        │    ├─ Discover API tokens
        │    │   ├─ ~/.tokens/git_token
        │    │   ├─ ~/.tokens/hcp_terraform_token
        │    │   └─ ~/.tokens/jira_api_token
        │    │
        │    └─ Display summary for user review
        │
        ├─── ❓ STEP 3: USER CONFIRMATION
        │    │
        │    ├─ Show discovered secrets list
        │    ├─ Ask: "Migrate all? (yes/no/review)"
        │    │
        │    ├─ If "review": Show each secret, ask individually
        │    ├─ If "no": Skip secrets migration
        │    └─ If "yes": Proceed to migration
        │
        ├─── 📝 STEP 4: SECRETS MIGRATION
        │    │
        │    ├─ Create hosts/${machineId}/secrets.yaml
        │    │
        │    ├─ Copy discovered secrets to secrets.yaml
        │    │   ├─ AWS credentials → aws_credentials
        │    │   ├─ SSH keys → ssh_key_{name}
        │    │   ├─ Database creds → db_{instance}_{env}
        │    │   └─ API tokens → token_{name}
        │    │
        │    ├─ Show progress for each secret
        │    │   ✅ AWS credentials → encrypted
        │    │   ✅ SSH key id_ed25519 → encrypted
        │    │   ✅ Database ti_prod → encrypted
        │    │   ...
        │    │
        │    └─ Generate .sops.yaml config (if needed)
        │
        ├─── 🔐 STEP 5: ENCRYPTION
        │    │
        │    ├─ Encrypt secrets.yaml with SOPS
        │    │   └─ sops -e -i hosts/${machineId}/secrets.yaml
        │    │
        │    ├─ Verify file is binary (encrypted)
        │    │   └─ Check file header for SOPS markers
        │    │
        │    └─ Show encryption success
        │
        ├─── ✅ STEP 6: VERIFICATION
        │    │
        │    ├─ Test decryption
        │    │   └─ sops -d hosts/${machineId}/secrets.yaml
        │    │
        │    ├─ Verify all secrets accessible
        │    │   ├─ Can read aws_credentials
        │    │   ├─ Can read ssh_key_*
        │    │   ├─ Can read db_*
        │    │   └─ Can read token_*
        │    │
        │    ├─ Show verification summary
        │    │   ✅ Decryption works
        │    │   ✅ All secrets accessible
        │    │   ✅ File is properly encrypted
        │    │
        │    └─ 🚨 ABORT if any check fails
        │
        ├─── ⚠️  STEP 7: FINAL WARNING
        │    │
        │    ├─ Display key backup reminder
        │    │   ⚠️  CRITICAL: Keep your age key secure!
        │    │       Location: ~/.config/sops/age/keys.txt
        │    │       If lost: Cannot decrypt secrets!
        │    │
        │    ├─ Blocking confirmation
        │    │   └─ "Press Enter to continue with setup..."
        │    │
        │    └─ User must acknowledge before proceeding
        │
        └─── 🎯 STEP 8: CONTINUE SETUP
             │
             ├─ Now safe to proceed with:
             │   • Machine configuration
             │   • Config discovery
             │   • VS Code setup
             │   • Work profile migration
             │
             └─ All secrets are encrypted and secure
```

---

## Critical Safety Checks

### Before SOPS Setup
```bash
# Check SOPS available
if ! command -v sops &>/dev/null; then
  echo "❌ SOPS not installed!"
  echo "Install: brew install sops"
  exit 1
fi

# Check age available
if ! command -v age &>/dev/null; then
  echo "❌ age not installed!"
  echo "Install: brew install age"
  exit 1
fi
```

### During SOPS Setup
```bash
# 1. Age key validation
if [ ! -f ~/.config/sops/age/keys.txt ]; then
  echo "❌ Age key not found!"
  exit 1
fi

if ! grep -q "AGE-SECRET-KEY" ~/.config/sops/age/keys.txt; then
  echo "❌ Invalid age key format!"
  exit 1
fi

# 2. User confirmation (blocking loop)
while true; do
  read -p "Have you saved your key securely? (yes/no): " confirm
  case $confirm in
    yes|YES|y|Y )
      break
      ;;
    no|NO|n|N )
      echo ""
      echo "⚠️  You MUST save your key before continuing!"
      echo ""
      echo "Backup options:"
      echo "  • Password manager (1Password, Bitwarden)"
      echo "  • USB drive (encrypted)"
      echo "  • Paper backup (secure location)"
      echo ""
      ;;
    * )
      echo "Please answer yes or no"
      ;;
  esac
done

# 3. SOPS encryption test
TEST_FILE=$(mktemp)
echo "test" > "$TEST_FILE"

if ! sops -e -i "$TEST_FILE" 2>/dev/null; then
  echo "❌ SOPS encryption failed!"
  rm -f "$TEST_FILE"
  exit 1
fi

# 4. SOPS decryption test
if ! sops -d "$TEST_FILE" > /dev/null 2>&1; then
  echo "❌ SOPS decryption failed!"
  rm -f "$TEST_FILE"
  exit 1
fi

rm -f "$TEST_FILE"
echo "✅ SOPS verified - encryption/decryption working"
```

### After Secrets Migration
```bash
# 1. Verify file encrypted
if ! file hosts/${machineId}/secrets.yaml | grep -q "data"; then
  echo "❌ secrets.yaml is not encrypted (plaintext detected)!"
  exit 1
fi

# 2. Test decryption
if ! sops -d hosts/${machineId}/secrets.yaml > /dev/null 2>&1; then
  echo "❌ Cannot decrypt secrets.yaml with your key!"
  echo "⚠️  This should never happen - something went wrong!"
  exit 1
fi

# 3. Verify secrets accessible
TEMP_DECRYPT=$(mktemp)
sops -d hosts/${machineId}/secrets.yaml > "$TEMP_DECRYPT"

# Check for expected secret keys
if ! grep -q "aws_credentials" "$TEMP_DECRYPT"; then
  echo "⚠️  Warning: aws_credentials not found in secrets"
fi

rm -f "$TEMP_DECRYPT"

echo "✅ Secrets migration verified"
```

---

## Blocking Points (Cannot Proceed Until Resolved)

### 🚫 Checkpoint 1: SOPS Installation
**Cannot proceed if**: SOPS or age not installed
**Solution**: Install via Homebrew or Nix

### 🚫 Checkpoint 2: Key Generation
**Cannot proceed if**: Age key generation fails
**Solution**: Check permissions, disk space, age binary

### 🚫 Checkpoint 3: User Confirmation
**Cannot proceed if**: User doesn't confirm key backup
**Solution**: Block in loop until user confirms "yes"

### 🚫 Checkpoint 4: SOPS Functionality
**Cannot proceed if**: SOPS encryption/decryption test fails
**Solution**: Debug SOPS config, check age key format

### 🚫 Checkpoint 5: Secrets Migration
**Cannot proceed if**: secrets.yaml not encrypted or can't decrypt
**Solution**: Re-run encryption, verify age key, check SOPS config

### 🚫 Checkpoint 6: Final Verification
**Cannot proceed if**: Any verification check fails
**Solution**: Review all previous steps, start from checkpoint that failed

---

## Error Handling

### Age Key Generation Failure
```bash
Error: Failed to generate age key
Cause: ~/.config/sops/age directory not writable
Fix:
  mkdir -p ~/.config/sops/age
  chmod 700 ~/.config/sops/age
  Retry key generation
```

### SOPS Encryption Failure
```bash
Error: SOPS cannot encrypt file
Cause: Age key not configured in SOPS
Fix:
  Check ~/.config/sops/age/keys.txt exists
  Check key format (AGE-SECRET-KEY-1...)
  Create .sops.yaml config if needed
```

### Secrets Discovery Empty
```bash
Warning: No secrets found
Cause: Fresh machine, no existing configs
Action: Skip secrets migration (not an error)
        User can add secrets later via edit-secrets
```

### Decryption Verification Failure
```bash
Error: Cannot decrypt secrets.yaml
Cause: Wrong age key or corrupted file
Fix:
  🚨 CRITICAL: DO NOT CONTINUE
  Restore from backup or re-run SOPS setup
  Never proceed with broken encryption
```

---

## User Communication

### Before SOPS Setup
```
🔐 Setting up secrets encryption...

This is the MOST IMPORTANT step of the setup.
Your age encryption key protects all your secrets.

⚠️  If you lose this key, you CANNOT decrypt your secrets!

Please pay close attention to the next steps.
```

### During Key Generation
```
1️⃣ Generating age encryption key...

✅ Age key generated: age1xyz...abc123
✅ Saved to: ~/.config/sops/age/keys.txt

2️⃣ Save your encryption key!

⚠️  CRITICAL: Store this key securely!

Key location: ~/.config/sops/age/keys.txt

📋 Backup options:
   • Password manager (1Password, Bitwarden)
   • USB drive (encrypted)
   • Paper backup (secure location)

⚠️  Without this key, you CANNOT decrypt your secrets!

❓ Have you saved your key securely? (yes/no)
```

### After Verification
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SOPS setup complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Age key generated and verified
✅ Secrets discovered and migrated
✅ Encryption working correctly
✅ All secrets accessible

⚠️  IMPORTANT: Keep your age key secure!
   Location: ~/.config/sops/age/keys.txt
   If lost, you cannot decrypt these secrets.

Press Enter to continue with system configuration...
```

---

## Why SOPS Must Be First

### 1. Security
- **Secrets never touch disk unencrypted** during migration
- **Immediate encryption** as secrets are discovered
- **Verify working** before handling sensitive data

### 2. Reliability
- **Test encryption/decryption** before importing secrets
- **Catch issues early** before secrets are at risk
- **Rollback safe** if SOPS setup fails

### 3. User Experience
- **Clear blocking points** - user knows what's required
- **Forced confirmation** - prevents accidental skipping
- **Verification before proceeding** - confidence in security

### 4. Data Integrity
- **All or nothing** - either fully encrypted or abort
- **Verification step** ensures secrets readable
- **No partial states** that could corrupt secrets

---

## Timeline

**SOPS Setup (Task 6.0)**: 1-2 hours
- Age key generation: 5 minutes
- User confirmation: Variable (user-dependent)
- Secrets discovery: 10-15 minutes
- Migration + encryption: 15-20 minutes
- Verification: 10 minutes
- **Buffer**: 30 minutes for issues

**Critical**: This MUST complete before any other Phase 6 tasks

---

## Success Criteria

- [ ] Age key generated
- [ ] User confirmed key backup (yes/no prompt)
- [ ] SOPS encryption test passed
- [ ] SOPS decryption test passed
- [ ] All secrets discovered
- [ ] User reviewed/approved secrets list
- [ ] secrets.yaml created
- [ ] secrets.yaml encrypted (binary format)
- [ ] Can decrypt secrets.yaml
- [ ] All secrets accessible after decryption
- [ ] User acknowledged final warning
- [ ] Ready to proceed to Tier 1

**ALL checks must pass before proceeding**
