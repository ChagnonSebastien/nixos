{ pkgs, ... }:
{
  imports = [ ./ozone-wayland.nix ];

  services.desktopManager.cosmic.enable = true;

  environment.cosmic.excludePackages = with pkgs; [
  ];
}