# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
{
  imports = [
    ./generic.nix
    ./modules/shell.nix
    ./modules/nvidia-gpu.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
  boot.kernelParams = [ "nvidia-drm.fbdev=1"];

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;
    open = false;
  };

  environment.systemPackages = with pkgs; [
    nvidia-docker
    cudatoolkit
    nvidia-container-toolkit
    libnvidia-container
  ];

  networking.hostName = "homelab";
  networking.firewall.enable = false;
  networking.networkmanager.enable = true;
  networking.interfaces.enp42s0 = {
    useDHCP = false;

    ipv4.addresses = [
      {
        address = "192.168.0.2";  # Replace with your desired static IP
        prefixLength = 24;        # Typically 24 for a 255.255.255.0 netmask
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.0.1";
    interface = "enp42s0";
  };

  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];  # Replace with your preferred DNS servers

  virtualisation.docker = {
    enable = true;

    daemon.settings.features.cdi = true;
    rootless = {
      enable = false;
      setSocketVariable = true;
    };

    #extraOptions = "--default-runtime=nvidia";
  };

  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" ];
    initialPassword = "change-me";
  };

  services.openssh.enable = true;

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11"; # Did you read the comment?

}

