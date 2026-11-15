{ pkgs, ... }:
let
  bulk-consolidate = pkgs.writeShellScriptBin "bulk-consolidate" ''
    exec ${pkgs.python3}/bin/python3 -I ${./bulk-consolidate.py} "$@"
  '';
in
{
  # dry run by default: `bulk-consolidate` shows the plan, the timer passes --execute
  environment.systemPackages = [ bulk-consolidate ];

  systemd.services.bulk-consolidate = {
    description = "Move each show's minority files onto the disk holding most of it";
    # Transmission's RPC must answer; if it doesn't, the run exits before touching any file
    after = [ "docker.service" ];
    unitConfig.RequiresMountsFor = [ "/media/bulk-seagate" "/media/bulk-toshiba" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${bulk-consolidate}/bin/bulk-consolidate --execute";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.bulk-consolidate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };
}
