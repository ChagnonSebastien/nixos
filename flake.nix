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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager, home-manager-unstable, nixvim, nixvim-unstable, disko, ... }:
    let
      system = "x86_64-linux";

      unstableOverlay = _final: prev: {
        inherit (import nixpkgs-unstable {
          inherit system;
          inherit (prev) config;
        }) claude-code;
      };

      # Each channel pins nixpkgs, home-manager and nixvim together.
      stable   = {
        inherit nixpkgs home-manager nixvim;
        overlays = [ unstableOverlay ];
      };
      unstable = {
        nixpkgs      = nixpkgs-unstable;
        home-manager = home-manager-unstable;
        nixvim       = nixvim-unstable;
        overlays     = [ ];
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
            { nixpkgs.overlays = channel.overlays; }
            channel.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                sharedModules   = [
                  channel.nixvim.homeModules.nixvim
                  ./home/modules/shell.nix
                  ./home/modules/nvim.nix
                  ./home/modules/git.nix
                ];
                users.seb       = ./hosts/${name}/home.nix;
              };
            }
          ];
        };

      mkMinimal = name: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = extraModules ++ [
            ./modules/base.nix
            ./hosts/${name}
            { networking.hostName = name; }
          ];
        };
    in {
      checks.${system}.bulk-consolidate =
        let pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.runCommand "bulk-consolidate-test" { } ''
          ${pkgs.python3}/bin/python3 -I ${./hosts/homelab/bulk-consolidate-test.py} ${./hosts/homelab/bulk-consolidate.py}
          touch $out
        '';

      nixosConfigurations = builtins.mapAttrs mkHost {
        desktop.channel  = unstable;
        laptop.channel   = unstable;
        homelab.channel  = stable;
        wsl = {
          channel      = stable;
          extraModules = [ nixos-wsl.nixosModules.default ];
        };
      } // builtins.mapAttrs mkMinimal {
        # Deliberately outside mkHost: no home-manager, docker or nvidia, so they stay small.
        vps            = [ disko.nixosModules.disko ];
        homelab-rescue = [ ];
      };
    };
}
