{
  machineId = "macbook-pro-m1";
  profileName = "personal";  # Options: "personal" | "work" | "minimal"
  description = "Jimmy's MacBook Pro";
  expectedHostname = "mbp-jimmy";
  system = "aarch64-darwin";

  # Home-Manager Control Options
  enableHomeManager = true;  # Set to false to completely disable home-manager
  skipGoPackages = false;    # Set to true to skip Go packages (gopls, etc.) - useful behind proxy
}
