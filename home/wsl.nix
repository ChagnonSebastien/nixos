{ config, pkgs, ...}:
let
  userBin = "/etc/profiles/per-user/${config.home.username}/bin";
in
{

  imports = [
    ./modules/shell.nix
  ];

  home.sessionVariables = rec {
    GOPRIVATE = "gitlab.com/qohash/*";
    PATH = "${userBin}:$PATH";
  };

  home.packages = with pkgs; [
    awscli2
    ssm-session-manager-plugin
    kubectl
    terraform
    openssl
    kubernetes-helm
    go
    gcc
    k9s
    azure-cli
    icu
    zip
    postgresql

    chromium
    tinyproxy
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
