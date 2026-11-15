# Metrics for the homelab's VictoriaMetrics, which scrapes them through wg-vps.
# Pull, not push: the homelab opens the connection, so its wg-vps-in filter stays
# "VPS may only reach Caddy". These ports are opened on wg-vps only, never publicly.
#
#   10.8.0.1:9100  node_exporter (CPU, memory, disk, per-interface traffic incl. wg-vps)
#   10.8.0.1:9180  Caddy per-host HTTP metrics (own listener: the admin API on :2019
#                  can rewrite the config, so it stays on localhost)
{ ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    # binds 0.0.0.0 so it doesn't depend on wg-vps being up first; the firewall scopes it
    openFirewall = false;
    enabledCollectors = [ "systemd" ];
  };

  services.caddy = {
    globalConfig = ''
      metrics {
        per_host
      }
    '';
    virtualHosts."http://:9180".extraConfig = ''
      metrics
    '';
  };

  networking.firewall.interfaces.wg-vps.allowedTCPPorts = [ 9100 9180 ];
}
