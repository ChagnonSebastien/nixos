{ ... }:
let
  net = import ../../lib/network.nix;
  r = net.roaming;
  wan = "enp0s31f6";
  ifname = "vps-exit";
  lanSubnets = [ "192.168.0.0/24" "192.168.1.0/24" ];
in
{
  networking.wg-quick.interfaces.${ifname} = {
    address = [ "${r.desktop.ip}/32" ];
    mtu = 1420;
    # installed by hand; a generated key would not match the peer the VPS pins
    privateKeyFile = "/var/lib/wireguard/${ifname}.key";
    peers = [
      {
        publicKey = r.exitPublicKey;
        endpoint = "${net.vps.ipv4}:${toString r.exitPort}";
        allowedIPs = [ "0.0.0.0/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # Profiles live in /run: `nmcli con modify` forks a persistent duplicate, change them here.
  networking.networkmanager.ensureProfiles.profiles.wired = {
    connection = {
      id = "wired";
      type = "ethernet";
      interface-name = wan;
    };
    ipv4 = {
      method = "auto";
      # 192.168.0.2 (homelab) sits behind the router; the main-table /24 wins over the tunnel
      route1 = "192.168.0.0/24,192.168.1.1";
      dns = "${net.homelab.lanIp};";
      ignore-auto-dns = "true";
    };
    # the exit is IPv4 only
    ipv6.method = "disabled";
  };

  # Kill switch: off the LAN, only the tunnel's own UDP may leave the wire.
  networking.firewall.extraCommands = ''
    iptables -N vpn-killswitch 2>/dev/null || iptables -F vpn-killswitch
    ${builtins.concatStringsSep "\n" (map (s: "iptables -A vpn-killswitch -d ${s} -j RETURN") lanSubnets)}
    iptables -A vpn-killswitch -d 224.0.0.0/4 -j RETURN
    iptables -A vpn-killswitch -d 255.255.255.255 -j RETURN
    iptables -A vpn-killswitch -d ${net.vps.ipv4} -p udp --dport ${toString r.exitPort} -j RETURN
    iptables -A vpn-killswitch -j REJECT --reject-with icmp-net-unreachable
    iptables -C OUTPUT -o ${wan} -j vpn-killswitch 2>/dev/null || iptables -I OUTPUT -o ${wan} -j vpn-killswitch

    ip6tables -C OUTPUT -o ${wan} -j REJECT 2>/dev/null || ip6tables -I OUTPUT -o ${wan} -j REJECT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D OUTPUT -o ${wan} -j vpn-killswitch 2>/dev/null || true
    ip6tables -D OUTPUT -o ${wan} -j REJECT 2>/dev/null || true
  '';
}
