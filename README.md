# nixos

NixOS + home-manager configuration for all my machines, as a single flake.

## Hosts

| Host       | Channel  | What it is                                          |
|------------|----------|-----------------------------------------------------|
| `desktop`  | unstable | Personal desktop: Hyprland, NVIDIA (legacy_580), Steam |
| `laptop`   | unstable | Personal laptop: KDE Plasma, NVIDIA, dev tooling    |
| `homelab`  | stable   | Home server: static IP, Docker, WireGuard, Pi-hole lists |
| `wsl`      | stable   | NixOS-WSL on Windows: Docker, dev tooling           |
| `vps`      | stable   | OVH VPS: minimal, no home-manager, disk layout via disko |

## Usage

The flake attribute name is the hostname, so on an already-installed host:

```sh
sudo nixos-rebuild switch --flake .
```

On a fresh install, or to build another host, name it explicitly:

```sh
sudo nixos-rebuild switch --flake .#<host>
```

`vps` and `homelab` read secrets from the private `nixos-secrets` input, which only `desktop`
and `wsl` can fetch, so deploy them from one of those instead of on the host. Deploys log in as
seb, so the servers only accept closures signed with a key from `deployKeys` in
`lib/network.nix`; a new deploying machine needs
`sudo sh -c 'umask 077; nix key generate-secret --key-name <host>-deploy-1 > /etc/nix/deploy-key.sec'`,
`nix.settings.secret-key-files` pointing at it, and its public half
(`sudo cat /etc/nix/deploy-key.sec | nix key convert-secret-to-public`) in `deployKeys`:

```sh
nixos-rebuild switch --flake .#vps --target-host vps --ask-sudo-password
nixos-rebuild switch --flake .#homelab --target-host homelab --ask-sudo-password
```

Update inputs with `nix flake update`; after committing to `nixos-secrets`, `nix flake update secrets`.

## Secrets

`nixos-secrets` (private) holds sops-encrypted YAML, one file per host, each openable by
two keys: mine (`~/.config/sops/age/keys.txt`, backed up off this machine) and the host's
SSH host key, which sops-nix uses at activation to write the values to `/run`. Edit with
`sops edit <host>.yaml` in that repo; `.sops.yaml` there lists who can open each file. A
reinstalled host has a new host key: put its `ssh-to-age` output in `.sops.yaml`, then
`sops updatekeys <host>.yaml`.

`nix flake check` runs the tests of the homelab's bulk pool consolidator.

## Layout

```
flake.nix              inputs, channels, and mkHost
hosts/<name>/
  default.nix          system config for the host (imports hardware.nix)
  hardware.nix         generated hardware config
  home.nix             home-manager config for seb on that host
modules/               NixOS modules; hosts import what they need
  desktop-environment/ Hyprland, Plasma + shared greetd/pipewire
lib/network.nix        IPs, ports and WireGuard keys shared between hosts
home/
  modules/             home-manager modules (shell, nvim, git, devtools, ...)
  desktop-environment/ per-desktop home-manager config
```

Every `mkHost` host gets these:

- **NixOS:** `common.nix` (which imports `base.nix`), `shell.nix`, `cli-tools.nix`, `fonts.nix`
- **home-manager:** `shell.nix`, `nvim.nix`, `git.nix`

`vps` and `homelab-rescue` use `mkMinimal` instead: only `base.nix` (flakes, nix gc and
store optimisation, timezone) and the hostname, no home-manager.

Each channel (`stable` = nixos-26.05, `unstable` = nixos-unstable) pins nixpkgs,
home-manager and nixvim together, and each host picks one channel.

## Adding a host

1. Create `hosts/<name>/` with `default.nix`, `hardware.nix`
   (from `nixos-generate-config`) and `home.nix`.
2. Add it under `nixosConfigurations` in `flake.nix` with its channel.
3. `git add` the new files (flakes only see tracked files), then rebuild.
