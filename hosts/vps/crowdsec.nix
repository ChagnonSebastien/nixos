# CrowdSec in watch mode: reads SSH and Caddy logs and records what it *would* ban
# (`cscli alerts list`, `cscli decisions list` show them as simulated). No bouncer is
# installed and simulation is on, so nothing is ever blocked. Local only: no CAPI
# registration, so no attack data is sent to crowdsec.net and no community blocklist.
# To enforce later: turn simulation off and add services.crowdsec-firewall-bouncer.
{ lib, ... }:
{
  options.services.caddy.virtualHosts = lib.mkOption {
    # Caddy writes access logs 0600; make them group-readable so CrowdSec (in group caddy)
    # can parse them. Same file names as the module default.
    type = lib.types.attrsOf (lib.types.submodule ({ config, ... }: {
      config.logFormat = lib.mkDefault ''
        output file /var/log/caddy/access-${lib.replaceStrings [ "/" " " ] [ "_" "_" ] config.hostName}.log {
          mode 0640
        }
      '';
    }));
  };

  config = {
    services.crowdsec = {
      enable = true;
      hub.collections = [
        "crowdsecurity/linux"
        "crowdsecurity/sshd"
        "crowdsecurity/caddy"
        "crowdsecurity/base-http-scenarios"
        "crowdsecurity/http-cve"
      ];
      localConfig = {
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          {
            filenames = [ "/var/log/caddy/access-*.log" ];
            labels.type = "caddy";
          }
        ];
        parsers.s02Enrich = [
          {
            name = "sebsuite/whitelist-infra";
            description = "Never flag the VPS itself (Gatus checks), localhost or the homelab tunnel";
            whitelist = {
              reason = "own infrastructure";
              ip = [ "198.245.55.120" "2607:5300:205:200::fccc" "127.0.0.1" "::1" ];
              cidr = [ "10.8.0.0/24" ];
            };
          }
        ];
      };
      settings = {
        simulation.simulation = true;
        general.api.server = {
          enable = true;
          # 8080 is Gatus
          listen_uri = "127.0.0.1:8081";
        };
        lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      };
    };

    users.users.crowdsec.extraGroups = [ "caddy" ];

    # existing log files were created 0600; new ones follow `mode 0640` above
    systemd.tmpfiles.rules = [
      "z /var/log/caddy 0750 caddy caddy -"
      "z /var/log/caddy/*.log 0640 caddy caddy -"
    ];
  };
}
