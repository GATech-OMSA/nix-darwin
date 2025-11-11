#!/usr/bin/env bash
# Security audit script for credential file permissions
# Validates that all registered secret paths have secure 600 permissions

set -o pipefail

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# CONFIGURATION
# ============================================================================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX_MODE=0
VERBOSE=0
SHOW_SECURE=0

# Statistics
TOTAL_FILES=0
SECURE_FILES=0
INSECURE_FILES=0
MISSING_FILES=0
FIXED_FILES=0

# Arrays for reporting
declare -a INSECURE_PATHS
declare -a MISSING_PATHS

# ============================================================================
# ARGUMENT PARSING
# ============================================================================
usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Security audit for credential file permissions.
Validates all files in lib/secrets-registry.nix have 600 permissions.

OPTIONS:
  -f, --fix          Automatically fix insecure permissions to 600
  -v, --verbose      Show detailed output for all files
  -s, --show-secure  Show secure files (normally hidden)
  -h, --help         Show this help message

EXAMPLES:
  $0                 # Audit only (no changes)
  $0 --fix           # Audit and fix insecure permissions
  $0 --verbose       # Show all files checked
  $0 -f -v           # Fix with detailed output

EXIT CODES:
  0 - All files secure or successfully fixed
  1 - Insecure files found (audit mode) or fix failed
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--fix)
      FIX_MODE=1
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -s|--show-secure)
      SHOW_SECURE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
