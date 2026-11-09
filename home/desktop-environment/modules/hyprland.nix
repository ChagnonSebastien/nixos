{ config, pkgs, lib, ...}: {

  options.desktop.sleepCommand = lib.mkOption {
    type = lib.types.str;
    default = "systemctl suspend";
  };

  config = {

  home.pointerCursor = {
    enable = true;
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

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
      hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
      hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")
      hl.env("LIBVA_DRIVER_NAME", "nvidia")
      hl.env("XDG_SESSION_TYPE", "wayland")
      hl.env("GBM_BACKEND", "nvidia-drm")
      hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
      -- nvidia's resume modeset overruns the rtkit RLIMIT_RTTIME hard limit and the kernel SIGKILLs Hyprland
      hl.env("HYPRLAND_NO_RT", "1")

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
          name  = "btop-float",
          match = { class = "btop-float" },
          float = true,
          size  = "1400 800",
          move  = "monitor_w-window_w-10 34",
      })

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

  programs.hyprlock = let
    font = "FiraCode Nerd Font Propo";
    mocha = {
      base = "rgb(1e1e2e)";
      baseBar = "rgba(1e1e2ed9)";
      basePanel = "rgba(1e1e2ef2)";
      surface0 = "rgb(313244)";
      surface1 = "rgb(45475a)";
      mauve = "rgb(cba6f7)";
      text = "rgb(cdd6f4)";
      subtext0 = "rgb(a6adc8)";
      red = "rgb(f38ba8)";
      peach = "rgb(fab387)";
      yellow = "rgb(f9e2af)";
    };
    barLabel = attrs: {
      monitor = "";
      color = mocha.text;
      font_size = 10;
      font_family = font;
      valign = "top";
      zindex = 2;
    } // attrs;
    powerButton = icon: cmd: x: barLabel {
      text = icon;
      onclick = cmd;
      position = "${toString x}, -4";
      halign = "left";
    };
  in {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        ignore_empty_input = true;
      };

      background = map (w: {
        inherit (w) monitor path;
        color = mocha.base;
        blur_passes = 2;
        blur_size = 4;
        brightness = 0.75;
      }) config.services.hyprpaper.settings.wallpaper;

      shape = [
        {
          monitor = "";
          size = "100%, 24";
          color = mocha.baseBar;
          position = "0, 0";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          size = "100%, 1";
          color = mocha.surface0;
          position = "0, -24";
          halign = "center";
          valign = "top";
        }
        {
          monitor = "";
          size = "72, 24";
          color = mocha.surface1;
          position = "0, 0";
          halign = "center";
          valign = "top";
          zindex = 1;
        }
        {
          monitor = "";
          size = "72, 2";
          color = mocha.mauve;
          position = "0, -22";
          halign = "center";
          valign = "top";
          zindex = 2;
        }
        {
          monitor = "";
          size = "340, 110";
          color = mocha.basePanel;
          rounding = 6;
          border_size = 1;
          border_color = mocha.surface1;
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        (powerButton "󰤄" config.desktop.sleepCommand 6)
        (powerButton "󰜉" "systemctl reboot" 30)
        (powerButton "󰐥" "systemctl poweroff" 54)
        (barLabel {
          text = "<b>locked</b>";
          font_size = 11;
          position = "0, -4";
          halign = "center";
        })
        (barLabel {
          text = "cmd[update:1000] date +'<b>%Y-%m-%d %H:%M</b>'";
          position = "-6, -4";
          halign = "right";
        })
        {
          monitor = "";
          text = "<b>$USER</b>";
          color = mocha.text;
          font_size = 11;
          font_family = font;
          position = "0, 28";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 34";
          outline_thickness = 2;
          rounding = 0;
          dots_size = 0.25;
          dots_spacing = 0.3;
          dots_center = true;
          outer_color = mocha.surface1;
          inner_color = mocha.surface0;
          font_color = mocha.text;
          check_color = mocha.yellow;
          fail_color = mocha.red;
          capslock_color = mocha.peach;
          font_family = font;
          fade_on_empty = false;
          placeholder_text = "<span foreground=\"##a6adc8\">password</span>";
          fail_text = "$FAIL ($ATTEMPTS)";
          position = "0, -14";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = let
      dpms = state: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'";
    in {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock -q";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd  = dpms "on";
        unlock_cmd       = dpms "on";

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
          on-timeout = dpms "off";
          on-resume  = dpms "on";
        }
        {
          timeout = 1800;
          on-timeout = config.desktop.sleepCommand;
        }
      ];
    };
  };
  };
}
