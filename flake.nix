{
  description = "Minimal NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        DesktopL = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            ./hardware-configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  nixvim.homeManagerModules.nixvim 
                ];
                users.seb = ./home/home.nix;
              };
            }
          ];
        };
      };

      homeConfigurations = {
        seb = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.packages.${system};
          modules = [
            ./home.nix
            nixvim.homeManagerModules.nixvim
          ];
        };
      };
    };
}

