{
  username = "jimmy";
  fullName = "Jimmy Jain";
  email = "jimmy-jain@users.noreply.github.com";

  # ============================================
  # CORPORATE PROXY CONFIGURATION (OPTIONAL)
  # ============================================
  # Uncomment and configure if behind corporate proxy/firewall.
  # These settings apply to Go, Python, and NPM package managers.
  #
  # Usage:
  #   1. Uncomment the proxies section below
  #   2. Set enabled = true for the proxy types you need
  #   3. Update URLs to match your corporate infrastructure
  #   4. Run: nix-rebuild && exec zsh
  #
  # Note: Both personal and work profiles can use proxies.
  #       Work profiles typically need this for corporate networks.

  # proxies = {
  #   # Go module proxy (for Go development and sops-nix)
  #   go = {
  #     enabled = false;  # Set to true to enable
  #     url = "https://nexus.company.com/repository/company-golang/";
  #     private = "github.com/company-corp/*";  # Comma-separated globs for private modules
  #   };
  #
  #   # Python package proxy (for pip, UV, micromamba)
  #   python = {
  #     enabled = false;  # Set to true to enable
  #     url = "https://nexus.company.com/repository/pypi-all/simple";
  #     trustedHost = "nexus.company.com";  # For self-signed certificates
  #   };
  #
  #   # NPM package proxy (for npm, pnpm, yarn)
  #   npm = {
  #     enabled = false;  # Set to true to enable
  #     url = "https://nexus.company.com/repository/npm-proxy/";
  #   };
  # };
}
