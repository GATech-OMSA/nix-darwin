# Phase 6: Setup.sh UX Enhancements

**Date**: 2025-11-07
**Status**: Design Complete
**Priority**: Critical for Task 6.0 completion

## Overview

Enhancement design for `setup.sh` addressing two critical UX gaps:
1. **Abort/Recovery Safety** - Handle interruptions gracefully without data loss
2. **Smart Defaults** - Auto-detect system values to minimize user input

## Problem Statement

### Current Gaps

**Gap 1: No Safe Abort Mechanism**
- User presses Ctrl+C during migration → potential data loss
- Original secrets deleted before encryption verified
- No way to resume from interruption point
- No clear recovery instructions

**Gap 2: Manual Information Entry**
- Forces user to type username (already in system)
- Requires email input (available in git config)
- No validation of entered values
- Repetitive for most users

## Design Principles

1. **Safety Without Friction** - Fast for common case, safe for all cases
2. **No Data Loss Ever** - Always recoverable, even on hard crash
3. **Informed Decisions** - Explain impact before changes
4. **Resume Capability** - Never repeat completed work

---

## Enhancement 1: Abort/Recovery Safety

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Setup Flow Phases                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Detection & Gathering (Safe - Read Only)                │
│     └─ Can abort freely, no recovery needed                │
│                                                             │
│  2. Create Backup (Point of Safety)                         │
│     └─ All originals copied to timestamped backup dir      │
│                                                             │
│  3. SOPS Key Generation (Recoverable)                       │
│     └─ Key exists, state tracks if backed up               │
│                                                             │
│  4. Secret Migration (Transactional)                        │
│     ├─ Encrypt to secrets.yaml                             │
│     ├─ Verify decryption works                             │
│     ├─ Rename originals to .bak (not delete!)              │
│     └─ State tracks each secret                            │
│                                                             │
│  5. Config Creation (Idempotent)                            │
│     └─ Can regenerate anytime from templates               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### State Persistence

**State File**: `~/.nix-darwin-setup.state`

```ini
# Setup state for resume capability
phase=migrate_secrets
timestamp=1699564321
backup=/Users/jimmy/.nix-darwin-setup-backup-1699564321
secrets_to_migrate=aws,ssh,db,tokens
secrets_migrated=aws,ssh
current_secret=db
sops_key_generated=yes
sops_key_backed_up=yes
machine_id=mbp-jimmy
machine_type=personal
username=jimmy
email=jimmy@example.com
```

**State Updates**:
- Written after each successful operation
- Read on script restart
- Removed only on successful completion or user-initiated cleanup

### Backup Strategy

**Backup Creation** (before any changes):
```bash
create_backup() {
  local timestamp=$(date +%s)
  BACKUP_DIR="$HOME/.nix-darwin-setup-backup-$timestamp"

  msg_info "Creating backup..."
  mkdir -p "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR"

  # Backup all secrets with metadata
  backup_file "~/.aws/credentials" "aws-credentials"
  backup_file "~/.aws/config" "aws-config"
  backup_file "~/.ssh/config" "ssh-config"
  backup_file "~/.db" "db-connections" "dir"
  backup_file "~/.tokens" "tokens" "dir"

  # Create manifest
  cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
Backup created: $(date)
Hostname: $(hostname)
User: $(whoami)
Purpose: nix-darwin setup migration

Files backed up:
$(ls -lh "$BACKUP_DIR")

Restore with: ./setup.sh --restore-backup $BACKUP_DIR
EOF

  # Update state
  echo "backup=$BACKUP_DIR" >> ~/.nix-darwin-setup.state

  msg_success "✅ Backup created: $BACKUP_DIR"
}
```

**Backup Retention**:
- Keep for 30 days minimum
- Auto-cleanup script (cron or launch agent)
- User can keep indefinitely with flag

### Transactional Migration

**Key Principle**: Never delete until encryption verified

```bash
migrate_secret_safe() {
  local secret_type="$1"  # aws, ssh, db, etc.
  local source_path="$2"
  local secrets_yaml="$3"

  msg_info "Migrating $secret_type secrets..."

  # Step 1: Read plaintext
  local content=$(cat "$source_path")

  # Step 2: Encrypt to secrets.yaml
  echo "$content" | sops --set "secrets.$secret_type" "$secrets_yaml"

  # Step 3: Verify decryption works
  local decrypted=$(sops -d "$secrets_yaml" | yq ".secrets.$secret_type")
  if [[ "$decrypted" != "$content" ]]; then
    msg_error "❌ Encryption verification failed for $secret_type!"
    return 1
  fi

  # Step 4: Rename original to .bak (NOT DELETE!)
  local backup_name="${source_path}.bak.migrated-$(date +%s)"
  mv "$source_path" "$backup_name"

  # Step 5: Update state
  add_to_state "secrets_migrated" "$secret_type"

  msg_success "✅ Migrated: $secret_type"
  msg_info "   Original: $backup_name (kept for 30 days)"
}
```

