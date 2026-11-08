{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    smartmontools
    (writeShellApplication {
      name = "smart-status";
      runtimeInputs = [ smartmontools jq ];
      text = ''
        if [ "$(id -u)" -ne 0 ]; then exec sudo "$0" "$@"; fi

        smartctl -j --scan-open | jq -r '.devices[] | "\(.name) \(.type)"' |
        while read -r dev type; do
          j=$(smartctl -j -d "$type" -i -c -A -l selftest "$dev" || true)
          echo "$j" | jq -r --arg dev "$dev" '"\($dev)  \(.model_name // "?") (\(.serial_number // "?"))"'
          echo
          echo "$j" | jq -r '
            def status:
              if .ata_smart_data.self_test.status then
                .ata_smart_data.self_test.status as $s
                | if $s.remaining_percent != null
                  then "test in progress (\($s.remaining_percent)% remaining)"
                  else "no test in progress" end
              elif .nvme_self_test_log then
                .nvme_self_test_log as $n
                | if ($n.current_self_test_operation.value // 0) != 0
                  then "test in progress (\(100 - ($n.current_self_test_completion_percent // 0))% remaining)"
                  else "no test in progress" end
              else "self-test not supported" end;
            (.power_on_time.hours // .nvme_smart_health_information_log.power_on_hours) as $now
            | def ago($h; $wrap):
                if $now == null then ""
                else " (\(if $wrap then ($now - $h) % 65536 else $now - $h end)h ago)" end;
              def last:
                # ATA self-test log stores lifetime hours in 16 bits, so it wraps at 65536
                ( [ .ata_smart_self_test_log.standard.table[]? | select(.status.value < 240) ][0]
                  | select(. != null)
                  | "\(.type.string): \(.status.string) at \(.lifetime_hours)h\(ago(.lifetime_hours; true))" )
                // ( .nvme_self_test_log.table[0] | select(. != null)
                  | "\(.self_test_code.string): \(.self_test_result.string) at \(.power_on_hours)h\(ago(.power_on_hours; false))" )
                // "none logged";
              "* power on: \(if $now then "\($now)h" else "unknown" end)", "* \(status)", "* last result: \(last)"
          '
          echo
        done
      '';
    })
  ];

  services.smartd = {
    enable = true;
    # state files let smartd run tests scheduled while the machine was off at the next boot
    extraOptions = [ "--savestates=/var/lib/smartd/" ];
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../6/03)";
  };

  systemd.services.smartd.serviceConfig.StateDirectory = "smartd";
}
