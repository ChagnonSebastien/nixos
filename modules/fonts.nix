{ pkgs, ... }:

{
  # TTY console font; keymap follows services.xserver.xkb.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    ubuntu-classic
    liberation_ttf
    (pkgs.vazirmatn or pkgs.vazir-fonts) # renamed in unstable; drop fallback once stable has vazirmatn
    font-awesome
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    nerd-fonts.fira-code
  ];
  fonts.fontconfig = {
    defaultFonts = {
      serif = [  "Liberation Serif" "Vazirmatn" ];
      sansSerif = [ "Ubuntu" "Vazirmatn" ];
      monospace = [ "FiraCode" ];
    };
  };
}
