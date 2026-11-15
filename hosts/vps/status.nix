# status.chagnon.dev: Gatus status page, served by the VPS itself so it stays up when the
# homelab or the tunnel is down. Service checks go through the public URLs (VPS Caddy →
# wg-vps → homelab Caddy → app), i.e. exactly what a visitor gets; the Server check tells
# a tunnel outage apart from a single service being down. Names are for end users.
{ ... }:
let
  siteIn = group: name: url: conditions: {
    inherit group name url;
    interval = "1m";
    conditions = conditions ++ [ "[RESPONSE_TIME] < 5000" ];
  };
  site = siteIn "Services";
in
{
  services.gatus = {
    enable = true;
    settings = {
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
        # "Server online" first and full width, in both the flat and the grouped view.
        custom-css = ''
          .grid > .endpoint:has([title="Server online"]) { order: -1; grid-column: 1 / -1; }
          .endpoint:has([title="Server online"]) .endpoint-header .text-muted-foreground { display: none; }
          .space-y-6:has(> .endpoint-group) { display: flex; flex-direction: column; gap: 1.5rem; }
          .space-y-6 > .endpoint-group { margin-top: 0 !important; }
          .endpoint-group:has([title="Server online"]) { order: -1; }
          /* flat view: Gatus puts suites in their own section; fold both sections into one grid */
          div:has(> div > .grid > .suite) { display: grid; gap: 0.75rem; grid-template-columns: minmax(0, 1fr); }
          @media (min-width: 640px) { div:has(> div > .grid > .suite) { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
          @media (min-width: 1024px) { div:has(> div > .grid > .suite) { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
          div:has(> div > .grid > .suite) > div, div:has(> div > .grid > .suite) > div > .grid { display: contents; }
          div:has(> div > .grid > .suite) > div > h2, .endpoint-group-content h3 { display: none; }
        '';
      };
      endpoints = [
        {
          # the wg-vps tunnel to the homelab Caddy; when this is down, every service is
          name = "Server online";
          group = "Server";
          url = "tcp://10.8.0.2:24443";
          interval = "30s";
          conditions = [ "[CONNECTED] == true" ];
        }

        (site "Authentication services" "https://auth.chagnon.dev/realms/master" [ "[STATUS] == 200" "[BODY].realm == master" ])
        (site "Fintrospect" "https://fintrospect.chagnon.dev/" [ "[STATUS] == 200" ])
        (site "Immich" "https://immich.chagnon.dev/api/server/ping" [ "[STATUS] == 200" "[BODY].res == pong" ])
        (site "Office" "https://office.chagnon.dev/status.php" [ "[STATUS] == 200" "[BODY].maintenance == false" ])
        (site "Vault" "https://vault.chagnon.dev/alive" [ "[STATUS] == 200" ])
      ];
      # One card for Sebflix and its request site: red if either check fails.
      suites = [
        {
          name = "Sebflix";
          group = "Services";
          interval = "1m";
          endpoints = [
            (removeAttrs (site "Streaming" "https://sebflix.chagnon.dev/health" [ "[STATUS] == 200" "[BODY] == Healthy" ]) [ "group" "interval" ])
            (removeAttrs (site "Requests" "https://jellyseerr.chagnon.dev/api/v1/status" [ "[STATUS] == 200" ]) [ "group" "interval" ])
          ];
        }
      ];
    };
  };

  services.caddy.virtualHosts."status.chagnon.dev".extraConfig = ''
    reverse_proxy 127.0.0.1:8080
  '';

  # served locally, not from the homelab: DNS only, not in edge.nix's homelabHosts
  services.cloudflare-dyndns.domains = [ "status.chagnon.dev" ];
}
