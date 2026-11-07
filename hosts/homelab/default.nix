{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
  ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  environment.systemPackages = with pkgs; [
    smartmontools
    (writeShellApplication {
      name = "smart-status";
      runtimeInputs = [ smartmontools jq ];
      text = ''
        if [ "$(id -u)" -ne 0 ]; then exec sudo "$0" "$@"; fi

        smartctl -j --scan-open | jq -r '.devices[] | "\(.name) \(.type)"' |
        while read -r dev type; do
          j=$(smartctl -j -d "$type" -i -c -l selftest "$dev" || true)
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
            def last:
              ( [ .ata_smart_self_test_log.standard.table[]? | select(.status.value < 240) ][0]
                | select(. != null)
                | "\(.type.string): \(.status.string) at \(.lifetime_hours)h" )
              // ( .nvme_self_test_log.table[0] | select(. != null)
                | "\(.self_test_code.string): \(.self_test_result.string) at \(.power_on_hours)h" )
              // "none logged";
            "* \(status)", "* last result: \(last)"
          '
          echo
        done
      '';
    })
  ];

  networking.firewall.enable = false;

  networking.networkmanager.enable = false;
  networking.useDHCP = false;

  networking.interfaces.enp42s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "192.168.0.2";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp42s0";
  };

  networking.wireguard.interfaces.wg-phone = {
    ips = [ "10.7.0.1/24" ];
    listenPort = 51821;
    privateKeyFile = "/var/lib/wireguard/wg-phone.key";
    generatePrivateKeyFile = true;
    peers = [{
      publicKey = "T4pPomAl7cPP/LVBcHvxjzSRqYJb/ZpPxnBlObZ710o=";
      allowedIPs = [ "10.2.0.2/32" ];
    }];
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg-phone" ];
    externalInterface = "enp42s0";
    extraCommands = ''
      iptables -C FORWARD -i wg-phone -o enp42s0 -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i wg-phone -o enp42s0 -j ACCEPT
      iptables -C FORWARD -i enp42s0 -o wg-phone -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
      iptables -A FORWARD -i enp42s0 -o wg-phone -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    '';
  };

  networking.nameservers = [ "192.168.0.2" ];

  virtualisation.docker = {
    enable = true;

    daemon.settings.features.cdi = true;

    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--filter" "until=168h" ];
    };
  };

  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/media/hdd-1" ];

  # nixpkgs only sets Requires=, so GPU containers race the CDI spec and die
  systemd.services.docker.after = [ "nvidia-container-toolkit-cdi-generator.service" ];

  users.users.seb = {
    extraGroups = [ "docker" "k3s" ];
    linger = true;
  };

  services.openssh.enable = true;
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../6/03)";
  };

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11";
}

