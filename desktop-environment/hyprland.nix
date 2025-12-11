{ pkgs, ... }:
{
  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_RUNTIME_DIR = "/run/user/$(id -u)";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  services.xserver.xkb.layout = "ca";
  services.xserver.xkb.variant = "fr";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk              # GTK immodule
      qt6Packages.fcitx5-chinese-addons #fcitx5-chinese-addons   # Pinyin/Shuangpin, punctuation, etc.
      fcitx5-rime             # Rime (Pinyin/Bopomofo/Wubi via schemas)
    ];
  };

  security.pam.services.hyprlock = { };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  services.seatd.enable = true;

  environment.systemPackages = with pkgs; [
    seatd
    pavucontrol
    swaynotificationcenter # Notification daemon
    sway-audio-idle-inhibit
    playerctl
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}

