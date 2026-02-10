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
      ipc = true;
      splash = false;

      wallpaper = [
        {
          monitor = "DP-2";
          path = "${wallpapers}/space_left.png";
        }
        {
          monitor = "DP-3";
          path = "${wallpapers}/space_right.png";
        }
      ];
    };
  };
}
