{ config, pkgs, ... }:
let
  report = "/var/lib/renovate/report.json";
  textfile = "/home/seb/services/docker/observability/textfile";
in
{
  # fine-grained PAT on nixos and nixos-services: contents, pull requests, issues read/write
  sops.secrets.renovate-token = { };

  services.renovate = {
    enable = true;
    schedule = "*-*-* 06:00:00";
    credentials.RENOVATE_TOKEN = config.sops.secrets.renovate-token.path;
    settings = {
      platform = "github";
      repositories = [
        "ChagnonSebastien/nixos"
        "ChagnonSebastien/nixos-services"
      ];
      onboarding = false;
      reportType = "file";
      reportPath = report;
    };
  };

  # flake.lock updates in nixos run nix inside the renovate sandbox
  services.renovate.runtimePackages = [ pkgs.nix ];

  systemd.timers.renovate.timerConfig.Persistent = true;
  systemd.services.renovate.onSuccess = [ "renovate-metrics.service" ];

  systemd.services.renovate-metrics = {
    serviceConfig.Type = "oneshot";
    path = [ pkgs.jq ];
    script = ''
      jq -r --arg now "$(date +%s)" -f ${./metrics/renovate.jq} ${report} > ${textfile}/renovate.prom.tmp
      mv ${textfile}/renovate.prom.tmp ${textfile}/renovate.prom
    '';
  };
}
