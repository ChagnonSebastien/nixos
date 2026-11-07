{ pkgs, config, lib, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/common.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
    ../../modules/shell.nix
    ../../modules/docker-rootless.nix
    ../../modules/desktop-environment/shared.nix
    ../../modules/desktop-environment/hyprland.nix
  ];

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedUDPPorts = [ 51820 ];
      allowedTCPPorts = [ ];
    };
  };

  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users = {
    users.seb = {
      isNormalUser = true;
      extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" "vboxusers" ];
      initialPassword = "change-me";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  environment.systemPackages = with pkgs; [
  ];

  environment.sessionVariables = {
  };

  environment.variables = {
  };

  # Override NVIDIA driver from nvidia-gpu.nix to use legacy_580 for this desktop's older GPU
  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_580;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05"; # Did you read the comment?

}

