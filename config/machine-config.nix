{
  # Machine identity
  machineId = "macbook-pro-m1";

  # Profile selection
  profileName = "personal";  # Options: "personal" | "work" | "minimal"

  # Machine metadata
  description = "Jimmy's MacBook Pro";
  expectedHostname = "mbp-jimmy";

  # System architecture
  system = "aarch64-darwin";

  # Home-Manager Control Options
  enableHomeManager = true;  # Set to false to completely disable home-manager
  skipGoPackages = false;    # Set to true to skip Go packages (gopls, etc.) - useful behind proxy

  # AWS Configuration (optional)
  aws = {
    enabled = true;          # Set to false to disable AWS helpers entirely
    useSso = false;          # Set to true for AWS SSO setup (work environments)
    ssoStartUrl = "";        # Required if useSso = true
    ssoRegion = "us-east-1"; # SSO region
  };
}
