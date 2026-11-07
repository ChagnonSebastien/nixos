{ config, pkgs, ...}:
let
  userBin = "/etc/profiles/per-user/${config.home.username}/bin";
in
{

  imports = [
    ./modules/shell.nix
    ./modules/devtools.nix
  ];

  home.sessionVariables = rec {
    GOPRIVATE = "gitlab.com/qohash/*";
    PATH = "${userBin}:$PATH";
  };

  home.packages = with pkgs; [
    ssm-session-manager-plugin
    icu
    zip
    tinyproxy
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
