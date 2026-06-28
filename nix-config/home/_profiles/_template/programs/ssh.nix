{ config, pkgs, lib, hostname, myLib, profileName, ... }:

{
  # SSH configuration - Declarative management
  # Manages ~/.ssh/config for both personal and work machines

  programs.ssh = {
    enable = true;

    # Disable home-manager's default config since we define our own
    enableDefaultConfig = false;

    # Host-specific configurations
    settings = {
      # GitHub
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };

      # GitLab (if needed)
      "gitlab.com" = {
        HostName = "gitlab.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };

      # Example: Personal server
      # Uncomment and customize as needed
      # "personal-server" = {
      #   HostName = "example.com";
      #   User = "jimmy";
      #   Port = 22;
      #   IdentityFile = "~/.ssh/id_ed25519";
      #   ForwardAgent = true;
      # };

      # Default configuration for all hosts — must come last in SSH config
      "*" = {
        # Key management (macOS-specific)
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
        IdentityFile = "~/.ssh/id_ed25519";

        # Performance
        Compression = true;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;

        # Security
        HashKnownHosts = true;
        StrictHostKeyChecking = "ask";
        VerifyHostKeyDNS = "yes";

        # Modern ciphers only
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
        ];
        MACs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
        ];
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];
      };
    } // lib.optionalAttrs (myLib.isWorkProfile profileName) {
      # Work-specific SSH configurations (only on work Mac)
      # Example: Work bastion host
      # "work-bastion" = {
      #   HostName = "bastion.company.com";
      #   User = "jimmy";
      #   IdentityFile = "~/.ssh/id_rsa_work";
      #   ForwardAgent = true;
      # };

      # Example: Work servers via bastion (ProxyJump)
      # "work-server-*" = {
      #   ProxyJump = "work-bastion";
      #   User = "jimmy";
      #   IdentityFile = "~/.ssh/id_rsa_work";
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
