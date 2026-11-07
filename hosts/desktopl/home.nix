{ pkgs, ...}: {

  imports = [
    ../../home/modules/shell.nix
    ../../home/modules/desktop-apps.nix
    ../../home/desktop-environment/hyprland.nix
  ];

  home.packages = with pkgs; [
    qview
    (mpv.override {
      yt-dlp = yt-dlp-light;
    })

    vesktop
    jellyfin-media-player
    (writeShellScriptBin "jellyfin" ''
      export QT_QPA_PLATFORM="xcb"
      exec ${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer "$@"
    '')
    wireguard-tools
    caprine
    element-desktop
    qbittorrent-enhanced
    jetbrains.idea
    prismlauncher
    obsidian
    #libreoffice-qt6-still
    onlyoffice-desktopeditors
    #chromium
    #(writeShellScriptBin "google-chrome" ''
    #  exec ${pkgs.chromium}/bin/chromium "$@"
    #'')

    claude-code
  ];

  xdg.mimeApps.defaultApplications = {
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

  # services.owncloud-client.enable = true;

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
