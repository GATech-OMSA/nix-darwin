# Warning System Usage Examples

Quick reference for using the warning system in nix-darwin shell functions.

## Basic Shell Helpers

### Simple Warning Message

```bash
# Display an informational message
warn "This is an informational message" "INFO"

# Display a warning
warn "This operation will modify system files" "WARNING"

# Display a critical warning
warn "This will delete data permanently" "CRITICAL"
```

**Output**:
```
ℹ️  INFO: This is an informational message
⚠️  WARNING: This operation will modify system files
🚨 CRITICAL: This will delete data permanently
```

### Simple Confirmation

```bash
# Ask user to confirm
if confirm "Do you want to proceed?"; then
  echo "User confirmed"
else
  echo "User cancelled"
fi

# Inline usage
confirm "Delete this file?" && rm file.txt
```

**Output**:
```
Do you want to proceed? (y/N) █
```

### Risky Operation Wrapper

```bash
# Wrap a risky command
risky "WARNING" "This will restart the service" systemctl restart myservice

# With multiple commands
risky "WARNING" "This will update all packages" sh -c "brew update && brew upgrade"
```

**Output**:
```
⚠️  WARNING: This will restart the service
Proceed? (y/N) y
[executes command]
```

### Critical Operation

```bash
# Require typing specific keyword
critical "DELETE" "This will permanently delete all backups" rm -rf ~/backups

# Custom confirmation text
critical "CONFIRM" "This will reset database" mysql -e "DROP DATABASE prod"
```

**Output**:
```
🚨 CRITICAL OPERATION
⚠️  This will permanently delete all backups

Type 'DELETE' to confirm: █
```

## Function Integration Patterns

### Pattern 1: INFO - Educational Notice

For operations that need guidance but aren't dangerous:

```bash
function edit-secrets() {
  # Show informational warning
  warn "Editing Encrypted Secrets" "INFO"
  echo "  • File will be decrypted temporarily"
  echo "  • Changes will be re-encrypted on save"
  echo "  • Make sure SOPS keys are configured correctly"
  echo ""

  sops "$secrets_file"
}
```

### Pattern 2: WARNING - Confirm Before Proceeding

For significant but reversible operations:

```bash
function nix-rebuild-confirm() {
  warn "System Rebuild" "WARNING"
  echo "  • This will rebuild your entire system configuration"
  echo "  • Changes will be applied immediately"
  echo "  • Previous generation available for rollback (nix-rollback)"
  echo ""

  if confirm "Proceed with rebuild?"; then
    sudo darwin-rebuild switch --flake ~/nix-darwin
  else
    echo "❌ Rebuild cancelled"
    return 1
  fi
}
```

### Pattern 3: CRITICAL - Require Keyword

For destructive or irreversible operations:

```bash
function cleanup-aggressive() {
  echo ""
  echo "🚨 AGGRESSIVE CLEANUP"
  echo "⚠️  DESTRUCTIVE OPERATION - Will permanently delete:"
  echo "  • Nix store garbage and old generations"
  echo "  • All tool caches (Ollama models, LLM caches)"
  echo "  • Development artifacts (node_modules, .venv, builds)"
  echo ""
  read -r "confirmation?Type 'DELETE' to confirm: "

  if [[ "$confirmation" != "DELETE" ]]; then
    echo "❌ Operation cancelled (incorrect confirmation)"
    return 1
  fi

  # Proceed with cleanup
}
```

### Pattern 4: Skip Flag Support

For automation while maintaining safety:

```bash
function dangerous-operation() {
  local skip_confirmation=false

  # Parse flags
  for arg in "$@"; do
    case $arg in
      --yes|-y) skip_confirmation=true ;;
      --help|-h)
        echo "Usage: dangerous-operation [OPTIONS]"
        echo "Options:"
        echo "  --yes, -y    Skip confirmation (use with caution)"
        return 0
        ;;
    esac
  done

  # Show warning unless skipped
  if [[ "$skip_confirmation" != "true" ]]; then
    warn "Dangerous Operation" "CRITICAL"
    if ! confirm "Proceed?"; then
      echo "❌ Operation cancelled"
      return 1
    fi
  fi

  # Do dangerous thing
}
```

### Pattern 5: Dry-Run Integration

Encourage safe testing:

```bash
function cleanup-all() {
  local dry_run=false
  local skip_confirmation=false

  # Parse flags
  for arg in "$@"; do
    case $arg in
      --dry-run) dry_run=true ;;
      --yes|-y) skip_confirmation=true ;;
    esac
  done

  # Warning only if not dry-run
  if [[ "$dry_run" != "true" ]] && [[ "$skip_confirmation" != "true" ]]; then
    warn "Cleanup Operation" "WARNING"
    echo "💡 TIP: Run with --dry-run first to preview changes"
    echo ""

    if ! confirm "Proceed?"; then
      echo "❌ Operation cancelled"
      return 1
    fi
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] Would delete X files"
  else
    # Actually delete
  fi
}
```

## Advanced Patterns

### Multi-Step Confirmation

For operations with multiple risky steps:

