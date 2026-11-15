{ lib, pkgs, ... }:
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

  networking.wireguard.interfaces.wg-home = {
    ips = [ "10.7.0.1/24" ];
    listenPort = 51821;
    # clients arrive relayed through the VPS (hosts/vps/vpn-relay.nix), i.e. WireGuard inside
    # WireGuard; 1280 leaves room for both headers on any network
    mtu = 1280;
    # if missing a fresh key is generated and every peer must be reconfigured
    privateKeyFile = "/var/lib/wireguard/wg-home.key";
    generatePrivateKeyFile = true;
    peers = [
      {
        publicKey = "T4pPomAl7cPP/LVBcHvxjzSRqYJb/ZpPxnBlObZ710o=";
        allowedIPs = [ "10.2.0.2/32" ];
      }
      {
        publicKey = "n90nNFBkbpqHjeHAKSIwZfEiahtkNLzykQwTvS/c8j8=";
        allowedIPs = [ "10.2.0.3/32" ];
      }
    ];
  };

  # Tunnel to the VPS edge (hosts/vps/edge.nix). We dial out to its fixed IP, so a new home
  # IP needs no reporting and no port forward. The VPS is treated as untrusted: the wg-vps-in
  # chain lets it open connections only to Caddy (10.8.0.2:24443, the caddy container's
  # published 443, which also demands the VPS client cert) and to the relayed wg-home VPN
  # port (51821/udp), never to other ports here or to the LAN. It sits in mangle PREROUTING
  # so it runs before Docker's DNAT and before routing/forwarding.
  networking.wireguard.interfaces.wg-vps = {
    ips = [ "10.8.0.2/24" ];
    # if missing a fresh key is generated and the VPS peer must be updated
    privateKeyFile = "/var/lib/wireguard/wg-vps.key";
    generatePrivateKeyFile = true;
    peers = [
      {
        publicKey = "/02pfCsNoefcrrg7Rl1R9mhmElz8OkhyOxNFL80d1C4=";
        endpoint = "198.245.55.120:51820";
        allowedIPs = [ "10.8.0.1/32" ];
        persistentKeepalive = 25;
      }
    ];
    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t mangle -N wg-vps-in 2>/dev/null || ${pkgs.iptables}/bin/iptables -t mangle -F wg-vps-in
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -d 10.8.0.2 -p tcp --dport 24443 -m conntrack --ctstate NEW -j RETURN
      # relayed wg-home VPN clients; WireGuard drops anything not signed by a client key
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -d 10.8.0.2 -p udp --dport 51821 -m conntrack --ctstate NEW -j RETURN
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -j DROP
      ${pkgs.iptables}/bin/iptables -t mangle -C PREROUTING -i wg-vps -j wg-vps-in 2>/dev/null || \
        ${pkgs.iptables}/bin/iptables -t mangle -I PREROUTING -i wg-vps -j wg-vps-in
    '';
    # the chain stays in place while the interface is down; nothing can arrive on it then
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg-home" ];
    externalInterface = "enp42s0";
    extraCommands = ''
      iptables -C FORWARD -i wg-home -o enp42s0 -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i wg-home -o enp42s0 -j ACCEPT
      iptables -C FORWARD -i enp42s0 -o wg-home -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i enp42s0 -o wg-home -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
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

  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/media/bulk-toshiba" "/media/bulk-seagate" "/media/bulk" "/media/important" ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "Tue *-*-01..07 02:00:00";
  };

  # module default AccuracySec=1d lets the scrub start up to a day late
  systemd.timers = lib.genAttrs [
    "btrfs-scrub-media-bulk\\x2dtoshiba"
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

