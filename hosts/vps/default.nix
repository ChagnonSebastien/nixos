{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./edge.nix
    ./metrics.nix
    ./status.nix
    ./vpn-relay.nix
    ./crowdsec.nix
  ];

  # Boots via SeaBIOS (EF02 partition); the ESP is kept so a switch to UEFI just works.
  # disko sets boot.loader.grub.devices from the EF02 partition.
  boot.loader.grub = { enable = true; efiSupport = true; efiInstallAsRemovable = true; };

  networking.hostName = "vps";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "ipv4";
    address = [ "2607:5300:205:200::fccc/64" ];
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
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIb8DukSl7cKWd80kIYsMal4GGA9i/RVP/7PHp5Ko+i0 seb@vps"
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Every deploy adds a system generation; without this the store only ever grows.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  boot.loader.grub.configurationLimit = 10;
  environment.systemPackages = with pkgs; [ git vim ];

  system.stateVersion = "26.05";
}
