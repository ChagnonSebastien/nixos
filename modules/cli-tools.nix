{ pkgs, ... }:

{
  # Baseline command-line tools available system-wide on every host.
  environment.systemPackages = with pkgs; [
    kitty # also ships kitty's terminfo, so ssh sessions from kitty render correctly
    pciutils
    wget
    tree
    ntfs3g
    unzip
    jq
  ];

  programs = {
    git.enable = true;
    vim.enable = true;
    neovim.enable = true;
    tmux.enable = true;
  };
}
