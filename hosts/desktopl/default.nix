{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./vpn.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/nvidia-gpu.nix
    ../../modules/smart-desktop.nix
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # This desktop's older GPU needs the legacy_580 driver branch.
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

  # legacy_580 drops GPU fence waits submitted before nvidia-resume finishes, freezing the screen on wake.
  systemd.services = let
    signalHyprland = sig: {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "-${pkgs.procps}/bin/pkill -${sig} -f '^Hyprland( |$)'";
      };
      wantedBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    };
  in {
    hyprland-sleep-pause = signalHyprland "STOP" // {
      before = [ "nvidia-suspend.service" "nvidia-hibernate.service" "systemd-suspend.service" "systemd-hibernate.service" ];
    };
    hyprland-sleep-continue = signalHyprland "CONT" // {
      after = [ "nvidia-resume.service" "systemd-suspend.service" "systemd-hibernate.service" ];
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05";
}

