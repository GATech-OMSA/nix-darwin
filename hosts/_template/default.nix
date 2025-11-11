{ config, pkgs, username, hostname, ... }:

{
  # Host-specific configuration template
  # Copy this directory and customize for your new machine

  networking = {
    hostName = hostname;
    computerName = "REPLACE_WITH_COMPUTER_NAME";  # e.g., "John's MacBook Pro"
    localHostName = hostname;
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Set primary user (required for some nix-darwin features)
  system.primaryUser = username;

  # Secrets Management with sops-nix
  # See: secrets/SETUP.md for setup documentation
  # Setup instructions:
  #   1. Generate age key: age-keygen -o ~/.config/sops/age/keys.txt
  #   2. Update secrets/.sops.yaml with your public key
  #   3. Create encrypted secrets: sops hosts/${hostname}/secrets.yaml
  #   4. Rebuild: darwin-rebuild switch --flake .
  sops = {
    # Path to your age key
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    # Default secrets file for this host
    defaultSopsFile = ./secrets.yaml;

    # Define secrets and where they should be placed
    # Uncomment and customize as needed
    secrets = {
      # .zsh_secrets - Environment variables and API keys
      # Automatically sourced in zsh.nix
      zsh_secrets = {
        path = "/Users/${username}/.zsh_secrets";
        owner = username;
        mode = "0600";
      };

      # SSH private key (Nix-managed for automated deployment)
      ssh_private_key = {
        path = "/Users/${username}/.ssh/id_ed25519";
        owner = username;
        mode = "0600";
      };

      # SSH public key
      ssh_public_key = {
        path = "/Users/${username}/.ssh/id_ed25519.pub";
        owner = username;
        mode = "0644";
      };

      # AWS credentials (if using AWS)
      # aws_credentials = {
      #   path = "/Users/${username}/.aws/credentials";
      #   owner = username;
      #   mode = "0600";
      # };

      # Add more secrets as needed
      # Example: Docker config, GPG keys, etc.
    };
  };

  # Enable Homebrew
  # (Configuration is in modules/darwin/homebrew.nix)
  homebrew.enable = true;

  # System state version (don't change this)
  system.stateVersion = 5;
}
