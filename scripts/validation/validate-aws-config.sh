#!/usr/bin/env bash
# ==================================================
# AWS Configuration Validation Script
# ==================================================
# Validates AWS CLI installation, configuration files,
# profiles, permissions, and machine-specific setup.
#
# Usage: ./scripts/validate-aws-config.sh [--verbose]
# ==================================================

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verbose mode
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

# Status counters
PASSED=0
FAILED=0
WARNINGS=0

# ==================================================
# Helper Functions
# ==================================================

log_header() {
    echo -e "\n${BLUE}==================================================\033[0m"
    echo -e "${BLUE}$1\033[0m"
    echo -e "${BLUE}==================================================\033[0m"
}

log_section() {
    echo -e "\n${BLUE}[$1]\033[0m"
}

log_pass() {
    echo -e "${GREEN}PASS:${NC} $1"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}error: fAIL:${NC} $1"
    FAILED=$((FAILED + 1))
}

log_warn() {
    echo -e "${YELLOW}warning: wARN:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

log_info() {
    echo -e "   $1"
}

check_exists() {
    local item="$1"
    local type="${2:-file}"

    if [[ "$type" == "file" ]] && [[ -f "$item" ]]; then
        return 0
    elif [[ "$type" == "dir" ]] && [[ -d "$item" ]]; then
        return 0
    elif [[ "$type" == "command" ]] && command -v "$item" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_permissions() {
    local file="$1"
    local expected="$2"

    if [[ ! -e "$file" ]]; then
        return 1
    fi

    # Follow symlinks to check actual file permissions
    local target="$file"
    if [[ -L "$file" ]]; then
        target=$(readlink "$file")
    fi

    local perms
    perms=$(stat -f "%Lp" "$target" 2>/dev/null || stat -c "%a" "$target" 2>/dev/null)

    if [[ "$perms" == "$expected" ]]; then
        return 0
    else
        return 1
    fi
}

# ==================================================
# Validation Checks
# ==================================================

validate_aws_cli() {
    log_section "AWS CLI Installation"

    if check_exists "aws" "command"; then
        local version
        version=$(aws --version 2>&1 | head -1)
        log_pass "AWS CLI installed: $version"

        # Check if version is modern (2.x)
        if echo "$version" | grep -q "aws-cli/2"; then
            log_pass "AWS CLI version 2.x detected (recommended)"
        else
            log_warn "AWS CLI version 1.x detected (consider upgrading to 2.x)"
        fi
    else
        log_fail "AWS CLI not installed"
        log_info "Install with: brew install awscli"
        return 1
    fi
}

validate_aws_directory() {
    log_section "AWS Directory Structure"

    if check_exists "$HOME/.aws" "dir"; then
        log_pass "AWS directory exists: ~/.aws"
    else
        log_fail "AWS directory missing: ~/.aws"
        log_info "Create with: mkdir -p ~/.aws && chmod 700 ~/.aws"
        return 1
    fi

    # Check directory permissions
    local dir_perms
    dir_perms=$(stat -f "%Lp" "$HOME/.aws" 2>/dev/null || stat -c "%a" "$HOME/.aws" 2>/dev/null)
    if [[ "$dir_perms" == "700" ]]; then
        log_pass "AWS directory has correct permissions (700)"
    else
        log_warn "AWS directory permissions are $dir_perms (recommended: 700)"
        log_info "Fix with: chmod 700 ~/.aws"
    fi
}

validate_aws_config() {
    log_section "AWS Configuration File"

    if check_exists "$HOME/.aws/config" "file"; then
        log_pass "AWS config exists: ~/.aws/config"

        # Check if it's a symlink (Nix-managed)
        if [[ -L "$HOME/.aws/config" ]]; then
            local target
            target=$(readlink "$HOME/.aws/config")
            log_info "Config is symlink to: $target"
            log_pass "Config is Nix-managed (immutable)"
        else
            log_warn "Config is not Nix-managed (editable)"
        fi

        # Validate syntax
        if grep -q "^\[" "$HOME/.aws/config" 2>/dev/null; then
            log_pass "Config has valid INI format"
        else
            log_fail "Config appears to be invalid or empty"
        fi

        # Count profiles
        local profile_count
        profile_count=$(grep -c "^\[profile " "$HOME/.aws/config" 2>/dev/null || echo "0")
        if [[ $profile_count -gt 0 ]]; then
            log_pass "Config contains $profile_count profile(s)"

            if [[ $VERBOSE -eq 1 ]]; then
                echo "   Profiles found:"
                grep "^\[profile " "$HOME/.aws/config" | sed 's/\[profile /     - /' | sed 's/\]//'
            fi
        else
            log_warn "No profiles found in config (only default)"
        fi
    else
        log_fail "AWS config missing: ~/.aws/config"
        log_info "Will be created on first aws configure"
    fi
}

validate_aws_credentials() {
    log_section "AWS Credentials File"

    local cred_file="$HOME/.aws/credentials"

    if check_exists "$cred_file" "file"; then
        log_pass "AWS credentials exist: ~/.aws/credentials"

        # Check if it's a symlink (SOPS-managed)
        if [[ -L "$cred_file" ]]; then
            local target
            target=$(readlink "$cred_file")
            log_pass "Credentials are symlink to: $target"

            if echo "$target" | grep -q "/run/secrets"; then
                log_pass "Credentials are SOPS-managed (encrypted)"
            fi
        else
            log_warn "Credentials are not SOPS-managed"
        fi

        # Check permissions
        if check_permissions "$cred_file" "600"; then
            log_pass "Credentials have correct permissions (600)"
        else
            local actual_perms
            actual_perms=$(stat -f "%Lp" "$cred_file" 2>/dev/null || stat -c "%a" "$cred_file" 2>/dev/null)
            log_fail "Credentials have insecure permissions: $actual_perms (should be 600)"
            log_info "Fix with: chmod 600 ~/.aws/credentials"
        fi

        # Count credential profiles
        local cred_count
        cred_count=$(grep -c "^\[" "$cred_file" 2>/dev/null || echo "0")
        if [[ $cred_count -gt 0 ]]; then
            log_pass "Credentials contain $cred_count profile(s)"

            if [[ $VERBOSE -eq 1 ]]; then
                echo "   Credential profiles:"
                grep "^\[" "$cred_file" | sed 's/\[/     - /' | sed 's/\]//'
            fi
        else
            log_warn "No credential profiles found"
        fi
    else
        log_warn "AWS credentials missing: ~/.aws/credentials"
        log_info "IAM credentials will be needed for non-SSO profiles"
    fi
}

validate_accounts_json() {
    log_section "Accounts Configuration (accounts.json)"

    local accounts_file="$HOME/.aws/accounts.json"

    if check_exists "$accounts_file" "file"; then
        log_pass "accounts.json exists: $accounts_file"

        # Validate JSON syntax
        if jq empty "$accounts_file" 2>/dev/null; then
            log_pass "accounts.json has valid JSON syntax"
        else
            log_fail "accounts.json has invalid JSON syntax"
            log_info "Validate with: jq . ~/.aws/accounts.json"
            return 1
        fi

        # Count projects
        local project_count
        project_count=$(jq 'keys | length' "$accounts_file" 2>/dev/null || echo "0")
        if [[ $project_count -gt 0 ]]; then
            log_pass "accounts.json contains $project_count project(s)"

            if [[ $VERBOSE -eq 1 ]]; then
                echo "   Projects:"
                jq -r 'to_entries[] | "     - \(.key) (\(.value.alias))"' "$accounts_file"
            fi
        else
            log_warn "No projects defined in accounts.json"
        fi

        # Validate schema
        local has_errors=0
        while IFS= read -r project; do
            # Check required fields
            if ! jq -e ".\"$project\".alias" "$accounts_file" &>/dev/null; then
                log_fail "Project '$project' missing required field: alias"
                has_errors=1
            fi

            if ! jq -e ".\"$project\".accounts" "$accounts_file" &>/dev/null; then
                log_fail "Project '$project' missing required field: accounts"
                has_errors=1
            fi
        done < <(jq -r 'keys[]' "$accounts_file")

        if [[ $has_errors -eq 0 ]]; then
            log_pass "All projects have required fields (alias, accounts)"
        fi
    else
        log_warn "accounts.json not found: $accounts_file"
        log_info "This file is required for multi-role AWS helper functions"
        log_info "See: docs/work/aws/aws-multi-role.md for setup"
    fi
}

validate_sso_configuration() {
    log_section "AWS SSO Configuration"

    # Check for SSO configuration in config file
    if check_exists "$HOME/.aws/config" "file"; then
        if grep -q "sso_" "$HOME/.aws/config"; then
            log_pass "SSO configuration found in config"

            # Count SSO profiles
            local sso_profiles
            sso_profiles=$(grep -c "sso_start_url" "$HOME/.aws/config" 2>/dev/null || echo "0")
            log_info "Found $sso_profiles SSO profile(s)"

            # Check for required SSO fields
            if grep -q "sso_start_url" "$HOME/.aws/config"; then
                log_pass "SSO start URL configured"
            fi

            if grep -q "sso_region" "$HOME/.aws/config"; then
                log_pass "SSO region configured"
            fi

            if grep -q "sso_account_id" "$HOME/.aws/config"; then
                log_pass "SSO account ID configured"
            fi

            if grep -q "sso_role_name" "$HOME/.aws/config"; then
                log_pass "SSO role name configured"
            fi
        else
            log_info "No SSO configuration found (may use IAM credentials)"
        fi
    fi

    # Check SSO cache directory
    if check_exists "$HOME/.aws/sso" "dir"; then
        log_info "SSO cache directory exists"

        # Check for active sessions
        local cache_files
        cache_files=$(find "$HOME/.aws/sso/cache" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $cache_files -gt 0 ]]; then
            log_info "Found $cache_files SSO cache file(s)"
        else
            log_info "No SSO cache files (no active sessions)"
        fi
    fi
}

validate_machine_specific() {
    log_section "Machine-Specific Configuration"

    local hostname
    hostname=$(hostname)
    log_info "Hostname: $hostname"

    # Determine machine type
    if echo "$hostname" | grep -qi "work"; then
        log_info "Machine type: Work"

        # Work-specific checks
        if [[ -n "${MACHINE_MODE:-}" ]] && [[ "$MACHINE_MODE" == "work" ]]; then
            log_pass "MACHINE_MODE environment variable set correctly: work"
        else
            log_warn "MACHINE_MODE not set or incorrect (expected: work)"
        fi

        # Check for work functions
        if type awslogin &>/dev/null; then
            log_pass "awslogin function available (work-specific)"
        else
            log_warn "awslogin function not available"
            log_info "Should be defined in home/_mixins/work.nix"
        fi

        if type awswho &>/dev/null; then
            log_pass "awswho function available"
        else
            log_warn "awswho function not available"
        fi

        # Check for corporate CA bundle
        if [[ -f "$HOME/.config/certs/cacert.pem" ]]; then
            log_pass "Corporate CA bundle found"
        else
            log_warn "Corporate CA bundle missing: ~/.config/certs/cacert.pem"
        fi
    else
        log_info "Machine type: Personal"

        if [[ -n "${MACHINE_MODE:-}" ]] && [[ "$MACHINE_MODE" == "home" ]]; then
            log_pass "MACHINE_MODE environment variable set correctly: home"
        else
            log_warn "MACHINE_MODE not set or incorrect (expected: home)"
        fi

        # Personal machine should have simpler AWS setup
        if grep -q "^\[profile personal\]" "$HOME/.aws/config" 2>/dev/null; then
            log_pass "Personal profile configured"
        else
            log_info "No personal profile found (may not be needed)"
        fi
    fi
}

validate_git_email() {
    log_section "Git Email Configuration"

    local git_email
    git_email=$(git config user.email 2>/dev/null || echo "")

    if [[ -n "$git_email" ]]; then
        log_pass "Git email configured: $git_email"

        local hostname
        hostname=$(hostname)

        if echo "$hostname" | grep -qi "work"; then
            # Work machine - should have work email
            if echo "$git_email" | grep -q "@.*\\."; then
                log_pass "Work email detected on work machine"
            else
                log_warn "Personal email on work machine: $git_email"
            fi
        else
            # Personal machine - should have personal email
            if echo "$git_email" | grep -q "noreply.github.com"; then
                log_pass "Personal GitHub email on personal machine"
            else
                log_info "Email: $git_email"
            fi
        fi
    else
        log_fail "Git email not configured"
        log_info "Configure with: git config --global user.email 'your@email.com'"
    fi
}

validate_profile_functions() {
    log_section "AWS Helper Functions"

    # Check if functions are available
    local functions=("awsuse" "awslogin" "awswho" "awslist" "awswhere" "awscheck")
    local available=0
    local missing=()

    for func in "${functions[@]}"; do
        if type "$func" &>/dev/null; then
            available=$((available + 1))
        else
            missing+=("$func")
        fi
    done

    local hostname
    hostname=$(hostname)

    if [[ $available -eq ${#functions[@]} ]]; then
        log_pass "All AWS helper functions available ($available/${#functions[@]})"
    elif [[ $available -gt 0 ]]; then
        log_warn "Some AWS functions available ($available/${#functions[@]})"
        log_info "Missing: ${missing[*]}"
    else
        # Personal machines don't need AWS functions
        if echo "$hostname" | grep -qi "work"; then
            log_fail "No AWS helper functions available"
            log_info "Functions should be loaded from home/_mixins/work.nix"
        else
            log_info "AWS helper functions not configured (not needed for personal machine)"
        fi
    fi

    if [[ $VERBOSE -eq 1 ]] && [[ $available -gt 0 ]]; then
        echo "   Available functions:"
        for func in "${functions[@]}"; do
            if type "$func" &>/dev/null; then
                echo "     $func"
            else
                echo "     error: $func"
            fi
        done
    fi
}

validate_current_session() {
    log_section "Current AWS Session"

    if [[ -n "${AWS_PROFILE:-}" ]]; then
        log_info "AWS_PROFILE set: $AWS_PROFILE"

        # Try to get caller identity
        if aws sts get-caller-identity &>/dev/null; then
            log_pass "AWS session is active and valid"

            if [[ $VERBOSE -eq 1 ]]; then
                echo "   Session details:"
                aws sts get-caller-identity | sed 's/^/     /'
            fi
        else
            log_warn "AWS_PROFILE set but session expired or invalid"
            log_info "Login with: awslogin (if work machine)"
        fi
    else
        log_info "No AWS_PROFILE currently set"
        log_info "Set with: export AWS_PROFILE=<profile-name>"
    fi

    # Check for last profile file
    if [[ -f "$HOME/.aws/.last_profile" ]]; then
        local last_profile
        last_profile=$(cat "$HOME/.aws/.last_profile")
        log_info "Last used profile: $last_profile"
    fi
}

# ==================================================
# Report Summary
# ==================================================

print_summary() {
    log_header "Validation Summary"

    echo -e "${GREEN}Passed:${NC}   $PASSED checks"
    echo -e "${YELLOW}warning: warnings:${NC} $WARNINGS issues"
    echo -e "${RED}error: failed:${NC}   $FAILED checks"
    echo ""

    if [[ $FAILED -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}All checks passed! AWS configuration looks good.${NC}"
        return 0
    elif [[ $FAILED -eq 0 ]]; then
        echo -e "${YELLOW}warning: configuration has warnings but no critical failures.${NC}"
        return 0
    else
        echo -e "${RED}error: configuration has critical failures. Please review above.${NC}"
        return 1
    fi
}

print_recommendations() {
    log_header "Recommendations"

    local hostname
    hostname=$(hostname)

    if echo "$hostname" | grep -qi "work"; then
        echo "Work Machine Recommendations:"
        echo "   1. Ensure accounts.json is configured with your work projects"
        echo "   2. Configure SSO profiles for each environment"
        echo "   3. Use awslogin function for SSO authentication"
        echo "   4. Keep corporate CA bundle updated"
        echo ""
        echo "Documentation:"
        echo "   - AWS Multi-Role Guide: docs/work/aws/aws-multi-role.md"
        echo "   - AWS Quick Reference: docs/work/aws/aws-quick-ref.md"
    else
        echo "Personal Machine Recommendations:"
        echo "   1. Configure personal profile with IAM credentials"
        echo "   2. Keep credentials in SOPS-encrypted secrets"
        echo "   3. Use minimal AWS configuration for personal projects"
        echo ""
        echo "Documentation:"
        echo "   - Infrastructure Reference: docs/reference/infrastructure.md"
    fi

    echo ""
    echo "Common Commands:"
    echo "   - Check current profile: awswho (or: aws sts get-caller-identity)"
    echo "   - List profiles: awslist (or: aws configure list-profiles)"
    echo "   - Switch profile: export AWS_PROFILE=<name>"
    if echo "$hostname" | grep -qi "work"; then
        echo "   - SSO login: awslogin <project> <env> [role]"
    fi
}

# ==================================================
# Main Execution
# ==================================================

main() {
    log_header "AWS Configuration Validation"
    echo "Running on: $(hostname)"
    echo "Date: $(date)"

    # Run all validations
    validate_aws_cli
    validate_aws_directory
    validate_aws_config
    validate_aws_credentials
    validate_accounts_json
    validate_sso_configuration
    validate_machine_specific
    validate_git_email
    validate_profile_functions
    validate_current_session

    # Print summary
    print_summary

    # Print recommendations
    print_recommendations

    # Exit code based on failures
    [[ $FAILED -eq 0 ]]
}

# Run main
main "$@"
