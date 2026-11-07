{ ... }:
{
  imports = [
    ./modules/shell.nix
    ./modules/pi-hole-lists.nix
  ];

  home.stateVersion = "24.05";
}
