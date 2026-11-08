{ pkgs, ... }:
let
  youtube-music = pkgs.symlinkJoin {
    name = "youtube-music";
    paths = [ pkgs.pear-desktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "youtube-music";
    postBuild = ''
      rm $out/bin/pear-desktop
      makeWrapper ${pkgs.pear-desktop}/bin/pear-desktop $out/bin/youtube-music \
        --add-flags "--disk-cache-size=104857600"

      desktop=share/applications/com.github.th-ch.youtube-music.desktop
      rm $out/$desktop
      sed -e 's|^Exec=pear-desktop|Exec=youtube-music|' -e 's|^Name=.*|Name=YouTube Music|' \
        ${pkgs.pear-desktop}/$desktop > $out/$desktop
    '';
  };
in
{
  # GUI apps shared by every graphical machine.
  home.packages = with pkgs; [
    librewolf
    youtube-music
    bitwarden-desktop
    bitwarden-cli
    vscodium
    obs-studio
    wl-clipboard # Clipboard CLI
    cliphist # Clipboard history
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
