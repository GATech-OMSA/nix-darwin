{
  username = "jimmy";
  fullName = "John Doe";
  email = "user@example.com";

  # Proxy configuration for corporate environments
  proxies = {
    # Go module proxy (for sops-nix and other Go-based tools)
    go = {
      enabled = true;
      url = "https://nexus.example.com/repository/duke-cne-golang/";
      private = "github.com/examplecorp-corp/";
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