### Signal Handling

**Graceful Interruption**:
```bash
setup_interrupt_handler() {
  trap 'handle_interrupt' INT TERM
}

handle_interrupt() {
  echo ""
  msg_warning "⏸️  Setup interrupted by user"
  echo ""

  # Save current state
  save_state

  msg_success "✅ State saved. Your progress is preserved."
  echo ""
  echo "📦 Backup location: $BACKUP_DIR"
  echo "💾 State file: ~/.nix-darwin-setup.state"
  echo ""
  echo "Recovery options:"
  echo "  1. Resume:  ./setup.sh --resume"
  echo "  2. Restore: ./setup.sh --restore-backup"
  echo "  3. Cleanup: ./setup.sh --cleanup-state"
  echo ""

  exit 130  # Standard SIGINT exit code
}
```

### Resume Flow

**Resume Detection**:
```bash
check_for_resume() {
  if [[ -f ~/.nix-darwin-setup.state ]]; then
    source ~/.nix-darwin-setup.state

    echo "⚠️  Incomplete setup detected from previous run"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase:       $phase"
    echo "Started:     $(date -r $timestamp)"
    echo "Backup:      $backup"
    echo "Completed:   $secrets_migrated"
    echo "Remaining:   $(remaining_secrets)"
    echo ""
    echo "Options:"
    echo "  [r] Resume from where you left off (recommended)"
    echo "  [s] Start fresh (restores from backup)"
    echo "  [a] Abort (keeps current state)"
    echo ""
    read -p "Choice [r/s/a]: " choice

    case "$choice" in
      r|R) resume_from_state ;;
      s|S) restore_and_restart ;;
      a|A) exit 0 ;;
      *) check_for_resume ;;  # Re-prompt
    esac
  fi
}
```

### Restore Mechanism

**Restore Command**: `./setup.sh --restore-backup [dir]`

```bash
restore_from_backup() {
  local backup_dir="${1:-$(find_latest_backup)}"

  if [[ ! -d "$backup_dir" ]]; then
    msg_error "Backup not found: $backup_dir"
    exit 1
  fi

  echo "📦 Restore from backup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Backup: $backup_dir"
  echo "Created: $(stat -f %Sm "$backup_dir")"
  echo ""
  echo "Files to restore:"
  ls -lh "$backup_dir" | grep -v "^total" | awk '{print "  " $9 " (" $5 ")"}'
  echo ""
  read -p "Restore? This will overwrite current files [yes/no]: " confirm

  if [[ "$confirm" != "yes" ]]; then
    msg_info "Restore cancelled"
    exit 0
  fi

  # Restore each file
  while IFS= read -r file; do
    restore_single_file "$file"
  done < <(find "$backup_dir" -type f -not -name "MANIFEST.txt")

  # Cleanup state
  rm -f ~/.nix-darwin-setup.state

  msg_success "✅ Restore complete!"
  echo ""
  echo "Original state recovered. You can now:"
  echo "  • Run setup again: ./setup.sh"
  echo "  • Keep backup: Saved in $backup_dir"
}
```

### Warning Checkpoints

**Warning 1: Before SOPS Key Generation**
```
⚠️  SOPS KEY GENERATION CHECKPOINT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
We're about to generate your encryption key.

🔐 CRITICAL: This key is the ONLY way to decrypt your secrets!

After generation, you MUST save it by:
  1. Writing it on paper (recommended)
  2. Storing in password manager
  3. Keeping multiple backups

⚡ Without this key, your secrets are UNRECOVERABLE!

Do NOT proceed until you're ready for this responsibility.

Continue? (type 'yes' to confirm):
```

**Warning 2: Before Secret Migration**
```
⚠️  SECRET MIGRATION CHECKPOINT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

About to migrate your secrets to encrypted storage.

✅ Safety measures in place:
  • Full backup: ~/.nix-darwin-setup-backup-1699564321
  • Originals renamed to .bak (NOT deleted)
  • Can restore anytime: ./setup.sh --restore-backup
  • Can resume if interrupted: ./setup.sh --resume

⏸️  Safe to interrupt (Ctrl+C) at any time
  • Progress saved automatically
  • Backup remains intact
  • No data loss

Secrets to migrate:
  • AWS credentials (~/.aws/credentials)
  • SSH config (~/.ssh/config)
  • Database connections (~/.db/)
  • API tokens (~/.tokens/)

Estimated time: 1-2 minutes

Continue? (yes/no):
```

