{
  username = "jimmy";
  fullName = "John Doe";
  email = "13123674+jimmy-jain@users.noreply.github.com";

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

    # NPM package proxy (configure if needed)
    npm = {
      enabled = false;
      url = "";
    };
  };
}
