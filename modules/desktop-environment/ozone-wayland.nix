{ ... }:

{
  # Run Electron/Chromium apps natively on Wayland.
  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };
}
