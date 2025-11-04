{ config, pkgs, lib, ...}: {

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      monitor = [
        "DP-2, 2560x1440@170, 0x0, 1"
        "DP-3, 2560x1440@170, 2560x0, 1"
      ];

      exec-once = [
        "waybar"
        "wl-paste --type text --watch cliphist store" # Stores only text data
        "wl-paste --type image --watch cliphist store" # Stores only image data
        "gnome-keyring-daemon --start --components=secrets"
        "fcitx5 -d"
        "sway-audio-idle-inhibit"
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
      "$fileManager" = "superfile";
      "$menu" = "rofi -show run";
      "$launcher" = "rofi -show drun";
      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, N, exec, $terminal"
        "$mainMod, delete, killactive,"
        "$mainMod, L, exec, pidof hyprlock || hyprlock -q"
        "$mainMod, E, exec, $terminal $fileManager"
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

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        ignore_empty_input = true;
        grace = 1;
      };

      background = [
        {
          monitor = "";
          blur_passes = 2;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo -e \"$(date +\"%A\")\"";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 90;
          font_family = "SF Pro Display Bold";
          position = "0, 350";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo -e \"$(date +\"%d %B\")\"";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 40;
          font_family = "SF Pro Display Bold";
          position = "0, 250";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo -e \"<span>$(date +\"- %I:%M -\")</span>\"";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 20;
          font_family = "SF Pro Display Bold";
          position = "0, 190";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "    $USER";
          color = "rgba(216, 222, 233, 0.70)";
          font_size = 18;
          font_family = "SF Pro Display Bold";
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = " 󰜉 ";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 50;
          onclick = "reboot now";
          position = "0, 100";
          halign = "center";
          valign = "bottom";
          font_family = "FiraCode Nerd Font";
        }
        {
          monitor = "";
          text = " 󰐥 ";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 50;
          onclick = "shutdown now";
          position = "820, 100";
          halign = "left"; 
          valign = "bottom";
          font_family = "FiraCode Nerd Font";
        }
        {
          monitor = "";
          text = " 󰤄 ";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 50;
          onclick = "systemctl suspend";
          position = "-820, 100";
          halign = "right";
          valign = "bottom";
          font_family = "FiraCode Nerd Font";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 60";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          outer_color = "rgba(255, 255, 255, 0)";
          inner_color = "rgba(255, 255, 255, 0.1)";
          font_color = "rgb(200, 200, 200)";
          halign = "center";
          valign = "center";
          font_family = "SF Pro Display Bold";
          position = "0, -210";
          dots_center = true;
          fade_on_empty = false;
          hide_input = false;
          placeholder_text = "<i><span foreground=\"##ffffff99\">🔒 Enter Pass</span></i>";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock -q";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd  = "hyprctl dispatch dpms on";
        unlock_cmd       = "hyprctl dispatch dpms on";

        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "pidof hyprlock || hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume  = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

}

