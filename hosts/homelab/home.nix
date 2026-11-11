{ pkgs, ... }:
{
  imports = [
    ../../home/modules/pi-hole-lists
  ];

  systemd.user.services.cost-split = {
    Unit.Description = "Recompute the Cost Split bill read by Grafana";
    Service = {
      Type = "oneshot";
      # docker CLI for identity lookups (ldapsearch, Jellyfin DB copy, Immich emails)
      Environment = "PATH=${pkgs.python3}/bin:/run/current-system/sw/bin";
      ExecStart = pkgs.writeShellScript "cost-split" ''
        set -eu
        cd "$HOME/services/docker/observability"
        y=$(date +%Y)
        python3 cost_split.py --db cost-split/bill.db "$y"
        if [ "$(date +%m)" = 01 ]; then
          python3 cost_split.py --db cost-split/bill.db "$((y - 1))"
        fi
      '';
    };
  };

  systemd.user.timers.cost-split = {
    Unit.Description = "Nightly Cost Split bill";
    Timer = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.stateVersion = "24.05";
}