```bash
function multi-step-operation() {
  warn "Multi-Step Process" "WARNING"

  # Step 1
  if confirm "Delete old backups?"; then
    rm -rf ~/old-backups
  fi

  # Step 2
  if confirm "Update system packages?"; then
    brew upgrade
  fi

  # Step 3 (critical)
  echo ""
  echo "🚨 FINAL STEP: Reset configuration"
  read -r "conf?Type 'RESET' to confirm: "
  if [[ "$conf" == "RESET" ]]; then
    rm ~/.config/*
  fi
}
```

### Conditional Warning Levels

Adjust warning based on context:

```bash
function cleanup-docker() {
  local running_containers=$(docker ps -q | wc -l)

  if [[ $running_containers -gt 0 ]]; then
    # Critical if containers running
    critical "STOP" \
      "This will stop $running_containers running containers" \
      docker stop $(docker ps -q)
  else
    # Just warning if no containers
    warn "Cleaning Docker resources" "WARNING"
    if confirm "Remove unused images?"; then
      docker image prune -a
    fi
  fi
}
```

### Pre-Flight Checks

Validate before proceeding:

```bash
function deploy-to-production() {
  warn "Production Deployment" "CRITICAL"

  # Pre-flight check 1: Git status
  if ! git diff --quiet; then
    warn "Uncommitted changes detected" "WARNING"
    if ! confirm "Deploy anyway?"; then
      return 1
    fi
  fi

  # Pre-flight check 2: Tests passing
  if ! make test; then
    echo "🚨 CRITICAL: Tests failing!"
    critical "DEPLOY" \
      "Tests are failing but you want to deploy anyway" \
      make deploy
  fi

  # Normal confirmation
  if confirm "Deploy to production?"; then
    make deploy
  fi
}
```

## Nix Layer Usage

### Basic Warning Generator

```nix
# In your Nix configuration
let
  warnings = myLib.warnings;

  cleanupFunction = warnings.mkRiskyOperation {
    level = "WARNING";
    message = "Cleanup Operation";
    details = [
      "Will delete caches"
      "Will remove old logs"
    ];
    command = "rm -rf /tmp/cache /var/log/old";
    skipFlag = "--yes";
  };
in
{
  # Use in shell functions...
}
```

### Pre-Flight Check Generator

```nix
let
  preFlightChecks = myLib.warnings.mkPreFlightChecks [
    {
      name = "Git Status";
      check = "git diff --quiet";
      failureMessage = "Uncommitted changes detected";
      level = "WARNING";
      continueOnFailure = true;
    }
    {
      name = "Tests Passing";
      check = "make test";
      failureMessage = "Tests are failing";
      level = "CRITICAL";
      continueOnFailure = false;
    }
  ];
in
{
  # Use in deployment scripts...
}
```

## Testing Your Warnings

### Manual Testing Checklist

```bash
# 1. Test cancellation
your-function
# Press 'n' → should cancel cleanly

# 2. Test confirmation
your-function
# Press 'y' → should proceed

# 3. Test critical with wrong keyword
cleanup-aggressive
# Type 'delete' (lowercase) → should reject

# 4. Test critical with correct keyword
cleanup-aggressive
# Type 'DELETE' → should proceed

# 5. Test skip flag
cleanup-aggressive --yes
# Should skip confirmation entirely

# 6. Test dry-run
cleanup-all --dry-run
# Should preview without confirmation
```

### Validation Questions

Ask yourself:

1. **Risk appropriate?** Does warning level match actual risk?
2. **Clear messaging?** Can user understand without docs?
3. **Easy to cancel?** Is escape clear and simple?
4. **Skip available?** Can automation bypass safely?
5. **Tested thoroughly?** Did you test all paths?

## Common Mistakes

### ❌ Don't Do This

```bash
# Too verbose - users will skip reading
function bad-warning() {
  echo "This operation will perform multiple steps including:"
  echo "1. Backing up your current configuration to /tmp"
  echo "2. Downloading new configuration from remote"
  echo "3. Validating the configuration against schema"
  echo "4. Applying configuration to system"
  echo "5. Restarting affected services"
  echo "6. Running post-deployment checks"
  echo "7. Cleaning up temporary files"
  echo "Do you want to proceed?"
  # Too long, lost attention
}

# Too weak for risky operation
function weak-warning() {
  echo "This might delete stuff"
  if confirm "Ok?"; then
    rm -rf /
  fi
}

# Confirmation too easy to bypass
function easy-bypass() {
  # Single 'y' too easy for production
  confirm "Delete production database?" && drop-database
}
```

### ✅ Do This Instead

```bash
# Concise and clear
function good-warning() {
  warn "Configuration Update" "WARNING"
  echo "  • Backs up current config"
  echo "  • Applies new settings"
  echo "  • Restarts services"
  echo ""
  if confirm "Proceed?"; then
    do-update
  fi
}

# Strong protection for risky operation
function strong-warning() {
  critical "DELETE" \
    "This will permanently delete production data" \
    rm -rf /var/data/production
}

# Appropriate confirmation for level
function right-level() {
  # WARNING for significant but reversible
  warn "Service restart required" "WARNING"
  confirm "Restart now?" && systemctl restart service
}
```

---

**See also**:
- [WARNING-SYSTEM.md](WARNING-SYSTEM.md) - Complete design documentation
- [lib/warnings.nix](warnings.nix) - Implementation
- [home/jimmy/shell/zsh.nix](../home/jimmy/shell/zsh.nix) - Shell integration
