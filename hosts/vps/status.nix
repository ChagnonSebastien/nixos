# status.chagnon.dev: Gatus status page, served by the VPS itself so it stays up when the
# homelab or the tunnel is down. Service checks go through the public URLs (VPS Caddy →
# wg-vps → homelab Caddy → app), i.e. exactly what a visitor gets; the Server check tells
# a tunnel outage apart from a single service being down. Names are for end users.
{ config, lib, ... }:
let
  net = import ../../lib/network.nix;

  # Shown in this order (Gatus itself only sorts by name/group/health; CSS reorders).
  services = [
    { name = "Authentication services"; url = "https://auth.chagnon.dev/realms/master"; conditions = [ "[STATUS] == 200" "[BODY].realm == master" ]; }
    { name = "Sebflix"; url = "https://sebflix.chagnon.dev/health"; conditions = [ "[STATUS] == 200" "[BODY] == Healthy" ]; }
    { name = "Jellyseerr"; url = "https://jellyseerr.chagnon.dev/api/v1/status"; conditions = [ "[STATUS] == 200" ]; }
    { name = "Immich"; url = "https://immich.chagnon.dev/api/server/ping"; conditions = [ "[STATUS] == 200" "[BODY].res == pong" ]; }
    { name = "Office"; url = "https://office.chagnon.dev/status.php"; conditions = [ "[STATUS] == 200" "[BODY].maintenance == false" ]; }
    { name = "Fintrospect"; url = "https://fintrospect.chagnon.dev/"; conditions = [ "[STATUS] == 200" ]; }
    { name = "Vault"; url = "https://vault.chagnon.dev/alive"; conditions = [ "[STATUS] == 200" ]; }
  ];

  orderCss = lib.concatImapStrings (i: s: ''
    .grid > .endpoint:has([title="${s.name}"]) { order: ${toString i}; }
  '') services;
in
{
  sops.templates.gatus-env.content = ''
    NTFY_ALERT_TOKEN=${config.sops.placeholder.ntfy-alert-token}
  '';

  services.gatus = {
    enable = true;
    environmentFile = config.sops.templates.gatus-env.path;
    settings = {
      alerting.ntfy = {
        url = "http://127.0.0.1:2586";
        topic = "alerts";
        token = "$NTFY_ALERT_TOKEN";
        priority = 4;
        click = "https://status.chagnon.dev";
        default-alert = {
          failure-threshold = 3;
          success-threshold = 2;
          send-on-resolved = true;
        };
      };
      web = {
        address = "127.0.0.1";
        port = 8080;
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
      };
      ui = {
        title = "SebSuite status";
        header = "SebSuite status";
        dashboard-heading = "Service status";
        dashboard-subheading = "Live status of SebSuite services. If the server is offline, every service is.";
        # "Server online" first and full width, then the services in the order above,
        # in both the flat and the grouped view.
        custom-css = ''
          .grid > .endpoint:has([title="Server online"]) { order: -1; grid-column: 1 / -1; }
          .endpoint:has([title="Server online"]) .endpoint-header .text-muted-foreground { display: none; }
          .space-y-6:has(> .endpoint-group) { display: flex; flex-direction: column; gap: 1.5rem; }
          .space-y-6 > .endpoint-group { margin-top: 0 !important; }
          .endpoint-group:has([title="Server online"]) { order: -1; }
        '' + orderCss;
      };
      endpoints = [
        {
          # the wg-vps tunnel to the homelab Caddy; when this is down, every service is
          name = "Server online";
          group = "Server";
          url = "tcp://${net.wgVps.homelab.ip}:${toString net.homelab.caddyPort}";
          interval = "30s";
          conditions = [ "[CONNECTED] == true" ];
          # the only alert: services fail with it during a tunnel outage, and Gatus cannot suppress them
          alerts = [ { type = "ntfy"; } ];
        }
      ] ++ map (s: {
        inherit (s) name url;
        group = "Services";
        interval = "1m";
        conditions = s.conditions ++ [ "[RESPONSE_TIME] < 5000" ];
      }) services;
    };
  };

  services.caddy.virtualHosts."status.chagnon.dev".extraConfig = ''
    reverse_proxy 127.0.0.1:8080
  '';

  # served locally, not from the homelab: DNS only, not in edge.nix's homelabHosts
  services.cloudflare-dyndns.domains = [ "status.chagnon.dev" ];
}
