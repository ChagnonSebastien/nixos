# Addresses and keys that more than one host config needs. Each WireGuard key is generated
# on its host (privateKeyFile) and must be copied here by hand when it changes.
{
  lan = {
    gateway = "192.168.0.1";
    prefixLength = 24;
  };

  homelab = {
    lanInterface = "enp42s0";
    lanIp = "192.168.0.2";
    # host port of the caddy container's 443
    caddyPort = 24443;
    wgHomePort = 51821;
  };

  vps = {
    ipv4 = "198.245.55.120";
    ipv6 = "2607:5300:205:200::fccc";
    wanInterface = "ens3";
  };

  wgVps = {
    port = 51820;
    subnet = "10.8.0.0/24";
    prefixLength = 24;
    vps = {
      ip = "10.8.0.1";
      # on the VPS: `sudo wg show wg-vps public-key`
      publicKey = "/02pfCsNoefcrrg7Rl1R9mhmElz8OkhyOxNFL80d1C4=";
    };
    homelab = {
      ip = "10.8.0.2";
      # on the homelab: `sudo wg show wg-vps public-key`
      publicKey = "vNdn2qkQn0asTzWtiy9NtNwAon8VxyCGHqkb2P+SXwg=";
    };
  };
}
