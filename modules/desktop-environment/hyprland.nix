{ config, pkgs, ... }:
{
  services.xserver.xkb.layout = "ca";
  services.xserver.xkb.variant = "fr";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
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
    sway-audio-idle-inhibit
    playerctl
  ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Always start the UWSM-managed session: the plain "Hyprland" session never
  # reaches graphical-session.target, so waybar, cliphist, hypridle, fcitx5 &
  # co. would not start. No session picker, just log in.
  services.greetd.settings.default_session.command =
    "${pkgs.tuigreet}/bin/tuigreet --time --remember"
    + " --cmd '${config.programs.uwsm.package}/bin/uwsm start -e -D Hyprland hyprland.desktop'";
}

