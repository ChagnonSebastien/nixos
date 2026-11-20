{ pkgs, ... }:
let
  textfile = "/home/seb/services/docker/observability/textfile";
in
{
  systemd.services.trivy-scan = {
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    startAt = "*-*-* 05:00:00";
    path = [ pkgs.trivy pkgs.docker pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      CacheDirectory = "trivy";
      RuntimeDirectory = "trivy-scan";
    };
    script = ''
      out=$RUNTIME_DIRECTORY
      failed=""
      trivy image --cache-dir "$CACHE_DIRECTORY" --download-db-only --quiet
      for img in $(docker ps --format '{{.Image}}' | sort -u); do
        if ! trivy image --cache-dir "$CACHE_DIRECTORY" --skip-db-update --image-src docker \
          --scanners vuln --format json --quiet "$img" > "$out/$(printf %s "$img" | sha256sum | cut -c1-16).json"; then
          failed+="$img"$'\n'
          rm -f "$out/$(printf %s "$img" | sha256sum | cut -c1-16).json"
        fi
      done
      jq -rs --arg now "$(date +%s)" --arg failed "$failed" -f ${./metrics/trivy.jq} "$out"/*.json > ${textfile}/trivy.prom.tmp
      mv ${textfile}/trivy.prom.tmp ${textfile}/trivy.prom
    '';
  };

  systemd.timers.trivy-scan.timerConfig.Persistent = true;
}
