{ ... }:
{
  # GRUB on EFI with os-prober, for dual-boot machines.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 10;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      default = 0;
      # Keep /boot from filling up: each kernel+initrd is ~56 MB.
      configurationLimit = 3;
    };
  };
}
