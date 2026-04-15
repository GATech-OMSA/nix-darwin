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
  proxies = {
    # Go module proxy (for sops-nix and other Go-based tools)
    go = {
      enabled = false;
      url = "";
      private = "";
    };

    # Python package proxy (configure if needed)
    python = {
      enabled = false;
      url = "";
      trustedHost = "";
    };

    # NPM package proxy (corporate Nexus registry)
    npm = {
      enabled = true;
      url = "https://nexus.ci.duke-energy.app/repository/duke-cne-npm";
    };
  };
}
