{
  description = "Minimal NixOS configuration flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-unstable = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager, home-manager-unstable, nixvim, nixvim-unstable }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        DesktopL = nixpkgs-unstable.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            ./hardware-configuration.nix

            ({...}: {
              nixpkgs.config.permittedInsecurePackages = [
                "beekeeper-studio-5.3.4"
                "qtwebengine-5.15.19"
              ];
            })

            home-manager-unstable.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  nixvim-unstable.homeModules.nixvim 
                ];
                users.seb = ./home/home.nix;
              };
            }
          ];
        };
        Homelab = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./homelab.nix
            ./homelab-hardware-configuration.nix
            ./generic.nix
            ./modules/shell.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [ nixvim.homeModules.nixvim ];
                users.seb = {
                  imports          = [ ./home/shell.nix ];
                  home.stateVersion = "24.05";
                };
              };
            }
          ];
        };
	Work = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./work.nix
            ./work-hardware-configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [ nixvim.homeModules.nixvim ];
                users.seb = {
                  imports          = [ ./home/work.nix ];
                  home.stateVersion = "24.05";
                };
              };
            }
          ];
        };
        WSL = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            nixos-wsl.nixosModules.default
            {
              wsl.enable = true;
              wsl.defaultUser = "seb";
              system.stateVersion = "24.11";
            }

            ./generic.nix
            ./modules/shell.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  nixvim.homeModules.nixvim 
                ];
                users.seb = {
                  imports = [ ./home/wsl.nix ];
                  home.stateVersion = "24.05";
                };
              };
            }
          ];
        };
      };

      homeConfigurations = {
        seb = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs-unstable.packages.${system};
          modules = [
            ./home.nix
            nixvim.homeModules.nixvim
          ];
        };
      };
    };
}

