{ config, pkgs, ... }:
let
  # git 2.54 drops a token-only URL credential after its first 200 and fails on private repos
  gitconfig = pkgs.writeText "renovate-gitconfig" ''
    [credential "https://github.com"]
    	helper = "!f() { echo username=x-access-token; echo \"password=$(cat /run/credentials/renovate.service/SECRET-RENOVATE_TOKEN)\"; }; f"
  '';
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
      gitAuthor = "Renovate <renovate@chagnon.dev>";
      reportType = "file";
      reportPath = report;
    };
  };

  # flake.lock updates in nixos run nix inside the renovate sandbox
  services.renovate.runtimePackages = [ pkgs.nix ];

  # simple-git rejects GIT_CONFIG_* env, so git must find the helper in HOME
  systemd.services.renovate.preStart = "ln -sf ${gitconfig} /var/lib/renovate/.gitconfig";

  systemd.timers.renovate.timerConfig.Persistent = true;
  systemd.services.renovate.onSuccess = [ "renovate-report.service" ];

  # reuse the ntfy token labelled homelab in the VPS ntfy-env
  sops.secrets.ntfy-token = { };

  systemd.services.renovate-report = {
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "renovate-report";
      LoadCredential = "ntfy:${config.sops.secrets.ntfy-token.path}";
    };
    path = [ pkgs.jq pkgs.curl ];
    script = ''
      jq -r --arg now "$(date +%s)" -f ${./metrics/renovate.jq} ${report} > ${textfile}/renovate.prom.tmp
      mv ${textfile}/renovate.prom.tmp ${textfile}/renovate.prom

      seen=$STATE_DIRECTORY/seen-prs
      touch "$seen"
      jq -r '.repositories | to_entries[] | .key as $r | .value.branches[] | select(.prNo != null)
        | [$r, (.prNo|tostring), (.prTitle // .branchName)] | @tsv' ${report} |
      while IFS=$(printf '\t') read -r repo pr title; do
        grep -qxF "$repo#$pr" "$seen" && continue
        curl -fsS -o /dev/null -H "Authorization: Bearer $(cat "$CREDENTIALS_DIRECTORY/ntfy")" \
          -H "Title: Renovate PR on $repo" -H "Tags: package" \
          -H "Click: https://github.com/$repo/pull/$pr" \
          -d "$title" https://ntfy.chagnon.dev/updates \
          && echo "$repo#$pr" >> "$seen"
      done
    '';
  };
}
