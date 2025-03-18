{ config, pkgs, lib, ...}:

let
  wallpapers = pkgs.fetchFromGitHub {
    owner = "ChagnonSebastien";
    repo = "Wallpapers";
    rev = "6434a34df7baa7de344fc69db6519cfcc83688dc";
    sha256 = "0xsg4vyx1rirb5s4kzikbgw6biw81fmrzp3141hckf8pdh6pgv8b";
  };
  
in
{  
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = [
        "${wallpapers}/space_left.png"
        "${wallpapers}/space_right.png"
      ];

      wallpaper = [
        "DP-2,${wallpapers}/space_left.png"
        "DP-3,${wallpapers}/space_right.png"
      ];
    };
  };
}
