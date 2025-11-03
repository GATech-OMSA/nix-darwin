{ config, pkgs, lib, hostname, ... }:

{
  # SSH configuration - Declarative management
  # Manages ~/.ssh/config for both personal and work machines

  programs.ssh = {
    enable = true;

    # Disable home-manager's default config since we define our own
    enableDefaultConfig = false;

    # Host-specific configurations
    matchBlocks = {
      # Default configuration for all hosts
      "*" = {
        extraOptions = {
          # Security settings
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
          IdentityFile = "~/.ssh/id_ed25519";

          # Performance
          Compression = "yes";
          ServerAliveInterval = "60";
          ServerAliveCountMax = "3";

          # Security
          HashKnownHosts = "yes";
          StrictHostKeyChecking = "ask";
          VerifyHostKeyDNS = "yes";

          # Modern ciphers only
          Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com";
          MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
          KexAlgorithms = "curve25519-sha256,curve25519-sha256@libssh.org";
        };
      };
      # GitHub
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      # GitLab (if needed)
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      # Example: Personal server
      # Uncomment and customize as needed
      # "personal-server" = {
      #   hostname = "example.com";
      #   user = "jimmy";
      #   port = 22;
      #   identityFile = "~/.ssh/id_ed25519";
      #   forwardAgent = true;
      # };

      # Work-specific SSH configurations (only on work Mac)
    } // lib.optionalAttrs (hostname == "mbp-work") {
      # Example: Work bastion host
      # "work-bastion" = {
      #   hostname = "bastion.company.com";
      #   user = "jimmy";
      #   identityFile = "~/.ssh/id_rsa_work";
      #   forwardAgent = true;
      # };

      # Example: Work servers via bastion (ProxyJump)
      # "work-server-*" = {
      #   proxyJump = "work-bastion";
      #   user = "jimmy";
      #   identityFile = "~/.ssh/id_rsa_work";
      # };
    };
  };

  # Note: SSH keys themselves should NOT be managed by Nix
  # Generate/manage keys manually:
  #   ssh-keygen -t ed25519 -C "your_email@example.com"
  #   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  #
  # For work machine, you may need separate keys:
  #   ssh-keygen -t rsa -b 4096 -C "work_email@company.com" -f ~/.ssh/id_rsa_work
}
