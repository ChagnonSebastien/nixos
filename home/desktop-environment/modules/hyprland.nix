{ config, pkgs, lib, ...}: {

  wayland.windowManager.hyprland = {
    enable = true;
    # UWSM (programs.hyprland.withUWSM) owns the systemd session targets. HM's
    # integration restarts hyprland-session.target on startup, which tears down
    # UWSM's graphical-session.target and makes Hyprland exit immediately.
    systemd.enable = false;

    # Hyprland >= 0.57 only reads hyprland.lua; hyprlang (hyprland.conf) is gone.
    # Written as plain Lua rather than `settings`, because Home Manager renders
    # `settings` calls alphabetically (hl.animation would precede hl.curve).
    configType = "lua";

    extraConfig = ''
      -- Monitors
      hl.monitor({ output = "DP-2", mode = "2560x1440@170", position = "0x0",    scale = 1 })
      hl.monitor({ output = "DP-3", mode = "2560x1440@170", position = "2560x0", scale = 1 })

      -- Programs
      local terminal    = "kitty"
      local fileManager = "superfile"
      local menu        = "rofi -show run"
      local launcher    = "rofi -show drun"
      local mainMod     = "SUPER"

      -- Autostart: nothing here. Session daemons are systemd user services
      -- bound to graphical-session.target (started by UWSM): waybar, cliphist
      -- and sway-audio-idle-inhibit via Home Manager; fcitx5 via its XDG
      -- autostart entry; gnome-keyring via the greetd PAM module.

      -- Environment
      hl.env("XCURSOR_SIZE", "24")
      hl.env("HYPRCURSOR_SIZE", "24")
      hl.env("LIBVA_DRIVER_NAME", "nvidia")
      hl.env("XDG_SESSION_TYPE", "wayland")
      hl.env("GBM_BACKEND", "nvidia-drm")
      hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
      hl.env("WLR_NO_HARDWARE_CURSORS", "true")

      -- Look and feel
      hl.config({
          general = {
              gaps_in     = 5,
              gaps_out    = 20,
              border_size = 2,
              col = {
                  active_border   = { colors = { "rgba(ff9900ee)", "rgba(ffbf00ee)" }, angle = 45 },
                  inactive_border = "rgba(595959aa)",
              },
              resize_on_border = false,
              allow_tearing    = false,
              layout           = "dwindle",
          },

          decoration = {
              rounding         = 10,
              active_opacity   = 1.0,
              inactive_opacity = 1.0,
              shadow = {
                  enabled      = true,
                  range        = 4,
                  render_power = 3,
                  color        = 0xee1a1a1a,
              },
              blur = {
                  enabled  = true,
                  size     = 3,
                  passes   = 1,
                  vibrancy = 0.1696,
              },
          },

          animations = { enabled = true },
          dwindle    = { preserve_split = true },
          master     = { new_status = "master" },

          misc = {
              force_default_wallpaper = -1,
              disable_hyprland_logo   = false,
          },

          input = {
              kb_layout    = "ca",
              kb_variant   = "fr",
              follow_mouse = 1,
              sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.
          },
      })

      -- Animations
      hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.01 } } })

      hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "myBezier" })
      hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4, bezier = "default", style = "popin 80%" })
      hl.animation({ leaf = "border",      enabled = true, speed = 6, bezier = "default" })
      hl.animation({ leaf = "borderangle", enabled = true, speed = 5, bezier = "default" })
      hl.animation({ leaf = "fade",        enabled = true, speed = 4, bezier = "default" })
      hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "default" })

      -- Keybindings
      local screenshotOut = "~/Pictures/Captures/$(date '+%Y-%m-%d_%H-%M-%S').png"

      hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + delete", hl.dsp.window.close())
      hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("pidof hyprlock || hyprlock -q"))
      hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("uwsm stop")) -- log out
      hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " " .. fileManager))
      hl.bind(mainMod .. " + F",      hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
      hl.bind(mainMod .. " + code:112", hl.dsp.window.fullscreen())
      hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))
      hl.bind("ALT + space",          hl.dsp.exec_cmd(launcher))

      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(
          "grim -g \"$(slurp -d -w 0)\" -t png - | satty --filename - --copy-command wl-copy --output-filename " .. screenshotOut))
      hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(
          "grim -g \"$(slurp -o -r -w 0)\" -t png - | satty --filename - --fullscreen --copy-command wl-copy --output-filename " .. screenshotOut))
      hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

      for _, dir in ipairs({ "left", "right", "up", "down" }) do
          hl.bind(mainMod .. " + " .. dir,             hl.dsp.focus({ direction = dir }))
          hl.bind(mainMod .. " + SHIFT + " .. dir,     hl.dsp.window.move({ direction = dir }))
      end

      for i = 1, 10 do
          local key = i % 10 -- 10 maps to key 0
          hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Window rules
      hl.window_rule({
          name  = "suppress-maximize",
          match = { class = ".*" },
          suppress_event = "maximize",
      })
    '';
  };

  # Clipboard history: one wl-paste watcher for text, one for images.
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # Block idle (hypridle/hyprlock) while audio is playing.
  systemd.user.services.sway-audio-idle-inhibit = {
    Unit = {
      Description = "Inhibit idle while audio is playing";
      PartOf = [ config.wayland.systemd.target ];
      After = [ config.wayland.systemd.target ];
    };
    Service = {
      ExecStart = lib.getExe pkgs.sway-audio-idle-inhibit;
      Restart = "on-failure";
    };
    Install.WantedBy = [ config.wayland.systemd.target ];
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

