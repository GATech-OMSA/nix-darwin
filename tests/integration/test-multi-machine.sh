#!/usr/bin/env bash
#
# Test: Multi-Machine Configuration
# Tests personal vs work machine differentiation
#

source "$(dirname "$0")/../test-framework.sh"

test_begin "Multi-Machine Configuration"

test_section "Machine Type Detection"

current_hostname=$(hostname -s)
test_info "Current hostname: $current_hostname"

# Read machineId and profileName from config (the canonical source of truth)
machine_id=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" machineId 2>/dev/null || echo "")
profile_name=$(nix eval --raw --file "$REPO_ROOT/config/machine-config.nix" profileName 2>/dev/null || echo "")

if [[ -z "$machine_id" ]]; then
  test_skip "All multi-machine tests" "Could not read machineId from config"
  test_end
fi

# Derive expected mode from profile
if [[ "$profile_name" == "personal" ]]; then
  expected_mode="home"
elif [[ "$profile_name" == "work" ]]; then
  expected_mode="work"
else
  expected_mode="$profile_name"
fi

config_name="$machine_id"

test_info "Machine ID: $machine_id"
test_info "Profile: $profile_name"
test_info "Expected MACHINE_MODE: $expected_mode"

test_section "Environment Variables"

# Test: MACHINE_MODE matches expected
assert_equals \
  "${MACHINE_MODE:-unset}" \
  "$expected_mode" \
  "MACHINE_MODE matches machine type"

# AWS_PROFILE can be modified at runtime (e.g., by awsuse), so just check it's set
if [[ -n "${AWS_PROFILE:-}" ]]; then
  _test_log "pass" "AWS_PROFILE is set: $AWS_PROFILE"
else
  test_skip "AWS_PROFILE test" "AWS_PROFILE not set"
fi

test_section "Profile Configuration"

# Test: Profile directory exists for active profile
assert_directory_exists \
  "$REPO_ROOT/nix-config/home/_profiles/$profile_name" \
  "Profile directory exists: $profile_name"

assert_file_exists \
  "$REPO_ROOT/nix-config/home/_profiles/$profile_name/default.nix" \
  "Profile default.nix exists"

test_section "Git Configuration"

# Test: Git email matches machine type
git_email=$(git config user.email 2>/dev/null || echo "")

if [[ "$profile_name" == "personal" ]]; then
  if [[ "$git_email" == *"users.noreply.github.com"* ]]; then
    _test_log "pass" "Personal profile uses GitHub noreply email"
  else
    _test_log "fail" "Personal profile email unexpected: $git_email"
  fi

elif [[ "$profile_name" == "work" ]]; then
  if [[ "$git_email" == *"@"* ]] && [[ "$git_email" != *"users.noreply.github.com"* ]]; then
    _test_log "pass" "Work profile uses work email: $git_email"
  else
    _test_log "fail" "Work profile email unexpected: $git_email"
  fi
fi

test_section "Machine-Specific Functions"

# AWS functions are zsh aliases — not available in non-interactive bash
test_skip "AWS function checks" "zsh functions, not available in bash test scripts"

test_section "Configuration Files"

# Test: Host-specific directory exists
assert_directory_exists \
  "$REPO_ROOT/nix-config/hosts/$config_name" \
  "Host directory exists: nix-config/hosts/$config_name"

# Test: Host configuration files exist
assert_file_exists \
  "$REPO_ROOT/nix-config/hosts/$config_name/default.nix" \
  "Host default.nix exists"

# Test: Secrets file exists (should be encrypted)
if [[ -f "$REPO_ROOT/nix-config/hosts/$config_name/secrets.yaml" ]]; then
  assert_file_exists \
    "$REPO_ROOT/nix-config/hosts/$config_name/secrets.yaml" \
    "Secrets file exists"

  # SOPS-encrypted files contain ENC[AES256_GCM markers
  if grep -q "ENC\[AES256_GCM" "$REPO_ROOT/nix-config/hosts/$config_name/secrets.yaml" 2>/dev/null; then
    _test_log "pass" "Secrets file is SOPS-encrypted"
  else
    _test_log "fail" "Secrets file is not encrypted"
  fi
fi

test_end
