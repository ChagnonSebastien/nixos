{ ... }:
let
  net = import ../../lib/network.nix;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "4h";
        ForwardAgent = false;
      };
      homelab = {
        HostName = net.homelab.lanIp;
        User = "seb";
      };
      vps = {
        HostName = net.vps.ipv4;
        User = "seb";
      };
    };
  };
}
