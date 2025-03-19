{ pkgs, ...}: {

  imports = [
    ./shell.nix
    ./hyprland.nix
    ./hyprpaper.nix
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    brave
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
    (writeShellScriptBin "jellyfin" ''
      export QT_QPA_PLATFORM="xcb"
      exec ${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer "$@"
    '')
    vscodium
    wireguard-tools
    caprine
    element-desktop
    libreoffice-qt6-still
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
  ];

  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      "text/html" = "librewolf.desktop"; # Replace with your browser's desktop file
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };
  };

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
