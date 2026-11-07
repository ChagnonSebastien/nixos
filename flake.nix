{
  description = "Minimal NixOS configuration flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  outputs = { nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager, home-manager-unstable, nixvim, nixvim-unstable, ... }:
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
      # Config lives in hosts/<name>/: default.nix (system, imports its
      # hardware.nix) and home.nix (home-manager for seb).
      # Every host gets the base modules below; hosts import the rest.
      mkHost = name: { channel, extraModules ? [ ] }:
        channel.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = extraModules ++ [
            ./modules/common.nix
            ./modules/shell.nix
            ./modules/cli-tools.nix
            ./modules/fonts.nix
            ./hosts/${name}
            { networking.hostName = name; }
            channel.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [
                  channel.nixvim.homeModules.nixvim
                  ./home/modules/shell.nix
                ];
                users.seb       = ./hosts/${name}/home.nix;
              };
            }
          ];
        };
    in {
      nixosConfigurations = builtins.mapAttrs mkHost {
        desktopl.channel = unstable;
        homelab.channel  = stable;
        work.channel     = stable;
        wsl = {
          channel      = stable;
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      };
    };
}
