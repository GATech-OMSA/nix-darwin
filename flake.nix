{
  description = "Jimmy's Nix Darwin Configuration - Modern, Modular, Production-Ready";

  # ============================================
  # INPUTS - External Dependencies
  # ============================================

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI coding tools (openspec, claude-code, etc.)
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # ============================================
  # OUTPUTS - System Configurations
  # ============================================

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, sops-nix, llm-agents }:
    let
      # ============================================
      # HELPER IMPORTS
      # ============================================

      myLib = import ./nix-config/lib { inherit inputs; };

      # User config (tracked, must exist before building)
      userConfig = import ./config/user-config.nix;

      # Overlays (reads userConfig for proxy settings)
      overlays = import ./nix-config/overlays { inherit inputs userConfig; };

      # Active machine config (tracked, overrides registry for local builds)
      machineConfig = import ./config/machine-config.nix;

      # ============================================
      # MACHINE REGISTRY
      # ============================================
      # Static defaults for all machines. CI uses these as-is.
      # Local builds merge overrides from config/machine-config.nix
      # for the matching machineId (e.g. profileName from switch-profile.sh).

      validProfiles = [ "personal" "work" "minimal" ];

      machineDefaults = [
        {
          machineId = "macbook-pro-m1-personal";
          profileName = "personal";
          system = "aarch64-darwin";
          expectedHostname = "mbp-jimmy";
          enableHomeManager = true;
          skipGoPackages = false;
        }
        {
          machineId = "macbook-pro-m3-work";
          profileName = "work";
          system = "aarch64-darwin";
          expectedHostname = "mbp-work";
          enableHomeManager = true;
          skipGoPackages = false;
        }
      ];

      # Merge local overrides for the active machine.
      # intersectAttrs keeps only keys present in both, so machineConfig
      # can't inject unexpected fields into the registry entry.
      machines = map (m:
        if m.machineId == (machineConfig.machineId or "")
        then m // (builtins.intersectAttrs m machineConfig)
        else m
      ) machineDefaults;

      # ============================================
      # DARWIN SYSTEM BUILDER
      # ============================================

      mkDarwinSystem = machine:
        assert builtins.elem machine.profileName validProfiles
          || throw "Invalid profileName '${machine.profileName}'";

        nix-darwin.lib.darwinSystem {
          inherit (machine) system;

          specialArgs = {
            inherit inputs myLib userConfig;
            inherit (machine) profileName machineId enableHomeManager skipGoPackages;
            hostname = machine.expectedHostname;
            username = userConfig.username;
          };

          modules = [
            { nixpkgs.overlays = overlays; }
            { system.configurationRevision = self.rev or self.dirtyRev or null; }
            sops-nix.darwinModules.sops
            ./nix-config/hosts/${machine.machineId}
            ./nix-config/modules/darwin
          ]
          ++ (if machine.enableHomeManager then [
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs myLib userConfig;
                  inherit (machine) profileName machineId skipGoPackages;
                  hostname = machine.expectedHostname;
                  username = userConfig.username;
                };

                users.${userConfig.username} = { config, pkgs, ... }: {
                  imports = [
                    ./nix-config/home/_template
                    ./nix-config/home/_profiles/${machine.profileName}
                  ];

                  manual.html.enable = false;
                  manual.json.enable = false;
                  manual.manpages.enable = false;
                };

                verbose = true;
                backupFileExtension = "hm-backup";
              };
            }
          ] else [
            {
              warnings = [
                ''
                  Home-Manager is DISABLED (enableHomeManager = false)
                  - No user-level shell/git/program configuration
                  - Only system-wide packages and settings will be applied
                  - To re-enable: Set enableHomeManager = true in config/machine-config.nix
                ''
              ];
            }
          ]);
        };

    in
    {
      # ============================================
      # MACHINE CONFIGURATIONS
      # ============================================
      # All machines exported — CI can test both, local builds select by machineId

      darwinConfigurations = builtins.listToAttrs (
        map (m: { name = m.machineId; value = mkDarwinSystem m; }) machines
      );

      # ============================================
      # LIBRARY EXPORTS
      # ============================================

      lib = myLib;

      # ============================================
      # VALIDATION & INTROSPECTION EXPORTS
      # ============================================

      activeProfile = machineConfig.profileName or "personal";
      activeMachineId = machineConfig.machineId or "default";
    };
}
