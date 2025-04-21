{ pkgs, ...}: {

  imports = [
    ./shell.nix
  ];

  home.packages = with pkgs; [
    awscli2
  ];

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "24.05";
}
