{ config, pkgs, ...}:
let
  userBin = "/etc/profiles/per-user/${config.home.username}/bin";
in
{

  imports = [
    ../../home/modules/shell.nix
    ../../home/modules/devtools.nix
  ];

  home.sessionVariables = {
    PATH = "${userBin}:$PATH";
  };

  home.packages = with pkgs; [
    ssm-session-manager-plugin
    icu
    zip
    tinyproxy
  ];

  programs.git.settings.user.email = "sebastien.chagnon@qohash.com";

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
