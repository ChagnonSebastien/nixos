{ ... }:
{
  imports = [
    ../../home/modules/shell.nix
    ../../home/modules/pi-hole-lists
  ];

  home.stateVersion = "24.05";
}
