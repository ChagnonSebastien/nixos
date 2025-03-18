{
  description = "Minimal NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
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
          ];
        };
      };

      homeConfigurations = {
        seb = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.packages.${system};
          modules = [
            ./home.nix
          ];
	};
      };
    };
}

