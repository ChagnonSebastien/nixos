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
        sha256 = "1sfjwvn6xwc882mzv9nhb8wsw3q4kapypq7gh1dkq3jqcjc717b3";
      }}/themes/mocha.conf
    '';
  };
}
