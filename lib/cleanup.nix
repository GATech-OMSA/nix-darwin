# Cleanup Helper Functions Library
# Provides reusable utilities for building consistent, safe cleanup functions

{ lib, pkgs, ... }:

let
  # ANSI color codes for output
  colors = {
    reset = "\\033[0m";
    bold = "\\033[1m";
    red = "\\033[31m";
    green = "\\033[32m";
    yellow = "\\033[33m";
    blue = "\\033[34m";
    magenta = "\\033[35m";
    cyan = "\\033[36m";
  };

  # Status indicators
  indicators = {
    success = "✅";
    error = "❌";
    warning = "⚠️ ";
    info = "ℹ️ ";
    cleanup = "🗑️ ";
    rocket = "🚀";
    check = "✓";
    cross = "✗";
  };

in
{
  # Generate disk space report (before/after comparison)
  mkDiskSpaceReport = { path ? "$HOME"; }: ''
    # Get disk space usage
    __cleanup_get_disk_space() {
      df -h "${path}" | awk 'NR==2 {print $3}'
    }

    # Report disk space saved
    __cleanup_report_space() {
      local before="$1"
      local after="$2"

      # Convert to bytes for calculation (simplified)
      echo -e "${colors.cyan}${indicators.info}Disk Space Report:${colors.reset}"
      echo "  Before: $before"
      echo "  After:  $after"

      # TODO: Calculate actual difference - requires more complex parsing
      # For now, just show before/after
    }
  '';

  # Log cleanup operations to history file
  mkCleanupLog = { logFile ? "$HOME/.cleanup-history"; }: ''
    # Initialize cleanup log
    __cleanup_log_init() {
      local tier="$1"
      local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

      mkdir -p "$(dirname ${logFile})"

      # Start log entry
      echo "" >> ${logFile}
      echo "[''${timestamp}] cleanup-''${tier}" >> ${logFile}

      # Store start time for duration calculation
      export __CLEANUP_START_TIME=$(date +%s)
    }

    # Log cleanup operation
    __cleanup_log_operation() {
      local category="$1"
      local status="$2"
      local details="$3"

      echo "  [''${category}] ''${status}''${details:+: $details}" >> ${logFile}
    }

    # Finalize cleanup log
    __cleanup_log_finalize() {
      local disk_before="$1"
      local disk_after="$2"
      local ops_success="$3"
      local ops_total="$4"

      local end_time=$(date +%s)
      local duration=$((end_time - __CLEANUP_START_TIME))
      local minutes=$((duration / 60))
      local seconds=$((duration % 60))

      echo "  Duration: ''${minutes}m ''${seconds}s" >> ${logFile}
      echo "  Operations: ''${ops_success}/''${ops_total} successful" >> ${logFile}
      echo "  Disk: ''${disk_before} → ''${disk_after}" >> ${logFile}

      # Rotate log (keep last 30 days)
      __cleanup_log_rotate
    }

    # Rotate cleanup history log
    __cleanup_log_rotate() {
      if [[ -f ${logFile} ]]; then
        local lines=$(wc -l < ${logFile})
        if [[ $lines -gt 1000 ]]; then
          tail -500 ${logFile} > ${logFile}.tmp
          mv ${logFile}.tmp ${logFile}
        fi
      fi
    }
  '';

  # Safety check with interactive confirmation
  mkSafetyCheck = {
    operation:
    description ? ""
    riskLevel ? "medium"  # low, medium, high
  }: ''
    # Interactive safety check
    __cleanup_confirm_''${operation}() {
      local dry_run=''${1:-false}
      local yes_flag=''${2:-false}

      # Skip confirmation if --yes flag
      if [[ "$yes_flag" == "true" ]]; then
        return 0
      fi

      # Show warning based on risk level
      ${if riskLevel == "high" then ''
        echo -e "${colors.red}${indicators.warning}HIGH RISK OPERATION${colors.reset}"
      '' else if riskLevel == "medium" then ''
        echo -e "${colors.yellow}${indicators.warning}Medium Risk Operation${colors.reset}"
      '' else ''
        echo -e "${colors.blue}${indicators.info}${colors.reset}"
      ''}

      ${if description != "" then ''
        echo -e "${colors.bold}${description}${colors.reset}"
      '' else ""}

      echo ""

      if [[ "$dry_run" == "true" ]]; then
        echo -e "${colors.cyan}[DRY RUN] Would execute: ${operation}${colors.reset}"
        return 0
      fi

      read -p "Continue with ${operation}? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${colors.yellow}Skipped: ${operation}${colors.reset}"
        return 1
      fi
      return 0
    }
  '';

  # Selective cleanup based on age
  mkSelectiveCleanup = {
    path
    pattern
    days
    description ? "old files"
  }: ''
    # Find and clean files older than ${toString days} days
    __cleanup_selective_''${lib.replaceStrings ["/"] ["_"] path}() {
      local dry_run=''${1:-false}
      local found_files=$(find "${path}" -type f -name "${pattern}" -mtime +${toString days} 2>/dev/null | wc -l | tr -d ' ')

      if [[ $found_files -eq 0 ]]; then
        echo -e "  ${indicators.info}No ${description} found (older than ${toString days} days)"
        return 0
      fi

      echo -e "  ${indicators.cleanup}Found $found_files ${description}"

      if [[ "$dry_run" == "true" ]]; then
        echo -e "${colors.cyan}  [DRY RUN] Would delete:${colors.reset}"
        find "${path}" -type f -name "${pattern}" -mtime +${toString days} 2>/dev/null | head -5
        if [[ $found_files -gt 5 ]]; then
          echo "  ... and $((found_files - 5)) more"
        fi
        return 0
      fi

      find "${path}" -type f -name "${pattern}" -mtime +${toString days} -delete 2>/dev/null
      echo -e "  ${indicators.success}Removed $found_files ${description}"
    }
  '';

  # Cleanup group - category header and operations
  mkCleanupGroup = {
    category
    icon ? indicators.cleanup
    operations
  }: ''
    # ${category} cleanup group
    __cleanup_group_''${lib.replaceStrings [" " "-"] ["_" "_"] category}() {
      local dry_run=''${1:-false}
      local yes_flag=''${2:-false}
      local success_count=0
      local total_count=0

      echo ""
      echo -e "${colors.bold}${colors.magenta}${icon} ${category}${colors.reset}"
      echo -e "${colors.magenta}${"=" * 50}${colors.reset}"

      ${lib.concatMapStrings (op: ''
        total_count=$((total_count + 1))
        if ${op} "$dry_run" "$yes_flag"; then
          success_count=$((success_count + 1))
        fi
      '') operations}

      echo -e "${colors.blue}  ${category}: $success_count/$total_count operations completed${colors.reset}"

      return 0
    }
  '';

  # Main cleanup function generator
  mkCleanupFunction = {
    name
    tier  # safe, quick, standard, dev, aggressive
    description
    groups  # List of cleanup groups to execute
  }: ''
    # ${description}
    # Tier: ${tier}
    ${name}() {
      local dry_run=false
      local yes_flag=false
      local verbose=false
      local quiet=false

      # Parse flags
      while [[ $# -gt 0 ]]; do
        case $1 in
          --dry-run)
            dry_run=true
            shift
            ;;
          --yes|-y)
            yes_flag=true
            shift
            ;;
          --verbose|-v)
            verbose=true
            shift
            ;;
          --quiet|-q)
            quiet=true
            shift
            ;;
          --help|-h)
            echo "Usage: ${name} [OPTIONS]"
            echo ""
            echo "${description}"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview operations without executing"
            echo "  --yes, -y    Skip all confirmation prompts"
            echo "  --verbose, -v Show detailed output"
            echo "  --quiet, -q   Minimal output"
            echo "  --help, -h    Show this help message"
            return 0
            ;;
          *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            return 1
            ;;
        esac
      done

      # Header
      if [[ "$quiet" != "true" ]]; then
        echo ""
        echo -e "${colors.bold}${colors.cyan}${indicators.rocket} ${description}${colors.reset}"
        echo -e "${colors.cyan}${"=" * 60}${colors.reset}"

        if [[ "$dry_run" == "true" ]]; then
          echo -e "${colors.yellow}${indicators.info}DRY RUN MODE - No changes will be made${colors.reset}"
        fi

        echo ""
      fi

      # Initialize logging
      __cleanup_log_init "${tier}"

      # Capture disk space before
      local disk_before=$(__cleanup_get_disk_space)
      local start_time=$(date +%s)

      # Execute cleanup groups
      local total_success=0
      local total_ops=0

      ${lib.concatMapStrings (group: ''
        if __cleanup_group_${lib.replaceStrings [" " "-"] ["_" "_"] group.category} "$dry_run" "$yes_flag"; then
          total_success=$((total_success + 1))
        fi
        total_ops=$((total_ops + 1))
      '') groups}

      # Capture disk space after
      local disk_after=$(__cleanup_get_disk_space)
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))
      local minutes=$((duration / 60))
      local seconds=$((duration % 60))

      # Final report
      if [[ "$quiet" != "true" ]]; then
        echo ""
        echo -e "${colors.bold}${colors.green}${indicators.success} Cleanup Complete!${colors.reset}"
        echo -e "${colors.green}${"=" * 60}${colors.reset}"
        __cleanup_report_space "$disk_before" "$disk_after"
        echo -e "${colors.cyan}${indicators.info}Duration: ''${minutes}m ''${seconds}s${colors.reset}"
        echo -e "${colors.cyan}${indicators.info}Groups completed: $total_success/$total_ops${colors.reset}"

        if [[ "$dry_run" == "true" ]]; then
          echo ""
          echo -e "${colors.yellow}${indicators.info}This was a DRY RUN - no changes were made${colors.reset}"
          echo -e "${colors.yellow}${indicators.info}Run without --dry-run to execute cleanup${colors.reset}"
        fi

        echo ""
      fi

      # Finalize logging
      __cleanup_log_finalize "$disk_before" "$disk_after" "$total_success" "$total_ops"
    }
  '';

  # Command check helper
  cmdCheck = cmd: ''
    command -v ${cmd} &> /dev/null
  '';

  # Safe command execution with error handling
  safeExec = {
    command
    description
    continueOnError ? true
  }: ''
    # Execute: ${description}
    __cleanup_exec_${lib.replaceStrings [" " "-" "/"] ["_" "_" "_"] command}() {
      local dry_run=''${1:-false}

      if [[ "$dry_run" == "true" ]]; then
        echo -e "${colors.cyan}  [DRY RUN] ${description}: ${command}${colors.reset}"
        return 0
      fi

      if ${command} &> /dev/null; then
        echo -e "  ${indicators.success}${description}"
        __cleanup_log_operation "${description}" "SUCCESS"
        return 0
      else
        echo -e "  ${indicators.error}${description} failed"
        __cleanup_log_operation "${description}" "FAILED"
        ${if continueOnError then "return 0" else "return 1"}
      fi
    }
  '';
}
