{ config, ... }:
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

  # S3 resume hang diagnosis: drop this block once the hanging device is found.
  boot.kernelParams = [
    "reserve_mem=2M:4096:oops"
    "ramoops.mem_name=oops"
    "ramoops.console_size=1048576"
    "ramoops.record_size=262144"
    "no_console_suspend"
  ];
  boot.kernelModules = [ "ramoops" ];
  # Otherwise systemd-pstore can run before ramoops loads and skip archiving the hang log.
  systemd.services.systemd-pstore.after = [ "systemd-modules-load.service" ];
  # pm_print_times logs each device callback at KERN_INFO, which ramoops only captures at console level 7.
  boot.consoleLogLevel = 7;
  systemd.tmpfiles.rules = [
    "w /sys/power/pm_print_times - - - - 1"
    "w /sys/power/pm_debug_messages - - - - 1"
  ];
  # watchdog0 is intel_oc_wdt; probe order decides the numbering.
  systemd.settings.Manager = {
    WatchdogDevice = "/dev/watchdog1";
    RuntimeWatchdogSec = "30s";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.05";
}

