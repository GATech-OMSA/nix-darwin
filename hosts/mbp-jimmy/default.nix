{ config, pkgs, username, hostname, ... }:

{
  # Host-specific configuration for personal MacBook M1
  networking = {
    hostName = hostname;
    computerName = "Jimmy's MacBook Pro";
    localHostName = hostname;
  };

  # User configuration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Set primary user (required for some nix-darwin features)
  system.primaryUser = username;

  # Secrets Management with sops-nix
  # See: secrets/SETUP.md for setup documentation
  # Edit secrets with: sops hosts/mbp-jimmy/secrets.yaml
  # Or use helper: edit-secrets
  sops = {
    # Path to your age key
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    # Default secrets file for this host
    defaultSopsFile = ./secrets.yaml;

    # Define secrets and where they should be placed
    secrets = {
      # .zsh_secrets - Environment variables and API keys
      # Automatically sourced in zsh.nix
      zsh_secrets = {
        path = "/Users/${username}/.zsh_secrets";
        owner = username;
        mode = "0600";
      };

      # SSH private key (optional - only if managing SSH keys with Nix)
      # ssh_private_key = {
      #   path = "/Users/${username}/.ssh/id_ed25519";
      #   owner = username;
      #   mode = "0600";
      # };

      # SSH public key (optional)
      # ssh_public_key = {
      #   path = "/Users/${username}/.ssh/id_ed25519.pub";
      #   owner = username;
      #   mode = "0644";
      # };

      # AWS credentials (optional)
      # aws_credentials = {
      #   path = "/Users/${username}/.aws/credentials";
      #   owner = username;
      #   mode = "0600";
      # };

      # Docker config (optional)
      # docker_config = {
      #   path = "/Users/${username}/.docker/config.json";
      #   owner = username;
      #   mode = "0600";
      # };
    };
  };

  # Enable Homebrew for personal Mac
  # (This gets configured in modules/darwin/homebrew.nix)
  homebrew.enable = true;

  # System state version (don't change this)
  system.stateVersion = 5;
}
