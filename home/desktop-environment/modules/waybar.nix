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
          echo "   ''${current:-direct}"
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

  gpu = lib.getExe (pkgs.writeShellApplication {
    name = "waybar-gpu";
    text = ''
      IFS=', ' read -r usage temp < <(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits)
      class=""
      if (( temp >= 80 )); then class="critical"; fi
      printf '{"text": "%s  %s%% %s°C", "class": "%s"}\n' "󰢮" "$usage" "$temp" "$class"
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
        modules-right = [ "keyboard-state" "group/stats" "network" "custom/network_toggle" "pulseaudio" "tray" "clock" "custom/notification" ];
        
        "group/stats" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            transition-left-to-right = false;
          };
          modules = [ "custom/stats" "temperature" "cpu" "memory" "custom/gpu" ];
        };

        "custom/stats" = {
          format = "󰍛";
          tooltip = false;
        };

        "custom/gpu" = {
          exec = gpu;
          return-type = "json";
          interval = 5;
          tooltip = false;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{} {icon}";
          "format-icons" = {
            notification = "󱅫";
            none = "";
            "dnd-notification" = " ";
            "dnd-none" = "󰂛";
            "inhibited-notification" = " ";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = " ";
            "dnd-inhibited-none" = " ";
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
          format = "{name}: {icon}";
          format-icons = {
            "1" = " ";
            "2" = " ";
            "3" = " ";
            "4" = " ";
            "5" = " ";
            urgent = " ";
            active = " ";
            default = " ";
          };
        };
        "keyboard-state" = {
          numlock = false;
          capslock = true;
          format = "{icon}";
          format-icons = {
            locked = "CAPS_LOCK 🔴";
            unlocked = "";
          };
        };
        "mpris" = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "▶";
            mpv = "🎵";
          };
          status-icons = {
            paused = "⏸";
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
        "cpu" = {
          format = "   {usage}%";
        };
        "memory" = {
          format = "   {}%";
        };
        "temperature" = {
          hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
          input-filename = "temp1_input";
          critical-threshold = 80;
          format-critical = "{icon} {temperatureC}°C";
          format = "{icon} {temperatureC}°C";
          format-icons = [""];
        };
        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "  {ifname}";
          tooltip-format = "  {ifname} via {gwaddr}";
          format-linked = "  {ifname} (No IP)";
          format-disconnected = "Disconnected ⚠ {ifname}";
          format-alt = "  {ifname}: {ipaddr}/{cidr}";
        };
        "pulseaudio" = {
          scroll-step = 5;
          format = "{icon}   {volume}% {format_source}";
          format-bluetooth = " {icon}   {volume}% {format_source}";
          format-bluetooth-muted = "🔇  {icon}   {format_source}";
          format-muted = "   MUTED {format_source}";
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

      .modules-right .module, #workspaces button {
        padding: 0px 6px;
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
        margin: 0px 2px;
        padding-left: 8px;
        padding-right: 8px;
        background-color: @surface0;
        font-size: 14px;
        font-weight: bold;
      }

      #clock {
        font-weight: bold;
      }

      #custom-stats, #temperature, #cpu, #memory, #custom-gpu {
        color: @subtext0;
      }

      #network.disconnected,
      #temperature.critical,
      #custom-gpu.critical {
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
