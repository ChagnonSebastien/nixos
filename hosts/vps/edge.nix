# Public edge for the homelab, replacing the Cloudflare proxy.
#
#   visitor ──https──▶ VPS Caddy ──https + client cert, inside wg-vps──▶ homelab Caddy (:24443)
#
# - The homelab dials wg-vps out to this VPS's fixed IP and keeps it alive, so a new home
#   IP is picked up by WireGuard roaming; nothing has to report it.
# - VPS Caddy terminates TLS (like Cloudflare did) so it can set CF-Connecting-IP etc.,
#   then re-encrypts to the homelab presenting a client cert from the private CA below.
#   The homelab Caddy trusts only that CA (its `cloudflare_only` snippet, pointed at our CA).
# - cloudflare-dyndns keeps the DNS records pointed at this VPS, unproxied.
{ lib, pkgs, ... }:
let
  # From the homelab: `sudo wg show wg-vps public-key`.
  homelabPublicKey = "vNdn2qkQn0asTzWtiy9NtNwAon8VxyCGHqkb2P+SXwg=";

  originPullDir = "/var/lib/origin-pull";

  # Hosts served through the homelab; each must also exist in the homelab Caddyfile.
  homelabHosts = [ "example.chagnon.dev" ];
in
{
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 51820 ];
  };

  networking.wireguard.interfaces.wg-vps = {
    ips = [ "10.8.0.1/24" ];
    listenPort = 51820;
    # generated on the VPS; the homelab config pins its public key
    privateKeyFile = "/var/lib/wireguard/wg-vps.key";
    peers = lib.optional (homelabPublicKey != null) {
      publicKey = homelabPublicKey;
      allowedIPs = [ "10.8.0.2/32" ];
      # no endpoint: the homelab dials in, and its address may change
    };
  };

  # Private CA + client cert the VPS presents to the homelab Caddy (Cloudflare's
  # "authenticated origin pull", self-hosted). Generated once; copy ca.pem to the homelab.
  systemd.services.origin-pull-cert = {
    description = "Generate the client certificate VPS Caddy presents to the homelab";
    wantedBy = [ "multi-user.target" ];
    before = [ "caddy.service" ];
    path = [ pkgs.openssl ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "origin-pull";
      UMask = "0077";
    };
    script = ''
      cd ${originPullDir}
      [ -s client.pem ] && exit 0
      openssl req -x509 -new -noenc -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout ca.key -out ca.pem -days 3650 -subj "/CN=vps origin pull CA" \
        -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
      openssl req -new -noenc -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
        -keyout client.key -out client.csr -subj "/CN=vps"
      openssl x509 -req -in client.csr -CA ca.pem -CAkey ca.key -CAcreateserial \
        -out client.pem -days 3650 -extfile <(printf '%s\n' \
          "basicConstraints=CA:FALSE" "keyUsage=critical,digitalSignature" "extendedKeyUsage=clientAuth")
      rm client.csr
      chmod 644 ca.pem client.pem
      chown caddy:caddy client.key
    '';
  };

  services.caddy = {
    enable = true;
    email = "sebastien.chagnon@proton.me";
    extraConfig = ''
      (homelab) {
        # host port 24443 is the caddy container's 443
        reverse_proxy https://10.8.0.2:24443 {
          # Same visitor-IP headers Cloudflare sent; `header_up` overwrites any the visitor supplies.
          # X-Forwarded-For/-Proto/-Host are set by Caddy itself.
          # Caddy defaults Host to the upstream address for HTTPS upstreams; the homelab
          # Caddy routes on Host and returns 421 when it differs from the SNI.
          header_up Host {http.request.host}
          header_up CF-Connecting-IP {remote_host}
          header_up X-Real-IP {remote_host}
          transport http {
            # SNI = requested host, so the homelab picks and we verify the right certificate
            tls_server_name {http.request.host}
            tls_client_auth ${originPullDir}/client.pem ${originPullDir}/client.key
          }
        }
      }
    '';
    virtualHosts = lib.genAttrs homelabHosts (_: { extraConfig = "import homelab"; });
  };
  systemd.services.caddy = {
    requires = [ "origin-pull-cert.service" ];
    after = [ "origin-pull-cert.service" ];
  };

  services.cloudflare-dyndns = {
    enable = true;
    # Cloudflare API token with Zone → DNS → Edit on chagnon.dev; just the token, root-only.
    apiTokenFile = "/var/lib/secrets/cloudflare-api-token";
    domains = homelabHosts;
    proxied = false;
    ipv4 = true;
    ipv6 = true;
  };
}
