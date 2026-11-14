# OVH VPS (KVM/OpenStack, SeaBIOS, virtio-scsi disk at /dev/sda, virtio-net ens3).
{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
