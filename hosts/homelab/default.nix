{ config, lib, pkgs, ... }:
let
  net = import ../../lib/network.nix;
  wgv = net.wgVps;
in
{
  imports = [
    ./hardware.nix
    ./bulk-consolidate.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
    ../../modules/smart.nix
  ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  # Opens everything that listened on 2026-11-15, so LAN and wg-home reach exactly what they did.
  # Trap: Docker-published ports are DNATed through FORWARD and never hit these rules; removing
  # one here does not close it (bind it to 127.0.0.1 in compose, or filter in DOCKER-USER).
  networking.firewall =
    let
      lanAndVpn = {
        allowedTCPPorts = [
          22 # sshd
          53 # pi-hole DNS
          8096 # jellyfin
          8200 # transmission container
          9091 # transmission RPC
          9100 # node-exporter
          18888 # vcclient
          24004 # pi-hole web
          24006 # phpldapadmin
          24020 # radarr
          24021 # prowlarr
          24022 # sonarr
          24024 # bazarr
          24026 # jellyseerr
          24030 # grafana
          24031 # victoriametrics
          24080 # caddy http
          net.homelab.caddyPort
        ];
        allowedUDPPorts = [
          53 # pi-hole DNS
          123 # pi-hole NTP
          net.homelab.caddyPort # caddy HTTP/3
          net.homelab.wgHomePort
        ];
      };
    in
    {
      enable = true;
      # containers reach host-network services (pi-hole DNS, node-exporter) and docker-proxy hairpins
      trustedInterfaces = [ "docker0" "br-+" ];
      # never ran with rpfilter; wg-home and the VPS relay were only tested without it
      checkReversePath = false;
      interfaces = {
        ${net.homelab.lanInterface} = lanAndVpn;
        wg-home = lanAndVpn;
        # mirrors wg-vps-in; wg-vps's own outer UDP has no fixed port and passes as ESTABLISHED
        # because the homelab always dials out with a keepalive
        wg-vps = {
          allowedTCPPorts = [ net.homelab.caddyPort ];
          allowedUDPPorts = [ net.homelab.wgHomePort ];
        };
      };
    };

  networking.networkmanager.enable = false;
  networking.useDHCP = false;

  networking.interfaces.${net.homelab.lanInterface} = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = net.homelab.lanIp;
        inherit (net.lan) prefixLength;
      }
    ];
  };

  networking.defaultGateway = {
    address = net.lan.gateway;
    interface = net.homelab.lanInterface;
  };

  networking.wireguard.interfaces.wg-home = {
    ips = [ "${net.roaming.homelabIp}/${toString net.roaming.prefixLength}" ];
    listenPort = net.homelab.wgHomePort;
    # clients arrive relayed through the VPS (hosts/vps/vpn-relay.nix), i.e. WireGuard inside
    # WireGuard; 1280 leaves room for both headers on any network
    mtu = 1280;
    # if missing a fresh key is generated and every peer must be reconfigured
    privateKeyFile = "/var/lib/wireguard/wg-home.key";
    generatePrivateKeyFile = true;
    # the VPS exit (hosts/vps/vpn-exit.nix) knows the same clients by the same IPs
    peers = map (c: {
      inherit (c) publicKey;
      allowedIPs = [ "${c.ip}/32" ];
    }) net.roaming.clients;
  };

  # Tunnel to the VPS edge (hosts/vps/edge.nix). We dial out to its fixed IP, so a new home
  # IP needs no reporting and no port forward. The VPS is treated as untrusted: the wg-vps-in
  # chain lets it open connections only to Caddy (10.8.0.2:24443, the caddy container's
  # published 443, which also demands the VPS client cert) and to the relayed wg-home VPN
  # port (51821/udp), never to other ports here or to the LAN. It sits in mangle PREROUTING
  # so it runs before Docker's DNAT and before routing/forwarding.
  networking.wireguard.interfaces.wg-vps = {
    ips = [ "${wgv.homelab.ip}/${toString wgv.prefixLength}" ];
    # if missing a fresh key is generated and the VPS peer must be updated
    privateKeyFile = "/var/lib/wireguard/wg-vps.key";
    generatePrivateKeyFile = true;
    peers = [
      {
        inherit (wgv.vps) publicKey;
        endpoint = "${net.vps.ipv4}:${toString wgv.port}";
        allowedIPs = [ "${wgv.vps.ip}/32" ];
        persistentKeepalive = 25;
      }
    ];
    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t mangle -N wg-vps-in 2>/dev/null || ${pkgs.iptables}/bin/iptables -t mangle -F wg-vps-in
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -d ${wgv.homelab.ip} -p tcp --dport ${toString net.homelab.caddyPort} -m conntrack --ctstate NEW -j RETURN
      # relayed wg-home VPN clients; WireGuard drops anything not signed by a client key
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -d ${wgv.homelab.ip} -p udp --dport ${toString net.homelab.wgHomePort} -m conntrack --ctstate NEW -j RETURN
      ${pkgs.iptables}/bin/iptables -t mangle -A wg-vps-in -j DROP
      ${pkgs.iptables}/bin/iptables -t mangle -C PREROUTING -i wg-vps -j wg-vps-in 2>/dev/null || \
        ${pkgs.iptables}/bin/iptables -t mangle -I PREROUTING -i wg-vps -j wg-vps-in
    '';
    # the chain stays in place while the interface is down; nothing can arrive on it then
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg-home" ];
    externalInterface = net.homelab.lanInterface;
    extraCommands = ''
      iptables -C FORWARD -i wg-home -o ${net.homelab.lanInterface} -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i wg-home -o ${net.homelab.lanInterface} -j ACCEPT
      iptables -C FORWARD -i ${net.homelab.lanInterface} -o wg-home -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i ${net.homelab.lanInterface} -o wg-home -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };

  networking.nameservers = [ net.homelab.lanIp ];

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

  sops.secrets = {
    seb-password.neededForUsers = true;
    root-password.neededForUsers = true;
  };
  # passwords come only from sops: `passwd` changes are reverted on the next activation
  users.mutableUsers = false;
  users.users.seb = {
    extraGroups = [ "docker" ];
    linger = true;
    initialPassword = lib.mkForce null;
    hashedPasswordFile = config.sops.secrets.seb-password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/ue3htKr0j2gAjPxg38E8UB/NYegnR3rr3R9Zhj7MP seb@desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIb8DukSl7cKWd80kIYsMal4GGA9i/RVP/7PHp5Ko+i0 seb@wsl"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5w4aOQVRSBeNk3Z0ei0POMMQBmHb6EAoDMswNluupK backup"
    ];
  };
  # root's password is for the emergency shell (sulogin) only; SSH never accepts it
  users.users.root.hashedPasswordFile = config.sops.secrets.root-password.path;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  # deployed from WSL as seb (--target-host), whose locally built paths are unsigned; seb has
  # sudo here already, so this grants nothing new
  nix.settings.trusted-users = [ "root" "seb" ];

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11";
}

