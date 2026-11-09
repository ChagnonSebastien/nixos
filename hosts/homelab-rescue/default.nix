{ pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXRESCUE";
    fsType = "ext4";
  };

  # shared with homelab: grub installs here under its own bootloader id, kernels stay on NIXRESCUE
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  networking = {
    hostName = "homelab-rescue";
    useDHCP = false;
    interfaces.enp42s0.ipv4.addresses = [ { address = "192.168.0.2"; prefixLength = 24; } ];
    defaultGateway = "192.168.0.1";
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  users.mutableUsers = false;
  users.users.seb = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # written at install time from homelab's shadow; the repo is public
    hashedPasswordFile = "/etc/rescue/seb.hash";
  };

  environment.systemPackages = with pkgs; [
    e2fsprogs gptfdisk parted btrfs-progs smartmontools efibootmgr rsync tmux vim
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/Montreal";
  documentation.enable = false;

  system.stateVersion = "26.05";
}
