{ config, lib, pkgs, ... }:

{
  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    nvidiaSettings = true;
    # mkDefault: hosts with older GPUs pick a legacy driver branch.
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
  };

  environment.systemPackages = with pkgs; [
    cudatoolkit
  ];
}

