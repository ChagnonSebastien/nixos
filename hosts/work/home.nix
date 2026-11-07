{ pkgs, ...}: {

  imports = [
    ../../home/modules/shell.nix
    ../../home/modules/desktop-apps.nix
    ../../home/modules/devtools.nix
    ../../home/desktop-environment/plasma.nix
  ];

  home.packages = with pkgs; [
    slack
    mpv
    jetbrains.idea

    corretto21
    nodejs

    pre-commit
    golangci-lint
    gofumpt
    gotools
    gnumake
    protobuf
  ];

  programs.zsh = {
    shellAliases = {
      vpn = "sudo bash aws-vpn.bash";
      dev = "bash qohash-connection-script-aws.bash -e dev -a";
      stg = "bash qohash-connection-script-aws.bash -e staging -a";
      prd = "bash qohash-connection-script-aws.bash -e prod -a";
      myip = "curl -s https://ipinfo.io/ip | wl-copy";
    };
  };

  programs.git.settings.user.email = "sebastien.chagnon@qohash.com";

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
