{ config, ... }:
{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "top";
      control-center-margin-top = 6;
      control-center-margin-bottom = 6;
      control-center-margin-right = 6;
      control-center-width = 420;
      notification-window-width = 420;
      notification-icon-size = 48;
      timeout = 6;
      timeout-low = 4;
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear";
        };
        dnd.text = "Do not disturb";
      };
    };
    style = ''
      @import url("file://${config.services.swaync.package}/etc/xdg/swaync/style.css");

      :root {
        --cc-bg: rgba(30, 30, 46, 0.92);
        --noti-border-color: #45475a;
        --noti-bg: 30, 30, 46;
        --noti-bg-alpha: 0.97;
        --noti-bg-darker: #181825;
        --noti-bg-hover: #313244;
        --noti-bg-focus: rgba(49, 50, 68, 0.6);
        --noti-close-bg: #313244;
        --noti-close-bg-hover: #45475a;
        --text-color: #cdd6f4;
        --text-color-disabled: #6c7086;
        --bg-selected: #cba6f7;
        --border-radius: 6px;
        --notification-icon-size: 48px;
        --notification-shadow: none;
        --font-size-body: 13px;
        --font-size-summary: 14px;
      }

      * {
        font-family: "FiraCode Nerd Font Propo", "Noto Sans CJK KR";
      }

      .notification-row .notification-background .notification.critical {
        border-color: #f38ba8;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .summary {
        font-weight: bold;
      }

      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .time,
      .notification-row .notification-background .notification .notification-default-action .notification-content .text-box .body {
        color: #a6adc8;
      }

      .control-center {
        background: rgba(30, 30, 46, 0.95);
        border: 1px solid #45475a;
      }

      .widget-title > label {
        font-size: 1.1rem;
        font-weight: bold;
      }

      .widget-title > button {
        background: #313244;
        color: #cdd6f4;
        border: none;
        box-shadow: none;
        padding: 2px 10px;
      }

      .widget-title > button:hover {
        background: #45475a;
      }

      .widget-dnd label {
        font-size: 1rem;
      }

      .widget-dnd switch {
        background: #45475a;
        border: none;
        border-radius: 12px;
        min-width: 40px;
        min-height: 20px;
      }

      .widget-dnd switch:checked {
        background: #cba6f7;
      }

      .widget-dnd switch slider {
        background: #cdd6f4;
        border-radius: 50%;
        min-width: 18px;
        min-height: 18px;
        margin: 1px;
        box-shadow: none;
      }
    '';
  };
}
