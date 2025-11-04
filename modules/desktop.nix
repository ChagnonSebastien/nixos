{ config, pkgs, ... }:

{
  boot.kernelParams = [ "kvm.enable_virt_at_load=0"]; # nvidia-drm.fbdev=1

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    open = false;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session";
	user = "greeter";
      };
    };
    restart = true;
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
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

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock = { };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.seatd.enable = true;

  environment.systemPackages = with pkgs; [
    spacedrive
    seatd
    pavucontrol
    swaynotificationcenter # Notification daemon 
    sway-audio-idle-inhibit
    playerctl
    cudatoolkit
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "seb" ];

  environment.sessionVariables = {
    #ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    #NIXOS_OZONE_WL = "1";
  };
  environment.variables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_RUNTIME_DIR = "/run/user/$(id -u)";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

}

