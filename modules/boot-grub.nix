{ pkgs, ... }:
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
      # Firmware updates wipe NVRAM boot entries and fall back to EFI/BOOT/BOOTX64.EFI.
      extraInstallCommands = ''
        ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/BOOT
        ${pkgs.coreutils}/bin/cp /boot/EFI/NixOS-boot/grubx64.efi /boot/EFI/BOOT/BOOTX64.EFI
      '';
    };
  };
}