**Warning 3: Before .bak Cleanup (30 days later)**
```
⚠️  BACKUP CLEANUP CHECKPOINT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Original files have been preserved as .bak for 30 days.

Migration date: 2024-11-06
Current date:   2024-12-06
Retention:      Expired today

Files to remove:
  • ~/.aws/credentials.bak.migrated-1699564321 (650 bytes)
  • ~/.ssh/config.bak.migrated-1699564321 (1.2K)
  • ~/.db/*.bak.migrated-1699564321 (multiple files)

⚠️  This is your LAST CHANCE to verify encrypted secrets work!

Options:
  [d] Delete backups (cannot undo)
  [k] Keep for another 30 days
  [c] Cancel cleanup

Choice [d/k/c]:
```

---

## Enhancement 2: Smart Defaults

### Auto-Detection Strategy

**Information Sources**:
```bash
# System sources
DETECTED_USER=$(whoami)
DETECTED_HOSTNAME=$(hostname -s)
DETECTED_ARCH=$(uname -m)

# Git configuration
DETECTED_EMAIL=$(git config --global user.email 2>/dev/null)
DETECTED_NAME=$(git config --global user.name 2>/dev/null)

# Shell environment
DETECTED_SHELL=$SHELL
DETECTED_HOME=$HOME
```

### Smart Gathering Flow

```bash
gather_user_info_smart() {
  msg_section "System Information"

  # Auto-detect
  detect_system_values

  # Display detected values
  echo "📋 Detected from your system:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-15s %s %s\n" "Username:" "$DETECTED_USER" "$(check_mark)"
  printf "%-15s %s %s\n" "Email:" "$DETECTED_EMAIL" "$(check_mark_or_warn "$DETECTED_EMAIL")"
  printf "%-15s %s %s\n" "Full name:" "$DETECTED_NAME" "$(check_mark_or_warn "$DETECTED_NAME")"
  printf "%-15s %s %s\n" "Hostname:" "$DETECTED_HOSTNAME" "$(check_mark)"
  echo ""

  # Validation warnings
  local needs_input=false
  if [[ -z "$DETECTED_EMAIL" ]]; then
    msg_warning "⚠️  No git email configured - will prompt"
    needs_input=true
  fi
  if [[ -z "$DETECTED_NAME" ]]; then
    msg_warning "⚠️  No git name configured - will prompt"
    needs_input=true
  fi
  echo ""

  # Keep or customize
  echo "Options:"
  echo "  [k] Keep detected values (fastest)"
  echo "  [c] Customize specific values"
  echo ""
  read -p "Choice [k/c]: " choice

  case "$choice" in
    k|K)
      accept_defaults
      prompt_missing_only
      ;;
    c|C)
      customize_values_interactive
      ;;
    *)
      gather_user_info_smart  # Re-prompt
      ;;
  esac

  # Show final configuration
  show_config_summary
}

check_mark_or_warn() {
  [[ -n "$1" ]] && echo "✓" || echo "⚠️"
}
```

### Selective Customization

```bash
customize_values_interactive() {
  msg_info "Customize values (press Enter to keep detected)"
  echo ""

  # Username
  customize_field "Username" "$DETECTED_USER" "USERNAME" show_username_impact

  # Email
  customize_field "Email" "$DETECTED_EMAIL" "EMAIL" show_email_impact

  # Full name
  customize_field "Full name" "$DETECTED_NAME" "FULL_NAME"

  # Machine type (always ask)
  select_machine_type
}

customize_field() {
  local label="$1"
  local current="$2"
  local var_name="$3"
  local impact_fn="${4:-}"

  echo "$label: $current"
  read -p "Change? [y/N]: " change

  if [[ "$change" =~ ^[Yy]$ ]]; then
    read -p "New $label: " new_value

    # Show impact if function provided
    if [[ -n "$impact_fn" && -n "$current" ]]; then
      $impact_fn "$current" "$new_value"
      read -p "Confirm change? [y/N]: " confirm
      [[ ! "$confirm" =~ ^[Yy]$ ]] && new_value="$current"
    fi

    eval "$var_name=\"$new_value\""
  else
    eval "$var_name=\"$current\""
  fi
  echo ""
}
```

### Impact Explanations

**Username Impact**:
```bash
show_username_impact() {
  local from="$1"
  local to="$2"

  cat <<EOF

⚠️  Impact of username change: '$from' → '$to'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This will affect:
  • User-data directory: user-data-$to/
  • Home directory references: /Users/$to
  • Nix configuration paths
  • Git commits (if using username for git)

✅ Safe to change - all references will be updated
⚠️  Note: System files in /Users/$from won't move automatically

EOF
}
```

