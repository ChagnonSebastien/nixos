{ ... }:
{
  imports = [
    ../../home/modules/shell.nix
    ../../home/modules/pi-hole-lists.nix
  ];

  home.stateVersion = "24.05";
}
