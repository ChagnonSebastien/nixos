{ lib, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
    ../../modules/smart.nix
  ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  networking.firewall.enable = false;

  networking.networkmanager.enable = false;
  networking.useDHCP = false;

  networking.interfaces.enp42s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "192.168.0.2";
        prefixLength = 24;
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

  networking.nameservers = [ "192.168.0.2" ];

  virtualisation.docker = {
    enable = true;

    daemon.settings.features.cdi = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--filter" "until=168h" ];
    };
  };

  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/media/hdd-1" ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "Tue *-*-01..07 02:00:00";
  };

  # module default AccuracySec=1d lets the scrub start up to a day late
  systemd.timers = lib.genAttrs [
    "btrfs-scrub-media-hdd\\x2d1"
    "btrfs-scrub-media-bulk\\x2dseagate"
    "btrfs-scrub-media-important"
  ] (_: { timerConfig.AccuracySec = lib.mkForce "1min"; });

  # nixpkgs only sets Requires=, so GPU containers race the CDI spec and die
  systemd.services.docker.after = [ "nvidia-container-toolkit-cdi-generator.service" ];

  users.users.seb = {
    extraGroups = [ "docker" "k3s" ];
    linger = true;
  };

  services.openssh.enable = true;

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11";
}

