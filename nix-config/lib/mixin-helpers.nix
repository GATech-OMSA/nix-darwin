{ lib }:

rec {
  # ==================================================
  # MIXIN GENERATOR
  # ==================================================
  # Create mixin with standard structure
  #
  # Usage:
  #   mkMixin {
  #     type = "work";
  #     packages = [ pkgs.unixODBC ];
  #     sessionVariables = { MACHINE_MODE = "work"; };
  #     shellAliases = { ... };
  #     initExtra = ''...'';
  #   }
  #
  # Provides standardized structure for machine-specific configurations
  #
  mkMixin = {
    type,
    packages ? [],
    sessionVariables ? {},
    shellAliases ? {},
    initExtra ? ""
  }: {
    home.packages = packages;
    home.sessionVariables = sessionVariables;
    programs.zsh.shellAliases = shellAliases;
    programs.zsh.initExtra = initExtra;
  };

  # ==================================================
  # CONDITIONAL MIXIN COMPONENTS
  # ==================================================
  # Create mixin components that apply conditionally
  #
  # Usage:
  #   mkConditionalMixinComponents {
  #     condition = hostname == "mbp-work";
  #     packages = [ pkgs.work-tool ];
  #     sessionVariables = { WORK_MODE = "true"; };
  #   }
  #
  mkConditionalMixinComponents = {
    condition,
    packages ? [],
    sessionVariables ? {},
    shellAliases ? {},
    initExtra ? ""
  }:
    if condition then {
      home.packages = packages;
      home.sessionVariables = sessionVariables;
      programs.zsh.shellAliases = shellAliases;
      programs.zsh.initExtra = initExtra;
    } else {};

  # ==================================================
  # MERGE MIXINS
  # ==================================================
  # Merge multiple mixins into a single configuration
  #
  # Usage:
  #   mergeMixins [
  #     (mkMixin { type = "base"; ... })
  #     (mkMixin { type = "dev"; ... })
  #   ]
  #
  mergeMixins = mixins:
    lib.foldl' (acc: mixin: {
      home.packages = (acc.home.packages or []) ++ (mixin.home.packages or []);
      home.sessionVariables = (acc.home.sessionVariables or {}) // (mixin.home.sessionVariables or {});
      programs.zsh.shellAliases = (acc.programs.zsh.shellAliases or {}) // (mixin.programs.zsh.shellAliases or {});
      programs.zsh.initExtra = (acc.programs.zsh.initExtra or "") + "\n" + (mixin.programs.zsh.initExtra or "");
    }) {} mixins;
}
