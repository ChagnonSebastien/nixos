{ pkgs, lib, ... }:
let
  wireguard = lib.getExe (pkgs.writeShellApplication {
    name = "waybar-wireguard";
    runtimeInputs = with pkgs; [ networkmanager procps ];
    text = ''
      active() {
        nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 == "wireguard" && !found { print $1; found = 1 }'
      }

      case "''${1:-status}" in
        status)
          current=$(active)
          echo " ''${current:-direct}"
          ;;
        next)
          mapfile -t locations < <(nmcli -t -f NAME,TYPE connection show | awk -F: '$2 == "wireguard" { print $1 }' | sort)
          locations+=(direct)
          current=$(active)
          current=''${current:-direct}
          next=''${locations[0]}
          for i in "''${!locations[@]}"; do
            if [[ "''${locations[$i]}" == "$current" ]]; then
              next=''${locations[$(( (i + 1) % ''${#locations[@]} ))]}
            fi
          done
          if [[ "$current" != direct ]]; then nmcli connection down "$current" >/dev/null; fi
          if [[ "$next" != direct ]]; then nmcli connection up "$next" >/dev/null; fi
          pkill -RTMIN+8 waybar || true
          ;;
      esac
    '';
  });

  stats = lib.getExe (pkgs.writeShellApplication {
    name = "waybar-stats";
    text = ''
      cpu_sample() { awk '/^cpu / { print $2 + $3 + $4 + $5 + $6 + $7 + $8, $5 + $6 }' /proc/stat; }
      read -r total1 idle1 < <(cpu_sample)
      sleep 1
      read -r total2 idle2 < <(cpu_sample)
      cpu=$(( 100 * ((total2 - total1) - (idle2 - idle1)) / (total2 - total1) ))

      read -r mem_used mem_total < <(awk '/^MemTotal/ { t = $2 } /^MemAvailable/ { a = $2 } END { printf "%.1f %.1f\n", (t - a) / 1048576, t / 1048576 }' /proc/meminfo)
      cpu_temp=$(( $(cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input) / 1000 ))
      IFS=', ' read -r gpu_usage gpu_temp gpu_mem_used gpu_mem_total < <(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits)

      disk_pcent() { df --output=pcent "$1" | tail -1 | tr -dc '0-9'; }
      disks=$(df -h --output=target,used,size,pcent -x tmpfs -x devtmpfs -x efivarfs -x overlay -x squashfs \
        | awk -v q="'" 'NR > 1 && $1 !~ /^\/(run|nix|proc|sys|dev)/ {
            line = sprintf("%-15s %5s / %-5s %4s", $1, $2, $3, $4)
            if ($4 + 0 >= 90) line = "<span color=" q "#f38ba8" q ">" line "</span>"
            printf "\\n%s", line
          }')

      class=""
      if (( cpu_temp >= 80 || gpu_temp >= 80 || $(disk_pcent /) >= 90 || $(disk_pcent /boot) >= 90 )); then class="critical"; fi

      tooltip="<tt>CPU   $cpu%   $cpu_temp°C\nRAM   $mem_used / $mem_total GiB\nGPU   $gpu_usage%   $gpu_temp°C\nVRAM  $(( gpu_mem_used / 1024 )) / $(( gpu_mem_total / 1024 )) GiB\n$disks</tt>"
      printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "󰍛" "$tooltip" "$class"
    '';
  });
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true; # started with graphical-session.target (UWSM)
    settings = {
      mainBar = {
        height = 24;
        modules-left = [ "hyprland/workspaces" "hyprland/submap" "mpris"];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "keyboard-state" "custom/stats" "network" "custom/network_toggle" "pulseaudio" "tray" "clock" "custom/notification" ];
        
        "custom/stats" = {
          exec = stats;
          return-type = "json";
          interval = 5;
          on-click = "kitty --class btop-float btop";
        };

        "custom/notification" = {
          tooltip = false;
          format = "{icon} {text}";
          "format-icons" = {
            notification = "󱅫";
            none = "";
            "dnd-notification" = "";
            "dnd-none" = "󰂛";
            "inhibited-notification" = "";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "";
            "dnd-inhibited-none" = "";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "sleep 0.1 && swaync-client -t -sw";
          "on-click-right" = "sleep 0.1 && swaync-client -d -sw";
          escape = true;
        };

        "custom/network_toggle" = {
          exec = "${wireguard} status";
          on-click = "${wireguard} next";
          signal = 8;
          interval = 60;
        };

        "hyprland/workspaces" = {
          disable-scroll = true;
          warp-on-scroll = false;
          format = "{name} {icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            urgent = "";
            active = "";
            default = "";
          };
        };
        "keyboard-state" = {
          numlock = false;
          capslock = true;
          format = "{icon}";
          format-icons = {
            locked = "󰘲 CAPS";
            unlocked = "";
          };
        };
        "mpris" = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "";
            mpv = "󰝚";
          };
          status-icons = {
            paused = "";
          };
        };
        "tray" = {
          spacing = 10;
        };
        "clock" = {
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          format = "{:%Y-%m-%d %H:%M}";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            on-scroll = 1;
            format = {
              today = "<span color='#cba6f7'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
        "network" = {
          format-wifi = " {essid} {signalStrength}%";
          format-ethernet = " {ifname}";
          tooltip-format = " {ifname} via {gwaddr}";
          format-linked = " {ifname} (no IP)";
          format-disconnected = "󰌘 disconnected";
          format-alt = " {ipaddr}/{cidr}";
        };
        "pulseaudio" = {
          scroll-step = 5;
          format = "{icon} {volume}%{format_source}";
          format-bluetooth = " {volume}%{format_source}";
          format-bluetooth-muted = " muted{format_source}";
          format-muted = " muted{format_source}";
          format-source = "";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
        };
      };
    };
    style = ''
      @define-color base #1e1e2e;
      @define-color crust #11111b;
      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color text #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color mauve #cba6f7;
      @define-color red #f38ba8;
      @define-color peach #fab387;

      * {
        font-family: "FiraCode Nerd Font Propo", "Noto Sans CJK KR";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: alpha(@base, 0.85);
        border-bottom: 1px solid @surface0;
        color: @text;
        transition-property: background-color;
        transition-duration: .5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      #waybar.empty #window {
        background-color: transparent;
      }

      .module, #workspaces button {
        padding: 0px 8px;
        border: none;
        border-radius: 0;
        color: @text;
      }

      .modules-right .module:hover, #workspaces button:hover {
        background: inherit;
        border-bottom: 2px solid @mauve;
      }

      #workspaces button.active {
        background-color: @surface1;
        border-bottom: 2px solid @mauve;
      }

      #workspaces button.urgent {
        background-color: @red;
        color: @crust;
      }

      #window {
        background-color: @surface0;
        font-weight: bold;
      }

      #clock {
        font-weight: bold;
      }

      #keyboard-state, #keyboard-state label {
        padding: 0;
      }

      #keyboard-state label.locked {
        padding: 0px 8px;
        background-color: @peach;
        color: @crust;
      }

      #custom-stats {
        color: @subtext0;
      }

      tooltip {
        background-color: @base;
        border: 1px solid @surface1;
        border-radius: 6px;
      }

      #network.disconnected,
      #custom-stats.critical {
        background-color: @red;
        color: @crust;
      }

      #pulseaudio.muted {
        color: @peach;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: @red;
      }
    '';
  };

}
