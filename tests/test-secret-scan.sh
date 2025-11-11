#!/usr/bin/env bash

# Test script for secret scanning functionality

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() {
  echo -e "${BLUE}[i]${NC}  $*"
}

success() {
  echo -e "${GREEN}✓${NC} $*"
}

warning() {
  echo -e "${YELLOW}!${NC}  $*"
}

error() {
  echo -e "${RED}×${NC} $*"
}

print_step() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$*${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

scan_existing_secrets() {
  print_step "◆ Scanning for Existing Secrets"

  info "Detecting secrets in your home directory..."
  echo ""

  local found_secrets=()
  local secret_count=0

  # Scan ~/.db/ directory (database credentials)
  if [ -d "$HOME/.db" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("Database credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.db" -type f -print0 2>/dev/null)
  fi

  # Scan ~/.tokens/ directory (API tokens)
  if [ -d "$HOME/.tokens" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("API token: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.tokens" -type f -print0 2>/dev/null)
  fi

  # Scan ~/.credentials/ directory
  if [ -d "$HOME/.credentials" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("Credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.credentials" -type f -print0 2>/dev/null)
  fi

  # Check AWS credentials
  if [ -f "$HOME/.aws/credentials" ]; then
    found_secrets+=("AWS credentials: ~/.aws/credentials")
    ((secret_count++)) || true
  fi

  # Scan SSH keys (private keys only, exclude .pub)
  if [ -d "$HOME/.ssh" ]; then
    while IFS= read -r -d '' file; do
      if [[ ! "$file" =~ \.pub$ ]] && [[ -f "$file" ]]; then
        found_secrets+=("SSH key: $file")
        ((secret_count++)) || true
      fi
    done < <(find "$HOME/.ssh" -name "id_*" -type f -print0 2>/dev/null)
  fi

  # Check Docker config
  if [ -f "$HOME/.docker/config.json" ]; then
    found_secrets+=("Docker config: ~/.docker/config.json")
    ((secret_count++)) || true
  fi

  # Scan ~/.vpn/ directory
  if [ -d "$HOME/.vpn" ]; then
    while IFS= read -r -d '' file; do
      found_secrets+=("VPN credential: $file")
      ((secret_count++)) || true
    done < <(find "$HOME/.vpn" -type f -print0 2>/dev/null)
  fi

  # Scan shell configuration files for exported secrets
  local shell_configs=("$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.config/fish/config.fish")
  for config_file in "${shell_configs[@]}"; do
    if [ -f "$config_file" ]; then
      # Search for export statements with secret-like patterns
      if grep -qE 'export.*(API_KEY|TOKEN|SECRET|PASSWORD|PRIVATE_KEY).*=' "$config_file" 2>/dev/null; then
        found_secrets+=("Shell config with secrets: $config_file")
        ((secret_count++)) || true
      fi
    fi
  done

  # Scan for all environment files (excluding backups)
  while IFS= read -r -d '' env_file; do
    found_secrets+=("Environment file: $env_file")
    ((secret_count++)) || true
  done < <(find "$HOME" -maxdepth 1 -type f \( -name ".env*" -o -name ".envrc" \) \
    ! -name "*.swp" \
    ! -name "*.bak" \
    ! -name "*.backup" \
    ! -name "*~" \
    -print0 2>/dev/null)

  # Scan application-specific config files
  local app_configs=(
    "$HOME/.npmrc:npm config"
    "$HOME/.netrc:Network credentials"
    "$HOME/.pgpass:PostgreSQL password"
    "$HOME/.my.cnf:MySQL credentials"
    "$HOME/.pypirc:PyPI credentials"
    "$HOME/.gem/credentials:Ruby gem credentials"
    "$HOME/.wakatime.cfg:WakaTime API key"
  )
  for app_config in "${app_configs[@]}"; do
    local file_path="${app_config%%:*}"
    local description="${app_config##*:}"
    if [ -f "$file_path" ]; then
      found_secrets+=("$description: $file_path")
      ((secret_count++)) || true
    fi
  done

  # Display results
  if [ $secret_count -eq 0 ]; then
    info "No existing secrets detected in common locations"
    echo "   You'll need to create them manually or via SOPS encryption"
  else
    success "Found $secret_count existing secret(s):"
    echo ""
    for secret in "${found_secrets[@]}"; do
      echo "   ✓ $secret"
    done
    echo ""
    warning "These secrets should be encrypted in hosts/\$MACHINE_ID/secrets.yaml"
    info "See docs for SOPS setup instructions"
  fi

  echo ""
}

# Run the scan
scan_existing_secrets

echo ""
echo "Test complete!"
