{ pkgs, ...}: {

  imports = [
    ./modules/hyprland.nix
    ./modules/hyprpaper.nix
    ./modules/waybar.nix
  ];

  home.packages = with pkgs; [
    rofi
    satty # Screenshoot editor
    grim # Screenshot from wayland compositor
    slurp # Screenshot zone selection
    wl-clipboard # Clipboard CLI
    cliphist # Clipboard history
  ];

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
        sha256 = "1h9zqc6gcz9rpn7p6ir3jy9glnj336jdcz5ildagd0fm5kn8vlz7";
      }}/themes/mocha.conf
    '';
  };
}
