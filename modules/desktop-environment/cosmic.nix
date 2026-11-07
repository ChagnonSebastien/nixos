{ pkgs, ... }:
{
  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  services.desktopManager.cosmic.enable = true;

  environment.cosmic.excludePackages = with pkgs; [
  ];
}