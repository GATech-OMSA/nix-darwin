{ config, pkgs, lib, inputs, mixins, hostname, myLib, ... }:

{
  # Home Manager configuration for jimmy
  # This is the main entry point for user-level configuration

  home = {
    username = "jimmy";
    homeDirectory = "/Users/jimmy";
    stateVersion = "24.05";  # Check home-manager releases

    # Session variables
    sessionVariables = {
      EDITOR = "code --wait";
      VISUAL = "code";
      PAGER = "less";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # Python
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
      UV_PYTHON_PREFERENCE = "only-managed";

      # AWS
      AWS_PAGER = "";
      AWS_DEFAULT_OUTPUT = "json";

      # FZF
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";

      # Terraform
      TF_PLUGIN_CACHE_DIR = "$HOME/.terraform.d/plugin-cache";
    };

    # Packages specific to user (not system-wide)
    packages = with pkgs; [
      # Add user-specific packages here
    ];
  };

  # Import all configurations
  imports = [
    # Mixins (reusable configurations)
    ../_mixins/base.nix
    ../_mixins/dev.nix
  ]
  # Import machine-specific mixins based on hostname
  ++ myLib.importIfPersonal hostname ../_mixins/personal.nix
  ++ myLib.importIfWork hostname ../_mixins/work.nix
  ++ [
    # Individual program configurations
    ./shell/zsh.nix
    ./programs/git.nix
    ./programs/vscode.nix
    ./programs/direnv.nix
    ./programs/ssh.nix
    ./programs/aws.nix
    ./development/python.nix
    ./development/node.nix
    ./development/ai-ml.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
