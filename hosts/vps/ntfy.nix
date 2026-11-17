# ntfy.chagnon.dev: push notifications, served by the VPS itself like status.nix so alerts
# still go out when the homelab or the tunnel is down.
#
# Users, tokens and topic ACLs are declarative, from the ntfy-env sops secret:
#   NTFY_AUTH_USERS=seb:<bcrypt from `ntfy user hash`>:admin
#   NTFY_AUTH_TOKENS=seb:tk_<29 chars>:homelab
#   NTFY_AUTH_ACCESS=<user>:<topic>:rw   (only for non-admin users)
# ntfy-alert-token is one of those tokens, alone, for the VPS's own alerts to the `alerts` topic.
{ config, ... }:
let
  port = 2586;
in
{
  sops.secrets.ntfy-env = { };
  sops.secrets.ntfy-alert-token = { };

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.secrets.ntfy-env.path;
    settings = {
      base-url = "https://ntfy.chagnon.dev";
      listen-http = "127.0.0.1:${toString port}";
      behind-proxy = true;
      auth-default-access = "deny-all";
    };
  };

  services.caddy.virtualHosts."ntfy.chagnon.dev".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString port}
  '';

  # served locally, not from the homelab: DNS only, not in edge.nix's homelabHosts
  services.cloudflare-dyndns.domains = [ "ntfy.chagnon.dev" ];
}
