{ pkgs, ...}: {

  imports = [
    ./modules/shell.nix
    ./desktop-environment/hyprland.nix
  ];

  home.packages = with pkgs; [
    librewolf

    qview
    vesktop
    youtube-music
    mpv
    bitwarden-desktop
    bitwarden-cli
    jellyfin-media-player
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
    #chromium
    #(writeShellScriptBin "google-chrome" ''
    #  exec ${pkgs.chromium}/bin/chromium "$@"
    #'')
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

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
