{ config, pkgs, ... }:
let
  net = import ../../lib/network.nix;
in
{
  imports = [
    ./hardware.nix
    ./edge.nix
    ./metrics.nix
    ./status.nix
    ./ntfy.nix
    ./vpn-relay.nix
    ./vpn-exit.nix
    ./crowdsec.nix
  ];

  # Boots via SeaBIOS (EF02 partition); the ESP is kept so a switch to UEFI just works.
  # disko sets boot.loader.grub.devices from the EF02 partition.
  boot.loader.grub = { enable = true; efiSupport = true; efiInstallAsRemovable = true; };

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "ipv4";
    address = [ "${net.vps.ipv6}/64" ];
    routes = [ { Gateway = "2607:5300:205:200::1"; GatewayOnLink = true; } ];
  };

  services.openssh = {
    enable = true;
    settings = {
      # keys only, for every user (bots try ~75 password guesses an hour); seb's password
      # still works for sudo and the OVH console
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  sops.secrets = {
    seb-password.neededForUsers = true;
    root-password.neededForUsers = true;
  };
  # passwords come only from sops: `passwd` changes are reverted on the next activation
  users.mutableUsers = false;
  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.seb-password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/ue3htKr0j2gAjPxg38E8UB/NYegnR3rr3R9Zhj7MP seb@desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIb8DukSl7cKWd80kIYsMal4GGA9i/RVP/7PHp5Ko+i0 seb@wsl"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5w4aOQVRSBeNk3Z0ei0POMMQBmHb6EAoDMswNluupK backup"
    ];
  };
  # root's password is for the emergency shell (sulogin) only; SSH never accepts it
  users.users.root.hashedPasswordFile = config.sops.secrets.root-password.path;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIb8DukSl7cKWd80kIYsMal4GGA9i/RVP/7PHp5Ko+i0 seb@wsl"
    # temporary: remove once seb's sops password is proven to work for sudo
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/ue3htKr0j2gAjPxg38E8UB/NYegnR3rr3R9Zhj7MP seb@desktop"
  ];

  boot.loader.grub.configurationLimit = 10;
  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
