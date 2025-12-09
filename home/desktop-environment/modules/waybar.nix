{ config, pkgs, lib, ...}: {  

  home.packages = with pkgs; [
    waybar
  ];

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        height = 24;
        modules-left = [ "hyprland/workspaces" "hyprland/submap" "mpris"];
        modules-center = [ "hyprland/window" ];
        modules-right = [ "keyboard-state" "temperature" "cpu" "memory" "network" "custom/network_toggle" "pulseaudio" "tray" "clock" "custom/notification" ];
        
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
          exec = pkgs.writeShellScript "get_wireguard_connection" ''
            sleep 0.5
            CONNECTION=$(nmcli connection | grep -i -E 'wireguard +[-a-z0-9]{3,}' | awk '{print $1}')
            if [[ -z "$CONNECTION" ]]; then
              echo "   home"
            else
              echo "   $CONNECTION"
            fi
          '';
          on-click = pkgs.writeShellScript "next_wireguard_connection"  ''
            #!/bin/bash

            # WireGuard connection names
            LOCATIONS=( $(nmcli connection | awk '/wireguard/ {print $1}' | sort) "home" )
            get_wireguard_connection() {
              CONNECTION=$(nmcli connection | grep -i -E 'wireguard +[-a-z0-9]{3,}' | awk '{print $1}')
              if [[ -z "$CONNECTION" ]]; then
                echo "home"
              else
                echo "$CONNECTION"
              fi
            }

            get_current_index() {
              for i in "''${!LOCATIONS[@]}"; do
                if [[ "''${LOCATIONS[$i]}" == "$1" ]]; then
                  echo $i
                  return
                fi
              done
              echo -1
            }

            # Get the current WireGuard connection
            CURRENT_CONNECTION=$(get_wireguard_connection)
            CURRENT_INDEX=$(get_current_index "$CURRENT_CONNECTION")

            # Determine the next connection index
            if [[ $CURRENT_INDEX -ge 0 ]]; then
              NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ''${#LOCATIONS[@]} ))
            else
              NEXT_INDEX=0
            fi

            # Bring down any active WireGuard connection
            nmcli connection down "$CURRENT_CONNECTION" 2>/dev/null

            # Bring up the next connection if it's not "home"
            NEXT_CONNECTION="''${LOCATIONS[$NEXT_INDEX]}"
            if [[ "$NEXT_CONNECTION" != "home" ]]; then
              nmcli connection up "$NEXT_CONNECTION"
            fi

          '';
          exec-on-event = true;
          interval = 10;
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
            focused = " ";
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
        };
        "calendar" = {
          mode = "year";
          mode-mon-col = 3;
          on-scroll = 1;
          format = {
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
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
          thermal-zone = 2;
          hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
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
      * {
        font-family: "Noto Sans CJK KR Regular";
        font-size: 13px;
        min-height: 0;
      }
      
      window#waybar {
        background-color: rgba(43, 48, 59, 0.5);
        border-bottom: 1px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
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
      }
      
      .modules-right .module:hover, #workspaces button:hover {
        background: inherit;
        border-bottom: 2px solid #c9545d;
      }

      #workspace button.active {
        background-color: rgba(255, 255, 255, 0.5);
      }
      
      #workspaces button.urgent {
        background-color: #eb4d4b;
      }
      
      #window {
        margin: 0px 2px;
        padding-left: 8px;
        padding-right: 8px;
        background-color: rgba(0,0,0,0.3);
        font-size:14px;
        font-weight: bold;
      }
      
      #clock {
        font-weight: bold;
      }
      
      #network.disconnected {
        background-color: #f53c3c;
      }
      
      #temperature.critical {
        background-color: #eb4d4b;
      }
      
      #tray > .passive {
        -gtk-icon-effect: dim;
      }
      
      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
      }
    '';
  };

}
