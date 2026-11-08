{ pkgs, ... }:
{
  imports = [ ./smart.nix ];

  services.smartd.notifications.systembus-notify.enable = true;

  systemd.services.smart-test-inhibit = {
    description = "Block sleep while a SMART self-test is running";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ smartmontools jq systemd coreutils procps ];
    script = ''
      testing() {
        smartctl -j --scan-open | jq -r '.devices[] | "\(.name) \(.type)"' |
        while read -r dev type; do
          # -n standby: polling must not spin up an idle disk, which can't be mid-test anyway
          smartctl -j -n standby -d "$type" -c -l selftest "$dev" || true
        done |
        jq -se 'any(.[];
          .ata_smart_data.self_test.status.remaining_percent != null
          or (.nvme_self_test_log.current_self_test_operation.value // 0) != 0)' >/dev/null
      }

      lock=""
      while true; do
        if testing; then
          if [ -z "$lock" ]; then
            systemd-inhibit --what=sleep --mode=block --who=smartd --why="SMART self-test running" sleep infinity &
            lock=$!
          fi
        elif [ -n "$lock" ]; then
          # killing systemd-inhibit itself would orphan its sleep; ending the child releases the lock
          pkill -P "$lock"
          wait "$lock" || true
          lock=""
        fi
        sleep 60
      done
    '';
  };
}
