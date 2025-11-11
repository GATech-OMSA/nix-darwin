{
  description = "Jimmy's Nix Darwin Configuration - Modern, Modular, Production-Ready";

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

    # Optional: nix-darwin-kickstarter patterns
    # Uncomment if you want additional community modules
    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, sops-nix }:
    let
      # Import custom lib functions
      myLib = import ./lib { inherit inputs; };

      # Import overlays
      overlays = import ./overlays { inherit inputs; };

      # Helper function for creating Darwin systems
      mkDarwinSystem = { hostname, system ? "aarch64-darwin", username, mixins ? [] }:
        let
          # Validate machine is recognized and get type
          machineType = myLib.requireKnownMachine hostname;
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs username hostname myLib machineType;
          };
          modules = [
            # Apply overlays to nixpkgs
            { nixpkgs.overlays = overlays; }

            # Host-specific configuration
            ./hosts/${hostname}

            # System modules
            ./modules/darwin
            ./modules/shared

            # Home Manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./home/${username};
                extraSpecialArgs = {
                  inherit inputs mixins hostname myLib machineType username;
                };
                verbose = true;
                backupFileExtension = "hm-backup";
              };
            }

            # Secrets management
            sops-nix.darwinModules.sops
          ];
        };
    in
    {
      # Personal MacBook (M1)
      darwinConfigurations."mbp-jimmy" = mkDarwinSystem {
        hostname = "mbp-jimmy";
        system = "aarch64-darwin";
        username = "jimmy";
        mixins = [ "base" "dev" "personal" ];
      };

      # Work MacBook (M3)
      darwinConfigurations."mbp-work" = mkDarwinSystem {
        hostname = "mbp-work";
        system = "aarch64-darwin";
        username = "jimmy";
        mixins = [ "base" "dev" "work" ];
      };

      # Expose helpers for reuse
      lib = myLib // {
        inherit mkDarwinSystem;
      };

      # Expose secret paths for use in scripts and validation
      # Usage: nix eval .#secretPaths --json
      secretPaths = myLib.secrets.secretPaths;
      secretGlobPatterns = myLib.secrets.secretGlobPatterns;
      secretsByType = myLib.secrets.secretsByType;

      # Expose machine type for current hostname (validation and testing)
      # Usage: nix eval .#currentMachineType --json
      currentMachineType = myLib.machineType (builtins.getEnv "HOSTNAME");
    };
}
