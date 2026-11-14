{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/user.nix
    ../../modules/kvm.nix
    ../../modules/boot-grub.nix
    ../../modules/devtools.nix
    ../../modules/nvidia-gpu.nix
    ../../modules/smart-desktop.nix
    ../../modules/docker-rootless.nix
    ../../modules/desktop-environment/shared.nix
    ../../modules/desktop-environment/plasma.nix
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback.out
  ];
  boot.kernelModules = [
    "v4l2loopback"
    "snd-aloop"
  ];
  boot.extraModprobeConfig = ''
    # exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming
    # card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
    # https://github.com/umlaeute/v4l2loopback
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
  '';

  networking.networkmanager.enable = true;

  users.users.seb = {
    description = "seb";
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  programs.firefox.enable = true;

  system.stateVersion = "25.11";
}
