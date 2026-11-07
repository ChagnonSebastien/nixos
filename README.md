# nixos

NixOS + home-manager configuration for all my machines, as a single flake.

## Hosts

| Host       | Channel  | What it is                                          |
|------------|----------|-----------------------------------------------------|
| `desktopl` | unstable | Personal desktop: Hyprland, NVIDIA (legacy_580), Steam |
| `homelab`  | stable   | Home server: static IP, Docker, WireGuard, Pi-hole lists |
| `work`     | stable   | Work laptop: KDE Plasma, NVIDIA, dev tooling        |
| `wsl`      | stable   | NixOS-WSL on Windows: Docker, dev tooling           |

## Usage

The flake attribute name is the hostname, so on an already-installed host:

```sh
sudo nixos-rebuild switch --flake .
```

On a fresh install, or to build another host, name it explicitly:

```sh
sudo nixos-rebuild switch --flake .#<host>
```

Update inputs with `nix flake update`.

## Layout

```
flake.nix              inputs, channels, and mkHost
hosts/<name>/
  default.nix          system config for the host (imports hardware.nix)
  hardware.nix         generated hardware config
  home.nix             home-manager config for seb on that host
modules/               NixOS modules; hosts import what they need
  desktop-environment/ Hyprland, Plasma, COSMIC + shared greetd/pipewire
home/
  modules/             home-manager modules (shell, nvim, git, devtools, ...)
  desktop-environment/ per-desktop home-manager config
```

Every host gets these from `mkHost`:

- **NixOS:** `common.nix`, `shell.nix`, `cli-tools.nix`, `fonts.nix`
- **home-manager:** `shell.nix`, `nvim.nix`, `git.nix`

Each channel (`stable` = nixos-26.05, `unstable` = nixos-unstable) pins nixpkgs,
home-manager and nixvim together, and each host picks one channel.

## Adding a host

1. Create `hosts/<name>/` with `default.nix`, `hardware.nix`
   (from `nixos-generate-config`) and `home.nix`.
2. Add it under `nixosConfigurations` in `flake.nix` with its channel.
3. `git add` the new files (flakes only see tracked files), then rebuild.
