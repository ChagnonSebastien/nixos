# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/shell.nix
    ../../modules/cli-tools.nix
    ../../modules/fonts.nix
    ../../modules/nvidia-gpu.nix
  ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  environment.systemPackages = with pkgs; [
    nvidia-docker
    nvidia-container-toolkit
    libnvidia-container
  ];

  networking.firewall.enable = false;

  networking.networkmanager.enable = false;
  networking.useDHCP = false;

  networking.interfaces.enp42s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "192.168.0.2";  # Replace with your desired static IP
        prefixLength = 24;        # Typically 24 for a 255.255.255.0 netmask
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp42s0";
  };

  networking.wireguard.interfaces.wg-phone = {
    ips = [ "10.7.0.1/24" ];
    listenPort = 51821;
    privateKeyFile = "/var/lib/wireguard/wg-phone.key";
    generatePrivateKeyFile = true;
    peers = [{
      publicKey = "T4pPomAl7cPP/LVBcHvxjzSRqYJb/ZpPxnBlObZ710o=";
      allowedIPs = [ "10.2.0.2/32" ];
    }];
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg-phone" ];
    externalInterface = "enp42s0";
    extraCommands = ''
      iptables -C FORWARD -i wg-phone -o enp42s0 -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i wg-phone -o enp42s0 -j ACCEPT
      iptables -C FORWARD -i enp42s0 -o wg-phone -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i enp42s0 -o wg-phone -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };

  networking.nameservers = [ "192.168.0.2" ];  # Replace with your preferred DNS servers

  virtualisation.docker = {
    enable = true;

    daemon.settings.features.cdi = true;
    rootless = {
      enable = false;
      setSocketVariable = true;
    };

    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--filter" "until=168h" ];
    };

    #extraOptions = "--default-runtime=nvidia";
  };

  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/media/hdd-1" ];

  users.users.seb = {
    extraGroups = [ "docker" ];
    linger = true;
  };

  services.openssh.enable = true;

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11"; # Did you read the comment?

}

