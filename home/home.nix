{ pkgs, ...}: {

  imports = [
    ./shell.nix
    ./hyprland.nix
    ./hyprpaper.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    librewolf

    qview
    vesktop
    rofi-wayland
    youtube-music
    mpv
    bitwarden
    bitwarden-cli
    jellyfin-media-player
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
    wireguard-tools
    caprine
    element-desktop
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
    obsidian
    #libreoffice-qt6-still
    onlyoffice-desktopeditors
  ];

  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      "text/html" = "librewolf.desktop"; # Replace with your browser's desktop file
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";

      "application/pdf" = "onlyoffice-desktopeditors.desktop";

      "image/apng" = "qview.desktop";
      "image/avif" = "qview.desktop";
      "image/bmp" = "qview.desktop";
      "image/gif" = "qview.desktop";
      "image/vnd.microsoft.icon" = "qview.desktop";
      "image/jpeg" = "qview.desktop";
      "image/png" = "qview.desktop";
      "image/svg+xml" = "qview.desktop";
      "image/tiff" = "qview.desktop";
      "image/webp" = "qview.desktop";

      "video/x-msvideo" = "mpv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/mp2t" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
    };
  };

  services.owncloud-client.enable = true;

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

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
