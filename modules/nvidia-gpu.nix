{ config, pkgs, ... }:

{
  boot.kernelParams = [ "kvm.enable_virt_at_load=0"]; # nvidia-drm.fbdev=1

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    open = false;
  };

  environment.systemPackages = with pkgs; [
    cudatoolkit
  ];
}

