{ config, ... }:
let
  textfile = "/home/seb/services/docker/observability/textfile";
  suffix = config.system.nixos.versionSuffix;
  date = builtins.substring 1 8 suffix;
  revision = builtins.substring 10 (-1) suffix;
in
{
  system.activationScripts.nixpkgs-age.text = ''
    if [ -d ${textfile} ]; then
      echo "nixos_nixpkgs_timestamp_seconds{revision=\"${revision}\"} $(date -u -d ${date} +%s)" > ${textfile}/nixos.prom
    fi
  '';
}
