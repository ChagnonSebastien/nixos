# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 10;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      default = 0;
    };
  };

  networking.hostName = "homelab";
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
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "seat" "video" "input" "audio" "networkmanager" "docker" ];
    initialPassword = "change-me";
  };

  services.openssh.enable = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  system.stateVersion = "24.11"; # Did you read the comment?

}

