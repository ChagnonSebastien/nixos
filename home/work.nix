{ pkgs, ...}: {

  imports = [
    ./modules/shell.nix
    ./desktop-environment/plasma.nix
  ];

  home.packages = with pkgs; [
    librewolf
    slack

    youtube-music
    mpv
    bitwarden-desktop
    bitwarden-cli
    wl-clipboard # Clipboard CLI
    cliphist # Clipboard history
    vscodium
    beekeeper-studio
    (writeShellScriptBin "beekeeper" ''
      export LIBGL_ALWAYS_SOFTWARE=1
      exec ${pkgs.beekeeper-studio}/bin/beekeeper-studio "$@"
    '')
    jetbrains.idea-ultimate
    obs-studio

    awscli2
    kubectl
    terraform
    openssl
    kubernetes-helm
    go
    gcc
    k9s
    azure-cli
    corretto21
    nodejs

    pre-commit
    golangci-lint
    gofumpt
    gotools
    gnumake
    postgresql
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

  xdg.mimeApps = {
    enable = true;
    
    defaultApplications = {
      "text/html" = "librewolf.desktop"; # Replace with your browser's desktop file
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
