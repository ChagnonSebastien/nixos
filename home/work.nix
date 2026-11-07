{ pkgs, ...}: {

  imports = [
    ./modules/shell.nix
    ./modules/desktop-apps.nix
    ./modules/devtools.nix
    ./desktop-environment/plasma.nix
  ];

  home.packages = with pkgs; [
    slack
    mpv
    wl-clipboard # Clipboard CLI
    cliphist # Clipboard history
    jetbrains.idea-ultimate

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

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
