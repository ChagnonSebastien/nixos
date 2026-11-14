{ lib, ... }:
let
  envFile = "/var/lib/nm-vpn/wireguard.env";

  wireguard =
    {
      id,
      keyVar,
      publicKey,
      endpoint,
      dns,
      dnsPriority ? 0,
      autoconnect ? false,
    }:
    {
      connection = {
        inherit id;
        type = "wireguard";
        interface-name = id;
        autoconnect = lib.boolToString autoconnect;
      };
      wireguard.private-key = "$" + keyVar;
      "wireguard-peer.${publicKey}" = {
        inherit endpoint;
        allowed-ips = "0.0.0.0/0;::/0;";
        persistent-keepalive = 25;
      };
      ipv4 = {
        method = "manual";
        address1 = "10.2.0.2/32";
        inherit dns;
        dns-priority = dnsPriority;
        dns-search = "~;";
        ignore-auto-dns = "true";
      };
      ipv6.method = "disabled";
    };

  profiles = {
    canada = wireguard {
      id = "canada";
      keyVar = "CANADA_WG_KEY";
      publicKey = "szjIaWj1+sWfmmap7eqtkgHDPl/y8HLHt+eeNbl/0w0=";
      endpoint = "139.28.218.2:51820";
      dns = "1.1.1.1;9.9.9.9;";
      dnsPriority = -42;
      autoconnect = true;
    };
    iceland = wireguard {
      id = "iceland";
      keyVar = "ICELAND_WG_KEY";
      publicKey = "yKbYe2XwbeNN9CuPZcwMF/lJp6a62NEGiHCCfpfxrnE=";
      endpoint = "185.159.158.1:51820";
      dns = "192.168.0.2;10.2.0.1;";
    };
    usa = wireguard {
      id = "usa";
      keyVar = "USA_WG_KEY";
      publicKey = "XeVyTJgexTGQ6w9xmiosAH6w86n8d7QKs3NBzU0Ze3k=";
      endpoint = "149.88.21.1:51820";
      dns = "192.168.0.2;10.2.0.1;";
    };
  };
in
{
  # Profiles live in /run: `nmcli con modify` forks a persistent duplicate, change them here.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ envFile ];
    profiles = profiles // {
      wired = {
        connection = {
          id = "wired";
          type = "ethernet";
          interface-name = "enp0s31f6";
        };
        ipv4 = {
          method = "auto";
          # 192.168.0.2 serves DNS to iceland/usa and must stay out of the full tunnels.
          route1 = "192.168.0.0/24,192.168.1.1";
        };
        ipv6.method = "auto";
      };
    };
  };

  systemd.services.NetworkManager-ensure-profiles.preStart = lib.concatMapStrings (p: ''
    : "''${${lib.removePrefix "$" p.wireguard.private-key}:?missing from ${envFile}}"
  '') (lib.attrValues profiles);
}
