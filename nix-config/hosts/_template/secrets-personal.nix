# secrets-personal.nix
#
# Personal machine SOPS secret definitions
# These secrets are auto-decrypted on rebuild and placed in specified paths
# Edit secrets with: edit-secrets

{ config, pkgs, username, ... }:

{
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

      # AWS credentials (encrypted in secrets.yaml)
      aws_credentials = {
        path = "/Users/${username}/.aws/credentials";
        owner = username;
        mode = "0600";
      };

      # Ollama SSH keys (encrypted in secrets.yaml)
      # Uncomment if you use remote Ollama and have keys in secrets.yaml
      # ollama_ssh_private_key = {
      #   path = "/Users/${username}/.ollama/id_ed25519";
      #   owner = username;
      #   mode = "0600";
      # };

      # ollama_ssh_public_key = {
      #   path = "/Users/${username}/.ollama/id_ed25519.pub";
      #   owner = username;
      #   mode = "0644";
      # };

      # Docker config (optional - uncomment if needed)
      # docker_config = {
      #   path = "/Users/${username}/.docker/config.json";
      #   owner = username;
      #   mode = "0600";
      # };
    };
  };
}
