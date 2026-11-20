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
      # images pulled by digest keep no name:tag locally, so trivy must get the image ID
      while read -r img cid; do
        report="$out/$(printf %s "$img" | sha256sum | cut -c1-16).json"
        if id=$(docker inspect -f '{{.Image}}' "$cid") \
          && trivy image --cache-dir "$CACHE_DIRECTORY" --skip-db-update --image-src docker \
            --scanners vuln --format json --quiet "$id" > "$report.raw"; then
          jq --arg img "$img" '.ArtifactName = $img' "$report.raw" > "$report"
        else
          failed+="$img"$'\n'
        fi
        rm -f "$report.raw"
      done < <(docker ps --format '{{.Image}} {{.ID}}' | sort -u -k1,1)
      jq -rs --arg now "$(date +%s)" --arg failed "$failed" -f ${./metrics/trivy.jq} "$out"/*.json > ${textfile}/trivy.prom.tmp
      mv ${textfile}/trivy.prom.tmp ${textfile}/trivy.prom
    '';
  };

  systemd.timers.trivy-scan.timerConfig.Persistent = true;
}
