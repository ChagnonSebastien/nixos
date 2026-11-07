{ pkgs, ... }:
{
  # GUI apps shared by every graphical machine.
  home.packages = with pkgs; [
    librewolf
    youtube-music
    bitwarden-desktop
    bitwarden-cli
    vscodium
    obs-studio
    beekeeper-studio
    (writeShellScriptBin "beekeeper" ''
      export LIBGL_ALWAYS_SOFTWARE=1
      exec ${pkgs.beekeeper-studio}/bin/beekeeper-studio "$@"
    '')
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "librewolf.desktop";
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };
  };
}
