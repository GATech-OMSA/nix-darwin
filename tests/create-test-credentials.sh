#!/usr/bin/env bash

# ============================================================================
# CREATE TEST CREDENTIALS
# ============================================================================
#
# Creates test credential files for testing secret scanning functionality
#
# Usage:
#   ./tests/create-test-credentials.sh
#
# What gets created:
#   - ~/.db/production           (database credentials)
#   - ~/.tokens/github           (API token)
#   - ~/.credentials/stripe      (API key)
#   - ~/.env.test                (environment variables)
#

set -e

# Colors
GREEN='\033[0;32m'
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

print_step() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}$*${NC}"
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

banner() {
  echo ""
  echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}║         Create Test Credentials for Scanning          ║${NC}"
  echo -e "${BOLD}${CYAN}║                                                        ║${NC}"
  echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

create_test_credentials() {
  print_step "Creating Test Credential Files"

  # Create directories
  info "Creating test directories..."
  mkdir -p ~/.db
  mkdir -p ~/.tokens
  mkdir -p ~/.credentials

  # Database credentials
  info "Creating: ~/.db/production"
  cat > ~/.db/production <<'EOF'
# Test Database Credentials
# DO NOT USE IN PRODUCTION
host=db.example.com
port=5432
user=admin
password=test_password_123
database=production_db
EOF
  success "Created ~/.db/production"

  # API token
  info "Creating: ~/.tokens/github"
  cat > ~/.tokens/github <<'EOF'
# Test GitHub Token
# DO NOT USE IN PRODUCTION
ghp_test1234567890abcdefghijklmnopqrstuvwxyz
EOF
  success "Created ~/.tokens/github"

  # API key
  info "Creating: ~/.credentials/stripe"
  cat > ~/.credentials/stripe <<'EOF'
# Test Stripe API Key
# DO NOT USE IN PRODUCTION
sk_test_abcdef123456789012345678901234567890
EOF
  success "Created ~/.credentials/stripe"

  # Environment file
  info "Creating: ~/.env.test"
  cat > ~/.env.test <<'EOF'
# Test Environment Variables
# DO NOT USE IN PRODUCTION

DATABASE_URL=postgresql://user:password@localhost:5432/mydb
API_KEY=sk_test_1234567890abcdef
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
STRIPE_SECRET_KEY=sk_test_abcdef123456
SENDGRID_API_KEY=SG.test123456789abcdef
EOF
  success "Created ~/.env.test"

  echo ""
}

show_summary() {
  print_step "Test Credentials Created"

  echo ""
  echo -e "${BOLD}Test credential files created:${NC}"
  echo ""
  echo "   Database:"
  echo "     ~/.db/production"
  echo ""
  echo "  API Tokens:"
  echo "     ~/.tokens/github"
  echo ""
  echo "  API Keys:"
  echo "     ~/.credentials/stripe"
  echo ""
  echo "  Environment:"
  echo "     ~/.env.test"
  echo ""
  echo -e "${CYAN}Next steps:${NC}"
  echo "  1. Run configure script to test secret scanning:"
  echo "     ${BOLD}./scripts/setup/configure.sh${NC}"
  echo ""
  echo "  2. Or test scanning in isolation:"
  echo "     ${BOLD}./test-secret-scan.sh${NC}"
  echo ""
  echo "  3. Clean up test credentials when done:"
  echo "     ${BOLD}./tests/cleanup-test-credentials.sh${NC}"
  echo ""
}

main() {
  banner
  create_test_credentials
  show_summary
}

main
