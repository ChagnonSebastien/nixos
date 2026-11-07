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

      # Each channel pins nixpkgs, home-manager and nixvim together.
      stable   = { inherit nixpkgs home-manager nixvim; };
      unstable = {
        nixpkgs      = nixpkgs-unstable;
        home-manager = home-manager-unstable;
        nixvim       = nixvim-unstable;
      };

      # A NixOS host with home-manager (and nixvim) wired up for user seb.
      # The attribute name doubles as the hostname, so a bare
      # `nixos-rebuild switch --flake .` always finds the right config.
      mkHost = name: { channel, modules, home }:
        channel.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = modules ++ [
            { networking.hostName = name; }
            channel.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [ channel.nixvim.homeModules.nixvim ];
                users.seb       = home;
              };
            }
          ];
        };
    in {
      nixosConfigurations = builtins.mapAttrs mkHost {
        desktopl = {
          channel = unstable;
          modules = [ ./desktop.nix ./hardware-configuration/desktop.nix ];
          home    = ./home/desktop.nix;
        };
        homelab = {
          channel = stable;
          modules = [ ./server.nix ./hardware-configuration/server.nix ];
          home    = ./home/server.nix;
        };
        work = {
          channel = stable;
          modules = [ ./work.nix ./hardware-configuration/work.nix ];
          home    = ./home/work.nix;
        };
        wsl = {
          channel = stable;
          modules = [ nixos-wsl.nixosModules.default ./wsl.nix ];
          home    = ./home/wsl.nix;
        };
      };
    };
}
