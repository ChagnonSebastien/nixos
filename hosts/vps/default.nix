{ pkgs, ... }:
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
  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/ue3htKr0j2gAjPxg38E8UB/NYegnR3rr3R9Zhj7MP seb@DesktopL"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIb8DukSl7cKWd80kIYsMal4GGA9i/RVP/7PHp5Ko+i0 seb@vps"
  ];

  boot.loader.grub.configurationLimit = 10;
  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
