{ config, pkgs, lib, ... }:

{
  # direnv configuration with nix-direnv
  # Essential for fast Nix development workflows

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # nix-direnv: 20x faster than regular direnv!
    nix-direnv.enable = true;
  };

  # direnv configuration file
  home.file.".config/direnv/direnv.toml".text = ''
    [global]
    load_dotenv = true
    strict_env = false

    [whitelist]
    # Add trusted directories here
    # prefix = [ "/Users/jimmy/Dev" ]
  '';
}
