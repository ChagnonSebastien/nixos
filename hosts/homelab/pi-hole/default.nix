{ config, lib, ... }:
let
  # paths must match the file:// adlist rows in gravity.db, which scope allow/<device> to its group
  lists = [
    "general"
    "allow/tv"
    "allow/phone"
    "allow/guest"
    "allow/work"
    "allow/desktop"
  ];
in
{
  environment.etc = lib.listToAttrs (map (name:
    lib.nameValuePair "pihole-lists/${name}.txt" { source = ./. + "/${name}.txt"; }) lists);

  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        port = 5335;
        access-control = [ "127.0.0.0/8 allow" ];
        do-ip6 = false;
        hide-identity = true;
        hide-version = true;
        prefetch = true;
        serve-expired = true;
        cache-min-ttl = 60;
        tls-cert-bundle = "/etc/ssl/certs/ca-certificates.crt";
      };
      forward-zone = [{
        name = ".";
        forward-tls-upstream = true;
        forward-addr = [
          "9.9.9.9@853#dns.quad9.net"
          "149.112.112.112@853#dns.quad9.net"
          "1.1.1.1@853#cloudflare-dns.com"
          "1.0.0.1@853#cloudflare-dns.com"
        ];
      }];
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [ 24004 ];
  };

  services.pihole-ftl = {
    enable = true;
    settings = {
      dns = {
        upstreams = [ "127.0.0.1#5335" ];
        listeningMode = "ALL";
        bogusPriv = false;
        domain.name = "home.arpa";
        cache.optimizer = -1;
        reply.host.force4 = true;
      };
      webserver = {
        interface.theme = "default-darker";
        headers = [
          "Content-Security-Policy: default-src 'self' 'unsafe-inline';"
          "X-Frame-Options: DENY"
          "X-XSS-Protection: 0"
          "X-Content-Type-Options: nosniff"
          "Referrer-Policy: strict-origin-when-cross-origin"
        ];
      };
    };
  };

  sops.secrets.pihole-web-password = { };
  sops.secrets.pihole-dns-hosts = { };
  sops.templates.pihole-ftl-env = {
    content = ''
      FTLCONF_webserver_api_password="${config.sops.placeholder.pihole-web-password}"
      FTLCONF_dns_hosts="${config.sops.placeholder.pihole-dns-hosts}"
    '';
    restartUnits = [ "pihole-ftl.service" ];
  };

  systemd.services.pihole-ftl = {
    wants = [ "unbound.service" ];
    after = [ "unbound.service" ];
    serviceConfig.EnvironmentFile = config.sops.templates.pihole-ftl-env.path;
  };

  # the module never refreshes remote adlists
  systemd.services.pihole-gravity = {
    description = "Pi-hole gravity update";
    after = [ "pihole-ftl.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.services.pihole-ftl.user;
      Group = config.services.pihole-ftl.group;
      ExecStart = "${lib.getExe config.services.pihole-ftl.piholePackage} -g";
    };
  };
  systemd.timers.pihole-gravity = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 04:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}
