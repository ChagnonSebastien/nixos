{ pkgs, config, lib, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
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

  users.users.seb.extraGroups = [ "vboxusers" ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # This desktop's older GPU needs the legacy_580 driver branch.
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05"; # Did you read the comment?

}

