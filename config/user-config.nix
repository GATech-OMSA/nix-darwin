{
  username = "jimmy";
  fullName = "Jim";
  email = "13123674+jimmy-jain@users.noreply.github.com";

  # AWS SSO configuration
  awsSso = {
    enabled = true;
    startUrl = "https://d-90661be104.awsapps.com/start";
    region = "us-east-1";
  };

  # Proxy configuration for corporate environments
  # Enable on work machine, leave disabled on personal
  proxies = {
    # Corporate CA bundle — single source of truth
    # Fanned out to AWS_CA_BUNDLE, NODE_EXTRA_CA_CERTS, PIP_CERT,
    # REQUESTS_CA_BUNDLE, SSL_CERT_FILE, npm cafile, CARGO_HTTP_CAINFO
    # Set to "" to disable CA fan-out (uses system defaults)
    corporateCaBundle = "";  # e.g. "$HOME/.config/certs/cacert.pem"

    # Go module proxy (for sops-nix and other Go-based tools)
    go = {
      enabled = false;
      url = "";
      private = "";
    };

    # Python package proxy
    python = {
      enabled = false;
      url = "";
      trustedHost = "";
    };

    # NPM package proxy (corporate Nexus registry)
    npm = {
      enabled = false;
      url = "";
    };

    # Cargo/Rust proxy
    cargo = {
      enabled = false;
    };
  };
}
