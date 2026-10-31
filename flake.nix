{
  description = "Minimal NixOS configuration flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
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
            ./desktop.nix
            ./hardware-configuration/desktop.nix

            home-manager-unstable.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                sharedModules = [
                  nixvim-unstable.homeModules.nixvim 
                ];
                users.seb = ./home/desktop.nix;
              };
            }
          ];
        };
        Homelab = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./server.nix
            ./hardware-configuration/server.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [ nixvim.homeModules.nixvim ];
                users.seb = {
                  imports          = [ ./home/modules/shell.nix ./home/modules/pi-hole-lists.nix ];
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
            ./hardware-configuration/work.nix

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

              virtualisation.docker = {
                enable = true;
                listenOptions = [ "/var/run/docker.sock" "127.0.0.1:2375" ];
                autoPrune = {
                  enable = true;
                  dates = "weekly";
                };
              };

              users.users.seb.extraGroups = [ "docker" ];

              # ssh docker context from Windows: NAT wslrelay drops hijacked
              # docker-api streams (run/exec output) but relays ssh fine
              services.openssh = {
                enable = true;
                ports = [ 2222 ];
                listenAddresses = [ { addr = "127.0.0.1"; port = 2222; } ];
                settings = {
                  PasswordAuthentication = false;
                  KbdInteractiveAuthentication = false;
                };
              };
              users.users.seb.openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjkq+wJLgt7T5p9sYYeDzLeaVnex6hMDw7kPE0s8bz18gfpU1LUSVbNTswXWMEI91KP9HZ+TWlhnCQ87ZvtnOwK5kbxPJ+EY+BN7LM7dBf8o3StnGmaIbM81MTCSG1a6t5/OeBAaq+VFzPV6RNi6+2Un7pc9Y1fnimZnJR/LQI/9HUQIH3L3QbGLa+yGMXUcmQAed5aD7Vmg80WQa/Mq3m+C3Nf0teTwVONTBC46tVo6cwOTjfIQE2RRcTVIxFABWLDMPJibvYL9761uEaMUdFZGj6/DU1SkrdjLo/KsK+DOqXdgx4U696quEfNnuGWKR82568APichZMQM1ytyWM9mQw+MWw4YJEMs+txSuRuWeNwqkmYH1yCyn/rb+GlalPxPPaOqKDyYaGZSFJU9UjuCBlxDBN1LMTNu3jrnIqPvfA4OhU/RoyWCtyH1JFNUW6lXGXwJbOhOwRTzD994TlQ0TnRKVkVe5CtQPc5txmEM7oirYZlplbUIdNqL6YJz+s= seb@QohashSebastien"
              ];

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

