{ ... }:

{
  # Don't let KVM claim VT-x/AMD-V when its module loads (default since
  # kernel 6.12), so other hypervisors such as VirtualBox can still use it.
  boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];
}
