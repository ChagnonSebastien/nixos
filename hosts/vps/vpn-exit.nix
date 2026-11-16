# VPN exit for the roaming clients (lib/network.nix `roaming`):
#
#   phone ──WireGuard──▶ 198.245.55.120:51822 (wg-exit) ──policy route──▶ wg-upstream ──▶ upstream VPN
#   phone ──WireGuard, relayed by vpn-relay.nix──▶ homelab wg-home  (192.168.0.0/24 only)
#
# LAN traffic never decrypts here; internet traffic does, before it enters the upstream VPN.
# vpn-exit.sh keeps wg-upstream on the fastest of `servers`; clients keep their 10.7.0.x and
# are masqueraded behind `address`. Two account keys from the secrets repo's vps.yaml serve
# every server: one for the live tunnel, one for testing candidates. Neither may be used on
# any other device, since a key used twice drops its older connection.
{ config, pkgs, lib, ... }:
let
  net = import ../../lib/network.nix;
  r = net.roaming;
  wan = net.vps.wanInterface;
  table = "51822";
  stateDir = "/var/lib/vpn-exit";

  # the tunnel address the provider assigns to every key
  address = "10.2.0.2";
  # endpoint and public key are in any config downloaded for that server
  servers = [
    { name = "ca-1212"; endpoint = "84.20.16.29:51820"; publicKey = "uUM9J8bziO0yZfsdYoruEfP3m6YuSu+Mek9W/J8mT1Y="; }
    { name = "ca-589"; endpoint = "104.254.95.98:51820"; publicKey = "SFesR+3u5/vyQGeaCSREjs4m2WznwFlWAQ9CE3QSnRg="; }
  ];
  serversFile = pkgs.writeText "vpn-exit-servers" (
    lib.concatMapStrings (s: "${s.name} ${s.endpoint} ${s.publicKey}\n") servers
  );

  vpn-exit = pkgs.writeShellApplication {
    name = "vpn-exit";
    runtimeInputs = with pkgs; [ iproute2 wireguard-tools iputils gawk coreutils ];
    text = builtins.readFile ./vpn-exit.sh;
  };
  env = {
    SERVERS_FILE = serversFile;
    LIVE_KEY = config.sops.secrets.vpn-exit-live-key.path;
    PROBE_KEY = config.sops.secrets.vpn-exit-probe-key.path;
    ADDRESS = address;
    STATE_DIR = stateDir;
    TABLE = table;
    CLIENT_IF = "wg-exit";
    PROBE_TARGET = "1.1.1.1";
  };
in
{
  environment.systemPackages = [ vpn-exit ];

  sops.secrets = {
    wg-exit = { };
    vpn-exit-live-key = { };
    vpn-exit-probe-key = { };
  };

  networking.firewall.allowedUDPPorts = [ r.exitPort ];

  networking.wireguard.interfaces.wg-exit = {
    ips = [ "10.7.0.254/32" ];
    listenPort = r.exitPort;
    mtu = 1420;
    # clients need `sudo wg show wg-exit public-key`
    privateKeyFile = config.sops.secrets.wg-exit.path;
    peers = map (c: {
      inherit (c) publicKey;
      allowedIPs = [ "${c.ip}/32" ];
    }) r.clients;
  };

  networking.firewall.extraCommands = ''
    iptables -t nat -N vpn-exit-post 2>/dev/null || iptables -t nat -F vpn-exit-post
    iptables -t nat -A vpn-exit-post -o wg-upstream -j MASQUERADE
    iptables -t nat -C POSTROUTING -j vpn-exit-post 2>/dev/null || iptables -t nat -A POSTROUTING -j vpn-exit-post

    # inserted first so it runs before vpn-relay-fwd's final DROP
    iptables -N vpn-exit-fwd 2>/dev/null || iptables -F vpn-exit-fwd
    iptables -A vpn-exit-fwd -i wg-exit -o wg-upstream -j ACCEPT
    iptables -A vpn-exit-fwd -i wg-upstream -o wg-exit -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A vpn-exit-fwd -i wg-exit -j DROP
    iptables -A vpn-exit-fwd -o wg-exit -j DROP
    iptables -C FORWARD -j vpn-exit-fwd 2>/dev/null || iptables -I FORWARD -j vpn-exit-fwd

    # strict rpfilter checks replies from the internet against the main table, which routes them
    # via ${wan}; WireGuard already only accepts what the server's key signed
    iptables -t mangle -C PREROUTING -i wg-upstream -j RETURN 2>/dev/null || \
      iptables -t mangle -I PREROUTING -i wg-upstream -j RETURN
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D POSTROUTING -j vpn-exit-post 2>/dev/null || true
    iptables -D FORWARD -j vpn-exit-fwd 2>/dev/null || true
    iptables -t mangle -D PREROUTING -i wg-upstream -j RETURN 2>/dev/null || true
  '';

  systemd.services.vpn-exit = {
    description = "VPN exit interface and routing for roaming clients";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "wireguard-wg-exit.service" ];
    wants = [ "network-online.target" ];
    environment = env;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "vpn-exit";
      StateDirectoryMode = "0700";
      ExecStart = "${vpn-exit}/bin/vpn-exit setup";
      ExecStartPost = "-${vpn-exit}/bin/vpn-exit select";
      ExecStop = "${vpn-exit}/bin/vpn-exit teardown";
    };
  };

  systemd.services.vpn-exit-check = {
    description = "Re-select the VPN exit server when the active one degrades or every 30 min";
    requisite = [ "vpn-exit.service" ];
    after = [ "vpn-exit.service" ];
    environment = env;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${vpn-exit}/bin/vpn-exit check";
    };
  };
  systemd.timers.vpn-exit-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "2min";
      OnBootSec = "2min";
    };
  };
}
