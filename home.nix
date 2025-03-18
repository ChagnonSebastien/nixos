{ config, pkgs, lib, ...}:

let
  nixvim = import (builtins.fetchGit {
    url = "https://github.com/nix-community/nixvim";
  });
  wallpapers = pkgs.fetchFromGitHub {
    owner = "ChagnonSebastien";
    repo = "Wallpapers";
    rev = "6434a34df7baa7de344fc69db6519cfcc83688dc";
    sha256 = "0xsg4vyx1rirb5s4kzikbgw6biw81fmrzp3141hckf8pdh6pgv8b";
  };
  
in
{

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.seb = { pkgs, ... }: {

    imports = [ nixvim.homeManagerModules.nixvim ];
    
    home.sessionVariables = {
      SUDO_EDITOR = "nvim";
    };

    home.packages = with pkgs; [
      bat
      unzip
      (btop.override { cudaSupport = true; })
      jq
      waybar
      brave
      librewolf
      qview
      vesktop
      rofi-wayland
      zoxide
      youtube-music
      mpv
      bitwarden
      bitwarden-cli
      jellyfin-media-player
      tlrc # tldr
      satty # Screenshoot editor
      grim # Screenshot from wayland compositor
      slurp # Screenshot zone selection 
      wl-clipboard # Clipboard CLI
      cliphist # Clipboard history
      (writeShellScriptBin "jellyfin" ''
        export QT_QPA_PLATFORM="xcb"
        exec ${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer "$@"
      '')
      vscodium
      dust
      wireguard-tools
      caprine
      element-desktop
      libreoffice-qt6-still
      qbittorrent-enhanced
      beekeeper-studio
      (writeShellScriptBin "beekeeper" ''
        export LIBGL_ALWAYS_SOFTWARE=1
        exec ${pkgs.beekeeper-studio}/bin/beekeeper-studio "$@"
      '')
      jetbrains.idea-ultimate
      wineWowPackages.waylandFull
      winetricks
      prismlauncher
      obs-studio
    ];

    home.sessionPath = [ "$HOME/.local/bin" ];

    xdg.mimeApps = {
      enable = true;
      
      defaultApplications = {
        "text/html" = "librewolf.desktop"; # Replace with your browser's desktop file
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "x-scheme-handler/about" = "librewolf.desktop";
        "x-scheme-handler/unknown" = "librewolf.desktop";
      };
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        preload = [
          "${wallpapers}/space_left.png"
          "${wallpapers}/space_right.png"
        ];

        wallpaper = [
          "DP-2,${wallpapers}/space_left.png"
          "DP-3,${wallpapers}/space_right.png"
        ];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        monitor = [
          "DP-2, 2560x1440, 0x0, 1"
          "DP-3, 2560x1440, 2560x0, 1"
        ];

        exec-once = [
          "waybar"
          "wl-paste --type text --watch cliphist store" # Stores only text data
          "wl-paste --type image --watch cliphist store" # Stores only image data
        ];

        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
          "WLR_NO_HARDWARE_CURSORS,true"
        ];

        general = { 
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(ff9900ee) rgba(ffbf00ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
            rounding = 10;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            shadow = {
                enabled = true;
                range = 4;
                render_power = 3;
                color = "rgba(1a1a1aee)";
            };
            blur = {
                enabled = true;
                size = 3;
                passes = 1;
                vibrancy = 0.1696;
            };
        };

        animations = {
          enabled = true;
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.01";
          animation = [
            "windows, 1, 4, myBezier"
            "windowsOut, 1, 4, default, popin 80%"
            "border, 1, 6, default"
            "borderangle, 1, 5, default"
            "fade, 1, 4, default"
            "workspaces, 1, 3, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = { 
          force_default_wallpaper = -1;
          disable_hyprland_logo = false;
        };

        input = {
          kb_layout = "ca";
          kb_variant = "fr";
          follow_mouse = 1;
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        "$terminal" = "kitty";
        "$fileManager" = "dolphin";
        "$menu" = "rofi -show run";
        "$launcher" = "rofi -show drun";
        "$mainMod" = "SUPER";

        bind = [
          "$mainMod, N, exec, $terminal"
          "$mainMod, delete, killactive,"
          "$mainMod, L, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, F, togglefloating,"
          "$mainMod, P, pseudo,"
          "$mainMod, J, togglesplit,"
          "$mainMod, 112, fullscreen,"
          "$mainMod, space, exec, $menu"
          "ALT, space, exec, $launcher"

          "$mainMod SHIFT, S, exec, grim -g \"$(slurp -d -w 0)\" -t png - | satty --filename - --copy-command wl-copy --output-filename ~/Pictures/Captures/$(date '+%Y-%m-%d_%H-%M-%S').png"
          "$mainMod, S, exec, grim -g \"$(slurp -o -r -w 0)\" -t png - | satty --filename - --fullscreen --copy-command wl-copy --output-filename ~/Pictures/Captures/$(date '+%Y-%m-%d_%H-%M-%S').png"
          "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          "$mainMod SHIFT, left, movewindow, l"
          "$mainMod SHIFT, right, movewindow, r"
          "$mainMod SHIFT, up, movewindow, u"
          "$mainMod SHIFT, down, movewindow, d"

          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        windowrulev2 = "suppressevent maximize, class:.*";
      }; 
    };

    programs.nixvim = {
      enable = true;

      colorschemes.catppuccin.enable = true;

      plugins = {
        lsp = {
          enable = true;
          servers = {
            clangd = {
              enable = true;
              autostart = true;
              rootDir = ''
                function(fname)
                  return require("lspconfig.util").root_pattern("compile_commands.json", ".git")(fname)
                end
              '';
            };
            nil_ls = {
              enable = true;
              autostart = true;
            };
            gopls = {
              enable = true;
              autostart = true;
            };
            ts_ls = {
              enable = true;
              autostart = true;
            };
          };
        };
        lualine.enable = true;
        lsp-lines.enable = true;
        coq-nvim = {
          enable = true;
          installArtifacts = true;
          settings = {
            auto_start = "shut-up";
            completion.always = false;
          };
        };
        illuminate = {
          enable = true;
          delay = 100;
        };
      };

      extraPackages = [
        pkgs.vimPlugins.coq-artifacts
      ];

      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        list = true;
      };
    };

    programs.kitty = {
      enable = true;
      settings = {
        enable_audio_bell = false;
      };
      extraConfig = ''
        include ${pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "kitty";
          rev = "main";
          sha256 = "1sfjwvn6xwc882mzv9nhb8wsw3q4kapypq7gh1dkq3jqcjc717b3";
        }}/themes/mocha.conf
      '';
    };

    programs.git = {
      enable = true;
      userName = "Sebastien Chagnon";
      userEmail = "sebastien.chagnon@proton.me";
      extraConfig = {
        push.default = "current";
      };

    };

    programs.zsh = {
      enable = true;
      shellAliases = {
        ls = "ls --color";
        c = "clear";
        nrt = "sudo nixos-rebuild test";
        nrs = "sudo nixos-rebuild switch";
      };
      envExtra = ''
        ZSH_WEB_SEARCH_ENGINES=(
          nixpkg "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query="
        )
      '';
      initExtra = ''
        precmd() { print "" }
      '';
      antidote = {
        enable = true;
        plugins = [
          "Aloxaf/fzf-tab"
          "zdharma-continuum/fast-syntax-highlighting"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-autosuggestions"
          "chisui/zsh-nix-shell"
          "agkozak/zsh-z"
          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/web-search"
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
        ];
      };
    };

    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "tiwahu";
    };

    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
      enableZshIntegration = true;
    };

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
    };
    
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

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

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };
}