**Email Impact**:
```bash
show_email_impact() {
  local from="$1"
  local to="$2"

  cat <<EOF

📧 Email change: '$from' → '$to'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This email will be used for:
  • Git commits (git config user.email)
  • Work profile configuration (if work machine)
  • User identification in config files

✅ Recommended: Use your primary Git email
💡 Tip: Check with 'git config --global user.email'

EOF
}
```

### Configuration Summary

```bash
show_config_summary() {
  msg_section "Configuration Summary"

  cat <<EOF
┌─────────────────────────────────────────────────────┐
│                 User Configuration                  │
├─────────────────────────────────────────────────────┤
│ Username:     $USERNAME                             │
│ Email:        $EMAIL                                │
│ Full name:    $FULL_NAME                            │
│ Machine:      $MACHINE_ID ($MACHINE_TYPE)           │
│ Hostname:     $DETECTED_HOSTNAME                    │
└─────────────────────────────────────────────────────┘

EOF

  read -p "Looks good? [Y/n]: " confirm
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    gather_user_info_smart  # Start over
  fi
}
```

---

## Implementation Plan

### Phase 1: Safety Infrastructure (2-3 hours)

**Tasks**:
1. Add state file management functions
2. Implement backup creation with manifest
3. Add signal handlers (INT, TERM)
4. Create restore functionality
5. Add resume detection

**Files to modify**:
- `setup.sh` (add functions)

**Testing**:
- Test Ctrl+C at each phase
- Verify state file correctness
- Test resume from each interruption point
- Verify backup/restore works

### Phase 2: Smart Defaults (1-2 hours)

**Tasks**:
1. Add auto-detection functions
2. Implement smart gathering flow
3. Add selective customization
4. Create impact explanation functions
5. Add configuration summary

**Files to modify**:
- `setup.sh` (replace gather_user_info)

**Testing**:
- Test with git config present
- Test with git config missing
- Test customize workflow
- Verify impact explanations shown

### Phase 3: Warning Checkpoints (1 hour)

**Tasks**:
1. Add warning before SOPS key generation
2. Add warning before secret migration
3. Update existing confirmation prompts
4. Add .bak cleanup warning (future cron job)

**Files to modify**:
- `setup.sh` (add warnings)

**Testing**:
- Verify warnings display correctly
- Test confirmation flows
- Ensure blocking works

### Phase 4: Integration & Testing (1 hour)

**Tasks**:
1. End-to-end testing all flows
2. Test abort/resume scenarios
3. Test restore functionality
4. Documentation updates

**Testing Scenarios**:
- ✅ Fresh setup with defaults
- ✅ Fresh setup with customization
- ✅ Abort during key generation → resume
- ✅ Abort during migration → resume
- ✅ Abort during migration → restore
- ✅ Multiple abort/resume cycles
- ✅ Restore from backup
- ✅ Missing git config handling

---

## Success Criteria

### Safety Requirements
- ✅ No data loss at any interruption point
- ✅ User can restore to original state anytime
- ✅ State tracking enables resume from any phase
- ✅ Clear recovery instructions on interrupt

### UX Requirements
- ✅ Fast path: 1-2 keypresses for defaults
- ✅ Custom path: Selective changes only
- ✅ Impact explained before changes
- ✅ No surprises or unexpected behavior

### Quality Requirements
- ✅ All scenarios tested
- ✅ Error messages helpful
- ✅ Documentation updated
- ✅ Code reviewed

---

## Future Enhancements

### Automatic Backup Cleanup
```bash
# Launch agent for periodic cleanup
# ~/Library/LaunchAgents/com.user.nix-darwin-cleanup.plist
# Runs weekly, removes backups > 30 days old
```

### Recovery Testing Script
```bash
# ./scripts/test-setup-recovery.sh
# Automated testing of all abort scenarios
# Ensures recovery always works
```

### Migration Verification
```bash
# After migration completes
# Verify all secrets accessible
# Compare with backup to ensure completeness
```

---

## Notes

### Design Decisions

**Why rename to .bak instead of delete?**
- Provides 30-day safety net
- Users can verify encrypted version works
- Accidental encryption failures recoverable
- Disk space minimal impact

**Why timestamped backups?**
- Multiple setup attempts don't conflict
- Can keep multiple backups if needed
- Clear chronological ordering
- Easy to identify latest

**Why state file instead of database?**
- Simple, portable, human-readable
- Easy to debug and inspect
- No dependencies
- Sufficient for use case

**Why not automatic restore on failure?**
- User should decide (informed consent)
- Might want to inspect state first
- Explicit > implicit for safety

---

## References

- Original design: [PHASE-6-SOPS-FIRST-FLOW.md](./PHASE-6-SOPS-FIRST-FLOW.md)
- Execution plan: [PHASE-6-EXECUTION-PLAN.md](./PHASE-6-EXECUTION-PLAN.md)
- Current setup.sh: `/Users/jimmy/nix-darwin/setup.sh`