print_header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$1${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_category() {
  echo ""
  echo -e "${BOLD}${BLUE}▶ $1${NC}"
  echo ""
}

check_secure() {
  ((SECURE_FILES++))
  if [[ $SHOW_SECURE -eq 1 ]] || [[ $VERBOSE -eq 1 ]]; then
    echo -e "  ${GREEN}✓${NC} $1 ${CYAN}(600)${NC}"
  fi
}

check_insecure() {
  ((INSECURE_FILES++))
  INSECURE_PATHS+=("$1:$2")
  echo -e "  ${RED}✗${NC} $1 ${RED}($2)${NC}"
}

check_missing() {
  ((MISSING_FILES++))
  MISSING_PATHS+=("$1")
  if [[ $VERBOSE -eq 1 ]]; then
    echo -e "  ${YELLOW}○${NC} $1 ${YELLOW}(missing)${NC}"
  fi
}

check_fixed() {
  ((FIXED_FILES++))
  echo -e "  ${GREEN}✓${NC} Fixed: $1 ${CYAN}(600 → 600)${NC}"
}

# ============================================================================
# PERMISSION CHECK FUNCTIONS
# ============================================================================

# Expand ${HOME} in path
expand_path() {
  local path="$1"
  echo "${path//\$\{HOME\}/$HOME}"
}

# Check single file permission
check_file_permission() {
  local file="$1"
  local expanded_file=$(expand_path "$file")

  ((TOTAL_FILES++))

  # Check if file exists
  if [[ ! -e "$expanded_file" ]]; then
    check_missing "$file"
    return
  fi

  # Get file permissions (3 digits only)
  local perms=$(stat -f "%A" "$expanded_file" 2>/dev/null || echo "000")

  # Check if permissions are secure (600)
  if [[ "$perms" == "600" ]]; then
    check_secure "$file"
  else
    check_insecure "$file" "$perms"

    # Fix if in fix mode
    if [[ $FIX_MODE -eq 1 ]]; then
      if chmod 600 "$expanded_file" 2>/dev/null; then
        check_fixed "$file"
        ((INSECURE_FILES--))
        ((SECURE_FILES++))
      else
        echo -e "    ${RED}→ Failed to fix permissions${NC}"
      fi
    fi
  fi
}

# Check AWS files
check_aws_files() {
  print_category "AWS CREDENTIALS"

  local aws_files=(
    "${HOME}/.aws/credentials"
    "${HOME}/.aws/config"
    "${HOME}/.aws/accounts.json"
    "${HOME}/.aws/.last_profile"
  )

  for file in "${aws_files[@]}"; do
    check_file_permission "$file"
  done
}

# Check database connection files
check_database_files() {
  print_category "DATABASE CONNECTIONS"

  # Oracle
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/oracle/$env"
  done

  # MSSQL
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/mssql/$env"
  done

  # PostgreSQL
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/postgres/$env"
  done

  # Oracle PS
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/oracle-ps/$env"
  done

  # ODS
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/ods/$env"
  done

  # DW
  for env in prod dev qa test; do
    check_file_permission "${HOME}/.db/dw/$env"
  done
}

# Check SSH keys
check_ssh_files() {
  print_category "SSH KEYS"

  local ssh_files=(
    "${HOME}/.ssh/id_ed25519"
    "${HOME}/.ssh/id_ed25519.pub"
    "${HOME}/.ssh/id_ed25519_work"
    "${HOME}/.ssh/id_ed25519_work.pub"
    "${HOME}/.ssh/known_hosts"
  )

  for file in "${ssh_files[@]}"; do
    check_file_permission "$file"
  done
}

# Check API tokens
check_token_files() {
  print_category "API TOKENS"

  local token_files=(
    "${HOME}/.tokens/git_token"
    "${HOME}/.tokens/hcp_terraform_token"
    "${HOME}/.tokens/jira_api_token"
    "${HOME}/.tokens/confluence_token"
  )

  for file in "${token_files[@]}"; do
    check_file_permission "$file"
  done
}

# Check service credentials
check_credential_files() {
  print_category "SERVICE CREDENTIALS"

  local cred_files=(
    "${HOME}/.credentials/servicenow"
    "${HOME}/.credentials/vpn"
  )

  for file in "${cred_files[@]}"; do
    check_file_permission "$file"
  done
}

# Check general secrets
check_general_secrets() {
  print_category "GENERAL SECRETS"

  local secret_files=(
    "${HOME}/.secrets/credentials.env"
    "${HOME}/.secrets/credentials.env.enc"
  )

  for file in "${secret_files[@]}"; do
    check_file_permission "$file"
  done
}

# Check SOPS age key
check_sops_key() {
  print_category "SOPS ENCRYPTION KEY"

  check_file_permission "${HOME}/.config/sops/age/keys.txt"
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

generate_summary_report() {
  print_header "📊 SECURITY AUDIT SUMMARY"
  echo ""

  # File statistics
  echo -e "${BOLD}Files Checked:${NC}    $TOTAL_FILES"
  echo -e "${GREEN}✓ Secure (600):${NC}   $SECURE_FILES"
  echo -e "${RED}✗ Insecure:${NC}       $INSECURE_FILES"
  echo -e "${YELLOW}○ Missing:${NC}        $MISSING_FILES"

  if [[ $FIX_MODE -eq 1 ]] && [[ $FIXED_FILES -gt 0 ]]; then
    echo -e "${CYAN}🔧 Fixed:${NC}          $FIXED_FILES"
  fi

  echo ""

  # Security score
  local secure_percent=0
  local existing_files=$((TOTAL_FILES - MISSING_FILES))
  if [[ $existing_files -gt 0 ]]; then
    secure_percent=$(( (SECURE_FILES * 100) / existing_files ))
  fi

  local status_emoji="🟢"
  local status_text="SECURE"
  local status_color="$GREEN"

  if [[ $INSECURE_FILES -gt 5 ]]; then
    status_emoji="🔴"
    status_text="CRITICAL"
    status_color="$RED"
  elif [[ $INSECURE_FILES -gt 0 ]]; then
    status_emoji="🟡"
    status_text="NEEDS ATTENTION"
    status_color="$YELLOW"
  fi

  echo -e "${BOLD}Security Score:${NC}  ${status_color}${secure_percent}%${NC} ($SECURE_FILES/$existing_files secure)"
  echo -e "${BOLD}Status:${NC}          ${status_emoji} ${status_color}${status_text}${NC}"
  echo ""
}

generate_fix_recommendations() {
  if [[ $INSECURE_FILES -eq 0 ]]; then
    return
  fi

  print_header "🔧 FIX RECOMMENDATIONS"
  echo ""

  if [[ $FIX_MODE -eq 1 ]]; then
    if [[ $FIXED_FILES -gt 0 ]]; then
      echo -e "${GREEN}✓${NC} Successfully fixed $FIXED_FILES file(s)"
    fi
    if [[ $INSECURE_FILES -gt 0 ]]; then
      echo -e "${RED}✗${NC} Failed to fix $INSECURE_FILES file(s)"
      echo ""
      echo -e "${BOLD}Manual fix required:${NC}"
      echo ""
    fi
  else
    echo -e "${BOLD}Insecure files detected. Fix with:${NC}"
    echo ""
    echo -e "  ${CYAN}# Fix all permissions automatically${NC}"
    echo -e "  $0 --fix"
    echo ""
    echo -e "  ${CYAN}# Or fix manually:${NC}"
  fi

  # Show commands for insecure files
  for entry in "${INSECURE_PATHS[@]}"; do
    local file="${entry%%:*}"
    local perms="${entry#*:}"
    local expanded_file=$(expand_path "$file")
    echo -e "  chmod 600 ${expanded_file}  ${YELLOW}# Current: $perms${NC}"
  done

  echo ""
}

generate_missing_file_report() {
  if [[ $MISSING_FILES -eq 0 ]] || [[ $VERBOSE -eq 0 ]]; then
    return
  fi

  print_header "📋 MISSING FILES (Optional)"
  echo ""
  echo -e "${YELLOW}These files are registered but don't exist yet:${NC}"
  echo ""

  for file in "${MISSING_PATHS[@]}"; do
    echo -e "  ${YELLOW}○${NC} $file"
  done

  echo ""
  echo -e "${CYAN}Note:${NC} Missing files are not a security issue."
  echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
  if [[ $FIX_MODE -eq 1 ]]; then
    print_header "🔒 SECURITY PERMISSION AUDIT & FIX"
  else
    print_header "🔒 SECURITY PERMISSION AUDIT"
  fi

  echo ""
  echo -e "${CYAN}Checking all files in lib/secrets-registry.nix${NC}"
  echo -e "${CYAN}Required permissions: 600 (owner read/write only)${NC}"

  # Run all permission checks
  check_aws_files
  check_database_files
  check_ssh_files
  check_token_files
  check_credential_files
  check_general_secrets
  check_sops_key

  # Generate reports
  generate_summary_report
  generate_fix_recommendations
  generate_missing_file_report

  # Exit with appropriate code
  if [[ $INSECURE_FILES -gt 0 ]]; then
    if [[ $FIX_MODE -eq 1 ]]; then
      echo -e "${RED}Some files could not be fixed automatically.${NC}"
      echo -e "${YELLOW}Review the fix recommendations above.${NC}"
      echo ""
    fi
    exit 1
  else
    echo -e "${GREEN}✓ All existing credential files have secure permissions!${NC}"
    echo ""
    exit 0
  fi
}

# Run main function
main
