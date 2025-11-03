{ config, pkgs, lib, ... }:

{
  # Personal machine-specific configuration

  # Personal-specific packages
  home.packages = with pkgs; [
    # Personal tools
    neofetch
  ];

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "home";
    AWS_PROFILE = "personal";
  };

  # Personal-specific shell aliases
  programs.zsh.shellAliases = {
    # Learning directory shortcuts
    learning = "cd ~/Dev/learning";
    courses = "cd ~/Dev/courses";
    experiments = "cd ~/Dev/experiments";

    # Ollama shortcuts
    ollama-start = "ollama serve";
    models = "ollama list";
    llama3 = "ollama run llama3";
    codellama = "ollama run codellama";
  };
}
